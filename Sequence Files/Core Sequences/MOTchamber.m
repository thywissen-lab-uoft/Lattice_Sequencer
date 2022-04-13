function timeout = MOTchamber(timein)

curtime = timein;
global seqdata

%% Pre-initiliaze


% CF : Shall we have some kind of reset in the beginning of the sequence?

% Turn off GM Shutter
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

% MOT Load

doMOT  = 1;
if doMOT
% This code initializses the MOT. This includes
% Rb+K detunings and power
% Field Gradients, Shims, and other coils
    
rb_MOT_detuning= 32;        % Rb trap MOT detuning in MHz
k_MOT_detuning = 22;        % K trap MOT detuning in MHz   
MOT_time = 1000;           % MOT load time in ms
curtime = calctime(curtime,100);

% Turn the UV on
setDigitalChannel(calctime(curtime,-0),'UV LED',1); % THe X axis bulb 1 on 0 off
setAnalogChannel(calctime(curtime,-0),'UV Lamp 2',3); % The y axis bubls 3V on , 0off
%%%%%%%%%%%%%%%% Set Rb MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',...          
    6590+rb_MOT_detuning);      
setAnalogChannel(calctime(curtime,0),'Rb Trap AM', 0.7);            % Rb MOT Trap power   (voltage)
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);             % Rb MOT trap TTL     (0 : ON)
setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',1);        % Rb MOT trap shutter (1 : ON)

% Repump
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0.9);           % Rb MOT repump power (voltage)
setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',1);       % Rb MOT repumper shutter (1 : ON)

%%%%%%%%%%%%%%%% Set K MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,10),'K Trap FM',k_MOT_detuning);  % K Trap Detuning
setAnalogChannel(calctime(curtime,0),'K Trap AM',0.8);              % K MOT trap power
setDigitalChannel(calctime(curtime,0),'K Trap TTL',0);              % K MOT trap TTL
setDigitalChannel(calctime(curtime,0),'K Trap Shutter',1);          % K mot trap shutter

% Repump
setAnalogChannel(calctime(curtime,10),'K Repump FM',0,2); %765      % K Repump Detuning
setAnalogChannel(calctime(curtime,0),'K Repump AM',0.45);           % K MOT repump power
setDigitalChannel(calctime(curtime,0),'K Repump TTL',0);            % K MOT repump TTL
setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);        % K MOT repump shutter

%%%%%%%%%%%%%%%% MOT Field Gradient %%%%%%%%%%%%%%%%
% Set MOT gradient
MOTBGrad = 10; %10
setAnalogChannel(calctime(curtime,0),'MOT Coil',MOTBGrad); 
addOutputParam('MOTBGrad',MOTBGrad);

%TTL (is this a TTL to the MOT currents?)
curtime = setDigitalChannel(calctime(curtime,0),'MOT TTL',0);

%Feed Forward (why is this here? CF)
setAnalogChannel(calctime(curtime,0),18,10); 


%%%%%%%%%%%%%%%% MOT Chamber shims %%%%%%%%%%%%%%%%

% Turn on shim supply relay, this diverts shim currens to MOT chamber
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

% The MOT shims in AMPS
% shims=0:0.1:.5;
% shim=getScanParameter(shims,seqdata.scancycle,seqdata.randcyclelist,'MOT_yshim');
curtime = setAnalogChannel(calctime(curtime,0),'X Shim',0.2 ,2);  0.2;
curtime = setAnalogChannel(calctime(curtime,0),'Y Shim', 2.0  ,2); 2;
curtime = setAnalogChannel(calctime(curtime,0),'Z Shim',0.9 ,2);  0.9;

%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime = calctime(curtime,MOT_time);
addOutputParam('MOT_time',MOT_time);

% Turn UV off
setDigitalChannel(calctime(curtime,-0),'UV LED',0); % THe X axis bulb 1 on 0 off
setAnalogChannel(calctime(curtime,-0),'UV Lamp 2',0); % The y axis bubls 3V on , 0off

end

   
%% cMOT V3. try to get best CMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
doCMOTv3 =1;        
if doCMOTv3
if ~doMOT
   error('You cannot load a CMOT without a MOT');       
end
            
% Time duration
rb_cMOT_time = 25;              % Ramp time of Rb CMOT
k_cMOT_time = 25;               % Ramp time of K CMOT

% Rubidum
rb_cMOT_detuning = 42;          % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;  % Rubidum CMOT repump power in V

% rb_cMOT_detunings=0:5:50;
% rb_cMOT_detuning=getScanParameter(rb_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_detuning');

% rb_cmot_repump_powers=0:.1:.9;
% rb_cmot_repump_power= getScanParameter(rb_cmot_repump_powers,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_repump_am');  %in MHZ
%  

% Potassium
k_cMOT_detuning = 5; 5;         % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz


k_cMOT_detunings=[4];
k_cMOT_detuning= getScanParameter(k_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_detuning');  %in MHZ

k_cMOT_times=[20];
k_cMOT_time= getScanParameter(k_cMOT_times,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_time');  
rb_cMOT_time=k_cMOT_time;

cMOT_time = max([rb_cMOT_time k_cMOT_time]); [50];% Total CMOT time

% Append output parameters if desired   
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
addOutputParam('rb_cMOT_detuning',rb_cMOT_detuning);
addOutputParam('rb_cmot_repump_power',rb_cmot_repump_power); 

%%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
% We have experimentally found that the "best" CMOT shims are the ones that
% match the MOT, but this can nominally be different
% setAnalogChannel(calctime(curtime,-2),'Y Shim',0.84,2); 
% setAnalogChannel(calctime(curtime,-2),'X Shim',0.25,2); 
% setAnalogChannel(calctime(curtime,-2),'Z Shim',0.00,2);

%%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
% AnalogFuncTo(calctime(curtime,0),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rb_cMOT_time,rb_cMOT_time,6590+rb_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',rb_cmot_repump_power);
setAnalogChannel(calctime(curtime,0),'Rb Trap AM',0.1);

%%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'K Trap FM',k_cMOT_detuning); %765
% AnalogFuncTo(calctime(curtime,0),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'K Repump FM',k_cMOT_repump_detuning,2); %765
% AnalogFuncTo(calctime(curtime,0),'K Repump FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_repump_detuning,2);

K_trap_am_list = [0.5];0.7;
k_cMOT_trap_am = getScanParameter(K_trap_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_trap_am');  %in MHZ
setAnalogChannel(calctime(curtime,0),'K Repump AM',0.25); %0.25
setAnalogChannel(calctime(curtime,0),'K Trap AM',k_cMOT_trap_am); %0.7 %0.3 Oct 30, 2015 

%%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
% CMOTBGrad=10;
% setAnalogChannel(calctime(curtime,0),'MOT Coil',CMOTBGrad);

% CMOTBGrads=20;
% CMOTBGrad= getScanParameter(CMOTBGrads,seqdata.scancycle,seqdata.randcyclelist,'CMOTBGrad');  %G/cm
% AnalogFuncTo(calctime(curtime,0),'MOT Coil',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),cMOT_time,cMOT_time,CMOTBGrad);


%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime=calctime(curtime,cMOT_time);   
end

%% Combined Molasses - K D1 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time after the CMOT.

doMol = 1;
if doMol

%%%%%%%%%%%% Shift the fields %%%%%%%%%%%%
% Set field gradient and shim values (ideally) to zero

% Turn off field gradients
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);   

% Set the shims
setAnalogChannel(calctime(curtime,0),'X Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Y Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Z Shim',0.00,2); %0.00

% Wait for fields to turn off (testing)
curtime=calctime(curtime,0);  

%%%%%%%%%%%% Turn off K D2  %%%%%%%%%%%%
% Turn off the K D2 light
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);   % (1: OFF)
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); % (1: OFF)

%%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%
% Rb Mol detuning setting
rb_molasses_detuning_list = 110;
rb_molasses_detuning = getScanParameter(rb_molasses_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_molasses_det');  

% Rb Mol trap power setting
rb_mol_trap_power_list = 0.15;
rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
% Rb Mol repump power settings
rb_mol_repump_power_list = 0.08;[0.01:0.01:0.15];
rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');
   
% Set the power and detunings
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 

%%%%%%%%%%%% K D1 GM Settings %%%%%%%%%%%%
% K D1 GM two photon detuning
SRS_det_list = [0];%0
SRS_det = getScanParameter(SRS_det_list,seqdata.scancycle,seqdata.randcyclelist,'GM_SRS_det');

% K D1 GM two photon sideband power
SRSpower_list = [4];   %%8
SRSpower = getScanParameter(SRSpower_list,seqdata.scancycle,seqdata.randcyclelist,'SRSpower');

% Set the two-photon detuning (SRS)
SRSAddress = 27; rf_on = 1; SRSfreq = 1285.8+SRS_det;%1285.8
addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));

% K D1 GM double pass (single photon detuning) - shift from 70 MHz
D1_freq_list = [0];
D1_freq = getScanParameter(D1_freq_list,seqdata.scancycle,seqdata.randcyclelist,'D1_freq');

% K D1 GM Double pass - modulation depth
mod_amp_list = [1.3];
mod_amp = getScanParameter(mod_amp_list,seqdata.scancycle,seqdata.randcyclelist,'GM_power');

% Set the single photon detuning (Rigol)
mod_freq = (70+D1_freq)*1E6;
mod_offset =0;
str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
addVISACommand(3, str);

% Open the D1 shutter (3 ms pre-trigger for delay)
setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter',1);

%%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
% Total Molasses Time
molasses_time_list = [8];
molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time'); 

%%%%%%%%%%%% advance time during molasses  %%%%%%%%%%%%
curtime = calctime(curtime,molasses_time);

% Close the D1 Shutter (3 ms pre-trigger for delay); 
setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter 2',0); % we have a double shutter on this beam
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);     % close this shutter too

end

%% Combined Molasses - K D2 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time from the CMOT phase
doMol2 = 1;
if doMol2

%%%%%%%%%%%% Shift the fields %%%%%%%%%%%%
% Set field gradient and shim values (ideally) to zero

% Turn off field gradients
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);   

% Set the shims to the nominal "zero field"
setAnalogChannel(calctime(curtime,0),'X Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Y Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Z Shim',0.00,2); %0.00

% Wait for fields to turn off
curtime=calctime(curtime,0);  % Currently set to zero as it hasn't made a difference

%%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%

% Rb Mol detuning setting
rb_molasses_detuning_list = 110;
rb_molasses_detuning = getScanParameter(rb_molasses_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_molasses_det');  

% Rb Mol trap power setting
rb_mol_trap_power_list = 0.15;
rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
% Rb Mol repump power settings
rb_mol_repump_power_list = 0.08;[0.01:0.01:0.15];
rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');
   
% Set the power and detunings
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 

%%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
% Total Molasses Time
molasses_time_list = [8];
molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time'); 

%%%%%%%%%%%% advance time during molasses  %%%%%%%%%%%%
curtime = calctime(curtime,molasses_time);
end

%% Optical Pumping
setDigitalChannel(calctime(curtime,0),'ScopeTrigger',1);
setDigitalChannel(calctime(curtime,1),'ScopeTrigger',0); 

doOP =1;
if doOP
% This stage using the Rb/K Pump (trap light) beam along the Y-axis to pump
% atoms into the |2,2> and |9/2,9/2> state

    % Turn off the trap beams before OP (keep repump on)    
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);    
    setDigitalChannel(calctime(curtime,-1.8),'Rb Trap Shutter',0); 
    setDigitalChannel(calctime(curtime,-1.8),'K Trap Shutter',0); 
    
    % Advance time a bit
    curtime = calctime(curtime,0.1);

    %some flags used in the script for optical pumping
    seqdata.flags.Rb_Probe_Order = 1;
%     seqdata.flags.K_D2_gray_molasses = 0;
    seqdata.flags.image_loc = 1;

    % Perform optical pumping
    curtime = optical_pumping(calctime(curtime,0.0));
    

end



%% Load into Magnetic Trap
loadMT = 1;

if loadMT 
    % Turn off Rb MOT Trap
    setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',0); 
    setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',0); 
    
    % Turn off Rb MOT Repump
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);     
    
    % Turn off Rb Probe
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'Rb Probe/OP Shutter',0); 

    % Turn of K MOT Trap
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'K Trap Shutter',0); 
    
    % Turn off K MOT Repump
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'K Repump Shutter',0); 

    % Turn off K Probe
    setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); % (0 is off for this beam)
    setDigitalChannel(calctime(curtime,-2),'K Probe/OP Shutter',0); 

    % Turn on the magtrap
    curtime = Load_MagTrap_from_MOT(curtime);    
    
%     curtime = calctime(curtime,100);    

    % Set the shims away from pumping values back to "zero" field
    setAnalogChannel(calctime(curtime,0),'X Shim',0.15,2); % 0.15
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.15,2); % 0.15
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.00,2); % 0.0    
    
    
    % Hold in magnetic trap if desired
    MTholds = [75];
    MThold =getScanParameter(MTholds,seqdata.scancycle,seqdata.randcyclelist,'MThold'); 
    curtime = calctime(curtime,MThold);    

end

%% Time of flight
% This section of code performs a time flight before doing fluorescence
% imaging with the MOT beams.
doTOF = 1;

if ~doTOF && loadMT
   error('MT load is not followed by TOF. Coils will get too hot');       
end

if doTOF      

%%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%    
% Turn off the field gradient
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1); 

% levitateGradient=[60:2:90];
% levitateGradient= getScanParameter(levitateGradient,seqdata.scancycle,seqdata.randcyclelist,'levitateGradient');  %in MHZ
% setAnalogChannel(calctime(curtime,0),'MOT Coil',levitateGradient,3); 

% Turn off the D2 beams, if they arent off already
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

%%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%

% Set the time of flight
tof_list = [15];
tof =getScanParameter(tof_list,seqdata.scancycle,seqdata.randcyclelist,'tof_time'); 

% Increment the time (ie. perform the time of flight)
curtime = calctime(curtime,tof);

% Turn coil off in case levitation was on
% setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1); 

%%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
%turn back on D2 for imaging (or make it on resonance)  

% Set potassium detunings to resonances (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',0);
setAnalogChannel(calctime(curtime,-0.5),'K Repump FM',0,2);

% Set potassium power to standard value
setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

% Set Rubidium detunings to resonance (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

% Set rubdium power to standard value
setAnalogChannel(calctime(curtime,-1),'Rb Trap AM', 0.7);            
setAnalogChannel(calctime(curtime,-1),'Rb Repump AM',0.9);          

% Imaging beams for K
% setDigitalChannel(calctime(curtime,-5),'K Repump Shutter',1); 
% setDigitalChannel(calctime(curtime,-5),'K Trap Shutter',1); 
% setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
% setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 

% % Imaging beams for Rb
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);      
setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1); 
setDigitalChannel(calctime(curtime,-5),'Rb Trap Shutter',1); 

% Camera Trigger (1) : Light+Atoms
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);

% Turn off the field gradient
% setAnalogChannel(calctime(curtime,20),'MOT Coil',0,1); 

% Wait for second image trigger
curtime = calctime(curtime,3000);

% Camera Trigger (2) : Light only
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);
 
% switich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

end

%% The end

curtime = calctime(curtime,1000);
timeout = curtime;
