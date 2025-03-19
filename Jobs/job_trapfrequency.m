function J=job_trapfrequency
%% Trap Frequency Measurement Sequence Modifier
 function curtime = trapfreq(curtime,ODT1_power,ODT2_power,field,evap_depth,mod_strength,mod_ramp_time,UX,UY,UZ,uwave_freq_amp,vert_disp)
        global seqdata;        
        
        %Set the evap depth
        defVar('xdtB_evap_power',evap_depth,'W');
        
        %Keep atoms spin-polarized
        seqdata.flags.xdtB_rf_mix                   = 0;
        seqdata.flags.xdtB_rf_mix_post_evap         = 0;
%         seqdata.flags.lattice_load_xdt_off        = 0; 
        
        %Set the final powers of the XDTs
        seqdata.flags.xdtB_ramp_power_end           = 1;
        defVar('xdtB_evap_end_ramp_power', ODT1_power,'W'); 0.195;
        defVar('xdtB_evap_end_ramp_power2', ODT2_power,'W'); 0.150;
        
        %Set the lattice depths
        defVar('lattice_load_depthX',UX,'Er');2.5;
        defVar('lattice_load_depthY',UY,'Er');2.5;
        defVar('lattice_load_depthZ',UZ,'Er');2.5;
        
        %Set plane shift
        seqdata.flags.qgm_doPlaneShift = 1;
        defVar('qgm_planeShift_N',9,'plane');% ALWAYS AN INTERGER
        
        %Set the field
        seqdata.flags.lattice_load_feshbach_ramp  = 1;
        defVar('lattice_load_feshbach_field',field,'G'); 
        
        %Set the displacement parameters       
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 2; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 2; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 2; % 1:X-direction 2:Y-direction 
        
        %Enable snap for trap frequency measurements
        seqdata.flags.conductivity_snap_and_hold        = 1; 
        defVar('conductivity_snap_and_hold_time',[0:1.5:36],'ms');[0:3:24 40:3:64];[0:1.5:36];[0:2.5:42.5];
        defVar('piezo_diabat_ramp_time',4,'ms'); %How fast to snap back to zero displacement
        
        %Change to ODT1 if displacing along Y
        defVar('conductivity_ODT1_mod_amp',mod_strength,'V');  % ODT1 Displacement
%         defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Displacement
        
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');  %How fast we initially displace the beams         
        defVar('conductivity_mod_time',50,'ms'); % 200 ms for force calibration
        
        
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
B = 201.1;

%Set final powers of ODTs in W
ODT1_power = 0.198;
ODT2_power = 0.088;

%Choose Lattice Depths
depthX = 2.5;
depthY = 2.5;
depthZ = 2.5;

% Optical Evaporation Power (W)
evap_depth = 0.054;0.065;

% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50; % 200 ms for force calibration

%Modulation amplitude (V)
mod_strength = [3]; %3 for XDT+lattice

%Choose the number of planes via uwave freq amplitude
uwave_freq_amp = 120;

vert_disp_list = [5];
vert_disp_list = vert_disp_list(randperm(numel(vert_disp_list)));

for ii = 1:length(vert_disp_list)
    vert_disp = vert_disp_list(ii);
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        trapfreq(curtime,ODT1_power,ODT2_power,B,evap_depth,mod_strength,mod_ramp_time,...
        depthX,depthY,depthZ,uwave_freq_amp,vert_disp),@main_sequence};
    out.CycleEnd = 25;
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = ['XDT and Lattice Y Trap Freq, ODTs (' num2str(ODT1_power*1e3) ',' num2str(ODT2_power*1e3) ') mW, (' ...
        num2str(depthX) ',' num2str(depthY) ',' num2str(depthZ), ') Er, ' num2str(B) ' G, ' num2str(1e3*evap_depth) ' mW, ' num2str(mod_strength) ' V amp, ' ...
        num2str(mod_ramp_time) ' ms ramp'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end
end

