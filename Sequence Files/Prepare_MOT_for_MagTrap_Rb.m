%------
%Author: David + Dylan
%Created: March 2011
%Summary: Prepares the cloud for loading into the magnetic trap
%------
function timeout = Prepare_MOT_for_MagTrap(timein)

global seqdata;

curtime = timein;

%% Take Flouresence image of MOT
%cam trigger
%DigitalPulse(curtime,1,1,1);

%% MOT Feed Forward 
%Increase the voltage on the supplies
setAnalogChannel(calctime(curtime,10),18,10); 

curtime = calctime(curtime,1500);

%% Bright MOT (Take out dark spot)
   
%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

%% Compression

do_compression = 1;

if do_compression
    
    yshim_comp = 0.2;
    xshim_comp = 0.05; %0.05
    zshim_comp = 0.05;

    %optimize shims for compression (put cloud at the position of the mag
    %trap center)
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,-2),19,yshim_comp); %1.25
    %turn on the X (left/right) shim
    setAnalogChannel(calctime(curtime,-2),27,xshim_comp); %0.3 
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,-2),28,zshim_comp); %0.2
        
    time_between_darkSPOT_and_cMOT = 0; %25

    cMOT_time = 15; %10

    %jump detuning further from resonance (~50MHz as suggested by Eric
    %Cornell Easy BEC paper)
    curtime = setAnalogChannel(calctime(curtime,time_between_darkSPOT_and_cMOT),34,6600);
    
     %Let there be 10ms of compression (5ms without bias + 5ms with bias)
    curtime=calctime(curtime,cMOT_time);
     
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
    
    %jump detuning further from resonance
    %setAnalogChannel(calctime(curtime,-5),34,6585);
    
    %turn on the shims for optical pumping and/or molasses

    yshim_mol = 0.10;
    xshim_mol = 0.1;
    zshim_mol = 0.05;
    
    %turn on the Y (quantizing) shim 
    setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %1.05 for molassess
    %turn on the X (left/right) shim 
    setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.25 for molasses
    %turn on the Z (top/bottom) shim 
    setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.15 for molasses  

    %change detuning
    setAnalogChannel(curtime,5,29.5);

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
    curtime = calctime(curtime,10); %10
    
  
        
    
end


%turn the trap light off
turn_off_beam(curtime,1,1);


%% OPTICAL PUMPING

if (0)
    curtime = calctime(curtime,1.0);
    curtime = optical_pumping(curtime);
else
    %optical pumping seemed to make little difference (why?)
    curtime = calctime(curtime,2.0);
end

%turn off the repump
turn_off_beam(curtime,2);

timeout = curtime;

end