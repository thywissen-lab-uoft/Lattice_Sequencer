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

    defVar('HF_kdet_shift',[-5],'MHz');
    kHFdet_shift = getVar('HF_kdet_shift');
    
    % Detunings for HF Imaging AOM
    params.detunings.repulsive_lattice  = [-7.7];-7.9;        % 15 ms tof, 195 G, 0.15 A lev
    params.detunings.repulsive_xdt      = [-7.1];-7.9;  % 25 ms tof, 195 G, 0.15 A lev
    params.detunings.attractive_lattice = -7.2;     % 15 ms tof, 207 G, 0.15 A lev
    params.detunings.attractive_xdt     = [-7.3];  % 25 ms tof, 207 G, 0.15 A lev

    %Set the RF frequency for the spin flip in TOF
    defVar('HF_rf_tof_shiftshift',[200],'kHz');
    d_rf = getVar('HF_rf_tof_shiftshift');

    % RF shifts for spin flip in TOF
    params.HF_rf_shift.repulsive_lattice    = 50;16;[57];     % 15 ms tof, 195 G, 0.15 A lev (zshim=0)
    params.HF_rf_shift.repulsive_xdt        = 90;200;   % 25 ms tof, 195 G, 0.15 A lev
    params.HF_rf_shift.attractive_lattice   = 22;     % 15 ms tof, 207 G, 0.15 A lev
    params.HF_rf_shift.attractive_xdt       = 90;140;   % 25 ms tof, 207 G, 0.15 A lev
    
    
    %% HG imaging tof rf sweep width
    
    defVar('HF_rf_tof_width',[0],'kHz');
    w_rf = getVar('HF_rf_tof_width');
    
    params.HF_rf_width.repulsive_lattice  = [150]*1e-3; % in MHz
    params.HF_rf_width.repulsive_xdt      = [30]*1e-3;
    params.HF_rf_width.attractive_lattice = [150]*1e-3;
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
