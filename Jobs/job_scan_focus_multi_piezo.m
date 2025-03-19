function J = job_scan_focus_multi_piezo
% Creates job file for feedback on stripes and focus

varList = [-.3:.05:.3];


npt = struct;
npt.xdt_B_evap_power = 0.058;
npt.lattice_load_feshbach_field = 201;
npt.NumCycles=length(varList); 

%% Sequence Modifier Function
    function curtime = focus_seq(curtime,plane_shift)
        global seqdata
        seqdata.flags.do_plane_selection            = 1;
        defVar('xdtB_evap_power',npt.xdt_B_evap_power,'W');
        defVar('lattice_load_feshbach_field',npt.lattice_load_feshbach_field,'G'); 
        defVar('qgm_planeShift_N',plane_shift,'plane');% ALWAYS AN INTERGER
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 0;           
        seqdata.flags.lattice_fluor_multi_mode      = 2;        
        seqdata.flags.misc_moveObjective            = 1; % update ojective piezo position
        defVar('objective_piezo',[5.95]+varList,'V');
    end

%% Create Job Object

plane_shift = 7;

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) ...
    focus_seq(curtime,plane_shift),...
    @main_sequence};
out.CycleEnd   = npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName  = ['focus check multi shot, Plane Shift ' num2str(plane_shift)];
out.SaveDir  = 'focus camera piezo scan';
J = sequencer_job(out);

end

