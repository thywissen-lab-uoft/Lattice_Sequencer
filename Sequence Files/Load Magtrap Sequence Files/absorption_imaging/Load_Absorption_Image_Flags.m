function flags = Load_Absorption_Image_Flags()

    %Standard flags.
    flags.image_atomtype = 'K';%seqdata.flags.image_atomtype; %Atom species being imaged: 'K' or 'Rb'
    flags.img_direction = 'X';%seqdata.flags.img_direction; %Which lattice direction the atoms are imaged in: 1 = x-cam, 2 = y-cam
    flags.condition = 'normal'; %'normal', 'in_trap', 'QP_imaging', 'SG', 'short_tof'
    flags.negative_imaging_shim = 'positive'; %0 = positive states 1 = negative states %Automatically set by K_RF_Sweep flag
    
    %% Dark Image for
    
    flags.TakeDarkImage = 1;
    
    
    %% Temporary kluge to work with Load_MagTrap_sequence
    global seqdata;
    
    switch seqdata.flags.image_atomtype
      case 0
        flags.image_atomtype = 'Rb';
      case 1
        flags.image_atomtype = 'K';
      case 2
        flags.image_atomtype = 'KRb';      
    end
    
    switch seqdata.flags.img_direction
      case 1
        flags.img_direction = 'X';
      case 2
        flags.img_direction = 'Y';
    end
    
    if seqdata.flags.QP_imaging == 1
      flags.condition = 'QP_imaging';
    end
    
    if seqdata.flags.do_stern_gerlach == 1
      flags.condition = 'SG';
    end
    
    if seqdata.flags.image_insitu == 1
        flags.condition = 'in_trap';
    end
    %% Other flags
    
    %OP/repump flags.
    flags.do_F1_pulse = 1;              % Repump Rb F = 1 to F = 2 before/during imaging
    flags.use_K_OP = 1;                 % Usually useful. Must enable repump as well.
    flags.use_K_repump = 1;             % 1:turn on K repump beam for imaging F=7/2
    flags.K_repump_during_image = 1;    % Not sure this is useful.

    
    %Special flags
    flags.iXon = 0; %Use iXon camera to take an absorption image (only vertical)

    
%% flags for HF imaging
% Setting for high field imaging
flags.High_Field_Imaging = seqdata.flags.High_Field_Imaging; %|| seqdata.flags.CDT_evap_2_high_field;

% In high field imaging, we can image either -9,-7, or -9 and -7 together
% using the double shutter
% 0 : Image -9 and -7 in double shutter
% 1 : Image -9 in single shutter
% 2 : Image -7 in single shutter
flags.HighFieldType=0; % Not implemented yet

% Image on attractive or repulsive side of 97 resonance 
% Set up for 15ms TOF
% 0 = image at 195G
% 1 = image at 207G
flags.HighField_Attractive = 0;

flags.Two_Imaging_Pulses = 1;
flags.Image_Negative9 = 0;
flags.Image_Both97 = 1;
flags.Spin_Flip_79_in_Tof = 1;

    
end