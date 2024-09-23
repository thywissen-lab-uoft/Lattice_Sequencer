function flags = Load_Absorption_Image_Flags()

    %Default Imaging Flags.
    flags.image_atomtype = 'K';% K, Rb, KRb, RbK
    flags.img_direction = 'X'; % X or Y
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
    
    switch seqdata.flags.image_direction
      case 1
        flags.img_direction = 'X';
      case 2
        flags.img_direction = 'Y';
    end
    
    if seqdata.flags.QP_imaging == 1
      flags.condition = 'QP_imaging';
    end
    
        
    if seqdata.flags.image_stern_gerlach_F == 1 || seqdata.flags.image_stern_gerlach_mF
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

    
end