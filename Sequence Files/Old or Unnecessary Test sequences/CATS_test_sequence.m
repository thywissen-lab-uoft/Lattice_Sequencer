%------
%Author: David McKay
%Created: Sept 2012
%Summary: This is a test sequence for the CATS
%------

function timeout = CATS_test_sequence(timein)

curtime = timein;

global seqdata;

initialize_channels;

%% Test QP Ramp Down

%Turn on coil 16

%make sure fast switch is off
setDigitalChannel(curtime,21,0);

%15/16 switch is on
setDigitalChannel(curtime,22,0);

curtime = calctime(curtime,20);

%23.1, 15.4

%set all coils to off
for i = [1 3 7:17 20:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end


%connect kitten
setDigitalChannel(calctime(curtime,0),29,1);

%15/16 switch is off (0) on (1) (nb: current flows when set to 1)
setDigitalChannel(calctime(curtime,20),22,1);

%relay
%setDigitalChannel(calctime(curtime,0),28,0);
 
%voltage
setAnalogChannel(curtime,18,10);

%7: push
%8: MOT
%9-17: Horizontal
%22: 12a
%23: 12b
%24: 13
%20: 14
%21: 15
%3: kitten
%1: 16

%curtime = setAnalogChannel(calctime(curtime,250),24,-5);
%curtime = setAnalogChannel(calctime(curtime,250),1,5);

curtime = setAnalogChannel(calctime(curtime,250),24,-5);
%curtime = setAnalogChannel(calctime(curtime,0),1,15);

%curtime = setAnalogChannel(calctime(curtime,1250),23,6);
%curtime = setAnalogChannel(calctime(curtime,0),7,0,1);

%curtime = setAnalogChannel(calctime(curtime,0),1,19.8);
% curtime = setAnalogChannel(calctime(curtime,500),22,0.5,1);
% curtime = setAnalogChannel(calctime(curtime,500),22,1.0,1);
% curtime = setAnalogChannel(calctime(curtime,500),22,1.5,1);
% curtime = setAnalogChannel(calctime(curtime,500),22,2.0,1);

%curtime = AnalogFunc(calctime(curtime,1050),20,@(t,tt,I0)(-I0/tt*t+5),1000,1000,10);
%setAnalogChannel(curtime,3,12); %kitten
 
% freqs_1b = [10*0.8 4 1.0 0.38]*1E6; %0.28 %0.315
%     RF_gain_1b = [-4 -4 -4]; %-4
%     sweep_times_1b = [3000 1500 1500]; %1500
% %  
% curtime = do_evap_stage(curtime, 1, freqs_1b, sweep_times_1b, RF_gain_1b, 0, 1);
% 

 
 %turn off
 curtime = calctime(curtime,1000);
 
 %ramp down in 200ms
 %curtime = AnalogFunc(calctime(curtime,150),1,@(t,tt,I0)((I0-23.1)/tt*t+23.1),200,200,5);
 
 curtime = calctime(curtime,500);
 
  %ramp up voltage supply depending on transfer
 setAnalogChannel(curtime,18,0);
 %set all coils to off
for i = [1 3 7:17 20:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end
%  
 
%% End
timeout = curtime;


end

