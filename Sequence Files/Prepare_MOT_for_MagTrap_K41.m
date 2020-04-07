%------
%Author: David + Dylan
%Created: March 2011
%Summary: Prepares the cloud for loading into the magnetic trap
%------

%----Input Vars
%blue_mot: flag to turn on blue mot
%----------

function timeout = Prepare_MOT_for_MagTrap_K41(timein, blue_mot)

global seqdata;

curtime = timein;

%% Take Flouresence image of MOT
%cam trigger
%DigitalPulse(curtime,1,1,1);

%% MOT Feed Forward 
%Increase the voltage on the supplies
%setAnalogChannel(calctime(curtime,10),18,10/6.6); 

curtime = calctime(curtime,1500);

%% Bright MOT (Take out dark spot)
   
%curtime = DigitalPulse(calctime(curtime,0),15,10,1);


%% Compression

do_compression = 1;

if do_compression

    if (1)
    
        yshim_comp = 0.2;
        xshim_comp = 0.05; %0.05
        zshim_comp = 0.55;

        %optimize shims for compression (put cloud at the position of the mag
        %trap center)
        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-2),19,yshim_comp); %1.25
        %turn on the X (left/right) shim
        setAnalogChannel(calctime(curtime,-2),27,xshim_comp); %0.3 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-2),28,zshim_comp); %0.2

        time_between_darkSPOT_and_cMOT = 0; %25

        cMOT_time = 100; %50

        detune1=-10; %0 %16
        detune2=5; %15 %30

        repumppwr1=0.25; %6
        repumppwr2=0.25;

        grad1 = 10;
        grad2 = 45;

        %note: only ramp three at a time or else it throws off the ADWIN timing

        %Jump Trap detuning closer to resonance to 7.2MHz
        curtime = setAnalogChannel(calctime(curtime,time_between_darkSPOT_and_cMOT),5,detune1);%7.2MHz %this was at 3.2MHz!! %18

        AnalogFunc(curtime,5,@(t,detune1,detune2,tt)(detune1+(detune2-detune1)*t/tt),cMOT_time,detune1,detune2,cMOT_time);

        %turn repump down
        setAnalogChannel(curtime,25,0.7); %repump 0.075
        setAnalogChannel(calctime(curtime,cMOT_time/2),25,0.3);
        %AnalogFunc(curtime,25,@(t,pwr1,pwr2,tt)(pwr1+(pwr2-pwr1)*t/tt),cMOT_time,repumppwr1,repumppwr2,cMOT_time);

        %turn trap down
        setAnalogChannel(curtime,26,0.1);
        setAnalogChannel(calctime(curtime,cMOT_time/2),26,0.3);

        %Ramp gradient (as suggested by Inouye paper...really seems to help)
        %AnalogFunc(calctime(curtime,0.0),8,@(t,grad1,grad2,tt)(grad1+(grad2-grad1)*t/tt),cMOT_time,grad1,grad2,cMOT_time);
        setAnalogChannel(curtime,8,grad2);

        %Let there be 10ms of compression (5ms without bias + 5ms with bias)
        curtime=calctime(curtime,cMOT_time);
        
    else
    
        %Try "normal" CMOT stage
        
        time_between_darkSPOT_and_cMOT = 0; %25

        cMOT_time = 100; %10

        %Jump Trap detuning closer to resonance to 7.2MHz
        curtime = setAnalogChannel(calctime(curtime,time_between_darkSPOT_and_cMOT),5,30);%7.2MHz %this was at 3.2MHz!! %18

        %turn repump down
        setAnalogChannel(curtime,25,0.3); %repump 0.075
        
        %turn trap down
        setAnalogChannel(curtime,26,0.3);
        
        %Let there be 10ms of compression (5ms without bias + 5ms with bias)
        curtime=calctime(curtime,cMOT_time);
        
    end
end

%% Turn off the MOT

%turn the MOT off
%CATS
setAnalogChannel(curtime,8,0);
%TTL
setDigitalChannel(curtime,16,0); %1 is fast turn-off, 0 is not


%% Molasses 

do_molasses = 1;

if do_molasses
    
    %turn on the shims for optical pumping and/or molasses

    yshim_mol = 0.2;
    xshim_mol = 0.15;
    zshim_mol = 0.15;
    
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %0.2 for molassess
    %turn on the X (left/right) shim 
    setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.05 for molasses
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.08 for molasses  

    %change detuning
    setAnalogChannel(curtime,5,17.25); %29.5

    %turn trap down
    setAnalogChannel(curtime,26,0.45);
    

    %list
%  repump_power_list=[0.25:0.05:0.5 0.25:0.05:0.5 0.25:0.05:0.5];
% % 
% % %Create linear list
% %index=seqdata.cycle;
% % 
% % %Create Randomized list
%  index=seqdata.randcyclelist(seqdata.cycle);
% % 
%  repump_power = repump_power_list(index)
%  addOutputParam('resonance',repump_power);
    
    
    %turn repump down
    setAnalogChannel(curtime,25,0.28); %0.3
     
       
    %do molasses for 5ms
    curtime = calctime(curtime,5); %5
    
    
end

%turn the trap light off
turn_off_beam(curtime,1,1);

%lag for trap shutter (1.7ms)
curtime = calctime(curtime,1.7);

if blue_mot
    
    blue_mot_time = 50;
    blue_molasses_time = 0;
    
    %turn blue mot on (overlap a little with red MOT)
    setDigitalChannel(calctime(curtime,-3),23,1);
    setAnalogChannel(curtime,8,10);
    
    %turn blue mot off    
    curtime = setAnalogChannel(calctime(curtime,blue_mot_time),8,0);
    curtime = setDigitalChannel(calctime(curtime,blue_molasses_time),23,0);
    
    
    %lag for the trap shutter (3.2ms)
    curtime = calctime(curtime,3.2);
    
end    

%to offset optical pumping time
%curtime = calctime(curtime,-2.0);

%% OPTICAL PUMPING

if (0)
    curtime = optical_pumping(curtime);
else
    %optical pumping seemed to make little difference (why?)
    %curtime = calctime(curtime,2.0);
end

%turn off the repump
turn_off_beam(curtime,2,1);

timeout = curtime;

end