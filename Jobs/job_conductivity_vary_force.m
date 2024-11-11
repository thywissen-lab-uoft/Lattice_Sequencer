function J=job_conductivity_vary_force
   
%% AC Sequnece Modifier
 function curtime = ac_conductivity_me(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time,mod_time)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        defVar('lattice_load_feshbach_field',field,'G'); 

        % Conductivity   
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');
        defVar('conductivity_mod_time',mod_time,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
 end
%% AC Conductivity Job
clear J

B0 = 201.1;         % Magnetic Field [G]
xdt_pow = 0.064;    % Optical Evaporation Power [W]
mod_ramp_time = 50; % Conductivity modulation ramp up time [ms]
freq = 52;          % Modulation Frequencies [Hz]
mod_amp_list = ...  % Modulation amplitude [V] 
    [0.8];

mod_amp_list =mod_amp_list(randperm(numel(mod_amp_list)));

T = 1e3/freq;       %period
t0 = 50;            % time after ramp to continue modulating
Tstart = ceil((t0+mod_ramp_time)/T)*T; % time complete moudlation ramp up and t0
Nperiods = 2;
NpointsperPeriod = 8;
total_mod_time = Tstart + [0:(1/NpointsperPeriod):Nperiods]*T;
total_mod_time = round(total_mod_time,1);
total_mod_time = total_mod_time(:);
mod_time = total_mod_time-mod_ramp_time;

 
for ii = 1:length(mod_amp_list)
    mod_strength = mod_amp_list(ii);
    
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        ac_conductivity_me(curtime,...
        freq,...
        B0,...
        xdt_pow,...
        mod_strength,...
        mod_ramp_time,...
        mod_time),...
        @main_sequence};
    out.CycleEnd = length(mod_time);
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = [num2str(ii) ' shake ' ...
        num2str(freq) ' Hz,' ...
        num2str(B0) 'G,' ...
        num2str(1e3*xdt_pow) ' mW,' ...
        num2str(mod_strength) ' amp,' ...
        num2str(mod_ramp_time) ' ms ramp'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end

end

