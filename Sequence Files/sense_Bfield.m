%------
%Author: Stefan Trotzky
%Created: March 2014
%Summary: Reset the Honeywell sensor and cycle set/reset for offset-free
%           measurement; currently takes 120 ms in total
%------

function timeout = sense_Bfield(timein)

curtime = timein;

global seqdata;

%% Test shims

% initial settling time
curtime = calctime(curtime,500);

% initial reset
curtime = DigitalPulse(calctime(curtime,0),'Field sensor SR',50,1);

% initial wait
curtime = calctime(curtime,50);

duty_cycle = 0.5;
cycle_period = 5;
ncycles = 100;

for j = 1:ncycles
    set_time = cycle_period*duty_cycle;
    reset_time = cycle_period*(1-duty_cycle);
curtime = DigitalPulse(calctime(curtime,0),'Field sensor SR',set_time,1);
curtime = calctime(curtime,reset_time);
end

% final wait
curtime = calctime(curtime,500);


%% 
%% End
timeout = curtime;

        
end
