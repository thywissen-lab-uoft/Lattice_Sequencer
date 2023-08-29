function curtime = testKitten(timein)

curtime = timein;
global seqdata;    


%set all transport coils to zero (except MOT)
for i = [8 7 9:17 22:24 20] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end

    DigitalPulse(calctime(curtime,0),...
        'LabJack Trigger Transport',50,1)
    
    curtime= calctime(curtime,1000);

%% Ramp up QP coils to some value

setAnalogChannel(calctime(curtime,0),'Coil 16',0,5);
setAnalogChannel(calctime(curtime,0),'Coil 15',0,5);

setAnalogChannel(calctime(curtime,0),'kitten',0,1);
setAnalogChannel(calctime(curtime,1),'kitten',0,1);

% Make sure QP reverse is off and 15/16 switch is on
setDigitalChannel(curtime,'Reverse QP Switch',0);
setDigitalChannel(curtime,'15/16 Switch',1); 
setDigitalChannel(curtime,'Kitten Relay',0); 

% Ramp up Feedforward
curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    100,100,0,15,2);

% Wait
curtime = calctime(curtime,50);

% Ramp up Coil 16
curtime = AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    100,100,0,30,5);

curtime = calctime(curtime,1000);

%% 

% DO KITTEK TEST HERE

%%
% Ramp down Coil 16
curtime = AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    100,100,30,0,5);

curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    100,100,12,0,2);


end

