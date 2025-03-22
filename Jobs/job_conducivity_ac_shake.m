function J=job_conducivity_ac_shake
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_conductivity(curtime,freq,field,evap_depth,pulse_depth,mod_strength,mod_ramp_time,Nplane_shift,vert_disp)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');evap_depth;
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
        
        %Choose the plane to image
        defVar('qgm_planeShift_N',(Nplane_shift),'plane');
        
        % Pulse lattice
        seqdata.flags.xdtB_pulse_lattice            = 1;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',[pulse_depth],'Er');pulse_depth;
        defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
        defVar('xdtb_lattice_pulse_equil_time',[100],'ms');
        
        % Modulation time
        t0 = 50;T = 1e3/freq; 
        t_start = T*ceil((t0+mod_ramp_time)/T);
        
        % Two periods 1/8 cycle sampling
        tvec = round(t_start + [0:0.125:2]*T, 1) - mod_ramp_time;
        
        % Three periods 1/10 cycle sampling
%         tvec = round(t_start + [0:0.1:3]*T, 1) - mod_ramp_time;
        
        tvec = tvec(:);
        tvec = tvec';
        defVar('conductivity_mod_time',[tvec],'ms');tvec;
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
% B_conductivity = 201.1;
% Optical Evaporation Power (W)
% power_conductivity = 0.0638; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;
% Plane Selection Frequency amplitude (kHz);

% Choose how many plane from center to shift by
Nplane = [6]; 

% Modulation Frequencies
freq_list = [20 30 40 50 55 57 60 62 65 67 70 75 80 90 100];[20 30 35 40 45 48 50 52 55 57 60 65 75 90 100];

% Randomize the modulation frequencies
freq_list = freq_list(randperm(numel(freq_list)));

% freq_list = [160 freq_list];
%55Hz trap frequency, 42.5Hz XDT trap frequency, 2.63 um/V
% mod_strength_list = calc_drive(2.7,2*pi*48,0.8,freq_list); %Inputs: (Temp (t), Gamma (s^-1), desired amp (um), drive frequency list (Hz))

rand_ind = [1];% Randomize the modulation frequencies
% rand_ind = rand_ind(randperm(numel(rand_ind)));

% Lattice pulse depth
pulse_list = [1];[6 5.5];%tbd [6.5 6 5 5 5 4.5 4.5];
pulse_list = pulse_list([rand_ind]);
 
% B field list
field_list = [201.1];[190 195 199.4 200.4 200.65 200.9 201.1]; 
field_list = field_list([rand_ind]);

% Gamma guesses for T = 2.8t, n=.08/2, in s^-1 
Gamma_list = [230];2*pi*563.4*.04*.96*[0.45 1.34];[0.45 0.6 1.17 1.6 1.77 1.9 2.2]; [1.34 1.9];
Gamma_list = Gamma_list([rand_ind]);

% evaporation depths
power_conductivity_list = [0.0546]; [0.0637];

vert_disp = [6];

loop = 1;
for bb = 1:length(field_list)  
    B = field_list(bb);
    pulse_depth = pulse_list(bb);
    power_conductivity = power_conductivity_list(bb);
    mod_strength_list = calc_drive(2.5,Gamma_list(bb),1,freq_list);
    
    for ii = 1:length(freq_list)
        % Get the current modulation frequency
        f = freq_list(ii);   
     

        mod_strength = mod_strength_list(ii);
        mod_strength = min([mod_strength 4]);
%         mod_strength = 0.6;

        out = struct;   
        out.SequenceFunctions   = {@main_settings,@(curtime) ...
            ac_conductivity(curtime,f,B,power_conductivity,pulse_depth,mod_strength,mod_ramp_time,Nplane,vert_disp),@main_sequence};
    %     npt.CycleStartFcn       = @cycleStart;
    %     npt.CycleCompleteFcn    = @cycleComplete;
    %     npt.JobCompleteFcn      = @jobComplete;

        out.CycleEnd = 17;    
    %     out.CycleEnd = 30;

        out.WaitMode = 2;
        out.WaitTime = 90;
        out.JobName             = [num2str(ii) ' shake, Plane Shift ' num2str(Nplane) ', ' num2str(f) ' Hz, ' ...
            num2str(B) 'G, ' num2str(1e3*power_conductivity) ' mW, ' num2str(pulse_depth) ' Er pulse, ' num2str(mod_strength) ' V, ' ...
            num2str(mod_ramp_time) ' ms ramp'];
        out.SaveDir         = out.JobName;    
        J(loop) = sequencer_job(out);
        loop = loop+1;
    end
end

end

