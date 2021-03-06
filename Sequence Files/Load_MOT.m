%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = Load_MOT(timein,detuning,loc)

curtime = timein;
global seqdata;

%detuning: Can be a 1x2 vector or a single number. If a vector and the atom
%type is set to K+Rb then the first element is Rb detuning and second is K
%detuning. If detuning is -100 then do not turn on the MOT

%loc: 0 MOT cell, 1 sci cell

if nargin<3
   loc = 0;
end

load_MOT_tof = 10;

%use kitten or not
use_kitten_Load_MOT = 2; %0: no kitten, 1: kitten, 2: coil 15 h-bridge

%trigger dark spot
%DigitalPulse(calctime(curtime,0),15,10,1)

%% sort out detuning

if length(detuning)==1
    rb_detuning = detuning;
    k_detuning = detuning;
elseif length(detuning)==2
    rb_detuning = detuning(1);
    k_detuning = detuning(2);
else
    error('Detuning format is wrong')
end

ScopeTriggerPulse(calctime(curtime,0),'Load MOT',1);


%% Turn shim multiplexer to MOT shims    
    setDigitalChannel(calctime(curtime,0),37,0); 
    %Don't close relay for Science Cell Shims because of current spikes
    setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);

%% Turn on Trap and Repump Light

curtime = calctime(curtime, load_MOT_tof);
%MOT stagger
K_MOT_before_Rb_time=0;

%K
if (seqdata.atomtype==1 || seqdata.atomtype==2 || seqdata.atomtype==4) && k_detuning~=-100
    
    k_trap_power = 0.8; %0.25 for ~2000 atom DFG; 0.8 for full power
    k_repump_power = 0.45; %0.25 for ~2000 atom DFG; 0.45 for full power
    
    %trap
    turn_on_beam(curtime,1,k_trap_power,1);%0.7
    
    %repump
    turn_on_beam(curtime,2,k_repump_power,1); 
%     setDigitalChannel(calctime(curtime,0),'gray molasses shear mod AOM TLL',0); % 0: turn off shear mod AOM
%     setDigitalChannel(calctime(curtime,0),'K Repump 0th Shutter',0); %turn on K repump power for MOT
    
%     Rb_Push_Power = 0.7;
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',0);
%     setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',Rb_Push_Power);
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',1);

end

if k_detuning == -100
    
    %turn off beams
    turn_off_beam(curtime,1,1,1);
    turn_off_beam(curtime,2,1,1);    
end
    

%Rb
if (seqdata.atomtype==3 || seqdata.atomtype==4) && rb_detuning~=-100
    
    %trap
    turn_on_beam(calctime(curtime,K_MOT_before_Rb_time),1,0.7,3);
    
    %repump
    turn_on_beam(calctime(curtime,K_MOT_before_Rb_time),2,0.8,3);
    rb_repump_power_list = [0.9];
    rb_repump_power = getScanParameter(rb_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'mot_rb_repump_power');;
    setAnalogChannel(calctime(curtime,20),'Rb Repump AM',rb_repump_power);
    
end

if rb_detuning == -100
    %turn off beams
    turn_off_beam(curtime,1,1,3);
    turn_off_beam(curtime,2,1,3);
end
    
%% Set Frequency 
        
if (seqdata.atomtype==1 || seqdata.atomtype==4) && k_detuning~=-100 %K-40
    
    %K-40
    setAnalogChannel(calctime(curtime,load_MOT_tof),'K Trap FM',k_detuning);
    
end

if seqdata.atomtype==2 && k_detuning~=-100 %K-41
   setAnalogChannel(calctime(curtime,load_MOT_tof),5,k_detuning); %15MHz worked best for K-41 %32.8MHz detuning
end

if (seqdata.atomtype==3 || seqdata.atomtype==4) && rb_detuning~=-100 %Rb-87
    setAnalogChannel(calctime(curtime,load_MOT_tof),34,6590+rb_detuning ); %775 is resonance %6585 at room temp
end


%% Turn on MOT Coil
   

BGrad = 10; %10

%Feed Forward
    setAnalogChannel(calctime(curtime,0),18,10); 
    %CATS
    setAnalogChannel(calctime(curtime,0),8,BGrad); %load_MOT_tof
% %    Science Cell QP (1.5A for 15G/cm)
    
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
    curtime = setDigitalChannel(calctime(curtime,0),16,0); %MOT TTL
    
    %turn on channel 16 fast swithch
    setDigitalChannel(curtime,21,0);


%% Turn on Shims

if loc==0
    
       %Turn on Shim Supply Relay
    setDigitalChannel(calctime(curtime,0),33,1);

    
%         %turn on the Y (quantizing) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),19,0.95,1); % 0.8 May 29 2013 %0.9 feb 4 (0.9 June 6)  (k=1.8, rb=0.8 june 25)
%     %turn on the X (left/right) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),27,0.5,1);  % 0.4 May 29 2013 %0.0 feb 4 (0.0 June 6)  (k=0.0, rb=0.4 june 25)
%     %turn on the Z (top/bottom) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),28,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)
%     %turn on the Z (top/bottom) shim via bipolar supply
%     %curtime = setAnalogChannel(calctime(curtime,0),47,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)

    
    %turn on the Y (quantizing) shim 
    curtime = setAnalogChannel(calctime(curtime,0),19,1.6,1); %1.6 % 0.8 May 29 2013 %0.9 feb 4 (0.9 June 6)  (k=1.8, rb=0.8 june 25)
    %turn on the X (left/right) shim 
    curtime = setAnalogChannel(calctime(curtime,0),27,0.4,1);  % 0.4 May 29 2013 %0.0 feb 4 (0.0 June 6)  (k=0.0, rb=0.4 june 25)
    %turn on the Z (top/bottom) shim 
    curtime = setAnalogChannel(calctime(curtime,0),28,1.6,1);  %1.6 % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)
    %turn on the Z (top/bottom) shim via bipolar supply
    %curtime = setAnalogChannel(calctime(curtime,0),47,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)
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

% curtime = calctime(curtime,10000);
% turn_off_beam(curtime,1,1,3);
% curtime = MOT_fluor_image(calctime(curtime,30));

%curtime = calctime(curtime,-500);

%Turn on UV cataract-inducing light.
UV_On_Time = seqdata.params.UV_on_time;
setDigitalChannel(calctime(curtime,UV_On_Time),'UV LED',1); %1 = on; 0, off
curtime = setAnalogChannel(calctime(curtime,UV_On_Time),'UV Lamp 2',5);
% setDigitalChannel(calctime(curtime,0),12,1);
% setDigitalChannel(calctime(curtime,5000),12,0);

timeout=curtime;

    
