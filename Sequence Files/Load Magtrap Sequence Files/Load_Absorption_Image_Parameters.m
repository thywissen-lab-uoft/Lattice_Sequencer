function params = Load_Absorption_Image_Parameters()

    %% Set imaging detunings
    % Potassium - X-cam
    params.detunings.K.X.positive.normal = 42;
    params.detunings.K.X.positive.in_trap = 44;
    params.detunings.K.X.positive.QP_imaging = 42;
    params.detunings.K.X.positive.SG = 45;
    params.detunings.K.X.positive.short_tof = 45;
    params.detunings.K.X.negative.normal = 51;
    params.detunings.K.X.negative.SG = 50;
    % Potassium - Y-cam
    params.detunings.K.Y.positive.normal = 42;
    params.detunings.K.Y.negative.normal = 52;
    % Potassium - MOT
    params.detunings.K.MOT.positive.normal = 41;
    params.detunings.K.MOT.positive.short_tof = 54.5;
    % Rubidium - X-cam
    params.detunings.Rb.X.positive.normal = 6590 - 238;
    params.detunings.Rb.X.positive.in_trap = 6590 - 246;
    params.detunings.Rb.X.positive.QP_imaging = 6590 - 238.5;
    params.detunings.Rb.X.positive.SG = 6590 - 241.8;
    params.detunings.Rb.X.negative = 6590 - 232;
    % Rubidium - Y-cam
    params.detunings.Rb.Y.positive.normal = 6590 - 230.7;
    params.detunings.Rb.Y.positive.in_trap = 6590 - 243;
    % Rubidium - MOT
    params.detunings.Rb.MOT.positive.normal = 6590 - 240;
    
    %% Probe beam powers
    params.powers.K.X = 0.09;
    params.powers.K.Y = 0.05;
    params.powers.K.MOT = 0.8;
    params.powers.Rb.X = 0.3;
    params.powers.Rb.Y = 0.25;
    params.powers.Rb.MOT = 0.25;
    
    %% Timing parameters
    params.pulse_length = 0.3;
    params.K_OP_time = 0.3;
    params.k_detuning_shift_time = 0.5;
    params.rb_detuning_shift_time = 4;
    
    %% Other parameters
    params.RB_FF = 1.2;
end
