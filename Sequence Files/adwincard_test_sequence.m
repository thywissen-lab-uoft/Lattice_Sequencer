%------
%Author: David McKay
%Created: July 2009
%Summary: This is a test sequence for testing the ADWIN card
%------

function timeout = test_sequence(timein)

curtime = timein;

global seqdata;

curtime = calctime(curtime,100);

% for i = 1:32
%     setDigitalChannel(curtime,i+32,1);
%     %setDigitalChannel(curtime,17,1);
%     curtime = calctime(curtime,500);
%     %setDigitalChannel(curtime,i,0);
% end

% setDigitalChannel(curtime,32,1);
% setDigitalChannel(curtime,17,1);

% DigitalPulse(curtime,32,1,1);
% DigitalPulse(curtime,17,1,1);

setAnalogChannel(curtime,55,1,1);
setAnalogChannel(curtime,49,1,1);

curtime = calctime(curtime,10);

DigitalPulse(calctime(curtime,0),12,10,1);
% DigitalPulse(curtime,32,1,1);
% DigitalPulse(curtime,17,1,1);

setAnalogChannel(curtime,55,0,1);
setAnalogChannel(curtime,49,0,1);


 
%% End
timeout = curtime;


end

