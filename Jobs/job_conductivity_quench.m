function J=job_conductivity_quench
    function curtime = bob(curtime,field)
        global seqdata;
        defVar('conductivity_FB_field',field,'G');
        
%         if field>=200.5
%             defVar('conductivity_snap_and_hold_time',[0:1:40],'ms');
%         else
    defVar('lattice_depth_load',1.5,'Er');
        defVar('conductivity_snap_and_hold_time',[0 2.5 5 7.5 10 15:5:150],'ms');
%         end

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
%  field_list = [195 195 197 200 200.2 200.4 200.5 200.7 200.8 200.9 201 201.1 201.2 201.3 201.4 201.5];
% field_list = [201.35 201.4 201.45 201.5 201.55 201.6];
%field_list = [201.3 201.4 201.5 201.6];
field_list = [170 180 185 190 195 196 197 198 199 200];
clear J
for ii = 1:length(field_list)
    B = field_list(ii);
    
    npt = struct;   
    npt.SequenceFunctions   = {@main_settings,@(curtime) bob(curtime,B),@main_sequence};
%     npt.CycleStartFcn       = @cycleStart;
%     npt.CycleCompleteFcn    = @cycleComplete;
%     npt.JobCompleteFcn      = @jobComplete;

%     if B>=200.5
%         npt.ScanCyclesRequested = 1:41;
%     else
        npt.ScanCyclesRequested = 1:33;
%     end
    npt.JobName             = [num2str(ii) ' 2.5Er Quench ' num2str(B)];
    npt.SaveDirName         = npt.JobName;    
    J(ii) = sequencer_job(npt);
end
    
end

