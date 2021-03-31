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

if nargin==0
   settings=struct;
   settings.Address=28;
   settings.Frequency=1.3383e+03; % Center Frequency (MHz);
   settings.Power=15;             % Power (dBM);
   settings.Enable=1;
end

disp('Programming SRS ');
disp(['     Address   : ' num2str(settings.Address)]);
disp(['     Frequency : ' num2str(settings.Frequency) ' MHz']);
disp(['     Power     : ' num2str(settings.Power) ' dBm']);
disp(['     Enable    : ' num2str(settings.Enable)]);

%         SRSAddress = 28;
%         else
%         %SRS A
%         SRSAddress = 27;

% GPIB Command Summary
%
% FREQ(?) Set(query) the output frequency
% AMPR(?) Set(query) the output power
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

cmd=sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',...
    settings.Frequency,settings.Power,settings.Enable);

addGPIBCommand(settings.Address,cmd);
end

