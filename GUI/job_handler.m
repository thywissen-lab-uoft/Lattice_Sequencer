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
    ListenerCycle       % listener object for when Cycle finishes
    ListenerAdwin       % listener object for when Adwin finishes
    TextBox             % text table to update job progress
    SequencerWatcher    % sequencer_watcher which watches the adwin
    doIterate           % boolean to continue running jobs
    DefaultJob          % The default job to run
    JobTabs         
    Cycle
    TableJobCycle
    TableJobOptions
    doHoldCycle
    doStopJobOnCycleComplete
    doStopQueueOnJobComplete
    doStartQueueOnDefaultJobCycleComplete
end    

events
   
end

methods
    
    % constructor
function obj = job_handler(gui_handle)          
    obj.SequencerJobs={};            
    d=guidata(gui_handle);          
    obj.TextBox = d.JobTable;
    obj.updateJobText;
    obj.SequencerWatcher = d.SequencerWatcher;
    obj.JobTabs = d.JobTabs;
    J_default = job_default;
    J_default.MakeTableInterface(obj.JobTabs);
    obj.DefaultJob = J_default;

    if isfield(d,'TableJobCycle')
        obj.TableJobCycle=d.TableJobCycle;
        obj.TableJobCycle.CellEditCallback=@obj.JobCycleCB;
    end
    if isfield(d,'TableJobOptions')
        obj.TableJobOptions=d.TableJobOptions;
        obj.TableJobOptions.CellEditCallback=@obj.JobOptionsCB;
    end
    obj.Cycle                                   = 1;
    obj.doHoldCycle                             = 0;
    obj.doStopJobOnCycleComplete                = 0;
    obj.doStopQueueOnJobComplete                = 0;
    obj.doStartQueueOnDefaultJobCycleComplete   = 0;
end

function JobOptionsCB(obj,src,evt)
    obj.doHoldCycle = src.Data{1,1};
    obj.doStopJobOnCycleComplete = src.Data{2,1};
    obj.doStopQueueOnJobComplete = src.Data{3,1};
    obj.doStartQueueOnDefaultJobCycleComplete = src.Data{4,1};
end

function JobCycleCB(obj,src,evt)   
    n = evt.NewData;
    if ~isnan(n) && isnumeric(n) && floor(n)==n && ~isinf(n) && n>0
        obj.Cycle = round(n);
    else
        src.Data = evt.PreviousData;
    end
end

function start(obj,job_type)     
    if ~obj.isIdle;return;end 
    if obj.SequencerWatcher.isRunning;return;end
    if nargin == 1;job_type = 'default';end

    % Get Job if you give it an index
    if isnumeric(job_type)
        job_index = job_type;
        if length(obj.SequencerJobs)>=job_index
            job_type = obj.SequencerJobs{job_index};
        end
    end

    % Different behavior if the second argin is a string
    switch class(job_type)
        case 'sequencer_job'
            job = job_type;            
        case 'char'
            switch job_type
                case 'default'
                    job = obj.DefaultJob;
                case 'queue'
                    job = obj.findNextJob;
                otherwise
                    error('Unexpected job type. Fix your code!');              
            end

        otherwise
            error('Unexpected job_type class. Fix your code!');
    end
    
    % Update current job
    obj.CurrentJob = job; 
    if job.CyclesCompleted>=job.CyclesRequested;obj.JobCompleteFcn;return;end   
    obj.runCurrentJob();    
end

function runCurrentJob(obj)
    job=obj.CurrentJob;
    job.Status = 'running';
    obj.updateJobText; 
    global seqdata
    seqdata.scancycle = job.CyclesCompleted+1;
    seqdata.sequence_functions = job.SequenceFunctions;
    t=runSequence(job.SequenceFunctions,@job.CycleStartFcnWrapper);              
    job.ExecutionDates(end+1) = t;
    % Get ready to wait for job to finish
    obj.ListenerCycle=listener(obj.SequencerWatcher,'CycleComplete',...
        @(src, evt) obj.CycleCompleteFcn);
    obj.ListenerAdwin=listener(obj.SequencerWatcher,'AdwinComplete',...
        @(src, evt) obj.AdwinCompleteFcn);
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
    obj.SequencerWatcher.StatusStr.String = 'sequencer idle';
    obj.SequencerWatcher.StatusStr.ForegroundColor = [0 128 0]/255;
    
    % Ending Stuff
    obj.CurrentJob.Status = 'complete';
    obj.CurrentJob.isComplete = true;
    obj.CurrentJob = [];
    obj.updateJobText;
     
    % Insert check on buttons
    if obj.doIterate && ~isempty(obj.findNextJob)
        obj.start;
    end        
end

% Evaluates when the Adwin is complete
function AdwinCompleteFcn(obj)
    delete(obj.ListenerAdwin);                      % Delete Listener
    obj.CurrentJob.Status = 'AdwinComplete';

    % Increment Cycles Completed
    if ~obj.doHoldCycle
        obj.CurrentJob.CyclesCompleted = obj.CurrentJob.CyclesCompleted+1;   
    end    
    obj.updateJobText;
    obj.CurrentJob.CycleCompleteFcnWrapper;         % Evalvulate job.CycleCompleteFcn

    if obj.CurrentJob.CyclesCompleted>=obj.CurrentJob.CyclesRequested
        obj.CurrentJob.isComplete = true;
        obj.CurrentJob.Status = 'JobCompleteFcn';
        obj.JobCompleteFcn;
        obj.CurrentJob.Status = 'Finished';
    end
    obj.updateJobText;
end

% Evaluates when the Cycle (Adwin+Wait) is complete
function CycleCompleteFcn(obj)    
    delete(obj.ListenerCycle);          % delete Listener   
    if obj.doStopJobOnCycleComplete
        obj.stop();
        return;
    end
    if (obj.doStopQueueOnJobComplete && obj.CurrentJob.isComplete)
        obj.stop();
        return;
    end
    if (obj.doStartQueueOnDefaultJobCycleComplete)
        obj.start('queue');
        return;
    end
    obj.start('default'); 
end

function addJobGUI(obj,startdir)
    if nargin==1
        startdir=pwd;
    end
    fstr='Add job files';
    [file,~] = uigetfile('*.m',fstr,startdir);          
    if ~file
        return;
    end            
    try            
        func=str2func(strrep(file,'.m',''));
        J = func();            
        obj.add(J);
    catch ME            
        warning(ME.message);
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
            obj.TextBox.Data{kk,3} = num2str(obj.SequencerJobs{kk}.CyclesRequested);
            obj.TextBox.Data{kk,4} = obj.SequencerJobs{kk}.JobName;
            % obj.TextBox.Data{kk,5} = mystr;                
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
    if isempty(obj.SequencerJobs)
        job = obj.DefaultJob;
        return;
    end

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

