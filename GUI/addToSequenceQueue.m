function ids = addToSequenceQueue(seq_funcs,scan_inds,opts)
global sequence_queue;
ids=[];
for kk=1:length(scan_inds)
   cmd = struct;
   cmd.SequenceFunctions    = seq_funcs;
   cmd.ScanCycle            = scan_inds(kk);
   cmd.Options              = opts;
   sequence_queue(end+1) = cmd;
end

end

