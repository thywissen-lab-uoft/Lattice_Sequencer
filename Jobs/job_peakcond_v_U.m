function J=job_peakcond_v_U
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_pvU(curtime,freq,field,evap_depth,mod_strength,mod_ramp_time)
        global seqdata;        
        
        defVar('xdtB_evap_power',evap_depth,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
               
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        defVar('conductivity_mod_freq',freq,'Hz');
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Mod Depth
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms'); 
     
        % Modulation time
        t0 = 50;
        T = 1e3/freq; 
        t_start = T*ceil((t0+mod_ramp_time)/T);
        tvec = round(t_start + [0:0.125:2]*T, 1) - mod_ramp_time;
        tvec = tvec(:);
        tvec = tvec';
        defVar('conductivity_mod_time',tvec,'ms');             
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        d = load('f_offset.mat');
        f_offset = d.f_offset; 
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
% B_conductivity = 201.1;
% Optical Evaporation Power (W)
power_conductivity = 0.070; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Modulation Frequencies
f = 54;
%Modulation amplitude
mod_strength = [1.2];
 
%xdtB lattice pulse depth
field_list = [190 195 198.5 199.4 200 200.4 200.65 200.8 200.9 201.1 201.2];
% field_list = [201.1 200];

% Randomize the lattice pulse depths
field_list = field_list(randperm(numel(field_list)));

ind=1;
for bb = 1:length(field_list)
    B = field_list(bb);             % magnetifc field [G]
    for vv = 1 :length(mod_strength)        
        V = mod_strength(vv);       % Drive amplitude [V]
        
        out = struct;   
        out.SequenceFunctions   = {@main_settings,@(curtime) ...
            ac_pvU(curtime,f,B,power_conductivity,V,mod_ramp_time),@main_sequence};
        out.CycleEnd = 17;
        out.WaitMode = 2;
        out.WaitTime = 90;
        out.JobName             = [num2str(bb) ' shake ' num2str(f) ' Hz,' ...
            num2str(B) 'G,' num2str(1e3*power_conductivity) ' mW ' num2str(V) ' amp, ' ...
            num2str(mod_ramp_time) ' ms ramp'];
        out.SaveDir         = out.JobName;    
        J(ind) = sequencer_job(out);
        ind = ind+1;
    end
end


end

