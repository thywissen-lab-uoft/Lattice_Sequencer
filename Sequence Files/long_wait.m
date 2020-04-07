%------
%Author: DCM
%Created: Aug 2010
%Summary: Waits for a long time, puts in intermittent analog channel
%updates to prevent the wait variable in the ADWIN array from overflowing.
%Need to do this for any waits longer than about 3s
%------


function timeout = long_wait(timein,waittime,channel,value)

%Need to give this function a channel and a value it can use for these
%updates (note: only does direct voltage updates)

global seqdata;

curtime = timein;

max_wait_period = 3000;

for i = 1:floor(waittime/max_wait_period)
   curtime = setAnalogChannel(calctime(curtime,max_wait_period),channel,value,1);
end
waittime = waittime - floor(waittime/max_wait_period)*max_wait_period;
curtime = calctime(curtime,waittime);
 
timeout = curtime;

end