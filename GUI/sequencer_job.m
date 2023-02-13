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
    SequencerWatcher  
    continueRunning        
    lh
    ExecutionDates
    Status
    UserCycleCompleteFcn;
    UserJobCompleteFcn;
end    
events
    CycleComplete
    JobComplete
end

methods
   

function obj = sequencer_job(SequenceFunctions,JobName,...
        ScanCyclesRequested)    
    if nargin == 2
        ScanCyclesRequested = [];
    end
    obj.SequencerWatcher    = obj.findSequencerWatcher;
    obj.JobName             = JobName;            
    obj.SequenceFunctions   = SequenceFunctions;
    obj.ScanCyclesRequested = ScanCyclesRequested;
    obj.ScanCyclesCompleted = [];    
    obj.ScanCycle           = [];
    obj.ExecutionDates      = [];
    obj.Status              = 'pending';
    
    obj.UserCycleCompleteFcn = @(x) disp('hi1');
    obj.UserJobCompleteFcn   = @(x) disp('hi2');
end    

function JobCompleteFcn(obj)        
    obj.Status              = 'complete';
    obj.notify('JobComplete');
    for kk=1:length(obj.ExecutionDates)
       disp(datestr(obj.ExecutionDates(kk)) )
    end
    
    % Execute User function here
    obj.UserJobCompleteFcn(obj);
end



function CycleCompleteFcn(obj)        
    delete(obj.lh);         
    % Increment cycles completed
    obj.ScanCyclesCompleted(end+1) = obj.ScanCycle;           
    cycles_left = setdiff(obj.ScanCyclesRequested,...
        obj.ScanCyclesCompleted);            
    if ~obj.continueRunning
        obj.Status = 'pending';        
    end    
    
    % Execute User function here
    obj.UserCycleCompleteFcn(obj);
    
    obj.notify('CycleComplete');
    if obj.continueRunning            
        if isempty(cycles_left) 
            obj.JobCompleteFcn;
        else
            obj.start;
        end
    end

end

function SequencerWatcher=findSequencerWatcher(obj)
    figs = get(groot,'Children');
    fig = [];
    for i = 1:length(figs)
        if isequal(figs(i).UserData,'sequencer_gui')        
            fig = figs(i);
        end
    end             
    d=guidata(fig);            
    SequencerWatcher = d.SequencerWatcher;
end

function stop(obj)
   obj.continueRunning = 0;
   obj.Status = 'stopping';
   disp('stopping job');
end

% Start this sequence
function start(obj)
    
    if obj.SequencerWatcher.isRunning
       warning('sequencer already running');              
       return;
    end
    
    obj.Status = 'running';            
    obj.continueRunning = 1;
    cycles_left = setdiff(obj.ScanCyclesRequested,...
        obj.ScanCyclesCompleted);

    if isempty(cycles_left)
        error('no more runs to do');
    end                   
    
    opts=struct;
    opts.ScanCycle = cycles_left(1);         

    obj.ScanCycle = opts.ScanCycle;

    global seqdata
    seqdata.scancycle = obj.ScanCycle;
    seqdata.sequence_functions = obj.SequenceFunctions;

    t=runSequence(obj.SequenceFunctions,opts);              
    obj.ExecutionDates(end+1) = t;
    obj.lh=listener(obj.SequencerWatcher,'CycleComplete',@(src, evt) obj.CycleCompleteFcn);
end

function delete(this)
    % delete any listeners
end
end
end

