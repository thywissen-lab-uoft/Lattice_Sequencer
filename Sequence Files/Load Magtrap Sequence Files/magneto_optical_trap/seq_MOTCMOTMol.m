function timeout = seq_MOTCMOTMol(timein,flags)
curtime = timein;
global seqdata;

if nargin==2
    seqdata.flags.MOTChamber=flags;
else
    % Sub sequence flags    
    seqdata.flags.MOTChamber.doMOT=1;   % Do I load the MOT
    seqdata.flags.MOTChamber.doCMOT=1;  % Do I transition to CMOT?
    seqdata.flags.MOTChamber.doMol=1;   % Do I peform double molasses?
    seqdata.flags.MOTChamber.doTOF=1;   % Do I perform fluorescence imaging with a TOF?
    seqdata.flags.MOTChamber.loadK=1;   % Do I load Potassium?
    seqdata.flags.MOTChamber.loadRb=1;  % Do I load Rubidium?     
    seqdata.flags.image_atomtype='Rb';  % What atom am I imaging?
end  

Rb_MOT_detuning=32;
    
%% Molasses Expansion Test

if seqdata.flags.MOTChamber.doMOT
    % This code initializses the MOT. This includes
    % Rb Detunings and power
    % K Detunings and power
    % Field Gradients, Shims, and other coils
    
% Rb_MOT_detuning= 32; % Rb trap MOT detuning in MHz
K_MOT_detuning = 22; % K trap MOT detuning in MHz   

curtime = calctime(curtime,100);

% Why do we turn the GM shutter off here? 
setDigitalChannel(calctime(curtime,0),1,0);

%%%%%%%%%%%%%%%% Set Rb MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',...          % 775 is resonance %6585 at room temp
    6590+Rb_MOT_detuning);      
setAnalogChannel(calctime(curtime,0),'Rb Trap AM', 0.7);            % Rb MOT Trap power
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);             % Rb MOT trap TTL

% Repump
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0.9);           % Rb MOT repump power
% (no AOM TTL control but we could do this for this, only a shutter);

if seqdata.flags.MOTChamber.loadRb
    % Open the Rb shutters
    setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',1);        % Rb MOT trap shutter
    setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',1);       % Rb MOT repumper shutter
else
    % Close the Rb shutters
    setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',0);        % Rb MOT trap shutter
    setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0);       % Rb MOT repumper shutter
end
        
%%%%%%%%%%%%%%%% Set K MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,10),'K Trap FM',K_MOT_detuning);  % K Trap Detuning
setAnalogChannel(calctime(curtime,0),'K Trap AM',0.8);              % K MOT trap power
setDigitalChannel(calctime(curtime,0),'K Trap TTL',0);              % K MOT trap TTL

% Repump
setAnalogChannel(calctime(curtime,10),'K Repump FM',0,2); %765      % K Repump Detuning
setAnalogChannel(calctime(curtime,0),'K Repump AM',0.45);           % K MOT repump power
setDigitalChannel(calctime(curtime,0),'K Repump TTL',0);            % K MOT repump TTL

if seqdata.flags.MOTChamber.loadK
    setDigitalChannel(calctime(curtime,0),'K Trap Shutter',1);          % K mot trap shutter
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);        % K MOT repump shutter
else
    setDigitalChannel(calctime(curtime,0),'K Trap Shutter',0);          % K mot trap shutter
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);        % K MOT repump shutter
end


%%%%%%%%%%%%%%%% MOT Field Gradient %%%%%%%%%%%%%%%%
BGrad = 10; %10
% Set MOT Field Gradient via CATS
setAnalogChannel(calctime(curtime,0),8,BGrad); 

%TTL 
curtime = setDigitalChannel(calctime(curtime,0),16,0); %MOT TTL

%Feed Forward (why is this here? CF)
% What does this do here?
setAnalogChannel(calctime(curtime,0),18,10); 


%%%%%%%%%%%%%%%% MOT Chamber shims %%%%%%%%%%%%%%%%

% Turn on shim supply relay, this diverts shim currens to MOT chamber
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

% THE NAMES OF THE SHIMS MAKE NO SESNSE

%turn on the Y (quantizing) shim 
curtime = setAnalogChannel(calctime(curtime,0),'Y MOT Shim',1.6,1);  1.6;
%turn on the X (left/right) shim 
curtime = setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.4,1);  0.4;
%turn on the Z (top/bottom) shim 
curtime = setAnalogChannel(calctime(curtime,0),'Z MOT Shim',1.6,1);  1.6;

%turn on the Z (top/bottom) shim via bipolar supply
%curtime = setAnalogChannel(calctime(curtime,0),47,0.42,1);   
    
curtime = calctime(curtime,10000);

%% Test D1 locking
% This piece of code is useful to check if the D1 laser has gone out of
% lock by checking to see if the D1 light can be use as a repumper for the
% MOT

test_D1_lock = 0;
if (test_D1_lock)
%TTL off D2 )
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1);  %1:off 0:on
%Turn on D1
    setDigitalChannel(calctime(curtime,-3),1,1);
end    
    

end

%% cMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
if seqdata.flags.MOTChamber.doCMOT
if ~seqdata.flags.MOTChamber.doMOT
   error('You cannot load a CMOT without a MOT');       
end
    
        
% Time duration
rb_cMOT_time = 25;          % Duration of the CMOT
k_cMOT_time = 25;           % Duration of the CMOT
cMOT_time = 50; %100 80

% Rubidum power
rb_cMOT_detuning = 42;      % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;

% Potassium power
k_cMOT_detuning = 5;            % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz

% Set the potassium beams            
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 

yshim_comp = 0.8;0.75;0.3;0.8;%0.8; %0.9 %0.8
xshim_comp = 0.25;0.6;0.4;%0.4; %0.25 %0.4
zshim_comp = 0.6;0.425;0.42;0.42;%0.42;

    % CMOT shim values (CF thinks these should be identical to the MOT ones
    % ideally)    
setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',yshim_comp,2); %1.25
setAnalogChannel(calctime(curtime,-2),'X MOT Shim',xshim_comp,2); %0.3 
setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',0,2); %0.2

% Change Rubidium detunings
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',rb_cmot_repump_power);

% Turn down Rbudium trap power (AOM is before TA)
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Trap AM',0.1);

% Change Potassium detunings
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765

% Turn down Potassium trap and repump power
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.25); %0.25
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.7); %0.7 %0.3 Oct 30, 2015 

%increase gradient to 15 G/cm
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'MOT Coil',10);

curtime=calctime(curtime,cMOT_time);   
end


%% Combined Molasses - K D1 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time from the CMOT phase

if seqdata.flags.MOTChamber.doMol

%%%%%%%%%%%% Shift the fields %%%%%%%%%%%%

% Turn off field gradients
setAnalogChannel(curtime,'MOT Coil',0,1);   

% Set the shims
setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.15,2); %0.3
setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.15,2); %0.25
setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.00,2);%0.1

%%%%%%%%%%%% Turn off K D2  %%%%%%%%%%%%

setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);   %1:off 0:on
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); %1:off 0:on

%%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%
% Rubidium molasses detuning
rb_molasses_detuning_list = 110;
rb_molasses_detuning = getScanParameter(rb_molasses_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_molasses_det');  

% Rubidium molasses trap power
rb_mol_trap_power_list = .15;
rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_trap_power');

% Rubidium molasses repump power
rb_mol_repump_power_list = 0.08;[0.01:0.01:0.15];0.02;
rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');
   
% Set the Rb beams
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 

%%%%%%%%%%%% K D1 GM Settings %%%%%%%%%%%%
% GM Sidebands - Detuning
SRS_det_list =  -0.6;
SRS_det = getScanParameter(SRS_det_list,seqdata.scancycle,seqdata.randcyclelist,'GM_SRS_det');
% GM Sidebands - Power
SRSpower_list = [2];   %%8
SRSpower = getScanParameter(SRSpower_list,seqdata.scancycle,seqdata.randcyclelist,'SRSpower');

% Set the two-photon detuning (SRS)
SRSAddress = 27;
rf_on = 1;
SRSfreq = 1285.8+SRS_det;%1285.8
addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));

% GM Double pass - shift from 70 MHz
D1_freq_list = [0];
D1_freq = getScanParameter(D1_freq_list,seqdata.scancycle,seqdata.randcyclelist,'D1_freq');
% GM Double pass - modulation depth
mod_amp_list = [1.2];
mod_amp = getScanParameter(mod_amp_list,seqdata.scancycle,seqdata.randcyclelist,'GM_power');

% Set the Single photon detuning (Rigol)
mod_freq = (70+D1_freq)*1E6;
mod_offset =0;
str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
addVISACommand(3, str);

% Open the D1 shutter (3 ms pre-trigger for delay)
setDigitalChannel(calctime(curtime,-3),1,1);

%%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
% Total Molasses Time
molasses_time_list = 5;
molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time'); 

% Wait for molasses
curtime = calctime(curtime,molasses_time);

% Close the D1 Shutter (3 ms pre-trigger for delay); 
setDigitalChannel(calctime(curtime,-3),65,0); % we have a double shutter on this beam
end




%% Time of flight
% This section of code performs a time flight before doing fluorescence
% imaging with the MOT beams.
if seqdata.flags.MOTChamber.doTOF

%%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%
    
% Turn off the field gradient
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);    

% Turn off the D2 beams, if they arent off already
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

% Turn off the D1 beams. The GM stage automattically does this

%%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%

% Set the time of flight
tof_list = 1;
tof =getScanParameter(tof_list,seqdata.scancycle,seqdata.randcyclelist,'tof_time'); 

% Increment the time (ie. perform the time of flight
curtime = calctime(curtime,tof);
    
%%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
%turn back on D2 for imaging (or make it on resonance)  

% Set potassium detunings to resonances (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,0),'K Trap FM',0);

setAnalogChannel(calctime(curtime,0),'K Repump FM',0,2);

% Set potassium power to standard value
setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

% Set Rubidium detunings to resonance (1 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

% Set rubdium power to standard value
setAnalogChannel(calctime(curtime,-1),'Rb Trap AM', 0.7);            
setAnalogChannel(calctime(curtime,-1),'Rb Repump AM',0.9);          

% Turn the beams on
switch seqdata.flags.image_atomtype
    case 'Rb' || 1
        setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
        setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
        setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);    
    case 'K' || 2
        setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
        setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
        setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);     
end
 

% Camera Trigger (1) : Light+Atoms
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);

% Wait for second image trigger
curtime = calctime(curtime,3000);

% Camera Trigger (2) : Light only
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);
 
% wtich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),1,0);
setDigitalChannel(calctime(curtime,0),65,1);
end

timeout = curtime;