%------
%Author: DCM
%Created: Aug 2010
%Summary: Loads the MOT into a Magnetic Trap
%------

%RHYS - This code is rather short and self-explanatory. Check timings,
%remove old code commented at bottom. 
function timeout = Load_MagTrap_from_MOT(timein)

global seqdata;

curtime = timein;

%% Magnetic Trapping
% updated @ 2018-03-22
   
    ramp_time1 = 1;
    hold_time1 = 10;
%     gradient_value1 = 0.5*(1.22 + 89.6*1);  

    gradient_value1_list=[0.75];
    gradient_value1= getScanParameter(gradient_value1_list,seqdata.scancycle,seqdata.randcyclelist,'gradient_value1');  %in MHZ
    gradient_value1=gradient_value1*(1.22 + 89.6*1);
%     gradient_value1=gradient_value1*gradient_value2;

%      ramp_time2_list = [50:2:100];
%      ramp_time2 = getScanParameter(ramp_time2_list,seqdata.scancycle,seqdata.randcyclelist,'ramp_time2');  

    ramp_time2 = 50;
    hold_time2 = 10;
    gradient_value2 = 50;1.0*(1.22 + 89.6*1);
    
    % Special ramp paramter CF
%     gList=5:5:100;
%     gradient_value1 = 100;
%     gradient_value2 = getScanParameter(gList,seqdata.scancycle,seqdata.randcyclelist,'gradient');
%     gradient_value2=30;
    
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
end