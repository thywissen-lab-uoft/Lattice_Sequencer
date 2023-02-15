classdef sequencer_job < handle
% Author : CJ Fujiwara
%
% This class contains jobs to run on the adwin.  A single job can have
% multiple scandincides, but only refers to a single set of sequence file.
% This is essentially a glorified struct

properties        
    SequenceFunctions  
    ScanCyclesRequested  
    ScanCyclesCompleted
    ScanCycle
    JobName
    SaveDirName
    ExecutionDates
    Status
    CycleStartFcn
    CycleCompleteFcn
    JobCompleteFcn
end    
events

end

methods
   
% contructor
% function obj = sequencer_job(SequenceFunctions,JobName,...
%         ScanCyclesRequested)    
%     if nargin == 2
%         ScanCyclesRequested = [];
%     end
%     obj.JobName             = JobName;            
%     obj.SequenceFunctions   = SequenceFunctions;
%     obj.ScanCyclesRequested = ScanCyclesRequested;
%     obj.ScanCyclesCompleted = [];    
%     obj.ScanCycle           = [];
%     obj.ExecutionDates      = [];
%     obj.SaveDirName         = [];
%     obj.Status              = 'pending';
% end    

function obj = sequencer_job(npt)    
  
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
end

end
end

