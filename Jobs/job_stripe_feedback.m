function J = job_stripe_feedback(npt)
% Creates job file for feedback on stripes and focus

if nargin ~=1
    npt=struct;
end


%% Sequence Modifier Function
% Stripe Feedback Sequence
    function curtime = stripe_seq(curtime)
        global seqdata         
        defVar('xdtB_evap_power',evap_depth_stripe,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
        defVar('qgm_planeShift_N',plane_shift,'plane');% ALWAYS AN INTERGER
        seqdata.flags.do_plane_selection            = 1;
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 1;           
        seqdata.flags.lattice_fluor_multi_mode      = 0; % 0: one image 2 :piezo multi shot
    end

% Fidelity Feedback Sequence
    function curtime = fidelity_seq(curtime)
        global seqdata
        defVar('xdtB_evap_power',evap_depth_fidelity,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
        defVar('qgm_planeShift_N',plane_shift,'plane');% ALWAYS AN INTERGER
        seqdata.flags.do_plane_selection            = 1;
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 0;           
        seqdata.flags.lattice_fluor_multi_mode      = 1;
    end

% Focus Feedback Sequence
    function curtime = focus_seq(curtime)
        global seqdata
        defVar('xdtB_evap_power',evap_depth_focus,'W');
        defVar('lattice_load_feshbach_field',field,'G'); 
        defVar('qgm_planeShift_N',plane_shift,'plane');% ALWAYS AN INTERGER
        seqdata.flags.do_plane_selection            = 1;
        seqdata.flags.lattice_conductivity_new      = 0; 
        seqdata.flags.plane_selection_dotilt        = 0;           
        seqdata.flags.lattice_fluor_multi_mode      = 2;
    end



%% Cycle Complete Function
%     CycleStartFcn           % user custom function to evalulate before sequence runs
%     CycleCompleteFcn        % user custom function to evaluate after the cycle

%% Cycle Complete Function    
   function cycle_complete_fcn_stripe(obj)       
        obj;    
        global seqdata
        if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ...
                ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
            warning('No feedback directory to run on');
        return;    
        end              
         data = getRecentGuiData(50);      
         doFeedback = 1;                  
         doExitPID = feedback_stripe(data,doFeedback);           
%        Use this code to allow feedback to end itself % 2025.04.02 minimum 3 shots
         if doExitPID && (obj.CycleNow > 2)
            obj.CycleNow = obj.CycleEnd; 
         end
   end

   function cycle_complete_fcn_focus(obj)       
        obj;     
        global seqdata
        if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ...
                ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
            warning('No feedback directory to run on');
        return;    
        end              
        data = getRecentGuiData(50); 
        doFeedback = 1;
        doExitPID=feedback_focus(data,doFeedback);    
        % Use this code to allow feedback to end itself % 2025.04.02 minimum 2 shots
         if doExitPID && (obj.CycleNow > 1)
            obj.CycleNow = obj.CycleEnd; 
         end
   end
%% Useful Settings
% This is terrible coding. CJF Will figure out a better way to structure
% things

plane_shift             = -1;
field                   = 201.1;
evap_depth_stripe       = 0.1;
evap_depth_focus        = 0.055;
evap_depth_fidelity     = 0.055;
%% Overrides
if isfield(npt,'lattice_load_feshbach_field')
    field = npt.lattice_load_feshbach_field;
end

%% Job Names
str_stripe = ['stripe : plane=' num2str(plane_shift) ',' ...
    'field=' num2str(field) ',' ...
    'evap2=' num2str(evap_depth_stripe)];
str_focus = ['focus : plane=' num2str(plane_shift) ',' ...
    'field=' num2str(field) ',' ...
    'evap2=' num2str(evap_depth_focus)];
str_fidelity = ['fidelity : plane=' num2str(plane_shift) ',' ...
    'field=' num2str(field) ',' ...
    'evap2=' num2str(evap_depth_fidelity)];


%% Create Job Object : STRIPE
out_stripe = struct;
out_stripe.SequenceFunctions       = {...
    @main_settings,@(curtime) ...
    stripe_seq(curtime),@main_sequence};
out_stripe.CycleCompleteFcn        = @cycle_complete_fcn_stripe;
out_stripe.CycleEnd                = 6;
out_stripe.WaitMode                = 2;
out_stripe.WaitTime                = 90;
out_stripe.JobName                 = str_stripe;
out_stripe.SaveDir                 = 'stripe';

Jstripe = sequencer_job(out_stripe);
Jstripe.CycleCompleteFcn=@() cycle_complete_fcn_stripe(Jstripe);

%% Create Job Object : FOCUS
out_focus = struct;
out_focus.SequenceFunctions       = {...
    @main_settings,@(curtime) ...
    focus_seq(curtime),@main_sequence};
out_focus.CycleCompleteFcn        = @cycle_complete_fcn_focus;
out_focus.CycleEnd                = 3;
out_focus.WaitMode                = 2;
out_focus.WaitTime                = 90;
out_focus.JobName                 = str_focus;
out_focus.SaveDir                 = 'focus';

Jfocus = sequencer_job(out_focus);
Jfocus.CycleCompleteFcn=@() cycle_complete_fcn_focus(Jfocus);
%% Create Job Object : FIDELITY
out_fidelity = struct;
out_fidelity.SequenceFunctions       = {...
    @main_settings,@(curtime) ...
    fidelity_seq(curtime),@main_sequence};
out_fidelity.CycleEnd                = 1;
out_fidelity.WaitMode                = 2;
out_fidelity.WaitTime                = 90;
out_fidelity.JobName                 = str_fidelity;
out_fidelity.SaveDir                 = 'fidelity';

Jfidelity = sequencer_job(out_fidelity);
%% Output

J = Jstripe;
J(end+1)=Jfocus;        % Uncomment line if you want to feedback focus
J(end+1)=Jfidelity;     % Uncomment line if you want to measure fidelity

end

