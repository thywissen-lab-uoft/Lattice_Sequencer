%------
%Author: DM
%Created: June 2011
%Summary: This function calls an absorption imaging sequence with the blue
%------

function timeout=blue_absorption_image(timein, image_loc)

global seqdata;

curtime = timein;

%digital trigger
DigitalPulse(curtime,12,0.1,1);

tof = 1.5;%1.5 %-0.5

%addOutputParam('tof',tof);

if nargin < 2
    image_loc = 0;
end

blue_shutter = 23;
blue_shutter_lag = 2.5;

if image_loc == 0
    
     %list
%   detuning_list=[203:0.1:204.4 203:0.1:204.4 203:0.1:204.4];
% 
%   detuning =  detuning_list(seqdata.randcyclelist(seqdata.cycle))
%  addOutputParam('resonance', detuning);    
    
   
    detuning = 204.2;
   
    detune_channel = 33;
    
elseif image_loc == 1
    %to do
else
    error('Invalid absorption imaging settings');
end

%% ABSORPTION IMAGING

%% Pre-Absorption Shutter Preperation
%Open Probe Shutter
setDigitalChannel(calctime(curtime,tof-blue_shutter_lag),blue_shutter,1); %-10

%Open Repump Shutter
setDigitalChannel(calctime(curtime,0.1),3,1);  
%turn repump back up
setAnalogChannel(curtime,25,0.7);
%repump TTL...leave on the whole time
setDigitalChannel(calctime(curtime,0),7,0);  
    
%% Turn on quantizing field

    
%turn the Y (quantizing) shim on after magnetic trapping

% if image_loc == 0;
%     setAnalogChannel(calctime(curtime,0),19,3.5); %had this at 3.5, timing at 1 for abs from MOT
% elseif image_loc == 1;
%     setAnalogChannel(calctime(curtime,0),19,3.5); %4.0
% end


% Turn Y shim off 100ms later
setAnalogChannel(calctime(curtime,100),19,0.00);
    

%% Prepare detuning, repump, and probe
 
%set detuning
setAnalogChannel(calctime(curtime,tof-30.0),detune_channel,-10.110+0.08323*detuning);

    
%% Take 1st probe picture

pulse_length = 0.2;

%Trigger
curtime = calctime(curtime,tof);
do_abs_pulse(curtime,pulse_length);

%digital trigger
DigitalPulse(curtime,12,0.1,1);

%close the shutter again
setDigitalChannel(calctime(curtime,10),blue_shutter,0); 

%% Take 2nd probe picture after 1s

%100us Camera trigger
curtime = calctime(curtime,1000);

%open the shutter
setDigitalChannel(calctime(curtime,-blue_shutter_lag),blue_shutter,1); 

do_abs_pulse(curtime,pulse_length)

%% Turn Probe and Repump off

curtime = calctime(curtime,100);

%blue shutter
setDigitalChannel(curtime,blue_shutter,0); 

%Repump
turn_off_beam(curtime,2);

timeout=curtime;


    function do_abs_pulse(curtime,pulse_length)
        %Camera trigger
        DigitalPulse(curtime,1,pulse_length,1);
        %Repump pulse
        %DigitalPulse(curtime,7,pulse_length,0);
    end

end
