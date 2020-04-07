%------
%Author: DM and DF
%Created: Nov 2011
%Summary: For looking at the blue probe fluorescence in the red MOT
%------

function timeout=blue_probe_MOT_fluor(timein)

global seqdata;

curtime = timein;


%addOutputParam('is_background',0);


%wait some time
curtime = calctime(curtime,1);


%identify which AOM is being used
AOM200MHz = 1;
AOM100MHz = 0;

%build a detuning list
 blue_detuning1 = 195;
 blue_detuning2 = 225;
 sweep_time = 75E3;
 
 frame_period = 2.5E3;    
 detuning_step = (blue_detuning2-blue_detuning1)/(sweep_time/frame_period);


for i = 1:((sweep_time)/(frame_period));
% for i = 1:((sweep_time)/(frame_period));
   
    if AOM200MHz
        %set detuning
        setAnalogChannel(calctime(curtime,0),33,-10.110+0.08323*(blue_detuning1+i*detuning_step));

        %trigger camera once
        curtime = DigitalPulse(calctime(curtime,1/2*frame_period),1,10,1);

        %trigger camera again
        curtime = DigitalPulse(calctime(curtime,1/2*frame_period),1,10,1);
    
    elseif AOM100MHz
         %set detuning
        setAnalogChannel(calctime(curtime,0),33,-11.74178+0.18006*(blue_detuning1+i*detuning_step));

        %trigger camera once
        curtime = DigitalPulse(calctime(curtime,1/2*frame_period),1,10,1);

        %trigger camera again
        curtime = DigitalPulse(calctime(curtime,1/2*frame_period),1,10,1);  
        
        
    end
     
    
end



timeout = curtime;


end
