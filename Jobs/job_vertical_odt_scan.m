function J = job_vertical_odt_scan
% Job function to optimize the ODT positions


%% Sequence Modifier Function

function curtime = vertical_odt_scan(curtime,ODT1_onebeam,ODT2_onebeam,ODT1_vert_ramp,ODT2_vert_ramp,lattice_load_depth,lattice_load_time)
    global seqdata         
    defVar('xdtB_evap_power',0.054,'W');
    defVar('lattice_load_feshbach_field',201.107,'G');  %npt.lattice_load_feshbach_field;       
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
    
    seqdata.flags.qgm_doPlaneShift = 1;
    defVar('qgm_planeShift_N',[-8 -2 -5],'plane');
    
%   Turn off one of the dipole trap beams to measure its position
    seqdata.flags.xdtB_one_beam_ODT1            = ODT1_onebeam;
    seqdata.flags.xdtB_one_beam_ODT2            = ODT2_onebeam;
    
    % Ramp Vertical Piezo of ODT1 or ODT2
    seqdata.flags.xdtB_vert_piezo_ramp_ODT1   = ODT1_vert_ramp;
    seqdata.flags.xdtB_vert_piezo_ramp_ODT2   = ODT2_vert_ramp;
    defVar('xdtB_vert_piezo_ramp_time',[100],'ms');         
    defVar('xdtB_vert_piezo_ramp_value_1',5,'V');
    defVar('xdtB_vert_piezo_ramp_value_2',[5],'V');3:0.5:8;

% % %     % Lattice Load Settings
    defVar('lattice_load_time',[lattice_load_time],'ms');750;
    defVar('lattice_load_depthX',2.78,'Er');2.78;
    defVar('lattice_load_depthY',2.44,'Er');2.44;
    defVar('lattice_load_depthZ',2.84,'Er');2.84;                
end

%% Create Job File

%**Flags**

%Choose which ODT to turn on during a one beam sequence
ODT1_onebeam = 0;
ODT2_onebeam = 0;

%Choose whether to ramp one of the ODTs
ODT1_vert_ramp = 0;
ODT2_vert_ramp = 0;

%**Params**

%Choose whether to pin or do science depth
lattice_load_depth = 2.5; 70; 2.5; 
lattice_load_time = 750; 0.2; 750; 

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) ...
    vertical_odt_scan(curtime,ODT1_onebeam,ODT2_onebeam,ODT1_vert_ramp,ODT2_vert_ramp,lattice_load_depth,lattice_load_time),...
    @main_sequence};
out.CycleEnd   = 13; %npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName         = ['Center plane scan, ' 'Beams ' num2str([ODT1_onebeam ODT2_onebeam]) ', Ramps ' num2str([ODT1_vert_ramp ODT2_vert_ramp]) ', Lattice Load ' num2str(lattice_load_depth) 'ER, evap ' num2str(1e3*0.054) ' mW, '  num2str(201.107) ' G' ];
out.SaveDir         = out.JobName;  
%% Output Job File
J = sequencer_job(out);

end

