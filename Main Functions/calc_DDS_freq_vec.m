%------
%Author: DJ
%Created: Dec 2010
%Summary: This function calculates the FTW given the frequency
%------

function y = calc_DDS_freq(format,frequency)

global seqdata;

DDS_freq_precision = 2^47;
DDS_clock_rate = 300E6;

FTW = frequency.*DDS_freq_precision/DDS_clock_rate;

if format == 0; %calculate in decimal from 0-255, in 6 bytes, from LSB to MSB

y = [mod(floor(FTW/256^0),256) mod(floor(FTW/256^1),256) mod(floor(FTW/256^2),256) mod(floor(FTW/256^3),256) mod(floor(FTW/256^4),256) mod(floor(FTW/256^5),256)]; 

elseif format == 1; %calculate in hex from 00 - FF
    
y = [dec2hex(mod(floor(FTW/256^0),256)) dec2hex(mod(floor(FTW/256^1),256)) dec2hex(mod(floor(FTW/256^2),256)) dec2hex(mod(floor(FTW/256^3),256)) dec2hex(mod(floor(FTW/256^4),256)) dec2hex(mod(floor(FTW/256^5),256))];

elseif format == 2; %calculate in character from 0 to ^ ( or something)

y = [native2unicode(mod(floor(FTW/256^0),256)) native2unicode(mod(floor(FTW/256^1),256)) native2unicode(mod(floor(FTW/256^2),256)) native2unicode(mod(floor(FTW/256^3),256)) native2unicode(mod(floor(FTW/256^4),256)) native2unicode(mod(floor(FTW/256^5),256))];
    
end