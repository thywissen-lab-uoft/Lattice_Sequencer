function J=job_conducivity_ac_shake
    function curtime = ac_conductivity(curtime,freq,field,evap_depth)
        global seqdata;        
        % Define field, frequency, and evaporation depth
        defVar('conductivity_FB_field',field,'G');       
        defVar('conductivity_mod_freq',freq,'Hz');          
        defVar('Evap_End_Power',evap_depth,'W');
        
        % Modulation time vector
        t0 = 50;
        T = 1e3/freq;
        tvec = round(t0 + linspace(0,3*T,25),1);
        defVar('conductivity_mod_time',tvec,'ms');      
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

%%
var_list = [20:10:160];
var_list = var_list(randperm(numel(var_list)));
clear J
for ii = 1:length(var_list)
    f = var_list(ii);
    B = 195;
    pow = 0.085;    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) ac_conductivity(curtime,x),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;


    npt.ScanCyclesRequested = 1:25;
    npt.JobName             = [num2str(ii) ' ' num2str(f) ' Hz,' ...
        num2str(B) 'G,' num2str(1e3*pow) ' mW'];
    npt.SaveDirName         = npt.JobName;    
    J(ii) = sequencer_job(npt);
end
    
end

