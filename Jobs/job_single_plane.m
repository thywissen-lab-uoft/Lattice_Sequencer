function J = job_single_plane(npt)
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

function curtime = one_plane(curtime)
    global seqdata         
    defVar('xdtB_evap_power',0.058,'W');
    defVar('lattice_load_feshbach_field',195,'G');  %npt.lattice_load_feshbach_field;       
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
    
    seqdata.flags.qgm_doPlaneShift = 1;
    defVar('qgm_planeShift_N',[7],'plane');    
    
    % Pulse lattice
    seqdata.flags.xdtB_pulse_lattice            = 0;
    defVar('xdtb_lattice_load_time',0.1,'ms');
    defVar('xdtb_lattice_depth',[1],'Er');
    defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
    defVar('xdtb_lattice_pulse_equil_time',[100],'ms');
    
    % CJF : This is now obselete. please see my comment FC/RL 
%     seqdata.flags.xdtB_odt1_piezo_vert_disp          = 0;
%     defVar('xdtB_odt1_piezo_vert_disp_amplitude',[5],'V');  
    
% %     Turn off one of the dipole trap beams to measure its position
    seqdata.flags.xdtB_one_beam_ODT1            = 0;
    seqdata.flags.xdtB_one_beam_ODT2            = 0;
    
%     % Ramp Vertical Piezo of ODT1 or ODT2
    seqdata.flags.xdtB_one_beam_ODT1 = 0;
    seqdata.flags.xdtB_one_beam_ODT2 = 1;
    defVar('xdtB_vert_piezo_ramp_time',[100],'ms');         
    defVar('xdtB_vert_piezo_ramp_value_1',5,'V');
    defVar('xdtB_vert_piezo_ramp_value_2',[0:1:10],'V');

            
% %     % Lattice Load Settings
    defVar('lattice_load_time',[.2],'ms');750;
    defVar('lattice_load_depthX',70,'Er');2.5;
    defVar('lattice_load_depthY',70,'Er');2.5;
    defVar('lattice_load_depthZ',70,'Er');2.5;                
end

%% Create Job File

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @one_plane,...
    @main_sequence};
out.CycleEnd   = 13;npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName             = ['ODT1 only scan plane shift ' num2str(1e3*0.058) ' mW, '  num2str(npt.lattice_load_feshbach_field) ' G' ];
out.SaveDir         = out.JobName;  
%% Output Job File
J = sequencer_job(out);

end

