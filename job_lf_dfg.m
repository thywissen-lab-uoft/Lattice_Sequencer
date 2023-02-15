function j=job_lf_dfg

% Sequence File
    function curtime = seq_mod(curtime)
        global seqdata;
        seqdata.flags.lattice   = 1;
        
        m_loop = load('m_loop.mat');
        
        p1 = m_loop.p1;
        p2 = m_loop.p3;
        p3 = m_loop.p3;
        
        defVar('p1',p1);
        defVar('p2',p2);
        defVar('p3',p3);        
    end

% This function evaluates at the end of each cycle
    function cycleComplete(job)
        val = job.GetData;
        
        % make the cost function        
        C = val;
        
        % Save it to disk.
        save('blah blah.mat',C)        
        
        % how to loop with m_loop?
    end

% This function evaluates at the end of the job
    function jobComplete(job)
       % Other stuff
    end

% Sequence functions to run
seqs = {@main_settings,@seq_mod,@main_sequence};

% Job Name
name = 'DFG Optimize';

% number of cycles in the job ([] and 0 are infinity)
N = [];

% add it to the queue
j = sequencer_job(seqs,name,N,@cycleComplete);
    
end

