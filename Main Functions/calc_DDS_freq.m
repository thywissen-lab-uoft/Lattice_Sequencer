%------
%Author: DJ
%Created: Dec 2010
%Summary: This function calculates the FTW in unicode format given
%the frequency (i.e. 1.285GHz) 
%------

function y = calc_DDS_freq(frequency,DDS_id)
%%%%%%%%%%%%%%%%%%%%%%%%% April 2014: added input parameter DDS_id to
%%%%%%%%%%%%%%%%%%%%%%%%% address e.g. indiidual calibration factors for
%%%%%%%%%%%%%%%%%%%%%%%%% each DDS (S.T.). If an error occurs in this
%%%%%%%%%%%%%%%%%%%%%%%%% function, this may be the reason. Make sure that
%%%%%%%%%%%%%%%%%%%%%%%%% DDS_id is specified (DDS_id = 1 for evaporation
%%%%%%%%%%%%%%%%%%%%%%%%% DDS). Handed down to calc_DDS_freq.
global seqdata;

%AD9854 parameters
DDS_freq_precision = 2^32;  %2^48
DDS_clock_rate = 1E9;  %300E6

%Microwave PLL circuit multiplication
DDS_multiplication = 1; %50

% individual calibration factors for DDSs
switch DDS_id
    case 1; DDS_calibration = (1+2.33e-7); % evaporation DDS
    otherwise; DDS_calibration = 1;
end

FTW = frequency*DDS_freq_precision/(DDS_multiplication*DDS_clock_rate/DDS_calibration);

%phase-o-matic (6 byte FTW)
%y = [native2unicode(mod(floor(FTW/256^0),256),encoding), native2unicode(mod(floor(FTW/256^1),256),encoding), native2unicode(mod(floor(FTW/256^2),256),encoding), native2unicode(mod(floor(FTW/256^3),256),encoding), native2unicode(mod(floor(FTW/256^4),256),encoding), native2unicode(mod(floor(FTW/256^5),256),encoding)];

%general purpose (4 byte FTW)
y = [char(mod(floor(FTW/256^0),256)), char(mod(floor(FTW/256^1),256)), char(mod(floor(FTW/256^2),256)), char(mod(floor(FTW/256^3),256))];
 

end