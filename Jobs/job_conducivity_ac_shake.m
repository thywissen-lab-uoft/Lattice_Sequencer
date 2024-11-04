function J=job_conducivity_ac_shake
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_conductivity(curtime,freq,field,levitate_value,evap_depth,mod_strength,mod_ramp_time,uwave_freq_amp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 
        %Levitation voltage value during xdtB
        defVar('xdtB_levitate_value',levitate_value,'V');        
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');      
        
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
%Evaporation Levitation Voltage
lev_conductivity = 0.11;
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);
uwave_freq_amp = 30;
% Modulation Frequencies
freq_list = 55+[-35 -30 -25 -20 -10 -5 0 5 10 20 30 45];
% Randomize the modulation frequencies
freq_list = freq_list(randperm(numel(freq_list)));


for ii = 1:length(freq_list)
    % Get the current modulation frequency
    f = freq_list(ii);   
    
    % AMPLITUDE RESPONSE CODE CAN BE CALCULATED MANUALLY NO NEED TO ALWAYS
    % PUT IT IN. FC FIX THIS PLEASE
    
    % Modulation Amplitude Calibration    
    %0.85um amplitude response
%     x0 = 50;
%     y0 = 0.9513;
%     aL = [9.3e-4 -1.18e-6 1.04e-9 -3.95e-13];
%     aH = [1.41e-3 -2.08e-7 2.47e-11 -1.3e-15];   

    %0.65um amplitude response
%     x0 = 50;
%     y0 = 0.9513;
%     aL = [7.87e-4 -9.73e-7 8.73e-10 -3.47e-13];
%     aH = [1.28e-3 -1.61e-7 1.56e-11 -7.28e-16]; 

    %0.65um amplitude response
    x0 = 51;
    y0 = 0.7139;
    aL = [7.67e-4 -1.01e-6 9.34e-10 -3.66e-13];
    aH = [1.07e-3 -1.42e-7 1.71e-11 -8.98e-16]; 
    
    if f<=x0
        a=aL;
    else
        a=aH;
    end        
    mod_strength = y0 + a(1)*(f-x0)^2 + a(2)*(f-x0)^4 + a(3)*(f-x0)^6 + a(4)*(f-x0)^8; 
    mod_strength = min([mod_strength 4]);

    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity(curtime,f,B_conductivity,lev_conductivity,power_conductivity,mod_strength,mod_ramp_time,uwave_freq_amp),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;
    npt.CyclesRequested = 17;
    npt.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B_conductivity) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp, ', num2str(uwave_freq_amp), ' kHz uwave amp'];
    npt.SaveDirName         = npt.JobName;    
    J(ii) = sequencer_job(npt);
end


end

