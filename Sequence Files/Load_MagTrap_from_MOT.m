%------
%Author: DCM
%Created: Aug 2010
%Summary: Loads the MOT into a Magnetic Trap
%------


function timeout = Load_MagTrap_from_MOT(timein)

global seqdata;

curtime = timein;

%% Magnetic Trapping
% updated @ 2018-03-22
    ramp_time1 = 1;
    hold_time1 = 10;
%     gradient_value1 = 0.5*(1.22 + 89.6*1);
    
    gradient_value1_list=[0.7];
    gradient_value1= getScanParameter(gradient_value1_list,seqdata.scancycle,seqdata.randcyclelist,'gradient_value1');  %in MHZ
    gradient_value1=gradient_value1*(1.22 + 89.6*1);
    
    ramp_time2 = 75;
    hold_time2 = 10;
    gradient_value2 = 1.0*(1.22 + 89.6*1);

    %Turn on MOT TTL
    setDigitalChannel(calctime(curtime,0),16,0);
    %1st ramp
    AnalogFuncTo(calctime(curtime,0),'MOT Coil',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time1,ramp_time1,gradient_value1);

    
curtime=calctime(curtime,ramp_time1+hold_time1);

    %2nd ramp
curtime = AnalogFuncTo(calctime(curtime,0),'MOT Coil',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time2,ramp_time2,gradient_value2);
    % 2nd hold
curtime = calctime(curtime, hold_time2);


timeout = curtime;

%%  Magnetic Trapping
% % % % % previous version, before 2018-03-22
% % % % %wait 1.1ms for the push to turn off and turn on the magnetic trap to
% % % % %80G/cm
% % % % 
% % % % % % % %list
% % % % % hold_time1_list=[ 100:400:2100 100:400:2100 100:400:2100];
% % % % % 
% % % % % %Create linear list
% % % % % %index=seqdata.cycle;
% % % % % 
% % % % % %Create Randomized list
% % % % % index=seqdata.randcyclelist(seqdata.cycle);
% % % % % 
% % % % % hold_time1 = hold_time1_list(index)
% % % % % addOutputParam('probe_detuning',hold_time1);
% % % % 
% % % % ramp_time1 = 1; %3
% % % % hold_time1 = 50; %200
% % % % ramp_time2 = 0;
% % % % hold_time2 = 0;
% % % % ramp_time3 = 0;
% % % % hold_time3 = 0;
% % % % ramp_time4 = 0;
% % % % initial_gradient = 1.0*(1.22 + 89.6*1); %1*(1.22 + 89.6*1);
% % % % 
% % % % filter_gradient = 0;
% % % % final_gradient = 0; 
% % % % 
% % % % 
% % % % %curtime = calctime(curtime,-2);
% % % % 
% % % % %Turn on MOT TTL
% % % % setDigitalChannel(calctime(curtime,2.0),16,0);
% % % % 
% % % % %setAnalogChannel(calctime(curtime,-10),18,10); 
% % % % 
% % % % %Turn off science cell MOT
% % % % %...
% % % % 
% % % % 
% % % % %Ramp Up Magnetic Trap
% % % % 
% % % % %     %Ramp 1
% % % % %     %if ramp_time1==0
% % % % %     %    error('Ramp Time 1 is zero, must have finite initial ramp of the mag trap')
% % % % %     %end
% % % % %     AnalogFunc(calctime(curtime,2.0),8,@(t,a)(a+minimum_jerk(t,ramp_time1,initial_gradient)),ramp_time1,0);
% % % % %     setAnalogChannel(calctime(curtime,2.0+ramp_time1),8,initial_gradient);
% % % % %     
% % % % %     %Ramp 2
% % % % %     %if ramp_time2~=0
% % % % %         AnalogFunc(calctime(curtime,2.0+ramp_time1+hold_time1),8,@(t,a)(a + minimum_jerk(t,ramp_time2,final_gradient)),ramp_time2,initial_gradient);
% % % % %         setAnalogChannel(calctime(curtime,1.0+ramp_time1+ramp_time2 + hold_time1),8,final_gradient+initial_gradient);
% % % % %     %end
% % % % %     
% % % % %     %Ramp 3
% % % % %     %if ramp_time3~=0
% % % % %         AnalogFunc(calctime(curtime,2.0+ramp_time1+hold_time1 + hold_time2 + ramp_time2),8,@(t,a)(a - minimum_jerk(t,ramp_time3,filter_gradient)),ramp_time3,final_gradient + initial_gradient);
% % % % %         setAnalogChannel(calctime(curtime,2.0+ramp_time1+hold_time1 + ramp_time2 + hold_time2 + ramp_time3),8,initial_gradient + final_gradient - filter_gradient);
% % % % %         %curtime=AnalogFunc(calctime(curtime,1.0+ramp_time1+hold_time1 + ramp_time2 + hold_time2 + ramp_time3 + hold_time3),8,@(t,a)(a + minimum_jerk(t,ramp_time4,filter_gradient)),ramp_time4,final_gradient + initial_gradient - filter_gradient);
% % % % %     %end
% % % % %     
% % % % %     %Ramp 4
% % % % %     %if ramp_time4~=0
% % % % %         AnalogFunc(calctime(curtime,2.0+ramp_time1+hold_time1 + ramp_time2 + hold_time2 + ramp_time3 + hold_time3),8,@(t,a)(a + minimum_jerk(t,ramp_time4,filter_gradient)),ramp_time4,final_gradient + initial_gradient - filter_gradient);
% % % % %         curtime=setAnalogChannel(calctime(curtime,2.0+ramp_time1+hold_time1 + ramp_time2 + hold_time2 + ramp_time3 + hold_time3 + ramp_time4),8,initial_gradient);  
% % % % %         %curtime=setAnalogChannel(calctime(curtime,1.0+ramp_time1+hold_time1 + ramp_time2 + hold_time2 + ramp_time3 + hold_time3 + ramp_time4),8,0);    
% % % % %     %end
% % % %     
% % % % 
% % % %     %setAnalogChannel(calctime(curtime,2.0),8,40);
% % % %     %AnalogFunc(calctime(curtime,2.0),8,@(t,gi,gf)(gi+(gf-gi)/20*t),20,40,initial_gradient);
% % % %     
% % % %     %AnalogFunc(calctime(curtime,2.0),8,@(t,ramp_time)(initial_gradient/ramp_time*t),ramp_time,ramp_time);
% % % %     setAnalogChannel(calctime(curtime,2),8,1.0*initial_gradient);
% % % %     %setAnalogChannel(calctime(curtime,2),8,20,4);
% % % %     
% % % %     %setAnalogChannel(calctime(curtime,20.0),8,1.0*initial_gradient);
% % % %     %AnalogFunc(calctime(curtime,10.0),8,@(t,tt,gi,gf)(gi+(gf-gi)/tt*t),400,400,1.7*initial_gradient,initial_gradient);
% % % %     
% % % %    curtime = calctime(curtime,hold_time1);
% % % %     
% % % % timeout = curtime;

end