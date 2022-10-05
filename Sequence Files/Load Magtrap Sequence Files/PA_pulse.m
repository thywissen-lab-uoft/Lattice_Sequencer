function [curtime] = PA_pulse(timein)
%PA_PULSE Summary of this function goes here
%   Detailed explanation goes here

global seqdata;
curtime = timein;

if timein ==0
   curtime = calctime(curtime,100); 
   setAnalogChannel(curtime,'Unused',0);

end


setDigitalChannel(0,'PA Shutter',1); % Shutter is closed

setDigitalChannel(0,'PA TTL',1); % AOM is on


setAnalogChannel(0,'Vortex Current Mod',0);
seqdata.analogchannels(33).name = 'Vortex Current Mod';
tD = -3.5;

pulse_time_list = [0:0.05:0.5 0.6 0.7 0.8 0.9 1];1;
pulse_time = getScanParameter(pulse_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'pulse_time','ms');

% pulse_time = paramGet('pulse_time');

if pulse_time>0

    % Turn OFF AOM
    setDigitalChannel(calctime(curtime,tD-1),'PA TTL',0);
    
    % Open the shutter
    setDigitalChannel(calctime(curtime,tD),'PA Shutter',0);

    % Turn on AOM
    setDigitalChannel(calctime(curtime,0),'PA TTL',1);
    
%     mod_val = 2.5;
%     AnalogFuncTo(calctime(curtime,0),'Vortex Current Mod',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), pulse_time, pulse_time, mod_val);
        

    % Advance Time
    curtime=calctime(curtime,pulse_time);
    
    % Turn off AOM
    setDigitalChannel(calctime(curtime,0),'PA TTL',0);    
        
    % Reset Current Modulation
%     setAnalogChannel(calctime(curtime,0),'Vortex Current Mod',0);    
    
    % Close Shutter
    setDigitalChannel(calctime(curtime,5),'PA Shutter',1);

    % Turn on AOM
    setDigitalChannel(calctime(curtime,9),'PA TTL',1);

end

% Wait 20 ms
curtime = calctime(curtime,20);

end

