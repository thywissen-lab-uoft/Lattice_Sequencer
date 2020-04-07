%------
%Author: DJ
%Created: Dec 2010
%Summary: This function calculates the FTW in either decimal, hex, or character format given
%the frequency (i.e. 1.285GHz) 
%------

function y = set_DDS_freq(frequency)

global seqdata;


%define which profile (from 0-3) to save frequency in:
profile = 1;

y = [native2unicode(hex2dec('A5')), native2unicode(profile), calc_DDS_freq(frequency)];
     

end