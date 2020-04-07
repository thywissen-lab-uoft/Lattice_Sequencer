%------
%Author: DM
%Created: Sep 2009
%Summary: This function takes an image with the recapture MOT
%------

function timeout=recap_image(timein)

curtime = timein;
global seqdata;

recap_atomtype = 2; %0 = Rb, 1 = K, 2=Rb+K

in_situ_recap = 1;

in_lattice = 0;

get_rid_of_Rb = 0;

ramp_off_FB = 0;



if recap_atomtype == 0
   k_recap_scale = 0;
   rb_recap_scale = 1;
elseif recap_atomtype == 1
   k_recap_scale = 1;
   rb_recap_scale = 0; 
elseif recap_atomtype == 2
   k_recap_scale = 1;
   rb_recap_scale = 1; 
end



if seqdata.flags.image_loc == 0 %MOT cell
    
    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
      
    k_recap_detuning = k_recap_scale*6; %7.2 for MOT
    k_recap_trap_power = 0.7;
    k_recap_repump_power = 0.8;
    k_recap_load_time = 40;
        
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
        
    rb_recap_detuning = rb_recap_scale*10; %7.2 for MOT
    rb_recap_trap_power = 0.7;
    rb_recap_repump_power = 0.8;
    rb_recap_load_time = 30;
    
    end

elseif seqdata.flags.image_loc == 1 %Science cell

    scale = 1;
    
    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    k_recap_detuning = k_recap_scale*(10); %7.2 for MOT
    k_recap_trap_power = 0.7*scale;
    k_recap_repump_power = 0.8*scale;
    k_recap_load_time = 100;
    
    k_D1_detuning = 200;
    k_D1_power = 6;
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
    rb_recap_detuning = rb_recap_scale*(55);  %20
    rb_recap_trap_power = 0.7*scale;
    rb_recap_repump_power = 0.8*scale;
    rb_recap_load_time = 30.0;
    end


else 
    error('invalid recapture location')
end

recap_exp_time = 10;




%% when does molasses turn on?
%"Load MOT" already has a 10ms TOF
tof = -8; %-8

beam_ontime = 5;

if in_situ_recap
curtime = calctime(curtime,beam_ontime);
else
curtime = calctime(curtime,5);
end

%% Get rid of Rb

 
    if get_rid_of_Rb

        %blow away any atoms left in F=2
        %open shutter
        setDigitalChannel(calctime(curtime,-200),25,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,-200),26,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,-200),24,1);
        %set detuning
        setAnalogChannel(calctime(curtime,-200),34,6590-237);

        %pulse beam with TTL 
        DigitalPulse(calctime(curtime,-190),24,15,0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,-150),25,0); %0=closed, 1=open

    end

%% Ramp off FB

if ramp_off_FB
   
    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
    
    ramptime = 200;
    
    AnalogFunc(calctime(curtime,-ramptime-50),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramptime,ramptime,-1,21.2);
    SetDigitalChannel(calctime(curtime,-50),'fast FB Switch',0); %fast switch
end

%% Wait and turn the MOT back on 
%digital trigger
DigitalPulse(curtime,12,0.1,1);

    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %curtime = Load_MOT(calctime(curtime,tof),[rb_recap_detuning k_recap_detuning],seqdata.flags.image_loc);   
    
        %trap detuning
            %K D2
            setAnalogChannel(calctime(curtime,0),5,k_recap_detuning);
            %K D1
            setAnalogChannel(calctime(curtime,0),48,k_D1_detuning);
            %Rb
            setAnalogChannel(calctime(curtime,0),34,6590+rb_recap_detuning);
        %trap power
            %K D2
            setAnalogChannel(calctime(curtime,0),26,k_recap_scale*k_recap_trap_power);
            %K D1
            setAnalogChannel(calctime(curtime,0),47,k_D1_power);
            %Rb
            setAnalogChannel(calctime(curtime,0),4,rb_recap_scale*rb_recap_trap_power);
        %trap TTL and shutter
            %K D2
            setDigitalChannel(calctime(curtime,0),6,0);
            setDigitalChannel(calctime(curtime,0),2,1);
            %K D1
            setDigitalChannel(calctime(curtime,0),36,1);
            setDigitalChannel(calctime(curtime,0),35,1);
            %Rb
            setDigitalChannel(calctime(curtime,0),8,0);
            setDigitalChannel(calctime(curtime,0),4,1);
        %repump power
            %K
            setAnalogChannel(curtime,25,k_recap_scale*k_recap_repump_power);
            %Rb    
            setAnalogChannel(curtime,2,rb_recap_scale*rb_recap_repump_power);
        %repump TTL and shutter
            %K
            setDigitalChannel(calctime(curtime,0),7,0);
            setDigitalChannel(calctime(curtime,0),3,1);
            %Rb
            setDigitalChannel(calctime(curtime,0),5,1);
        
            %MOT coils
%         setAnalogChannel(calctime(curtime,-5),18,10);
%         curtime = setAnalogChannel(calctime(curtime,0),8,10);
        
        if ~in_situ_recap
        %QP coils
            QP_recap_time = 0;
            %kitten and coil 15 must be off
            setAnalogChannel(calctime(curtime,QP_recap_time),3,0,1);
            setAnalogChannel(calctime(curtime,QP_recap_time),21,0,1);
            %turn on 15/16 switch 
            setDigitalChannel(calctime(curtime,QP_recap_time),22,1);
            %coil 16
            setAnalogChannel(calctime(curtime,QP_recap_time),1,1.5);
            %fast switch
            setDigitalChannel(calctime(curtime,QP_recap_time),21,0);
        else
        end
%     
    end
    
    %curtime = calctime(curtime,10);
    
    %Rb
%     if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     curtime = Load_MOT(calctime(curtime,tof),[rb_recap_detuning k_recap_detuning],seqdata.flags.image_loc);
%     %control recap_trap_power
%     curtime = setAnalogChannel(curtime,26,rb_recap_scale*rb_recap_trap_power);
%     %control recap_repump_power
%     curtime = setAnalogChannel(curtime,25,rb_recap_scale*rb_recap_repump_power);
%     end


%% Cam trigger after "recap_load_time" load

    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    DigitalPulse(calctime(curtime,35),26,recap_exp_time,1);
    end
    
    %Rb
%     if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     curtime = DigitalPulse(calctime(curtime,-recap_exp_time),26,recap_exp_time,1);
%     end
    
    
    
    curtime = calctime(curtime,k_recap_load_time);

%% turn MOT off

    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %trap
    turn_off_beam(curtime,1,1);
    setAnalogChannel(calctime(curtime,0),26,0,1);
    setDigitalChannel(calctime(curtime,0),6,1);
    setDigitalChannel(calctime(curtime,0),2,0);
    %D1
    setAnalogChannel(calctime(curtime,0),47,0);
    setDigitalChannel(calctime(curtime,0),36,0);
    setDigitalChannel(calctime(curtime,0),35,0);
    %turn the repump off
    turn_off_beam(curtime,2,1);
    setAnalogChannel(calctime(curtime,0),25,0,1);
    setDigitalChannel(calctime(curtime,0),7,1);
    setDigitalChannel(calctime(curtime,0),3,0);
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     %trap
%     turn_off_beam(curtime,1,1);
%     %turn the repump off
%     turn_off_beam(curtime,2,1);
    setAnalogChannel(calctime(curtime,0),4,0,1);
    setDigitalChannel(calctime(curtime,0),8,1);
    setDigitalChannel(calctime(curtime,0),4,0);
    
    setAnalogChannel(calctime(curtime,0),2,0,1);
    setDigitalChannel(calctime(curtime,0),5,0);
    end


%turn off MOT current
setAnalogChannel(curtime,8,0);

if ~in_situ_recap
% %turn off coil 16
            %coil 16
            setAnalogChannel(calctime(curtime,0),1,0,1);
            %fast switch
            %setDigitalChannel(curtime,21,1);
             %turn off 15/16 switch 
            setDigitalChannel(calctime(curtime,0),22,0);

else
end
%% Load_MOT (1s later)

if in_lattice
curtime = Load_Lattice(calctime(curtime,1500),0.01);
else
 curtime = calctime(curtime,1500);   
end
    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %curtime = Load_MOT(calctime(curtime,1000),[rb_recap_detuning k_recap_detuning],seqdata.flags.image_loc);
    
    %trap detuning
        %curtime = setAnalogChannel(calctime(curtime,1000),5,k_recap_detuning);
        curtime = setAnalogChannel(calctime(curtime,beam_ontime),5,k_recap_detuning);
        setAnalogChannel(calctime(curtime,0),34,6590+rb_recap_detuning);
        %trap power
        setAnalogChannel(calctime(curtime,0),26,k_recap_scale*k_recap_trap_power);
        setAnalogChannel(calctime(curtime,0),47,k_D1_power);
        setAnalogChannel(calctime(curtime,0),4,rb_recap_scale*rb_recap_trap_power);
        %trap TTL and shutter
        setDigitalChannel(calctime(curtime,0),6,0);
        setDigitalChannel(calctime(curtime,0),2,1);
        setDigitalChannel(calctime(curtime,0),36,1);
        setDigitalChannel(calctime(curtime,0),35,1);
        setDigitalChannel(calctime(curtime,0),8,0);
        setDigitalChannel(calctime(curtime,0),4,1);
        %repump power
        setAnalogChannel(curtime,25,k_recap_scale*k_recap_repump_power);
        setAnalogChannel(curtime,2,rb_recap_scale*rb_recap_repump_power);
        %repump TTL and shutter
        setDigitalChannel(calctime(curtime,0),7,0);
        setDigitalChannel(calctime(curtime,0),3,1);
        
        setDigitalChannel(calctime(curtime,0),5,1);
        %MOT coils
%         setAnalogChannel(calctime(curtime,0),18,10);
%         curtime = setAnalogChannel(calctime(curtime,0),8,10);
        
        if ~in_situ_recap
        %QP coils
            %kitten and coil 15 must be off
            setAnalogChannel(curtime,3,0,1);
            setAnalogChannel(curtime,21,0,1);
            %turn on 15/16 switch 
            setDigitalChannel(calctime(curtime,QP_recap_time),22,1);
            %coil 16
            setAnalogChannel(calctime(curtime,0),1,2);
            %fast switch
            setDigitalChannel(curtime,21,0);
        else
        end
    
    end
    %Rb
%     if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     curtime = Load_MOT(calctime(curtime,1000),[rb_recap_detuning k_recap_detuning],seqdata.flags.image_loc);
%     end


%% cam trigger after "recap_load_time" load

   %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    DigitalPulse(calctime(curtime,0),26,recap_exp_time,1);
    end
    
    %Rb
%     if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     curtime = DigitalPulse(calctime(curtime,rb_recap_load_time),26,recap_exp_time,1);
%     end

%K
%     if (seqdata.atomtype==1 || seqdata.atomtype==4)
%     %trap
%     turn_off_beam(curtime,1,1);
%     setAnalogChannel(calctime(curtime,0),26,0,1);
%     setDigitalChannel(calctime(curtime,0),6,1);
%     setDigitalChannel(calctime(curtime,0),2,0);
%     %turn the repump off
%     turn_off_beam(curtime,2,1);
%     setAnalogChannel(calctime(curtime,0),25,0,1);
%     setDigitalChannel(calctime(curtime,0),7,1);
%     setDigitalChannel(calctime(curtime,0),3,0);
%     end

curtime = calctime(curtime,k_recap_load_time);

%% turn MOT off

    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %trap
    turn_off_beam(curtime,1,1);
    setAnalogChannel(calctime(curtime,0),26,0,1);
    setDigitalChannel(calctime(curtime,0),6,1);
    setDigitalChannel(calctime(curtime,0),2,0);
    %D1
    setAnalogChannel(calctime(curtime,0),47,0);
    setDigitalChannel(calctime(curtime,0),36,0);
    setDigitalChannel(calctime(curtime,0),35,0);
    %turn the repump off
    turn_off_beam(curtime,2,1);
    setAnalogChannel(calctime(curtime,0),25,0,1);
    setDigitalChannel(calctime(curtime,0),7,1);
    setDigitalChannel(calctime(curtime,0),3,0);
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
%     %trap
%     turn_off_beam(curtime,1,1);
%     %turn the repump off
%     turn_off_beam(curtime,2,1);
    setAnalogChannel(calctime(curtime,0),4,0,1);
    setDigitalChannel(calctime(curtime,0),8,1);
    setDigitalChannel(calctime(curtime,0),4,0);
    
    setAnalogChannel(calctime(curtime,0),2,0,1);
    setDigitalChannel(calctime(curtime,0),5,0);
    end
    
    

if ~in_situ_recap
% %turn off coil 16
            %coil 16
            setAnalogChannel(calctime(curtime,0),1,0,1);
            %fast switch
            setDigitalChannel(curtime,21,1);
            %turn on 15/16 switch 
            setDigitalChannel(calctime(curtime,0),22,0);
else
end

%%  add time so that load lattice shuts off lattice

    curtime = calctime(curtime,500);

timeout=curtime;

end
