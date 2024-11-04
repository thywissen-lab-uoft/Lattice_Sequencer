function j=job_optimize_DFG

% Sequence Modifier File
    function curtime = seq_mod(curtime)
        global seqdata;
        seqdata.flags.xdt = 0;
%         
%         m_loop = load('m_loop.mat');
%         
%         p1 = m_loop.p1;
%         p2 = m_loop.p3;
%         p3 = m_loop.p3;
%         
%         defVar('p1',p1);
%         defVar('p2',p2);
%         defVar('p3',p3);        
    end

% This function evaluates at the end of each cycle
    function cycleComplete
        disp('hi');
        
%         val = job.GetData;
%         
%         % make the cost function        
%         C = val;
%         
%         % Save it to disk.
%         save('blah blah.mat',C)        
        
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
npt.JobName             = 'DFG Optimize';
npt.SequenceFunctions   = {@main_settings,@seq_mod,@main_sequence};
npt.ScanCyclesRequested = 2;
npt.CycleStartFcn       = @cycleStart;
npt.CycleCompleteFcn    = @cycleComplete;
npt.JobCompleteFcn      = @jobComplete;
npt.SaveDirName         = 'DFG Optimize Test';

% Make the job
j = sequencer_job(npt);
    
end

