function J = job_single_plane(npt)
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

function curtime = one_plane(curtime)
    global seqdata         
    defVar('xdtB_evap_power',0.055,'W');0.0545;
    defVar('lattice_load_feshbach_field',201.107,'G');  %npt.lattice_load_feshbach_field;       
    seqdata.flags.lattice_conductivity_new      = 0; 
    seqdata.flags.plane_selection_dotilt        = 0; 
    seqdata.flags.lattice_fluor_multi_mode      = 0; 
    
    seqdata.flags.qgm_doPlaneShift = 1;
    defVar('qgm_planeShift_N',[-13:1:-1],'plane');   
    
    % set spin mixture
%     seqdata.flags.xdtB_rf_mix                   = 1;
%     seqdata.flags.xdtB_rf_mix_post_evap          = 1;
    
    % Pulse lattice
    seqdata.flags.xdtB_pulse_lattice            = 0;
    defVar('xdtb_lattice_load_time',0.1,'ms');
    defVar('xdtb_lattice_depth',[1],'Er');
    defVar('xdtb_lattice_hold_pulse_time',[2],'ms');
    defVar('xdtb_lattice_pulse_equil_time',[100],'ms');
    
    % Scan the tilt/notilt offset
    defVar('tilt_notilt_shift',[110],'kHz');
    tilt_notilt_offset = getVar('tilt_notilt_shift');
    freq_offset_notilt_list = getVar('qgm_plane_uwave_frequency_offset_tilt')+tilt_notilt_offset;
    defVar('qgm_plane_uwave_frequency_offset_notilt',freq_offset_notilt_list,'kHz');
    defVar('qgm_plane_uwave_frequency_amplitude_notilt',30,'kHz');
    
% %     Turn off one of the dipole trap beams to measure its position
%     seqdata.flags.xdtB_one_beam_ODT1            = 0;
%     seqdata.flags.xdtB_one_beam_ODT2            = 0;
    
%     % Ramp Vertical Piezo of ODT1 or ODT2
    seqdata.flags.xdtB_one_beam_ODT1 = 0;
    seqdata.flags.xdtB_one_beam_ODT2 = 0;
    defVar('xdtB_vert_piezo_ramp_time',[100],'ms');         
    defVar('xdtB_vert_piezo_ramp_value_1',5,'V');
    defVar('xdtB_vert_piezo_ramp_value_2',[5],'V');

            
% %     % Lattice Load Settings
%     defVar('lattice_load_time',[750],'ms');750;
%     defVar('lattice_load_depthX',2.5,'Er');2.5;
%     defVar('lattice_load_depthY',2.5,'Er');2.5;
%     defVar('lattice_load_depthZ',2.5,'Er');2.5;    

    % Optical pumping after pinning/unlevitate
%     seqdata.flags.lattice_do_optical_pumping    = 0; 

    % plane selection settings
%     seqdata.flags.plane_selection_douWave       = 0; 
%     seqdata.flags.plane_selection_doKill        = 0;
%     seqdata.flags.plane_selection_doLFKill      = 0;
    
%     defVar('qgm_LF_kill_time',[3],'ms');3;10;5;
%     defVar('qgm_LF_kill_detuning',[26],'MHz');41;36;% 2024/05/07 35 MHz for 120 Er; 2024/07/08 30 MHz 250 ER, 41 MHz 70 ER
%     defVar('qgm_LF_kill_power',[0.5],'V');.01;.02;

end

%% Create Job File

out = struct;
out.SequenceFunctions   = {...
    @main_settings,...
    @one_plane,...
    @main_sequence};
out.CycleEnd   = 13;npt.NumCycles;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName             = ['Center Plane Scan ' num2str(1e3*0.055) ' mW, '  num2str(201.107) ' G, ' num2str(30) 'kHz sweep'];
out.SaveDir         = out.JobName;  
%% Output Job File
J = sequencer_job(out);

end

