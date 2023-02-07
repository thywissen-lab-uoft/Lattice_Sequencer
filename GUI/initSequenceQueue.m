function initSequenceQueue

global sequence_queue;

sequence_queue = struct(...
    'SequenceFunctions',{},...
    'ScanCycle',{},...
    'Options',{});
    
end

