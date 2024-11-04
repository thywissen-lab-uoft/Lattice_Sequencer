function timeout = MOT_sequence_new(timein)

if nargin == 0 
    timein = 0;
else
    curtime = timein;
end

global seqdata

%% MAIN SETTINGS (this is dumb, but just for now)
%Initialize
if nargin == 0 
    curtime = 0;
else
    curtime = timein;
end

global seqdata;

% seqdata.IxonGUIAnalayisHistoryDirectory = 'X:\IxonGUIAnalysisHistory';

% Number of DDS scans is zero
seqdata.numDDSsweeps = 0;

% % CF : Is this really useful? Also we have more than A and B SRS
% seqdata.flags.SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB
% % This can be removed since we don't really do good checkcs.
%%% Constants and Parameters

% % Shim Zero (to eliminate all bkgd fields)
% seqdata.params.shim_zero = [0.1425, -0.0652, -0.1015];
% 
% % Plug Zero (to move MT underneath sapphire window)
% seqdata.params.plug_shims = seqdata.params.shim_zero + ...
%     [-1.3400 +0.125 +0.35];
% 
% % Slope relation between shim and QP currents to keep field center fixed.
% % Important for ramping QP at end of RF1B and during QP ramp down in ODT
% Cx = -0.0507;
% Cy = 0.0045;
% Cz = 0.0115;
% 
% seqdata.params.plug_shims_slopes = [Cx Cy Cz];
% 
% % CF : Is this ever actually used?
% %Current shim values (x,y,z)- reset to zero
% seqdata.params.shim_val = [0 0 0]; 

% MOT Shim values during the MOT (and steady state)
seqdata.params.MOT_shim = [0.2 1.6 0.5]; [0.2 2.0 0.9]; % in Amps

% MOT Shim Zero (for any optical molasses that needs B= 0 G; GM/Mol
seqdata.params.MOT_shim_zero =  [0.15 0.15 0.00]; % in Amps

seqdata.constants.hyperfine_ground = 714.327+571.462;

%%% Misc Flags
seqdata.flags.misc_calibrate_PA             = 0; % Pulse for PD measurement
seqdata.flags.misc_lock_PA                  = 0; % Update wavemeter lock
seqdata.flags.misc_program4pass             = 1; % Update four-pass frequency
seqdata.flags.misc_programGMDP              = 0; % Update GM DP frequency
seqdata.flags.misc_ramp_fesh_between_cycles = 1; % Demag the chamber
seqdata.flags.misc_moveObjective            = 1; % update ojective piezo position
% defVar('objective_piezo',[3.75],'V');[1.65];
% 0.1V = 700 nm, larger means further away from chamber
% 1 V= 7 um
% 10 V = 70 um
% tubeis m30 x .75 (750 um per turn)
% Typically have around 10 planes at most --> 5 um width --> need to
% specify to within 0.1V for a single plane and 1V for the entire cloud
seqdata.flags.Rb_Probe_Order                = 1;   % 1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                                    % 2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT
% defVar('PA_detuning',round(-49.539,6),'GHz');
defVar('UV_on_time',10000,'ms');                    % Can be just added onto the adwin wait timer

%%% MOT Settings

% WARNING : Because we typically load the MOT at the end of the sequence to
% save time, if you change the MOT settings it is generally advised to
% enable the load at start flag so that the MOT settings are updated at the
% beginning of the sequence and the MOT is given time to load.

seqdata.flags.MOT_load_at_start             = 1; %do a specific load time
defVar('MOT_controlled_load_time',10000,'ms');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOT to MT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.MOT_prepare_for_MT            = 0;

seqdata.flags.MOT_CMOT                      = 0; % Do the CMOT
seqdata.flags.MOT_CMOT_detuning_ramp        = 0; % 0:no change, 1:linear ramp, 2:diabatic
seqdata.flags.MOT_CMOT_power_ramp           = 0; % 0:no change, 1:linear ramp, 2:diabatic
seqdata.flags.MOT_CMOT_grad_ramp            = 0; % 0:no change, 1:linear ramp, 2:diabatic

seqdata.flags.MOT_Mol                       = 0; % Do the molasses
seqdata.flags.MOT_Mol_KGM_power_ramp        = 0; % 0: no ramp, 1:linear ramp

seqdata.flags.MOT_optical_pumping           = 0; % optical pumping for MT

seqdata.flags.MOT_load_to_MT                = 0; % do not use
seqdata.flags.loadMT                        = 0;


defVar('k_mot_img_detuning',[-10],'MHz');%-10 GM
% K CMOT parameters
defVar('cmot_k_trap_detuning',2,'MHz');5;
defVar('cmot_k_repump_detuning',0,'MHz');0;
defVar('cmot_k_trap_power',0.5,'V');0.5;
defVar('cmot_k_repump_power',0.25,'V');0.25;
defVar('cmot_k_ramp_time',20,'ms');20;

% Rb CMOT parameters
defVar('cmot_rb_trap_detuning',[-24],'MHz');-30;
defVar('cmot_rb_trap_power',0.1,'V');0.1;
defVar('cmot_rb_repump_power',0.0275,'V');0.0275;
defVar('cmot_rb_ramp_time',20,'ms');20;

% CMOT Field
defVar('cmot_grad',10,'G/cm');

% Rb Molasses
defVar('mol_rb_trap_detuning',[-110],'MHz');-110;-81;
defVar('mol_rb_trap_power',0.15,'V');
defVar('mol_rb_repump_power',0.08,'V');
defVar('mol_rb_time',8,'ms');

% K D1 Gray Molasses
defVar('mol_kd1_single_photon_detuning_shift',[0],'MHz');
defVar('mol_kd1_trap_power_start',1.3,'V');
defVar('mol_kd1_trap_power_end',1.3,'V');
defVar('mol_kd1_two_photon_detuning',[0],'MHz');
defVar('mol_kd1_sideband_power',[-10],'dBm');
defVar('mol_kd1_time',8,'ms');

seqdata.params.Mol_shim = [];

seqdata.flags.MOT_programGMDP              = 0; % Update GM DP frequency
defVar('D1_DP_FM',222.5,'MHz');

%%% Imaging
seqdata.flags.image_type                    = 0; % 0: absorption, 1 : MOT fluor  
seqdata.flags.image_atomtype                = 0; % 0:Rb,1:K,2:K+Rb (double shutter), applies to fluor and absorption

seqdata.flags.image_loc                     = 1; % 0: `+-+MOT cell, 1: science chamber    
seqdata.flags.image_direction               = 1; % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
seqdata.flags.image_stern_gerlach_F         = 0; % 1: Do a gradient pulse at the beginning of ToF
seqdata.flags.image_stern_gerlach_mF        = 0; % 1: Do a gradient pulse at the beginning of ToF
        
seqdata.flags.image_levitate                = 0; % 2: apply a gradient during ToF to levitate atoms (not yet tested)
seqdata.flags.image_iXon                    = 0; % (unused?) use iXon camera to take an absorption image (only vertical)
seqdata.flags.image_F1_pulse                = 0; % (unused?) repump Rb F=1 before/during imaging (unused?)

%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)
seqdata.flags.image_insitu                  = 0; % Does this flag work for QP/XDT? Or only QP?

% Choose the time-of-flight time for absorption imaging 
defVar('tof',[0.25],'ms'); %DFG 25ms ; RF1b Rb 15ms ; RF1b K 5ms; BM 15ms ; in-situ 0.25ms



%% Gray Molasses
% Why should this be here? Put it in the MOT part of the code?

if seqdata.flags.MOT_programGMDP
    setAnalogChannel(calctime(curtime,0),'D1 FM',getVar('D1_DP_FM'));    
end

%% Initialize Voltage levels
% % CF: All of these should be put into some separate reset code
% 
% %Initialize modulation ramp to off.
% setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0);
% 
% %Initialize the Raman VVA to on.
% setAnalogChannel(calctime(curtime,0),'Raman VVA',9.9);
% 
% %close all RF and uWave switches
% setDigitalChannel(calctime(curtime,0),'RF TTL',0);
% setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
% setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
% setAnalogChannel(calctime(curtime,0),'uWave VVA',10);
% 
% %Set both transfer switches back to initial positions
% setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);   % 0: RF
% setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); % 1: Rb
% setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1);  % 0:Anritsu, 1 = Sextupler (unsued?)
% 
% %Reset Feschbach coil regulation
% setDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);   % Integrator disabled
% setDigitalChannel(calctime(curtime,0),'FB offset select',0);    % No offset voltage
% 
% %turn off dipole trap beams
% setAnalogChannel(calctime(curtime,0),'dipoleTrap1',seqdata.params.ODT_zeros(1));
% setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
% setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
% setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);
% 
% %turn off lattice beams
% setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);%-0.1,1);    
% setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%-0.1,1);
% setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);%-0.1,1);
% 
% setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
% setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
% 
% %set rotating waveplate back to full dipole power
% AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);
% 
% %set uWave Generator Selection back to SRS A by default
% setDigitalChannel(curtime,'K uWave Source',0);
% 
% % Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
% CDT_piezo_X = 0;
% CDT_piezo_Y = 0;
% CDT_piezo_Z = 0;
% % setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X,1);
% setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y,1);
% setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z,1);
% 
% %Close science cell repump shutter
% setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
% setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed
% 
% %Kill beam AOM on to keep warm.
% setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
% setDigitalChannel(curtime,'Downwards D2 Shutter',0);
% 
% %Pulsed beams on to keep warm.
% setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
% 
% %Set Raman AOM TTL to open for AOM to stay warmed up
% %Turn off Raman shutter with TTL.
% %     setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
% setDigitalChannel(calctime(curtime,5),'Raman Shutter',0); %2021/03/30 new shutter
% 
% setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1);
% 
% setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1);
% 
% %Set 'D1' Raman AOMs to open, shutter closed.
% setDigitalChannel(calctime(curtime,0),'EIT Probe TTL',1);
% setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);
% 
% %Set TTL to keep F-pump and mF-pump warm.
% setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
% setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
% setAnalogChannel(calctime(curtime,0),'F Pump',9.99);
% 
% %Plug beam
% setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
% setAnalogChannel(calctime(curtime,0),'Plug',getVar('plugTA_current')); % Current in mA
% 
% %High-field imaging
% setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);
% 
% % Turn on MOT Shim Supply Relay
% setDigitalChannel(calctime(curtime,0),'Shim Relay',1);
% 
% % Turn off Rigol modulation
% addr_mod_xy = 9; % ch1 x mod, ch2 y mod
% addr_z = 5; %ch1 z lat, ch2 z mod  
% ch_off = struct;
% ch_off.STATE = 'OFF';
% ch_off.AMPLITUDE = 0;
% ch_off.FREQUENCY = 1;
% 
% programRigol(addr_mod_xy,ch_off,ch_off);    % Turn off xy mod
% programRigol(addr_z,[],ch_off);             % Turn off z mod

%% Load the MOT
curtime = calctime(curtime,500);

% Rerun load MOT if necessary for controller load
if (seqdata.flags.MOT_load_at_start == 1)
%     trigger_offset=0;
%     trigger_length = 50;
%     DigitalPulse(calctime(curtime,trigger_offset-trigger_length),...
%     'LabJack Trigger Transport',trigger_length,1); 
    loadMOTSimple(curtime,1);   
    curtime = calctime(curtime,getVar('MOT_controlled_load_time'));
end   

rampGrad = 0;
if rampGrad == 1
    
    defVar('grad_val',[10:2.5:25]);
    Grad = getVar('grad_val');
    tr = 1000;
    AnalogFuncTo(calctime(curtime,0),'MOT Coil',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tr,tr,Grad);

    curtime = calctime(curtime,2000);
    
end

%% Prepare to Load into the Magnetic Trap
% CF Why are these TTLs switched? Just use the shutter and go back to max
% MOT power?!?

if seqdata.flags.MOT_prepare_for_MT
    logNewSection('Preparing MOT for MT',curtime);   
    
    % If not a fluoresence image take a picture of the MOT here
%     if seqdata.flags.image_type ~= 1    
%         DigitalPulse(calctime(curtime,-10),'Mot Camera Trigger',1,1);
%     end


    curtime = Prepare_MOT_for_MagTrap(curtime);

    if seqdata.flags.image_type == 0    
        %Open other AOMS to keep them warm. Why ever turn them off for long
        %when we have shutters to do our dirty work?
        setDigitalChannel(calctime(curtime,100),'K Trap TTL',0);
        setAnalogChannel(calctime(curtime,100),'K Trap AM',0.8);

        setDigitalChannel(calctime(curtime,100),'Rb Trap TTL',0);    
        setAnalogChannel(calctime(curtime,100),'Rb Trap AM',0.7);

        setDigitalChannel(calctime(curtime,100),'K Repump TTL',0);
        setAnalogChannel(calctime(curtime,100),'K Repump AM',0.45);

        setAnalogChannel(calctime(curtime,100),'Rb Repump AM',0.9);
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

    if seqdata.flags.loadMT  
         % Turn off Rb MOT Trap
        setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0); 
        setDigitalChannel(calctime(curtime,0),'Rb Trap Shutter',0); 

        % Turn off Rb MOT Repump
        setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);     

        % Turn off Rb Probe
        setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1); 
        setDigitalChannel(calctime(curtime,0),'Rb Probe/OP Shutter',0); 

        % Turn of K MOT Trap
        setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
        setDigitalChannel(calctime(curtime,0),'K Trap Shutter',0); 

        % Turn off K MOT Repump
        setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
        setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0); 

        % Turn off K Probe
        setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); % (0 is off for this beam)
        setDigitalChannel(calctime(curtime,0),'K Probe/OP Shutter',0); 

        % Turn on the magtrap
        curtime = Load_MagTrap_from_MOT(curtime);  
        
        % Hold in magnetic trap if desired
        MTholds = [10];
        MThold =getScanParameter(MTholds,seqdata.scancycle,seqdata.randcyclelist,'MThold'); 
        curtime = calctime(curtime,MThold);   
        
%         tramp = 20;    
%         tdel = 500;
%         AnalogFuncTo(calctime(curtime,tdel),'X MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(1),2);    
%         AnalogFuncTo(calctime(curtime,tdel),'Y MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(2),2);    
%         AnalogFuncTo(calctime(curtime,tdel),'Z MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(3),2); 
        
    else
        
%         tramp = 20;    
%         tdel = 500;
%         AnalogFuncTo(calctime(curtime,tdel),'X MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(1),2);    
%         AnalogFuncTo(calctime(curtime,tdel),'Y MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(2),2);    
%         AnalogFuncTo(calctime(curtime,tdel),'Z MOT Shim',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             tramp, tramp, seqdata.params.MOT_shim(3),2); 
    end
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

% Set the shims
setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.00,2); %0.00

%Ramp to MOT values after atoms are gone
tramp = 20;    
tdel = 500;
AnalogFuncTo(calctime(curtime,tdel),'X MOT Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tramp, tramp, seqdata.params.MOT_shim(1),2);    
AnalogFuncTo(calctime(curtime,tdel),'Y MOT Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tramp, tramp, seqdata.params.MOT_shim(2),2);    
AnalogFuncTo(calctime(curtime,tdel),'Z MOT Shim',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    tramp, tramp, seqdata.params.MOT_shim(3),2); 

% levitateGradient=[0:10:50];
% levitateGradient= getScanParameter(levitateGradient,seqdata.scancycle,seqdata.randcyclelist,'levitateGradient');  %in MHZ
% setAnalogChannel(calctime(curtime,0),'MOT Coil',levitateGradient,3); 

% Turn off the D2 beams, if they arent off already
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

%%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%

% Set the time of flight
seqdata.params.tof = getVar('tof');
tof = seqdata.params.tof; 

% Increment the time (ie. perform the time of flight)
curtime = calctime(curtime,tof);

% Turn coil off in case levitation was on
% setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1); 

%%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
%turn back on D2 for imaging (or make it on resonance)  

% Set potassium detunings to resonances (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',getVar('k_mot_img_detuning'));
setAnalogChannel(calctime(curtime,-0.5),'K Repump FM',0,2);

% Set potassium power to standard value
setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

% Set Rubidium detunings to resonance (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

% Rb Trap Detuning    
Rb_Trap_MOT_det_list=[-25];
Rb_Trap_MOT_detuning=getScanParameter(Rb_Trap_MOT_det_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_Trap_MOT_detuning','MHz');
f_osc = calcOffsetLockFreq(Rb_Trap_MOT_detuning,'MOT');
DDS_id = 3;    
DDS_sweep(calctime(curtime,-1),DDS_id,f_osc*1e6,f_osc*1e6,1);   

% Set rubdium power to standard value
setAnalogChannel(calctime(curtime,-0.5),'Rb Trap AM', 0.7);            
setAnalogChannel(calctime(curtime,-0.5),'Rb Repump AM',0.9);          

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
    setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',1); 
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