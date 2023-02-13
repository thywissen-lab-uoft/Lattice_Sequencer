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

defaultSequence='@main_settings,@main_sequence';
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
    'MenuBar','figure','resize','off','CloseRequestFcn',@closeFig,...
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
        catch exception
            warning('Something went wrong stopping and deleting timers');
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
    'bordertype','etchedin');
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];
hpMain.OuterPosition=[0 hF.Position(4)-h w h];

 % Jobs uipanel
hpJobs = uipanel('parent',hF,'units','pixels','backgroundcolor','w',...
    'title','jobs','bordertype','etchedin');
hpJobs.Position = [1 180 w hF.Position(4)-180];

% sequence uipanel
hpSeq = uipanel('parent',hpMain,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin','title','sequence');
hpSeq.Position(3:4)=[347 90];
hpSeq.Position(1:2)=[1 71];

% wait uipanel
hpWait = uipanel('Parent',hpMain,'units','pixels','Title','wait mode',...
    'backgroundcolor',cc);
hpWait.Position(3:4)=[347 70];
hpWait.Position(1:2)=[1 1];

% run uipanel
hpRun = uipanel('Parent',hpMain,'units','pixels','Title','run mode',...
    'backgroundcolor',cc);
hpRun.Position(3:4)=[347 160];
hpRun.Position(1:2)=[350 1];


%% Jobs Panel Graphical Objects

% Job Table
tJobs = uitable('parent',hpJobs,'fontsize',8,'rowname',{});
tJobs.ColumnName = {'id','status','n','name','sequence'};
tJobs.ColumnWidth={60 60 40 170 350};
tJobs.ColumnEditable=[false false false false false];
hme = 20;
tJobs.Position = [1 hme hpMain.Position(3) hpJobs.Position(4)-(hme+15)];

%% Sequence
% Sequence File edit box
mystr='comma separated sequnce functions (@func1,@func2,@func3,...)';
tSeq=uicontrol(hpSeq,'style','text','string',mystr,...
    'horizontalalignment','left','fontsize',7,'backgroundcolor',cc);
tSeq.Position(3)=335;
tSeq.Position(4)=tSeq.Extent(4);
tSeq.Position(1:2)=[5 46];

% Sequence File edit box
eSeq=uicontrol(hpSeq,'style','edit','string',defaultSequence,...
    'horizontalalignment','left','fontsize',8,'backgroundcolor',cc);
eSeq.Position(3)=335;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 32];
data.SequenceText = eSeq;

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'browse.jpg']),[22 22]);
bBrowse=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@browseCB,'tooltip','browse file');
bBrowse.Position(3:4)=[24 24];
bBrowse.Position(1:2)=[5 4];

bDefault=uicontrol(hpSeq,'style','pushbutton','String','default seq.',...
    'backgroundcolor',cc,'FontSize',8,'units','pixels',...
    'Callback',@defaultCB);
bDefault.Position(3:4)=[60 24];
bDefault.Position(1:2)=bBrowse.Position(1:2) + [bBrowse.Position(3)+2 0];

    function defaultCB(~,~)
       eSeq.String = defaultSequence; 
    end

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
        fh = str2func(erase(eSeq.String,'@'));        
        plotgui2;
    end

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'compile.jpg']),[20 20]);
bCompile=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@bCompileCB,'tooltip','compile sequence');
bCompile.Position(3:4)=[25 25];
bCompile.Position(1:2)=bPlot.Position(1:2)+[bPlot.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'command_window.jpg']),[20 20]);
bCmd=uicontrol(hpSeq,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) commandwindow,'tooltip',...
    'move up directory level','tooltip','command window');
bCmd.Position(3:4)=[25 25];
bCmd.Position(1:2)=bCompile.Position(1:2)+[bCompile.Position(3)+2 0];

    function bCompileCB(~,~)    
        fName=eSeq.String;        
        strs=strsplit(fName,',');
        funcs={};
        for kk=1:length(strs)
           funcs{kk} =  str2func(erase(strs{kk},'@')); 
        end
        compile(funcs)        
        updateScanVarText;    
    end

    function browseCB(~,~)
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
        funcname=['@' erase(file,'.m')];
        eSeq.String=funcname;
        disp([datestr(now,13) ' New sequence function is ' funcname]);
    end

    function fileCB(~,~,n)
        fname = strrep(eSeq.String,'@','');
        try            
            fName=eSeq.String;        
            strs=strsplit(fName,',');
            names={};
            for kk=1:length(strs)
                names{kk} =  erase(strs{kk},'@'); 
            end
            
            disp(['Opening ' names{n}]);
            open(names{n});
        catch ME
            warning(ME.message);
        end        
    end

%% Wait Timer Graphical interface

% Button group for selecting wait mode. The user data holds the selected
% button
bgWait = uibuttongroup('Parent',hpWait,'units','pixels','backgroundcolor',cc,...
    'BorderType','none');
bgWait.Position(3:4)=[347 20];
bgWait.Position(1:2)=[1 30];

% Create three radio buttons in the button group. The user data holds the
% selected mode (0,1,2) --> (no wait, intercyle, target time)
uicontrol(bgWait,'Style','radiobutton', 'String','none',...
    'Position',[5 1 100 20],'Backgroundcolor',cc,'UserData',0,'value',0);  
uicontrol(bgWait,'Style','radiobutton','String','intercycle',...
    'Position',[50 1 100 20],'Backgroundcolor',cc,'UserData',1,'value',1);
uicontrol(bgWait,'Style','radiobutton','String','total',...
    'Position',[120 1 100 20],'Backgroundcolor',cc,'UserData',2,'value',0);              

% Table for storing value of wait time
tblWait=uitable(hpWait,'RowName','','ColumnName','','Data',waitDefault,...
    'ColumnWidth',{30},'ColumnEditable',true,'ColumnFormat',{'numeric'},...
    'fontsize',8,'Enable','on');
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4);
tblWait.Position(1:2)=[260 30];

% Seconds label for the wait time.
tWait=uicontrol(hpWait,'style','text','string','seconds',...
    'fontsize',8,'units','pixels','backgroundcolor',cc);
tWait.Position(3:4)=tWait.Extent(3:4);
tWait.Position(1)=tblWait.Position(1)+tblWait.Position(3)+2;
tWait.Position(2)=tblWait.Position(2);

% Axis object for plotting the wait bar
waitbarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',hpWait,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1:2)=[10 5];
axWaitBar.Position(3:4)=[bgWait.Position(3)-20 10];
title('Wait Timer');

% Plot the wait bar
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],waitbarcolor);

% String labels for time end points
tWaitTime1 = text(0,0,'0.00 s','parent',axWaitBar,'fontsize',10,...
    'horizontalalignment','left','units','pixels','verticalalignment','bottom');
tWaitTime1.Position=[5 10];
tWaitTime2 = text(0,0,'10.00 s','parent',axWaitBar,'fontsize',10,...
    'horizontalalignment','right','units','pixels','verticalalignment','bottom');
tWaitTime2.Position=[axWaitBar.Position(3) 10];



%% Run mode graphics and callbacks


% Adwin Progress bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',hpRun,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=[10 10 hpRun.Position(3)-20 10];
axAdWinBar.Position(2) = 100;
% Plot the patch of color for the bar
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1], adwinbarcolor);

% Add some text labels for the current and end time
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','left','units','pixels','verticalalignment','bottom');
tAdWinTime1.Position=[5 10];
tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','right','units','pixels','verticalalignment','bottom');
tAdWinTime2.Position=[axAdWinBar.Position(3) 10];

% Add an overall label
text(.5,1.05,'adwin progress','fontsize',10,'horizontalalignment','center', ...
    'verticalalignment','bottom','fontweight','bold');

% Button to run the cycle
bRunIter=uicontrol(hpRun,'style','pushbutton','String','Run Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','Callback',{@bRunCB 0});
bRunIter.Position(3:4)=[85 20];bRunIter.Position(1:2)=[5 30];
bRunIter.Tooltip='Run the current sequence.';

% Button to run the cycle
bStartScan=uicontrol(hpRun,'style','pushbutton','String','Start Scan',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold');
bStartScan.Position(3:4)=[85 20];
bStartScan.Position(1:2)=[5 5];
bStartScan.Callback={@bRunCB 1};
bStartScan.Tooltip='Start the scan.';

% Button to run the cycle
bContinue=uicontrol(hpRun,'style','pushbutton','String','Resume Scan',...
    'backgroundcolor',[173 216 230]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold');
bContinue.Position(3:4)=[85 20];
bContinue.Position(1:2)=[95 5];
bContinue.Callback={@bRunCB 2};
bContinue.Tooltip='resume the scan from current iteration.';

% Button to stop scan
bStop=uicontrol(hpRun,'style','pushbutton','String','Stop Scan',...
    'backgroundcolor',[255	218	107]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@bStopCB,'Tooltip','stop scan');
bStop.Position(3:4)=[85 20];
bStop.Position(1:2)=[185 5];

% Button to reset cycle number to one
bResetCycleNum=uicontrol(hpRun,'style','pushbutton','String','reset cycle#',...
    'backgroundcolor',[238,232,170]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','callback',@bResetCycleNumCB);
bResetCycleNum.Position(3:4)=[85 20];
bResetCycleNum.Position(1:2)=[95 30];
bResetCycleNum.Tooltip='Reset cycle number';

% Status String
ttt=uicontrol(hpRun,'style','text','string','cycle #',...
    'backgroundcolor','w','fontsize',8,'units','pixels');
ttt.Position(3:4)=ttt.Extent(3:4);
ttt.Position(1:2)=[290 38];

cycleTbl=uitable(hpRun,'RowName',{},'ColumnName',{},...
    'ColumnEditable',[true],'Data',[1],'units','pixels',...
    'ColumnWidth',{50},'FontSize',10,'CellEditCallback',@tblCB);
cycleTbl.Position(3:4)=cycleTbl.Extent(3:4);
cycleTbl.Position(1:2)=[285 20];

    function tblCB(src,evt)
        n = evt.NewData;
        if ~isnan(n) && isnumeric(n) && floor(n)==n && ~isinf(n) && n>0
            seqdata.scancycle = evt.NewData;
        else
            src.Data = evt.PreviousData;
        end
    end

% Checkbox for repeat cycle
cRpt=uicontrol(hpRun,'style','checkbox','string','repeat cycle?','fontsize',8,...
    'backgroundcolor',cc,'units','pixels');
cRpt.Position(3:4)=[100 cRpt.Extent(4)];
cRpt.Position(1:2)=[185 33];
cRpt.Tooltip='Enable or disable automatic repitition of the sequence.';

% Status String
tStatus=uicontrol(hpRun,'style','text','string','idle',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','bold','visible','on','horizontalalignment','center');
tStatus.Position(3:4)=[axAdWinBar.Position(3) 15];
tStatus.Position(1:2)=[bStop.Position(1)+bStop.Position(3) 1];
tStatus.Position(1) = axAdWinBar.Position(1);
tStatus.Position(2) = axAdWinBar.Position(2) - 15;
tStatus.ForegroundColor=[0 128 0]/255;

% Scan Var
tScanVar=uicontrol(hpRun,'style','text','string','No detected variable scanning with ParamDef/Get.',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','normal','visible','on','horizontalalignment','center');
tScanVar.Position(3:4)=[axAdWinBar.Position(3) 15];
tScanVar.Position(1) = axAdWinBar.Position(1);
tScanVar.Position(2) = tStatus.Position(2) - 15;

% Button to reseed random list
ttStr=['Reseed random list of scan indeces.'];
bRandSeed=uicontrol(hpRun,'style','pushbutton','String','reseed random',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bRandSeed.Position(3:4)=[80 16];
bRandSeed.Position(1:2)=[1 hpRun.Position(4)-bRandSeed.Position(4)-14];
bRandSeed.Callback=@(src,evt) bReseedRandom;

    function bReseedRandom(~,~)
       seqdata.randcyclelist = makeRandList ;
    end


% Button to abort adwin (not well tested)
ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
    'outputs to their reset value.  DANGEROUS'];
bAbort=uicontrol(hpRun,'style','pushbutton','String','abort',...
    'backgroundcolor','r','FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr,'Callback',@bAbortCB);
bAbort.Position(3:4)=[40 15];
bAbort.Position(1:2)=[hpRun.Position(3)-bAbort.Position(3)-5 ...
    hpRun.Position(4)-bAbort.Position(4)-12];

% Button to reset adwin (not well tested)
ttStr=['Reinitialize channels and reset Adwin outputs ' ...
    'to default values.'];
bReset=uicontrol(hpRun,'style','pushbutton','String','reset',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bReset.Position(3:4)=[40 15];
bReset.Position(1:2)=[bAbort.Position(1)-bReset.Position(3) ...
    bAbort.Position(2)];
bReset.Callback=@bResetCB;

%% Button Callbacks

    function CycleComplete(src,evt)        
        d=guidata(hF);
        d.SequencerListener.Enabled = 0;
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
           warning('The sequencer running you dummy!');
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

    function bResetCycleNumCB(~,~)
        cycleTbl.Data = 1;
        seqdata.scancycle = 1;
    end

    function runSequenceCB    
        fName=eSeq.String;        
        strs=strsplit(fName,',');
        funcs={};
        for kk=1:length(strs)
           funcs{kk} =  str2func(erase(strs{kk},'@')); 
        end        
        d=guidata(hF);
        d.SequencerWatcher.RequestWaitTime = d.SequencerWatcher.WaitTable.Data;

        runSequence(funcs);    
        d.SequencerListener.Enabled=1;
    end    

% Reset Button callback
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

handles.WaitButtons = bgWait;
handles.WaitTable = tblWait;
handles.WaitBar = pWaitBar;
handles.WaitStr1 = tWaitTime1;
handles.WaitStr2 = tWaitTime2;
handles.AdwinBar = pAdWinBar;
handles.AdwinStr1 = tAdWinTime1;
handles.AdwinStr2 = tAdWinTime2;
handles.StatusStr = tStatus;

data.cycleTbl = cycleTbl;
data.Status = tStatus;
data.VarText = tScanVar;
data.SequencerWatcher = sequencer_watcher(handles);
data.SequencerListener = listener(data.SequencerWatcher,...
    'CycleComplete',@CycleComplete);
data.SequencerListener.Enabled = 0;
data.JobTable = tJobs;


assignin('base','gui_main',hF);

guidata(hF,data);

jh =  job_handler(hF);
assignin('base','jh',jh);

end


