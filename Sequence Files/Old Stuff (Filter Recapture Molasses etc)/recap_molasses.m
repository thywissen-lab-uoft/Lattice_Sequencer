%------
%Author: DJ
%Created: Sep 2013
%Summary: 
%------

function timeout=recap_molasses(timein)

curtime = timein;
global seqdata;

recap_atomtype = 2; %0 = Rb, 1 = K, 2=Rb+K



in_lattice = 1;

get_rid_of_Rb = 0;

ramp_off_FB = 1;

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
    k_recap_load_time = 50;
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
    rb_recap_detuning = rb_recap_scale*(25);  %20
    rb_recap_trap_power = 0.7;
    rb_recap_repump_power = 0.8;
    rb_recap_load_time = 30.0;
    end


else 
    error('invalid recapture location')
end

recap_exp_time = 10;




%% when does molasses turn on?
%"Load MOT" already has a 10ms TOF
tof = -8; %-8

beam_ontime = -50;

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
            %K
            setAnalogChannel(calctime(curtime,0),5,k_recap_detuning);
            %Rb
            setAnalogChannel(calctime(curtime,0),34,6590+rb_recap_detuning);
        %trap power
            %K
            setAnalogChannel(calctime(curtime,0),26,k_recap_scale*k_recap_trap_power);
            %Rb
            setAnalogChannel(calctime(curtime,0),4,rb_recap_scale*rb_recap_trap_power);
        %trap TTL and shutter
            %K
            setDigitalChannel(calctime(curtime,0),6,0);
            setDigitalChannel(calctime(curtime,0),2,1);
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
          = setAnalogChannel(calctime(curtime,0),8,10);
        
       
%     
    end
    
   

%% Wait
    
    
    curtime = calctime(curtime,k_recap_load_time);

%% turn molasses off

    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    %trap
    turn_off_beam(curtime,1,1);
    setAnalogChannel(calctime(curtime,0),26,0,1);
    setDigitalChannel(calctime(curtime,0),6,1);
    setDigitalChannel(calctime(curtime,0),2,0);
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



timeout=curtime;

end
