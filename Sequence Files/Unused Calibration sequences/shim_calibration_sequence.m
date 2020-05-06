%------
%Author: Stefan Trotzky
%Created: March 2014
%Summary: Ramps the shims for calibration measurements; also includes FB
%ramp
%------

function timeout = shim_calibration_sequence(timein)

curtime = timein;

global seqdata;

%% Test shims
    do_FB = 0;
    do_QP = 0;

    SetDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',0);
    SetDigitalChannel(calctime(curtime,0),'Shim Multiplexer',1);
%     DigitalPulse(calctime(curtime,0),'Field sensor SR',10,1);
%     DigitalPulse(calctime(curtime,0),12,10,1);
    
    %
    DigitalPulse(calctime(curtime,50),'Field sensor SR',10,1);
    DigitalPulse(calctime(curtime,50),'Remote field sensor SR',10,1);
    SetDigitalChannel(calctime(curtime,100),'Bipolar Shim Relay',1);

curtime = calctime(curtime,2000);
    if (do_FB)
        SetDigitalChannel(calctime(curtime,0),31,1);
    end
    
    if (do_QP)
        setDigitalChannel(calctime(curtime,0), 21, 0); % fast QP, 1 is off
        setDigitalChannel(calctime(curtime,0), 22, 1); % 15/16 switch
        setDigitalChannel(calctime(curtime,0),29, 0);
    end

   
    
%     shim_vals = [0.01+0.115,0.023-0.0975,-0.024-0.145]; % zero field at sensor
    shim_vals = [-0.0,0,0.0]; 
    FB_val = 0;
    QP_val = 0*1.78;
    QP_FF = 23*(QP_val/30);
    shim_ramptime = 25;
    FB_ramptime = 100;
    QP_ramptime = 100;

    if (do_FB)
        AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),FB_ramptime,FB_ramptime,0,FB_val);
    end
    
    if (do_QP)
        AnalogFunc(calctime(curtime,-10),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0,QP_FF);
        AnalogFunc(calctime(curtime,0),1,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0,QP_val);
    end
    
    DigitalPulse(calctime(curtime,-1),'ACync Master',shim_ramptime + 17,1);
%     DigitalPulse(calctime(curtime,1.5),'Field sensor SR',1,1);
    ScopeTriggerPulse(calctime(curtime,0),'ACync',1);
    
    AnalogFunc(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,0,shim_vals(1),3);
    AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,0,shim_vals(2),4);
curtime = AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,0,shim_vals(3),3);
    
curtime = calctime(curtime,2000);
curtime = sense_Bfield(calctime(curtime,0));
    

    if (do_FB)
        AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),FB_ramptime,FB_ramptime,0);
        SetDigitalChannel(calctime(curtime,FB_ramptime),31,0);
    end
    
    if (do_QP)
        AnalogFuncTo(calctime(curtime,+10),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0);
        AnalogFuncTo(calctime(curtime,0),1,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0);
        setDigitalChannel(calctime(curtime,QP_ramptime+15), 21, 1); % fast QP, 1 is off
        setDigitalChannel(calctime(curtime,QP_ramptime+15), 22, 0);
    end
    
    shim_final_vals = [0 0 0];
    
    AnalogFuncTo(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,shim_final_vals(1),3);
    AnalogFuncTo(calctime(curtime,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,shim_final_vals(2),4);
curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,shim_final_vals(3),3);

curtime = calctime(curtime,100);

%% 
%% End
timeout = curtime;

        
end
