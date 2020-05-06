%------
%Author: DM
%Created: Feb 2011
%Summary: This function calls a fluorescence imaging sequence
%------

function timeout=fluor_image(timein)

global seqdata;

curtime = timein;

tof=2;%2

%take an image in the magnetic trap
in_trap_img = 1;
  
if in_trap_img
    tof = -100;
end

%0: trap light, 1: plug beam, 2: dipole 2 beam, 3: Science chamber molasses
%beams 
fluor_type = 0;


%% FLUORESCENCE IMAGING

%% Prepare detuning, repump, and probe

if fluor_type == 0
    
    %shutters (K Trap and K Repump)
    setDigitalChannel(calctime(curtime,-5),2,1);
    setDigitalChannel(calctime(curtime,-5),3,1);
    
    %keep TTL off
    setDigitalChannel(calctime(curtime,-5),6,1);
    setDigitalChannel(calctime(curtime,-5),7,1);
    
    %set power
    setAnalogChannel(calctime(curtime,-5),25,0.7);
    setAnalogChannel(calctime(curtime,-5),26,0.7);
    
    %set detuning
    setAnalogChannel(calctime(curtime,-5),5,5)
    
elseif fluor_type == 1
    
    %open fluorescence beam shutter
    setDigitalChannel(calctime(curtime,tof-4),10,1);
    
elseif fluor_type == 2 % dipole 2 beam
    
    %Dipole beam is already on
    
elseif fluor_type == 3 %molasses beams
    
    %Prepare the beams just like when using trap light, a small amount is
    %picked off and sent into the fiber for molasses
    
    %shutters
    setDigitalChannel(calctime(curtime,-5),2,1);
    setDigitalChannel(calctime(curtime,-5),3,1);
    
    %keep TTL off
    setDigitalChannel(calctime(curtime,-5),6,1);
    setDigitalChannel(calctime(curtime,-5),7,1);
    
    %set power
    setAnalogChannel(calctime(curtime,-5),25,0.7);
    setAnalogChannel(calctime(curtime,-5),26,0.7);
    
    %set detuning
    setAnalogChannel(calctime(curtime,-5),5,5)
    

    
else
   error('Undefined fluorescence type');
end
   
    
%% Take 1st probe picture

pulse_length = 0.1;

curtime = calctime(curtime, tof);
ScopeTriggerPulse(curtime,'Start TOF',0.1);

if fluor_type == 0
    setDigitalChannel(curtime,6,0);
    setDigitalChannel(curtime,7,0);
elseif fluor_type == 1
    setAnalogChannel(curtime,33,1);%0.4
elseif fluor_type == 2    
    %setAnalogChannel(calctime(curtime,0),38,0.25,1);
    %setAnalogChannel(calctime(curtime,1.5),38,,-0.3,1);
elseif fluor_type == 3
    setDigitalChannel(curtime,6,0);
    setDigitalChannel(curtime,7,0);
end

%100us Camera trigger
DigitalPulse(curtime,26,pulse_length,1);

%% Take 2nd probe picture after 1s

%100us Camera trigger
curtime = DigitalPulse(calctime(curtime,1000),26,pulse_length,1);

%shut off fluorescence beam
curtime = setAnalogChannel(calctime(curtime,100),33,0);


%% Turn Y shim off
setAnalogChannel(curtime,19,0.00);

%turn off fluorescence beam

if fluor_type == 0
    turn_off_beam(curtime,1);
    turn_off_beam(curtime,2);
elseif fluor_type == 1
    turn_off_beam(curtime,5);
elseif fluor_type == 2    
    %setAnalogChannel(calctime(curtime,0),38,0.25,1);
    %setAnalogChannel(calctime(curtime,1.5),38,,-0.3,1);
elseif fluor_type == 3
    turn_off_beam(curtime,1);
    turn_off_beam(curtime,2);    
end


timeout=curtime;

end
