%------
%Author: Dave
%Created: May 2012
%Summary: Ramp the QP after transport. Outputs are the currents/voltages
%after the ramp
%------
%RHYS - Never played with this much. Combination of QP value and kitten
%value (and shim values) sets the trap depth and position. Could experiment
%with this for RF1A. Probably the trap cannot be much deeper, but also,
%because it is so deep (high current) and because RF1A lasts so long, the
%coils heat considerably.
function [timeout I_QP I_kitt V_QP I_fesh] = ramp_QP_after_trans(timein, do_ramp_qp)


curtime = timein;
global seqdata;

%raise QP starting value
%rev 45
    QP_value = 18.89;
    %QP_value = 15.25; %relaxed gradient
%rev 48
    %QP_value = 16.5;

%Kitten starting value
%rev 45
    Kitten_curval = 10.18; %10.99 %raised QP normal
    %Kitten_curval = 8; %raised QP relaxed gradient
    %Kitten_curval = 6.2; %QP normal
%rev 48
    %Kitten_curval = 7.7;
    
%Current voltage
vSet = 12.25;

%Feshbach current
Feshval = 0;

if do_ramp_qp
   
    %turn off kitten and coil 14 to make sure we're in the last pair of coils
    setAnalogChannel(curtime,20,0,1);
    %comment this out for raise QP position
    %setAnalogChannel(curtime,3,0,1);
    
    
    
    ramp_factor = 1.1;1.1; %1.1
    
        
    QP_ramp_time = 500+0*7500; %500+7500
    QP_curval = QP_value;
    QP_value = 30*ramp_factor*1.0; %new value of the QP %30
    Kitten_value = (2/11)*QP_value*0.67; %0.67  %6.2, 0.206*QP_value; (2/11)*QP_value*0.67
    %addOutputParam('Kitten_value',Kitten_value);

    %     %"cold" resistance is 0.68-0.69 Ohms, but as the coil heats up this
    %vSet_ramp = 0.755*QP_value/0.9+0.75 ;
    %rev 45 value
    %vSet_ramp = 22.0*ramp_factor; %22.0 %24.5 for QP = 35 @10s %21.5 hold %17.5 for ramping just top QP to 30, 19 for kitten to 6.2, 20 for kitten to 0
    %rev 48 value
    vSet_ramp = 22*ramp_factor*1.0*1.025;  %1.0
    
    if vSet_ramp^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
    
    lin_ramp = 0;
    
    if lin_ramp
        f = @(t,tt,dt,y0)(dt*t/tt+y0);
    else
        f = @(t,tt,dt,y0)(minimum_jerk(t,tt,dt)+y0);
    end
    
    %ramp up feed forward depending on gradient
     %setAnalogChannel(calctime(curtime,10),18,vSet); 
     
     %ramp up voltage supply depending on transfer
     AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(f(t,tt,dt,vSet)),QP_ramp_time,QP_ramp_time,vSet_ramp-vSet);

    %ramp coil 15
    %AnalogFunc(curtime,21,@(t,tt,dt)(minimum_jerk(t,tt,dt)+10.9),QP_ramp_time,QP_ramp_time,QP_value);

    %ramp coil 16
     AnalogFunc(calctime(curtime,20),1,@(t,tt,dt)(f(t,tt,dt,QP_curval)),QP_ramp_time,QP_ramp_time,QP_value-QP_curval);
    
     %ramp Feshbach
     if Feshval>0
        AnalogFunc(calctime(curtime,0),37,@(t,tt,dt)(f(t,tt,dt,0)),QP_ramp_time,QP_ramp_time,Feshval);
     end
     
    %ramp Kitten
     curtime = AnalogFunc(calctime(curtime,0),3,@(t,tt,dt)(f(t,tt,dt,Kitten_curval)),QP_ramp_time,QP_ramp_time,Kitten_value-Kitten_curval);
    
         
    %set kitten gate voltage to zero
    if Kitten_value==0
        
        setAnalogChannel(curtime,3,0,1);
        
        %physical disconnect kitten
        %make kitten relay an open switch
        setDigitalChannel(calctime(curtime,10),29,0);

        
    end

    %curtime = ramp_qp(curtime,[0 0 QP_curval],[0 0 QP_value],QP_ramp_time,10);
    
    curtime = calctime(curtime,100);
    
    %ramp kitten down
%     kitten_down_time = 20000;
%     AnalogFunc(calctime(curtime,-5),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet_ramp),kitten_down_time,kitten_down_time,2);
%     curtime = AnalogFunc(curtime,3,@(t,tt,dt)(minimum_jerk(t,tt,dt)+Kitten_value),kitten_down_time,kitten_down_time,-Kitten_value);
%     
    
    I_QP  = QP_value;
    I_kitt = Kitten_value;
    V_QP = vSet_ramp;
    I_fesh = Feshval;

else
    
    I_QP  = QP_value;
    I_kitt = Kitten_curval;
    V_QP = vSet;
    I_fesh = Feshval;
    
end


timeout = curtime;

end