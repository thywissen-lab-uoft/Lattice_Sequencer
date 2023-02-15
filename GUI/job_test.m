function jh=job_test(jh)

if nargin == 0
    jh = job_handler;
end
%% RF1B K 

    function curtime = seq_mod_1(curtime)
        global seqdata;
        seqdata.flags.lattice   = 0;
        seqdata.flags.xdt       = 0;        
    end

% sequence functions to run
funcs = {@main_settings,@seq_mod_1,@main_sequence};

% add it to the queue
j1 = sequencer_job(funcs,'K RF1B stats',1:2);

%% XDT DFG TOF
tofVec = [21 23 25];
    function curtime = seq_mod_2(curtime)
        global seqdata;
        seqdata.flags.xdt       = 1;        
        defVar('tof',tofVec);
    end

funcs = {@main_settings,@seq_mod_2,@main_sequence};

j2 = sequencer_job(funcs,'DFG TOF',1:3);

%% XDT DFG stats

    function curtime = seq_mod_dfg(curtime)
        global seqdata;
    end

funcs = {@main_settings,@seq_mod_dfg,@main_sequence};

% j3 = sequencer_job(funcs,'DFG TOF');

%% add jobs

jh.add(j1);
jh.add(j2);
% jh.addJob(j3);

end

