function J=job_optimize_DFG_end_power_endtime

%% Optimize Power

% Sequence Modifier File
    function curtime = seq_mod(curtime)
        global seqdata;
        seqdata.flags.xdt = 1;
        defVar('tof',25);        
        defVar('end_power',[.05:.01:.12]);
        defVar('evap_time',25000);
    end

% This function evaluates at the end of each cycle
    function cycleComplete

    end

% This function evaluates at the start of each cycle
    function cycleStart
  
    end

% This function evaluates at the end of the job
    function jobComplete
        % Get the data and then write it           
    end

npt = struct;
npt.JobName             = 'DFG Optimize End Power';
npt.SequenceFunctions   = {@main_settings,@seq_mod,@main_sequence};
npt.ScanCyclesRequested = 1:8;
npt.CycleStartFcn       = @cycleStart;
npt.CycleCompleteFcn    = @cycleComplete;
npt.JobCompleteFcn      = @jobComplete;
npt.SaveDirName         = 'DFG Optimize End Power';

% Make the job
j1 = sequencer_job(npt);
    

%% Optimize Time

% Sequence Modifier File
    function curtime = seq_mod2(curtime)
        global seqdata;
        seqdata.flags.xdt = 1;
        defVar('tof',25);        
        
        b=load('blah.mat');
        defVar('end_power',b.EndPower);
        defVar('evap_time',[5000:2000:20000]);
    end

% This function evaluates at the end of each cycle
    function cycleComplete2

    end

% This function evaluates at the start of each cycle
    function cycleStart2
  
    end

% This function evaluates at the end of the job
    function jobComplete2
        % Get the data and then write it           
    end

npt = struct;
npt.JobName             = 'DFG Optimize Time';
npt.SequenceFunctions   = {@main_settings,@seq_mod2,@main_sequence};
npt.ScanCyclesRequested = 1:16;
npt.CycleStartFcn       = @cycleStart2;
npt.CycleCompleteFcn    = @cycleComplete2;
npt.JobCompleteFcn      = @jobComplete2;
npt.SaveDirName         = 'DFG Optimize Time';

% Make the job
j2 = sequencer_job(npt);

%% Collect Jobs

J = [j1 j2];
end

