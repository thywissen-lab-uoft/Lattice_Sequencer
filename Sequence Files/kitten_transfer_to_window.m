%------
%Author: Dylan
%Created: May 2012
%Summary: Ramp the QP before QP transfer. Outputs are the currents/voltages
%after the ramp
%------
function [timeout I_QP I_kitt V_QP ] = kitten_transfer_to_window(timein, I_QP, I_kitt, V_QP)


curtime = timein;
global seqdata;

%if transfer_during_evap


    
QP_value = I_QP;
Kitten_curval = I_kitt;
vSet = V_QP;

    
    QP_ramp_time = 23000; %500
    QP_curval = QP_value;
    QP_value = QP_curval 
    Kitten_value = (2/11)*QP_value*0;  
    
    vSet_ramp = 1.07*vSet; %24
   
    if vSet_ramp^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
   
     %ramp up voltage supply depending on transfer
     AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),QP_ramp_time,QP_ramp_time,vSet_ramp-vSet);
   
    %ramp coil 16
     AnalogFunc(calctime(curtime,20),1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_curval),QP_ramp_time,QP_ramp_time,QP_value-QP_curval);
    
          
     kitten_time = 0;
     
    %ramp Kitten
     curtime = AnalogFunc(calctime(curtime,kitten_time),3,@(t,tt,dt)(minimum_jerk(t,tt,dt)+Kitten_curval),QP_ramp_time,QP_ramp_time,Kitten_value-Kitten_curval);
    
         
    %set kitten gate voltage to zero
    if Kitten_value==0
        
        setAnalogChannel(calctime(curtime,0),3,0,1);
        
        %physical disconnect kitten
        %make kitten relay an open switch
        setDigitalChannel(calctime(curtime,30),29,0);

        
    end

       
    curtime = calctime(curtime,100);
    
       
    I_QP  = QP_value;
    I_kitt = Kitten_value;
    V_QP = vSet_ramp;
   
    
%else
    
%     I_QP  = QP_value;
%     I_kitt = Kitten_curval;
%     V_QP = vSet;

%end


timeout = curtime;

end