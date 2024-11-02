function J = job_default

    if nargin==0
        npt = struct;
    end

    function default_cycle_complete_fcn
        disp('cycle complete function');
    end

    function default_cycle_start_fcn
        disp('cycle start function');
        disp('oop')
        keyboard
    end

    function default_job_complete_fcn
        disp('job complete function');
    end

%% Create Job File
out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @main_sequence};
out.CyclesRequested   = inf;
out.JobName               = ['default job'];

out.CycleStartFcn         = @default_cycle_start_fcn;
out.CycleCompleteFcn      = @default_cycle_complete_fcn;
out.JobCompleteFcn        = @default_job_complete_fcn;

%% Output Job File
J = sequencer_job(out);

end

