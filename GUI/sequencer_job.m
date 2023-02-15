classdef sequencer_job < handle
% Author : CJ Fujiwara
%
% This class contains jobs to run on the adwin.  A single job can have
% multiple scandincides, but only refers to a single set of sequence file.

properties        
    SequenceFunctions  
    ScanCyclesRequested  
    ScanCyclesCompleted
    ScanCycle
    Options   
    JobName
    ImageSaveDirectory
    ExecutionDates
    Status
end    
events

end

methods
   
% contructor
function obj = sequencer_job(SequenceFunctions,JobName,...
        ScanCyclesRequested)    
    if nargin == 2
        ScanCyclesRequested = [];
    end
    obj.JobName             = JobName;            
    obj.SequenceFunctions   = SequenceFunctions;
    obj.ScanCyclesRequested = ScanCyclesRequested;
    obj.ScanCyclesCompleted = [];    
    obj.ScanCycle           = [];
    obj.ExecutionDates      = [];
    obj.Status              = 'pending';
end    

% function that evaluates upon job completion
function JobCompleteFcn(obj)        
    disp('job done');
end

% function that evaluates upon cycle completion
function CycleCompleteFcn(obj)        
    disp('cycle done');
end

end
end

