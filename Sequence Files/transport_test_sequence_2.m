%------
%Author: David McKay
%Created: Sept 2012
%Summary: This is for testing the calibration of the transport coils
%------

function timeout = transport_test_sequence_2(timein)

curtime = timein;

global seqdata;

curtime = calctime(curtime,50);

%% Initialize Coils

%turn on voltage
setAnalogChannel(curtime,18,10); 

%close kitten 
setDigitalChannel(curtime,29,0);

%start with all coils off (voltage to 0)
for i = [1 7 8 9:17 22:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
end

curtime = calctime(curtime,50);

%set to current zero
for i = [14:17] 
    setAnalogChannel(calctime(curtime,0),i,0,2);
end

%turn on kitten
setAnalogChannel(curtime,3,0,1);
%open kitten relay
setDigitalChannel(curtime,29,1);
%turn off 15/16 switch
setDigitalChannel(curtime,22,0);
%turn on 15
setAnalogChannel(curtime,21,4);
%turn off 16
setAnalogChannel(curtime,1,0,1);

% %turn on 14
% setAnalogChannel(calctime(curtime,10),22,2);

curtime = calctime(curtime,1000);

%turn on kitten
setAnalogChannel(curtime,3,0,1);
%close kitten relay
setDigitalChannel(curtime,29,0);
%turn off 15/16 switch
setDigitalChannel(curtime,22,0);
%turn on 15
setAnalogChannel(curtime,21,0,1);
%turn off 16
setAnalogChannel(curtime,1,0,1);

% %tunr off 14
% setAnalogChannel(curtime,22,0,1);

%% End
timeout = curtime;


end

