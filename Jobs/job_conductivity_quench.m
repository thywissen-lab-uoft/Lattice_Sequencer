function J=job_conductivity_quench
    function curtime = bob(curtime,var)
        global seqdata;
        
        field = var;
        defVar('conductivity_FB_field',field,'G');
       
%         freq = 54;
%         defVar('conductivity_mod_freq',freq,'Hz');    
%         
%         defVar('Evap_End_Power',0.075,'W');
% 
%         t0 = 50;
%         T = 1e3/freq;
%         tvec = round(t0 + linspace(0,3*T,30),1);
%         defVar('conductivity_mod_time',tvec,'ms');      % Modulation Time
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

var_list = [170 175 180 185 190 195 196 197 198 199 200];
var_list = [170 var_list(randperm(numel(var_list)))];
clear J
for ii = 1:length(var_list)
    x = var_list(ii);
    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) bob(curtime,x),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;

%     if B>=200.5
%         npt.ScanCyclesRequested = 1:41;
%     else
        npt.ScanCyclesRequested = 1:40;
%     end
    npt.JobName             = [num2str(ii) ' 2.5Er 2V 2V Quench ' num2str(x)];
    npt.SaveDirName         = npt.JobName;    
    J(ii) = sequencer_job(npt);
end
    
end

