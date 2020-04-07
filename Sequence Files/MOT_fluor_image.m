%------
%Author: DM
%Created: July 2011
%Summary: This function takes a fluorescence image of the MOT. NOTE: Can
%only be used when the MOT is already on
%------

function timeout=MOT_fluor_image(timein)

global seqdata;

curtime = timein;

wait_time = 1;

%% FLUORESCENCE IMAGING

%curtime = Load_MOT(calctime(curtime,0),30);

   
%% Take 1st probe picture

pulse_length = 1.0;

%setAnalogChannel(calctime(curtime,0),25,0.4);

curtime = calctime(curtime, wait_time);

%Camera trigger (Note: absorption length is set by exposure setting in
%camera program)
DigitalPulse(curtime,26,pulse_length,1); % PixelFly Trigger

%% Take 2nd probe picture after 1s

%shut off MOT gradient (leave beams on)
setAnalogChannel(calctime(curtime,100),8,0,1); % MOT coil
setDigitalChannel(calctime(curtime,100),4,0);  % Turn Rb trap shutter OFF
setDigitalChannel(calctime(curtime,100),3,0);  % Turn K Trap shutter OFF


curtime = calctime(curtime,1000);

setDigitalChannel(calctime(curtime,-10),4,1);  % Turn Rb trap shutter On
setDigitalChannel(calctime(curtime,-10),3,0);  % Turn K Trap shutter ON

%100us Camera trigger
curtime = DigitalPulse(curtime,26,pulse_length,1);

%% Turn Y shim off
setAnalogChannel(curtime,19,0.00);


timeout=curtime;

end
