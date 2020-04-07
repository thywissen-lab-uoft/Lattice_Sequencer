%------
%Author: David McKay
%Created: July 2009
%Summary: This is a test sequence for RF and microwaves to check if they
%are output the correct signals
%------

function timeout = rf_uwave_test_sequence(timein)

curtime = timein;

global seqdata;

seqdata.numDDSsweeps = 0;

keep_uwave_on = 0;

%dummy set Feshbach to zero 
setAnalogChannel(curtime,37,0,1);

curtime  = do_uWave_pulse(calctime(curtime,200), 0, 20*1E6,100,0);
DigitalPulse(curtime,12,0.1,1);

curtime  = calctime(curtime,100);

if keep_uwave_on
    setDigitalChannel(calctime(curtime,0),17,1);
    setDigitalChannel(calctime(curtime,0),14,1);
end
    

timeout = curtime;

end

