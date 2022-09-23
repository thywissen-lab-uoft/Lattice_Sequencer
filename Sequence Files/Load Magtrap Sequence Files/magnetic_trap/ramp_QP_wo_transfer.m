%------
%Author: Vijin
%Created: Dec 2020
%Summary: Ramp the QP to a different gradient without changing the trap
%center
%------


function [timeout I_QP I_kitt V_QP I_fesh] = ramp_QP_wo_transfer(timein, ramp_down_QP_before_transfer, I_QP, I_kitt, V_QP, I_fesh)


curtime = timein;
global seqdata;

if ramp_down_QP_before_transfer


QP_value = I_QP;
Kitten_curval = I_kitt;
vSet = V_QP;

disp(['     I_QP ' num2str(I_QP)]);
disp(['     I_kitt ' num2str(I_kitt)]);


%Feshval = 0;
Feshval = I_fesh ;
    
%Final Gradient ramp factor
    ramp_factor_list = [0.1:0.01:0.2 0.22:0.02:0.3];
    ramp_factor = getScanParameter(ramp_factor_list,seqdata.scancycle,seqdata.randcyclelist,'ramp_factor');
    
    QP_ramp_time = 500;500; %500
    QP_curval = QP_value;
    Zshim_curval = seqdata.params.plug_shims(3); % The current, current value  
%     Zshim_value = (Zshim_curval-seqdata.params.shim_zero(3))*ramp_factor+seqdata.params.shim_zero(3);
    
    Zshim_value = Zshim_curval*ramp_factor;

    Yshim_curval = seqdata.params.plug_shims(2);
    Yshim_value = Yshim_curval*ramp_factor;
    Xshim_curval = seqdata.params.plug_shims(1);
    Xshim_value = Xshim_curval*ramp_factor;
    disp('QP_curval!!!!')
    disp(QP_curval)
    QP_value = QP_curval*ramp_factor; 
    Kitten_value = ramp_factor*5.04-0.495;Kitten_curval*ramp_factor;  
    
    disp(['     I_QP_2 ' num2str(QP_value)]);
    disp(['     I_kitt_2 ' num2str(Kitten_value)]);

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
     
     kitten_time = 20;
    %ramp shims
    AnalogFunc(calctime(curtime,20),'Y Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Yshim_curval),QP_ramp_time,QP_ramp_time,Yshim_value-Yshim_curval,4); 
    AnalogFunc(calctime(curtime,20),'X Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Xshim_curval),QP_ramp_time,QP_ramp_time,Xshim_value-Xshim_curval,3); 
    AnalogFunc(calctime(curtime,20),'Z Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Zshim_curval),QP_ramp_time,QP_ramp_time,Zshim_value-Zshim_curval,3); 
    
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