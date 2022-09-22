function programSRSFinal(settings)
% programSRSFinal.m
%
% Author      : C Fujiwara
% Last Edited : 2022/09/22
%
% This function programs our SRS sources to a single frequency.
%
% This works for the SG380 line of SRS sources
%
% See the SRS manuals for a detailed discussion
%
% Each SRS has a few different options.  However, the biggest difference is
% which port you are going to output on. In principle there are three
% different kinds of outputs :
%
%  H : Frequency doubled output at the back
%  L : "LF" BNC output at front (DC-60 MHz)
%  R : "RF" N type output at front (High frequency)

%% Description of commands
% The commands here 

%%%%%% GPIB Command Summary

% FREQ(?) Set(query) the output frequency

% MODL(?) Set(query) the modulation enable
% MFNC(?) Set(query) the modulation function (typically want mode 5)
    % 0 : Sine wave
    % 1 : Ramp
    % 2 : Triangle
    % 3 : Square
    % 4 : Noise
    % 5 : External
% FDEV(?) Set(query) the modulation range (this is an amplitude)

% ENBH(?) Enable(query) the frequency doubled output
% ENBL(?) Enable(query) the low frequency output
% ENBR(?) Enable (query) the the N type output

% AMPR(?) Set(query) the output power of the front N type output
% AMPL(?) Set(query) the output power of the front BNC output
% AMPH(?) Set(query) the output power of the back output

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


%% Default Settings

defaultSettings=struct;
defaultSettings.GPIB = 28;      % GPIB Address to program

defaultSettings.FREQ = 1285;    % Frequency [MHz]

defaultSettings.MODL = 0;       % Enable or Disable frequency modulation
defaultSettings.FDEV = 1;       % Modulation amplitude [MHz]
defaultSettings.TYPE = 1;       % Modulation type   (1 : frequency)
defaultSettings.MFNC = 5;       % Modulation source (5 : external)

defaultSettings.ENBH = 0;       % Enable H output
defaultSettings.ENBR = 0;       % Enabe RF output
defaultSettings.ENBL = 0;       % Enable LF output

defaultSettings.AMPR = 0;       % Amplitude of RF output [dBm]
defaultSettings.AMPL = 0;       % Amplitude of LF output [dBm]
defaultSettings.AMPH = 0;       % Amplitude of H output [dBm]

defaultSettings.DISP = 2;       % What to display

%% Units

units = struct;
units.FREQ = 'MHz';
units.AMPR = 'dBm';
units.AMPL = 'dBm';
units.AMPH = 'dBm';
units.FDEV = 'MHz';

%% Assign to default if not given

if nargin == 0 
   settings = defaultSettings; 
end

%% Give default values
% If a value is not given, assign it one of the default values

fnames = fieldnames(defaultSettings);
for jj = 1:length(fnames)
    if ~isfield(settings,fnames{jj})
        settings.(fnames{jj}) = defaultSettings.(fnames{jj});
    end    
end

%% Check that only one output is enabled

if sum(settings.ENBH + settings.ENBL + settings.ENBR)~=1
   error('You can only have one SRS output enabled at a time!!'); 
end

%% Print desired output
disp('Programming SRS ');

for kk=1:length(fnames)
    str = ['     ' fnames{kk} ' : ' num2str(settings.(fnames{kk}))];
    
    if isfield(units,fnames{kk})
        str = [str ' ' units.(fnames{kk})];
    end
   disp(str);
end

%% Disable outputs first
% At the beginning disable all outputs. This may not be necessary, but I'm
% not sure how the SRS behaves if you accidnetally enable multiple outputs.

cmds = ['ENBR 0; ENBH 0; ENBL 0;'];

%% Send output commands
for kk=1:length(fnames)
   if ~isequal(fnames{kk},'GPIB')
        cmd = [fnames{kk} ' ' num2str(settings.(fnames{kk}))];       
        if isfield(units,fnames{kk})
            cmd = [cmd ' ' units.(fnames{kk})];
        end
        
        cmd = [cmd ';'];
        
        cmds = [cmds cmd];
   end
end

addGPIBCommand(settings.GPIB,cmd,'Mode','First');

end

