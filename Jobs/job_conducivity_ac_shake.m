function J=job_conducivity_ac_shake
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_conductivity(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        seqdata.flags.lattice_load_feshbach_ramp  = 1;
        defVar('lattice_load_feshbach_field',field,'G'); 
   
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');      
        
        % Pulse lattice
        seqdata.flags.xdtB_pulse_lattice            = 0;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',[5],'Er');
        defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
        defVar('xdtb_lattice_pulse_equil_time',[500],'ms');
        
        % Modulation time
        t0 = 50;T = 1e3/freq; 
        t_start = T*ceil((t0+mod_ramp_time)/T);
        
        % Two periods 1/8 cycle sampling
        tvec = round(t_start + [0:0.125:2]*T, 1) - mod_ramp_time;
        
        % Three periods 1/10 cycle sampling
%         tvec = round(t_start + [0:0.1:3]*T, 1) - mod_ramp_time;
        
        tvec = tvec(:);
        tvec = tvec';
        defVar('conductivity_mod_time',tvec,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
B_conductivity = 201.1;
% Optical Evaporation Power (W)
power_conductivity = 0.067; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);

% Modulation Frequencies
freq_list = [54];

% Randomize the modulation frequencies
% freq_list = freq_list(randperm(numel(freq_list)));

% freq_list = [160 freq_list];

for ii = 1:length(freq_list)
    % Get the current modulation frequency
    f = freq_list(ii);   
    
    %0.65um amplitude response
    % x0 = 14;
    % y0 = 1.9786;
    % aL = [3.95e-4 -4.90e-7 4.30e-10 -1.60e-13];
    % aH = [2.09e-4 4.91e-8 -4.40e-12 1.16e-16]; 

    [x0,y0,aL,aH] = calc_drive(2.4,2*pi*36,0.65); %Inputs: (Temp (t), Gamma (s^-1), desired amp (um))
    
    if f<=x0
        a=aL;
    else
        a=aH;
    end   

    mod_strength = y0 + a(1)*(f-x0)^2 + a(2)*(f-x0)^4 + a(3)*(f-x0)^6 + a(4)*(f-x0)^8; 
    mod_strength = min([mod_strength 4]);
    
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity(curtime,f,B_conductivity,power_conductivity,mod_strength,mod_ramp_time),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;

    out.CycleEnd = 17;    
%     out.CycleEnd = 30;

    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = [num2str(ii) ' shake ' '5 Er pulse' num2str(f) ' Hz,' ...
        num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end


end

