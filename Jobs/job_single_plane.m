function J = job_single_plane(npt)
% Creates a job for running a single plane.

if nargin==0
    npt = struct;
end

if ~isfield(npt,'xdtB_evap_power')
    npt.xdt_B_evap_power = 0.065;
end

if ~isfield(npt,'lattice_load_feshbach_field')
    npt.lattice_load_feshbach_field = 201.1;
end

if ~isfield(npt,'NumCycles')
   npt.NumCycles=20; 
end

%% Sequence Modifier Function

function curtime = one_plane(curtime)
    global seqdata         
    defVar('xdtB_evap_power',npt.xdt_B_evap_power,'W');
    defVar('lattice_load_feshbach_field',npt.lattice_load_feshbach_field,'G');         
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
 
    defVar('objective_piezo',[5],'V');

%    seqdata.flags.qgm_doPlaneShift = 1;
%    defVar('qgm_planeShift_N',[-9:1:-3],'plane');
 
end

%% Create Job File

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @one_plane,...
    @main_sequence};
out.CycleEnd   = 10;npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName             = ['single plane ' num2str(1e3*npt.xdt_B_evap_power) ' mW, '  num2str(npt.lattice_load_feshbach_field) ' G' ];
out.SaveDir         = out.JobName;  
%% Output Job File
J = sequencer_job(out);

end

