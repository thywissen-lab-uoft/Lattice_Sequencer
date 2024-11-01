function hF=mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.
%
% Author      : CJ Fujiwara
% Last Edited : 2023/02

%% Find previous instance of gui
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


% defaultSequence='@main_settings,@main_sequence';

defaultSequence={@main_settings,@main_sequence};
seqdata.sequence_functions = defaultSequence;

figName='Main GUI';

if seqdata.debugMode
    
    figName=[figName ' DEBUG MODE'];
end

%% Initialize Primary Figure graphics

disp('Opening Lattice Sequencer...');

% Figure color and size settings
cc='w';w=700;h=350;

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,'NumberTitle','off',...
    'MenuBar','figure','CloseRequestFcn',@closeFig,...
    'UserData','sequencer_gui');
clf
hF.Position(3:4)=[w h];
set(hF,'WindowStyle','docked');

handles = struct;


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

% Main uipanel
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','line','BorderColor','k','borderwidth',1);
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];
hpMain.OuterPosition=[0 1 w 600];

% status uipanel
hpStatus = uipanel('Parent',hpMain,'units','pixels',...
    'backgroundcolor',cc,'bordertype','line','BorderColor','k','borderwidth',1);
hpStatus.Position(3:4)=[360 65];
hpStatus.Position(1:2)=[0 0];
% hpStatus.Position(1:2)=[140 1];

% run uipanel
hpRun = uipanel('Parent',hpMain,'units','pixels','Title','job controller',...
    'backgroundcolor',cc,'bordertype','line','BorderColor','k','borderwidth',1);
hpRun.Position(3:4)=[350 140];
hpRun.Position(1:2)=[0 hpStatus.Position(2)+hpStatus.Position(4)];
% hpRun.Position(1:2)=[1 1];

hpJobDetail=uitabgroup(hpMain,'units','pixels');
hpJobDetail.Position(3:4)=[347 250];
hpJobDetail.Position(1:2)=[1 hpRun.Position(2)+hpRun.Position(4)];

default_job_tab=uitab(hpJobDetail,'Title','default job','units','pixels');
current_job_tab=uitab(hpJobDetail,'Title','current job','units','pixels');

hpDefaultJob = uipanel('parent',default_job_tab,'backgroundcolor','w','units',...
    'normalized','position',[0 0 1 1]);
hpCurrentJob = uipanel('parent',current_job_tab,'backgroundcolor','w','units',...
    'normalized','position',[0 0 1 1]);

% sequence uipanel
hpSeq = uipanel('parent',hpMain,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin','title','sequence');
hpSeq.Position(3:4)=[347 90];
hpSeq.Position(1:2)=[1 hpJobDetail.Position(2)+hpJobDetail.Position(4)];

 % Jobs uipanel
hpJobs = uipanel('parent',hF,'units','pixels','backgroundcolor','w',...
    'title','job queue','bordertype','etchedin');
hpJobs.Position(1:2) = [1 hpSeq.Position(2)+hpSeq.Position(4)];
hpJobs.Position(3:4)=[w 90];








hF.SizeChangedFcn=@sequencer_resize;

    function sequencer_resize(src,evt)
        % hpJobs.Position(4) = hpJobs.Parent.Position(4)-hpJobs.Position(2)-5;
        tJobs.Position(4) = tJobs.Parent.Position(4)-tJobs.Position(2)-20;
    end

%% Jobs Panel Graphical Objects

% Job Table
tJobs = uitable('parent',hpJobs,'fontsize',8,'rowname',{});
tJobs.ColumnName = {'', 'status','cycles','name','sequence'};
tJobs.ColumnWidth={20 60 40 170 345};
tJobs.ColumnEditable=[true false false false false];
tJobs.ColumnFormat = {'logical','char','char','char','char'};
hme = 30;
tJobs.Position = [1 hme hpMain.Position(3) hpJobs.Position(4)-(hme+15)];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'help.jpg']),[16 16]);
bHelp=uicontrol(hpJobs,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@helpCB,'tooltip','help');
bHelp.Position(3:4)=[20 20];
bHelp.Position(1:2)=[5 5];

    function helpCB(~,~)
       doc job_handler
       doc sequencer_job
    end

% Button to run the cycle
bRunJob=uicontrol(hpJobs,'style','pushbutton','String','Start Queue',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@startJobsCB);
bRunJob.Position(3:4)=[40 20];
bRunJob.Position(1:2)=[35 5];
bRunJob.Tooltip='Run the jobs';

    function startJobsCB(~,~)
        d=guidata(hF);
        d.JobHandler.start;
    end

% Button to run the cycle
bStopJob=uicontrol(hpJobs,'style','pushbutton','String','Stop',...
    'backgroundcolor',[255	218	107]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@stopJobsCB);
bStopJob.Position(3:4)=[40 20];
bStopJob.Position(1:2)=[80 5];
bStopJob.Tooltip='Stop jobs';

    function stopJobsCB(~,~)
        d=guidata(hF);
        d.JobHandler.stop;
    end

% Button to run the cycle
bClearJob=uicontrol(hpJobs,'style','pushbutton','String','remove all jobs',...
    'backgroundcolor',[173 216 230]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@clearJobsCB);
bClearJob.Position(3:4)=[80 20];
bClearJob.Position(1:2)=[125 5];
bClearJob.Tooltip='Clear jobs';

    function clearJobsCB(~,~)
        d=guidata(hF);
        d.JobHandler.clear;
    end

% Button to add a job
bAddJob=uicontrol(hpJobs,'style','pushbutton','String','add job to queue',...
    'backgroundcolor',[205,133,63]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@addJobsCB);
bAddJob.Position(3:4)=[60 20];
bAddJob.Position(1:2)=[170 5];
bAddJob.Tooltip='Add jobs';

    function addJobsCB(~,~)        
        dirName=['Jobs'];
        curpath = fileparts(mfilename('fullpath'));
        defname = fullfile(curpath,dirName);        
        fstr='Add job files';
        [file,~] = uigetfile('*.m',fstr,defname);          
        if ~file
            return;
        end        
        
        try            
            func=str2func(strrep(file,'.m',''));
            J = func();            
            d=guidata(hF);
            d.JobHandler.add(J);
        catch ME
            warning(ME.message);
        end
    end


%% Sequence
% Sequence File edit box
mystr='comma separated sequnce functions (@func1,@func2,@func3,...)';
tSeq=uicontrol(hpSeq,'style','text','string',mystr,...
    'horizontalalignment','left','fontsize',7,'backgroundcolor',cc);
tSeq.Position(3)=335;
tSeq.Position(4)=tSeq.Extent(4);
tSeq.Position(1:2)=[5 46];

% Sequence File edit box
eSeq=uicontrol(hpSeq,'style','edit','string','A',...
    'horizontalalignment','left','fontsize',8,'backgroundcolor',cc,'enable','off');
eSeq.Position(3)=335;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 32];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'browse.jpg']),[22 22]);
bBrowse=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@browseCB,'tooltip','browse file');
bBrowse.Position(3:4)=[24 24];
bBrowse.Position(1:2)=[5 4];

% button to change to default sequence
bDefault=uicontrol(hpSeq,'style','pushbutton','String','default seq.',...
    'backgroundcolor',cc,'FontSize',8,'units','pixels',...
    'Callback',@defaultCB);
bDefault.Position(3:4)=[60 24];
bDefault.Position(1:2)=bBrowse.Position(1:2) + [bBrowse.Position(3)+2 0];

    function defaultCB(~,~)
        seqdata.sequence_functions = defaultSequence;
        d=guidata(hF);        
        d.SequencerWatcher.updateSequenceFileText(defaultSequence);
    end

% matlab.desktop.editor.getActive

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'folder_up.jpg']),[20 20]);
bDirUp=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) cd('..'),'tooltip','move up directory level');
bDirUp.Position(3:4)=[24 24];
bDirUp.Position(1:2)=bDefault.Position(1:2)+[bDefault.Position(3)+2 0];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'file1.png']),[17 17]);
bFile1=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@fileCB 1},'tooltip','open first file');
bFile1.Position(3:4)=[24 24];
bFile1.Position(1:2)=bDirUp.Position(1:2)+[bDirUp.Position(3)+2 0];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'file2.png']),[17 17]);
bFile2=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@fileCB 2},'tooltip','open second file');
bFile2.Position(3:4)=[24 24];
bFile2.Position(1:2)=bFile1.Position(1:2)+[bFile1.Position(3)+2 0];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'file3.png']),[17 17]);
bFile3=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@fileCB 3},'tooltip','open third file');
bFile3.Position(3:4)=[24 24];
bFile3.Position(1:2)=bFile2.Position(1:2)+[bFile2.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'plot.jpg']),[24 24]);
bPlot=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@bPlotCB,'tooltip','plot');
bPlot.Position(3:4)=[25 25];
bPlot.Position(1:2)=bFile3.Position(1:2)+[bFile3.Position(3)+2 0];

    function bPlotCB(~,~)
        plotgui2;
    end

% Button to recompile seqdata but not program devices
cdata=imresize(imread(['GUI/images' filesep 'compile.jpg']),[20 20]);
bCompilePartial=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@bCompileCB 0},'tooltip',...
    'compile sequence but don''t program devices');
bCompilePartial.Position(3:4)=[25 25];
bCompilePartial.Position(1:2)=bPlot.Position(1:2)+[bPlot.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'compile_yellow.jpg']),[20 20]);
bCompileFull=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',{@bCompileCB 1},'tooltip',...
    'compile sequence and program devices');
bCompileFull.Position(3:4)=[25 25];
bCompileFull.Position(1:2)=bCompilePartial.Position(1:2)+[bCompilePartial.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'command_window.jpg']),[20 20]);
bCmd=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) commandwindow,'tooltip',...
    'move up directory level','tooltip','command window');
bCmd.Position(3:4)=[25 25];
bCmd.Position(1:2)=bCompileFull.Position(1:2)+[bCompileFull.Position(3)+2 0];

    function bCompileCB(~,~,doProgramDevices)    
        compile(seqdata.sequence_functions,doProgramDevices)        
        updateScanVarText;    
    end

% callback to change sequence file
    function browseCB(src,evt)    
        disp([datestr(now,13) ' Changing the sequence file.']);        
        % Directory where the sequence files lives
        dirName=['Sequence Files' filesep 'Core Sequences'];
        % The directory of the root
        curpath = fileparts(mfilename('fullpath'));
        % Construct the path where the sequence files live
        defname=[curpath filesep dirName];
        fstr='Select a sequence file to use...';
        [file,~] = uigetfile('*.m',fstr,defname);          
        if ~file
            disp([datestr(now,13) ' Cancelling'])
            return;
        end        
        file = erase(file,'.m');        
        seqdata.sequence_functions = {str2func(file)};        
        d=guidata(hF);
        d.SequencerWatcher.updateSequenceFileText(seqdata.sequence_functions);               
    end

    function fileCB(~,~,n)
        d=guidata(hF);
        str = d.SequencerWatcher.SequenceText.String;
        
        try            
            strs=strsplit(strrep(str,'@',''),',');
            names={};
            for kk=1:length(strs)
                names{kk} =  erase(strs{kk},'@'); 
            end            
            name = strsplit(names{n},'/');
            name = name{1};
            open(name);
        catch ME
            warning(ME.message);
        end        
    end
%% Sequencer Status Panel
% 
% % Status String
% sL=uicontrol(hpStatus,'style','text','string','sequencer status',...
%     'backgroundcolor','w','fontsize',7,'units','pixels',...
%     'visible','on','horizontalalignment','left');
% sL.Position=[5 sL.Parent.Position(4)-12 100 10];



% Axis object for plotting the wait bar
waitbarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',hpStatus,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1:2)=[5 5];
axWaitBar.Position(3:4)=[axWaitBar.Parent.Position(3)-2*axWaitBar.Position(1) 15];

% Plot the wait bar
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],waitbarcolor);
text(.5,.5,'wait timer','fontsize',8,'horizontalalignment','center', ...
    'verticalalignment','middle','fontweight','bold');

% String labels for time end points
tWaitTime1 = text(0,0,'0.00 s','parent',axWaitBar,'fontsize',8,...
    'horizontalalignment','left','units','data','verticalalignment','middle');
tWaitTime1.Position=[0.01 .5];

tWaitTime2 = text(0,0,'10.00 s','parent',axWaitBar,'fontsize',8,...
    'horizontalalignment','right','units','data','verticalalignment','middle');
tWaitTime2.Position(1:2)=[.99 .5];

% Adwin Progress bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',hpStatus,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=axWaitBar.Position;[10 30 hpStatus.Position(3)-20 15];
axAdWinBar.Position(2) = axWaitBar.Position(2)+axWaitBar.Position(4)+2;
% Plot the patch of color for the bar
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1], adwinbarcolor);

% Add some text labels for the current and end time
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',8,...
    'horizontalalignment','left','units','data','verticalalignment','middle');
tAdWinTime1.Position=[.01 .5];


tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',8,...
    'horizontalalignment','right','units','data','verticalalignment','middle');
tAdWinTime2.Position=[.99 .5];

% Add an overall label
text(.5,.5,'adwin timer','fontsize',8,'horizontalalignment','center', ...
    'verticalalignment','middle','fontweight','bold');



% Scan Var
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
tStatus.Position(3:4)=[150 15];
tStatus.Position(1) = axAdWinBar.Position(1);
tStatus.Position(2) = tScanVar.Position(2)+tScanVar.Position(4)+1;
tStatus.ForegroundColor=[0 128 0]/255;


% Status String
tCycle=uicontrol(hpStatus,'style','text','string','Cycle # : ',...
    'backgroundcolor','w','fontsize',7,'units','pixels',...
    'visible','on','horizontalalignment','right');
tCycle.Position(3:4)=[80 10];
tCycle.Position(1) = tCycle.Parent.Position(3)-tCycle.Position(3)-10;
tCycle.Position(2) = tStatus.Position(2);


%% Wait Timer Graphical interface

tWaitMode = uicontrol(hpRun,'style','text','string','wait mode : ',...
    'units','pixels','fontsize',7,'backgroundcolor','w','fontname','arial');
tWaitMode.Position(1:2) = [5 110];
tWaitMode.Position(3:4) = [50 10];

menuWaitMode = uicontrol(hpRun,'style','popupmenu','string',{'none','intercycle','total'},...
    'units','pixels','fontsize',7,'value',2);
menuWaitMode.Position(3:4)=[70 15];
menuWaitMode.Position(1:2)=[tWaitMode.Position(1)+tWaitMode.Position(3) tWaitMode.Position(2)];

% Table for storing value of wait time
tblWait=uitable(hpRun,'RowName','','ColumnName','','Data',waitDefault,...
    'ColumnWidth',{30},'ColumnEditable',true,'ColumnFormat',{'numeric'},...
    'fontsize',8,'Enable','on');
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4);
tblWait.Position(1:2)=[2+menuWaitMode.Position(1)+menuWaitMode.Position(3) menuWaitMode.Position(2)-5];

% Wait Unit Label
tWaitSec = uicontrol(hpRun,'style','text','string','sec.',...
    'units','pixels','fontsize',7,'backgroundcolor','w','fontname','arial');
tWaitSec.Position(1:2) = [tblWait.Position(1)+tblWait.Position(3) tWaitMode.Position(2)];
tWaitSec.Position(3:4) = [20 10];

% Status String
tCycleNumberLabel=uicontrol(hpRun,'style','text','string','cycle # :',...
    'backgroundcolor','w','fontsize',7,'units','pixels',...
    'horizontalalignment','left');
tCycleNumberLabel.Position(3:4)=[45 10];
tCycleNumberLabel.Position(1:2)=[5 tWaitMode.Position(2)-25];

cycleTbl=uitable(hpRun,'RowName',{},'ColumnName',{},...
    'ColumnEditable',[true],'Data',[1],'units','pixels',...
    'ColumnWidth',{30},'FontSize',7,'CellEditCallback',@tblCB,...
    'columnformat',{'numeric'});
cycleTbl.Position(3:4)=cycleTbl.Extent(3:4);
cycleTbl.Position(1:2)=[tCycleNumberLabel.Position(1)+tCycleNumberLabel.Position(3)+2 tCycleNumberLabel.Position(2)-5];

    function tblCB(src,evt)
        n = evt.NewData;
        if ~isnan(n) && isnumeric(n) && floor(n)==n && ~isinf(n) && n>0
            seqdata.scancycle = evt.NewData;
        else
            src.Data = evt.PreviousData;
        end
    end

% Checkbox for repeat cycle
cRpt=uicontrol(hpRun,'style','checkbox','string','hold cycle #','fontsize',7,...
    'backgroundcolor',cc,'units','pixels');
cRpt.Position(3:4)=[100 cRpt.Extent(4)];
cRpt.Position(1:2)=[5 tCycleNumberLabel.Position(2)-25];
cRpt.Tooltip='Enable or disable automatic repitition of the sequence.';

% Checkbox to hold sequencer
cHold=uicontrol(hpRun,'style','checkbox','string','hold job after current cycle','fontsize',7,...
    'backgroundcolor',cc,'units','pixels');
cHold.Position(3:4)=[150 cHold.Extent(4)];
cHold.Position(1:2)=[5 cRpt.Position(2)-15];
cHold.Tooltip='Hold the sequencer after end of next cycle.';

% Button to run the cycle
bRunIter=uicontrol(hpRun,'style','pushbutton','String','Run Single Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','Callback',{@bRunCB 0});
bRunIter.Position(3:4)=[120 16];
bRunIter.Position(1:2)=[5 22];
bRunIter.Tooltip='Run the current sequence.';

% Button to run the cycle
bStartScan=uicontrol(hpRun,'style','pushbutton','String','Start Current Job',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold');
bStartScan.Position(3:4)=[120 16];
bStartScan.Position(1:2)=[5 5];
bStartScan.Callback={@bRunCB 1};
bStartScan.Tooltip='Start the scan.';
% 
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


%% Button Callbacks

    function CycleComplete(src,evt)        
        d=guidata(hF);
        d.SequencerListener.Enabled = 0;
        d.CycleStr.String = '';
        if cRpt.Value
            disp('Repeating the sequence');
            cycleTbl.Data       = seqdata.scancycle;
            runSequenceCB;
        else
            if seqdata.doscan
                % Increment the scan and run the sequencer again
                seqdata.scancycle = seqdata.scancycle+1;
                cycleTbl.Data       = seqdata.scancycle;
                runSequenceCB;
            end
        end   
    end    

% Run button callback.
    function bRunCB(~,~,run_mode)    
        % Initialize the sequence if seqdata is not defined
        % Should this just happen every single time?
        if isempty(seqdata)
            LatticeSequencerInitialize();
        end
        d=guidata(hF);       
        
        % Is the sequence already running?        
        if (d.SequencerWatcher.isRunning)
           warning('The sequencer running you clod!');
           return;
        end        
                
        switch run_mode            
            case 0 % Run a single iteration               
                seqdata.scancycle   = cycleTbl.Data;
            case 1 % 1 : start a scan
                seqdata.doscan      = 1;
                seqdata.scancycle   = 1;
                cycleTbl.Data       = 1;
            case 2 % Continue the scan
                seqdata.doscan      = 1;
                seqdata.scancycle   = seqdata.scancycle + 1;
                cycleTbl.Data       = seqdata.scancycle;
        end  
        runSequenceCB;        
    end

    function bStopCB(~,~)    
        disp('stopping scan');
        seqdata.doscan=0;           
    end


    function runSequenceCB    
        d=guidata(hF);
        d.SequencerWatcher.RequestWaitTime = d.SequencerWatcher.WaitTable.Data;

        runSequence(seqdata.sequence_functions);    
        d.SequencerListener.Enabled=1;
    end    

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

handles.WaitButtons = menuWaitMode;
handles.WaitTable = tblWait;
handles.WaitBar = pWaitBar;
handles.WaitStr1 = tWaitTime1;
handles.WaitStr2 = tWaitTime2;
handles.AdwinBar = pAdWinBar;
handles.AdwinStr1 = tAdWinTime1;
handles.AdwinStr2 = tAdWinTime2;
handles.StatusStr = tStatus;
handles.SequenceText = eSeq;
handles.CycleStr= tCycle;


data.cycleTbl = cycleTbl;
data.Status = tStatus;
data.VarText = tScanVar;
data.SequencerWatcher = sequencer_watcher(handles);
data.SequencerListener = listener(data.SequencerWatcher,...
    'CycleComplete',@CycleComplete);
data.SequencerListener.Enabled = 0;
data.JobTable = tJobs;
data.SequenceText = eSeq;
data.CycleStr = tCycle;


guidata(hF,data);

data.JobHandler = job_handler(hF);
guidata(hF,data);

%% Update Things
data.SequencerWatcher.updateSequenceFileText(seqdata.sequence_functions);


%% Assign Handles
% Add gui figure, sequecner watcher, and job handler to base workspace so
% that they may be accessed from the command line

assignin('base','jh',data.JobHandler);
assignin('base','gui_main',hF);
assignin('base','sw',data.SequencerWatcher);
end


