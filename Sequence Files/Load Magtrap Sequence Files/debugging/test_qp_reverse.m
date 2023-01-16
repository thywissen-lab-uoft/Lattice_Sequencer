
function timeout = test_qp_reverse(timein)

curtime = timein;
global seqdata;

% This code tests the ability to run current forwards and backwards through
% the QP coils

% Channel to test
pulsetime = 2000;       % Duration of pulse
current = 5;            % Current in amps

% Define current ramp function
ramp_iparabola = @(t,tt,y0,y1) (y1-y0)*(1-(2*t/tt-1).^2)+y0;

%% Set logic and otherwise prepare
curtime = calctime(curtime,100);
 
%Ramp off MOT
setAnalogChannel(calctime(curtime,-50),8,10);
AnalogFuncTo(calctime(curtime,0),'MOT Coil',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);

% Wait
curtime = calctime(curtime,500);

% Turn off Kitten relay
setDigitalChannel(curtime,'Kitten Relay',0); %0: OFF, 1: ON

% Turn off 15/16 switch
setDigitalChannel(curtime,'15/16 Switch',0); %0: OFF, 1: ON

% Turn off Reverse QP Switch
setDigitalChannel(curtime,'Reverse QP Switch',0);

% Turn on Coil 16 TTL
setDigitalChannel(curtime,'Coil 16 TTL',1); %1: turns coil off; 0: coil can be on
curtime = calctime(curtime,500);

% Set Tranport PSU Feed Forward
setAnalogChannel(calctime(curtime,-100), 'Transport FF',80*(abs(current)/30)/3 + 0.5);
%% Ramp for QP Mode

% Wait a moment
curtime = calctime(curtime,100);

% Turn off reverse QP switch
setDigitalChannel(curtime,'Reverse QP Switch',0);

% Turn on 15/16 switch
setDigitalChannel(curtime,'15/16 Switch',1);

% Wait a moment
curtime = calctime(curtime,100);

% Trigger scope
DigitalPulse(calctime(curtime,0),'ScopeTrigger',10,1);

% Ramp Coil 16
curtime = AnalogFunc(calctime(curtime,0),'Coil 16',@(t,tt,y1) ...
    ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,current,2);

%% Wait and switch mode
curtime = calctime(curtime,100);

% Turn on reverse QP switch
setDigitalChannel(curtime,'Reverse QP Switch',1);

% Turn off 15/16 switch
setDigitalChannel(curtime,'15/16 Switch',0);

% Wait
curtime = calctime(curtime,100);

%% Ramp for Reverse QP Mode

% Ramp Coil 15
curtime = AnalogFunc(calctime(curtime,0),'Coil 15',@(t,tt,y1) ...
    ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,current,2);


%% Wait

curtime = calctime(curtime,1000);

%% Go back to MOT gradient for wait time

% MOT Gradient
gradient = 2;

% Set the transport feed forwards
setAnalogChannel(calctime(curtime,-30),'Transport FF',23*(gradient/30) + 0.5);

%Turn on Coil
curtime = setAnalogChannel(calctime(curtime,0),'MOT Coil',gradient,2);

%set all transport coils to zero (except MOT)
for i = [7 9:17 22:24 20] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end
    
%Turn off QP Coils
setAnalogChannel(calctime(curtime,0),'Coil 15',-.8,1); %15
curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1); %16
curtime = setAnalogChannel(curtime,'kitten',0,1); %kitten
curtime = setDigitalChannel(curtime,'15/16 Switch',0);
curtime = setDigitalChannel(curtime,'Reverse QP Switch',0);


curtime = calctime(curtime,100);
timeout = curtime;