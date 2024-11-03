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
    CompilerStatus
    DebugMode

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
    obj.CurrentJob = obj.DefaultJob;

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
    obj.CompilerStatus                          = 0; 
    obj.DebugMode = d.DebugMode;
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

function updateSeqStr(obj,str,cc)
    if nargin == 2
        cc=[0 0 0];
    end
   set(obj.SequencerWatcher.StatusStr,...
        'String',str,'ForegroundColor',cc);
end

% Evaluates when the Adwin is complete. Independent of Wait Timer
function AdwinCompleteFcn(obj)
    delete(obj.ListenerAdwin);                      % Delete Listener
    if ~isvalid(obj.CurrentJob)
        warning('CurrentJob has been deleted. Ignoring CycleCompleteFcn.')
        obj.updateJobText;
        return;
    end
    
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

    % If job is deleted, count is as completed
    if ~isvalid(obj.CurrentJob)
        warning('CurrentJob deleted. No JobCompleteFcn to evaluate.')
        updateJobText()
        return;
    end    
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
    obj.updateJobText();    
end

% Evaluates when the Total Cycle (Adwin+Wait) is complete
function CycleCompleteFcn(obj)    
    delete(obj.ListenerCycle);          % delete Listener   
    jobExist = isvalid(obj.CurrentJob);
    % If job is deleted, count is as completed
    if ~jobExist
        warning('CurrentJob deleted. Treating as if is complete.')
    end       

    if obj.doStopOnCycleComplete
        return;
    end

    if (obj.doStopOnJobComplete && (obj.CurrentJob.isComplete() || ~jobExist))
        return;
    end

    % If DefaultJob and want to start queue, move onto next job
    if jobExist && (isequal(obj.CurrentJob,obj.DefaultJob) && ...
            (obj.doStartQueueOnDefaultJobCycleComplete))
        obj.start('queue');
        return;        
    end    

    % Continue the job
    if jobExist && ~obj.CurrentJob.isComplete()
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

function clearQueueSelect(obj)
    delInds = [obj.JobTable.Data{:,1}];
    for kk=1:length(obj.SequencerJobs)
        if delInds(kk)
            delete(obj.SequencerJobs{kk})
        end
    end
    obj.SequencerJobs(delInds)=[];
    obj.updateJobText;
end

function moveQueueSelect(obj,number)
    temp_data = [obj.JobTable.Data{:,1}];
    selected_indeces = [obj.JobTable.Data{:,1}]; 
    N = length(selected_indeces);

    inds = 1:N;


    if number>0
        for mm=2:N
            if ~selected_indeces(mm-1) && selected_indeces(mm)
                 inds([mm-1 mm])=inds([mm mm-1]);
                 selected_indeces([mm-1 mm])=selected_indeces([mm mm-1]);
            end
        end 
    else
        for mm=(N-1):-1:1
            if ~selected_indeces(mm+1) && selected_indeces(mm)
                 inds([mm+1 mm])=inds([mm mm+1]);
                  selected_indeces([mm+1 mm])=selected_indeces([mm mm+1]);
            end
        end
    end
    obj.SequencerJobs=obj.SequencerJobs(inds);
    obj.JobTable.Data=obj.JobTable.Data(inds,:);
    % obj.updateJobText();  
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

%% seqdata Adwin Functions
% 
% function runCurrentJob(obj)
%     job=obj.CurrentJob;
%     job.Status = 'running';
%     obj.StringJob.String=['(' num2str(obj.getCurrentJobIndex) ') ' obj.CurrentJob.JobName];
%     obj.updateJobText; 
%     global seqdata
%     seqdata.scancycle = job.CyclesCompleted+1;
%     seqdata.sequence_functions = job.SequenceFunctions;
%     obj.CycleStartFcn();
%     t=runSequence(job.SequenceFunctions);              
%     job.ExecutionDates(end+1) = t;
%     % Get ready to wait for job to finish
%     obj.ListenerCycle=listener(obj.SequencerWatcher,'CycleComplete',...
%         @(src, evt) obj.CycleCompleteFcn);
%     obj.ListenerAdwin=listener(obj.SequencerWatcher,'AdwinComplete',...
%         @(src, evt) obj.AdwinCompleteFcn);
%     % obj.doIterate   = true;
% end

function runCurrentJob(obj)
    job=obj.CurrentJob;
    job.Status = 'running';
    obj.StringJob.String=['(' num2str(obj.getCurrentJobIndex) ') ' obj.CurrentJob.JobName];
    obj.updateJobText; 
    global seqdata
    seqdata.scancycle = job.CyclesCompleted+1;
    seqdata.sequence_functions = job.SequenceFunctions;
    obj.CycleStartFcn();
    
    ret = obj.compile();
    if ret
        [ret,tExecute]=obj.run();
    end
    if ret
        job.ExecutionDates(end+1) = tExecute;
        obj.ListenerCycle=listener(obj.SequencerWatcher,'CycleComplete',...
            @(src,evt) obj.CycleCompleteFcn);
        obj.ListenerAdwin=listener(obj.SequencerWatcher,'AdwinComplete',...
            @(src,evt) obj.AdwinCompleteFcn);
    end
end
function [ret,tExecute] = run(obj)
    global adwinprocessnum
    ret = true;             % compile good
    tExecute = [];

    obj.updateSeqStr('loading adwin',[220,88,42]/255); 
    if ~obj.DebugMode
        try            
            load_sequence;
        catch ME
            warning(getReport(ME,'extended','hyperlinks','on'))
            ret = false;
            return;
        end
    end
    obj.updateSeqStr('adwin loaded',[17,59,8]/255); 

    % Make control file
    try
        obj.updateSeqStr('making log file',[17,59,8]/255);
        if ~obj.DebugMode    
            tExecute = makeControlFile;
        else 
            tExecute = now;
        end
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'))
        ret = false;
        return;
    end
    obj.updateSeqStr('starting adwin',[17,59,8]/255); 
    try
        if ~obj.DebugMode;Start_Process(adwinprocessnum);end        
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'))
        ret = false;
        return;
    end
    obj.updateSeqStr('adwin is running','r'); 
    obj.SequencerWatcher.AdwinTime = obj.CurrentJob.AdwinTime;
    start(obj.SequencerWatcher);
end

% Compiles the seqdata (see compile.m for old way)
function ret = compile(obj,doProgramDevices)       
    if nargin==1;doProgramDevices=1;end

    obj.CompilerStatus = 1; % compiler busy
    ret = true;             % compile good

    % Initialize Sequence
    try
        obj.updateSeqStr('initializing sequence','k');    
        start_new_sequence;
        initialize_channels;
        logInitialize;
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.updateSeqStr('sequence initialize error','r'); 
        pause(0.1)
        ret = false;% compile fail
        obj.CompilerStatus = 0;% compiler idle
        return;
    end

    % Evaluate Sequence Functions
    try    
        curtime = 0;
        obj.updateSeqStr('evaluating sequence functions','k');   
        for kk = 1:length(obj.CurrentJob.SequenceFunctions)
            obj.updateSeqStr(['@' func2str(obj.CurrentJob.SequenceFunctions{kk})],[220,88,42]/255);    
            pause(0.1);
            curtime = obj.CurrentJob.SequenceFunctions{kk}(curtime);                 
        end
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.updateSeqStr('sequence compile error','r'); 
        pause(0.1)
        ret = false;% compile fail
        obj.CompilerStatus = 0;% compiler idle
        return;
    end

     % Update GUI Text (needs to be udpated)
    try;updateScanVarText;end

    % Convert Into Hardware Commands
    try
        obj.updateSeqStr(...
            ['converting sequence into hardware commands'],...
            [220,88,42]/255); 
        obj.CurrentJob.AdwinTime=calc_sequence(doProgramDevices);    
        obj.updateSeqStr(...
            ['sequence calulated'],...
            [17,59,8]/255); 
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'));
        obj.updateSeqStr('hardware conversion error','r'); 
        pause(0.1)
        ret = false;% compile fail
        obj.CompilerStatus = 0;% compiler idle
        return;
    end
    obj.CompilerStatus = 0;
end


end

end

