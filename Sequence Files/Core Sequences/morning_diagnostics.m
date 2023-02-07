function morning_diagnostics
% morning_diagnostics.m
%
% Author : C Fujiwara
% 
% PLEASE READ ME.
%
% This code uses the batch running of the machine to do a few machine
% diagnostics.

%% Initialize
global sequence_queue_checker
global seqdata
evalin('base','openvar(''sequence_queue'')')

initSequenceQueue;

%% RF1B K 

% Camera and analysis options
opts = struct;
opts.saveDirName = 'K RF1B stats';

N = 5;                         % number of iterations to run
scaninds = ones(N,1);          % scancycle indeces to use

% sequence functions to run
funcs = {@main_settings,@modseq_RF1BK,@main_sequence};

% add it to the queue
addToSequenceQueue(funcs,scaninds,opts);

%% XDT DFG TOF
opts = struct;
opts.saveDirName = 'dfg tof';

funcs = {@main_settings,@modseq_dfg_mix_tof,@main_sequence};
addToSequenceQueue(funcs,1:9,opts);

%% XDT DFG stats
opts = struct;
opts.saveDirName = 'dfg stats';

N = 20;
scaninds = ones(N,1);

funcs = {@main_settings,@modseq_dfg_mix,@main_sequence};
addToSequenceQueue(funcs,scaninds,opts);

%% Batch Process
seqdata.doscan = 0;
seqdata.scancycle = 1;

start(sequence_queue_checker);

end

