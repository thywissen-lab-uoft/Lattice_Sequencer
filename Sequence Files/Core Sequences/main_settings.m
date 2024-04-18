function timeout = main_settings(timein)
% main_settings.m

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
defVar('objective_piezo',[1.96],'V');
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
seqdata.flags.image_stern_gerlach_mF        = 0; % 1: Do a gradient pulse at the beginning of ToF
        
seqdata.flags.image_levitate                = 0; % 2: apply a gradient during ToF to levitate atoms (not yet tested)
seqdata.flags.image_iXon                    = 0; % (unused?) use iXon camera to take an absorption image (only vertical)
seqdata.flags.image_F1_pulse                = 0; % (unused?) repump Rb F=1 before/during imaging (unused?)

seqdata.flags.High_Field_Imaging            = 0; % High field imaging (shouldn't this be automatic?)

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
defVar('mt_ramp_grad_value',[16:4:32],'A');
defVar('mt_hold_time',[0:500:10000]);

%% Optical Dipole Trap
seqdata.params.ODT_zeros = [-0.04,-0.04];

% Master XDT flag.  This will override all other XDT flags
seqdata.flags.xdt                           = 1;

% Main XDT flags.  These control the individual stages (not used yet)
seqdata.flags.xdt_load                      = 1;
seqdata.flags.xdt_pre_evap                  = 1;
seqdata.flags.xdt_evap                      = 1;
seqdata.flags.xdt_post_evap                 = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Loading Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defVar('xdt_load_power',1.0,'W');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Pre Evaporation Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_Rb_21uwave_sweep_field    = 1;    % Field Sweep Rb 2-->1
seqdata.flags.xdt_Rb_21uwave_sweep_freq     = 0;    % uWave Frequency sweep Rb 2-->1
seqdata.flags.xdt_K_p2n_rf_sweep_freq       = 1;    % RF Freq Sweep K +9-->-9  

% State Manipulation Before Optical Evaporation 
seqdata.flags.xdt_d1op_start                = 1;    % D1 pump to purify
seqdata.flags.xdt_rfmix_start               = 1;    % RF Mixing -9-->-9+-7    
seqdata.flags.xdt_kill_Rb_before_evap       = 0;    % optically remove Rb
seqdata.flags.xdt_kill_K7_before_evap       = 0;    % optical remove 7/2 K after (untested)

defVar('xdt_sympathetic_power',0.800,'W');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Evaporation Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Optical Evaporation
% 1: exp 2: fast linear 3: piecewise linear
seqdata.flags.CDT_evap                      = 1;       
% Stage 1 Evaporation (K+Rb)
defVar('xdt_evap1_power',[0.065],'W');0.078;0.085;0.08;0.078;
defVar('xdt_evap1_time',25e3,'ms');
defVar('xdt_evap1_tau_fraction',3.5,'arb');

% Stage 2 Evaporation (K+K)
defVar('xdt_evap2_power',0.110,'W');
defVar('xdt_evap2_time',10e3,'ms');
defVar('xdt_evap2_tau_fraction',3.5','arb')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Post Evaporation XDT Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% State Manipulation After Stage 1 optical evaporation
seqdata.flags.xdt_d1op_end                  = 0;    % D1 optical pumping
seqdata.flags.xdt_rfmix_end                 = 0;    % RF Mixing -9-->-9+-7
seqdata.flags.xdt_kill_Rb_after_evap        = 0;    % optically remove Rb
seqdata.flags.xdt_kill_K7_after_evap        = 0;    % optical remove 7/2 K after (untested)

% Ramp up of optical power at the end of optical evaporation
seqdata.flags.xdt_ramp_power_end            = 1;    % Ramp dipole back up after evaporation before any further physics 
defVar('xdt_evap_end_ramp_power', 0.120,'W');   % end optical power ramp
defVar('xdt_evap_end_ramp_time',  [250],'ms');    % time to perform ramp
defVar('xdt_evap_end_ramp_hold',  [250],'ms'); % time to wait after ramping


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT Other (CF Unclear) Flags and Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XDT High Field Experiments
seqdata.flags.xdt_evap2stage                = 0;    % Perform K evap at low field
seqdata.flags.xdt_evap2_HF                  = 0;    % Perform K evap at high field (set rep. or attr. in file)
seqdata.flags.xdt_high_field_a              = 0;

%% Waveplate Rotation 1

seqdata.flags.rotate_waveplate_1   = 1;   

% Reset XDT/XYLattice waveplate at end of sequence
% seqdata.flags.waveplate_reset       = 1; commented out since WE ALWAYS
% SHOULD RESET?

% This rotation occurs at the end of optical evaporation

% Ideally we want just enough power to load the lattices and for any
% pinning operation, this is ideal for the AOM diffraction efficiency to
% get by PID regulation


defVar('rotate_waveplate1_duration',600,'ms'); % How smoothly to rotate
defVar('rotate_waveplate1_delay',-700,'ms');   % How long before lattice loading 
defVar('rotate_waveplate1_value',0.05,'normalized power'); % Amount of power going to lattices


%% Optical Lattice Loading

% These are the lattice flags sorted roughly chronologically. 
seqdata.flags.lattice_load_1            = 1;    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading optical lattical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the lattices
defVar('lattice_load_time',300,'ms');
defVar('lattice_load_depthX',2.5,'Er');
defVar('lattice_load_depthY',2.5,'Er');
defVar('lattice_load_depthZ',2.5,'Er');

% Turn off XDTs after ramping loading lattice
seqdata.flags.lattice_load_xdt_off        = 0;      
defVar('lattice_load_xdt_off_time',[500],'ms');           

% Hold time after loading lattice
defVar('lattice_ramp_1_holdtime',[0],'ms');

% If you want to do a round trip
seqdata.flags.lattice_load_1_round_trip   = 0;       % Load the lattices; (1: normal, 2:single lattice, 3: 
defVar('lattice_ramp_1_round_trip_equilibriation_time',[2000],'ms');            % Hold time after loading before doing round trip



%% Optical Lattice
seqdata.flags.lattice                   = 1; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% More Lattice Flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defVar('lattice_pin_depth',60,'Er');
defVar('lattice_pin_time', 0.2, 'ms');

seqdata.flags.do_lattice_am_spec            = 0;    % Amplitude modulation spectroscopy    
seqdata.flags.lattice_rotate_waveplate_2    = 0;    % Second waveplate rotation 95% 
seqdata.flags.lattice_lattice_ramp_2        = 0;    % Secondary lattice ramp for fluorescence imaging
seqdata.flags.lattice_lattice_ramp_3        = 0;    % Secondary lattice ramp for fluorescence imaging
seqdata.flags.lattice_pin                   = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
seqdata.flags.lattice_PA                    = 0;
seqdata.flags.lattice_hold_at_end           = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conductivity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These flags are associated with the conducitivity experiment
seqdata.flags.lattice_conductivity          = 0;    % old sequence
seqdata.flags.lattice_conductivity_new      = 0;   % New sequence created July 25th, 2023

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RF/uWave Spectroscopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.lattice_uWave_spec            = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection, Raman Transfers, and Fluorescence Imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
seqdata.flags.lattice_do_optical_pumping    = 0;    % (1426) keep : optical pumping in lattice  
% Actual fluorsence image flags - NO LONGER USED
seqdata.flags.Raman_transfers               = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plane Selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
seqdata.flags.do_plane_selection            = 0;    % Plane selection flag
seqdata.flags.plane_selection.useFeedback   = 1;
seqdata.flags.plane_selection.dotilt        = 0;

% Default Plane Selection No Tilt Settings
freq_offset_notilt_list = [150];
freq_offset_amplitude_notilt_list = [15];
defVar('qgm_plane_uwave_frequency_offset_notilt',freq_offset_notilt_list,'kHz');
defVar('qgm_plane_uwave_frequency_amplitude_notilt',freq_offset_amplitude_notilt_list,'kHz');

% Default Plane Selection Tilt Settings
freq_offset_tilt_list = 150;
freq_offset_amplitude_tilt_list = 8; 
defVar('qgm_plane_uwave_frequency_offset_tilt',freq_offset_tilt_list,'kHz');
defVar('qgm_plane_uwave_frequency_amplitude_tilt',freq_offset_amplitude_tilt_list,'kHz');

% Feedback offset defaults to 0
d = load('f_offset.mat');
f_offset = d.f_offset;        
defVar('f_offset',f_offset,'kHz');
% defVar('f_offset',0,'kHz');

% defVar('f_amplitude',15,'kHz');

% Note:
% It is sometimes helpful to run the fluorence imaging code as other things
% such as :
% - alignment of EIT/FPUMP beams
% - Raman spectroscopy (to show Raman is working)
% - uWave spectroscopy (to find two photon frequency/field)

% New Standard Fluoresnce Image Flags
seqdata.flags.lattice_ClearCCD_IxonTrigger  = 0;    % Add additional trigger to clear CCD
seqdata.flags.lattice_fluor                 = 0;    % Do Fluoresnce imaging
seqdata.flags.lattice_fluor_bkgd            = 1;    % Take a background image with imaging light on, no atoms
                                                    % MUST SET NUMKIN +1

seqdata.flags.lattice_img_stripe            = 0;    % Plane select with tilt and take an additional imag of the stripe

seqdata.IxonMultiExposures=[];
seqdata.IxonMultiPiezos=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BandMapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.lattice_bandmap               = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LATTICE COURSE ALIGNMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If you have completely lost lattice alignment, use these flags to pulse
% the lattices.  Good luck.

% 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
seqdata.flags.lattice_pulse_for_alignment   = 0; 

% 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)
seqdata.flags.lattice_pulse_z_for_alignment = 0; 

%% Plane Selection


%% Conductivity

seqdata.flags.conductivity_ODT1_mode            = 0; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ODT2_mode            = 0; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_mod_direction        = 1; % 1:X-direction 2:Y-direction

defVar('conductivity_snap_and_hold_time',[0],'ms');
defVar('conductivity_FB_field',190,'G')
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
    

defVar('scope_pos',-7);
getVar('scope_pos');

    
%% QGM Imaging


%% Scope Trigger
% Choose which scope trigger to use.

% seqdata.scope_trigger = 'rf_spectroscopy';
% seqdata.scope_trigger = 'Lattice_Mod';
% seqdata.scope_trigger = 'FB_ramp';
seqdata.scope_trigger = 'lattice_ramp_1';
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

% seqdata.scope_trigger = '40k 97 mixing';
% seqdata.scope_trigger = 'Rampup ODT';
%% end time

timeout = curtime;

end

