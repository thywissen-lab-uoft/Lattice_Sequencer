%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = Molassess(timein,detuning)

curtime = timein;


%% Turn on Trap and Repump Light
    %Analog
    curtime = setAnalogChannel(curtime+1,3,1.0); %turn trap AOM intensity to full
    curtime = setAnalogChannel(curtime+1,1,1.0); %turn repump AOM intensity to full
    %TTL
    curtime = setDigitalChannel(curtime+1,6,0);%TTL signal 0 = light, 1 = no light
    curtime = setDigitalChannel(curtime+1,7,0);
    %Shutters
    curtime = setDigitalChannel(curtime+1,2,1);
    curtime = setDigitalChannel(curtime+1,3,1);

%% Set Frequency 
curtime = setAnalogChannel(curtime+1,5,detuning); %32.8MHz detuning


%% Turn on Shim Coils

%Y-direction (Transport direction/Push coil)
setAnalogChannel(curtime,14,0.0,1); %0.5 %0

%Z-direction (up/down)
setAnalogChannel(curtime,15,0.1,1); %0

%X-direction (North-South)
setAnalogChannel(curtime,16,0.2,1); %4 %0.8




timeout=curtime;

end