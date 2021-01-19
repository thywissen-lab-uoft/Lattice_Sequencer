function params = Load_Absorption_Image_Parameters()
    global seqdata;
    %% Set imaging detunings
    % Potassium - X-cam
    kdet_shift_list = [-5:5];%-1
    kdet_shift = getScanParameter(kdet_shift_list,seqdata.scancycle,seqdata.randcyclelist,'kdet_shift');
    params.detunings.K.X.positive.normal = 19+2.5;19;
    params.detunings.K.X.positive.in_trap = 23.5;
    params.detunings.K.X.positive.QP_imaging = 21.5+2.5;
    params.detunings.K.X.positive.SG = 24.5;
    params.detunings.K.X.positive.short_tof = 24.5;
    params.detunings.K.X.negative.normal = 30.5+2;
    params.detunings.K.X.negative.SG = 32.5;29.5;
    % Potassium - Y-cam
    params.detunings.K.Y.positive.normal = 21.5;
    params.detunings.K.Y.negative.normal = 31.5;
    % Potassium - MOT
    params.detunings.K.MOT.positive.normal = 20.5;
    params.detunings.K.MOT.positive.short_tof = 24.0;
    % Rubidium - X-cam
    params.detunings.Rb.X.positive.normal = 6590 - 238-4;
%     rbdet_shift_list = [7];-1
%     rbdet_shift = getScanParameter(rbdet_shift_list,seqdata.scancycle,seqdata.randcyclelist,'rbdet_shift');
    params.detunings.Rb.X.positive.in_trap = 6590 - 246+7;
    params.detunings.Rb.X.positive.QP_imaging = 6590 - 238.5;
    params.detunings.Rb.X.positive.SG = 6590 - 241.8 +2;
    params.detunings.Rb.X.negative.normal = 6590 - 232;
    % Rubidium - Y-cam
    params.detunings.Rb.Y.positive.normal = 6590 - 230.7;
    params.detunings.Rb.Y.positive.in_trap = 6590 - 243;
    % Rubidium - MOT
    params.detunings.Rb.MOT.positive.normal = 6590 - 240;
    
    %% Other detunings
    
    params.k_OP_detuning.positive = 24;
    params.k_OP_detuning.negative = 33;
    params.k_repump_shift.positive = 28;
    params.k_repump_shift.negative = 21;
    %% Probe beam powers
    params.powers.K.X = 0.19;0.09;
    params.powers.K.Y = 0.05;
    params.powers.K.MOT = 0.8;
    params.powers.Rb.X = 0.3;
    params.powers.Rb.Y = 0.25;
    params.powers.Rb.MOT = 0.25;
    
    %% Stern Gerlach parameters
    params.SG.SG_shim_val = [-0.45,+0.1,2]; %[x,y,z] [0,0,2.5] March 16th, 2014 %-0.6 %2
    params.SG.SG_fesh_val = 0;
    params.SG.SG_shim_ramptime = 1; %1
    params.SG.SG_shim_rampdelay = 0; %0 with respect to pulse start
    params.SG.SG_fesh_ramptime = 1;
    params.SG.SG_fesh_rampdelay = 0; % with respect to pulse start
    SG_QP_val_list = [6];
    SG_QP_val = getScanParameter(SG_QP_val_list,seqdata.scancycle,seqdata.randcyclelist,'SG_QP_val');
    params.SG.SG_QP_val = SG_QP_val*1.78;%6*1.78
    params.SG.SG_QP_pulsetime = 5;%5
    params.SG.SG_QP_ramptime = 2;%2
    params.SG.SG_QP_FF = 23*(params.SG.SG_QP_val/30); % voltage FF on delta supply
    params.SG.SG_wait_TOF = 1;%1

    
    %% Other parameters
    params.others.RB_FF = 1.2;
    
    %% Timing parameters
    params.timings.tof = seqdata.params.tof;
    params.timings.pulse_length = 0.3;
    params.timings.K_OP_time = 0.3;
    params.timings.k_detuning_shift_time = 0.5;
    params.timings.rb_detuning_shift_time.MOT = 4;
    params.timings.rb_detuning_shift_time.X = 50;1500;
    params.timings.rb_detuning_shift_time.Y = 50;
    
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
