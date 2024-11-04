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
properties (SetObservable)
    SequenceFunctions       % cell array : sequence functions to evaluate
    % CyclesCompleted         % double     : number of cycles completed
    % CyclesRequested         % double     : number of cycles requested
    CycleNow            % double
    CycleEnd              % double
    WaitMode                % double     : 0:no wait, 1:intercycle, 2: total
    WaitTime                % double     : wait time in seconds
    SaveDir                 % char       : directory string save images (see imaging computer)
    JobName                 % char       : name of the job
    ExecutionDates          % the dates at which each sequence in the job is run
    Status                  % the current status of the job
    CycleStartFcn           % user custom function to evalulate before sequence runs
    CycleCompleteFcn        % user custom function to evaluate after the cycle
    JobCompleteFcn          % user custom function to evaluate when job is complete
    CameraFile              % camera control output file
    Tab
    Panel                   % Panel interface
    TableInterface
    AdwinTime               % Time to evaluvlate sequence
    UpdateHandlerFcn
    
end    
events

end

methods      

function obj = sequencer_job(npt)     
    obj.CameraFile = 'Y:\_communication\camera_control.mat';
    obj.JobName             = npt.JobName;            
    obj.SequenceFunctions   = npt.SequenceFunctions;
    % obj.Status              = 'pending';
    % 
    % obj.CyclesCompleted     = 0;    
    % obj.CyclesRequested     = npt.CyclesRequested;

    obj.CycleNow            = 1;
    obj.CycleEnd            = 2; 



    obj.SaveDir             = '';
    obj.ExecutionDates      = [];
    obj.CycleStartFcn       = @false;
    obj.CycleCompleteFcn    = @false;
    obj.JobCompleteFcn      = @false;
    obj.WaitMode            = 1;
    obj.WaitTime            = 30;
    obj.AdwinTime           = NaN;
    obj.Tab                 = [];
    if isfield(npt,'WaitMode');         obj.WaitMode        = npt.WaitMode;end
    if isfield(npt,'WaitTime');         obj.WaitTime        = npt.WaitTime;end  
    if isfield(npt,'SaveDir');          obj.SaveDir         = npt.SaveDir;end
    % if isfield(npt,'CyclesRequested');  obj.CyclesRequested = npt.CyclesRequested;end
    if isfield(npt,'CycleEnd');  obj.CycleEnd = npt.CycleEnd;end

    
    if isfield(npt,'CycleStartFcn');obj.CycleStartFcn = npt.CycleStartFcn;end
    if isfield(npt,'CycleCompleteFcn');obj.CycleCompleteFcn = npt.CycleCompleteFcn;end
    if isfield(npt,'JobCompleteFcn');obj.JobCompleteFcn = npt.JobCompleteFcn;end
    if isfield(npt,'TableInterface')
        obj.TableInterface = npt.TableInterface;
    end   
end    

function delete(obj)
    if ~isempty(obj.Tab);delete(obj.Tab);end
end

function MakeTableInterface(this,parent,boop)
    if nargin ==2
        boop=false;
    end

    if isempty(this.Tab) || ~isvalid(this.Tab)
        this.Tab = uitab(parent,'title',this.JobName);
    end

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
        'ButtonDownFcn',@this.TableButtonDownFcn,...
        'CellEditCallback',@this.TableCellEditCB);
    this.updateTableInterface();
    this.TableInterface.Position = [1 1 this.TableInterface.Extent(3)+1 this.TableInterface.Extent(4)+1];

    if boop
        bClose = uicontrol(this.Panel,'style','pushbutton',...
            'string','close','fontsize',7,'foregroundcolor','r','units','pixels',...
            'Callback',{@(src,evt) delete(this.Tab)},'backgroundcolor','w');
        bClose.Position(1:2)=this.TableInterface.Position(1:2)+[0 this.TableInterface.Position(4)];
        bClose.Position(3:4)=[30 20];
    else
    
        % Button for file selection of the sequenece file
        cdata=imresize(imread(['GUI/images' filesep 'browse.jpg']),[16 16]);
        bBrowse=uicontrol(this.Panel,'style','pushbutton','CData',cdata,...
            'backgroundcolor','w','Callback',@this.browseCB,'tooltip','browse file');
        bBrowse.Position(3:4)=[18 18];
        bBrowse.Position(1:2)=[this.TableInterface.Position(1) ...
            this.TableInterface.Position(2)+this.TableInterface.Position(4)+2];
     
        % refresh
        bJobRefresh=uicontrol(this.Panel,'style','pushbutton','String','refresh job_default()',...
            'backgroundcolor','w','FontSize',7,'units','pixels',...
            'Callback',@this.refreshDefaultJob);
        bJobRefresh.Position(3:4)=[100 18];
        bJobRefresh.Position(1:2)=bBrowse.Position(1:2) + [bBrowse.Position(3)+2 0];

        % Go to Default Sequence
        bSeqDefault=uicontrol(this.Panel,'style','pushbutton','String','default sequence',...
            'backgroundcolor','w','FontSize',7,'units','pixels',...
            'Callback',@this.chSequence,'UserData',0);
        bSeqDefault.Position(3:4)=[80 18];
        bSeqDefault.Position(1:2)=bJobRefresh.Position(1:2) + [bJobRefresh.Position(3)+2 0];
    
        % Go to Test Sequence
        bSeqTest=uicontrol(this.Panel,'style','pushbutton','String','test sequence',...
            'backgroundcolor','w','FontSize',7,'units','pixels',...
            'Callback',@this.chSequence,'UserData',1);
        bSeqTest.Position(3:4)=[80 18];
        bSeqTest.Position(1:2)=bSeqDefault.Position(1:2) + [bSeqDefault.Position(3)+2 0];
    end   
end

function refreshDefaultJob(this,src,evt)
    % delete(this);
    J = job_default();
    names = fieldnames(this);
    for kk=1:length(names)
        if ~isequal(names{kk},'Tab') ...
                && ~isequal(names{kk},'Panel') ...
                && ~isequal(names{kk},'TableInterface')

            this.(names{kk})=J.(names{kk});
        end        
    end
    if ~isempty(this.Tab) && isvalid(this.Tab)
        this.updateTableInterface();
    end
end

function TableCellEditCB(this,src,evt)
    Name = src.Data{evt.Indices(1),1};
    s = evt.NewData;
    switch Name
        case 'JobName'
            this.JobName = s;
        case 'SequenceFunctions'
            src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
            
        % case 'CyclesCompleted'
        %     if isnumeric(s) && isequal(floor(s),s) && ...
        %         ~isnan(s) && ~isinf(s) && s>=0 
        %         s = max([this.CyclesRequested s]);
        %         this.CyclesCompleted = s;
        %     else
        %         src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
        %     end
        % case 'CyclesRequested'
        %     if isnumeric(s) && isequal(floor(s),s) && ...
        %         ~isnan(s) &&  s>=0                
        %         this.CyclesRequested = s;
        %     else
        %         src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
        %     end
        case 'CycleNow'
            if isnumeric(s) && isequal(floor(s),s) && ...
                ~isnan(s) && ~isinf(s) && s>0 
                this.CycleNow = s;
            else
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
            end            
        case 'CycleEnd'
            if isnumeric(s) && isequal(floor(s),s) && ...
                ~isnan(s) &&  s>0                
                this.CycleEnd = s;
            else
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
            end

        case 'WaitMode'
            if isequal(s,0) || isequal(s,1) || isequal(s,2)
                this.WaitMode = s;
            end
        case 'WaitTime'
            if isnumeric(s) &&  ...
                ~isnan(s) && ~isinf(s) && s>=0                
                this.WaitTime = s;
            else
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
            end
        case 'SaveDir'
            if verify_filename(s)
                this.SaveDir = s;
            else
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
            end
        case 'CycleStartFcn'
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
        case 'CycleCompleteFcn'
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;
        case 'JobCompleteFcn'
                src.Data{evt.Indices(1),evt.Indices(2)}=evt.PreviousData;

        otherwise
    end
    this.UpdateHandlerFcn();
    

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
    % Directory where the sequence files lives
    dirName=['Sequence Files' filesep 'Core Sequences'];
    % The directory of the root
    curpath = fileparts(fileparts(mfilename('fullpath')));
    % Construct the path where the sequence files live    
    defname=[curpath filesep dirName];
    fstr='Select a sequence file to use...';
    [file,~] = uigetfile('*.m',fstr,defname);          
    if ~file;return;end        
    file = erase(file,'.m');  
    this.SequenceFunctions = {str2func(file)}; 
    this.updateTableInterface();
end

function tWaitReal=calcRealWaitTime(this)
    if isnumeric(this.AdwinTime) && ~isnan(this.AdwinTime) && ~isinf(this.AdwinTime)
        switch this.WaitMode
            case 0
                tWaitReal=0;
            case 1
                tWaitReal = this.WaitTime;
            case 2
                tWaitReal = this.WaitTime-this.AdwinTime;
        end
    else
        tWaitReal = NaN;
    end
end

function updateTableInterface(this)
    if isempty(this.Tab) || ~isvalid(this.Tab) || ~isvalid(this.TableInterface)
        return;
    end
    this.TableInterface.Data={
        'JobName', this.JobName;
        'SequenceFunctions',this.getSequenceFunctionStr;...
        % 'CyclesCompleted',this.CyclesCompleted;    
        % 'CyclesRequested',this.CyclesRequested;
        'CycleNow',this.CycleNow;    
        'CycleEnd',this.CycleEnd;
        'WaitMode',this.WaitMode;
        'WaitTime', this.WaitTime;
        'SaveDir', this.SaveDir;
        'CycleStartFcn',func2str(this.CycleStartFcn);
        'CycleCompleteFcn',func2str(this.CycleCompleteFcn);
        'JobCompleteFcn',func2str(this.JobCompleteFcn)
        };
end

function ret=isComplete(this)
    ret=this.CycleNow>=this.CycleEnd;
end

function mystr=getSequenceFunctionStr(this)
    mystr=[];
    for ii = 1:length(this.SequenceFunctions)
        mystr = [mystr func2str(this.SequenceFunctions{ii}) ','];
    end
    mystr(end)=[];
end


end
end

