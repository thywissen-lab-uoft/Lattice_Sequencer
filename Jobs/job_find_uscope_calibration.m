function J = job_find_uscope_calibration(npt)
% Creates a job for running a single plane.

if nargin==0
    npt = struct;
end

if ~isfield(npt,'xdtB_evap_power')
    npt.xdt_B_evap_power = 0.0645;
end

if ~isfield(npt,'lattice_load_feshbach_field')
    npt.lattice_load_feshbach_field = 195;
end

if ~isfield(npt,'NumCycles')
   npt.NumCycles=20; 
end

%% Sequence Modifier Function

function curtime = scan_uscope(curtime,plane_shift)
    global seqdata         
    defVar('xdtB_evap_power',0.056,'W');
    defVar('lattice_load_feshbach_field',201.1,'G');  %npt.lattice_load_feshbach_field;       
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
    
    seqdata.flags.qgm_doPlaneShift = 1;
    defVar('qgm_planeShift_N',plane_shift,'plane');        
    
    kappa_0 = -0.076;   
    kappa_0 = -0.096;    

    dkappa = [-.02:.004:.02];
    
    defVar('qgm_planeShift_voltperplane',kappa_0+dkappa,'V'); % V/Plane (sign convention is relative to freqperplane)

   % Lattice Load Settings
    defVar('lattice_load_time',750,'ms');
    defVar('lattice_load_depthX',2.5,'Er');
    defVar('lattice_load_depthY',2.5,'Er');
    defVar('lattice_load_depthZ',2.5,'Er');              
end

%% Create Job File
clear J

planes = [4 11];

 for ii = 1:length(planes)     
    out = struct;
    out.SequenceFunctions   = {...
        @main_settings,...
        @(curtime) ...
        scan_uscope(curtime,planes(ii)),...
        @main_sequence};
    out.CycleEnd   = 11;
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName         = ['scan Vperplane plane ' num2str(planes(ii))];
    out.SaveDir         = out.JobName;  
    J(ii) = sequencer_job(out);
 end
    
 
%% Output Job File
% J = sequencer_job(out);

end

