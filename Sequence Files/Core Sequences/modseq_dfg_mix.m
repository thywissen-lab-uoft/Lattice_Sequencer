function [timeout] = modseq_dfg_mix(curtime)
global seqdata

seqdata.flags.image_atomtype                = 1;
seqdata.flags.mt                            = 1;
seqdata.flags.xdt                           = 1;
seqdata.flags.lattice                       = 0;
defVar('tof',25,'ms');

timeout = curtime;
end

