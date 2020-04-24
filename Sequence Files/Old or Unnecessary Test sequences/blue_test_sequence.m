%------
%Author: David McKay
%Created: June 2011
%Summary: For testing the blue MOT
%------

function timeout = blue_test_sequence(timein)

curtime = timein;

global seqdata;


%% Test blue

blue_freq_list = [203:0.25:206];

blue_freq = blue_freq_list(seqdata.randcyclelist(seqdata.cycle))

addOutputParam('blue_freq',blue_freq); 

setAnalogChannel(calctime(curtime,10),8,0);

curtime = setAnalogChannel(calctime(curtime,400),8,10);

curtime = calctime(curtime,2000);

setAnalogChannel(calctime(curtime,100),33,-10.110+0.08323*blue_freq);

setAnalogChannel(calctime(curtime,100),26,0.7);

%blue_on = mod(seqdata.cycle,2)
blue_on = 1;

%blue shutter
curtime = setDigitalChannel(calctime(curtime,200),23,blue_on);

%trap shutter
if blue_on 
        
    setDigitalChannel(calctime(curtime,3.2-2.5),2,0);
    %turn off magnetic field
    setAnalogChannel(calctime(curtime,1.5),8,0);
    
    curtime = calctime(curtime,2.5);
        
end

%turn down repump
setAnalogChannel(calctime(curtime,0),25,0.7);
%0.7 max
%0 min

%trap TTL off
%curtime = setDigitalChannel(calctime(curtime,20),6,1);

%increase trap gradient
%setAnalogChannel(calctime(curtime,0),8,10)

% blue_wait_list = 10:10:300;
% 
% blue_mot_wait_time = blue_wait_list(seqdata.randcyclelist(seqdata.cycle))

blue_mot_wait_time = 0.0;

% Red fluorescence
% red_freq_list = [760 762.5 765 767.5 770 772.5 775 777.5 780 782.5 785 787.5 790 792.5 755 750];
% 
% red_freq = red_freq_list(seqdata.randcyclelist(seqdata.cycle))
% 
% addOutputParam('red_freq',red_freq); 
% 
% %change trap detuning
% setAnalogChannel(calctime(curtime,1),34,red_freq);
% 
% setAnalogChannel(calctime(curtime,1),26,0.005);
% 
% 
% %turn off blue shutter
% setDigitalChannel(calctime(curtime,blue_mot_wait_time-3.5),23,0);
% 
% %turn red back on
% setDigitalChannel(calctime(curtime,blue_mot_wait_time-2.0),2,1);
% 
% %turn field off
% setAnalogChannel(calctime(curtime,blue_mot_wait_time-2.0),8,0);


%collect fluorescence
%trap TTL on
%curtime = setDigitalChannel(calctime(curtime,blue_mot_wait_time-0.2),6,0);

% %set fluorescence detuning
%         setAnalogChannel(calctime(curtime,blue_mot_wait_time-1.0),34,756); %756
%         %offset FF
%          setAnalogChannel(calctime(curtime,blue_mot_wait_time-1.0),35,0.06,1) %0.06
%          



%digital trigger
DigitalPulse(calctime(curtime,blue_mot_wait_time),12,0.1,1);

%cam trigger 
curtime = DigitalPulse(calctime(curtime,blue_mot_wait_time),1,1,1);

%blue shutter
curtime = setDigitalChannel(calctime(curtime,1000),23,0);
%turn trap off
curtime = setDigitalChannel(calctime(curtime,0),2,0);

%reference
curtime = DigitalPulse(calctime(curtime,20),1,1,1);

%turn trap back on
curtime = Load_MOT(calctime(curtime,50),35);

%set offset lock  FF back to zero
%setAnalogChannel(calctime(curtime,blue_mot_wait_time+1200),35,0.00,1)


% timeout = curtime;

end

