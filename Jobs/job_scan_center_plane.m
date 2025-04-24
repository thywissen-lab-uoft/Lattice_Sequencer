function J = job_scan_center_plane(npt)
% Creates a job for running a single plane.

if nargin==0
    npt = struct;
end

if ~isfield(npt,'xdtB_evap_power')
    npt.xdt_B_evap_power = 0.0645;
end

if ~isfield(npt,'lattice_load_feshbach_field')
    npt.lattice_load_feshbach_field = 195;
end

if ~isfield(npt,'NumCycles')
   npt.NumCycles=20; 
end

%% Sequence Modifier Function

function curtime = scan_center_plane(curtime,ODT1_onebeam,ODT2_onebeam,ODT1_vert_ramp,ODT2_vert_ramp,lattice_load_depth,lattice_load_time,lattice_load_field)
    global seqdata         
    defVar('xdtB_evap_power',0.057,'W');
    defVar('lattice_load_feshbach_field',lattice_load_field,'G');  %npt.lattice_load_feshbach_field;       
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
    
    seqdata.flags.qgm_doPlaneShift = 1;
    % CF : Who keeps on changnig this to spacings of 1; keep it at 2
    defVar('qgm_planeShift_N',[1],'plane'); 

%   Turn off one of the dipole trap beams to measure its position
    seqdata.flags.xdtB_one_beam_ODT1 = ODT1_onebeam;
    seqdata.flags.xdtB_one_beam_ODT2 = ODT2_onebeam;
    
    % Ramp Vertical Piezo of ODT1 or ODT2
    seqdata.flags.xdtB_vert_piezo_ramp_ODT1   = ODT1_vert_ramp;
    seqdata.flags.xdtB_vert_piezo_ramp_ODT2   = ODT2_vert_ramp;
    defVar('xdtB_vert_piezo_ramp_time',[100],'ms');         
    defVar('xdtB_vert_piezo_ramp_value_1',5,'V');
    defVar('xdtB_vert_piezo_ramp_value_2',[5],'V');
%     
%     offset = defVar('tilt_notilt_shift',[100:10:170],'kHz');
%     notilt = getVar('qgm_plane_uwave_frequency_offset_tilt') + getVar('tilt_notilt_shift');
%     defVar('qgm_plane_uwave_frequency_offset_notilt',notilt,'kHz');
%     defVar('qgm_plane_uwave_frequency_amplitude_notilt',10,'kHz');

% % %     % Lattice Load Settings
    defVar('lattice_load_time',[lattice_load_time],'ms');750;
    defVar('lattice_load_depthX',lattice_load_depth,'Er');2.5;
    defVar('lattice_load_depthY',lattice_load_depth,'Er');2.5;
    defVar('lattice_load_depthZ',lattice_load_depth,'Er');2.5;
    
    % Ramp XDT powers after loading
    seqdata.flags.lattice_load_xdt_ramp_power = 1;
    defVar('lattice_load_xdt1_ramp_power',[0.100],'W');
    defVar('lattice_load_xdt2_ramp_power',[0.300],'W');
    defVar('lattice_load_xdt_ramp_time',[100],'ms'); 
    
    % Snap XDT powers back
    seqdata.flags.lattice_load_xdt_snap_power = 1;
    defVar('lattice_load_xdt1_snap_power',[0.198],'W');
    defVar('lattice_load_xdt2_snap_power',[0.088],'W');
    defVar('lattice_load_xdt_snap_time',[0.1],'ms'); 
    defVar('lattice_load_xdt_hold_time',[2 20 12 25],'ms'); 
    
    
end

%% Create Job File
clear J

%Choose which ODT to turn on during a one beam sequence
ODT1_onebeam = 0;
ODT2_onebeam = 0;

%Choose whether to ramp one of the ODTs
ODT1_vert_ramp = 0;
ODT2_vert_ramp = 0;

%Choose whether to pin or do science depth
lattice_load_depth = 2.5; 70; 2.5; 
lattice_load_time = 750; 0.2; 750;

% Choose the field
field = 200.6;

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) ...
    scan_center_plane(curtime,ODT1_onebeam,ODT2_onebeam,ODT1_vert_ramp,ODT2_vert_ramp,lattice_load_depth,lattice_load_time,field),...
    @main_sequence};
out.CycleEnd   = 13;npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName         = ['scan center plane ' 'Beams ' num2str([ODT1_onebeam ODT2_onebeam]) ', Ramps ' num2str([ODT1_vert_ramp ODT2_vert_ramp]) ', Lattice Load ' num2str(lattice_load_depth) ' Er, ' 'evap' num2str(1e3*0.054) ' mW, '  num2str(195) ' G' ];
out.SaveDir         = out.JobName;  
%% Output Job File
J = sequencer_job(out);

end

