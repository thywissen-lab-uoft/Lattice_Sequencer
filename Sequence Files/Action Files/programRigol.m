function programRigol(settings)
% programRigol.m
%
% Author : C Fujiwara
% Last Edited : 2021/03/31
%
% This code programs the Rigol DG4162 which we use in lab as a function
% generator in lab to drive AOMs.  This code includes a brief overview of
% the functioning of thiese function generators.
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
%
%
%
end

