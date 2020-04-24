%------
%Author: DCM
%Created: Aug 2010
%Summary: This is magnetic filter code that used to be in
%Load_MagTrap_sequence
%------


function timeout = magnetic_filter(timein)

global seqdata;

curtime = timein;

%% Magnetic Filter

% %final gradient list
% %post_filter_gradient_list=[-45:2.5:0];
% 
% % %Create linear list
% %index=seqdata.cycle;
% % 
%  %Create Randomized lists
% %index=seqdata.randcyclelist(seqdata.cycle);
% 
% %post_filter_gradient = post_filter_gradient_list(index)
% 
% %Create Output data
% %addOutputParam('distance moved',post_filter_gradient)
% 
%     %paramters
%     post_ramp_time1 =50; %30
%     post_hold_time1 = 0; %250
%     post_ramp_time2 = 0; %30
%     post_hold_time2 = 0; %150 must keep this >150 or atoms will be captured
%     post_final_gradient = 51.03;
%     post_filter_gradient =0;
%     
%     %curve
%     AnalogFunc(calctime(curtime,50),8,@(t,a)(a + minimum_jerk(t,post_ramp_time1,post_filter_gradient)),post_ramp_time1,post_final_gradient);
%     setAnalogChannel(calctime(curtime,50 + post_ramp_time1),8,post_final_gradient + post_filter_gradient);
%     AnalogFunc(calctime(curtime,50 + post_ramp_time1 + post_hold_time1),8,@(t,a)(a - minimum_jerk(t,post_ramp_time2,post_filter_gradient)),post_ramp_time2,post_final_gradient + post_filter_gradient);
%     setAnalogChannel(calctime(curtime,50 + post_ramp_time1 + post_hold_time1 + post_ramp_time2),8,+post_final_gradient);
%     curtime = setAnalogChannel(calctime(curtime,50 + post_ramp_time1 + post_hold_time1 + post_ramp_time2 + post_hold_time2),8,0);
%     
%     %TTL
%     curtime = setDigitalChannel(curtime,12,0);
%     
%     %trigger
%     DigitalPulse(curtime,13,0.10,1);
 
timeout = curtime;

end