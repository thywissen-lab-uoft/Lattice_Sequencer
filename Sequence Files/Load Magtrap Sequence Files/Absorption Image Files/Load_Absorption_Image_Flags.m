function flags = Load_Absorption_Image_Flags()
    
    flags.image_atomtype = 'K';%seqdata.flags.image_atomtype; %Atom species being imaged: 'K' or 'Rb'
    flags.img_direction = 'X';%seqdata.flags.img_direction; %Which lattice direction the atoms are imaged in: 1 = x-cam, 2 = y-cam
    flags.condition = 'SG'; %'normal', 'in_trap', 'QP_imaging', 'SG', 'short_tof'
    flags.negative_imaging_shim = 'positive'; %0 = positive states 1 = negative states %Automatically set by K_RF_Sweep flag

    flags.image_loc = 1; %Why do I need this?
    flags.iXon = 0; %Use iXon camera to take an absorption image (only vertical)
    flags.do_F1_pulse = 1; %Repump Rb F = 1 to F = 2 before/during imaging
    flags.High_Field_Imaging = 0; %Set to image the atoms at a field near the FB resonance (near 202.1G)
    
    %These flags were already isolated in absorption_image.
    flags.use_K_OP = 1; %Usually useful. Must enable repump as well.
    flags.use_K_repump = 1; % 1:turn on K repump beam for imaging F=7/2
    flags.K_repump_during_image = 0; %Not sure this is useful.
    flags.perp_quant_field = 0; %set to nonzero integer (1) to use a quantization field perpendicular to img_direction    quant_handover_time = 3; % time to ramp shims for imaging ... this may be changed below depending on the selected option    
    
end