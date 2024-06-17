function timeout = main_settings(timein)
% main_settings.m

%% Initialzie
if nargin == 0 
    curtime = 0;
else
    curtime = timein;
end

global seqdata;


seqdata.IxonGUIAnalayisHistoryDirectory = 'X:\IxonGUIAnalysisHistory';

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

% MOT Shim values during the MOT (and steady state)
seqdata.params.MOT_shim =  [0.2 2.0 0.9]; % in Amps

% MOT Shim Zero (for any optical molasses that needs B= 0 G; GM/Mol
seqdata.params.MOT_shim_zero =  [0.15 0.15 0.00]; % in Amps


seqdata.constants.hyperfine_ground = 714.327+571.462;

%% Misc Flags
seqdata.flags.misc_calibrate_PA             = 0; % Pulse for PD measurement
seqdata.flags.misc_lock_PA                  = 0; % Update wavemeter lock
seqdata.flags.misc_program4pass             = 1; % Update four-pass frequency
seqdata.flags.misc_programGMDP              = 0; % Update GM DP frequency
seqdata.flags.misc_ramp_fesh_between_cycles = 1; % Demag the chamber
seqdata.flags.misc_moveObjective            = 1; % update ojective piezo position
defVar('objective_piezo',[1.65],'V');[1.96];
% 0.1V = 700 nm, larger means further away from chamber
% 1 V= 7 um
% 10 V = 70 um
% tubeis m30 x .75 (750 um per turn)
% Typically have around 10 planes at most --> 5 um width --> need to
% specify to within 0.1V for a single plane and 1V for the entire cloud
seqdata.flags.Rb_Probe_Order                = 1;   % 1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                                    % 2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT
defVar('PA_detuning',round(-49.539,6),'GHz');
defVar('UV_on_time',10000,'ms');                    % Can be just added onto the adwin wait timer

%% MOT Settings

% WARNING : Because we typically load the MOT at the end of the sequence to
% save time, if you change the MOT settings it is generally advised to
% enable the load at start flag so that the MOT settings are updated at the
% beginning of the sequence and the MOT is given time to load.

seqdata.flags.MOT_load_at_start             = 0; %do a specific load time
defVar('MOT_controlled_load_time',15000,'ms');


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

seqdata.flags.MOT_load_to_MT                = 0; % Makes things worse?

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
defVar('mol_kd1_single_photon_detuning_shift',0,'MHz');
defVar('mol_kd1_trap_power_start',1.3,'V');
defVar('mol_kd1_trap_power_end',1.3,'V');
defVar('mol_kd1_two_photon_detuning',0,'MHz');
defVar('mol_kd1_sideband_power',[8],'dBm');
defVar('mol_kd1_time',8,'ms');

seqdata.params.Mol_shim = [];

seqdata.flags.MOT_programGMDP              = 0; % Update GM DP frequency
defVar('D1_DP_FM',222.5,'MHz');

%% Imaging
seqdata.flags.image_type                    = 0; % 0: absorption, 1 : MOT fluor  
seqdata.flags.image_atomtype                = 1; % 0:Rb,1:K,2:K+Rb (double shutter), applies to fluor and absorption

seqdata.flags.image_loc                     = 1; % 0: `+-+MOT cell, 1: science chamber    
seqdata.flags.image_direction               = 1; % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
seqdata.flags.image_stern_gerlach_F         = 0; % 1: Do a gradient pulse at the beginning of ToF
seqdata.flags.image_stern_gerlach_mF        = 1; % 1: Do a gradient pulse at the beginning of ToF
        
seqdata.flags.image_levitate                = 0; % 2: apply a gradient during ToF to levitate atoms (not yet tested)
seqdata.flags.image_iXon                    = 0; % (unused?) use iXon camera to take an absorption image (only vertical)
seqdata.flags.image_F1_pulse                = 0; % (unused?) repump Rb F=1 before/during imaging (unused?)

%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)
seqdata.flags.image_insitu                  = 0; % Does this flag work for QP/XDT? Or only QP?

% Choose the time-of-flight time for absorption imaging 
defVar('tof',[15],'ms'); %DFG 25ms ; RF1b Rb 15ms ; RF1b K 5ms; BM 15ms ; in-situ 0.25ms

% For double shutter imaging, may delay imaging Rb after K
defVar('tof_krb_diff',[.1],'ms');
%% Transport

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

%% Magnetic Trap

% Main flag for magnetic trap
seqdata.flags.mt                            = 1;

 % compress QP after transport
seqdata.flags.mt_compress_after_transport   = 0;

 % ramp science shims for plugging
seqdata.flags.mt_ramp_to_plugs_shims        = 1;

% Use stage1  = 2 to evaporate fast for transport benchmarking 
%[stage1, decomp/transport, stage1b] 
%Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.
seqdata.flags.RF_evap_stages                = [1, 1, 1];

% Turn on plug beam during RF1B
seqdata.flags.mt_use_plug                   = 1;
defVar('plugTA_current',2500,'mA');2500;

% Resonantly kill atoms after evaporation
seqdata.flags.mt_kill_Rb_after_evap         = 0;    
seqdata.flags.mt_kill_K_after_evap          = 0;     

% Ramp plug power at end of evaporation
seqdata.flags.mt_plug_ramp_end              = 0;

defVar('RF1A_time_scale',[0.6],'arb');1.2;0.6;      % RF1A timescale
defVar('RF1B_time_scale',[1],'arb');[0.8];   % RF1B timescale
defVar('RF1A_finalfreq',[16],'MHz');8;16;         % RF1A Ending Frequency
defVar('RF1B_finalfreq',[4],'MHz');[1];[0.8];        % RF1B Ending Frequency %this is currently not used

%%% MT HOLD %%%    
seqdata.flags.mt_ramp_down_end              = 0;
seqdata.flags.mt_lifetime                   = 0;
defVar('mt_ramp_grad_time',100,'ms');
defVar('mt_ramp_grad_value',[32],'A');
defVar('mt_hold_time',[500]);

%% Optical Dipole Trap
seqdata.flags.xdt                           = 1;    % Master Flag (overrides all other flags)

% XDT Power request zeros
seqdata.params.ODT_zeros = [-0.04,-0.04];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Loading Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_load                      = 1;    % Master Sub Flag
defVar('xdt_load_power',1.0,'W');
defVar('xdt_load_time',75,'ms');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Pre Evaporation Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_pre_evap                  = 1;    % Master Sub Flag

% Subflags
seqdata.flags.xdt_Rb_21uwave_sweep_field    = 1;    % Field Sweep Rb 2-->1
seqdata.flags.xdt_Rb_21uwave_sweep_freq     = 0;    % uWave Frequency sweep Rb 2-->1
seqdata.flags.xdt_Rb_2_kill                 = 1;    % Kill Rb F=2 after uWave transfer

seqdata.flags.xdt_K_p2n_rf_sweep_freq       = 1;    % RF Freq Sweep K +9-->-9  
seqdata.flags.xdt_d1op_start                = 0;    % D1 pump to purify( CF thinks we shoulnd't do this normally)
seqdata.flags.xdt_rfmix_start               = 1;    % RF Mixing -9-->-9+-7    
seqdata.flags.xdt_kill_Rb_before_evap       = 0;    % optically remove Rb (untested)
seqdata.flags.xdt_kill_K7_before_evap       = 0;    % optical remove 7/2 K after (untested)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Evaporation (Rb + K) Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_evap_stage_1               = 1;    % Master Sub Flag

% Sympathetic Power Ramp
seqdata.flags.xdt_ramp2sympathetic           = 1;  
defVar('xdt_evap_sympathetic_power',0.800,'W');     % Sympathetic power
defVar('xdt_evap_sympathetic_ramp_time',500,'ms');  % Sympathetic ramp time

% Optical evaporation
seqdata.flags.CDT_evap                       = 1; 
defVar('xdt_evap1_power',[0.12],'W');
defVar('xdt_evap1_time',25e3,'ms');
defVar('xdt_evap1_tau_fraction',3.5,'arb');

% Power Ramp (useful to halt evaporation)
seqdata.flags.xdt_ramp_power_end             = 1;   
defVar('xdt_evap_end_ramp_power', [.17],'W');  .17;
defVar('xdt_evap_end_ramp_time',  [500],'ms');  
defVar('xdt_evap_end_ramp_hold',  [0],'ms'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Post Evaporation Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

seqdata.flags.xdt_post_evap_stage1           = 0;    % Master Sub Flag

% State Manipulation After Stage 1 optical evaporation
seqdata.flags.xdt_d1op_end                  = 0;    % D1 optical pumping
seqdata.flags.xdt_rfmix_end                 = 0;    % RF Mixing -9-->-9+-7
seqdata.flags.xdt_kill_Rb_after_evap        = 0;    % optically remove Rb
seqdata.flags.xdt_kill_K7_after_evap        = 0;    % optical remove 7/2 K after (untested)
seqdata.flags.xdt_uWave_K_Spectroscopy      = 0;

% Other Stuff
seqdata.flags.xdt_k_rf_rabi_oscillation     = 0;    % RF rabi oscillations after evap
seqdata.flags.xdt_ramp_QP_FB_and_back       = 0;    % Ramp up and down FB and QP to test field gradients
seqdata.flags.xdt_ramp_up_FB_for_lattice    = 0;    %Ramp FB up at the end of evap  
seqdata.flags.xdt_unlevitate_evap           = 0;    % Unclear what this is for
seqdata.flags.xdt_do_dipole_trap_kick       = 0;    % Kick the dipole trap, inducing coherent oscillations for temperature measurement
seqdata.flags.xdt_do_hold_end               = 0;
seqdata.flags.xdt_am_modulate               = 0;    % 1: ODT1, 2:ODT2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Other (CF Unclear) Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT High Field Experiments
seqdata.flags.xdt_evap2stage                = 0;    % Perform K evap at low field
seqdata.flags.xdt_evap2_HF                  = 0;    % Perform K evap at high field (set rep. or attr. in file)
seqdata.flags.xdt_high_field_a              = 0;

%% Optical Dipole Trap B

seqdata.flags.xdtB                          = 1;         % Master Flag

% Levitation
seqdata.flags.xdtB_levitate                 = 1;
defVar('xdtB_levitate_value',[.07],'V');.09;
defVar('xdtB_levitate_ramptime',100,'ms');

% Feshbach
seqdata.flags.xdtB_feshbach                 = 1;
defVar('xdtB_feshbach_field',190,'G');
defVar('xdtB_feshbach_ramptime',500,'ms');

% Feshbach
seqdata.flags.xdtB_feshbach_fine            = 1;
defVar('xdtB_feshbach_fine_field',195,'G');
defVar('xdtB_feshbach_fine_ramptime',100,'ms');

% Hopping the Resonance
seqdata.flags.xdtB_feshbach_hop             = 0;
seqdata.flags.xdtB_rf_mix_feshbach          = 0;

% Evaporation
seqdata.flags.xdtB_evap                     = 1;
defVar('xdtB_evap_power',[0.075:.005:.120],'W');0.077;.085;
defVar('xdtB_evap_time',[5000],'ms');
defVar('xdtB_evap_tau_fraction',3.5','arb')

% Ramp up optical power to halt evaporation
seqdata.flags.xdtB_ramp_power_end           = 1;
defVar('xdtB_evap_end_ramp_power', [0.12],'W');   
defVar('xdtB_evap_end_ramp_time',  [250],'ms');  

% Feshbach
seqdata.flags.xdtB_feshbach_fine2            = 0;
defVar('xdtB_feshbach_fine2_field',201.1,'G');
defVar('xdtB_feshbach_fine2_ramptime',500,'ms');

% Unhop Resonance
seqdata.flags.xdtB_feshbach_unhop           = 0;

% Feshbach
seqdata.flags.xdtB_feshbach_off             = 1;
defVar('xdtB_feshbach_off_field',20,'G');
defVar('xdtB_feshbach_off_ramptime',100,'ms');

% Unlevitate
seqdata.flags.xdtB_levitate_off             = 1;
defVar('xdtB_levitate_off_ramptime',100,'ms');

% piezo kick for vertical trap frequency
seqdata.flags.xdtB_piezo_vert_kick          = 0;
defVar('xdtB_piezo_vert_kick_amplitude',4,'V');         
defVar('xdtB_piezo_vert_kick_rampup_time',100,'ms');
defVar('xdtB_piezo_vert_kick_rampoff_time',4,'ms');
defVar('xdtB_piezo_vert_kick_holdtime', [1],'ms');

% Turn off one of the dipole trap beams to measure its position
seqdata.flags.xdtB_one_beam                 = 0;


%% Waveplate Rotation 1
% This rotation occurs at the end of optical evaporation

% Ideally we want just enough power to load the lattices and for any
% pinning operation, this is ideal for the AOM diffraction efficiency to
% get by PID regulation

seqdata.flags.rotate_waveplate_1   = 1;   
defVar('rotate_waveplate1_duration',5000,'ms'); % How smoothly to rotate
defVar('rotate_waveplate1_delay',-5500,'ms');   % How long before lattice loading 
defVar('rotate_waveplate1_value',0.1,'normalized power');.06; % Amount of power going to lattices

%% Load the Optical Lattice

% These are the lattice flags sorted roughly chronologically. 
seqdata.flags.lattice_load            = 0;    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading optical lattical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the lattices
defVar('lattice_load_time',[750],'ms');500;
defVar('lattice_load_depthX',[2.5],'Er');2.5;
defVar('lattice_load_depthY',[2.5],'Er');2.5;
defVar('lattice_load_depthZ',[2.5],'Er');2.5;

% Ramp dimple during lattice loading (not implemented yet)
seqdata.flags.lattice_load_dimple         = 0;

% Turn off XDTs after ramping loading lattice
seqdata.flags.lattice_load_xdt_off        = 0;      
defVar('lattice_load_xdt_off_time',[500],'ms');           

% Hold time after loading lattice
defVar('lattice_load_holdtime',[250],'ms');
% defVar('lattice_load_holdtime',1000-getVar('lattice_load_time'),'ms');         

% Adjust feshbach field after loading
seqdata.flags.lattice_load_feshbach_ramp  = 0;
defVar('lattice_load_feshbach_time',300,'ms'); %ramp time
defVar('lattice_load_feshbach_field',200.8,'G');
defVar('lattice_load_feshbach_holdtime',[0],'ms'); % Hold time after ramping feshbach

% Ramp the lattices to science depth after loading 
seqdata.flags.lattice_sci_ramp        = 0;

defVar('lattice_sci_time',[500],'ms');500;
defVar('lattice_sci_depthX',[2.5],'Er');2.5;
defVar('lattice_sci_depthY',[2.5],'Er');2.5;
defVar('lattice_sci_depthZ',[2.5],'Er');2.5;

% If you want to do a round trip
seqdata.flags.lattice_load_round_trip   = 0;       
defVar('lattice_ramp_1_round_trip_equilibriation_time',[2000],'ms');  

%% Conductivity Experiment
seqdata.flags.lattice_conductivity_new      = 0;   % New sequence created July 25th, 2023
seqdata.flags.lattice_conductivity          = 0;    % old sequence

% Conductivity Flags
seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction

defVar('conductivity_snap_and_hold_time',[0],'ms');
defVar('conductivity_FB_field',201.1,'G')
defVar('conductivity_zshim',0,'A')
defVar('conductivity_mod_freq',[55],'Hz')       % Modulation Frequency
defVar('conductivity_mod_time',[50],'ms');      % Modulation Time
defVar('conductivity_mod_ramp_time',150,'ms');  % Ramp Time

%Additional heating using FB ramp for Temp matching
defVar('FB_heating_field', 201, 'G');
defVar('FB_heating_holdtime',[750],'ms');
    
% Modulation amplitude not to exceed +-4V.
if seqdata.flags.conductivity_mod_direction == 1
    %For x-direction modulation only adjust ODT2 amp
    defVar('conductivity_ODT1_mod_amp',0,'V');  % ODT1 Mod Depth   
    defVar('conductivity_ODT2_mod_amp',4,'V');  % ODT2 Mod Depth
    defVar('conductivity_rel_mod_phase',0,'deg');   % Phase shift of sinusoidal mod - should be 0 for mod along x
elseif seqdata.flags.conductivity_mod_direction == 2
    %For y-direction modulation only adjust ODT1 amp
    defVar('conductivity_ODT1_mod_amp',4,'V');  % ODT1 Mod Depth  
    defVar('conductivity_ODT2_mod_amp',0,'V');  % ODT2 Mod Depth
    defVar('conductivity_rel_mod_phase',180,'deg');   % Phase shift of sinusoidal mod - should be 180 for mod along y
end    

%% Optical Lattice
seqdata.flags.lattice                       = 1; 
if ~seqdata.flags.lattice_load;seqdata.flags.lattice  =0;end

% Pin 
seqdata.flags.lattice_pin                   = 1;
defVar('lattice_pin_depth',[70],'Er');60;
defVar('lattice_pin_time', [.2], 'ms');0.2;

% Turn off feshbach/levitation after pinning
seqdata.flags.lattice_feshbach_off          = 1;
defVar('lattice_feshbach_off_field',20,'G');
defVar('lattice_feshbach_off_ramptime',100,'ms');
seqdata.flags.lattice_levitate_off          = 1;
defVar('lattice_levitate_off_ramptime',100,'ms');

% Pulse dimple beam after pinning
seqdata.flags.lattice_pulse_dimple          = 0;

% Optical pumping after pinning/unlevitate
seqdata.flags.lattice_do_optical_pumping    = 2; 
%0==off, 1==old code, 2==new CF code (May 2024)  

% Ramp lattices for fluoresence
seqdata.flags.lattice_rotate_waveplate_2    = 1;    % Second waveplate rotation 95% 
seqdata.flags.lattice_fluor_ramp            = 1;    % Secondary lattice ramp for fluorescence imaging

% AM Spec
seqdata.flags.do_lattice_am_spec            = 0;    % Amplitude modulation spectroscopy    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
seqdata.flags.lattice_PA                    = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RF/uWave Spectroscopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.lattice_uWave_spec            = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection, Raman Transfers, and Fluorescence Imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Actual fluorsence image flags - NO LONGER USED
seqdata.flags.Raman_transfers               = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
seqdata.flags.do_plane_selection            = 0;    % Plane selection flag
seqdata.flags.plane_selection.useFeedback   = 1;
seqdata.flags.plane_selection.dotilt        = 0;

% pselect_ramp_fields;
% pselect_dotilt;
% pselect_dokill;
% pselect_douwave;


% Default Plane Selection No Tilt Settings
freq_offset_notilt_list = [540];470;
freq_offset_amplitude_notilt_list = 15;40; [15];
defVar('qgm_plane_uwave_frequency_offset_notilt',freq_offset_notilt_list,'kHz');
defVar('qgm_plane_uwave_frequency_amplitude_notilt',freq_offset_amplitude_notilt_list,'kHz');

% Default Plane Selection Tilt Settings
freq_offset_tilt_list =[310]; 510;
freq_offset_amplitude_tilt_list = 8; 
defVar('qgm_plane_uwave_frequency_offset_tilt',freq_offset_tilt_list,'kHz');
defVar('qgm_plane_uwave_frequency_amplitude_tilt',freq_offset_amplitude_tilt_list,'kHz');

% Feedback offset defaults to 0
d = load('f_offset.mat');
f_offset = d.f_offset;        
defVar('f_offset',f_offset,'kHz');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fluorescence Selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Note:
% It is sometimes helpful to run the fluorence imaging code as other things
% such as :
% - alignment of EIT/FPUMP beams
% - Raman spectroscopy (to show Raman is working)
% - uWave spectroscopy (to find two photon frequency/field)

% New Standard Fluoresnce Image Flags
seqdata.flags.lattice_ClearCCD_IxonTrigger  = 0;    % Add additional trigger to clear CCD (obsolete)
seqdata.flags.lattice_fluor                 = 1;    % Do Fluoresnce imaging
seqdata.flags.lattice_fluor_bkgd            = 1;    % Take a background image with imaging light on, no atoms

seqdata.flags.lattice_img_stripe            = 0;    % (osolete) Plane select with tilt and take an additional imag of the stripe
seqdata.IxonMultiExposures=[];
seqdata.IxonMultiPiezos=[];

defVar('qgm_filter_1',20,'step');40;
getVar('qgm_filter_1');

defVar('qgm_filter_2',-160,'step');
getVar('qgm_filter_2');

defVar('qgm_filter_3',60,'step');
getVar('qgm_filter_3');

defVar('qgm_filter_4',-20,'step');
getVar('qgm_filter_4');
%% Optical Lattice : OLD HIGH FIELD EXPERIMENT
seqdata.flags.lattice_HF_old                   = 0;
 if ~seqdata.flags.lattice_load;seqdata.flags.lattice_HF_old  =0;end

%% Optical Lattice Turn off Procedure
seqdata.flags.lattice_off                       = 1;    % Master Flag
% Turning off lattice only matters if the lattice was on to begin with!
if ~seqdata.flags.lattice_load;seqdata.flags.lattice_off  =0;end

% Turn off feshbach field
seqdata.flags.lattice_off_feshbach_off          = 0;
defVar('lattice_off_feshbach_off_field',20,'G');
defVar('lattice_off_feshbach_off_ramptime',100,'ms');
% Unlevitate
seqdata.flags.lattice_off_levitate_off          = 0;
defVar('lattice_off_levitate_off_ramptime',100,'ms');

% If feshbach was never turned on, no need to turn it off
if ~seqdata.flags.xdtB_feshbach
    seqdata.flags.lattice_off_feshbach_off          = 0;
    seqdata.flags.lattice_off_levitate_off          = 0;
end

% BandMapping
seqdata.flags.lattice_off_bandmap                           = 1;

if seqdata.flags.lattice_fluor_ramp
    defVar('lattice_bm_time',[5],'ms');
else
    defVar('lattice_bm_time',[.5],'ms');
end

seqdata.flags.lattice_off_bandmap_xdt_off_simultaneous     = 0;         % Turn off XDT at same time as lattice?
if seqdata.flags.lattice_off_bandmap_xdt_off_simultaneous
    defVar('lattice_bm_xdt_ramptime',getVar('lattice_bm_time'),'ms');   % Simultaneous means same bm_time
else
    defVar('lattice_bm_xdt_ramptime',5,'ms');                           % Ramp time is asynchronous with lattice
    defVar('lattice_bm_xdt_waittime',[10],'ms');                        % Wait time before lattice off
end

%% Lattice Course Alignment
% If you have completely lost lattice alignment, use these flags to pulse
% the lattices.  Good luck.
%
% CF : I have no idea how this code works

% 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
seqdata.flags.lattice_pulse_for_alignment   = 0; 

% 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)
seqdata.flags.lattice_pulse_z_for_alignment = 0; 


%% QGM Imaging


%% Scope Trigger
% Choose which scope trigger to use.

% seqdata.scope_trigger = 'rf_spectroscopy';
% seqdata.scope_trigger = 'Lattice_Mod';
% seqdata.scope_trigger = 'FB_ramp';
seqdata.scope_trigger = 'lattice_ramp_1';
% seqdata.scope_trigger = 'lattice_sci_ramp';
% seqdata.scope_trigger = 'pulse lattice';
% seqdata.scope_trigger = 'Raman Beams On';
% seqdata.scope_trigger = 'PA_Pulse';
% seqdata.scope_trigger = 'lattice_ramp_2';
% seqdata.scope_trigger = 'lattice_off';
% seqdata.scope_trigger = 'Camera triggers';
% seqdata.scope_trigger = 'Start Transport';
% seqdata.scope_trigger = 'TOF';
% seqdata.scope_trigger = 'Optical pumping';
% seqdata.scope_trigger = 'MOT Trigger';
% seqdata.scope_trigger = 'CMOT';
% seqdata.scope_trigger = 'Molasses';
% seqdata.scope_trigger = 'Plane selection';
% seqdata.scope_trigger = 'fluorescence';

% seqdata.scope_trigger = '40k 97 mixing';
% seqdata.scope_trigger = 'Rampup ODT';
%% end time

timeout = curtime;

end

