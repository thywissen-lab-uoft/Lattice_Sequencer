%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = MOT_sequence(timein,detuning)

global seqdata;

curtime = timein;


%% Turn on Trap and Repump Light
     %Analog
    setAnalogChannel(calctime(curtime,0),26,0.7); %turn trap AOM intensity to full
    setAnalogChannel(calctime(curtime,0),25,0.55); %turn repump AOM intensity to full
    %TTL
    setDigitalChannel(calctime(curtime,0),6,0);%TTL signal 0 = light, 1 = no light
    setDigitalChannel(calctime(curtime,0),7,0);
    %Shutters
    setDigitalChannel(calctime(curtime,0),2,1);
    setDigitalChannel(calctime(curtime,0),3,1);

%% Set Frequency 
curtime = setAnalogChannel(curtime+1,5,detuning); %32.8MHz detuning

%digital trigger
%DigitalPulse(curtime,12,1000,1);
%% Turn on MOT Coil

%Feed Forward
    curtime = setAnalogChannel(curtime+1,18,10/6.6); 
    %CATS
    curtime = setAnalogChannel(curtime+1,8,15); %15G/cm
    %TTL
    curtime = setDigitalChannel(curtime+1,16,0); %MOT TTL

%% Turn on Shims



    %turn on the Y (quantizing) shim 
    curtime = setAnalogChannel(calctime(curtime,0),19,0.4); 
    %turn on the X (left/right) shim 
    curtime = setAnalogChannel(calctime(curtime,0),27,0.6); 
    %turn on the Z (top/bottom) shim 
    curtime = setAnalogChannel(calctime(curtime,0),28,0.0); 
    


%% Take MOT flourescence image
%list
%loadtime_list=[1000:1000:30000.0];

%Create linear list
%index=seqdata.cycle;

%Create Randomized list
%index=seqdata.randcyclelist(seqdata.cycle);

%loadtime=loadtime_list(index)
%addOutputParam('resonance',loadtime);

%curtime = DigitalPulse(calctime(curtime,15000),1,.75,1);
curtime = calctime(curtime,15000);

%% Shutter Preperation for Absorption
%Open Probe Shutter
curtime = setDigitalChannel(curtime,4,1);
%Open Repump Shutter
curtime = setDigitalChannel(curtime,3,1);
%Open OP Shutter
curtime = setDigitalChannel(curtime,5,1);



%% Compression
%Jump Trap detuning closer to resonance to 7.2MHz
curtime = setAnalogChannel(calctime(curtime,10),5,20);%9.2MHz

%% Compression

%% Absorption

%call absorption image function
curtime=absorption_image(calctime(curtime,2));

%% Close Shutters
%Close Probe Shutter
curtime = setDigitalChannel(curtime,4,0);
%Close Repump Shutter
curtime = setDigitalChannel(curtime,3,0);
%Close OP Shutter
curtime = setDigitalChannel(curtime,5,0);

%% Turn off Shim Coils

%Y-direction (Transport direction/Push coil)
%setAnalogChannel(curtime,14,0,1);

%Z-direction (up/down)
%setAnalogChannel(curtime,15,0,1); 

%X-direction (North-South)
%setAnalogChannel(curtime,16,0,1); 
%% Timeout


timeout = curtime;

end