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
    CyclesCompleted         % Number of cycles Completed
    CyclesRequested         % Number of cycles requested
    WaitMode
    WaitTime
    SaveDir
    isComplete
    JobName                 % the name of the job
    ExecutionDates          % the dates at which each sequence in the job is run
    Status                  % the current status of the job
    CycleStartFcn           % user custom function to evalulate before sequence runs
    CycleCompleteFcn        % user custom function to evaluate after the cycle
    JobCompleteFcn          % user custom function to evaluate when job is complete
    CameraFile              % camera control output file

    Tab
    Panel                   % Panel interface
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
    obj.isComplete          = false;
    obj.CyclesRequested     = npt.CyclesRequested;
    obj.CyclesCompleted     = 0;    
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
    if isfield(npt,'CycleStartFcn');obj.CycleStartFcn = npt.CycleStartFcn;end
    if isfield(npt,'CycleCompleteFcn');obj.CycleCompleteFcn = npt.CycleCompleteFcn;end
    if isfield(npt,'JobCompleteFcn');obj.JobCompleteFcn = npt.JobCompleteFcn;end
    if isfield(npt,'TableInterface')
        obj.TableInterface = npt.TableInterface;
        obj.TableInterface.CellEditCallback = obj.EditTableInterface;
    end
    

    
  
end    

function MakeTableInterface(this,parent) 
    this.Tab = uitab(parent,'title',this.JobName);
    this.Panel = uipanel('parent',this.Tab,'units','normalized',...
        'backgroundcolor','w','position',[0 0 1 1]);
    this.TableInterface = uitable('parent',this.Panel,...
        'units','pixels',...
        'fontsize',7,...
        'columnwidth',{100 180},...
        'ColumnFormat',{'char','char'},...
        'RowName',{},'columnname',{},...
        'ColumnEditable',[false true],...
        'fontname','arialnarrow',...
        'ButtonDownFcn',@this.TableButtonDownFcn);
    this.updateTableInterface();
    this.TableInterface.Position = [1 1 this.TableInterface.Extent(3)+1 this.TableInterface.Extent(4)+1];

    % Button for file selection of the sequenece file
    cdata=imresize(imread(['GUI/images' filesep 'browse.jpg']),[16 16]);
    bBrowse=uicontrol(this.Panel,'style','pushbutton','CData',cdata,...
        'backgroundcolor','w','Callback',@browseCB,'tooltip','browse file');
    bBrowse.Position(3:4)=[18 18];
    bBrowse.Position(1:2)=[this.TableInterface.Position(1) ...
        this.TableInterface.Position(2)+this.TableInterface.Position(4)+2];

    % Go to Default Sequence
    bSeqDefault=uicontrol(this.Panel,'style','pushbutton','String','default sequence',...
        'backgroundcolor','w','FontSize',7,'units','pixels',...
        'Callback',@this.chSequence,'UserData',0);
    bSeqDefault.Position(3:4)=[80 18];
    bSeqDefault.Position(1:2)=bBrowse.Position(1:2) + [bBrowse.Position(3)+2 0];

    % Go to Test Sequence
    bSeqTest=uicontrol(this.Panel,'style','pushbutton','String','test sequence',...
        'backgroundcolor','w','FontSize',7,'units','pixels',...
        'Callback',@this.chSequence,'UserData',1);
    bSeqTest.Position(3:4)=[80 18];
    bSeqTest.Position(1:2)=bSeqDefault.Position(1:2) + [bSeqDefault.Position(3)+2 0];
end

function chSequence(this,src,evt)
    switch src.UserData
        case 0
            this.SequenceFunctions={@main_settings,@main_sequence};
        case 1
            this.SequenceFunctions={@test_sequence}; 
        otherwise

    end
    this.updateTableInterface();
end

function TableButtonDownFcn(this,src,evt)
      % figHandle = ancestor(src, 'figure');
      clickType = get(ancestor(src,'figure'),'SelectionType');
      if strcmp(clickType, 'alt')
          disp('right click action goes here!');
      else 
          disp('idffernt')
      end
end


function browseCB(this,src,evt)    
    % % Directory where the sequence files lives
    % dirName=['Sequence Files' filesep 'Core Sequences'];
    % % The directory of the root
    % curpath = fileparts(mfilename('fullpath'));
    % % Construct the path where the sequence files live
    % defname=[curpath filesep dirName];
    % fstr='Select a sequence file to use...';
    % [file,~] = uigetfile('*.m',fstr,defname);          
    % if ~file
    % disp([datestr(now,13) ' Cancelling'])
    % return;
    % end        
    % file = erase(file,'.m');        
    % seqdata.sequence_functions = {str2func(file)};        
    % d=guidata(hF);
    % d.SequencerWatcher.updateSequenceFileText(seqdata.sequence_functions);               
end

function updateTableInterface(this)
    this.TableInterface.Data={
        'JobName', this.JobName;
        'SequenceFunctions',this.getSequenceFunctionStr;...
        'isComplete',this.isComplete;    
        'CyclesCompleted',this.CyclesCompleted;    
        'CyclesRequested',this.CyclesRequested;
        'WaitMode',this.WaitMode;
        'WaitTime', this.WaitTime;
        'SaveDir', this.SaveDir;
        'CycleStartFcn',func2str(this.CycleStartFcn);
        'CycleCompleteFcn',func2str(this.CycleCompleteFcn);
        'JobCompleteFcn',func2str(this.JobCompleteFcn)
        };
end

function mystr=getSequenceFunctionStr(this)
    mystr=[];
    for ii = 1:length(this.SequenceFunctions)
        mystr = [mystr func2str(this.SequenceFunctions{ii}) ','];
    end
    mystr(end)=[];
end

function EditTableInterface(this,src,evt)
    keyboard
end

% % function that evaluates upon job completion
% function JobCompleteFcnWrapper(obj)  
%     disp('Executing job complete function');
%     pause(.1);    
%     if ~isempty(obj.JobCompleteFcn)
%        obj.JobCompleteFcn(); 
%     end
% end
% 
% % function that evaluates upon cycle completion
% function CycleCompleteFcnWrapper(obj)        
%     disp('Executing cycle complete function.');
%     pause(.1);
%     if ~isempty(obj.CycleCompleteFcn)
%         obj.CycleCompleteFcn(); 
%     end
% end
% 
% % function that evaluates upon after compitation but before run
% function CycleStartFcnWrapper(obj)        
%     disp('Executing cycle start function.');
%     pause(.1);
%     if ~isempty(obj.CycleStartFcn)
%         obj.CycleStartFcn(); 
%     end
% end

end
end

