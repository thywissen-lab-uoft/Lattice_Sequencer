function J = job_single_plane_focus_feedback(npt)
% Creates job file for feedback on stripes and focus

if nargin==0
   npt = struct; 
end
if nargin==0
    npt = struct;
end

if ~isfield(npt,'xdtB_evap_power')
    npt.xdt_B_evap_power = 0.08;
end

if ~isfield(npt,'lattice_load_feshbach_field')
    npt.lattice_load_feshbach_field = 201;
end

if ~isfield(npt,'NumCycles')
   npt.NumCycles=4; 
end


%% Sequence Modifier Function
    function curtime = focus_seq(curtime)
        global seqdata         
        defVar('xdtB_evap_power',npt.xdt_B_evap_power,'W');
        defVar('lattice_load_feshbach_field',npt.lattice_load_feshbach_field,'G'); 
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 0;           
        seqdata.flags.lattice_fluor_multi_mode      = 2;
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
        data = getRecentGuiData(4);  % CF : DONT TOUCH THIS W/O TALKING TO ME, oKAY CF CHANGED IT BUT IT SHOULD REALLY UST BE A BIG NMBER FIX THIS BUG LATER
        feedback_focus(data);
   end

%% Create Job Object
out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @focus_seq,...
    @main_sequence};
out.CycleCompleteFcn      = @cycle_complete_fcn_focus;
out.CycleEnd   = npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName  = ['focus feedback'];
out.SaveDir  = 'focus';
J = sequencer_job(out);

end

