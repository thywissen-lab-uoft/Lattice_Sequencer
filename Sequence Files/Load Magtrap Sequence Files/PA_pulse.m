function [curtime] = PA_pulse(timein,pulse_number)
%PA_PULSE Summary of this function goes here
%   Detailed explanation goes here

global seqdata;
curtime = timein;
if nargin == 1
    do_reset = 1;
    pulse_number = 1;
else
   if pulse_number > 1
       do_reset = 0;
   else
       do_reset = 1;
   end
end

if timein ==0
   curtime = calctime(curtime,500); 
   setAnalogChannel(curtime,'Unused',0);
%     SelectScopeTrigger('PA_Pulse');
end

%% Grab the last voltages
if pulse_number == 1
try
    % Read the last written magnetic field
    [bfield, voltagefunc, voltage, time] = getChannelValue(seqdata,'FB Current',1,0);
   
    addOutputParam('PA_field',bfield,'G');
    
    
    [Ishim, voltagefunc, voltage, time] = getChannelValue(seqdata,'Z Shim',1,0);

    addOutputParam('PA_Z_Shim',Ishim,'A');

end
end
%% Rigol Settings

% AOM voltage at maximum diffraction efficiency
V0 = 1.250;

%PA_rel_pow_list = [0.1];
%PA_rel_pow = getScanParameter(PA_rel_pow_list,...
%    seqdata.scancycle,seqdata.randcyclelist,'PA_rel_pow','arb');

PA_rel_pow = paramGet('PA_rel_pow');
addOutputParam('PA_rel_pow',PA_rel_pow,'arb.');

PA_pow = PA_rel_pow*V0;
if pulse_number == 1
    addOutputParam('PA_pow',PA_pow,'V');
end

adrr = 10;
ch_PA=struct;
ch_PA.FREQUENCY=110E6;     % Modulation Frequency
ch_PA.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP) 
ch_PA.STATE = 'ON';    
ch_PA.AMPLITUDE = PA_pow;
programRigol(adrr,[],ch_PA); 
    
%%

ScopeTriggerPulse(calctime(curtime,-0.5),'PA_Pulse',10);



%Set the PA AOM and shutter at the start of the sequence (only if this is
%the first time PA_pulse is called.
if do_reset == 1
    setDigitalChannel(0,'PA Shutter',1); % Shutter is closed

    setDigitalChannel(0,'PA TTL',1); % AOM is on

    setAnalogChannel(0,'Vortex Current Mod',0);
    seqdata.analogchannels(33).name = 'Vortex Current Mod';
end

tD = -3.5;

useRelTime = 0;
if useRelTime    
    Tmax = paramGet('pulse_time_max');

    % pulse_time = paramGet('pulse_time');
    pulse_time = paramGet('pulse_time_rel')*Tmax;
    pulse_time = round(pulse_time/.005)*.005;
else
    pulse_time = paramGet('pulse_time');
end

%Only set the output param once
if pulse_number == 1
    addOutputParam('pulse_time',pulse_time,'ms');
end

%Trigger the PA labjack if doing the end of cycle power calibration
if pulse_number == 2
    pulse_time = 3;
    DigitalPulse(calctime(curtime,1),'PA LabJack Trigger',1,1)
end
if pulse_number == 1
    fake_pulse = 0; % 1: fake, 0: not fake ;vary this parameter if you want a fake pulse
else
    fake_pulse = 0; %this should remain 0
end
fake_pulse = 0;
if pulse_time>0 
    if fake_pulse == 0
        % Turn OFF AOM
        setDigitalChannel(calctime(curtime,tD-1),'PA TTL',0);

        % Open the shutter
        setDigitalChannel(calctime(curtime,tD),'PA Shutter',0);

        % Turn on AOM
        setDigitalChannel(calctime(curtime,0),'PA TTL',1);

        % Advance Time
        curtime=calctime(curtime,pulse_time);

        % Turn off AOM
        setDigitalChannel(calctime(curtime,0),'PA TTL',0);    

        % Close Shutter
        setDigitalChannel(calctime(curtime,5),'PA Shutter',1);

        % Turn on AOM
        setDigitalChannel(calctime(curtime,100),'PA TTL',1);
    end
    
    if fake_pulse == 1   
        % Advance Time
        curtime=calctime(curtime,pulse_time);   
    end
end

% Wait 20 ms
curtime = calctime(curtime,20);

