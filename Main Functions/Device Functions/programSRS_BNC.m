function programSRS_BNC(settings)
% programSRS.m
%
% Author      : C Fujiwara
% Last Edited : 2021/03/30
%
% This function programs our SRS sources to a single frequency.
%
% This works for the SG380 line of SRS sources
%
% See the SRS manuals for a detailed discussion
%
% This current version of code keeps the old addGPIBCommand. As of writing
% of this function, CF is unclear how the GPIB addresses are specified, and
% so treats it as a black box.

if nargin==0
   settings=struct;
   settings.Address=28;
   settings.Frequency=1.3383e+03; % Center Frequency (MHz);
   settings.PowerBNC=15;             % Power (dBM);
   settings.Enable=1;
   settings.EnableSweep=0;        % Whether to sweep the frequency
   settings.SweepRange=100;     % Sweep range in kHz
end

settings.EnableN   = 0;

logText('Programming SRS ');
logText(['     Address      : ' num2str(settings.Address)]);
logText(['     Frequency    : ' num2str(settings.Frequency) ' MHz']);
logText(['     Power        : ' num2str(settings.PowerBNC) ' dBm']);
logText(['     Enable       : ' num2str(settings.EnableBNC)]);
logText(['     Enable Sweep : ' num2str(settings.EnableSweep)]);
logText(['     Sweep Range  : ' num2str(settings.SweepRange) ' MHz']);


% ADDRESSES:
% See SRS manual on how to change GPIB adress
    % 27 - SRS A  (For GM?)
    % 28 - SRS B  1.3-1.5 GHz uWave
    % 29 - SRS RB 6.8 GHz    

% GPIB Command Summary
%
% FREQ(?) Set(query) the output frequency
% AMPR(?) Set(query) the output power
% MODL(?) Set(query) the modulation enable
% MFNC(?) Set(query) the modulation funcy
    % 0 : Sine wave
    % 1 : Ramp
    % 2 : Triangle
    % 3 : Square
    % 4 : Noise
    % 5 : External
% FDEV(?) Set(query) the modulation range

% DISP(?) Set(query) the dispay
%   0 : Modulation Type
%   1 : Modulation Function
%   2 : Frequency
%   3 : Phase
%   4 : Modulation Rate or Period
%   5 : Modulation Deviation or Duty Cycle
%   6 : RF Type-N Amplitude
%   7 : BNC Amplitude
%   8 : RF Double Amplitude
%   9 : Clock Amplitude
%   10 : BNC Offset
%   11 : Rear DC Offset
%   12 : Clock Offset

% ENBR(?) Set(query) the enable state of the Type-N output (0:off 1:on)
cmdstr=['FREQ %fMHz; MODL %g; MFNC %g; FDEV %gMHz;' ...
    'DISP 2; ENBR %g; ENBL %g; AMPL %gdBm; FREQ?'];
cmd=sprintf(cmdstr,...
    settings.Frequency,...
    settings.EnableSweep,...
    5, ...      % Modulating function is always external [-1V,1V]
    settings.SweepRange,...
    settings.EnableN,...
    settings.EnableBNC,...
    settings.PowerBNC);

% cmd=sprintf('FREQ?;')
if ischar(settings.Address)
    % this cmd is for testing purposes
%     cmd = sprintf('FREQ %fMHZ; AMPL %gdBm; FREQ?; AMPL?',...
%         settings.Frequency,...
%         settings.PowerBNC);
    sendIPCommand(cmd,settings.Address)
else
    % disp(cmd)
    addGPIBCommand(settings.Address,cmd);
end

end

function sendIPCommand(command,addr,port)

% Default port is 5024 for srs 
if nargin ==2
   port = 5024; 
end

% Find a tcpip object.
obj1 = instrfind('Type', 'tcpip', 'RemoteHost', addr, 'RemotePort', port, 'Tag', '');

% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = tcpip(addr, port);
else
    fclose(obj1);
    obj1 = obj1(1);
end
%open tcpip object
fopen(obj1);

% flush input
flushinput(obj1);
% write the string
query(obj1, command, '%s\n' ,'%s\n') % but with correct commands
% read the output

fclose(obj1);

end