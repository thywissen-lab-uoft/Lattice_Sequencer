%------
%Author: Dave
%Created: Aug 2012
%Summary: Weaken QP Trap for final stage of evaporation
%------
function [timeout I_QP V_QP] = weak_QP_trap(timein, I_QP, V_QP, weak_QP)


curtime = timein;
global seqdata;

if ~weak_QP
    timeout = timein;
    return;
end


QP_value = I_QP;
vSet = V_QP;

qp_ramp_down_start_time = 0;
do_qp_ramp_down = 1;

ramp_shims = 1;


 %try linear versus min jerk
ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%ramp_func = @(t,tt,y2,y1)(minimum_jerk(t,tt,y2-y1)+y1);

if qp_ramp_down_start_time<0
    error('QP ramp must happen after time zero');
end



%% Ramp the QP Down
    
    QP_curval = QP_value;
    
    %value to ramp down to first
    QP_ramp_percent = 0.81; %0.25
    qp_ramp_down_time1 = 300;
        
        
       
    if V_QP^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
   
     %ramp up voltage supply depending on transfer
     %AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),dipole_transfer_time,dipole_transfer_time,vSet_ramp-vSet);
   
     
    
    %ramp down part of the way
    if do_qp_ramp_down
    
        zshim_start = (0.8-0.3)*0.8;
        yshim_start = (0.5-0.514)*1.25;
        xshim_start = (1.6-0.3)*0.8;
        
        %DCM Aug 21 --- Shims have been optimized for a 0.25 ramp down
        
        % % %list
        shim_list = (-5:1:5)/500;
        % 
        % %Create linear list
        %index=seqdata.cycle;
        % 
        % %Create Randomized list
        index=seqdata.randcyclelist(seqdata.cycle);
        % tof = tof_list(index);
        
        %increasing this pushes the QP zero "up" (wrt gravity)
        zshim_end = 0.335; %0.13 %0.15
        addOutputParam('zshim',zshim_end); 
                        
        yshim_end = yshim_start;  %0.25 0.4 0.6
                
        %moves cloud orthogonal to gravity (higher number, plug is higher)
        %higher number moves the QP zero "down" (wrt the MATLAB view)
        xshim_end = 1.034; %0.76 0.65
        addOutputParam('xshim',xshim_end); 
        
        %put on rf knife ([5 4])
        %do_evap_stage(calctime(curtime,qp_ramp_down_start_time+200), 0, [5 4]*1E6, qp_ramp_down_time1, [-4], 0, 0)
        
        
        if ramp_shims
            %ramp shims
            %z 
            AnalogFunc(calctime(curtime,qp_ramp_down_start_time),28,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,zshim_end,zshim_start); %0.8
            %y
             AnalogFunc(calctime(curtime,qp_ramp_down_start_time),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,yshim_end,yshim_start); %1.1875
            %x
             AnalogFunc(calctime(curtime,qp_ramp_down_start_time),27,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,xshim_end,xshim_start);%0.8
        end

        %Ramp down current
        
        V_QP = vSet*QP_ramp_percent;
        
        %ramp down voltage supply depending on transfer
        curtime = AnalogFunc(calctime(curtime,qp_ramp_down_start_time),18,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,V_QP,vSet);
           
        %ramp down QP
        curtime = AnalogFunc(calctime(curtime,qp_ramp_down_start_time),1,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,QP_curval*QP_ramp_percent,QP_curval);

         
        I_QP  = QP_curval;
        
        
        if QP_ramp_percent == 0
            
            setAnalogChannel(curtime,1,0,1);
            
        end
        
    else
        
        zshim_end = (0.8-0.3)*0.8;
        I_QP = QP_curval;
        
    end
    
    %curtime = calctime(curtime,50);
   
    
             


timeout = curtime;

end