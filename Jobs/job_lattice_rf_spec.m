function J = job_lattice_rf_spec

%% Lattice RF spectroscopy sequence modifier

% IN PROGRESS DO NOT USE This is BAD, rewrite later

 function curtime = rf_spec(curtime,field)
        global seqdata;        
        
%         % Set the evap depth
%         defVar('xdtB_evap_power',evap_depth,'W');
        
        % RF mix atoms to produce doublons
        seqdata.flags.xdtB_rf_mix                   = 1;
        seqdata.flags.xdtB_rf_mix_post_evap         = 1;
%         seqdata.flags.lattice_load_xdt_off        = 0; 
%         
%         % Set the final powers of the XDTs
%         seqdata.flags.xdtB_ramp_power_end           = 1;
%         defVar('xdtB_evap_end_ramp_power', ODT1_power,'W'); 0.198;
%         defVar('xdtB_evap_end_ramp_power2', ODT2_power,'W'); 0.088;
%         
%         % Set the lattice load depths
%         defVar('lattice_load_depthX',4,'Er');2.5;
%         defVar('lattice_load_depthY',4,'Er');2.5;
%         defVar('lattice_load_depthZ',4,'Er');
        
        % Enable Raman spec
        seqdata.flags.lattice_raman_spec            = 1;

        % Ramp field to RF spec field
        seqdata.flags.lattice_field_ramp_post_spec  = 1;
        defVar('lattice_post_spec_feshbach_time',100,'ms');
        defVar('lattice_post_spec_feshbach_field',[field],'G');20;131.98;
        defVar('lattice_post_spec_feshbach_holdtime',[0],'ms');

        seqdata.flags.lattice_RF_spectroscopy       = 1;

        defVar('lattice_RF_spec_frequency_offset',[-85:1.5:5],'kHz');
        defVar('lattice_RF_spec_sweep_range',[2.5],'kHz');  
        defVar('lattice_RF_spec_time',[10],'ms');   1;
        defVar('lattice_RF_spec_power',[5],'dBm');

 end
%% AC Conductivity Job
clear J

% Magnetic Field (G)
B_list = [132.06:.01:132.11]-0.107;

for ii = 1:length(B_list)
    B = B_list(ii);
    out = struct;   
    out.SequenceFunctions   = {@main_settings,@(curtime) ...
        rf_spec(curtime,B),@main_sequence};
    out.CycleEnd = 61;
    out.WaitMode = 2;
    out.WaitTime = 90;
    out.JobName             = ['Lattice RF spec 100 Er, ' num2str(B) ' G, '...
        '65 mW evap, 4 Er load, HS1 10 ms 2.5 kHz 5 dBm sweep'];
    out.SaveDir         = out.JobName;    
    J(ii) = sequencer_job(out);
end
end

