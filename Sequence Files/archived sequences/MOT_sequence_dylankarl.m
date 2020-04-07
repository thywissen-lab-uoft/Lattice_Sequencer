%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = MOT_sequence_dylankarl(timein,detuning)

curtime = timein;


%% Turn on AOMs
%trap
curtime = setDigitalChannel(curtime+1,6,0);
%repump
curtime = setDigitalChannel(curtime+1,7,0);

%% Set Frequency 
curtime = setAnalogChannel(curtime+1,5,detuning); %32.8MHz detuning
curtime = setAnalogChannel(curtime+10,3,1.0); %turn trap AOM intensity to full
curtime = setAnalogChannel(curtime+10,1,1.0); %turn repump AOM intensity to full

%% Open Shutters
%trap shutter
curtime = setDigitalChannel(curtime+1,2,1);
%repump shutter
curtime = setDigitalChannel(curtime+1,3,1);

%% Turn on MOT Coil
curtime = setAnalogChannel(curtime+1,8,13.5); %13.5G/cm
%curtime = setAnalogChannel(curtime+1,7,3.00); %3 Gauss in the push coil
curtime = setDigitalChannel(curtime+1,12,1); %MOT TTL

%% Misc
%% Close Shutters%% 
%trap shutter
curtime = setDigitalChannel(curtime+10,2,0);
%repump shutter
curtime = setDigitalChannel(curtime+10,3,0);




timeout = curtime+10;
%% Set Frequency 
curtime = setAnalogChannel(curtime+1,5,detuning); %32.8MHz detuning
curtime = setAnalogChannel(curtime+1,3,1.0); %turn trap AOM intensity to full
curtime = setAnalogChannel(curtime+1,1,1.0); %turn repump AOM intensity to full

timeout = curtime;

end