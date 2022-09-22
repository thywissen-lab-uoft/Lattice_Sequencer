function programSRS(settings)
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
%
%
% Each SRS has a few different options.  However, the biggest difference is
% which port you are going to output on. In principle there are three
% different kinds of outputs

if nargin==0
   settings=struct;
   settings.Address=28;
   settings.Frequency=1.3383e+03; % Center Frequency (MHz);
   settings.Power=15;             % Power (dBM);
   settings.Enable=1;
   settings.EnableSweep=0;        % Whether to sweep the frequency
   settings.SweepRange=100;       % Sweep range in kHz
end


disp('Programming SRS ');
disp(['     Address      : ' num2str(settings.Address)]);
disp(['     Frequency    : ' num2str(settings.Frequency) ' MHz']);
disp(['     Power        : ' num2str(settings.Power) ' dBm']);
disp(['     Enable       : ' num2str(settings.Enable)]);
disp(['     Enable Sweep : ' num2str(settings.EnableSweep)]);
disp(['     Sweep Range  : ' num2str(settings.SweepRange) ' MHz']);


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

cmd=sprintf('FREQ %fMHz; AMPR %gdBm; MODL %g; MFNC %g; FDEV %gMHz; DISP 2; ENBR %g; FREQ?',...
    settings.Frequency,...
    settings.Power,...
    settings.EnableSweep,...
    5, ...      % Modulating function is always external [-1V,1V]
    settings.SweepRange,...
    settings.Enable);

addGPIBCommand(settings.Address,cmd);
end

