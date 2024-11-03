function hF=mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.
%
% Author      : CJ Fujiwara
% Last Edited : 2024/11

%% Find previous instance of gui
% Open the GUI if it already exists
figs = get(groot,'Children');
for i = 1:length(figs)
    if isequal(figs(i).UserData,'sequencer_gui')       
       warning('Sequencer GUI already open. Please close it if you want a new instace');
       figure(figs(i));
       return;
    end
end
%% Initialize Things
LatticeSequencerInitialize();
global seqdata;
global adwinprocessnum;
data = struct;
seqdata.doscan = 0;
evalin('base','global seqdata')
evalin('base','openvar(''seqdata'')')
evalin('base','openvar(''seqdata.flags'')')
evalin('base','openvar(''seqdata.params'')')
evalin('base','openvar(''seqdata.variables'')')
waitDefault=30;
defaultSequence={@main_settings,@main_sequence};
defaultSequence={@test_sequence};

seqdata.sequence_functions = defaultSequence;
figName='Main GUI';
if seqdata.debugMode    
    figName=[figName ' DEBUG MODE'];
end
%% Initialize Primary Figure graphics

disp('Opening Lattice Sequencer...');

% Figure color and size settings
cc='w';w=360;h=600;

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,'NumberTitle','off',...
    'MenuBar','figure','CloseRequestFcn',@closeFig,...
    'UserData','sequencer_gui');
clf
hF.Position(3:4)=[w h];
set(hF,'WindowStyle','docked');

handles = struct;
hF.SizeChangedFcn=@sequencer_resize;

%% Close Figure Callback
 function closeFig(src,~)
   disp('Requesting to close the sequencer GUI.');     
   t=guidata(src);

   if t.SequencerWatcher.isRunning       
       tt=['The sequence is still running or repitions are engaged '...
           'with the wait timer running. Are you sure you want to ' ...
           'close the GUI? If the sequence data has already been ' ...
           'sent to the Adwin, the experiment will still be running.'];
       tit='Sequence is still running!';           
       f2=figure('Name',tit,'color','w','NumberTitle','off',...
           'windowstyle','modal','units','pixels','resize','off');
       f2.Position(3:4)=[400 200];
       f2.Position(1:2)=src.Position(1:2)+[-50 100];           
       uicontrol('style','text','String',tt,'parent',f2,...
           'fontsize',10,'units','normalized','horizontalalignment',...
           'center','backgroundcolor','w','Position',[.05 .5 .9 .35]);           
       uicontrol('style','pushbutton','string','yes','parent',f2,...
           'fontsize',10','units','normalized','backgroundcolor',...
           [253 106 2]/255,'Position',[.25 .15 .2 .2],'Callback',@doClose);  
       uicontrol('style','pushbutton','string','cancel','parent',f2,...
           'fontsize',10','units','normalized','backgroundcolor','w',...
           'position',[.55 .15 .2 .2],'Callback',@(~,~) close(f2));  
   else
        disp('Closing the sequencer GUI. Goodybe. I love you'); 
        try
            delete(t.SequencerWatcher);
        catch ME
            warning(ME.message);
        end        
        try 
            delete(t.JobHandler)
        catch ME
           warning(ME.message); 
        end
        delete(src);
   end

    function doClose(~,~)
        close(f2);
        disp('Closing the sequencer GUI. Goodybe. I love you');
        t=guidata(src);
        delete(src);
    end       
 end
%% Panel Graphics Holders

% Panel : Main
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','line','BorderColor','k','borderwidth',1);
hpMain.Position=[1 1 400 600];

% Panel : Timer Display and Status
hpStatus = uipanel('Parent',hpMain,'units','pixels',...
    'backgroundcolor',cc,'bordertype','line','BorderColor','k','borderwidth',1);
hpStatus.Position(3:4)=[hpStatus.Parent.Position(3) 85];
hpStatus.Position(1:2)=[0 0];

% Tab Group : Job object detail
hpJobDetail=uitabgroup(hpMain,'units','pixels');
hpJobDetail.Position(3:4)=[347 260];
hpJobDetail.Position(1:2)=[0 hpStatus.Position(2)+hpStatus.Position(4)];

% Panel : Job Controller
hpRun = uipanel('Parent',hpMain,'units','pixels',...
    'backgroundcolor',cc,'bordertype','line','BorderColor','k','borderwidth',1);
hpRun.Position(3:4)=[hpRun.Parent.Position(3) 160];
hpRun.Position(1:2)=[0 hpJobDetail.Position(2)+hpJobDetail.Position(4)];

% Panel : Job Queue
hpJobQueue = uipanel('parent',hF,'units','pixels','backgroundcolor','w',...
    'title','Job Queue','bordertype','etchedin');
hpJobQueue.Position(1:2) = [1 hpRun.Position(2)+hpRun.Position(4)];
hpJobQueue.Position(3:4)=[hpJobQueue.Parent.Position(3) 90];

% Job Queue Table Table
tableJobs = uitable('parent',hpJobQueue,'fontsize',7,...
    'ColumnName',{'', 'Status','#','Job Name'},...
    'ColumnEditable',[true false false false],...
    'ColumnWidth',{20 50 20 170},...
    'ColumnFormat',{'logical','char','char','char'},...
    'Position', [1 1 hpMain.Position(3) hpJobQueue.Position(4)-12],...
    'FontName','Helvetica-Narrow');

    function sequencer_resize(src,evt)
        try
            hpMain.Position(3:4)    = hpMain.Parent.Position(3:4);
            hpStatus.Position(3)    = hpStatus.Parent.Position(3);
            hpJobDetail.Position(3) = hpJobDetail.Parent.Position(3);
            hpRun.Position(3)       = hpRun.Parent.Position(3);
            hpJobQueue.Position(3)  = hpJobQueue.Parent.Position(3);
            hpJobQueue.Position(4)  = max([hpJobQueue.Parent.Position(4)-hpJobQueue.Position(2)-5 50]);            
            tableJobs.Position(3)    = tableJobs.Parent.Position(3)-tableJobs.Position(1)-2;
            tableJobs.ColumnWidth{4} = max([50 tableJobs.Position(3)-sum([tableJobs.ColumnWidth{1:end-1}])-60]);
            tableJobs.Position(4)   = max([tableJobs.Parent.Position(4)-tableJobs.Position(2)-20 50]);
            axWaitBar.Position(3)   = axWaitBar.Parent.Position(3)-2*axWaitBar.Position(1);
            axAdWinBar.Position(3)  = axWaitBar.Position(3);
            tCycle.Position(1)      = tCycle.Parent.Position(3)-tCycle.Position(3)-10;
            tScanVar.Position(3)=axAdWinBar.Position(3);

            tStatus.Position(3)=[tStatus.Parent.Position(3)-tStatus.Parent.Position(1)-5];

            for kk=1:length(hpJobDetail.Children)
                gphx=hpJobDetail.Children(kk).Children(1).Children;
                for jj=1:length(gphx)                    
                    if isequal(class(gphx(jj)),'matlab.ui.control.Table')
                        gphx(jj).Parent.Units='pixels';
                        wP = gphx(jj).Parent.Position(3);
                        gphx(jj).Parent.Units='normalized';    
                        w2 = wP-gphx(jj).ColumnWidth{1}-20;
                        gphx(jj).ColumnWidth{2}=max([w2 50]);
                        gphx(jj).Position(3:4)=gphx(jj).Extent(3:4)+[5 2];
                    end

                end
            end
            drawnow;

        end
    end

%% Sequencer Status Panel
% This panel contains graphical objects which shows details about the
% current sequence being run

% Wait Progress bar
waitbarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',hpStatus,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1:2)=[5 5];
axWaitBar.Position(3:4)=[axWaitBar.Parent.Position(3)-2*axWaitBar.Position(1) 15];
% Plot the wait bar
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],waitbarcolor);
% Wait Bar Text Label
text(.5,.5,'wait timer','fontsize',8,'horizontalalignment','center', ...
    'verticalalignment','middle','fontweight','bold');
% String labels for time end points
tWaitTime1 = text(0,0,'0.00 s','parent',axWaitBar,'fontsize',8,...
    'horizontalalignment','left','units','data','verticalalignment','middle',...
    'Position',[0.01 .5]);
tWaitTime2 = text(0,0,'10.00 s','parent',axWaitBar,'fontsize',8,...
    'horizontalalignment','right','units','data','verticalalignment','middle',...
    'Position',[0.99 .5]);

% Adwin Progress bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',hpStatus,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=axWaitBar.Position;[10 30 hpStatus.Position(3)-20 15];
axAdWinBar.Position(2) = axWaitBar.Position(2)+axWaitBar.Position(4)+2;
% Plot the patch of color for the bar
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1], adwinbarcolor);
% Adwin Bar Text Label
text(.5,.5,'adwin timer','fontsize',8,'horizontalalignment','center', ...
    'verticalalignment','middle','fontweight','bold');
% Add some text labels for the current and end time
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',8,...
    'horizontalalignment','left','units','data','verticalalignment','middle',...
    'Position',[0.01 0.5]);
tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',8,...
    'horizontalalignment','right','units','data','verticalalignment','middle',...
    'Position',[.99 0.5]);

% Scan Variable
tScanVar=uicontrol(hpStatus,'style','text','string','No detected variable scanning with ParamDef/Get.',...
    'backgroundcolor','w','fontsize',7,'units','pixels',...
    'fontweight','normal','visible','on','horizontalalignment','left');
tScanVar.Position(3:4)=[axAdWinBar.Position(3) 10];
tScanVar.Position(1) = axAdWinBar.Position(1);
tScanVar.Position(2) = axAdWinBar.Position(2)+axAdWinBar.Position(4)+2;

% Status String
tStatus=uicontrol(hpStatus,'style','text','string','sequencer idle',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','bold','visible','on','horizontalalignment','left');
tStatus.Position(1) = axAdWinBar.Position(1);
tStatus.Position(2) = tScanVar.Position(2)+tScanVar.Position(4)+1;
tStatus.Position(3:4)=[tStatus.Parent.Position(3)-tStatus.Parent.Position(1)-15 15];
tStatus.ForegroundColor=[0 128 0]/255;

% Status String
tCurrentJob=uicontrol(hpStatus,'style','text','string','JobDefault',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','bold','visible','on','horizontalalignment','left');
tCurrentJob.Position(1) = axAdWinBar.Position(1);
tCurrentJob.Position(2) = tStatus.Position(2)+tStatus.Position(4)+1;
tCurrentJob.Position(3:4)=[tCurrentJob.Parent.Position(3)-tCurrentJob.Parent.Position(1)-15 15];
tCurrentJob.ForegroundColor=[0 0 0];

% Status String
tCycle=uicontrol(hpStatus,'style','text','string','Cycle # : ',...
    'backgroundcolor','w','fontsize',7,'units','pixels',...
    'visible','on','horizontalalignment','right');
tCycle.Position(3:4)=[80 10];
tCycle.Position(1) = tCycle.Parent.Position(3)-tCycle.Position(3)-10;
tCycle.Position(2) = tStatus.Position(2);

%% Job Controller
wB = 100;
hB  = 18;

% Button to run the cycle
bRunDefault=uicontrol(hpRun,'style','pushbutton','String','Run JobDefault',...
    'backgroundcolor',[152 251 152]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bRunDefault.Position(3:4)=[wB hB];
bRunDefault.Position(1:2)=[5 5];
bRunDefault.Tooltip='Start JobDefault';

% Button to run the cycle
bRun=uicontrol(hpRun,'style','pushbutton','String','Run JobQueue',...
    'backgroundcolor',[173 216 230]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bRun.Position(3:4)=[wB hB];
bRun.Position(1:2)=[bRunDefault.Position(1) bRunDefault.Position(2)+bRunDefault.Position(4)+2];
bRun.Tooltip='Start or continue queued job.';

% Button to run the cycle
bClearQueue=uicontrol(hpRun,'style','pushbutton','String','Clear JobQueue',...
    'backgroundcolor', [255 206 27]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bClearQueue.Position(3:4)=[wB hB];
bClearQueue.Position(1:2)=[bRun.Position(1) bRun.Position(2)+bRun.Position(4)+2];
bClearQueue.Tooltip='Clear jobs';



% Button to add a job
bAddJob=uicontrol(hpRun,'style','pushbutton','String','Add to JobQueue',...
    'backgroundcolor',[205,133,63]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bAddJob.Position(3:4)=[wB hB];
bAddJob.Position(1:2)=[bClearQueue.Position(1) bClearQueue.Position(2)+bClearQueue.Position(4)+2];
bAddJob.Tooltip='Add jobs';

% Button to remove selected jobs
bViewJob=uicontrol(hpRun,'style','pushbutton','String',['View ' char(10003) ' in JobQueue'],...
    'backgroundcolor',[218, 177, 218]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bViewJob.Position(3:4)=[wB hB];
bViewJob.Position(1:2)=[bAddJob.Position(1) bAddJob.Position(2)+bAddJob.Position(4)+2];
bViewJob.Tooltip='View jobs';

% Button to remove selected jobs
bRemoveJob=uicontrol(hpRun,'style','pushbutton','String',['Del. ' char(10003) ' in JobQueue'],...
    'backgroundcolor',[248, 131, 121]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bRemoveJob.Position(3:4)=[wB hB];
bRemoveJob.Position(1:2)=[bViewJob.Position(1) bViewJob.Position(2)+bViewJob.Position(4)+2];
bRemoveJob.Tooltip='Add jobs';

bMoveJobUp=uicontrol(hpRun,'style','pushbutton','String',['Move ' char(10003) ' ' char(8593)],...
    'backgroundcolor',[205,133,63]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bMoveJobUp.Position(3:4)=[wB/2 hB];
bMoveJobUp.Position(1:2)=[bRemoveJob.Position(1) bRemoveJob.Position(2)+bRemoveJob.Position(4)+2];
bMoveJobUp.Tooltip='Move Job Up';

bMoveJobDown=uicontrol(hpRun,'style','pushbutton','String',['Move ' char(10003) ' ' char(8595) ],...
    'backgroundcolor',[205,133,63]/255,'FontSize',7,'units','pixels',...
    'fontweight','bold');
bMoveJobDown.Position(3:4)=[wB/2 hB];
bMoveJobDown.Position(1:2)=[bMoveJobUp.Position(1)+bMoveJobUp.Position(3) bMoveJobUp.Position(2)];
bMoveJobDown.Tooltip='Move Job Down';


% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'plot.jpg']),[24 24]);
bPlot=uicontrol(hpRun,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@bPlotCB,'tooltip','plot');
bPlot.Position(3:4)=[25 25];
bPlot.Position(1:2)=[bRunDefault.Position(1)+bRunDefault.Position(3)+4 bRunDefault.Position(2)];

    function bPlotCB(~,~)
        plotgui2;
    end

% Button to recompile seqdata but not program devices
cdata=imresize(imread(['GUI/images' filesep 'compile.jpg']),[20 20]);
bCompilePartial=uicontrol(hpRun,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@bCompileCB 0},'tooltip',...
    'compile sequence but don''t program devices');
bCompilePartial.Position(3:4)=[25 25];
bCompilePartial.Position(1:2)=bPlot.Position(1:2)+[0 bPlot.Position(4)];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'compile_yellow.jpg']),[20 20]);
bCompileFull=uicontrol(hpRun,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@bCompileCB 1},'tooltip',...
    'compile sequence and program devices');
bCompileFull.Position(3:4)=[25 25];
bCompileFull.Position(1:2)=bCompilePartial.Position(1:2)+[0 bCompilePartial.Position(4)];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'command_window.jpg']),[20 20]);
bCmd=uicontrol(hpRun,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) commandwindow,'tooltip',...
    'move up directory level','tooltip','command window');
bCmd.Position(3:4)=[25 25];
bCmd.Position(1:2)=bCompileFull.Position(1:2)+[0 bCompileFull.Position(4)];

    function bCompileCB(~,~,doProgramDevices)    
        compile(seqdata.sequence_functions,doProgramDevices)        
        updateScanVarText;    
    end

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'help.jpg']),[20 20]);
bHelp=uicontrol(hpRun,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@helpCB,'tooltip','help');
bHelp.Position(3:4)=[25 25];
bHelp.Position(1:2)=bCmd.Position(1:2)+[0 bCmd.Position(4)+1];

    function helpCB(~,~)
       doc job_handler
       doc sequencer_job
    end

% % Button to reseed random list
% ttStr=['Reseed random list of scan indeces.'];
% bRandSeed=uicontrol(hpRun,'style','pushbutton','String','reseed random',...
%     'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
%     'fontweight','normal','Tooltip',ttStr);
% bRandSeed.Position(3:4)=[80 16];
% bRandSeed.Position(1:2)=[1 hpRun.Position(4)-bRandSeed.Position(4)-14];
% bRandSeed.Callback=@(src,evt) bReseedRandom;
% 
%     function bReseedRandom(~,~)
%        seqdata.randcyclelist = makeRandList ;
%     end
% 
% % Button to reset adwin (not well tested)
% ttStr=['Reinitialize channels and reset Adwin outputs ' ...
%     'to default values.'];
% bReset=uicontrol(hpRun,'style','pushbutton','String','reset',...
%     'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
%     'fontweight','normal','Tooltip',ttStr);
% bReset.Position(3:4)=[40 15];
% bReset.Position(1:2)=[bRandSeed.Position(1)+bRandSeed.Position(3) ...
%     bRandSeed.Position(2)];
% bReset.Callback=@bResetCB;
% 
% % Button to abort adwin (not well tested)
% ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
%     'outputs to their reset value.  DANGEROUS'];
% bAbort=uicontrol(hpRun,'style','pushbutton','String','abort',...
%     'backgroundcolor','r','FontSize',8,'units','pixels',...
%     'fontweight','normal','Tooltip',ttStr,'Callback',@bAbortCB);
% bAbort.Position(3:4)=[40 15];
% bAbort.Position(1:2)=[bReset.Position(1)+bReset.Position(3) ...
%     bReset.Position(2)];

tbl_job_options = uitable(hpRun,'RowName',{},'columnname',{},...
    'ColumnEditable',[true false],'units','pixels',...
    'ColumnWidth',{15 195},'fontsize',7,'columnformat',{'logical','char'});
tbl_job_options.Data={...
    false, 'HOLD CycleNumber';
    false, 'STOP on CycleComplete';
    false, 'STOP on JobComplete ';
    false, 'START Queue on DefaultJob CycleComplete';
    false, 'START DefaultJob on QueueComplete ';
    false, 'REPEAT QUEUE on QueueComplete'};
tbl_job_options.Position=[bRunDefault.Position(1)+bRunDefault.Position(3)+35 bRunDefault.Position(2) ...
    tbl_job_options.Extent(3) tbl_job_options.Extent(4)];

tbl_job_cycle=uitable(hpRun,'RowName',{},'ColumnName',{},...
    'ColumnEditable',[true false],'Data',{1, 'CycleNumber'},'units','pixels',...
    'ColumnWidth',{20, 180},'FontSize',7,...
    'columnformat',{'numeric','char'});
tbl_job_cycle.Position(3:4)=tbl_job_cycle.Extent(3:4);
tbl_job_cycle.Position(1:2)=tbl_job_options.Position(1:2)+[0 tbl_job_options.Position(4)];


% Reset Button callback (not tested well)
    function bResetCB(~,~)        
        disp('Reseting the adwin outputs to their default values');
        LatticeSequencerInitialize();
        fh=@reset_sequence;
        fh(0);
        calc_sequence();
        try
            load_sequence(); 
            pause(0.1);
            disp('The Adwin should have resetted the values');
        end
    end

% Abort Button callback (not tested well)
    function bAbortCB(~,~)       
        disp('Aborting adwin and then resetting!!! Good luck');
        try
            Stop_Process(adwinprocessnum);
            disp('Sequence should be stopped');
            bResetCB;      
        catch exception
            warning(exception.message)            
        end
    end
%% guidata output
% THIS IS SUPER MESSY

handles.WaitBar = pWaitBar;
handles.WaitStr1 = tWaitTime1;
handles.WaitStr2 = tWaitTime2;
handles.AdwinBar = pAdWinBar;
handles.AdwinStr1 = tAdWinTime1;
handles.AdwinStr2 = tAdWinTime2;
handles.StatusStr = tStatus;
handles.CycleStr= tCycle;
data.SequencerWatcher = sequencer_watcher(handles);


data.TableJobCycle = tbl_job_cycle;
data.TableJobOptions = tbl_job_options;

data.StringJob = tCurrentJob;
data.Status = tStatus;
data.VarText = tScanVar;
data.SequencerListener.Enabled = 0;
data.JobTable = tableJobs;
data.CycleStr = tCycle;
data.JobTabs = hpJobDetail;

guidata(hF,data);
data.JobHandler = job_handler(hF);
guidata(hF,data);

dirName=['Jobs'];
curpath = fileparts(mfilename('fullpath'));
defname = fullfile(curpath,dirName);   

bRun.Callback           = @(src,evt) data.JobHandler.start('queue');
bRunDefault.Callback    = @(src,evt) data.JobHandler.start('default',0);
bClearQueue.Callback    = @(src,evt) data.JobHandler.clearQueue();
bAddJob.Callback        = @(src,evt) data.JobHandler.addJobGUI(defname);
bViewJob.Callback       = @(src,evt) data.JobHandler.viewJobs();
bRemoveJob.Callback     = @(src,evt) data.JobHandler.deleteSelectedJobs();
bMoveJobDown.Callback   = @(src,evt) data.JobHandler.moveSelectJobs(-1);
bMoveJobUp.Callback     = @(src,evt) data.JobHandler.moveSelectJobs(1);
    
%% Assign Handles
% Add gui figure, sequecner watcher, and job handler to base workspace so
% that they may be accessed from the command line

assignin('base','jh',data.JobHandler);
assignin('base','gui_main',hF);
assignin('base','sw',data.SequencerWatcher);

commandwindow
end


