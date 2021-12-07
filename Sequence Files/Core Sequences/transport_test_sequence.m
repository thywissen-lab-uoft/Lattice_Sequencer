%------
%Author: David McKay
%Created: July 2009
%Summary: This is a test sequence for transport
%------

function timeout = transport_test_sequence(timein)

curtime = timein;
global seqdata;

% Channel to test
pulsetime = 2000;       % Duration of pulse
current = 5;            % Current in amps
% channel = 21;           % Channel to use

% channel = 'Coil 11';
channel = 'Push Coil';

% Set logic for digital switch FETs
curtime = calctime(curtime,100);
setDigitalChannel(curtime,'Kitten Relay',0); %0: OFF, 1: ON
setDigitalChannel(curtime,'15/16 Switch',0); %0: OFF, 1: ON
setDigitalChannel(curtime,'Coil 16 TTL',1); %1: turns coil off; 0: coil can be on
curtime = calctime(curtime,500);
 
%Ramp off MOT
setAnalogChannel(calctime(curtime,-50),8,10);
AnalogFuncTo(calctime(curtime,0),8,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);
curtime = calctime(curtime,500);


is_bipolar = 0;

% Define current ramp function
ramp_iparabola = @(t,tt,y0,y1) (y1-y0)*(1-(2*t/tt-1).^2)+y0;%(y1-y0)*(1-(tt-t)/tt)+y0;
ramp_cosine = @(t,tt,y0) y0/2*(1-cos(2*pi*t/tt));

%set FF
setAnalogChannel(calctime(curtime,-200),18,25*(abs(current)/30)/3 + 0.5);

% %use the following for QT coil
% AnalogFunc(calctime(curtime,-200),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0.5,25*(abs(current)/30)/1 + 0.5);

% use the following for other transfer coils
AnalogFunc(calctime(curtime,-200),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0.5,8*(abs(current)/30)/1 + 0.5);

%Kitten to max current for the ramp if using coil 15 or 16 alone.
setAnalogChannel(calctime(curtime,-175),3,0,1); % current set to 5 for fully on   

%"Turn on" coil to 0
setAnalogChannel(calctime(curtime,-50),channel,0,1); %Start at zero for AnalogFuncTo

% %Test for coil 16
% setAnalogChannel(calctime(curtime,-200),'coil 15',0,1);

%Turn on coil for pulsetime 
% curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_cosine(t,tt,y0),pulsetime,pulsetime,current,3);
% curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_cosine(t,tt,y0),pulsetime,pulsetime,-current,3);

% Analog ramps
%digital trigger
DigitalPulse(calctime(curtime,0),'ScopeTrigger',10,1);
%Turn on if using kitten (for channels 15/16). 
%           AnalogFunc(calctime(curtime,0),3,@(t,tt,y1)ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,0.3*current,2);
curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y1)ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,current,2);
if (is_bipolar)
    curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y1)ramp_iparabola(t,tt,0,y1),pulsetime,pulsetime,-current,2);
end
% 
% setAnalogChannel(calctime(curtime,0),3,6,1);
% % curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_iparabola(t,tt,y0),pulsetime,pulsetime,current,2);
% % % curtime = AnalogFuncTo(calctime(curtime,0),channel,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,current,2);
% % % curtime = AnalogFuncTo(calctime(curtime,pulsetime),channel,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);
% % setAnalogChannel(calctime(curtime,20),3,0);
% % curtime = calctime(curtime,2000);

% % setAnalogChannel(calctime(curtime,0),3,6,1);
% % setAnalogChannel(calctime(curtime,0),channel,current);
% % curtime = setAnalogChannel(calctime(curtime,pulsetime),channel,0.0);
% % setAnalogChannel(calctime(curtime,pulsetime),3,0);
% % 
curtime = calctime(curtime,1000);

%Go back to MOT gradient for wait time
gradient = 2;
% curtime = calctime(curtime,2000);
%set FF
setAnalogChannel(calctime(curtime,-30),18,23*(gradient/30) + 0.5);

%Turn on Coil
curtime = setAnalogChannel(calctime(curtime,0),8,gradient,2);


%set all transport coils to zero (except MOT)
for i = [7 9:17 22:24 20] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end

    
%Turn off QP Coils
setAnalogChannel(calctime(curtime,0),'Coil 15',-.8,1); %15
curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1); %16
curtime = setAnalogChannel(curtime,3,0,1); %kitten
curtime = setDigitalChannel(curtime,'15/16 Switch',0);


curtime = calctime(curtime,100);
timeout = curtime;