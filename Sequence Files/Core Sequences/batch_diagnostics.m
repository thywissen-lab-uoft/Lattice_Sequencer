function batch_diagnostics
% morning_diagnostics.m
%
% Author : C Fujiwara
% 

global sequence_queue;

sequence_queue = struct(...
    'SequenceFunctions',{},...
    'ScanCycle',{},...
    'Options',{});

%% RF1B K 

% Camera and analysis options
opts = struct;
opts.saveDirName = 'K RF1B stats';

N = 2;                         % number of iterations to run
scaninds = ones(N,1);          % scancycle indeces to use

    function curtime = seq_mod_1(curtime)
        global seqdata;
        seqdata.flags.lattice   = 0;
        seqdata.flags.xdt       = 0;        
    end

% sequence functions to run
funcs = {@main_settings,@seq_mod_1,@main_sequence};

% add it to the queue
% addToSequenceQueue(funcs,scaninds,opts);

%% XDT DFG TOF
opts = struct;
opts.saveDirName = 'dfg tof';

tofVec = [21 23 25];
    function curtime = seq_mod_2(curtime)
        global seqdata;
        seqdata.flags.xdt       = 0;        
        defVar('tof',tofVec);
    end

funcs = {@main_settings,@seq_mod_2,@main_sequence};
addToSequenceQueue(funcs,1:length(tofVec),opts);

%% XDT DFG stats
opts = struct;
opts.saveDirName = 'dfg stats';

N = 2;
scaninds = ones(N,1);

funcs = {@main_settings,@modseq_dfg_mix,@main_sequence};
% addToSequenceQueue(funcs,scaninds,opts);

%% Batch Process

batchBegin;


end

