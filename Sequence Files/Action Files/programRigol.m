function programRigol(InternalAddress,ch1_set,ch2_set)
% programRigol.m
%
% Author : C Fujiwara
% Last Edited : 2021/03/31
%
% This code programs the Rigol DG4162 which we use in lab as a function
% generator in lab to drive AOMs.  This code includes a brief overview of
% the functioning of these function generators.
%
%   global_settings
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

%   - set the clock to be external%
%
%   The modes of operation are CONSTANT, BURST, SWEEP, MOD
%   CONSTANT - constant frequency (occurs if BURST,SWEEP, and MOD are off)
%   BURST - output on when given a trigger (duration can be linked to
%       trigger or can be externally set)
%   SWEEP - Sweep the output frequency over a range
%   MOD - modulate the frequency (currently only amplitude modulation);
%
% If a settings if not provided for a given parameter, it is not written.
% However, all typically set parameters will be read.

%% Default settings

if nargin~=3
    warning(['You should really give me all argument all the time. ' ...
        ' Just make an argument an empty [] if you don'' want to use it.']);
    InternalAddress=1;
    
    ch1_set=struct;
    ch1_set.FREQUENCY='1.0985E8';
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

%% Grab the Device Name

DeviceName=getVISADeviceName(InternalAddress);

%% Define Commands
% This structure defines all readable and writable commands to the Rigol
% DG4162.  The fieldname of the structure corresponds to the fieldname of
% the input structure fieldnames.  The value of each field is a string
% which corresponds to the command to be written to the Rigol.  It accounts
% for the channel output via <n> which is later replaced with an integer.
% Queries are automatically hanlded by just adding a ? in the readRigol
% function defined later.

cmds=struct;

cmds.CLOCK_SOURCE=':SYSTEM:ROSCILLATOR:SOURCE';

cmds.LOAD=':OUTPUT<n>:LOAD';
cmds.STATE=':OUTPUT<n>:STATE';

cmds.FREQUENCY=':OUTPUT<n>:LOAD';
cmds.AMPLITUDE_UNIT=':SOURCE<n>:VOLTAGE:UNIT';
cmds.AMPLITUDE=':SOURCE<n>:IMMEDIATE:AMPLITUDE';
cmds.BURST=':OUTPUT<n>:BURST:STATE';
cmds.MOD=':OUTPUT<n>:MOD:STATE';
cmds.SWEEP=':OUTPUT<n>:SWEEP:STATE';

cmds.SWEEP_FREQUENCY_CENTER=':SOURCE<n>:FREQUENCY:CENTER';
cmds.SWEEP_FREQUENCY_SPAN=':SOURCE<n>:FREQUENCY:SPAN';
cmds.SWEEP_FREQUENCY_TIME=':SOURCE<n>:FREQUENCY:TIME';
cmds.SWEEP_FREQUENCY_TYPE=':SOURCE<n>:FREQUENCY:TYPE';
cmds.SWEEP_FREQUENCY_TRIGGER=':SOURCE<n>:SWEEP:TRIGGER:SOURCE';
cmds.SWEEP_HOLDTIME_STOP='SOURCE<n>:SWEEP:HTIME:STOP';
cmds.SWEEP_HOLDTIME_START='SOURCE<n>:SWEEP:HTIME:START';

%% Notify the user
disp(' ');

disp([' Progamming ' DeviceName]);
disp(' - BURST, MOD, and SWEEP are mutually exclusive commands');
disp(' - SWEEP returns to initial frequency at end of sweep.');
disp(' - BURST can only go up to 100 MHz, <300ns trigger latency');
disp(' - MOD is not coded yet.');


% Connect to Rigol
obj=visaConnect(DeviceName);

% If connection faile exit the function
if isempty(obj)
    return;
end   
%% Write and Read

try 
    % Read channe 1 and channel 2 settings.
    ch1_get=readRigol(obj,1);
    ch2_get=readRigol(obj,2);
    disp(ch1_get)
    disp(ch2_get)
catch ME    
    warning('Unable to read from Rigol. Closing connection safely');
    disp(ME);
end


%% Close Connect and Delete
fclose(obj);
delete(obj);


%% Helper Functions

    function out=readRigol(ch)
        out=struct;
        out.NAME=['OUTPUT' num2str(ch)];
        fnames=fieldnames(cmds);

        for kk=1:length(fieldnames(cmds))
            str=cmds.(fnames{kk});              % Get the command for this parameter
            str=strrep(str,'<n>',num2str(ch));  % Replace <n> with the channel  
            str=[str '?'];                      % Add question mark for query
            out.(fnames{kk})=strtrim(query(obj,str));
        end       
    end

end

function obj=visaConnect(DeviceName)
    obj=[];

    try
        % Find the VISA object
        obj = instrfind('Type','visa-usb','RsrcName', DeviceName);
        if isempty(obj)
            obj = visa('NI', DeviceName);
        else
            fclose(obj);
            obj = obj(1);
        end

        % Open the VISA object
        fopen(obj);
        
        % Get basic device information
        nfo = query(obj, '*IDN?');
        nfo=strtrim(nfo);   
        disp(['Established connection to ' nfo]);

    catch ME
        warning(['Unable to connect to ' DeviceName]);
        disp(ME);
    end

end

