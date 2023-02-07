function morning_diagnostics
global seqdata

initSequenceQueue;

%% RF1B K 
% Camera and analysis options
opts = struct;
opts.saveDirName = 'K RF1B stats';

N = 20;                         % number of iterations to run
scaninds = ones(N,1);           % scancycle indeces to use

% sequence functions to run
funcs = {@main_settings,@modseq_RF1BK,@main_sequence};

% add it to the queue
addToSequenceQueue(funcs,opts,scaninds;

%% XDT DFG

opts = struct;
opts.saveDirName = 'dfg stats';

funcs = {@main_settings,@modseq_dfg_mix,@main_sequence};
addToSequenceQueue(funcs,opts,ones(N,1));

%% XDT DFG TOF

opts = struct;
opts.saveDirName = 'dfg stats';

funcs = {@main_settings,@modseq_dfg_mix_tof,@main_sequence};
addToSequenceQueue(funcs,opts,1:30);

%% Go Run

% start everything

end

