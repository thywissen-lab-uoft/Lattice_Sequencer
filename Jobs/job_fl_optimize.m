function J = job_fl_optimize

%% Values

plane_shift             = 5;
field                   = 201.1;
evap_depth_fl           = 0.055;

str_2photon = ['fluor optimize : plane=' num2str(plane_shift) ',' ...
    'field=' num2str(field) ',' ...
    'evap2=' num2str(evap_depth_fl)];

str_raman = ['raman optimize : plane=' num2str(plane_shift) ',' ...
    'field=' num2str(field) ',' ...
    'evap2=' num2str(evap_depth_fl)];
%% Sequence Modifier Function
    B = [.17:.005:.24];
    V = [0.8:.1:1.2];    
    V=1.1;
    [BB,PP] = meshgrid(B,V);
    BB=BB(:);
    PP=PP(:);    
    
function curtime = seq_fl_detuning(curtime)
    global seqdata         
    defVar('xdtB_evap_power',evap_depth_fl,'W');
    defVar('lattice_load_feshbach_field',field,'G');    
    defVar('qgm_planeShift_N',plane_shift,'plane');        

    defVar('qgm_field_shift',BB,'G');
    defVar('F_Pump_Power',PP,'V');
    seqdata.flags.do_plane_selection            = 1;
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0;           
    seqdata.flags.lattice_fluor_multi_mode      = 1;             
    seqdata.flags.qgm_doPlaneShift              = 1;
end

out_detune = struct;
out_detune.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) seq_fl_detuning(curtime),...
    @main_sequence};
out_detune.CycleEnd        = length(BB);
out_detune.WaitMode        = 2;
out_detune.WaitTime        = 90;
out_detune.JobName         = str_2photon;
out_detune.SaveDir         = 'fidelity optimize';  

%% Raman Modifier Function
v1 = [0.2:.2:1.0];
v2 = [0.2:.2:1.0];
[vv1,vv2] = meshgrid(v1,v2);
vv1=vv1(:);
vv2=vv2(:);  
    
function curtime = seq_fl_raman(curtime)
    global seqdata         
    defVar('xdtB_evap_power',evap_depth_fl,'W');
    defVar('lattice_load_feshbach_field',field,'G');    
    defVar('qgm_planeShift_N',plane_shift,'plane');        

    defVar('qgm_field_shift',0.20,'G');
    defVar('F_Pump_Power',1.2,'V');
    
    defVar('qgm_Raman1_power',vv1);
    defVar('qgm_Raman2_power',vv2);
    
    seqdata.flags.do_plane_selection            = 1;
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0;           
    seqdata.flags.lattice_fluor_multi_mode      = 1;             
    seqdata.flags.qgm_doPlaneShift              = 1;
end

out_raman_pow = struct;
out_raman_pow.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) seq_fl_raman(curtime),...
    @main_sequence};
out_raman_pow.CycleEnd        = length(vv1);
out_raman_pow.WaitMode        = 2;
out_raman_pow.WaitTime        = 90;
out_raman_pow.JobName         = str_raman;
out_raman_pow.SaveDir         = 'fidelity optimize raman power';  


%% Output Job File
% J = sequencer_job(out_detune);
J = sequencer_job(out_raman_pow);

end

