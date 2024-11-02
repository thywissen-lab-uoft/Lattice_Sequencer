% classdef sequencer_job < handle
classdef sequencer_job < matlab.mixin.Copyable

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


    % ScanCyclesRequested     % array of scan cycle indices to run
    % ScanCyclesCompleted     % array of scan cycle indices which have been complete so far
    % ScanCycle               % which scan cycle will be run

    CyclesCompleted         % Number of cycles Completed
    CyclesRequested         % Number of cycles requested
    Cycle                   % Next/Current Cycle to run
    WaitMode
    WaitTime

    SaveDir


    JobName                 % the name of the job
    ExecutionDates          % the dates at which each sequence in the job is run
    Status                  % the current status of the job
    CycleStartFcn           % user custom function to evalulate before sequence runs
    CycleCompleteFcn        % user custom function to evaluate after the cycle
    JobCompleteFcn          % user custom function to evaluate when job is complete
    CameraFile              % camera control output file
    TableInterface
end    
events

end

methods      

function obj = sequencer_job(npt)     
    obj.CameraFile = 'Y:\_communication\camera_control.mat';
    obj.JobName             = npt.JobName;            
    obj.SequenceFunctions   = npt.SequenceFunctions;
    obj.Status              = 'pending';
    obj.CyclesRequested     = npt.CyclesRequested;
    obj.CyclesCompleted     = 0;    
    obj.Cycle               = 1;
    obj.SaveDir             = '';
    obj.ExecutionDates      = [];
    obj.CycleStartFcn       = [];
    obj.CycleCompleteFcn    = [];
    obj.JobCompleteFcn      = [];
    obj.WaitMode            = 1;
    obj.WaitTime            = 30;

    if isfield(npt,'WaitMode');         obj.WaitMode        = npt.WaitMode;end
    if isfield(npt,'WaitTime');         obj.WaitTime        = npt.WaitTime;end  
    if isfield(npt,'SaveDir');          obj.SaveDir         = npt.SaveDir;end
    if isfield(npt,'CyclesRequested');  obj.CyclesRequested = npt.CyclesRequested;end


    if isfield(npt,'CycleStartFcn');obj.CycleStartFcn = @npt.CycleStartFcn;end
    if isfield(npt,'CycleCompleteFcn');obj.CycleCompleteFcn = @npt.CycleCompleteFcn;end
    if isfield(npt,'JobCompleteFcn');obj.JobCompleteFcn = @npt.JobCompleteFcn;end

    if isfield(npt,'TableInterface')
        obj.TableInterface = npt.TableInterface;
        obj.TableInterface.CellEditCallback = obj.EditTableInterface;
    end
    

    
  
end    

function MakeTableInterface(this,parent,options)
    if nargin ==2
        options=struct;
    end

    this.TableInterface = uitable('parent',parent,...
        'units','pixels',...
        'fontsize',7,...
        'columnwidth',{100 180},...
        'ColumnFormat',{'char','char'},...
        'RowName',{},'columnname',{},...
        'ColumnEditable',[false true],...
        'fontname','arialnarrow');

    this.TableInterface.Data={
        'JobName', this.JobName;
        'SequenceFunctions',this.getSequenceFunctionStr;...
        'CyclesCompleted',this.CyclesCompleted;    
        'CyclesRequested',this.CyclesRequested;
        'WaitMode',this.WaitMode;
        'WaitTime', this.WaitTime;
        'SaveDir', this.SaveDir;
        'CycleCompleteFcn',func2str(@this.CycleCompleteFcn);
        'JobCompleteFcn',func2str(@this.JobCompleteFcn);
        'CycleStartFcn',func2str(@this.CycleStartFcn)};
    if isfield(options,'Position')
        this.TableInterface.Position=options.Position;
    end
end

function mystr=getSequenceFunctionStr(this)
    mystr=[];
    for ii = 1:length(this.SequenceFunctions)
        mystr = [mystr func2str(funcs{ii}) ','];
    end
    mystr(end)=[];
end

function EditTableInterface(this,src,evt)
    keyboard
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
    keyboard
%     if ~isempty(obj.SaveDirName)
%         SaveDir = obj.SaveDirName;
%         try
%             save(obj.CameraFile,'SaveDir');
%         end
%     end
end

end
end

