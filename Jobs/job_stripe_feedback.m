function J = job_stripe_feedback(npt)
% Creates job file for feedback on stripes and focus

if nargin==0
   npt = struct; 
end
if nargin==0
    npt = struct;
end

if ~isfield(npt,'xdtB_evap_power')
    npt.xdt_B_evap_power = 0.1;
end

if ~isfield(npt,'lattice_load_feshbach_field')
    npt.lattice_load_feshbach_field = 201;
end

if ~isfield(npt,'NumCycles')
   npt.NumCycles=6; 
end

field      = 201.1;
evap_depth = 0.11;


%% Sequence Modifier Function
    function curtime = stripe_seq(curtime,plane_shift)
        global seqdata         
        defVar('xdtB_evap_power',evap_depth,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
        defVar('qgm_planeShift_N',plane_shift,'plane');% ALWAYS AN INTERGER
        seqdata.flags.do_plane_selection            = 1;
        seqdata.flags.lattice_conductivity_new      = 1; 
        seqdata.flags.plane_selection_dotilt        = 1;           
        seqdata.flags.lattice_fluor_multi_mode      = 0; % 0: one image 2 :piezo multi shot
    end

%% Cycle Complete Function
%     CycleStartFcn           % user custom function to evalulate before sequence runs
%     CycleCompleteFcn        % user custom function to evaluate after the cycle

%% Cycle Complete Function    
   function cycle_complete_fcn_focus
        global seqdata
        if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ...
                ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
            warning('No feedback directory to run on');
        return;    
        end              
         data = getRecentGuiData(50);  % CF : DONT TOUCH THIS W/O TALKING TO ME
         feedback_stripe(data);        
   end

%% Create Job Object

plane_shift = 0;

out = struct;
out.SequenceFunctions   = {...
    @main_settings,@(curtime) ...
    stripe_seq(curtime,plane_shift),@main_sequence};
out.CycleCompleteFcn      = @cycle_complete_fcn_focus;
out.CycleEnd       = npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
% out.JobName               = ['stripe and focus feedback'];
out.JobName               = ['stripe feedback, Plane Shift ' num2str(plane_shift)];
out.SaveDir = 'stripe';

J = sequencer_job(out);

end

