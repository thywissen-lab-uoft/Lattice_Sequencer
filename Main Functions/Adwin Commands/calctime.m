function y = calctime(curtime,addtime)

global seqdata;

%this converts a time in real units into the ADWIN sequencer time (# of
%ADWIN events). Default is to floor to the integer number of ADWIN steps.

y = curtime + floor(addtime/seqdata.deltat*seqdata.timeunit+1E-9);

if y<0
    error('Can''t go back in time!');
end

end