function output = standard_params
% Author : CJ Fujiwara
%
% When running the experiment for long runs of fluorescence imaging, it is
% useful to have commonly used experimental parameters on hand.  Also for
% something that Skynet can optimize. (To be implemented perhaps later)

output = struct;
output.xdtB_evap_power                  = 0.054;
output.lattice_load_feshbach_field      = 201.1;
output.qgm_planeShift_N                 = 5;
output.lattice_load_depthX              = 2.5;
output.lattice_load_depthY              = 2.5;
output.lattice_load_depthZ              = 2.5;
output.lattice_load_time                = 750;
    
end

