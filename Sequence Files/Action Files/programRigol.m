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
%
%
%   BASIC TIPS
%
%   CONSTANT FREQUENCY
%   For constant frequency, set BURST, SWEEP, and MOD to OFF. And then
%   you just need to specify the FREQUENCY, and AMPLITUDE. You may also
%   want to make sure that STATE is ON to enable the output
%
%   SWEEP
%   To sweep the frequency, set SWEEP to ON. (BURST and MOD will default
%   to OFF).  Then you just need to specify teh FREQUENCY_CENTER, the
%   AMPLITUDE, the FREQUENCY_SPAN, and the SWEEP_TIME. May also want to
%   want sure that SWEEP_TRIGGER is set to EXT so that you can trigger the
%   device.
%
%   BURST
%   This mode is a bit more complicated because it depends whether you want
%   the Rigol to internally set the maximum burst time (<1E6 cycles,
%   reliable timing) or if you want to externally set the burst time via an
%   external trigger (resolution limited by Adwin to ~5us). This is set by
%   the BURST_MODE to TRIG or GAT respectively.  
%   
%   In TRIG (aka NCYCLE) mode, the NCYCLES are specified which governs the 
%   time.  It is up to the user to calculate the number of cycles for the
%   desired time (you should dothis in sequencer code); it will be 
%   NCYCLES/FREQUENCY. You will also want to verify that the trigger is
%   external (this is a start trigger).
%
%   In GAT mode the burst will begin and end with an external trigger.

%% Default settings

% Some default settings. This should really never be called.
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
%
% Feel free to append additional commands onto here, the code will ignore
% any commands that are not specified in the input structure.
%
% See the programming manual for description of commands

cmds=struct;

cmds.CLOCK_SOURCE=':SYSTEM:ROSCILLATOR:SOURCE';

cmds.LOAD=':OUTPUT<n>:LOAD';
cmds.STATE=':OUTPUT<n>:STATE';

cmds.FREQUENCY=':OUTPUT<n>:LOAD';                               % Hz
cmds.AMPLITUDE_UNIT=':SOURCE<n>:VOLTAGE:UNIT';                  % 
cmds.AMPLITUDE=':SOURCE<n>:VOLTAGE:LEVEL:IMMEDIATE:AMPLITUDE';  % VPP VRMS DBM
cmds.BURST=':SOURCE<n>:BURST:STATE';                            % ON, OFF
cmds.MOD=':SOURCE<n>:MOD:STATE';                                % ON, OFF
cmds.SWEEP=':SOURCE<n>:SWEEP:STATE';                            % ON, OFF

% Specific to SWEEP mode
cmds.SWEEP_FREQUENCY_CENTER=':SOURCE<n>:FREQUENCY:CENTER';  % Hz
cmds.SWEEP_FREQUENCY_SPAN=':SOURCE<n>:FREQUENCY:SPAN';      % Hz
cmds.SWEEP_TIME=':SOURCE<n>:SWEEP:TIME';                    % seconds
cmds.SWEEP_TYPE=':SOURCE<n>:SWEEP:SPACING';                 % LIN, LOG, STE
cmds.SWEEP_TRIGGER=':SOURCE<n>:SWEEP:TRIGGER:SOURCE';       % INT, EXT, MAN
cmds.SWEEP_TRIGGER_SLOPE=':SOURCE<n>:SWEEP:TRIGGER:SLOPE';  % POS,NEG
cmds.SWEEP_HOLDTIME_STOP='SOURCE<n>:SWEEP:HTIME:STOP';      % seconds
cmds.SWEEP_HOLDTIME_START='SOURCE<n>:SWEEP:HTIME:START';    % seconds

% Specific to BURST MODE
cmds.BURST_MODE=':SOURCE<n>:BURST:MODE';                    % TRIG, GAT, INF
cmds.BURST_TRIGGER=':SOURCE<n>:BURST:TRIGGER';              % INT, EXT, MAN
cmds.BURST_TRIGGER_SLOPE=':SOURCE<n>:BURST:TRIGGER:SLOPE';  % POS, NEG
cmds.BURST_PHASE=':SOURCE<n>:BURST:PHASE';                  % degress (also be 0?)
cmds.BURST_NCYCLES=':SOURCE<n>:BURST:NCYCLES';              % Number of cycles

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

% Have the Rigol beep to show that you're talking to it
playBeep;

%% Write and Read

try 
    % Read channe 1 and channel 2 settings.
    ch1_get=readRigol(1);
    ch2_get=readRigol(2);
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

% Have the function generator play a beep;
    function playBeep        
        strBeepON=':SYSTEM:BEEPER:STATE ON';
        strBeepOFF=':SYSTEM:BEEPER:STATE ON';
        strBeepGo=':SYSTEM:BEEPER::IMMEDIATE';
        
        fprintf(obj,strBeepON);
        pause(0.01);
        fprintf(obj,strBeepGo);
        pause(0.01);
        fprintf(obj,strBeepOFF);
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
