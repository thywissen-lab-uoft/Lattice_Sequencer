function timeout = MOT_sequence_new(timein)

if nargin == 0 
    timein = 0;
else
    curtime = timein;
end

global seqdata

%% TOF

seqdata.params.tof = getVar('tof');

%% PA Laser Lock Detuning

if seqdata.flags.misc_lock_PA    
    updatePALock(curtime);    
end

%% Set Objective Piezo Voltages
% Update the objective piezo height

if seqdata.flags.misc_moveObjective
    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',...
        getVarOrdered('objective_piezo'),1);
end
    


%% Gray Molasses
% Why should this be here? Put it in the MOT part of the code?

if seqdata.flags.MOT_programGMDP
    setAnalogChannel(calctime(curtime,0),'D1 FM',getVar('D1_DP_FM'));    
end

%% Initialize Voltage levels
% CF: All of these should be put into some separate reset code

%Initialize modulation ramp to off.
setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0);

%Initialize the Raman VVA to on.
setAnalogChannel(calctime(curtime,0),'Raman VVA',9.9);

%close all RF and uWave switches
setDigitalChannel(calctime(curtime,0),'RF TTL',0);
setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
setAnalogChannel(calctime(curtime,0),'uWave VVA',10);

%Set both transfer switches back to initial positions
setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);   % 0: RF
setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); % 1: Rb
setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1);  % 0:Anritsu, 1 = Sextupler (unsued?)

%Reset Feschbach coil regulation
setDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);   % Integrator disabled
setDigitalChannel(calctime(curtime,0),'FB offset select',0);    % No offset voltage

%turn off dipole trap beams
setAnalogChannel(calctime(curtime,0),'dipoleTrap1',seqdata.params.ODT_zeros(1));
setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);

%turn off lattice beams
setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);%-0.1,1);    
setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%-0.1,1);
setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);%-0.1,1);

setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up

%set rotating waveplate back to full dipole power
AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);

%set uWave Generator Selection back to SRS A by default
setDigitalChannel(curtime,'K uWave Source',0);

% Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
CDT_piezo_X = 0;
CDT_piezo_Y = 0;
CDT_piezo_Z = 0;
% setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X,1);
setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y,1);
setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z,1);

%Close science cell repump shutter
setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed

%Kill beam AOM on to keep warm.
setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
setDigitalChannel(curtime,'Downwards D2 Shutter',0);

%Pulsed beams on to keep warm.
setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);

%Set Raman AOM TTL to open for AOM to stay warmed up
%Turn off Raman shutter with TTL.
%     setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
setDigitalChannel(calctime(curtime,5),'Raman Shutter',0); %2021/03/30 new shutter

setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1);

setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1);

%Set 'D1' Raman AOMs to open, shutter closed.
setDigitalChannel(calctime(curtime,0),'EIT Probe TTL',1);
setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);

%Set TTL to keep F-pump and mF-pump warm.
setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
setAnalogChannel(calctime(curtime,0),'F Pump',9.99);

%Plug beam
setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
setAnalogChannel(calctime(curtime,0),'Plug',getVar('plugTA_current')); % Current in mA

%High-field imaging
setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);

% Turn on MOT Shim Supply Relay
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

% Turn off Rigol modulation
addr_mod_xy = 9; % ch1 x mod, ch2 y mod
addr_z = 5; %ch1 z lat, ch2 z mod  
ch_off = struct;
ch_off.STATE = 'OFF';
ch_off.AMPLITUDE = 0;
ch_off.FREQUENCY = 1;

programRigol(addr_mod_xy,ch_off,ch_off);    % Turn off xy mod
programRigol(addr_z,[],ch_off);             % Turn off z mod

%% Load the MOT
curtime = calctime(curtime,500);

seqdata.flags.MOT_load_at_start = 1;

% Rerun load MOT if necessary for controller load
if (seqdata.flags.MOT_load_at_start == 1)
    loadMOTSimple(curtime,1);   
    curtime = calctime(curtime,getVar('MOT_controlled_load_time'));
end   

%% Prepare to Load into the Magnetic Trap
% CF Why are these TTLs switched? Just use the shutter and go back to max
% MOT power?!?

if seqdata.flags.MOT_prepare_for_MT
    dispLineStr('Preparing MOT for MT',curtime);   
    
    % If not a fluoresence image take a picture of the MOT here
    if seqdata.flags.image_type ~= 1    
        DigitalPulse(calctime(curtime,-10),'Mot Camera Trigger',1,1);
    end


    curtime = Prepare_MOT_for_MagTrap(curtime);

    if seqdata.flags.image_type == 0    
        %Open other AOMS to keep them warm. Why ever turn them off for long
        %when we have shutters to do our dirty work?
        setDigitalChannel(calctime(curtime,10),'K Trap TTL',0);
        setAnalogChannel(calctime(curtime,10),'K Trap AM',0.8);

        setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',0);    
        setAnalogChannel(calctime(curtime,10),'Rb Trap AM',0.7);

        setDigitalChannel(calctime(curtime,10),'K Repump TTL',0);
        setAnalogChannel(calctime(curtime,10),'K Repump AM',0.45);

        setAnalogChannel(calctime(curtime,10),'Rb Repump AM',0.9);
    end
end

    
%% Load into Magnetic Trap
% CF : The shims probably should be diabatically switch after loading into
% the magtrap. On the other hand, you don't want to keep atoms in the MOT
% cell for too long due to high vapor pressure

if seqdata.flags.MOT_load_to_MT
    
    yshim2 = 0.25;
    xshim2 = 0.25;
    zshim2 = 0.05;

    %optimize shims for loading into mag trap
    setAnalogChannel(calctime(curtime,0.01),'Y MOT Shim',yshim2,3); %1.25
    setAnalogChannel(calctime(curtime,0.01),'X MOT Shim',xshim2,2); %0.3 
    setAnalogChannel(calctime(curtime,0.01),'Z MOT Shim',zshim2,2); %0.2

    curtime = Load_MagTrap_from_MOT(curtime);

    % CF : This seems bad to me as they will perturb the just loaded MT, I
    % think should this be done adiabatically

    %**Should be set to zero volts to fully turn off the shims (use volt func 1)
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.0,2); %2
else
    
    tramp = 20;    
    tdel = 2000;
    AnalogFuncTo(calctime(curtime,tdel),'X MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(1),2);    
    AnalogFuncTo(calctime(curtime,tdel),'Y MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(2),2);    
    AnalogFuncTo(calctime(curtime,tdel),'Z MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(3),2);       
end

%% Time of flight
% This section of code performs a time flight before doing fluorescence
% imaging with the MOT beams.
doTOF =1;

if ~doTOF && seqdata.flags.MOT_load_to_MT
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
tof_list = [1:1:15];
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
if seqdata.flags.image_atomtype == 1
    setDigitalChannel(calctime(curtime,-5),'K Repump Shutter',1); 
    setDigitalChannel(calctime(curtime,-5),'K Trap Shutter',1); 
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
end

% % Imaging beams for Rb
if seqdata.flags.image_atomtype == 0
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);      
    setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1); 
    setDigitalChannel(calctime(curtime,-5),'Rb Trap Shutter',1); 
end

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


tnow=now;
addOutputParam('now',(tnow-floor(tnow))*24*60*60);

timeout = curtime;