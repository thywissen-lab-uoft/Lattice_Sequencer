function J=job_conducivity_ac_shake
   
%% AC Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = ac_conductivity(curtime,freq,field,evap_depth,pulse_depth,mod_strength,mod_ramp_time,Nplane_shift,lattice_load_depth)
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
        % Cross-thermalization
        seqdata.flags.conductivity_cross_thermalize     = 0; % Wait after modulating
        defVar('conductivity_cross_thermalize_time',[0],'ms'); % Wait time after modulating for cross-thermalization
        
        %Choose the plane to image
        defVar('qgm_planeShift_N',(Nplane_shift),'plane');
        
        % Pulse lattice
        seqdata.flags.xdtB_pulse_lattice            = 1;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',pulse_depth,'Er');
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
        
%         tvec = [1 10 20 30 40 50 75 100 150 200 300 400 500 1000];
%         tvec = 50;
        defVar('conductivity_mod_time',tvec,'ms');200;
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
        defVar('f_offset',f_offset,'kHz'); 
        
        % % %     % Lattice Load Settings
        defVar('lattice_load_time',[750],'ms');750;
        defVar('lattice_load_depthX',2.78,'Er');lattice_load_depth;2.5;
        defVar('lattice_load_depthY',2.44,'Er');lattice_load_depth;2.5;
        defVar('lattice_load_depthZ',2.84,'Er');lattice_load_depth;2.5;     
        
%         % Ramp XDT powers after loading
%         seqdata.flags.lattice_load_xdt_ramp_power = 0;
%         defVar('lattice_load_xdt1_ramp_power',[0.100],'W');
%         defVar('lattice_load_xdt2_ramp_power',[0.175],'W');
%         defVar('lattice_load_xdt_ramp_time',[100],'ms'); 
% 
%         % Snap XDT powers back
%         seqdata.flags.lattice_load_xdt_snap_power = 0;
%         defVar('lattice_load_xdt1_snap_power',[0.198],'W');
%         defVar('lattice_load_xdt2_snap_power',[0.088],'W');
%         defVar('lattice_load_xdt_snap_time',[0.1],'ms'); 
%         defVar('lattice_load_xdt_hold_time',hold_time,'ms'); 
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
Nplane = [-7]; 

% Modulation Frequencies
% freq_list = [20 30 40 45 50 55 60 65 68 70 72 75 80 85 90 100];
% freq_list = [20 30 35 40 45 48 50 52 55 57 60 65 75 90 100];
freq_list = [70 75 80 85];[10:10:120 45 65 55];
% freq_list = [55];

% Randomize the modulation frequencies
freq_list = freq_list(randperm(numel(freq_list)));

% freq_list = [160 freq_list];
%55Hz trap frequency, 42.5Hz XDT trap frequency, 2.63 um/V
% mod_strength_list = calc_drive(2.7,2*pi*48,0.8,freq_list); %Inputs: (Temp (t), Gamma (s^-1), desired amp (um), drive frequency list (Hz))

% rand_ind = [1];% Randomize the modulation frequencies
% rand_ind = rand_ind(randperm(numel(rand_ind)));

 
% B field list
% field_list = [201.1];[190 195 199.4 200.4 200.65 200.9 201.1]; 
% field_list = [190 195 198.5 200 200.35 200.6 200.9 201.1];
B = [201.107];
% field_list = field_list([rand_ind]);

% Gamma guesses for T = 2t, nup_peak=.08, in s^-1 
Gamma_list = [210];
% Gamma_list = [210];
% Gamma_list = Gamma_list([rand_ind]);

T_list = [2.7]; %t
% T_list = 3.5;
% evaporation depths
power_conductivity_list = 0.0538; [0.0536 0.054]; [0.0637];

% Lattice pulse depth
pulse_list = 0; [0 0];[6 5.5];%tbd [6.5 6 5 5 5 4.5 4.5];

% mod_strength_list = [3 4];
% lattice load depth
lattice_load_depth = 2.5;

% thold = [0:1:10 12 15 17 20 25 30];
% thold = [0:5:25 30 40 50 75 100 125 150 200 250 300 400];

loop = 1;
for pp = 1:length(power_conductivity_list)  
    power_conductivity = power_conductivity_list(pp);
    pulse_depth = pulse_list(pp);%(bb);
%     mod_strength = mod_strength_list(pp);
    mod_strength_list = calc_drive(T_list(pp),Gamma_list(pp),1.2,freq_list);
    
    for ii = 1:length(freq_list)
        % Get the current modulation frequency
        f = freq_list(ii);   
%         if f >= 90
%             mod_strength = 4;
%         else
%             mod_strength = 3;
%         end
        mod_strength = mod_strength_list(ii);
        mod_strength = min([mod_strength 4]);
%         mod_strength = 4;

        out = struct;   
        out.SequenceFunctions   = {@main_settings,@(curtime) ...
            ac_conductivity(curtime,f,B,power_conductivity,pulse_depth,mod_strength,mod_ramp_time,Nplane,lattice_load_depth),@main_sequence};
    %     npt.CycleStartFcn       = @cycleStart;
    %     npt.CycleCompleteFcn    = @cycleComplete;
    %     npt.JobCompleteFcn      = @jobComplete;
        out.CycleEnd = 17;  
        out.WaitMode = 2;
        out.WaitTime = 90;
        out.JobName             = [num2str(ii) ' shake, Plane Shift ' num2str(Nplane) ', ' num2str(f) ' Hz, ' ...
            num2str(B) 'G, ' num2str(1e3*power_conductivity) ' mW, ' num2str(lattice_load_depth) ' Er load, ' num2str(pulse_depth) ' Er pulse, ' num2str(mod_strength) ' V, ' ...
            num2str(mod_ramp_time) ' ms ramp'];
%         out.JobName             = ['3.5 ER Joule heating, 201.1 G, evap 54 mW, 50 ms ramp, 200 ms, 1 V'];
%         out.JobName             = ['3.5 ER Joule heating, FAKE DRIVE, 200 ms hold, 50 ms ramp, 195 G, evap 54 mW, 1 ER pulse'];
%         out.JobName             = [num2str(ii) ' cross thermalize, Plane Shift ' num2str(Nplane) ', ' ...
%             num2str(B) 'G, ' num2str(1e3*power_conductivity) ' mW, ' num2str(lattice_load_depth) ' Er load'];
        out.SaveDir         = out.JobName;    
        J(loop) = sequencer_job(out);
        loop = loop+1;
    end
end

end

