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

%% Sort out detuning

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

% Potassium MOT beams turn on
if (seqdata.atomtype==1 || seqdata.atomtype==2 || seqdata.atomtype==4) && k_detuning~=-100
    disp(' Turning on K beams');
    k_trap_power = 0.8; %0.25 for ~2000 atom DFG; 0.8 for full power
    k_repump_power = 0.45; %0.25 for ~2000 atom DFG; 0.45 for full power
    
    % Trap
    turn_on_beam(curtime,1,k_trap_power,1);%0.7
    
    % Repump
    turn_on_beam(curtime,2,k_repump_power,1); 
%     setDigitalChannel(calctime(curtime,0),'gray molasses shear mod AOM TLL',0); % 0: turn off shear mod AOM
%     setDigitalChannel(calctime(curtime,0),'K Repump 0th Shutter',0); %turn on K repump power for MOT
    
%     Rb_Push_Power = 0.7;
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',0);
%     setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',Rb_Push_Power);
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',1);
end

% CF : Why turn off beams for a particular detuning?
if k_detuning == -100    
    %turn off beams
    turn_off_beam(curtime,1,1,1);
    turn_off_beam(curtime,2,1,1);    
end
    

% Rubidium MOT beams turn on
if (seqdata.atomtype==3 || seqdata.atomtype==4) && rb_detuning~=-100
    disp(' Turning on Rb beams');
    
    %Added 06/10/2022 by FC and RL
    %This modulates the frequency and amplitude of the Rb Trap AOM
    %frequency source (Rigol DG 4162) (Device 8). 
    rb_trap_freq_list =  [109]; % in MHz
    rb_trap_freq=getScanParameter(rb_trap_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,...
        'rb_trap_AOM_FM', 'MHz');
    
    rb_trap_amp = 1.08; %in V
    rb_trap_offset = 0; %in V
    
    str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',(rb_trap_freq)*1E6,rb_trap_amp,rb_trap_offset);
    addVISACommand(8, str);  %Device 8 Source 2 is the new Rb trap AOM FM
    
    % Trap
    turn_on_beam(calctime(curtime,K_MOT_before_Rb_time),1,0.7,3); % The analog voltage sent here (0.7) no longer does anything.
    
    % Repump
    turn_on_beam(calctime(curtime,K_MOT_before_Rb_time),2,0.8,3); %should this be 0.9 not 0.8?
    
    rb_repump_power_list = [0.9];
    rb_repump_power = getScanParameter(rb_repump_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'mot_rb_repump_power');;
    setAnalogChannel(calctime(curtime,20),'Rb Repump AM',rb_repump_power);    
end

% CF : Why turn off beams for a particular detuning?
if rb_detuning == -100
    %turn off beams
    turn_off_beam(curtime,1,1,3);
    turn_off_beam(curtime,2,1,3);
end
    
%% Set Frequency 
disp(' Setting MOT Detunings ...');
      
% K Trap Detuning 40K
if (seqdata.atomtype==1 || seqdata.atomtype==4) && k_detuning~=-100   
    setAnalogChannel(calctime(curtime,load_MOT_tof),...
        'K Trap FM',k_detuning);    
end

% K Trap Detuning 41K (This seems unecessary)
if seqdata.atomtype==2 && k_detuning~=-100 %K-41
   setAnalogChannel(calctime(curtime,load_MOT_tof),...
       5,k_detuning); %15MHz worked best for K-41 %32.8MHz detuning
end

% Rubidium Trap Detuning
if (seqdata.atomtype==3 || seqdata.atomtype==4) && rb_detuning~=-100 %Rb-87
    setAnalogChannel(calctime(curtime,load_MOT_tof),...
        'Rb Beat Note FM',6590+rb_detuning ); %775 is resonance %6585 at room temp
    
    MOT_trap_detuning_real = -28;
    f_osc = calcOffsetLockFreq(MOT_trap_detuning_real,'MOT');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,load_MOT_tof),DDS_id,f_osc*1e6,f_osc*1e6,1)    
end

%% Turn on MOT Coil
   disp(' Setting MOT Coil Gradients');


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
   disp(' Setting MOT Shim values');

    %Turn on Shim Supply Relay
    setDigitalChannel(calctime(curtime,0),33,1);

    
%         %turn on the Y (quantizing) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),19,0.95,1); % 0.8 May 29 2013 %0.9 feb 4 (0.9 June 6)  (k=1.8, rb=0.8 june 25)
    %turn on the X (left/right) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),27,0.5,1);  % 0.4 May 29 2013 %0.0 feb 4 (0.0 June 6)  (k=0.0, rb=0.4 june 25)
%     %turn on the Z (top/bottom) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),28,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)
%     %turn on the Z (top/bottom) shim via bipolar supply
%     %curtime = setAnalogChannel(calctime(curtime,0),47,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)

    
    %turn on the Y (quantizing) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),'Y Shim',2,2)%(1.6,1); %1.6 % 0.8 May 29 2013 %0.9 feb 4 (0.9 June 6)  (k=1.8, rb=0.8 june 25)
    %turn on the X (left/right) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),'X Shim',0.2,2)%(0.4,1);  % 0.4 May 29 2013 %0.0 feb 4 (0.0 June 6)  (k=0.0, rb=0.4 june 25)
    %turn on the Z (top/bottom) shim 
%     curtime = setAnalogChannel(calctime(curtime,0),'Z Shim',0.9,2)%(1.6,1);  %1.6 % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)
    %turn on the Z (top/bottom) shim via bipolar supply
    %curtime = setAnalogChannel(calctime(curtime,0),47,0.42,1);  % 0.42 May 29 2013 %0.45 feb 4 (0.42 June 6) (k=0.6,rb=0.42 june 25)

 %Rb optimized shim values
    curtime = setAnalogChannel(calctime(curtime,0),'X Shim',0.2,2);
    curtime = setAnalogChannel(calctime(curtime,0),'Y Shim',2.0,2);
    curtime = setAnalogChannel(calctime(curtime,0),'Z Shim',0.9,2);

 %K optimized shim values
% curtime = setAnalogChannel(calctime(curtime,0),'X Shim',0.0 ,2);  0.2;
% curtime = setAnalogChannel(calctime(curtime,0),'Y Shim', 0.0  ,2); 2;
% curtime = setAnalogChannel(calctime(curtime,0),'Z Shim',0.2 ,2);  0.9;
%  
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

%% MOT PULSE
doMOTPulse = 0;

if doMOTPulse
    disp('Pulsing MOT Beams for PD measurements');
    tW = 500;
    tP = 100;
    
    curtime = calctime(curtime,tW);  % Wait for equilibriation
    
    % Turn off K beams
    setDigitalChannel(calctime(curtime,0),'K Trap Shutter',0);
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);
    
    % Turn on K beams
    setDigitalChannel(calctime(curtime,tP),'K Trap Shutter',1);
    setDigitalChannel(calctime(curtime,tP),'K Repump Shutter',1);    
    curtime = calctime(curtime,tP);
    
    % Wait a little bit
    curtime = calctime(curtime,100);
    
    % Turn off Rb Beams    
    setDigitalChannel(calctime(curtime,0),'Rb Trap Shutter',0);
    setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0);
    
    % Turn on Rb Beams
    setDigitalChannel(calctime(curtime,tP),'Rb Trap Shutter',1);  
    setDigitalChannel(calctime(curtime,tP),'Rb Repump Shutter',1);    
    curtime = calctime(curtime,tP);    
end

%% UV ON
%Turn on UV cataract-inducing light.

disp('Turning on UV light');
UV_On_Time = seqdata.params.UV_on_time;
setDigitalChannel(calctime(curtime,UV_On_Time),'UV LED',1); %1 = on; 0, off
curtime = setAnalogChannel(calctime(curtime,UV_On_Time),'UV Lamp 2',5);


%% End it
timeout=curtime;

    
