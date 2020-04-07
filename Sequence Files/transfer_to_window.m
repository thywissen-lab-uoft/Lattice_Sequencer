%------
%Author: Dave
%Created: May 2012
%Summary: Run through a list of evaporation frequencies
%------
function [timeout I_QP I_kitt V_QP] = transfer_to_window(timein, I_QP0, I_kitt0, V_QP0, do_transfer, ramp_down_grad)


curtime = timein;
global seqdata;

if do_transfer
    
%      %list
%    evap_time_list=[0:1000:7000];
% 
%     % 
%     % %Create linear list
%     %index=seqdata.cycle;
%     
%     % 
%     % %Create Randomized list
%     index=seqdata.randcyclelist(seqdata.cycle);
%     %index = seqdata.cycle;
%     % 
%     evap_time = evap_time_list(index);
%     addOutputParam('evap_time',evap_time); 
    
    %transfer parameters
    QP_transfer_time = 1000; %1000
    QP_transfer_hold_time = 100+100; 
    
    
    end_kitten_val =  I_kitt0*0.0; %3.6-2 = +1, %1.1


    vset1 = V_QP0;
    vset2 = 1.07*vset1;

    %ramp up voltage
    AnalogFunc(calctime(curtime,-20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vset1),QP_transfer_time,QP_transfer_time,vset2-vset1);
    
    %ramp down kitten
    curtime = AnalogFunc(curtime,3,@(t,tt,dt)(minimum_jerk(t,tt,dt)+I_kitt0),QP_transfer_time,QP_transfer_time,end_kitten_val-I_kitt0);

    if (end_kitten_val <= 1.1)
        end_kitten_val = 0;
    end
    
    if end_kitten_val == 0
        %set kitten voltage to 0
        curtime = setAnalogChannel(curtime,3,0,1);

        %physical disconnect kitten
        %make kitten relay an open switch
        setDigitalChannel(calctime(curtime,10),29,0);

    end

    %hold at position
    curtime = calctime(curtime, QP_transfer_hold_time);
         
    I_QP = I_QP0;
    I_kitt = end_kitten_val;
    V_QP = vset2;
    
else
    
    %nothing's changed
    I_QP = I_QP0;
    I_kitt = I_kitt0;
    V_QP = V_QP0;

end

if ramp_down_grad

    RD_time2 = 500;
    ramp_down_2_factor = 0.7;%0.4

    start_QP_RD_current2 = I_QP;
    end_QP_RD_current2 = I_QP*ramp_down_2_factor;

    start_RD_voltage2 = V_QP;
    end_RD_voltage2 = start_RD_voltage2*ramp_down_2_factor;

    %ramp down coil 16
    AnalogFunc(curtime,1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+start_QP_RD_current2),RD_time2,RD_time2,end_QP_RD_current2-start_QP_RD_current2);

    %ramp down voltage
    curtime = AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+start_RD_voltage2),RD_time2,RD_time2,end_RD_voltage2-start_RD_voltage2);
   
    I_QP = end_QP_RD_current2;
    V_QP = end_RD_voltage2;
    
end

    
timeout = curtime;

end

%% Old tranfers

% if bottom_QP_only %only turn I_bleed on
%         
%         Bleed_value = 0;
%         
%         %resistance increase
%         vSet_ramp = 0.755*(QP_value+Bleed_value/1.8)+0.75;
%                 
%         %ramp up voltage supply depending on transfer
%          AnalogFunc(calctime(curtime,-200),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),QP_transfer_time,QP_transfer_time, vSet_ramp, vSet);
%         
%               
%          curtime = AnalogFunc(curtime,37,@(t,tt,dt)(minimum_jerk(t,tt,dt)),QP_transfer_time,QP_transfer_time,Bleed_value);
%          curtime = calctime(curtime,QP_transfer_hold_time);   
%          
%     elseif top_QP_only %condition is I_bleed = I_16
%       
%         Bleed_value = 18;
%         addOutputParam('Bleed_value',Bleed_value);
%         
%         %resistance increase
%         vSet_ramp = 0.755*(QP_value-Bleed_value/2)+0.75;
%                 
%         %ramp up voltage supply depending on transfer
%          AnalogFunc(calctime(curtime,100),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),QP_transfer_time,QP_transfer_time, vSet_ramp, vSet);
%             
%          %ramp up bleed FET
%          AnalogFunc(curtime,37,@(t,tt,dt)(minimum_jerk(t,tt,dt)),QP_transfer_time,QP_transfer_time,Bleed_value);
%          %ramp down coil 16
%          curtime = AnalogFunc(curtime,1,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+QP_value),QP_transfer_time,QP_transfer_time,Bleed_value);
%       
%          curtime = calctime(curtime,QP_transfer_hold_time);   
%         
%     elseif both_QP %condition is I_bleed = 2*I_16
%         
%         QP_transfer_scale = 0.75; 
% 
%         Bleed_value = 11.3;
%         
%         %resistance increase
%         %vSet_ramp = 0.755*(QP_value+Bleed_value/(1.0))+0.75;
%         vSet_ramp = 0.755*(QP_value+Bleed_value/(0.5))*QP_transfer_scale+0.75;
%                 
%         %ramp up voltage supply depending on transfer
%          AnalogFunc(calctime(curtime,-300),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),QP_transfer_time,QP_transfer_time, vSet_ramp, vSet);
%          %AnalogFunc(curtime,18,@(t,tt,dt)(minimum_jerk(t,tt,dt)),QP_transfer_time,QP_transfer_time,QP_transfer_scale*Bleed_value);
%          
%         addOutputParam('Bleed_value',Bleed_value);
%      
%          %ramp up bleed FET
%          AnalogFunc(curtime,37,@(t,tt,dt)(minimum_jerk(t,tt,dt)),QP_transfer_time,QP_transfer_time,QP_transfer_scale*Bleed_value);
%          %ramp down coil 16
%          %curtime = AnalogFunc(curtime,1,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+QP_value),QP_transfer_time,QP_transfer_time,Bleed_value/(2));
%          curtime = AnalogFunc(curtime,1,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+QP_value),QP_transfer_time,QP_transfer_time,QP_transfer_scale*(Bleed_value/2-QP_value)+QP_value);
%  
%          curtime = calctime(curtime,QP_transfer_hold_time);   
        