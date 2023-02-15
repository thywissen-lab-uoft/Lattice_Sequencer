function jh=job_test(jh)

if nargin == 0
    jh = job_handler;
end

%% RF1B K 

    function curtime = seq_mod_1(curtime)
        global seqdata;
        seqdata.flags.lattice   = 0;
        seqdata.flags.xdt       = 0;      
        defVar('tof',5);
    end

npt=struct;
npt.SequenceFunctions   = {@main_settings,@seq_mod_1,@main_sequence};
npt.JobName             = 'K RF1B stats';
npt.ScanCyclesRequested = [1:10];
npt.SaveDirName         = 'K RF1B stats';

j1 = sequencer_job(npt);

%% XDT DFG TOF
tofVec = [17 19 21 23 25];
    function curtime = seq_mod_2(curtime)
        global seqdata;
        seqdata.flags.xdt       = 1;        
        defVar('tof',tofVec);
    end

npt=struct;
npt.SequenceFunctions   = {@main_settings,@seq_mod_2,@main_sequence};
npt.JobName             = 'DFG TOF';
npt.ScanCyclesRequested = [1 2 3 4 5];
npt.SaveDirName         = 'DFG TOF';

j2 = sequencer_job(npt);

%% XDT LF DFG TOF
    function curtime = seq_mod_3(curtime)
        global seqdata;
        seqdata.flags.xdt       = 1;        
        defVar('tof',25);
    end

npt=struct;
npt.SequenceFunctions   = {@main_settings,@seq_mod_3,@main_sequence};
npt.JobName             = 'LF DFG stats';
npt.ScanCyclesRequested = [1:20];
npt.SaveDirName         = 'LF DFG stats';

j3 = sequencer_job(npt);
%% Add jobs to handler
J = [j1 j2 j3];
jh.add(J);
end

