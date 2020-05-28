%Global comments:
%Need to remove some of these in Load_MagTrap_sequence
%Do we need image_type?
%Make this as compact as possible

image_loc = 1; %Location of the image: 0 = MOT, 1 = science chamber
image_atomtype = 1; %Atom species being imaged: 0 = Rb, 1 = K, 2 = Both
%Delete the others? %1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direc tion (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
img_direction = 1; %Which lattice direction the atoms are imaged in: 1 = x-cam, 2 = y-cam
do_stern_gerlach = 0; %Whether to pulse the QP coil to split spins during ToF (takes some time,setting minimum ToF): 0 = No SG, 1 = SG
iXon = 0; %Use iXon camera to take an absorption image (only vertical)
do_F1_pulse = 1; %Repump Rb F = 1 to F = 2 before/during imaging
In_Trap_imaging = 0; %Set to take the image while the atoms are still in the magnetic trap
High_Field_Imaging = 0; %Set to image the atoms at a field near the FB resonance (near 202.1G)
perp_quant_field = 0; %set to nonzero integer (1) to use a quantization field perpendicular to img_direction

use_K_OP = 1; %Usually useful. Must enable repump as well.
use_K_repump = 1; % 1:turn on K repump beam for imaging F=7/2
use_K_repump_at_low_field = 0; %Ever used?
K_repump_during_image = 0; %Not sure this is useful.
negative_imaging_shim = 0; %0 = positive states 1 = negative states %Automatically set by K_RF_Sweep flag


if seqdata.flags.High_Field_Imaging==0 %disable the optical pumping during HF imaging
    use_K_OP = 0;
end

%Take an image after short time of flight
short_tof = 0;
%Take an in-situ image of the cloud after D1 cooling (need to leave a wait
%time after the molasses >3ms)
in_situ_D1 = 0;
%         if seqdata.flags. image_type == 8
%             in_situ_D1 = 1;
%         end
%Image with 405nm Beam
blue_image = 0;
%Image with D1 beam
D1_image = 0;