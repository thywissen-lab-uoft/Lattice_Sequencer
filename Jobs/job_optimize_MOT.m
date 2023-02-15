function j=job_optimize_MOT

% Sequence Modifier File
    function curtime = seq_mod(curtime)
        global seqdata;
        seqdata.flags.xdt = 0;   
    end

% This function evaluates at the end of each cycle
    function cycleComplete
        disp('hi');
          
        
        % how to loop with m_loop?
    end

% This function evaluates at the start of each cycle
    function cycleStart
        disp('hi2');
    end

% This function evaluates at the end of the job
    function jobComplete
        disp('hi3');
    end

npt = struct;
npt.JobName             = 'MOT Optimize';
npt.SequenceFunctions   = {@main_settings,@seq_mod,@main_sequence};
npt.ScanCyclesRequested = 1:2;
npt.CycleStartFcn       = @cycleStart;
npt.CycleCompleteFcn    = @cycleComplete;
npt.JobCompleteFcn      = @jobComplete;
npt.SaveDirName         = 'MOT Optimize';

% Make the job
j = sequencer_job(npt);
    
end

