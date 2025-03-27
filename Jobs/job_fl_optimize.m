function J = job_fl_optimize

%% Values

plane_shift             = 5;
field                   = 201.1;
evap_depth_fl           = 0.055;

str_fluor = ['fluor optimize : plane=' num2str(plane_shift) ',' ...
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
%% Raman Modifier Function
v1 = [0.3:.1:1.0];
v2 = [0.3:.1:1.0];
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
    
    defVar('qgm_Raman1_power',v1);
    defVar('qgm_Raman2_power',v2);
    
    seqdata.flags.do_plane_selection            = 1;
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0;           
    seqdata.flags.lattice_fluor_multi_mode      = 1;             
    seqdata.flags.qgm_doPlaneShift              = 1;
end
%%
out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @(curtime) seq_fl_detuning(curtime),...
    @main_sequence};
out.CycleEnd        = length(BB);
out.WaitMode        = 2;
out.WaitTime        = 90;
out.JobName         = str_fluor;
out.SaveDir         = 'fidelity optimize';  
%% Output Job File
J = sequencer_job(out);

end

