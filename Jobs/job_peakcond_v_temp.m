function J=job_peakcond_v_temp
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_p(curtime,freq,field,lattice_pulse_depth,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
               
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms'); 
     
        % Pulse lattice to heat atoms
        seqdata.flags.xdtB_pulse_lattice            = 1;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',lattice_pulse_depth,'Er');
        defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
        defVar('xdtb_lattice_pulse_equil_time',[100],'ms');
        
        % Modulation time
        t0 = 50;T = 1e3/freq; 
        t_start = T*ceil((t0+mod_ramp_time)/T);
%         tvec = round(t0 + linspace(0,2*T,18),1);
%         tvec = round(t_start + [zeros(1,3) 0.25*ones(1,3) 0.5*ones(1,3) 0.75*ones(1,3) ones(1,3)]*T, 1) - mod_ramp_time;
        tvec = round(t_start + [0:0.125:2]*T, 1) - mod_ramp_time;
        tvec = tvec(:);
        tvec = tvec';
        defVar('conductivity_mod_time',tvec,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',uwave_freq_amp,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
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
f = 51;
%Modulation amplitude
mod_strength = 0.9;
%xdtB lattice pulse depth
pulse_depth_list = [0:4];

% Randomize the lattice pulse depths
pulse_depth_list = pulse_depth_list(randperm(numel(pulse_depth_list)));


for ii = 1:length(pulse_depth_list)
    % Get the current modulation frequency
    pulse_depth = pulse_depth_list(ii);   
    
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_p(curtime,f,B_conductivity,pulse_depth,power_conductivity,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    out.CycleEnd = 17;
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = [num2str(ii) ' shake ' num2str(pulse_depth) 'ER, ' num2str(f) ' Hz,' ...
        num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end


end

