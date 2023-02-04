function timeout = Load_MagTrap_from_MOT(timein)

global seqdata;

curtime = timein;



ramp_time1 = 1;
hold_time1 = 10;

gradient_value1_list=[0.75];
gradient_value1= getScanParameter(gradient_value1_list,...
    seqdata.scancycle,seqdata.randcyclelist,'gradient_value1');  %in MHZ
gradient_value1=gradient_value1*(1.22 + 89.6*1);

ramp_time2 = 50;
hold_time2 = 10;
gradient_value2 = 50;1.0*(1.22 + 89.6*1);

%Turn on MOT TTL
setDigitalChannel(calctime(curtime,0),'MOT TTL',0);
%1st ramp
AnalogFuncTo(calctime(curtime,0),'MOT Coil',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time1,ramp_time1,gradient_value1);


curtime=calctime(curtime,ramp_time1+hold_time1);

%2nd ramp
curtime = AnalogFuncTo(calctime(curtime,0),'MOT Coil',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time2,ramp_time2,gradient_value2);
% 2nd hold
curtime = calctime(curtime, hold_time2);


timeout = curtime;
end