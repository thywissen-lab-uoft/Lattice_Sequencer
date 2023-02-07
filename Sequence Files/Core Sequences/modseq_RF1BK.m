function [timeout] = modseq_RF1BK(curtime)
global seqdata

seqdata.flags.image_atomtype            = 1;
seqdata.flags.mt                        = 1;
seqdata.flags.xdt                       = 0;
seqdata.flags.lattice                   = 0;
defVar('tof',5,'ms');

timeout = curtime;
end

