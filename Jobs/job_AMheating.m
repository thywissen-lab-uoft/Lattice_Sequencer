function J=job_AMheating
%% Trap Frequency Measurement w/ AM heating Sequence Modifier
 function curtime = trapfreq_heat(curtime,ODT1_power,ODT2_power,field,evap_depth,UX,UY,UZ,uwave_freq_amp)
        global seqdata;        
        
        %Set the evap depth
        defVar('xdtB_evap_power',evap_depth,'W');
        
        %Keep atoms spin-polarized
        seqdata.flags.xdtB_rf_mix                   = 0;
        seqdata.flags.xdtB_rf_mix_post_evap         = 0;
        
        %Set the final powers of the XDTs
        seqdata.flags.xdtB_ramp_power_end           = 1;
        defVar('xdtB_evap_end_ramp_power', ODT1_power,'W'); 0.195;
        defVar('xdtB_evap_end_ramp_power2', ODT2_power,'W'); 0.150;
        
        %Set the lattice depths
        defVar('lattice_load_depthX',UX,'Er');2.5;
        defVar('lattice_load_depthY',UY,'Er');2.5;
        defVar('lattice_load_depthZ',UZ,'Er');2.5;
        
        %Set the field
        seqdata.flags.lattice_load_feshbach_ramp  = 1;
        defVar('lattice_load_feshbach_field',field,'G'); 
        
        %Set the displacement parameters       
        seqdata.flags.lattice_conductivity_new      = 0;  
        
        % AM Spec
        seqdata.flags.do_lattice_am_spec            = 1;    % Amplitude modulation spectroscopy   
        defVar('AM_spec_mod_amp',[14],'Vpp');
        defVar('AM_spec_freq',[70 80 145 160 170],'Hz');%107.5:5:192.5;154.1;
        defVar('AM_spec_time',[800],'ms');
       
        
        % Plane Selection
        seqdata.flags.plane_selection_dotilt        = 0;
        defVar('qgm_plane_uwave_frequency_amplitude_notilt',uwave_freq_amp,'kHz');
        d = load('f_offset.mat');
        f_offset = d.f_offset; 
        defVar('f_offset',f_offset,'kHz'); 
 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
B = 201.1;
B = 195;

%Set final powers of ODTs in W
ODT1_power = 0.195;
ODT2_power = 0.150;

%Choose Lattice Depths
depthX = 2.5;
depthY = 2.5;
depthZ = 2.5;

% Optical Evaporation Power (W)
evap_depth = 0.065;


%Choose the number of planes via uwave freq amplitude
uwave_freq_amp = 60;

out = struct;   
out.SequenceFunctions   = {@main_settings,@(curtime) ...
    trapfreq_heat(curtime,ODT1_power,ODT2_power,B,evap_depth,...
    depthX,depthY,depthZ,uwave_freq_amp),@main_sequence};
out.CycleEnd = 10;
out.WaitMode = 2;
out.WaitTime = 90;
out.JobName             = ['Heat trap freq, ODTs (' num2str(ODT1_power*1e3) ',' num2str(ODT2_power*1e3) ') mW, (' ...
    num2str(depthX) ',' num2str(depthY) ',' num2str(depthZ), ') Er, ' num2str(B) ' G, ' num2str(1e3*evap_depth) ' mW'];
out.SaveDir         = out.JobName;    
J = sequencer_job(out);

end

