%------
%Author: Dave
%Created: Aug 2012
%Summary: Transfer to a Single Beam Dipole Trap (for alignment)
%------
function [timeout I_QP V_QP P_dip ] = single_dipole_transfer(timein, I_QP, V_QP, dipole_ID)


curtime = timein;
global seqdata;


QP_value = I_QP;
vSet = V_QP;

  
%Dipole_ID is the beam to transfer to

if dipole_ID==1
    dipole_channel = 40;
elseif dipole_ID==2
    dipole_channel = 38;
else
    error('Invalid Dipole ID');
end

qp_ramp_down_start_time = 0;

dipole_on_time = 100;

do_qp_ramp_down = 1;

shim_QP_zero = 0;
tilt_evap = 0;

CDT_evap = 0;

 %try linear versus min jerk
ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%ramp_func = @(t,tt,y2,y1)(minimum_jerk(t,tt,y2-y1)+y1);

if qp_ramp_down_start_time<0
    error('QP ramp must happen after time zero');
end

   
%% Ramp Dipole

dipole_ramp_start_time = -1000;
dipole_ramp_up_time = 1000; %500

CDT_power = 10;
addOutputParam('dipole_power',CDT_power); 

dipole_power = CDT_power;

%ramp dipole trap on
AnalogFunc(calctime(curtime,dipole_ramp_start_time),dipole_channel,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole_power,0);


%% Ramp the QP Down
    
    QP_curval = QP_value;
    
    %value to ramp down to first
    QP_ramp_percent = 0.05; %0.315 %0
    qp_ramp_down_time1 = 1000;
        
            
    vSet_ramp = 1.07*vSet; %24
   
       
    if vSet_ramp^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
   
     %ramp up voltage supply depending on transfer
     %AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),dipole_transfer_time,dipole_transfer_time,vSet_ramp-vSet);
   
     
    
    %ramp down part of the way
    if do_qp_ramp_down
    
        zshim_start = (0.8-0.3)*0.8;
        yshim_start = 0*(0.5-0.52)*1.25;
        xshim_start = (1.6-0.3)*0.8;
        
        zshim_end = 0.1; %0.35 %0.1
        yshim_end = 0.4;  %0.4
        xshim_end = 0.76; %1.04 %0.85
        %put on rf knife ([5 4])
        %do_evap_stage(calctime(curtime,qp_ramp_down_start_time+200), 0, [5 4]*1E6, qp_ramp_down_time1, [-4], 0, 0)
    
        
        delta_z = zshim_start + (-zshim_start+zshim_end)*(1-QP_ramp_percent);
        delta_y = yshim_start + (-yshim_start+yshim_end)*(1-QP_ramp_percent);
        delta_x = xshim_start + (-xshim_start+xshim_end)*(1-QP_ramp_percent);
        
        %ramp shims
        %z 
        AnalogFunc(calctime(curtime,qp_ramp_down_start_time),28,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,delta_z,zshim_start); %0.8
%         %y
         AnalogFunc(calctime(curtime,qp_ramp_down_start_time),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,delta_y,yshim_start); %1.1875
%         %x
         AnalogFunc(calctime(curtime,qp_ramp_down_start_time),27,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,delta_x,xshim_start);%0.8


        %ramp down QP
        curtime = AnalogFunc(calctime(curtime,qp_ramp_down_start_time),1,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),qp_ramp_down_time1,qp_ramp_down_time1,QP_curval*QP_ramp_percent,QP_curval);

        %make sure timing is ok
        if (dipole_ramp_start_time+dipole_ramp_up_time)>(qp_ramp_down_start_time+qp_ramp_down_time1)
            curtime = calctime(curtime,(dipole_ramp_start_time+dipole_ramp_up_time)-(qp_ramp_down_start_time+qp_ramp_down_time1));
        end

         
        I_QP  = QP_curval*QP_ramp_percent;
        
        
        if QP_ramp_percent == 0
            
            setAnalogChannel(curtime,1,0,1);
            
        end
        
    else
        
        zshim_end = (0.8-0.3)*0.8;
        I_QP = QP_curval;
        
    end
    
   
    
    V_QP = vSet_ramp;
        
    
    %Turn off plug
       
    setAnalogChannel(calctime(curtime,0),33,0); %0
    setDigitalChannel(calctime(curtime,-2),10,0);
    
    %curtime = setAnalogChannel(curtime,1,QP_value);
      
     P_dip = dipole_power;
    
    curtime = calctime(curtime,dipole_on_time);

%% CDT evap

if CDT_evap
    
      %ramp on Q shim to quantize atoms
%     CDT_yshim = 0.75; 
%     curtime = AnalogFunc(calctime(curtime,0),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),100,100,CDT_yshim,0.4); %1.1875
%     
    CDT_pwrs = [CDT_power 5];
    CDT_times = [5000];
    
    for i = 1:length(CDT_times)
        CDT_start_pwr1 = CDT_pwrs(i);
        CDT_end_pwr1 = CDT_pwrs(i+1);
        CDT_evap_time1 = CDT_times(i);
        %ramp down dipole 
        AnalogFunc(calctime(curtime,0),dipole_channel,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),CDT_evap_time1,CDT_evap_time1,CDT_end_pwr1,CDT_start_pwr1);
        
    end


else
    
end
    
    
%% Tilt Evaporation
    
    if shim_QP_zero
        
        shim_QP_time = 150;
        shim_QP_start = zshim_end+0*(0.8-0.3)*0.8;
        shim_QP_end =  1.0;
       
        %z 
         curtime = AnalogFunc(curtime, 28, @(t,tt,y2,y1)(y1+(y2-y1)*t/tt), shim_QP_time, shim_QP_time, shim_QP_end, shim_QP_start);
    end
    
        
    if tilt_evap
        
        ramp_down_after_tilt = 0;
        
        %hold for 500ms to allow excess atoms to "boil off"
        curtime = calctime(curtime,500);
        
%          sci_probe_detuning_list=[100:1000:5100];
%         % 
%         % %Create linear list
%         %index=seqdata.cycle;
%         % 
%         % %Create Randomized list
%         index=seqdata.randcyclelist(seqdata.cycle);
%         % 
%         sci_probe_detuning = sci_probe_detuning_list(index)
%         addOutputParam('evap_time', sci_probe_detuning);    
        
        start_tilt_grad = I_QP;
        
        %wants to go slow at the beginning
        tilt_times = [8500 4500 0*2000];
        tilt_grads = [start_tilt_grad start_tilt_grad*3.5 start_tilt_grad*5.5 start_tilt_grad*7.0];
        
        tilt_times = [8000 4000];
        tilt_grads = [start_tilt_grad start_tilt_grad*3.5 start_tilt_grad*5.5];
        
        yshim_max = 0.5;
        xshim_max = 1.5;
        
        yshim0 = (0.5-0.52)*1.25;
        xshim0 = (1.6-0.3)*0.8;
        
        yshims = [yshim0 yshim_max yshim_max yshim_max];
        xshims = [xshim0 xshim_max xshim_max xshim_max];
        
%         start_tilt_grad = I_QP;
%         end_tilt_grad1 = start_tilt_grad*3.5;
%         end_tilt_grad2 = start_tilt_grad*5.5;
%         %end_tilt_grad3 = start_tilt_grad*6.5; %6.5
%                 
        cut_freq = 3;

        %put on rf knife (seems to help alot)
        do_evap_stage(calctime(curtime,-10), 0, [cut_freq cut_freq]*1E6, sum(tilt_times), [-2], 0, 1);
   
        end_tilt_index = 0;
        
        %tilt up the QP
        for i = 1:length(tilt_times)
            if tilt_times(i)>0
                
                %ramp shims
%                 %y
%                 AnalogFunc(calctime(curtime,0),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),tilt_times(i),tilt_times(i),yshims(i+1),yshims(i)); %1.1875
%                 %x
%                 AnalogFunc(calctime(curtime,0),27,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),tilt_times(i),tilt_times(i),xshims(i+1),xshims(i));%0.8
%                  
                %ramp grad
                curtime = AnalogFunc(curtime, 1, @(t,tt,y2,y1)(y1+(y2-y1)*t/tt), tilt_times(i), tilt_times(i), tilt_grads(i+1), tilt_grads(i));
            
                end_tilt_index = i;
            end
        end
        
        if ramp_down_after_tilt
            
            end_dipole_pwr = 0.2;
            
            %ramp down dipole and QP
            AnalogFunc(curtime, 40, @(t,tt,y2,y1)(y1+(y2-y1)*t/tt), 1000, 1000, end_dipole_pwr, dipole_power);
%             %y
%             AnalogFunc(calctime(curtime,0),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1000,1000,yshims(1),yshims(end_tilt_index+1)); %1.1875
%             %x
%             AnalogFunc(calctime(curtime,0),27,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1000,1000,xshims(1),xshims(end_tilt_index+1));%0.8
                            
            curtime = AnalogFunc(curtime, 1, @(t,tt,y2,y1)(y1+(y2-y1)*t/tt), 1000, 1000, start_tilt_grad*0.95, tilt_grads(end_tilt_index+1));
    %     
            P_dip = 0.4;

%             %ramp down dipole with QP balancing gravity
            curtime = AnalogFunc(curtime, 40, @(t,tt,y2,y1)(y1+(y2-y1)*t/tt), 5000, 5000, 0.15, end_dipole_pwr);
%             P_dip = 0.19;
        else
            I_QP = tilt_grads(end_tilt_index+1);
        end
% %         
    end
    
    
    
   
    
%else
    
%     I_QP  = QP_value;
%     I_kitt = Kitten_curval;
%     V_QP = vSet;

%end


timeout = curtime;

end