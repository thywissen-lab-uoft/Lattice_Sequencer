function J=job_conductivity_one_freq
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_conductivity_2(curtime,...
    freq,field,evap_depth,mod_strength,mod_ramp_time,total_mod_time)
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

        % Single plane selection
        seqdata.flags.plane_selection_dotilt        = 0;
        
        % Modulation time
        tVec = total_mod_time - mod_ramp_time;
        defVar('conductivity_mod_time',tVec,'ms');   
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
B0 = 201.1;
% Optical Evaporation Power (W)
xdt_power = 0.066; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Modulation Frequencies
freq = 55;


% Randomize the modulation frequencies
periods = [0 2 4 6];

for ii = 1:length(periods)
    N = periods(ii);                      % Number of periods to evalulate prior
    T_period_ms = round(1e3/freq,1);      % Period of drive [ms]
    N0 = ceil(mod_ramp_time/T_period_ms); % Num cyclces needed for ramp
    T0 = (N+N0)*T_period_ms;              % Starting Time
    dT = [0:0.125:2]*T_period_ms;         % Time vector over next 2 periods

    total_time_vector = T0 + dT;


    f=freq;
    
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

    
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity_2(curtime,...
        f,B0,...
        xdt_power,mod_strength,mod_ramp_time,total_time_vector),...
        @main_sequence};
    out.CycleEnd = length(total_time_vector);
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = [num2str(ii) ' shake ' num2str(f) ' Hz,' ...
        num2str(B0) 'G,' num2str(1e3*xdt_power) ' mW ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp,' num2str(N) ' periods start'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end


end

