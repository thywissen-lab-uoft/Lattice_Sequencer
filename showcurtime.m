function showcurtime(curtime)
global seqdata
t=seqdata.deltat*curtime;
disp([' curtime = ' num2str(t*1E3,'%.3f') ' ms (' num2str(curtime) ' cycles)']);
% display the time in ms to the neart us (three decimal points);
end

