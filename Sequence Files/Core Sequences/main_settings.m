function npt = main_settings(npt)

%% Imaging

npt.flags.image_type = 0; 
%0: absorption image, 1: recapture, 2:fluor, 
%3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 
%6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses 
%8: iXon fluorescence + Pixelfly absorption
npt.flags.MOT_flour_image = 0;

iXon_movie = 0; %Take a multiple frame movie?
npt.flags.image_atomtype = 1;   % 0: Rb; 1:K; 2: K+Rb (double shutter)
npt.flags.image_loc = 1;        % 0: `+-+MOT cell, 1: science chamber    
npt.flags.image_direction = 0;  % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
npt.flags.image_stern_gerlach = 0; % 1: Do a gradient pulse at the beginning of ToF
npt.flags.image_iXon = 0;          % (unused?) use iXon camera to take an absorption image (only vertical)
npt.flags.image_F1_pulse = 0;      % (unused?) repump Rb F=1 before/during imaging (unused?)

npt.flags.High_Field_Imaging = 0;
%1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
%3 = make sure shim are off for D1 molasses (should be removed)

npt.flags.image_insitu =0; % Does this flag work for QP/XDT? Or only QP?

% Choose the time-of-flight time for absorption imaging
tof_list = [25]; %DFG 25ms ; RF1b Rb 15ms ; RF1b K 5ms; BM 15ms
npt.params.tof = getScanParameter(tof_list,...
    npt.scancycle,npt.randcyclelist,'tof','ms');

% For double shutter imaging, may delay imaging Rb after K
tof_krb_diff_list= [0];
npt.params.tof_krb_diff = getScanParameter(tof_krb_diff_list,...
    npt.scancycle,npt.randcyclelist,'tof_krb_diff','ms');


%% MOT

%% Transport
% Horizontal Transport Type
npt.flags.hor_transport_type            = 1; 
%0: min jerk curves, 1: slow down in middle section curves, 2: none

% Vertical Transport Type
npt.flags.ver_transport_type            = 3; 
% 0: min jerk curves, 1: slow down in middle section curves, 
% 2: none, 3: linear, 4: triple min jerk

npt.flags.mt_compress_after_transport   = 1; % compress QP after transport

%% Mangetic Trap

npt.flags.RF_evap_stages                = [1, 1, 1];
npt.flags.mt_use_plug                   = 1;            % Turn on plug beam during RF1B
npt.flags.mt_lower_after_evap           = 0;            % Lower cloud after evaporation before TOF (can be useful for hot clouds)
npt.flags.mt_kill_Rb_after_evap         = 0;            % Resonant pulse after evap Rb
npt.flags.mt_kill_K_after_evap          = 0;            % Resonant pulse after evap K
npt.flags.mt_plug_ramp_end              = 0;            % Ramp plug power at end of evaporation

%% Optical Dipole Trap

npt.flags.xdt                           = 1; 
npt.params.ODT_zeros = [-0.04,-0.04];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_qp_ramp_down1             = 1;
npt.flags.xdt_qp_ramp_down2             = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% State Manipulation Before Optical Evaporation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_Rb_21uwave_sweep_field    = 1;    % Field Sweep Rb 2-->1
npt.flags.xdt_Rb_21uwave_sweep_freq     = 0;    % uWave Frequency sweep Rb 2-->1
npt.flags.xdt_K_p2n_rf_sweep_freq       = 1;    % RF Freq Sweep K +9-->-9  
npt.flags.xdt_d1op_start                = 1;    % D1 pump to purify
npt.flags.xdt_rfmix_start               = 1;    % RF Mixing -9-->-9+-7    
npt.flags.xdt_kill_Rb_before_evap       = 0;    % optically remove Rb
npt.flags.xdt_kill_K7_before_evap       = 0;    % optical remove 7/2 K after (untested)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optical Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_ramp_FB_before_evap       = 0;    % Ramp up feshbach before evaporation
npt.flags.xdt_levitate_evap             = 0;    % Apply levitation gradient
npt.flags.xdt_ramp2sympathetic          = 1;    % Ramp to sympathetic powers
npt.flags.xdt_optical_evaporation_1     = 1;    % First Stage Optical Evaporation
npt.flags.xdt_optical_evaporation_2     = 1;    % Second Stage Optical Evaporation
npt.flags.xdt_unlevitate_evap           = 0;    % Remove levitation gradient

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% State Manipulation after Optical Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_d1op_end                  = 0;    % D1 optical pumping
npt.flags.xdt_rfmix_end                 = 0;    % RF Mixing -9-->-9+-7
npt.flags.xdt_kill_Rb_after_evap        = 0;    % optically remove Rb
npt.flags.xdt_kill_K7_after_evap        = 0;    % optical remove 7/2 K after (untested)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% High Field Operations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_high_field_a              = 0;    % High Field stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%After Evaporation (unless CDT_evap = 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_ramp_power_end            = 1;    % Ramp dipole back up after evaporation before any further physics 
npt.flags.xdt_do_dipole_trap_kick       = 0;    % Kick the dipole trap, inducing coherent oscillations for temperature measurement
npt.flags.xdt_do_hold_end               = 0;    % Hold ODT
npt.flags.xdt_am_modulate               = 0;    % 1: ODT1, 2:ODT2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spectroscopy after Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
npt.flags.xdt_k_rf_rabi_oscillation     = 0;    % RF rabi oscillations after evap
npt.flags.xdt_ramp_QP_FB_and_back       = 0;    % Ramp up and down FB and QP to test field gradients
npt.flags.xdt_uWave_K_Spectroscopy      = 0;
npt.flags.xdt_ramp_up_FB_for_lattice    = 0;    %Ramp FB up at the end of evap  


%% Optical Lattice

% set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
npt.flags.lattice                       = 0; 

% 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
npt.flags.lattice_pulse_for_alignment   = 0; 

% 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)
npt.flags.lattice_pulse_z_for_alignment = 0; 

%% Miscellaneous
end

