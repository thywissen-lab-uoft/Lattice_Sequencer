function J=job_conducivity_quench
   
%% Quench Sequnece Modifier
% THIS CODE IS UGLY AND CONFUSING, NEEDS TO BE FIXED
 function curtime = quench_conductivity(curtime,field,evap_depth,pulse_depth,mod_strength,mod_ramp_time,Nplane_shift)
        global seqdata;        
        
        % Optical Evaporation        
        defVar('xdtB_evap_power',evap_depth,'W');
        % Magnetic Field in Lattice
        seqdata.flags.lattice_load_feshbach_ramp  = 1;
        defVar('lattice_load_feshbach_field',field,'G'); 
    
         %Set the displacement parameters       
        seqdata.flags.lattice_conductivity_new      = 1;  
        % Conductivity       
        seqdata.flags.conductivity_ODT1_mode            = 2; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_ODT2_mode            = 2; % 0:OFF, 1:SINE, 2:DC
        seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction 
        
        %Enable snap for trap frequency measurements
        seqdata.flags.conductivity_snap_and_hold        = 1; 
        defVar('conductivity_snap_and_hold_time',[0:3:54],'ms');
        defVar('piezo_diabat_ramp_time',4,'ms'); %How fast to snap back to zero displacement
        
        %Change to ODT1 if displacing along Y
%         defVar('conductivity_ODT1_mod_amp',mod_strength,'V');  % ODT1 Displacement
        defVar('conductivity_ODT2_mod_amp',mod_strength,'V');  % ODT2 Displacement
        
        defVar('conductivity_mod_ramp_time',mod_ramp_time,'ms');  %How fast we initially displace the beams         
        defVar('conductivity_mod_time',50,'ms'); % 200 ms for force calibration;  
        
        %Choose the plane to image
        defVar('qgm_planeShift_N',(Nplane_shift),'plane');
        
        % Pulse lattice
        seqdata.flags.xdtB_pulse_lattice            = 1;
        defVar('xdtb_lattice_load_time',0.1,'ms');
        defVar('xdtb_lattice_depth',[pulse_depth],'Er');
        defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
        defVar('xdtb_lattice_pulse_equil_time',[100],'ms');
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        d = load('f_offset.mat');
        f_offset = d.f_offset;% - 1*20;        
        defVar('f_offset',f_offset,'kHz'); 
 end
%% Quench Conductivity Job
clear J

% Magnetic Field (G)
% B_conductivity = 201.1;
% Optical Evaporation Power (W)
power_conductivity = 0.066; 
% Conductivity modulation ramp up time (ms)
mod_ramp_time = 50;


% Choose how many plane from center to shift by
Nplane = [-8]; 


mod_strength = [4];

rand_ind = [1:1:2];% Randomize the modulation frequencies
rand_ind = rand_ind(randperm(numel(rand_ind)));

% Lattice pulse depth
% pulse_list = [4.5 3.5];%tbd 
% pulse_list = [6.5 6 5 5 5 4.5 4.5];
pulse_list = [4 2];
pulse_list = pulse_list([rand_ind]);
 
%xdtB lattice pulse depth
% field_list = [190 200];
% field_list = [190 195 199.4 200.4 200.65 200.9 201.1]; 
field_list = [190 201.1];
field_list = field_list([rand_ind]);

loop = 1;
for bb = 1:length(field_list)  
    B = field_list(bb);
    pulse_depth = pulse_list(bb);
    
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        quench_conductivity(curtime,B,power_conductivity,pulse_depth,mod_strength,mod_ramp_time,Nplane),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;

    out.CycleEnd = 19;    
%     out.CycleEnd = 30;

    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = [num2str(bb) ' quench, Plane Shift ' num2str(Nplane) ', ' ...
        num2str(B) 'G,' num2str(1e3*power_conductivity) ' mW, ' num2str(pulse_depth) ' Er pulse, ' num2str(mod_strength) ' amp, ' ...
        num2str(mod_ramp_time) ' ms ramp'];
    out.SaveDir         = out.JobName;    
    J(loop) = sequencer_job(out);
    loop = loop+1;

end

end

