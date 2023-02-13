classdef job_handler < handle
% Author : CJ Fujiwara
%
% This can organizers and tracks all jobs which are run on the
% sequencer.

properties        
    CurrentJob
    SequencerJobs
    ListenerJob
    ListenerCycle
    TextBox
end    
events
   BatchComplete
end

methods
    
% constructor
function obj = job_handler(gui_handle)           
    obj.SequencerJobs={};            
    d=guidata(gui_handle);          
    obj.TextBox = d.JobTable;
    obj.updateJobText;
end   

% function that updates the job table
function updateJobText(obj)
    if isempty(obj.SequencerJobs)
       obj.TextBox.Data={};
    else
        for kk = 1:length(obj.SequencerJobs)
            funcs=obj.SequencerJobs{kk}.SequenceFunctions;
            mystr =[];
            for ii = 1:length(funcs)
                mystr = [mystr '@' func2str(funcs{ii}) ','];
            end
            mystr(end)=[];

            obj.TextBox.Data{kk,2} = obj.SequencerJobs{kk}.Status;
            obj.TextBox.Data{kk,3} = ...
                [num2str(length(obj.SequencerJobs{kk}.ScanCyclesCompleted)) ...
                '/' num2str(length(obj.SequencerJobs{kk}.ScanCyclesRequested))];
            obj.TextBox.Data{kk,4} = obj.SequencerJobs{kk}.JobName;
            obj.TextBox.Data{kk,5} = mystr;                
        end
    end
end

% Add job to list
function addJob(obj,job)
    obj.SequencerJobs{end+1} = job;
    obj.updateJobText;
end

% Clear all jobs
function clearJobs(obj)
    for kk=1:length(obj.SequencerJobs)
       delete(obj.SequencerJobs{kk}); 
    end
    obj.SequencerJobs={};
    obj.updateJobText;
end

% chekcs to see if the jobs are idle
function val = isIdle(obj)
    val = 1;
    for kk=1:length(obj.SequencerJobs)
        status = obj.SequencerJobs{kk}.Status;        
        switch status
            case 'complete'
            case 'pending'
            case 'running'
                val = 0;
                str = ['Job ' num2str(kk) ' is currently running.'];
                warning(str);
                return;
            case 'stopping'
                val = 0;
                str = ['Job ' num2str(kk) ' is currently stopping.'];
                warning(str);
                return;
            otherwise
                error('unknown status');
        end  
    end   
end

% Start or continue job
function start(obj)      
    % Check if any jobs are running or if sequencer is currently running
    if ~obj.isIdle
       return; 
    end    
    
    % Find the first non complete job
   for kk=1:length(obj.SequencerJobs)
       if isequal(obj.SequencerJobs{kk}.Status,'pending')
         obj.CurrentJob = obj.SequencerJobs{kk};
         obj.CurrentJob.start;
          obj.ListenerJob=listener(obj.CurrentJob,...
            'JobComplete',@(src, evt) obj.CurrentJobComplete);
          obj.ListenerCycle=listener(obj.CurrentJob,...
              'CycleComplete',@(src, evt) obj.CycleComplete);
          obj.updateJobText;
          return
       end
   end
   warning('no more uncompleted jobs to run');
end

function CycleComplete(obj)
    obj.updateJobText;
end

% Execute at end of current job
function CurrentJobComplete(obj)
    delete(obj.ListenerJob);   
    delete(obj.ListenerCycle);   
    obj.CurrentJob = [];
    obj.start;
end

% Stop request
function stop(obj)
    if ~isempty(obj.CurrentJob)
       obj.CurrentJob.stop 
    end
    obj.updateJobText;
end                

% delete me
function delete(obj)
    % delete any listeners
    obj.clearJobs;
    obj.updateJobText;
end

end

end

