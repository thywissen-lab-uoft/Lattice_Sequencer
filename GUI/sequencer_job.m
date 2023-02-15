classdef sequencer_job < handle
% sequencer_job This class contains jobs to run on the adwin.  A single job can have
% multiple scandincides, but only refers to a single set of sequence file.
% This is essentially a glorified struct
%
% Author : CJ Fujiwara
%
% Most properties are self explainatory with the exception of the custom
% user functions. CycleStartFcn, CycleCompleteFcn, JobCompleteFcn.  These
% functions are particularly useful if you want to do feedback on the
% machine after each run or set of runs.
%
% Because only one sequence may be run at a time, sequencer_jobs may only
% be excuted from an instance of the job_handler class.
%
% See also JOB_HANDLER, MAINGUI
properties        
    SequenceFunctions       % cell arary of sequence functions to evaluate
    ScanCyclesRequested     % array of scan cycle indices to run
    ScanCyclesCompleted     % array of scan cycle indices which have been complete so far
    ScanCycle               % which scan cycle will be run
    JobName                 % the name of the job
    SaveDirName             % the name of the directory to save images
    ExecutionDates          % the dates at which each sequence in the job is run
    Status                  % the current status of the job
    CycleStartFcn           % user custom function to evalulate before sequence runs
    CycleCompleteFcn        % user custom function to evaluate after the cycle
    JobCompleteFcn          % user custom function to evaluate when job is complete
    CameraFile              % camera control output file
end    
events

end

methods      

function obj = sequencer_job(npt)    
 
    obj.CameraFile = 'Y:\_communication\camera_control.mat';

    obj.JobName             = npt.JobName;            
    obj.SequenceFunctions   = npt.SequenceFunctions;
    obj.ScanCyclesRequested = npt.ScanCyclesRequested;
    obj.Status              = 'pending';

    obj.ScanCyclesCompleted = [];    
    obj.ScanCycle           = [];
    obj.ExecutionDates      = [];
    obj.SaveDirName         = [];
    obj.CycleStartFcn       = [];
    obj.CycleCompleteFcn    = [];
    obj.JobCompleteFcn      = [];

    
    if isfield(npt,'CycleStartFcn')
        obj.CycleStartFcn = @npt.CycleStartFcn; 
    end
    
    if isfield(npt,'JobCompleteFcn')
        obj.JobCompleteFcn = @npt.JobCompleteFcn; 
    end
    
    if isfield(npt,'CycleCompleteFcn')
        obj.CycleCompleteFcn = @npt.CycleCompleteFcn; 
    end
    
    if isfield(npt,'SaveDirName')
       obj.SaveDirName = npt.SaveDirName; 
    end    

end    

% function that evaluates upon job completion
function JobCompleteFcnWrapper(obj)  
    disp('Executing job complete function');
    pause(.1);
    
    if ~isempty(obj.JobCompleteFcn)
       obj.JobCompleteFcn(); 
    end
end

% function that evaluates upon cycle completion
function CycleCompleteFcnWrapper(obj)        
    disp('Executing cycle complete function.');
    pause(.1);
    if ~isempty(obj.CycleCompleteFcn)
        obj.CycleCompleteFcn(); 
    end
end

% function that evaluates upon after compitation but before run
function CycleStartFcnWrapper(obj)        
    disp('Executing cycle start function.');
    pause(.1);
    if ~isempty(obj.CycleStartFcn)
        obj.CycleStartFcn(); 
    end
    
    if ~isempty(obj.SaveDirName)
        SaveDir = obj.SaveDirName;
        try
            save(obj.CameraFile,'SaveDir');
        end
    end
end

end
end

