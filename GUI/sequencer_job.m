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
    obj.SequencerWatcher = obj.findSequencerWatcher;
    obj.JobName = JobName;            
    obj.SequenceFunctions = SequenceFunctions;
    obj.ScanCyclesRequested = ScanCyclesRequested;
    obj.ScanCyclesCompleted = [];    
    obj.ScanCycle = [];
    obj.ExecutionDates = [];
    obj.Status = 'pending';
end    

function JobCompleteFcn(obj)        
    obj.Status = 'complete';
    obj.notify('JobComplete');
    for kk=1:length(obj.ExecutionDates)
       disp(datestr(obj.ExecutionDates(kk)) )
    end
end

function CycleCompleteFcn(obj)               
    obj.ScanCyclesCompleted(end+1) = obj.ScanCycle;           
    cycles_left = setdiff(obj.ScanCyclesRequested,...
        obj.ScanCyclesCompleted);        
    obj.notify('CycleComplete');

    delete(obj.lh);     
    if obj.continueRunning            
        if isempty(cycles_left) 
            obj.JobCompleteFcn;
        else
            obj.start;
        end
    else
        obj.Status = 'stopped';
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

function start(obj)
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

    t=runSequence(obj.SequenceFunctions,opts);              
    obj.ExecutionDates(end+1) = t;
    obj.lh=listener(obj.SequencerWatcher,'CycleComplete',@(src, evt) obj.CycleCompleteFcn);
end

function delete(this)
    % delete any listeners
end
end
end

