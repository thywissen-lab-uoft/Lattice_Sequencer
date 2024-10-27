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
   npt.NumCycles=7; 
end

field      = 201.1;
evap_depth = 0.1;

%% Sequence Modifier Function
    function curtime = stripe_seq(curtime)
        global seqdata         
        defVar('xdtB_evap_power',evap_depth,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 1;           
        seqdata.flags.lattice_fluor_multi_mode      = 2;
        seqdata.flags.misc_PiezoFeedback            = 1;
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
        data = getRecentGuiData(30); 
        feedback_stripe(data);        
        feedback_focus(data);
   end

%% Create Job Object
out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @stripe_seq,...
    @main_sequence};
out.CycleCompleteFcn      = @cycle_complete_fcn_focus;
out.ScanCyclesRequested   = 1:npt.NumCycles;
out.JobName               = ['stripe and focus feedback'];
J = sequencer_job(out);

end

