function [curtime] = PA_pulse(timein)
%PA_PULSE Summary of this function goes here
%   Detailed explanation goes here

global seqdata;
curtime = timein;

if timein ==0
   curtime = calctime(curtime,100); 
   setAnalogChannel(curtime,'Unused',0);

end

%% Rigol Settings

% AOM voltage at maximum diffraction efficiency
V0 = 1.250;

PA_rel_pow_list = [1];
PA_rel_pow = getScanParameter(PA_rel_pow_list,...
    seqdata.scancycle,seqdata.randcyclelist,'PA_rel_pow','arb');

% PA_rel_pow = paramGet('PA_rel_pow');
% addOutputParam('PA_rel_pow',PA_rel_pow,'arb.');

PA_pow = PA_rel_pow*V0;

addOutputParam('PA_pow',PA_pow,'V');

adrr = 10;
ch_PA=struct;
ch_PA.FREQUENCY=110E6;     % Modulation Frequency
ch_PA.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP) 
ch_PA.STATE = 'ON';    
ch_PA.AMPLITUDE = PA_pow;
programRigol(adrr,[],ch_PA); 
    
%%

ScopeTriggerPulse(curtime,'PA_Pulse');


setDigitalChannel(0,'PA Shutter',1); % Shutter is closed

setDigitalChannel(0,'PA TTL',1); % AOM is on


setAnalogChannel(0,'Vortex Current Mod',0);
seqdata.analogchannels(33).name = 'Vortex Current Mod';
tD = -3.5;

pulse_time_list = [20];1;%ms
pulse_time = getScanParameter(pulse_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'pulse_time','ms');


% %Tmax = 7 + ((60-7)/(207-201))*(paramGet('PA_FB_field') + 3 - 201);
% Tmax = 1000;
% pulse_time = paramGet('pulse_time');
% addOutputParam('pulse_time',pulse_time,'ms');


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

