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

% sequence functions to run
funcs = {@main_settings,@modseq_RF1BK,@main_sequence};

% add it to the queue
addToSequenceQueue(funcs,scaninds,opts);

%% XDT DFG TOF
opts = struct;
opts.saveDirName = 'dfg tof';

funcs = {@main_settings,@modseq_dfg_mix_tof,@main_sequence};
addToSequenceQueue(funcs,1:2,opts);

%% XDT DFG stats
opts = struct;
opts.saveDirName = 'dfg stats';

N = 2;
scaninds = ones(N,1);

funcs = {@main_settings,@modseq_dfg_mix,@main_sequence};
addToSequenceQueue(funcs,scaninds,opts);

%% Batch Process

batchBegin;


end

