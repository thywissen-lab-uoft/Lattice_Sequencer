%------
%Author: David McKay
%Created: Nov 2012
%Summary: This is a dipole test sequence to check maximum power
%------

function timeout = dipole_test_sequence(timein)

curtime = timein;

global seqdata;

%turn on dipole 1 + 2
dipole1_on = 1;
dipole2_on = 1;

dipole1_pwr = 7;
dipole2_pwr = 7;

curtime = calctime(curtime,100);
setDigitalChannel(calctime(curtime,0),12,0);

if dipole1_on
    setAnalogChannel(curtime,40,dipole1_pwr);
end

if dipole2_on
    setAnalogChannel(curtime,38,dipole2_pwr);
end

curtime = calctime(curtime,1000);

setAnalogChannel(curtime,40,0,1);
setAnalogChannel(curtime,38,0,1);
 
%% End
timeout = curtime;


end

