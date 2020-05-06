%------
%Author: Graham
%Created: June 2012
%Summary: This turns on the MOT (test)
%------
function timeout = Load_MOT_test(timein,detuning,loc)

curtime = timein;
global seqdata;

%loc: 0 MOT cell, 1 sci cell

if nargin<3
   loc = 0;
end

load_MOT_tof = 10;
do_molasses = 0;
atomtype = 1; %1 - K40, 2 - 87Rb

%use kitten or not
use_kitten_Load_MOT = 2; %0: no kitten, 1: kitten, 2: coil 15 h-bridge

%trigger dark spot
%DigitalPulse(calctime(curtime,0),15,10,1)




%% Molasses (for testing power balance)

%To fix: the quadrupole field is not turning off *completely* here

molasses_time = 1000; %20
molasses_detuning = 50; %50

if do_molasses
    
    %turn on the shims for optical pumping and/or molasses

    %set shims and detuning (atom dependent)
    if atomtype==1 %K40
             
        
%         yshim_mol = 0; %0.5
%         xshim_mol = 0.4; %0.1
%         zshim_mol = 0.05; %0.2
% 
%         %turn on the Y (quantizing) shim 
%         setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %1.05 for molassess
%         %turn on the X (left/right) shim 
%         setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.25 for molasses
%         %turn on the Z (top/bottom) shim 
%         setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.15 for molasses  
    
                 
%         %turn down Trap power for molasses
%         setAnalogChannel(calctime(curtime,0),26,0.7);
%         
%         %set Repump power (turn down for molasses)
%        setAnalogChannel(calctime(curtime,0),25,0.24);
%        setAnalogChannel(calctime(curtime,5),25,0.7);
        
%         %set molasses detuning
%         setAnalogChannel(calctime(curtime,0),34,756); %756
%         %offset FF
%          setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06

        BGrad = 0; %10

        %Feed Forward
        setAnalogChannel(calctime(curtime,0),18,0);
        %CATS
        setAnalogChannel(calctime(curtime,0),8,BGrad); %13G/cm
        %Science Cell QP (1.5A for 15G/cm)
        
        %turn on the Y (quantizing) shim
        curtime = setAnalogChannel(calctime(curtime,0),19,0.9,1); %0.9 feb 4 (0.9 June 6)
        %turn on the X (left/right) shim
        curtime = setAnalogChannel(calctime(curtime,0),27,0.4,1);  %0.0 feb 4 (0.0 June 6)
        %turn on the Z (top/bottom) shim
        curtime = setAnalogChannel(calctime(curtime,0),28,0.4,1);  %0.45 feb 4 (0.42 June 6)
        
        
           
    elseif atomtype==2 %Rb
        
        %optimized by imaging a long molasses
        %optimized by evap April 18, 2012 (both methods were basically the
        %same)
        yshim_mol = 0.1; %0.3
        xshim_mol = 0.1; %0.1
        zshim_mol = 0.05; %0.05

        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %1.05 for molassess
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.25 for molasses
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.15 for molasses  
        
       
       %set OP detuning 
        setAnalogChannel(calctime(curtime,0),34,6590+molasses_detuning);
        
         %turn trap down
        setAnalogChannel(curtime,4,0.7);

        %turn repump down
        %setAnalogChannel(curtime,2,0.28); %0.3
     
        
    end
             
    
   
  
    %do molasses for 5ms
    curtime = calctime(curtime,molasses_time); %5
    
    
else
    
    %need to do this so that the probe detuning is ok
    
     %set molasses detuning
%     setAnalogChannel(calctime(curtime,0),34,756); %756
%     %offset FF
%      setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06

end

%% Turn on Trap and Repump Light

    %trap
    curtime = turn_on_beam(calctime(curtime,load_MOT_tof),1,0.7);
    
    %repump
    turn_on_beam(curtime,2,0.8);

    
    
%% Set Frequency 
    %setAnalogChannel(calctime(curtime,load_MOT_tof),5,detuning); %32.8MHz detuning
    
      
%    %list
%  MOT_detuning_list=[6510:5:6540];
%   %Create linear list
%  %index=seqdata.cycle;
%  
%  %Create Randomized list
%  index=seqdata.randcyclelist(seqdata.cycle);
% %  
%  MOT_detuning = MOT_detuning_list(index)
%   addOutputParam('hor_transport_distance',MOT_detuning);
    
if seqdata.atomtype==1 || seqdata.atomtype==4 %K-40
    
    %K-40
    
end

if seqdata.atomtype==2 %K-41
   setAnalogChannel(calctime(curtime,load_MOT_tof),5,detuning); %15MHz worked best for K-41 %32.8MHz detuning
end

if seqdata.atomtype==3 || seqdata.atomtype==4 %Rb-87
    setAnalogChannel(calctime(curtime,load_MOT_tof),34,6590+detuning); %775 is resonance %6585 at room temp
end


%% Turn on MOT Coil
   

BGrad = 15; %10

%Feed Forward
    setAnalogChannel(calctime(curtime,load_MOT_tof),18,10); 
    %CATS
    setAnalogChannel(calctime(curtime,load_MOT_tof),8,BGrad); %13G/cm
    %Science Cell QP (1.5A for 15G/cm)
    
    if loc==1
        if use_kitten_Load_MOT ==1;    
        setAnalogChannel(calctime(curtime,load_MOT_tof),1,3.5);
        setAnalogChannel(calctime(curtime,load_MOT_tof),21,1,1);
        setAnalogChannel(calctime(curtime,load_MOT_tof),3,0,1);
        elseif use_kitten_Load_MOT == 0;
        %set 16 current
        setAnalogChannel(calctime(curtime,load_MOT_tof),1,3.5);
        %set 15 current
        setAnalogChannel(calctime(curtime,load_MOT_tof),21,0,1);
        setAnalogChannel(calctime(curtime,load_MOT_tof),3,0,1);
        setAnalogChannel(calctime(curtime,load_MOT_tof),32,1,1);
        elseif use_kitten_Load_MOT == 2;
        %set 16 current
        setAnalogChannel(calctime(curtime,load_MOT_tof),1,0.5);
        %set 15 current
        setAnalogChannel(calctime(curtime,load_MOT_tof),21,0.5,1);
        end
    end
        
    %TTL
    curtime = setDigitalChannel(calctime(curtime,load_MOT_tof),16,0); %MOT TTL
    
    %turn on channel 16 fast swithch
    setDigitalChannel(curtime,21,0);


%% Turn on Shims

if loc==0

    %list
%  detuning_list=[20:3:41 20:3:41 20:3:41];
% % 
% % %Create linear list
% index=seqdata.cycle;
% % 
% % %Create Randomized list
% % %index=seqdata.randcyclelist(seqdata.cycle);
% % 
%  detuning = detuning_list(index)
%  addOutputParam('resonance',detuning);
    
    %turn on the Y (quantizing) shim 
    curtime = setAnalogChannel(calctime(curtime,0),19,0.9,1); %0.9 feb 4 (0.9 June 6)
    %turn on the X (left/right) shim 
    curtime = setAnalogChannel(calctime(curtime,0),27,0,1);  %0.0 feb 4 (0.0 June 6)
    %turn on the Z (top/bottom) shim 
    curtime = setAnalogChannel(calctime(curtime,0),28,0.42,1);  %0.45 feb 4 (0.42 June 6)
    
elseif loc==1
    
    %turn on the Y (quantizing) shim 
    curtime = setAnalogChannel(calctime(curtime,0),19,0.0); %0.5 
    %turn on the X (left/right) shim 
    curtime = setAnalogChannel(calctime(curtime,0),27,0.0); %0.75
    %turn on the Z (top/bottom) shim 
    curtime = setAnalogChannel(calctime(curtime,0),28,0.0);%0.5
    
else
    
    error('Invalid MOT location');
    
end



    
    %Shutters
    %setDigitalChannel(calctime(curtime,5000),2,0);
    %setDigitalChannel(calctime(curtime,5000),3,0);
    %curtime = calctime(curtime,1000);

%% Turn on Probe
%     %analog
%     setAnalogChannel(calctime(curtime,0),4,.1,1);
%     %TTL
%     setDigitalChannel(calctime(curtime,0),8,0);
%     %shutter
%     curtime=setDigitalChannel(curtime,4,1);


%% MOT fly away

flyaway = 0;

if flyaway

    
    
    %Set Frequency 
    curtime = setAnalogChannel(calctime(curtime,3000),5,10); %32.8MHz detuning
    %setAnalogChannel(calctime(curtime,load_MOT_tof),34,6575);

    
%     %turn on the Y (quantizing) shim 
%     setAnalogChannel(calctime(curtime,-1),19,1.0); %1.0 for molassess
%     %turn on the X (left/right) shim 
%     setAnalogChannel(calctime(curtime,-1),27,0.3); %0.30 for molasses
%     %turn on the Z (top/bottom) shim 
%     setAnalogChannel(calctime(curtime,-1),28,0.1); %0.10 for molasses  
    
    %lower repump intensity
    curtime = setAnalogChannel(curtime,25,0.4);
    curtime = setAnalogChannel(curtime,26,0.7);


        %TTL
        curtime = setDigitalChannel(curtime,16,0); %MOT TTL
         %CATS
        curtime = setAnalogChannel(curtime,8,0); %13.5G/cm
        
end

MOT_flicker = 0;

if MOT_flicker

    for step = 1:1
    
    curtime = setAnalogChannel(calctime(curtime,1000),8,0); 
    curtime = setAnalogChannel(calctime(curtime,2000),8,10); 
 
    
    end

%     curtime = calctime(curtime,2000);
%     setAnalogChannel(curtime,8,0); %13G/cm
%     curtime = calctime(curtime,1000);
%     setAnalogChannel(curtime,8,BGrad)
    
else    
end

timeout=curtime;

    
