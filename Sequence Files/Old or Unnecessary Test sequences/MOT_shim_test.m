%------
%Author: David McKay
%Created: August 2010
%Summary: This turns the MOT mag field off for testing molasses
%------ 

function timeout = MOT_shim_test(timein)


curtime = timein;

mot_ttl = 1;

curtime = calctime(curtime,20);

%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,0),19,1.2); %1.0 for molassess
%turn on the X (left/right) shim 
setAnalogChannel(calctime(curtime,0),27,0.2); %0.30 for molasses
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0),28,0.5); %0.10 for molasses  

setDigitalChannel(curtime,16,mot_ttl);

setAnalogChannel(curtime,5,17.5);

%turn repump down
setAnalogChannel(calctime(curtime,-5),25,0.15);

%turn trap down
setAnalogChannel(calctime(curtime,-5),26,0.4);

curtime = Load_MOT(calctime(curtime,500),30);

timeout = curtime;
