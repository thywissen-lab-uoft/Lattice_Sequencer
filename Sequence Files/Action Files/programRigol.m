function programRigol(global_settings,ch1_set,ch2_set)
% programRigol.m
%
% Author : C Fujiwara
% Last Edited : 2021/03/31
%
% This code programs the Rigol DG4162 which we use in lab as a function
% generator in lab to drive AOMs.  This code includes a brief overview of
% the functioning of these function generators.
% 
% Some primary features that we desire
%
%   - set the carrier frequency (around 80 MHz)
%   - set the output amplitude (either in Vpp or dBm)
%   - specify the anticipated load (50Ohm or Z=infinity)
%   - turn on/off the output with an external trigger (long pulses)
%   - turn on the output with an external and run for a set period of time
%   (short pulses that the adwin can't do)
%   - sweep the frequency of carrier (ie. for Landau-Zener)
%   - ramp up/down power of both outputs (ie. for STIRAP).
%   - set the clock to be external
%   -
% While units can be specified in the write commands, to keep things simple
% all units shall use their default values (Hz, and seconds)

if nargin~=3
    global_settings=struct;
    global_settings.InternalAddress=1;
    global_settings.ClockSource='External';
    
    ch1_set=struct;
    ch1_set.FREQUENCY='1.0985E9';
    ch1_set.STATE='ON';
    ch1_set.AMPLITUDE='0.4';
    ch1_set.AMPLITUDE_UNIT='VPP';
    ch1_set.BURST='OFF';
    ch1_set.MOD='OFF';
    ch1_set.SWEEP='OFF';

    ch2_set=struct;
    ch2_set.FREQUENCY='80E6';
    ch2_set.STATE='ON';
    ch2_set.AMPLITUDE='0.4';
    ch2_set.AMPLITUDE_UNIT='VPP';
    ch2_set.BURST='OFF';
    ch2_set.MOD='OFF';
    ch2_set.SWEEP='OFF';    
    
end
%% Description of Operation
% This code always writes a SIN wave to the Rigol
%
% The modes of operation are CONSTANT, BURST, SWEEP
%   CONSTANT - output a constant frequency
%   BURST - output 
%   SWEEP
%   MOD


%% Define your settings

global_settings.DeviceName=getVISADeviceName(global_settings.InternalAddress);




%% Verify connection to VISA object and display its name
try
    % Find the VISA object
    obj = instrfind('Type','visa-usb','RsrcName', global_settings.DeviceName);
    if isempty(obj)
        obj = visa('NI', global_settings.DeviceName);
    else
        fclose(obj);
        obj = obj(1);
    end

    % Open the VISA object
    fopen(obj);
    nfo = query(obj, '*IDN?');
    nfo=strtrim(nfo);    

    fclose(obj);
catch ME
    warning('Unable to connect to Rigol');
    disp(ME);
    return;
end
try
%% Initiate Connection to write
disp(' ');
disp([' Progamming ' nfo]);
disp(' Notes: ');
disp(' - BURST,MOD, and SWEEP are mutually exclusive commands');
disp(' - SWEEP outputs constants frequency is start and end are equal.');
disp(' - SWEEP returns to start frequency at end of sweep');
disp(' - BURST can only go up to 100 MHz, <300ns trigger latency');
fopen(obj);

fprintf(obj,[':SYSTem:ROSCillator:SOURce ' global_settings.ClockSource]);

%% WRITE SETTINGS
% 
% cmds=struct;
% 
% cmds(1).Name='Frequency';
% cmds(2).Command=@(ch) [':SOURCE' num2str(1) ':FREQUENCY?'];
% 
% 
% fnames={'FREQUENCY',...
%     'STATE',...
%     'AMPLITUDE_UNIT',...
%     'AMPLITUDE',...
%     'BURST',...
%     'MOD',...
%     'SWEEP',...
%     'SWEEP_FREQUENCY_CENTER',...
%     'SWEEP_FREQUENCY_SPAN',...
%     'SWEEP_TRIGGER'};

% testing
fprintf(obj,[':SOURCE1:SWEEP:STATE ON']);
fprintf(obj,[':SOURCE1:SWEEP:TIME 10ms']);


%% READ IN ALL COMMANDS



ch1_get=readRigol(obj,1);
ch2_get=readRigol(obj,2);

%%%%% Display Results

disp(ch1_get)
disp(ch2_get)
catch ME    
    warning('Unable to read from Rigol. Closing connection safely');
end



%% Close Connect and Delete
fclose(obj);
delete(obj);
end

function out=readRigol(obj,ch)

out=struct;
out.NAME=['OUTPUT' num2str(ch)];
out.LOAD=strtrim(query(obj,[':OUTPUT' num2str(ch) ':LOAD?']));
out.STATE=strtrim(query(obj,[':OUTPUT' num2str(ch) ':STATE?']));
out.FREQUENCY=strtrim(query(obj,[':SOURCE' num2str(ch) ':FREQUENCY?']));
out.AMPLITUDE=strtrim(query(obj,[':SOURCE' num2str(ch) ':VOLTAGE:IMMEDIATE:AMPLITUDE?']));
out.AMPLITUDE_UNIT=strtrim(query(obj,[':SOURCE' num2str(ch) ':VOLTAGE:UNIT?']));
out.BURST=strtrim(query(obj,[':SOURCE' num2str(ch) ':BURST:STATE?']));
out.MOD=strtrim(query(obj,[':SOURCE' num2str(ch) ':MOD:STATE?']));
out.SWEEP=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:STATE?']));

if isequal(out.SWEEP,'ON')
    out.SWEEP_FREQUENCY_CENTER=strtrim(query(obj,[':SOURCE' num2str(ch) ':FREQUENCY:CENTER?']));
    out.SWEEP_FREQUENCY_SPAN=strtrim(query(obj,[':SOURCE' num2str(ch) ':FREQUENCY:SPAN?']));
    out.SWEEP_TIME=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:TIME?']));
    out.SWEEP_HOLDTIME_START=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:HTIME:START?']));
    out.SWEEP_HOLDTIME_STOP=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:HTIME:STOP?']));
    out.SWEEP_TYPE=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:SPACING?']));
    out.SWEEP_TRIGGER=strtrim(query(obj,[':SOURCE' num2str(ch) ':SWEEP:TRIGGER:SOURCE?']));
end

end
