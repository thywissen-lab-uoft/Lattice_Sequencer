function params = Load_Absorption_Image_Parameters()
    global seqdata;
    %% Set imaging detunings
    % Potassium - X-cam
    kdet_shift_list = [0];%[2];%-1
    kdet_shift = getScanParameter(kdet_shift_list,...
        seqdata.scancycle,seqdata.randcyclelist,'kdet_shift','MHz');
    params.detunings.K.X.positive.normal = 22.2 ;
    params.detunings.K.X.positive.in_trap = 23.5;
    params.detunings.K.X.positive.QP_imaging = 21.5;
    params.detunings.K.X.positive.SG = 24.5;
    params.detunings.K.X.positive.short_tof = 24.5;
    params.detunings.K.X.negative.normal = 32.6; %(32.6) for DFG, (34.9) is for the ODT loading %%%%%32.5-2.72 for XDT loading , 32.5-4.76 DFG?
    
    % for mF stern gerlach
    params.detunings.K.X.negative.SG = 34.5; 
    
    % for F stern gerlach
%     params.detunings.K.X.negative.SG = 35.5; 
    
    % Lattice F Stern Gerlach, TOF = 15 ms
%     params.detunings.K.X.negative.SG = 35.5+kdet_shift;

    
    % Potassium - Y-cam
    params.detunings.K.Y.positive.normal = 21.5;
    params.detunings.K.Y.negative.normal = 31.5+0;
    % Potassium - MOT
    params.detunings.K.MOT.positive.normal = 20.5;
    params.detunings.K.MOT.positive.short_tof = 24.0;
    % Rubidium - X-cam
    
%     
    rbdet_shift_list = [0];
    rbdet_shift = getScanParameter(rbdet_shift_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rbdet_shift','MHz');
    
%     params.detunings.Rb.X.positive.normal = 6590 - 238;           % XDTs/lattice
%     params.detunings.Rb.X.positive.in_trap = 6590 - 246+7;          % QP in-situ
%     params.detunings.Rb.X.positive.QP_imaging = 6590 - 238.5 + rbdet_shift;       % QP TOF
%     params.detunings.Rb.X.positive.SG = 6590 - 241.8 +2;            % Stern Gerlach
%     params.detunings.Rb.X.negative.normal = 6590 - 232;
%     
% %     This is not calibrated; only to prevent code frmo crashing
%     params.detunings.Rb.X.negative.SG = 6590 - 241.8 +2;   
%     
% %     Rubidium - Y-cam
%     params.detunings.Rb.Y.positive.normal = 6590 - 230.7;
%     params.detunings.Rb.Y.positive.in_trap = 6590 - 243;
% %     Rubidium - MOT
%     params.detunings.Rb.MOT.positive.normal = 6590 - 240;


    % Rubidium XCAM
    params.detunings.Rb.X.positive.normal = 10;    % |2,2> 2022/09/02
    params.detunings.Rb.X.positive.in_trap = 0;             % |2,2> Uncalibrated
    params.detunings.Rb.X.positive.QP_imaging = 10;         % QP imaging 15 ms tof |2,2> 2022/09/02
    params.detunings.Rb.X.positive.SG = 0;                  % Uncalibrated
    params.detunings.Rb.X.negative.normal = 0;              % Uncalibrated
    params.detunings.Rb.X.negative.SG = 0;                  % Uncalibrated
    
%     Rubidium - Y-cam
    params.detunings.Rb.Y.positive.normal = 0;
    params.detunings.Rb.Y.positive.in_trap = 0;
%     Rubidium - MOT
    params.detunings.Rb.MOT.positive.normal  = 0 ;



    
    
    %% HF imaging
%     % Potassium -HF -Xcam : settting the DP HF imaging AOM freq
%     kHFdet_shift_list = [-8];%195G
    kHFdet_shift_list = [-11:1:-4];
    kHFdet_shift = getScanParameter(kHFdet_shift_list,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_kdet_shift','MHz');


%     params.detunings.K.X.negative9.HF.normal = -7 -0.4;
%    %195G:-1.5 206:-0.4
   
    params.detunings.K.X.negative9.HF.normal = [-8];%195G
    params.detunings.K.X.negative9.HF.attractive = [-8.5];[-9]; %[-9] %for 207G 15ms TOF; [-8.5] for 207G 21 ms
        
    % Detunings
    params.detunings.K.X.negative9.HF.repulsive_lattice = [-9];  [-8];       % 15 ms tof, 195 G
    params.detunings.K.X.negative9.HF.repulsive_xdt = [-8];             % 15 ms tof, 195 G
    params.detunings.K.X.negative9.HF.attractive_lattice = kHFdet_shift;[-7.5];[-10];[-8.5];      % 15 ms tof, 207 G
    params.detunings.K.X.negative9.HF.attractive_xdt = [-8.5];          % 21 ms tof, 207 G

    
    
    drf_list = [0];
    d_rf = getScanParameter(drf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_tof_shiftshift','kHz');

    % RF shifts
    params.HF_rf_shift.repulsive_lattice = [57];        % 15 ms tof, 195 G, (zshim=0)
%     params.HF_rf_shift.repulsive_xdt = 0; 0;52.5;[57];       % 21 ms tof, 195 G, (zshim=0)
    params.HF_rf_shift.repulsive_xdt = 52.5;       % 15 ms tof, 195 G, no QP(zshim=0)

    
    params.HF_rf_shift.attractive_lattice = [62];45;    % 15 ms tof, 207 G, (zshim=0)
    params.HF_rf_shift.attractive_xdt = [140];          % 21 ms tof, 207 G (zshim=0)
%     params.HF_rf_shift.attractive_xdt = [125];        % 21 ms tof, 207G (zshim=3)
    
    
    params.detunings.K.X.negative9.HF.SG = -4.5; %
    
%     params.detunings.K.X.negative7.HF.normal = 9.25 + 0.4; 
    %201G:+0.2 %190G: -0.25 %180G: -2.53 %195G: 0 204.5G: 0.5 207G: 0.4
    params.detunings.K.X.negative7.HF.normal = 9.25-0.6;
    params.detunings.K.X.negative7.HF.SG = 12.5;
        
    %% Other detunings
    
    params.k_OP_detuning.positive = 24;
    params.k_OP_detuning.negative = 33;
    params.k_repump_shift.positive = 28;
    params.k_repump_shift.negative = 21;21;
    %% Probe beam powers
    K_probe_pwr_list = [0.12];%.15;%[0.5];
    K_probe_pwr = getScanParameter(K_probe_pwr_list,seqdata.scancycle,...
        seqdata.randcyclelist,'K_probe_pwr','V');
    
    params.powers.K.X = K_probe_pwr;0.12;0.09;
    params.powers.K.Y = 0.12;
    params.powers.K.MOT = 0.8;
    Rb_probe_pwr_list = [0.1];[0.1];%-1
    Rb_probe_pwr = getScanParameter(Rb_probe_pwr_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_probe_pwr');
    
    
    params.powers.Rb.X = Rb_probe_pwr;
    params.powers.Rb.Y = 0.25;
    params.powers.Rb.MOT = 0.25;
    
    %% Stern Gerlach parameters
    params.SG.SG_shim_val = [-0.45,+0.1,2]; %[x,y,z] [0,0,2.5] March 16th, 2014 %-0.6 %2
    params.SG.SG_fesh_val = 0;
    params.SG.SG_shim_ramptime = 1; 
    params.SG.SG_shim_rampdelay = 0; %0 with respect to pulse start
    params.SG.SG_fesh_ramptime = 1;
    params.SG.SG_fesh_rampdelay = 0; % with respect to pulse start
    params.SG.SG_wait_TOF = 1;

    SG_QP_val_list = [7.5];%7.5;%5
    SG_QP_val = getScanParameter(SG_QP_val_list,seqdata.scancycle,seqdata.randcyclelist,'SG_QP_val');
    
% %    mF Stern Gerlach For |9,-9> vs |9,-7> low field (15ms TOF K)
    params.SG.SG_QP_val = 7.5*1.78;
    params.SG.SG_QP_pulsetime = 5;
    params.SG.SG_QP_ramptime =2;
 
% %     % F Stern Gerlach : |9,-9> vs |7,-7> low field (~20G) (15ms TOF)
%     params.SG.SG_QP_val = 1.78*5;
%     params.SG.SG_QP_pulsetime = 2; 
%     params.SG.SG_QP_ramptime =1; 
    
    % Stern Gerlach feed forward
    params.SG.SG_QP_FF = 23*(params.SG.SG_QP_val/30); % voltage FF on delta supplySS

    %% Other parameters
    params.others.RB_FF = 1.2;
    
    %% Timing parameters
    params.timings.tof = seqdata.params.tof;
    params.timings.pulse_length = 0.3;
    params.timings.time_diff_two_absorp_pulses = 1;1;0.05; % time delay for the 2nd light pulse
    params.timings.K_OP_time = 0.3;
    params.timings.k_detuning_shift_time = 0.5;
    params.timings.rb_detuning_shift_time.MOT = 4;
    params.timings.rb_detuning_shift_time.X = 50;1500;
    params.timings.rb_detuning_shift_time.Y = 50;
    wait_time_list = [0.03];
    params.timings.wait_time = getScanParameter(wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'imaging_wait_time');
    
    %% Quantization field timings
    %RHYS - These have to be last right now due to mathematics... kind of silly
    params.quant_timings.normal.quant_handover_time = 15; %RHYSCHANGE Oct 17, 2018 from 30
    params.quant_timings.normal.quant_handover_delay = -15; %RHYSCHANGE Oct 17, 2018 from -30
    params.quant_timings.normal.quant_handover_fesh_ramptime = 15;  %0
    params.quant_timings.normal.quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
    
    params.quant_timings.SG.quant_handover_delay = params.SG.SG_wait_TOF + params.SG.SG_QP_pulsetime;
    params.quant_timings.SG.quant_handover_time = 1; %Give 1ms for quantizing shims to turn on.
    params.quant_timings.SG.quant_handover_fesh_ramptime = 1;
    params.quant_timings.SG.quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
    
    params.quant_timings.QP_imaging.quant_handover_delay = min(0,params.timings.tof-2); % minimum ramp time for shims: ~2ms
    params.quant_timings.QP_imaging.quant_handover_time = 0;
    params.quant_timings.QP_imaging.quant_handover_fesh_ramptime = 0;
    params.quant_timings.QP_imaging.quant_handover_fesh_rampdelay = 0;
    
    params.quant_timings.in_trap.quant_handover_delay = min(0,params.timings.tof-2); % minimum ramp time for shims: ~2ms
    params.quant_timings.in_trap.quant_handover_time = 0;
    params.quant_timings.in_trap.quant_handover_fesh_ramptime = 0;
    params.quant_timings.in_trap.quant_handover_fesh_rampdelay = 0;
    
    params.quant_timings.short_tof.quant_handover_delay = min(0,params.timings.tof-2); % minimum ramp time for shims: ~2ms
    params.quant_timings.short_tof.quant_handover_time = 0;
    params.quant_timings.short_tof.quant_handover_fesh_ramptime = 0;
    params.quant_timings.short_tof.quant_handover_fesh_rampdelay = 0;

    %% Quantization field values
    % RHYS - Why not make these all the same magnitude?
    params.quant_shim_val.X.positive = [0.00,2.45,0.00];
    params.quant_shim_val.X.negative = [0.00,-1.00,0.00];
    params.quant_shim_val.Y.positive = [2.45,0.00,0.00];
    params.quant_shim_val.Y.negative = [-1.00,0.00,0.00];
end
