function J = job_default

    if nargin==0
        npt = struct;
    end

    function default_cycle_complete_fcn
        disp('cycle complete function');
    end

    function default_cycle_start_fcn
        disp('cycle start function');
    end

    function default_job_complete_fcn
        disp('job complete function');
    end

%% Create Job File
out = struct;
out.SequenceFunctions       = {@main_settings,@main_sequence};
out.WaitMode                = 2;
out.WaitTime                = 90;


out.SequenceFunctions       = {@test_sequence};
out.WaitMode                = 1;
out.WaitTime                = 5;


out.CyclesRequested         = 5;
out.JobName                 = 'JobDefault';
out.CycleStartFcn           = @default_cycle_start_fcn;
out.CycleCompleteFcn        = @default_cycle_complete_fcn;
out.JobCompleteFcn          = @default_job_complete_fcn;
out.SaveDir                 = 'NewData';


%% Output Job File

J = sequencer_job(out);

end

