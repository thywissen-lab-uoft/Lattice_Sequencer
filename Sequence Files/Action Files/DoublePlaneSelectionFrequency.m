function [frequency] = DoublePlaneSelectionFrequency(f, is1, fs1, is2, fs2)

% [freq] = DoublePlaneSelectionFrequency(f, [Fi1, mFi1], [Ff1, mFf1], [Fi2, mFi2], [Fi2, mFi2])
%
% Finds the frequency (in MHz) for plane selection from state |Fi2, mFi2> 
% to |Ff2, mFf2>, given that plane selection for state |Fi1, mFi1> to |Ff1, mFf1>
% worked at the frequency f (in MHz).  Makes use of the FrequencyToField function.
% G.Edge June 2015

h = 6.6260755e-34;

%Calcluate the field in the plane of interest, based on the 
% working plane selection
B = FrequencyToField(f*1E6, is1, fs1);

frequency = (BreitRabiK(B,fs2(1),fs2(2)) - BreitRabiK(B,is2(1),is2(2)))/h/1000;