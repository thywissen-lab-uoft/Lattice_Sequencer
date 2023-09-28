function curtime = transport_low_kitten_GS1516(timein)
curtime = timein;


%% Prepare

% Wait
curtime = calctime(curtime,100);


setDigitalChannel(curtime,'Kitten Relay',1); % Kitten Relay off 0: OFF, 1: ON
setAnalogChannel(curtime,'15/16 GS',3,1); 
setAnalogChannel(curtime,'kitten',60); 
setAnalogChannel(curtime,'Coil 15',-1,1)
setAnalogChannel(curtime,'MOT Coil',0); 

% setDigitalChannel(curtime,'15/16 Switch',1); % Turn on 15/16 Switch 0: OFF, 1: ON

% Wait
curtime = calctime(curtime,500);
 
% Turn up FF
curtime = AnalogFunc(calctime(curtime,0),'Transport FF',@(t,tt,y1,y2)...
    (ramp_linear(t,tt,y1,y2)),1000,1000,0,12.25);
curtime = calctime(curtime,1000);

    DigitalPulse(calctime(curtime,-10),...
        'LabJack Trigger Transport',10,1);
    curtime = calctime(curtime,500);
    
curtime = AnalogFunc(calctime(curtime,0),'Coil 16',@(t,tt,y1,y2)...
    (ramp_linear(t,tt,y1,y2)),1000,1000,0,30,5);
curtime = calctime(curtime,1000);
curtime = AnalogFunc(calctime(curtime,0),'Coil 16',@(t,tt,y1,y2)...
    (ramp_linear(t,tt,y1,y2)),1000,1000,30,0,5);


curtime = AnalogFunc(calctime(curtime,0),'Transport FF',@(t,tt,y1,y2)...
    (ramp_linear(t,tt,y1,y2)),1000,1000,12.25,0);
end

