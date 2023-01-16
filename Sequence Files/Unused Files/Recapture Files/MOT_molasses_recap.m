%------
%Author: Dylan
%Created: May 2013
%Summary:   Turns on optical molasses beams
%------

function [timeout I_QP V_QP]  = MOT_molasses_recap(timein, QP_val, V_QP)
global seqdata;

% timein is the time at which the molasses beams are turned on
    curtime = timein;
     
%imaging molasses parameters    
    img_molasses_detuning = 5;%30 %45
    img_molasses_time = 10;%10
    
%% Turn QP down

    %Turn QP down parameters
        
        QP_ramp_time_recap = 1000; %500
        %starting parameters
         QP_curval = QP_val;
         Vset_start = V_QP; 
        %ending parameters
         QP_value = 5;
         Vset_recap = 10;
        
        
 %ramp up voltage supply depending on transfer
     AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+Vset_start),QP_ramp_time_recap,QP_ramp_time_recap,Vset_recap-Vset_start);
   
    %ramp coil 16
    
     curtime = AnalogFunc(calctime(curtime,20),1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_curval),QP_ramp_time_recap,QP_ramp_time_recap,QP_value-QP_curval);
        

%% turn on the shims for optical pumping and/or molasses
% SHIM COILS !!!
    shim_ramptime = 25;
    
    %These values just guesses for now
    img_xshim = 0;
    img_yshim = 0*0.5;
    img_zshim = 0*0.8;


    %Turn on Shim Supply Relay
        SetDigitalChannel(calctime(curtime,-1),33,1);

    %turn on shims
        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-1),'Y MOT Shim',img_yshim,3); 
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,-1),'X MOT Shim',img_xshim,2); 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-1),'Z MOT Shim',img_zshim,2); 
 
%% turn on trap and repump beams        
        
    %set trap detuning
        setAnalogChannel(calctime(curtime,-3),5,img_molasses_detuning);

        
    %Turn on beams    
        %trap analog
        SetAnalogChannel(calctime(curtime,0),26,1*0.8,1); %trap
        SetAnalogChannel(calctime(curtime,0),25,1*0.8,1); %repump
        %shutter
        SetDigitalChannel(calctime(curtime,0),2,1); %trap
        SetDigitalChannel(calctime(curtime,0),3,1); %repump

        %Pulse beam (AOM TTL on/off)
        DigitalPulse(calctime(curtime,2.5),6,img_molasses_time,0);
        DigitalPulse(calctime(curtime,2.5),7,img_molasses_time,0);
         
%          %Trigger camera during molasses beam on
%          DigitalPulse(calctime(curtime,2.5+img_molasses_time-2),26,2,0);

%% 2ms camera trigger after (img_molasses_time-2ms) of light

    curtime = DigitalPulse(calctime(curtime,2.5+img_molasses_time-1),26,2,1);
    
    %wait 10ms before turning off beams
    calctime(curtime,10)
    
%% turn off trap and repump beams   

    %turn off beams
        %trap
        turn_off_beam(calctime(curtime,0.5),1,0);
        %repump
        curtime = turn_off_beam(calctime(curtime,0.5),2,0);
        
%% Turn off QP    
        qp_ramp_down_time = 250;
        qp_ramp_end = 0;
        ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
   
        AnalogFunc(calctime(curtime,0),1,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time,qp_ramp_down_time,qp_ramp_end,QP_value);
  
        %curtime=calctime(curtime,5)      
    I_QP = qp_ramp_end; 
    V_QP = Vset_recap;
    
    %% turn on trap and repump beams for reference image     

    curtime = calctime(curtime,2000);
    
    %set trap detuning
        setAnalogChannel(calctime(curtime,-3),5,img_molasses_detuning);

        
    %Turn on beams    
        %trap analog
        SetAnalogChannel(calctime(curtime,0),26,1*0.8,1); %trap
        SetAnalogChannel(calctime(curtime,0),25,1*0.8,1); %repump
        %shutter
        SetDigitalChannel(calctime(curtime,0),2,1); %trap
        SetDigitalChannel(calctime(curtime,0),3,1); %repump

        %Pulse beam (AOM TTL on/off)
        DigitalPulse(calctime(curtime,2.5),6,img_molasses_time,0);
        DigitalPulse(calctime(curtime,2.5),7,img_molasses_time,0);
         
%          %Trigger camera during molasses beam on
%          DigitalPulse(calctime(curtime,2.5+img_molasses_time-2),26,2,0);
    
%% 2ms camera trigger for reference image

    curtime = DigitalPulse(calctime(curtime,2.5+img_molasses_time-1),26,2,1);
    
%% turn off trap and repump beams   

    %turn off beams
        %trap
        turn_off_beam(calctime(curtime,0.5),1,0);
        %repump
        curtime = turn_off_beam(calctime(curtime,0.5),2,0);
        
    timeout = curtime;

end