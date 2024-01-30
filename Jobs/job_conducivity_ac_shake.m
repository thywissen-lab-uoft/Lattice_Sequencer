function J=job_conducivity_ac_shake
    function curtime = bob(curtime,var)
        global seqdata;
        
        field = var;
        defVar('conductivity_FB_field',field,'G');
       
        freq = 54;
        defVar('conductivity_mod_freq',freq,'Hz');  
        
        defVar('Evap_End_Power',0.08,'W');
        
        t0 = 50;
        T = 1e3/freq;
        tvec = round(t0 + linspace(0,3*T,30),1);
        defVar('conductivity_mod_time',tvec,'ms');      % Modulation Time
    end

    function curtime = bob2(curtime,var)
        global seqdata;
        
%         field = 170;
%         defVar('conductivity_FB_field',field,'G');
       
        freq = var;
        defVar('conductivity_mod_freq',freq,'Hz');  
        
%         defVar('Evap_End_Power',0.075,'W');
        
        t0 = 50;
        T = 1e3/freq;
        tvec = round(t0 + linspace(0,3*T,25),1);
        defVar('conductivity_mod_time',tvec,'ms');      % Modulation Time
    end

% This function evaluates at the end of each cycle
    function cycleComplete
    end

% This function evaluates at the start of each cycle
    function cycleStart
    end

% This function evaluates at the end of the job
    function jobComplete
    end

    function overridetoDFG(curtime)
        global seqdata
        seqdata.flags.lattice = 0;
        defVar('tof',25,'ms');
    end
%%

var_list = [20:10:160];
var_list = var_list(randperm(numel(var_list)));
clear J
for ii = 1:length(var_list)
    x = var_list(ii);
    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) bob2(curtime,x),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;

%     if B>=200.5
%         npt.ScanCyclesRequested = 1:41;
%     else
        npt.ScanCyclesRequested = 1:25;
%     end
    npt.JobName             = [num2str(ii) ' 2.5Er Modulate ' num2str(x)];
    npt.SaveDirName         = npt.JobName;    
    J(ii) = sequencer_job(npt);
end
    
end

