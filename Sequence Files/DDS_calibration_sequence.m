%------
%Author: Stefan Trotzky
%Created: April 2014
%Summary: Some calibrations of our general purpose DDSs
%------

function timeout = test_sequence(timein)

curtime = timein;

global seqdata;

% Connect output of DDS and ourput of frequency locked SRS synthesizer to
% Ch1 and 2 of scope, set scope to XY mode. Select alternatively: use
% appropriate mixer and LP filter to create beat of both sources. Minimize
% frequency difference by adjusting calibration factor. Once satisfied
% transfer calibration factor to cal_DDS_freq.m, assigning it to the
% respective DDS_id. Check calibration by setting factor back to one in
% this function.

MHz = 1e6;

pulse_length = 3000;
frequency = 10*MHz;
factor = 1;%1+2.33e-7;

addGPIBCommand(27,sprintf('FREQ %fMHz; AMPR -10dBm; MODL 0; DISP 2; ENBL 1; FREQ?',frequency/MHz));

ScopeTriggerPulse(calctime(curtime,1000),'DDS Pulse',100);

curtime = do_rf_pulse(calctime(curtime,1000),0,factor*frequency,pulse_length,0,10);

curtime = calctime(curtime,1000);


%% End
timeout = curtime;

        
end
