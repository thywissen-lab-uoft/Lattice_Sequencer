function J = job_pulse_lattice_heat
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = pulse_lattice_heat(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        %Levitation voltage value during xdtB
               
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');  
        defVar('lattice_load_feshbach_holdtime',[0],'ms');

        % Pulse lattice
        seqdata.flags.xdtB_pulse_lattice            = 1;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',[0:0.5:5],'Er');
        defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
        defVar('xdtb_lattice_pulse_equil_time',[500],'ms');
        
        % Modulation time
        t0 = 50;T = 1e3/freq; 
        t_start = T*ceil((t0+mod_ramp_time)/T);
%         tvec = round(t0 + linspace(0,2*T,18),1);
%         tvec = round(t_start + [zeros(1,3) 0.25*ones(1,3) 0.5*ones(1,3) 0.75*ones(1,3) ones(1,3)]*T, 1) - mod_ramp_time;
        tvec = round(t_start + [0]*T, 1) - mod_ramp_time;
        tvec = tvec(:);
        tvec = tvec';
        defVar('conductivity_mod_time',t0,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',uwave_freq_amp,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset;       
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
B_conductivity = 201.1;
% Optical Evaporation Power (W)
power_conductivity = 0.064; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);
uwave_freq_amp = 30;
% Modulation Frequencies
f = 55;
%Modulation strength
mod_strength = 0.9;

out = struct;   
out.SequenceFunctions   = {@main_settings,@(curtime) ...
    pulse_lattice_heat(curtime,f,B_conductivity,power_conductivity,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
out.CycleEnd = 11;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName             = [' pulse lattice heat ' num2str(f) ' Hz,' ...
    num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
    num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
out.SaveDir         = out.JobName;    
J = sequencer_job(out);


end
