%------
%Author: DJ
%Created: Aug 2010
%Summary: This can be used to measure temperature from a recaptured MOT
%signal
%------


function timeout = MagTrap_filter(timein)

global seqdata;

curtime = timein;

%%  Magnetic Filtering

hold_time1 = 100;
rampdown_time = 400; %400
hold_time2 = 600; %100
rampup_time = rampdown_time; %3
hold_time3 = 200;

initial_gradient = 1*(1.22 + 89.6*1); %1*(1.22 + 89.6*1);
filter_gradient = 10;
final_gradient = initial_gradient;


% %list
% filter_gradient_list=[5:1:16];
% 
% %Create linear list
% index=seqdata.cycle;
% 
% %Create Randomized list
% %index=seqdata.randcyclelist(seqdata.cycle);
% 
% filter_gradient = filter_gradient_list(index)
% addOutputParam('resonance',filter_gradient);



%Turn on MOT TTL
setDigitalChannel(calctime(curtime,2.0),16,0);
   
%Ramp Up Magnetic Trap

    %Hold at initial gradient
    setAnalogChannel(calctime(curtime,2.0),8,initial_gradient);
    
    %Ramp down to filter gradient and hold
    %if ramp_time1==0
    %    error('Ramp Time 1 is zero, must have finite initial ramp of the mag trap')
    %end
    AnalogFunc(calctime(curtime,2.0+hold_time1),8,@(t,a)(a-minimum_jerk(t,rampdown_time,initial_gradient-filter_gradient)),rampdown_time,initial_gradient);
    setAnalogChannel(calctime(curtime,2.0+hold_time1+rampdown_time),8,filter_gradient);
    
    %Ramp back up to final gradient and hold
    if rampup_time~=0
       AnalogFunc(calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2),8,@(t,a)(a + minimum_jerk(t,rampup_time,final_gradient-filter_gradient)),rampup_time,filter_gradient);
       setAnalogChannel(calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2+rampup_time),8,final_gradient);
    end
    
    
    %Hold at final gradient for hold_time3:
    curtime=calctime(curtime,2.0+hold_time1+rampdown_time+hold_time2+rampup_time+hold_time3);
    
    
timeout = curtime;

end