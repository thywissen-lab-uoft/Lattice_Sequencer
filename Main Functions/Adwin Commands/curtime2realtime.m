function tout = curtime2realtime(curtime2,curtime1)
% This function calculates the amount of real time that has transpired
% between two Adwin times curtime2 and curtime1.  If no curtime1 is
% provided it is assumed that you want the total time.

global seqdata;

if nargin==1
    curtime1=0;
end

% Calculate the time in ms
tout=(curtime2-curtime1)*seqdata.deltat/seqdata.timeunit;

end

