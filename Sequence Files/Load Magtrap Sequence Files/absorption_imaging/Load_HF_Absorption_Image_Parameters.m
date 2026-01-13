function params = Load_HF_Absorption_Image_Parameters()
    global seqdata;
    %% Set K trap detuning
    % Potassium - X-cam
    kdet_shift_list = [0];%[2];%-1
    kdet_shift = getScanParameter(kdet_shift_list,...
        seqdata.scancycle,seqdata.randcyclelist,'kdet_shift','MHz');

    %Detuning for the K TRAP AOM
    params.detunings.KTrap = 30.6;
    
    %% HF imaging detunings
    % Potassium -HF -Xcam : setting the DP HF imaging AOM freq

    defVar('HF_kdet_shift',[0],'MHz');
    kHFdet_shift = getVar('HF_kdet_shift');
    
    % Detunings for HF Imaging AOM
    params.detunings.repulsive_lattice  = [-9];         % 15 ms tof, 195 G
    params.detunings.repulsive_xdt      = [-7.1];-7.9;  % 25 ms tof, 195 G
    params.detunings.attractive_lattice = [-8.5];       % 15 ms tof, 207 G
    params.detunings.attractive_xdt     = [-7.3];-8.5;  % 25 ms tof, 207 G

    %Set the RF frequency for the spin flip in TOF
    defVar('HF_rf_tof_shiftshift',[0],'kHz');
    d_rf = getVar('HF_rf_tof_shiftshift');

    % RF shifts for spin flip in TOF
    params.HF_rf_shift.repulsive_lattice    = [57];     % 15 ms tof, 195 G, (zshim=0)
    params.HF_rf_shift.repulsive_xdt        = 90;200;   % 25 ms tof, 195 G, levitate on
    params.HF_rf_shift.attractive_lattice   = [62];     % 15 ms tof, 207 G, (zshim=0)
    params.HF_rf_shift.attractive_xdt       = 90;140;   % 25 ms tof, 207 G, levitate on
    
    
    %% HG imaging tof rf sweep width
    
    params.HF_rf_width.repulsive_lattice  = [30]*1e-3; % in MHz
    params.HF_rf_width.repulsive_xdt      = [30]*1e-3;
    params.HF_rf_width.attractive_lattice = [20]*1e-3;
    params.HF_rf_width.attractive_xdt     = [20]*1e-3;

    %% Timing parameters
    params.timings.tof = seqdata.params.tof;
    params.timings.pulse_length = 0.3;
    params.timings.time_diff_two_absorp_pulses = 1; % time delay for the 2nd light pulse
    params.timings.k_detuning_shift_time = 0.5;

    wait_time_list = [0.03];
    params.timings.wait_time = getScanParameter(wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'imaging_wait_time');
    
end
