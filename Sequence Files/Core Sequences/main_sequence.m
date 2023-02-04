function timeout = main_sequence(timein)
% main_sequence.m

if nargin == 0 
    curtime = timein;
end

global seqdata;

% Number of DDS scans is zero
seqdata.numDDSsweeps = 0;

% CF : Is this really useful? Also we have more than A and B SRS
seqdata.flags.SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB
% This can be removed since we don't really do good checkcs.
%% Constants and Parameters

% Shim Zero (to eliminate all bkgd fields)
seqdata.params.shim_zero = [0.1425, -0.0652, -0.1015];

% Plug Zero (to move MT underneath sapphire window)
seqdata.params.plug_shims = seqdata.params.shim_zero + ...
    [-1.3400 +0.125 +0.35];

% Slope relation between shim and QP currents to keep field center fixed.
% Important for ramping QP at end of RF1B and during QP ramp down in ODT
Cx = -0.0507;
Cy = 0.0045;
Cz = 0.0115;

seqdata.params.plug_shims_slopes = [Cx Cy Cz];

% CF : Is this ever actually used?
%Current shim values (x,y,z)- reset to zero
seqdata.params.shim_val = [0 0 0]; 

%% Flags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MISC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seqdata.flags.misc_calibrate_PA             = 0; % Pulse for PD measurement
seqdata.flags.misc_lock_PA                  = 0; % Update wavemeter lock
seqdata.flags.misc_program4pass             = 0; % Update four-pass frequency
seqdata.flags.misc_programGMDP              = 0; % Update GM DP frequency
seqdata.flags.misc_ramp_fesh_between_cycles = 1; % Demag the chamber

seqdata.flags.Rb_Probe_Order                = 1;   % 1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                                    % 2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT
defVar('PA_detuning',round(-49.539,6),'GHz');
defVar('UV_on_time',10000,'ms');                    % Can be just added onto the adwin wait timer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOT  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WARNING : Because we typically load the MOT at the end of the sequence to
% save time, if you change the MOT settings it is generally advised to
% enable the load at start flag so that the MOT settings are updated at the
% beginning of the sequence and the MOT is given time to load.

seqdata.flags.MOT_load_at_start             = 0; %do a specific load time
defVar('MOT_controlled_load_time',20000,'ms');

seqdata.params.MOT_shim = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOT to MT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.MOT_prepare_for_MT            = 1;

seqdata.flags.MOT_CMOT                      = 1; % Do the CMOT
seqdata.flags.MOT_CMOT_detuning_ramp        = 2; % 0:no change, 1:linear ramp, 2:diabatic
seqdata.flags.MOT_CMOT_power_ramp           = 2; % 0:no change, 1:linear ramp, 2:diabatic
seqdata.flags.MOT_CMOT_grad_ramp            = 0; % 0:no change, 1:linear ramp, 2:diabatic

seqdata.flags.MOT_Mol                       = 1; % Do the molasses
seqdata.flags.MOT_Mol_KGM_power_ramp        = 0; % 0: no ramp, 1:linear ramp

seqdata.flags.MOT_optical_pumping           = 1; % optical pumping for MT

seqdata.flags.MOT_load_to_MT                = 0;

% K CMOT parameters
defVar('cmot_k_trap_detuning',5,'MHz');5;
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
defVar('mol_rb_trap_detuning',-81,'MHz');
defVar('mol_rb_trap_power',0.15,'V');
defVar('mol_rb_repump_power',0.08,'V');
defVar('mol_rb_time',8,'ms');

% K D1 Gray Molasses
defVar('mol_kd1_single_photon_detuning_shift',0,'MHz');
defVar('mol_kd1_trap_power_start',1.3,'V');
defVar('mol_kd1_trap_power_end',1.3,'V');
defVar('mol_kd1_two_photon_detuning',0,'MHz');
defVar('mol_kd1_sideband_power',4,'dBm');
defVar('mol_kd1_time',8,'ms');

seqdata.params.Mol_shim = [];

seqdata.flags.MOT_programGMDP              = 0; % Update GM DP frequency
defVar('D1_DP_FM',222.5,'MHz');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seqdata.flags.image_type                    = 0; % 0: absorption, 1 : MOT fluor  
seqdata.flags.image_atomtype                = 1; % 0:Rb,1:K,2:K+Rb (double shutter), applies to fluor and absorption

seqdata.flags.image_loc                     = 1; % 0: `+-+MOT cell, 1: science chamber    
seqdata.flags.image_direction               = 0; % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
seqdata.flags.image_stern_gerlach           = 0; % 1: Do a gradient pulse at the beginning of ToF
seqdata.flags.image_iXon                    = 0; % (unused?) use iXon camera to take an absorption image (only vertical)
seqdata.flags.image_F1_pulse                = 0; % (unused?) repump Rb F=1 before/during imaging (unused?)

seqdata.flags.High_Field_Imaging            = 0; % High field imaging (shouldn't this be automatic?)

%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)
seqdata.flags.image_insitu = 0; % Does this flag work for QP/XDT? Or only QP?

% Choose the time-of-flight time for absorption imaging 
defVar('tof',[25],'ms'); %DFG 25ms ; RF1b Rb 15ms ; RF1b K 5ms; BM 15ms
seqdata.params.tof = getVar('tof');

% For double shutter imaging, may delay imaging Rb after K
defVar('tof_krb_diff',[0],'ms');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Transport %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For debugging: enable only certain coils during the transport
% sequence (and only during the transport sequence!)
% seqdata.coil_enable = ones(1,23); % can comment these lines for normal operation
% seqdata.coil_enable(8) = 0; %coil 7
% List of channels as they are ordered in transport_coil_currents*.m:
% 1:a18, 2:a7, 3:a8 4:a9, 5:a10, 6:a11, 7:a12, 8:a13, 9:a14, 10:a15,
% 11:a16, 12:a17, 13:a9, 14:a22, 15:a23, 16:a24, 17:a20, 18:a21, 19:a6,
% 20:a3, 21:a17, 22:d22, 23:d28
% use this order with the boolean enable array!

% Enable magnetic transport
seqdata.flags.transport                     = 1;

%0: min jerk curves, 1: slow down in middle section curves, 2: none
seqdata.flags.transport_hor_type            = 1;

% 0: min jerk, 1: slow in middle 2:none, 3:linear, 4: triple min jerk
seqdata.flags.transport_ver_type            = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Magnetic Trap %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Main flag for magnetic trap
seqdata.flags.mt                            = 1;

 % compress QP after transport
seqdata.flags.mt_compress_after_transport   = 1;

 % ramp science shims for plugging
seqdata.flags.mt_ramp_to_plugs_shims        = 1;

% Use stage1  = 2 to evaporate fast for transport benchmarking 
%[stage1, decomp/transport, stage1b] 
%Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.
seqdata.flags.RF_evap_stages                = [1, 1, 1];

% Turn on plug beam during RF1B
seqdata.flags.mt_use_plug                   = 1;

% Resonantly kill atoms after evaporation
seqdata.flags.mt_kill_Rb_after_evap         = 0;    
seqdata.flags.mt_kill_K_after_evap          = 0;     

% Ramp plug power at end of evaporation
seqdata.flags.mt_plug_ramp_end              = 0;

defVar('RF1A_time_scale',[0.6],'arb');      % RF1A timescale
defVar('RF1B_time_scale',[0.8],'arb');      % RF1B timescale
defVar('RF1A_finalfreq',[16],'MHz');        % RF1A Ending Frequency
defVar('RF1B_finalfreq',[.8],'MHz');        % RF1B Ending Frequency

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DIPOLE TRAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.params.ODT_zeros = [-0.04,-0.04];

% Dipole trap
% 1: dipole trap loading, 2: dipole trap pulse, 3: pulse on dipole trap during evaporation
seqdata.flags.xdt                           = 1;

% Dipole trap flags will be ignored if XDT is off

% MT to XDT State Transfer
seqdata.flags.xdt_Rb_21uwave_sweep_field    = 1;    % Field Sweep Rb 2-->1
seqdata.flags.xdt_Rb_21uwave_sweep_freq     = 0;    % uWave Frequency sweep Rb 2-->1
seqdata.flags.xdt_K_p2n_rf_sweep_freq       = 1;    % RF Freq Sweep K +9-->-9  

% State Manipulation Before Optical Evaporation 
seqdata.flags.xdt_d1op_start                = 1;    % D1 pump to purify
seqdata.flags.xdt_rfmix_start               = 1;    % RF Mixing -9-->-9+-7    
seqdata.flags.xdt_kill_Rb_before_evap       = 0;    % optically remove Rb
seqdata.flags.xdt_kill_K7_before_evap       = 0;    % optical remove 7/2 K after (untested)

% Optical Evaporation
% 1: exp 2: fast linear 3: piecewise linear
seqdata.flags.CDT_evap                      = 1;       

% State Manipulatoin After Optical Evaporation
seqdata.flags.xdt_d1op_end                  = 0;    % D1 optical pumping
seqdata.flags.xdt_rfmix_end                 = 0;    % RF Mixing -9-->-9+-7
seqdata.flags.xdt_kill_Rb_after_evap        = 0;    % optically remove Rb
seqdata.flags.xdt_kill_K7_after_evap        = 0;    % optical remove 7/2 K after (untested)

% XDT High Field Experiments
seqdata.flags.xdt_high_field_a              = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OPTICAL LATTICE %%%%%%%%%s%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
seqdata.flags.lattice                       = 0; 


seqdata.flags.lattice_reset_waveplate       = 1; % Reset lattice waveplate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LATTICE COURES ALIGNMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If you have completely lost lattice alignment, use these flags to pulse
% the lattices.  Good luck.

% 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
seqdata.flags.lattice_pulse_for_alignment   = 0; 

% 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)
seqdata.flags.lattice_pulse_z_for_alignment = 0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OTHER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (seqdata.flags.xdt ~= 0 || seqdata.flags.lattice ~= 0)
    seqdata.flags.QP_imaging = 0;
else
    seqdata.flags.QP_imaging = 1;
end


%% Set switches for predefined scenarios

% Ignore other experimental parts if doing fluoresence imaging. It is
% possilble to "there and back" imaging with transport, but this is very
% rare and can be handled manuualy
if seqdata.flags.image_type == 1
    seqdata.flags.transport                     = 0;
    seqdata.flags.mt                            = 0;
    seqdata.flags.xdt                           = 0;
    seqdata.flags.lattice                       = 0;    
end

% Do not run the demag if you don't make a magnetic trap
if ~seqdata.flags.mt
   seqdata.flags.misc_ramp_fesh_between_cycles = 0;
end

% Do not reset the lattice waveplate if you didn't use it
if ~seqdata.flags.lattice
   seqdata.flags.lattice_reset_waveplate     = 0;
end

% Ignore other experimental parts if doing fluoresence imaging.
if seqdata.flags.image_loc == 0 
    seqdata.flags.mt_use_plug = 0;
    seqdata.flags.mt_compress_after_transport = 0;
    seqdata.flags.RF_evap_stages = [0 0 0];
    seqdata.flags.xdt = 0;
    seqdata.flags.lattice = 0;  
    seqdata.flags.lattice_pulse_for_alignment = 0;
end

%% Scope Trigger
% Choose which scope trigger to use.

% scope_trigger = 'rf_spectroscopy';
scope_trigger = 'Lattice_Mod';
% scope_trigger = 'FB_ramp';
% scope_trigger = 'lattice_ramp_1';
% scope_trigger = 'lattice_off';
% scope_trigger = 'Raman Beams On';
% scope_trigger = 'PA_Pulse';


%% PA Laser Lock Detuning

if seqdata.flags.misc_lock_PA    
    updatePALock(curtime);    
end

%% Set Objective Piezo VoltageS
% If the cloud moves up, the voltage must increase to refocus
%  (as the experiment warms up, selected plane tends to move up a bit)

obj_piezo_V_List = [3];[5];[4.6];
% 0.1V = 700 nm, must be larger than  larger value means farther away from the window.
%     obj_piezo_V = getScanParameter(obj_piezo_V_List, ...
%     seqdata.scancycle, 1, 'Objective_Piezo_Z','V');%5

obj_piezo_V = getScanParameter(obj_piezo_V_List, ...
seqdata.scancycle, 1:length(obj_piezo_V_List), 'Objective_Piezo_Z','V');%5

% obj_piezo_V = 6.8;
setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);
addOutputParam('objpzt',obj_piezo_V,'V');
    
%% Four-Pass

% Set 4-Pass Frequency
detuning_list = [5];
df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
DDSFreq = 324.206*1e6 + df*1e3/4;
addOutputParam('FourPassFrequency',DDSFreq*1e-6,'MHz');

if seqdata.flags.misc_program4pass
    DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
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
setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X,1);
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
setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);

%Set TTL to keep F-pump and mF-pump warm.
setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
setAnalogChannel(calctime(curtime,0),'F Pump',9.99);

%Plug beam
setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
setAnalogChannel(calctime(curtime,0),'Plug',2500); % Current in mA

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
end

%% Transport 
% Use the CATS to mangetically transport the atoms from the MOT cell to the
% science chamber.

if seqdata.flags.transport
    dispLineStr('Magnetic Transport',curtime);

    % Open kitten relay
    curtime = setDigitalChannel(curtime,'Kitten Relay',1);
    
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
    %Turn Shims to Science cell zero values
    setAnalogChannel(calctime(curtime,1000),'X Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Z Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Y Shim',0,4); %4

    % Scope trigger
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
    
    tic;
curtime = Transport_Cloud(curtime, seqdata.flags.transport_hor_type,...
        seqdata.flags.transport_ver_type, seqdata.flags.image_loc);
    t2=toc;
    disp(['Transport cloud calculation took ' num2str(t2) ' seconds']);
    
end

%% Floursence image in MOT Cell
% Perform fluoresence imaging. Comes after transport in case you want to do
% a there and back measurement.

% if seqdata.flags.image_type == 1
%    curtime = MOT_fluorescence_image(curtime);
% end

%% Magnetic Trap

if seqdata.flags.mt
    [curtime, I_QP, I_kitt, V_QP, I_fesh, I_shim] = magnetic_trap(curtime);
end

%% Dipole Trap

if ( seqdata.flags.xdt == 1 )
    dispLineStr('Caling dipole_transfer.m',curtime);   
    [curtime, I_QP, V_QP, P_dip, I_shim] = ...
        dipole_transfer(curtime, I_QP, V_QP, I_shim);
end

%% Pulse lattice after releasing from trap

if (seqdata.flags.lattice_pulse_for_alignment ~= 0)
    curtime = Pulse_Lattice(curtime,...
        seqdata.flags.lattice_pulse_for_alignment);
end

%% Optical Lattice

if ( seqdata.flags.lattice ~= 0 )
    curtime = Load_Lattice(curtime);
end

%% Pulse Z Lattice after ramping up other lattices to align

if (seqdata.flags.lattice_pulse_z_for_alignment == 1 )
    curtime = Pulse_Lattice(curtime,4);
end

%% Initiate Time of Flight in absorption image

if seqdata.flags.image_type == 0
    dispLineStr('Turning off coils and traps.',curtime);   
    
    % Turn off the MOT (shouldnt it already be off?)
    setAnalogChannel(curtime,'MOT Coil',0,1);
    
    % Turn off all transport Coils (shouldnt it already be off?)
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end   
    
    if ~seqdata.flags.High_Field_Imaging    
        % Turn off QP Coils (analog control)    
        setAnalogChannel(calctime(curtime,0),'Coil 15',0,1);            % C15
        curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1);  % C16
        curtime = setAnalogChannel(curtime,'kitten',0,1);               % Kitten    

        % MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
        qp_switch1_delay_time = 0;
        if I_kitt == 0
            %use fast switch
            setDigitalChannel(curtime,'Coil 16 TTL',1); % Turn off Coil 16
            setDigitalChannel(calctime(curtime,500),'Coil 16 TTL',0); % Turn on Coil 16
        else
            %Cannot use Coil 16 fast switch if atoms have not be transferred to
            %imaging direction!
        end
        % Turn off 15/16 switch (10 ms later)
        setDigitalChannel(calctime(curtime,qp_switch1_delay_time),'15/16 Switch',0);
    end
    
    % XDT TOF (CF : What about if the lattice is on?)
    if seqdata.flags.xdt        
        % Read XDT Powers right before tof
        P1 = getChannelValue(seqdata,'dipoleTrap1',1);
        P2 = getChannelValue(seqdata,'dipoleTrap2',1);

        addOutputParam('xdt1_final_power',P1,'W');
        addOutputParam('xdt2_final_power',P2,'W');

        % Turn off AOMs 
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);

        % XDT1 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',...
            seqdata.params.ODT_zeros(1));
        % XDT2 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
        % I think this channel is unused now
        setDigitalChannel(calctime(curtime,-1),'XDT Direct Control',1);
    end          

    if ( seqdata.flags.lattice ~= 0 )
        % Make sure lattices are off (whhat about the TTL?)
        % Load lattice handles band mapping
        setAnalogChannel(calctime(curtime,0),'zLattice',-10,1); % Z lattice
        setAnalogChannel(calctime(curtime,0),'yLattice',-10,1); % Y lattice
        setAnalogChannel(calctime(curtime,0),'xLattice',-10,1); % X lattice
    end    
end

%% Absorption Imaging

if seqdata.flags.image_type == 0
    dispLineStr('Absorption Imaging.',curtime);
    curtime = absorption_image2(calctime(curtime,0.0));         
end    

%% Post-sequence: rotate diople trap waveplate to default value
if (seqdata.flags.lattice_reset_waveplate == 1)
    %Rotate waveplate to divert all power to dipole traps.
    P_RotWave = 0;
    AnalogFunc(calctime(curtime,0),'latticeWaveplate',...
        @(t,tt,Pmin,Pmax) ...
        (0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
        200,200,P_RotWave,0); 
end

%% Demag pulse
if seqdata.flags.misc_ramp_fesh_between_cycles
    if seqdata.flags.High_Field_Imaging
    % This is meant to leave material near the atoms with the same
    % magnetization at the beginning of a new cycle, irrespective whether
    % some strong field was pulsed/snapped off or not during the cycle that
    % just ends. We do not have any positive observation that this helps,
    % but we leave it in just in case (total 1.3s extra).
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
    else 
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
    end
end
    
%% Reset Channels
% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

% Set/Reset Pulses for Remote Field Sensor (after the sensor in the bucket)
curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);

% Reset analog and digital channels (shouldn't this always happen?)
curtime = Reset_Channels(calctime(curtime,0));

%turn on the Raman shutter for frquuency monitoring
setDigitalChannel(calctime(curtime,0),'Raman Shutter',1);

% Set the shim values to zero
setAnalogChannel(calctime(curtime,0),'X Shim',0,1);
setAnalogChannel(calctime(curtime,0),'Y Shim',0,1);
setAnalogChannel(calctime(curtime,0),'Z Shim',0,1);   

%% Load MOT
% Load the MOT
dispLineStr('Load the MOT',curtime);
loadMOTSimple(curtime,0);

% Wait some additional time
if ~seqdata.flags.MOT_load_at_start
    curtime = calctime(curtime,getVar('UV_on_time'));
end

%% Transport Reset

% Reset transport relay (Coil 3 vs Coil 11)
curtime = setDigitalChannel(calctime(curtime,10),'Transport Relay',0);

%% Post-sequence: Pulse the PA laser again for labjack power measurement
if seqdata.flags.misc_calibrate_PA == 1    
   curtime = PA_pulse(curtime,2);     
end
    
%% Scope trigger selection
SelectScopeTrigger(scope_trigger);

%% Timeout
timeout = curtime;

% Check if sequence is on for too long
if (((timeout - timein)*(seqdata.deltat/seqdata.timeunit))>100000)
    error('Cycle time greater than 100s! Is this correct?')
end

%% Order Flags and Fields
% For visual purposes.  This sorts the flags by flag_groups while keeping
% the original ordering as defined in the sequence.

flag_groups = {'misc','image','MOT','transport','mt','xdt','lattice'};
flag_names = fieldnames(seqdata.flags);
for kk = 1:length(flag_groups)
    inds = startsWith(flag_names,flag_groups{kk});
    [~,inds] = sort(inds,'ascend');
    flag_names = flag_names(inds);
end
seqdata.flags = orderfields(seqdata.flags,flag_names);

dispLineStr('Sequence Complete.',curtime);
end