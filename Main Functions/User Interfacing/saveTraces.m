function saveTraces(opts)

% This code saves the analog and digital channels to file

global seqdata

rootDir = 'Y:\_communication';

[aTraces, dTraces]=generateTraces(seqdata);

end

