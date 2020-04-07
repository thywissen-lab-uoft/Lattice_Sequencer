%------
%Author: DJ
%Created: Sep 2009
%Summary: This function calls an absorption imaging sequence
%------

function timeout=Recapture_MOT(timein)

global seqdata;

curtime = timein;


%% Recapture MOT

%turn the MOT off
    %CATS
    setAnalogChannel(curtime,8,0);
    %TTL
    setDigitalChannel(curtime,12,0);
    
%turn the trap light off
    %Analog AOM
    setAnalogChannel(curtime,3,0.0);
    %TTL AOM
    setDigitalChannel(curtime,6,1);
    %Shutter
    %setDigitalChannel(curtime,2,0);
    
    %waitlist
tof_list=[0.5:10:110.5];

%Create linear list
index=seqdata.cycle;

%Create Randomized list
%index=seqdata.randcyclelist(seqdata.cycle);

%TOF
%tof=5.5;%for OP, allow 500us for push turn-off - meaning start the tof at 1.9+0.5=2.4ms
tof = tof_list(index)

%Create Output data
addOutputParam('Time Of Flight',tof);

%wait 500 us and turn the MOT back on to 7.2MHz detuning
curtime = Load_MOT(calctime(curtime,tof),7.2);

%cam trigger after 10ms load
curtime = DigitalPulse(calctime(curtime,10),1,5,1);

%turn the trap light off
    %analog
    setAnalogChannel(curtime,3,0.0);
    %TTL
    setDigitalChannel(curtime,6,1);
    %shutter
    setDigitalChannel(curtime,2,0);

    %turn the repump light off
    %analog
    setAnalogChannel(curtime,1,0);
    %TTL
    setDigitalChannel(curtime,7,1);
    %shutter
    curtime = setDigitalChannel(curtime,3,0);

%Load_MOT
curtime = Load_MOT(calctime(curtime,1000),7.2);


%cam trigger after 1s
curtime = DigitalPulse(calctime(curtime,0),1,5,1);

timeout=curtime;

end
