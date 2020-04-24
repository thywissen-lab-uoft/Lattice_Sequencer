%------
%Author: DJ
%Created: Aug 2010
%Summary: This can be used to measure temperature from a recaptured MOT
%signal
%------


function timeout = cube_MagTrap_filter(timein,coil_channel,sign)

global seqdata;

curtime = timein;

%%  Magnetic Filtering

hold_time1 = 100;
rampdown_time = 400; %400
hold_time2 = 600; %100
rampup_time = rampdown_time; %3
hold_time3 = 200;

cube_filter_gradient = 19.0519;

% %list
% cube_filter_gradient_list=[2:0.4:5.8];
% 
% %Create linear list
% index=seqdata.cycle;
% 
% %Create Randomized list
% %index=seqdata.randcyclelist(seqdata.cycle);
% 
% cube_filter_gradient = cube_filter_gradient_list(index)
% addOutputParam('resonance',cube_filter_gradient);

if coil_channel == 22

initial_gradient = sign*19.0519*1.0; %1*(1.22 + 89.6*1);
filter_gradient = sign*cube_filter_gradient*1.0;
final_gradient = sign*19.0519*1.0;

elseif coil_channel == 23

initial_gradient = sign*19.0519*1.0; %1*(1.22 + 89.6*1);
filter_gradient = sign*cube_filter_gradient*1.0;
final_gradient = sign*19.0519*1.0;

end
    





%Turn on MOT TTL
%setDigitalChannel(calctime(curtime,2.0),16,0);



%Ramp Up Magnetic Trap

    %Hold at initial gradient
    setAnalogChannel(calctime(curtime,2.0),coil_channel,initial_gradient);
    
    %Ramp down to filter gradient and hold
    %if ramp_time1==0
    %    error('Ramp Time 1 is zero, must have finite initial ramp of the mag trap')
    %end
    AnalogFunc(calctime(curtime,2.0+hold_time1),coil_channel,@(t,a)(a-minimum_jerk(t,rampdown_time,initial_gradient-filter_gradient)),rampdown_time,initial_gradient);
    setAnalogChannel(calctime(curtime,2.0+hold_time1+rampdown_time),coil_channel,filter_gradient);
    
    %Ramp back up to final gradient and hold
    if rampup_time~=0
       AnalogFunc(calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2),coil_channel,@(t,a)(a + minimum_jerk(t,rampup_time,final_gradient-filter_gradient)),rampup_time,filter_gradient);
       setAnalogChannel(calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2+rampup_time),coil_channel,final_gradient);
    end
    
    
    %Hold at final gradient for hold_time3:
    curtime=calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2+rampup_time+hold_time3);
    



timeout = curtime;

end