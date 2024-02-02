classdef job_handler < handle
% JOB_HANDLER Creates handler which manages multiple jobs of the adwin
% sequencer. This includes different seqeunce files, flags, variables, and
% special functions.  This is useful when trying to do batch runs of the
% experimental cycle or when attempting to closed feedback of the
% experiment for automated machine optimization.
%
% Author : CJ Fujiwara
%
% Only one of these objects should be active at a given time.  This object
% should automatically be created when the mainGUI is called. An instance
% should be added to the main MATLAB workspace as jh.
%
% You can run this code from the GUI or from the command line with
% functions such as jh.start, jh.add(job), jh.clear(job), jh.stop.
%
%   See also START, ADD, CLEAR, STOP, MAINGUI, SEQUENCER_JOB
properties        
    CurrentJob          % current active sequencer job
    SequencerJobs       % array of sequencer jobs to run
    ListenerCycle       % listener object for adwin cycle complete
    TextBox             % text table to update job progress
    SequencerWatcher    % sequencer_watcher which watches the adwin
    doIterate           % boolean to continue running jobs
end    
events
   
end

methods
    
function obj = job_handler(gui_handle)          
% constructor
    obj.SequencerJobs={};            
    d=guidata(gui_handle);          
    obj.TextBox = d.JobTable;
    obj.updateJobText;
    obj.SequencerWatcher = d.SequencerWatcher;
end   

function start(obj,job)      
% START hello
% 
% This function
    if ~obj.isIdle
       return; 
    end
        
    % Find first pending job if none specified
    if nargin == 1
       job = obj.findNextJob;
    end
    
    % Check to see if job is object or number
    if ~isequal(class(job),'sequencer_job') && isnumeric(job)
        job = obj.SequencerJobs{job};
    end
    
    % Check if sequencer is alrady running
    if obj.SequencerWatcher.isRunning
       warning('sequencer already running');              
       return;
    end
    
    % Update current job
    obj.CurrentJob = job;
    
    % Cycle remaining in this job
    cycles_left = setdiff(job.ScanCyclesRequested,job.ScanCyclesCompleted);
    
    % No more cycles, run the job complete fcn
    if isempty(cycles_left)
        obj.JobCompleteFcn;
        return;
    end
    
    % Update the job
    job.Status = 'running';
    obj.updateJobText;

    job.ScanCycle = cycles_left(1);
    global seqdata
    seqdata.scancycle = job.ScanCycle;
    seqdata.sequence_functions = job.SequenceFunctions;
    t=runSequence(job.SequenceFunctions,@job.CycleStartFcnWrapper);              
    job.ExecutionDates(end+1) = t;
    
    % Get ready to wait for job to finish
    obj.ListenerCycle=listener(obj.SequencerWatcher,'CycleComplete',...
        @(src, evt) obj.CycleCompleteFcn);
    obj.doIterate   = true;
end

function JobCompleteFcn(obj)
% Evaluates at the end of the job. This handles graphical calls and also
% excutes any user defind functions in the sequencer_job

    obj.CurrentJob.Status = 'job end';
    obj.updateJobText;
    
    % Run User job funcion
    obj.SequencerWatcher.StatusStr.String = 'evaluating job end function';
    obj.SequencerWatcher.StatusStr.ForegroundColor = [220,88,42]/255;
    obj.CurrentJob.JobCompleteFcnWrapper;
    obj.SequencerWatcher.StatusStr.String = 'idle';
    obj.SequencerWatcher.StatusStr.ForegroundColor = [0 128 0]/255;
    
    % Ending Stuff
    obj.CurrentJob.Status = 'complete';
    obj.CurrentJob = [];
    obj.updateJobText;
     
    % Insert check on buttons
    if obj.doIterate && ~isempty(obj.findNextJob)
        obj.start;
    end        
end

function CycleCompleteFcn(obj)    
% Evaluates at the end of the cycle. This handles graphical calls and also
% excutes any user defind functions in the sequencer_job

    delete(obj.ListenerCycle);      % delete listerner   
    job = obj.CurrentJob;           % get the current job

    % Increment cycles completed
    job.ScanCyclesCompleted(end+1) = job.ScanCycle;           
        
    % Execute User function here        
    obj.SequencerWatcher.StatusStr.String = 'evaluating job end function';
    obj.SequencerWatcher.StatusStr.ForegroundColor = [220,88,42]/255;
    obj.CurrentJob.Status = 'cycle end';
    obj.updateJobText;
    obj.CurrentJob.CycleCompleteFcnWrapper;       
    obj.CurrentJob.Status = 'pending';
    obj.updateJobText;
    obj.SequencerWatcher.StatusStr.String = 'idle';
    obj.SequencerWatcher.StatusStr.ForegroundColor = [0 128 0]/255;
    
    % Insert check on buttons
    if ~obj.doIterate
        obj.CurrentJob.Status='pending';
        obj.CurrentJob = [];
        obj.updateJobText;
        return;
    end        
    
    % Check if any more runs to do
    cycles_left = setdiff(job.ScanCyclesRequested,...
        job.ScanCyclesCompleted);  
    if isempty(cycles_left) 
        obj.JobCompleteFcn;     % Finish job
    else
        obj.start(job);        % Continue job        
    end
end

% Add job to list
function add(obj,job)
    for kk=1:length(job)
        obj.SequencerJobs{end+1} = job(kk);
        obj.updateJobText;
    end
end

% Stop Current Job
function stop(obj)
    obj.doIterate   = false;
    if ~isempty(obj.CurrentJob)
       obj.CurrentJob.Status = 'stopping';
    end
    obj.updateJobText;
end   

% Clear all jobs
function clear(obj)
    if ~isIdle(obj)
       warning('Cannot clear jobs until idle. Stopping jobs instead.');
       obj.stop;
       return;
    end
    
    for kk=1:length(obj.SequencerJobs)
       delete(obj.SequencerJobs{kk}); 
    end
    obj.SequencerJobs={};
    obj.CurrentJob = [];
    obj.updateJobText;
end

% Function that updates the job table
function updateJobText(obj)
    if isempty(obj.SequencerJobs)
       obj.TextBox.Data={};
    else
        for kk = 1:length(obj.SequencerJobs)
            funcs=obj.SequencerJobs{kk}.SequenceFunctions;
            mystr =[];
            for ii = 1:length(funcs)
                mystr = [mystr func2str(funcs{ii}) ','];
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

% Check if job handler is idle
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
            case 'cycle end'
                val = 0;
                str = ['Job ' num2str(kk) ' is cycle end function'];
                warning(str);
                return;
            case 'job end'
                val = 0;
                str = ['Job ' num2str(kk) ' is job end function'];
                warning(str);
                return;
            otherwise
                error('unknown status');
        end  
    end   
end

% Find next job that is pending
function job = findNextJob(obj)
    job = [];
   for kk=1:length(obj.SequencerJobs)
       if isequal(obj.SequencerJobs{kk}.Status,'pending')
            job = obj.SequencerJobs{kk};
            return
       end
   end
end


% delete me
function delete(obj)
    % delete any listeners
    obj.clear;
    obj.updateJobText;
end

end

end

