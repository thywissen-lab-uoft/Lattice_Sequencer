function curtime = QP_test(timein)

curtime = timein;
global seqdata;
seqdata.flags.Frank = 1;
%% Ramp up QP coils to some value

LF_QP_List =  [0.099];.14;0.115;
    LF_QP = getScanParameter(LF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'LF_QPReverse','V');  
    
    setAnalogChannel(calctime(curtime,0),'Coil 16',0,1);
    setAnalogChannel(calctime(curtime,0),'Coil 15',0,1);
    
    setDigitalChannel(calctime(curtime,0),'Coil 16 TTL',0);
    
    curtime = calctime(curtime,50);
    % Turn off 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',1); 
    curtime = calctime(curtime,10);

    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',0);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage
    QP_FFValue = 23*(LF_QP/.125/30); % voltage FF on delta supply
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        100,100,QP_FFValue);
    curtime = calctime(curtime,50);

    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,LF_QP,1);

%% Wait time
curtime = calctime(curtime,8000);

%% Ramp down QP coils

qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1); 
    curtime = calctime(curtime,100);
    
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            5,5,0); 
    
        % Go back to "normal" configuration
    curtime = calctime(curtime,10);
    % Turn off reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',0);
    curtime = calctime(curtime,10);

    % Turn on 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',1);
    curtime = calctime(curtime,10);
end

