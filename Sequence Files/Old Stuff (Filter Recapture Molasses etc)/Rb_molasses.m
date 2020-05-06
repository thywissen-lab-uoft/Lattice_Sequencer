%------
%Author: DM
%Created: Sep 2009
%Summary: This function takes an image with the recapture MOT
%------

function timeout=Rb_molasses(timein)

curtime = timein;
global seqdata;

recap_atomtype = 0; %0 = Rb, 1 = K, 2=Rb+K



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




% parameters

    molasses_on_time = 30;
    
    %K
    if (seqdata.atomtype==1 || seqdata.atomtype==4)
    k_recap_detuning = k_recap_scale*6; %7.2 for MOT
    k_recap_trap_power = 0.7;
    k_recap_repump_power = 0.8;
   
    end
    
    %Rb
    if (seqdata.atomtype==3 || seqdata.atomtype==4)
    rb_recap_detuning = rb_recap_scale*5;  
    rb_recap_trap_power = 0.7;
    rb_recap_repump_power = 0.8;
    
    end

%% when to turn molasses on

turn_on_time = -50;

%curtime = calctime(curtime,-50);

%% turn molasses light on

%digital trigger
DigitalPulse(curtime,12,0.1,1);

   
        %trap detuning
        setAnalogChannel(calctime(curtime,turn_on_time),5,k_recap_detuning);
        setAnalogChannel(calctime(curtime,turn_on_time),34,6590+rb_recap_detuning);
        %trap power
        setAnalogChannel(calctime(curtime,turn_on_time),26,k_recap_scale*k_recap_trap_power);
        setAnalogChannel(calctime(curtime,turn_on_time),4,rb_recap_scale*rb_recap_trap_power);
        %trap TTL and shutter
        setDigitalChannel(calctime(curtime,turn_on_time),6,0);
        setDigitalChannel(calctime(curtime,turn_on_time),2,1);
        setDigitalChannel(calctime(curtime,turn_on_time),8,0);
        setDigitalChannel(calctime(curtime,turn_on_time),4,1);
        %repump power
        setAnalogChannel(calctime(curtime,turn_on_time),25,k_recap_scale*k_recap_repump_power);
        setAnalogChannel(calctime(curtime,turn_on_time),2,rb_recap_scale*rb_recap_repump_power);
        %repump TTL and shutter
        setDigitalChannel(calctime(curtime,turn_on_time),7,0);
        setDigitalChannel(calctime(curtime,turn_on_time),3,1);
        
        setDigitalChannel(calctime(curtime,turn_on_time),5,1);
       




    
   % curtime = calctime(curtime,molasses_on_time);

%% turn  molasses light off

%     %K
%     if (seqdata.atomtype==1 || seqdata.atomtype==4)
%     %trap
%     turn_off_beam(curtime,1,1);
%     setAnalogChannel(calctime(curtime,turn_on_time+molasses_on_time),26,0,1);
%     setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),6,1);
%     setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),2,0);
%     %turn the repump off
%     turn_off_beam(calctime(curtime,turn_on_time+molasses_on_time),2,1);
%     setAnalogChannel(calctime(curtime,turn_on_time+molasses_on_time),25,0,1);
%     setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),7,1);
%     setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),3,0);
%     end
%     
    %Rb
   
%     %trap
%     turn_off_beam(curtime,1,1);
%     %turn the repump off
%     turn_off_beam(curtime,2,1);
    setAnalogChannel(calctime(curtime,turn_on_time+molasses_on_time),4,0,1);
    setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),8,1);
    setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),4,0);
    
    setAnalogChannel(calctime(curtime,turn_on_time+molasses_on_time),2,0,1);
    setDigitalChannel(calctime(curtime,turn_on_time+molasses_on_time),5,0);
    




timeout=curtime;

end
