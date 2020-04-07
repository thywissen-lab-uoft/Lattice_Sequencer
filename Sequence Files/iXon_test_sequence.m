function timeout = iXon_test_sequence(timein)

curtime = timein;

global seqdata;

%% Test iXon Camera

% setDigitalChannel(curtime,'Rb Probe/OP TTL',1);
% 
% flush camera with first exposure
curtime = DigitalPulse(curtime,'iXon Trigger',0.1,1);
% wait some time for second exposure
curtime = calctime(curtime,100);

% set Probe intensity
setAnalogChannel(calctime(curtime,-5),'Rb Probe/OP AM',0.5);
setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',0.5);
% open probe shutter
DigitalPulse(calctime(curtime,-10),'Rb Probe/OP Shutter',20,1);
DigitalPulse(calctime(curtime,-10),'K Probe/OP Shutter',20,1);
% trigger camera for second image
DigitalPulse(curtime,'iXon Trigger',0.1,1);
% pulse AOM with fast TTL
DigitalPulse(calctime(curtime,0.1),'Rb Probe/OP TTL',0.05,0);
% DigitalPulse(calctime(curtime,0.1),'K Probe/OP TTL',0.05,0);
% set Probe intensity
setAnalogChannel(calctime(curtime,+5),'Rb Probe/OP AM',0);
setAnalogChannel(calctime(curtime,+5),'K Probe/OP AM',0);

timeout = curtime;