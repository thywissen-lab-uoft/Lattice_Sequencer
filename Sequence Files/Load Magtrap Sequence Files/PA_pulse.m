function [curtime] = PA_pulse(timein)
%PA_PULSE Summary of this function goes here
%   Detailed explanation goes here

global seqdata;
curtime = timein;


% Shutter 1 is usually closed (light not allowed)
setDigitalChannel(0,'Vortex Shutter 1',0);

% Shutter 2 is nominally open (light allowed)
setDigitalChannel(0,'Vortex Shutter 2',1);

tD1 = -2.75;
tD2 = -2.85;
% 
% tD1=0;
% tD2=0;

pulse_time_list = [0];
pulse_time = getScanParameter(pulse_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'pulse_time');

if pulse_time>0

    % Let light through with Shutter 1
    setDigitalChannel(calctime(curtime,tD1),'Vortex Shutter 1',1);

    % Stop light with shutter 2
    setDigitalChannel(calctime(curtime,tD2+pulse_time),'Vortex Shutter 2',0);

    % Reset 1000 ms later
    setDigitalChannel(calctime(curtime,1000),'Vortex Shutter 1',0);
    setDigitalChannel(calctime(curtime,1020),'Vortex Shutter 2',1);
    
    curtime = calctime(curtime,pulse_time);
end

end

