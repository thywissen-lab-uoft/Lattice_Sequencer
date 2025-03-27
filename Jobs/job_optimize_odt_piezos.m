function [J] = job_optimize_odt_piezos
%JOB_OPTIMIZE_ODT_PIEZOS Summary of this function goes here
%   Detailed explanation goes here

% Job 1 : Find Location of ODT1
%   There are various ways to do this. The current scheme is where we fix
%   ODT1 vertical piezo, and pin the lattice from ODT1 only. We then scan
%   the selectio plane to optimize.
%
% Job 2 : Optimize Density via scanning ODT2
%   With ODT1 fixed, we optimized the ODT2 position by scanning the
%   vertical piezo and trying to optimize the density at the selected
%   plane.
%
% Job 3 : Refind the center plane
%   Everything should be centered, but we should remeasure the center
%   plane.

%% Settings
evap_depth = 0.055;
field = 201.5;
plane_shift = 5;

pin_depth = 70;
pin_time = 0.01;
%% Sequence Modifier Function

function curtime = xdt1_find_center(curtime)
    global seqdata         
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0;     
    seqdata.flags.qgm_doPlaneShift = 1;
    
    seqdata.flags.xdtB_one_beam_ODT1            = 1;    % Turn on ODT1
    seqdata.flags.xdtB_one_beam_ODT2            = 0;    % Turn off ODT2
    
    defVar('xdtB_evap_power',evap_depth,'W');
    defVar('lattice_load_feshbach_field',field,'G');  
    defVar('qgm_planeShift_N',[-4:2:16],'plane');    
    
    % Ramp Vertical Piezo of ODT1 or ODT2
    seqdata.flags.xdtB_vert_piezo_ramp_ODT1   = 0;
    seqdata.flags.xdtB_vert_piezo_ramp_ODT2   = 0;
    defVar('xdtB_vert_piezo_ramp_time',[100],'ms');         
    defVar('xdtB_vert_piezo_ramp_value_1',5,'V');
    defVar('xdtB_vert_piezo_ramp_value_2',5,'V');

%   % Lattice Load Settings
    defVar('lattice_load_time',pin_time,'ms');
    defVar('lattice_load_depthX',pin_depth,'Er');
    defVar('lattice_load_depthY',pin_depth,'Er');
    defVar('lattice_load_depthZ',pin_depth,'Er');                
end

end

