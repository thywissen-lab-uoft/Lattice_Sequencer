%------
%Author: David McKay
%Created: Sept 2012
%Summary: This is a test sequence for running the transport (mimicking
%Load_MagTrap_sequence
%------

function timeout = transport_test_sequence(timein)

curtime = timein;

global seqdata;

do_end_ramp = 1;

initialize_channels;

DigitalPulse(curtime,12,0.1,1);

curtime = calctime(curtime,300);

%% Initialize Coils

%start with all coils off
for i = [1 3 7:17 20:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end

curtime = calctime(curtime,50);

%make sure all switches are set
%fast switch off
setDigitalChannel(curtime,21,0);

%relay is on
setDigitalChannel(curtime,28,0);

%15/16 switch is off!
setDigitalChannel(curtime,22,0);

%kitten is in
setDigitalChannel(curtime,29,1)

%% MOT Stage

%Turn on MOT
setAnalogChannel(curtime,18,10); 
%CATS
setAnalogChannel(curtime,8,10);

curtime = calctime(curtime,100);

%turn off trap (molasses)
setAnalogChannel(curtime,8,0); 
curtime = calctime(curtime,20);

%load into magnetic trap
curtime = Load_MagTrap_from_MOT(curtime);

%% Magnetic Trap

%% Transport

hor_transport_type = 1; %0: min jerk curves, 1: slow down in middle section curves, 2: none
ver_transport_type = 3; %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear, 4: triple min jerk

curtime = Transport_Cloud(curtime, hor_transport_type, ver_transport_type, 1);

%% Turn off Coils


curtime = calctime(curtime,100);

curtime = ramp_QP_after_trans(curtime, do_end_ramp);

curtime = calctime(curtime,100);

%start with all coils off
for i = [1 3 7:17 20:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end

setAnalogChannel(curtime,18,0); 

curtime = calctime(curtime,50);

%make sure all switches are set
%fast switch off
setDigitalChannel(curtime,21,0);

%relay is on
setDigitalChannel(curtime,28,0);

%15/16 switch is off!!
setDigitalChannel(curtime,22,0);

%kitten is in
setDigitalChannel(curtime,29,1)

curtime = calctime(curtime,50);
 
%% End
timeout = curtime;


end

