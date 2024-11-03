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
    JobTable             % text table to update job progress
    SequencerWatcher    % sequencer_watcher which watches the adwin
    % doIterate           % boolean to continue running jobs
    DefaultJob          % The default job to run
    JobTabs         
    Cycle
    TableJobCycle
    TableJobOptions
    doHoldCycle
    doStopOnCycleComplete
    doStopOnJobComplete
    doStartQueueOnDefaultJobCycleComplete
    doStartDefaultJobOnQueueComplete
    StringJob
end    

events
   
end

methods
    
    % constructor
function obj = job_handler(gui_handle)          
    obj.SequencerJobs={};            
    d=guidata(gui_handle);          
    obj.JobTable = d.JobTable;
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

    if isfield(d,'StringJob')
        obj.StringJob=d.StringJob;
    end
    obj.Cycle                                   = 1;
    obj.doHoldCycle                             = 0;
    obj.doStopOnCycleComplete                   = 0;
    obj.doStopOnJobComplete                     = 0;
    obj.doStartQueueOnDefaultJobCycleComplete   = 0;
    obj.doStartDefaultJobOnQueueComplete        = 0;
end

function JobOptionsCB(obj,src,evt)
    obj.doHoldCycle = src.Data{1,1};
    obj.doStopOnCycleComplete = src.Data{2,1};
    obj.doStopOnJobComplete = src.Data{3,1};
    obj.doStartQueueOnDefaultJobCycleComplete = src.Data{4,1};
    obj.doStartDefaultJobOnQueueComplete = src.Data{5,1};
end

function JobCycleCB(obj,src,evt)   
    n = evt.NewData;
    if ~isnan(n) && isnumeric(n) && floor(n)==n && ~isinf(n) && n>0
        obj.Cycle = round(n);
    else
        src.Data = evt.PreviousData;
    end
end

function start(obj,job_type,Cycle)     
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
                    if isequal(job,obj.DefaultJob)
                        job.CyclesCompleted = 0;
                    end
                otherwise
                    error('Unexpected job type. Fix your code!');              
            end

        otherwise
            error('Unexpected job_type class. Fix your code!');
    end

    if nargin==3
        job.CyclesCompleted = Cycle;
    end
    
    % Update current job
    obj.CurrentJob = job; 
    obj.runCurrentJob();    
end

function runCurrentJob(obj)
    job=obj.CurrentJob;
    job.Status = 'running';
    obj.StringJob.String=['(' num2str(obj.getCurrentJobIndex) ') ' obj.CurrentJob.JobName];

    obj.updateJobText; 
    global seqdata
    seqdata.scancycle = job.CyclesCompleted+1;
    seqdata.sequence_functions = job.SequenceFunctions;
    obj.CycleStartFcn();
    t=runSequence(job.SequenceFunctions);              
    job.ExecutionDates(end+1) = t;
    % Get ready to wait for job to finish
    obj.ListenerCycle=listener(obj.SequencerWatcher,'CycleComplete',...
        @(src, evt) obj.CycleCompleteFcn);
    obj.ListenerAdwin=listener(obj.SequencerWatcher,'AdwinComplete',...
        @(src, evt) obj.AdwinCompleteFcn);
    % obj.doIterate   = true;
end

function ind=getCurrentJobIndex(obj)
    if isequal(obj.CurrentJob,obj.DefaultJob)
        ind = 0;
    else        
        ind=find(cellfun(@(myjob) isequal(obj.CurrentJob,myjob),obj.SequencerJobs),1);
    end
end

function CycleStartFcn(obj)
    obj.CurrentJob.Status = 'CycleStartFcn()';
    set(obj.SequencerWatcher.StatusStr,...
        'String',[func2str(obj.CurrentJob.CycleStartFcn)],...
        'ForegroundColor',[220,88,42]/255);
    obj.updateJobText();
    try         
        obj.CurrentJob.CycleStartFcn();
        obj.CurrentJob.Status = 'pending';
    catch ME
        warning on
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.CurrentJob.Status = 'CycleStartFcn() Error';
    end
    obj.updateJobText();
end

% Evaluates when the Adwin is complete. Independent of Wait Timer
function AdwinCompleteFcn(obj)
    delete(obj.ListenerAdwin);                      % Delete Listener
    obj.CurrentJob.Status = 'AdwinComplete';

    % Increment Cycles Completed
    if ~obj.doHoldCycle
        obj.CurrentJob.CyclesCompleted = obj.CurrentJob.CyclesCompleted+1;   
    end    
    obj.updateJobText;
    obj.CurrentJob.Status = 'CycleCompleteFcn()';
    obj.updateJobText;

    % if ~isempty(obj.CurrentJob.CycleCompleteFcn)
    set(obj.SequencerWatcher.StatusStr,...
        'String',[func2str(obj.CurrentJob.CycleCompleteFcn)],...
        'ForegroundColor',[220,88,42]/255);
    try         
        obj.CurrentJob.CycleCompleteFcn();
        obj.CurrentJob.Status = 'pending';
    catch ME
        warning on
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.CurrentJob.Status = 'CycleCompleteFcn() Error';
    end
    obj.updateJobText;
    if obj.CurrentJob.isComplete()
        obj.JobCompleteFcn();       
    end
    obj.updateJobText;
end

% Evaluates when a job is complete.  Independent of Wait Timer
function JobCompleteFcn(obj)
    obj.CurrentJob.Status = 'job end';
    obj.updateJobText;    
    
    % Run User job funcion
    set(obj.SequencerWatcher.StatusStr,...
        'String',[func2str(obj.CurrentJob.JobCompleteFcn)],...
        'ForegroundColor',[220,88,42]/255);
    try
        obj.CurrentJob.JobCompleteFcn();
        obj.CurrentJob.Status = 'complete';
    catch ME
        warning on
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.CurrentJob.Status = 'JobCompleteFcn() Error';
    end
    set(obj.SequencerWatcher.StatusStr,...
        'String','idle','ForegroundColor',[0 128 0]/255);
    % Ending Stuff    
    obj.updateJobText;    
end

% Evaluates when the Total Cycle (Adwin+Wait) is complete
function CycleCompleteFcn(obj)    
    delete(obj.ListenerCycle);          % delete Listener   

    if obj.doStopOnCycleComplete
        return;
    end

    if (obj.doStopOnJobComplete && obj.CurrentJob.isComplete())
        return;
    end

    % If DefaultJob and want to start queue, move onto next job
    if isequal(obj.CurrentJob,obj.DefaultJob) && ...
            (obj.doStartQueueOnDefaultJobCycleComplete)
        obj.start('queue');
        return;        
    end    

    % Continue the job
    if ~obj.CurrentJob.isComplete()
        obj.start(obj.CurrentJob)  
    else
        if isequal(obj.DefaultJob,obj.findNextJob())
            % If the next job is complete, then all jobs are done
            if obj.doStartDefaultJobOnQueueComplete
                % run default job on complete
                obj.DefaultJob.CyclesCompleted=0;
                obj.start('default');
                return;
            end
        else
            % go to next job
            obj.start('queue');
            return;
        end
    end



    
    
    % Continue this job
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

% Add job to queue
function add(obj,job)
    for kk=1:length(job)
        obj.SequencerJobs{end+1} = job(kk);
        obj.updateJobText;
    end
end

% % Stop Current Job
% function stop(obj)
%     obj.doIterate   = false;
%     if ~isempty(obj.CurrentJob)
%        obj.CurrentJob.Status = 'stopping';
%     end
%     obj.updateJobText;
% end   

function viewJobs(obj)
    selJobs=obj.SequencerJobs([obj.JobTable.Data{:,1}]);
    for kk=1:length(selJobs)
        selJobs{kk}.MakeTableInterface(obj.JobTabs,1);
    end
end

% Clear all jobs
function clearQueue(obj) 
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
       obj.JobTable.Data={};
    else
        for kk = 1:length(obj.SequencerJobs)
            funcs=obj.SequencerJobs{kk}.SequenceFunctions;
            mystr =[];
            for ii = 1:length(funcs)
                mystr = [mystr func2str(funcs{ii}) ','];
            end
            mystr(end)=[];
            obj.JobTable.Data{kk,1} = false;
            obj.JobTable.Data{kk,2} = obj.SequencerJobs{kk}.Status;
            obj.JobTable.Data{kk,3} = num2str(obj.SequencerJobs{kk}.CyclesRequested);
            obj.JobTable.Data{kk,4} = obj.SequencerJobs{kk}.JobName;
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
    job = [];
    if isempty(obj.SequencerJobs)
        job = obj.DefaultJob;
        return;
    end

   for kk=1:length(obj.SequencerJobs)
       if isequal(obj.SequencerJobs{kk}.Status,'pending')
            job = obj.SequencerJobs{kk};
            return
       end
   end
    job = obj.DefaultJob;   
end


% delete me
function delete(obj)
    % delete any listeners
    obj.clearQueue;
    obj.updateJobText;
end

end

end

