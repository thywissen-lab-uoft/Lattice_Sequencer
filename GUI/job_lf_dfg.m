function j=job_lf_dfg

    function curtime = seq_lf_dfg(curtime)
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

    function cycleComplete(job)
        val = job.GetData;
        
        % make the cost function        
        C = val;
        
        % Save it to disk.
        save('blah blah.mat',C)        
        
        % how to loop with m_loop?
    end

    function jobComplete(job)
       % Other stuff
    end

% sequence functions to run
seqs = {@main_settings,@seq_mod_1,@main_sequence};

% add it to the queue
j = sequencer_job(seqs,'DFG Optimize',[],@cycleComplete);
    
end

