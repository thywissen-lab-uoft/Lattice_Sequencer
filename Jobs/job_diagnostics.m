function J=job_diagnostics


% %% RF1B K 
% 
%     function curtime = seq_mod_1(curtime)
%         global seqdata;
%         seqdata.flags.lattice   = 0;
%         seqdata.flags.xdt       = 0;      
%         defVar('tof',5);
%     end
% 
% npt=struct;
% npt.SequenceFunctions   = {@main_settings,@seq_mod_1,@main_sequence};
% npt.JobName             = 'K RF1B stats';
% npt.ScanCyclesRequested = [1:10];
% npt.SaveDirName         = 'K RF1B stats';
% 
% j1 = sequencer_job(npt);
% 
% %% XDT Load K 
% 
%     function curtime = seq_mod_1a(curtime)
%         global seqdata;
%         seqdata.flags.lattice   = 0;
%         seqdata.flags.xdt       = 1;      
%         
%         seqdata.flags.xdt_Rb_21uwave_sweep_field    = 0;    
%         seqdata.flags.xdt_Rb_21uwave_sweep_freq     = 0;   
%         seqdata.flags.xdt_K_p2n_rf_sweep_freq       = 0;     
%         seqdata.flags.xdt_d1op_start                = 0;    
%         seqdata.flags.xdt_rfmix_start               = 0;        
%         seqdata.flags.xdt_kill_Rb_before_evap       = 0;  
%         seqdata.flags.xdt_kill_K7_before_evap       = 0;   
%         seqdata.flags.CDT_evap                      = 0;            
%         defVar('tof',15);
%     end
% 
% npt=struct;
% npt.SequenceFunctions   = {@main_settings,@seq_mod_1a,@main_sequence};
% npt.JobName             = 'K XDT load stats';
% npt.ScanCyclesRequested = [1:10];
% npt.SaveDirName         = 'K XDT load stats';
% 
% j1a = sequencer_job(npt);
% 
% %% XDT Load K 
% 
%     function curtime = seq_mod_1b(curtime)
%         global seqdata;
%         seqdata.flags.lattice   = 0;
%         seqdata.flags.xdt       = 1;      
%         
%         seqdata.flags.xdt_Rb_21uwave_sweep_field    = 1;    
%         seqdata.flags.xdt_Rb_21uwave_sweep_freq     = 0;   
%         seqdata.flags.xdt_K_p2n_rf_sweep_freq       = 1;     
%         seqdata.flags.xdt_d1op_start                = 1;    
%         seqdata.flags.xdt_rfmix_start               = 1;        
%         seqdata.flags.xdt_kill_Rb_before_evap       = 0;  
%         seqdata.flags.xdt_kill_K7_before_evap       = 0;   
%         seqdata.flags.CDT_evap                      = 0;            
%         defVar('tof',15);
%     end
% 
% npt=struct;
% npt.SequenceFunctions   = {@main_settings,@seq_mod_1b,@main_sequence};
% npt.JobName             = 'K XDT load post spin manip';
% npt.ScanCyclesRequested = [1:10];
% npt.SaveDirName         = 'K XDT load post spin manip';
% 
% j1a = sequencer_job(npt);


% %% XDT LF DFG TOF
%     function curtime = seq_mod_3(curtime)
%         global seqdata;
%         seqdata.flags.xdt       = 1;        
%         defVar('tof',25);
%     end
% 
% npt=struct;
% npt.SequenceFunctions   = {@main_settings,@seq_mod_3,@main_sequence};
% npt.JobName             = 'LF DFG stats';
% npt.ScanCyclesRequested = [1:10];
% npt.SaveDirName         = 'LF DFG stats';
% 
% j3 = sequencer_job(npt);

%% XDT LF DFG TOF
    function curtime = seq_mod_3(curtime)
        global seqdata;
        seqdata.flags.xdt       = 1;        
        defVar('tof',25);
    end

npt=struct;
npt.SequenceFunctions   = {@main_settings,@seq_mod_3,@main_sequence};
npt.JobName             = 'LF DFG stats';
npt.ScanCyclesRequested = [1:10];
npt.SaveDirName         = 'LF DFG stats';


%% Add jobs to handler
% J = [j1 j2 j3];

end

