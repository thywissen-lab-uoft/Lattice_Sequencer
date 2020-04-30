%------
%Author: Dylan
%Created: May 2012
%Summary: Ramp the QP before QP transfer. Outputs are the currents/voltages
%after the ramp
%------
function [timeout I_QP I_kitt V_QP I_fesh] = ramp_QP_before_transfer(timein, ramp_down_QP_before_transfer, I_QP, I_kitt, V_QP, I_fesh)


curtime = timein;
global seqdata;

%RHYS - why the heck is there an if statement with the same title as the
%function here?
if ramp_down_QP_before_transfer


QP_value = I_QP;
Kitten_curval = I_kitt;
vSet = V_QP;


%Feshval = 0;
Feshval = I_fesh ;
    
    %RHYS - A parameter that can be modulated to control trap compression
    %at RF1B. Note that changing will move trap if shims not also scaled in
    %the known way (linear interpolation between plug shim and shim zero
    %values). Recently raised, although one would think smaller would be
    %better here. Could try the JILA trick of decompressing further during
    %RF1B evaporation also.
    ramp_factor = 0.8; %0.7 DCM added 0.6 Aug 18
    
    QP_ramp_time = 500; %500
    QP_curval = QP_value;
    QP_value = QP_curval*ramp_factor; 
    Kitten_value = (2/11)*QP_value*0;  
    
    vSet_ramp = 22.0*ramp_factor*1.2; %24 %DCM added 1.2 Aug 18
   
    if vSet_ramp^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
   
     %ramp up voltage supply depending on transfer
     AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),QP_ramp_time,QP_ramp_time,vSet_ramp-vSet);
   
    %ramp coil 16
     AnalogFunc(calctime(curtime,20),1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_curval),QP_ramp_time,QP_ramp_time,QP_value-QP_curval);
    
     %ramp Feshbach
     if Feshval>0
        AnalogFunc(calctime(curtime,0),38,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+Feshval),QP_ramp_time,QP_ramp_time,Feshval);
     end
     
     kitten_time = 0;
     
    %ramp Kitten
    %RHYS - I think the kitten ramps to 0 here, as one might expect, but
    %please check.
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
    I_fesh = Feshval;
    
else
    
%     I_QP  = QP_value;
%     I_kitt = Kitten_curval;
%     V_QP = vSet;

end


timeout = curtime;

end