function hF=mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.
%
% Author      : CJ Fujiwara
% Last Edited : 2023/02
%
% Much of this code has been slowly morphed over the years from previous
% graduate students.
%
% CF has attempted to improve the code architecture.


% Close any figure with the same name. Only one instance of mainGUI may be
% open at a time
figs = get(groot,'Children');
for i = 1:length(figs)
    if isequal(figs(i).UserData,'sequencer_gui')       
       warning('Sequencer GUI already open. Please close it if you want a new instace');
       figure(figs(i));
       return;
    end
end

%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;
global adwinprocessnum;

seqdata.doscan = 0;
seqdata.randcyclelist = makeRandList;

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

disp('Opening Lattice Sequencer...');
%% Delete old timer objects
% The progress of the sequence is tracked using some MATLAB timers. Delete
% these timers so that MATLAB doesn't get confused and make a whole bunch
% of timer instances.  CF's understanding of how timers are saved in 
% different MATLAB workspaces may be a little dated.  
%
% You may check existing timer instances with timerfindall. 

% Names of timers, defined here so that the constructor uses the same name
% to make the timers later
adwinTimeName='AdwinProgressTimer';
waitTimeName='InterCycleWaitTimer';

% Delete any existing timers
delete(timerfind('Name',adwinTimeName));
delete(timerfind('Name',waitTimeName));
%% Initialize Primary Figure graphics

% Figure color and size settings
cc='w';w=700;h=170;

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,'NumberTitle','off',...
    'MenuBar','figure','resize','off','CloseRequestFcn',@closeFig,...
    'UserData','sequencer_gui');
clf
hF.Position(3:4)=[w h];
set(hF,'WindowStyle','docked');
data = struct;

timer_handles = struct;

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
%% Main Panel

% Main uipanel
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin');
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];
hpMain.OuterPosition=[0 hF.Position(4)-h w h];

%% Settings Graphical Objects

hpSeq = uipanel('parent',hpMain,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin','title','sequence');
hpSeq.Position(3:4)=[347 90];
hpSeq.Position(1:2)=[1 71];

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
    'backgroundcolor',cc,'Callback',@(~,~) commandwindow,'tooltip','move up directory level','tooltip','command window');
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
            warning('Cant open sequence file for some reason');
        end        
    end

%% Wait Timer Graphical interface

hpWait = uipanel('Parent',hpMain,'units','pixels','Title','wait mode',...
    'backgroundcolor',cc);
hpWait.Position(3:4)=[347 70];
hpWait.Position(1:2)=[1 1];

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

% Run sequence mode
bgRun = uibuttongroup('Parent',hpMain,'units','pixels','Title','run mode',...
    'backgroundcolor',cc,'UserData',0,'SelectionChangedFcn',@runModeCB);
bgRun.Position(3:4)=[347 160];bgRun.Position(1:2)=[350 1];
        
    function runModeCB(~,evnt)
        switch evnt.NewValue.String
            case 'single'
                disp('Changing run mode to single iteration');
                bRunIter.Enable     = 'on';
                bRunIter.Visible    = 'on';                
                bStartScan.Visible  = 'off';
                bStartScan.Enable   = 'off';                    
                bContinue.Visible   = 'off';
                bContinue.Enable    = 'off';                
                bStop.Visible       = 'off';
            case 'scan'
                disp('Changing run mode to scan mode.');
                bRunIter.Enable     = 'on';
                bRunIter.Visible    = 'on';                
                bStartScan.Visible  = 'on';
                bStartScan.Enable   = 'on';                   
                bContinue.Visible   = 'on';
                bContinue.Enable    = 'on';                
                bStop.Visible       = 'on';
        end        
    end

% Radio button for single mode
rSingle=uicontrol(bgRun,'Style','radiobutton', 'String','single',...
    'Position',[5 90 65 30],'Backgroundcolor',cc,'UserData',0,...
    'fontsize',8,'Value',1);  
rSingle.Position(2) = bgRun.Position(4)-rSingle.Position(4)-7;

% Radio button for scan mode
rScan=uicontrol(bgRun,'Style','radiobutton','String','scan',...
    'Position',[55 85 100 30],'Backgroundcolor',cc,'UserData',1,...
    'FontSize',8);
rScan.Position(2) = rSingle.Position(2);

%%%%%%%%%%%%%%%%%%%%% ADWIN PROGRESS BAR  %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create axis object for the bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',bgRun,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=[10 10 bgRun.Position(3)-20 10];
axAdWinBar.Position(2) = rScan.Position(2)-axAdWinBar.Position(4)-15;
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

%% Run Controls

% Button to run the cycle
bRunIter=uicontrol(bgRun,'style','pushbutton','String','Run Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','Callback',{@bRunCB 0});
bRunIter.Position(3:4)=[100 20];bRunIter.Position(1:2)=[5 30];
bRunIter.Tooltip='Run the current sequence.';

% Button to run the cycle
bStartScan=uicontrol(bgRun,'style','pushbutton','String','Start Scan',...
    'backgroundcolor',[152 251 152]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','Visible','off','enable','off');
bStartScan.Position(3:4)=[100 20];
bStartScan.Position(1:2)=[5 5];
bStartScan.Callback={@bRunCB 1};
bStartScan.Tooltip='Start the scan.';

% Button to run the cycle
bContinue=uicontrol(bgRun,'style','pushbutton','String','Continue Scan',...
    'backgroundcolor',[173 216 230]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','Visible','off','enable','off');
bContinue.Position(3:4)=[110 20];
bContinue.Position(1:2)=[110 5];
bContinue.Callback={@bRunCB 2};
bContinue.Tooltip='Continue the scan from current iteration.';

% Button to stop
bStop=uicontrol(bgRun,'style','pushbutton','String','Stop Scan',...
    'backgroundcolor',[255	218	107]/255,'FontSize',8,'units','pixels',...
    'fontweight','bold','enable','on','visible','off');
bStop.Position(3:4)=[100 20];
bStop.Position(1:2)=[225 5];
bStop.Callback=@bStopCB;
bStop.Tooltip='Compile and run the currently selected sequence.';


cycleTbl=uitable(bgRun,'RowName','Cycle #','ColumnName',{},...
    'ColumnEditable',[true],'Data',[1],'units','pixels',...
    'ColumnWidth',{50},'FontSize',12,'CellEditCallback',@tblCB);
cycleTbl.Position(3:4)=cycleTbl.Extent(3:4);
cycleTbl.Position(1:2)=[110 bRunIter.Position(2)+2];

    function tblCB(src,evt)
        n = evt.NewData;
        if ~isnan(n) && isnumeric(n) && floor(n)==n && ~isinf(n) && n>0
            seqdata.scancycle = evt.NewData;
        else
            src.Data = evt.PreviousData;
        end
    end

% Checkbox for repeat cycle
cRpt=uicontrol(bgRun,'style','checkbox','string','repeat cycle?','fontsize',8,...
    'backgroundcolor',cc,'units','pixels');
cRpt.Position(3:4)=[100 cRpt.Extent(4)];
cRpt.Position(1:2)=[cycleTbl.Position(1)+cycleTbl.Position(3)+5 cycleTbl.Position(2)];
cRpt.Tooltip='Enable or disable automatic repitition of the sequence.';

% Status String
tStatus=uicontrol(bgRun,'style','text','string','idle',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','bold','visible','on','horizontalalignment','center');
tStatus.Position(3:4)=[axAdWinBar.Position(3) 15];
tStatus.Position(1:2)=[bStop.Position(1)+bStop.Position(3) 1];
tStatus.Position(1) = axAdWinBar.Position(1);
tStatus.Position(2) = axAdWinBar.Position(2) - 15;
tStatus.ForegroundColor=[0 128 0]/255;

% Scan Var
tScanVar=uicontrol(bgRun,'style','text','string','No detected variable scanning with ParamDef/Get.',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','normal','visible','on','horizontalalignment','center');
tScanVar.Position(3:4)=[axAdWinBar.Position(3) 15];
tScanVar.Position(1) = axAdWinBar.Position(1);
tScanVar.Position(2) = tStatus.Position(2) - 15;

% Button to reseed random list
ttStr=['Reseed random list of scan indeces.'];
bRandSeed=uicontrol(bgRun,'style','pushbutton','String','reseed random',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bRandSeed.Position(3:4)=[80 16];
bRandSeed.Position(1:2)=[100 bgRun.Position(4)-bRandSeed.Position(4)-14];
bRandSeed.Callback=@bReseedRandom;

    function bReseedRandom(~,~)
       seqdata.randcyclelist = makeRandList ;
    end

%% Interrupt buttons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ABORT  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
    'outputs to their reset value.  DANGEROUS'];
bAbort=uicontrol(bgRun,'style','pushbutton','String','abort',...
    'backgroundcolor','r','FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr,'Callback',@bAbortCB);
bAbort.Position(3:4)=[40 15];
bAbort.Position(1:2)=[bgRun.Position(3)-bAbort.Position(3)-5 ...
    bgRun.Position(4)-bAbort.Position(4)-12];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESET  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Reinitialize channels and reset Adwin outputs ' ...
    'to default values.'];
bReset=uicontrol(bgRun,'style','pushbutton','String','reset',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bReset.Position(3:4)=[40 15];
bReset.Position(1:2)=[bAbort.Position(1)-bReset.Position(3) ...
    bAbort.Position(2)];
bReset.Callback=@bResetCB;

%% Sequence Watcher
timer_handles.WaitButtons = bgWait;
timer_handles.WaitTable = tblWait;
timer_handles.WaitBar = pWaitBar;
timer_handles.WaitStr1 = tWaitTime1;
timer_handles.WaitStr2 = tWaitTime2;
timer_handles.AdwinBar = pAdWinBar;
timer_handles.AdwinStr1 = tAdWinTime1;
timer_handles.AdwinStr2 = tAdWinTime2;
timer_handles.StatusStr = tStatus;

%% Button Callbacks

    function CycleComplete(src,evt)        
        d=guidata(hF);
        d.SequencerListener.Enabled = 0;
        if cRpt.Value
            disp('Repeating the sequence');
            runSequenceCB;
        else
            if seqdata.doscan
                % Increment the scan and run the sequencer again
                seqdata.scancycle = seqdata.scancycle+1;
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
                if isequal(bgRun.SelectedObject.String,'single')
                    seqdata.scancycle = 1;
                else
                    seqdata.scancycle = cycleTbl.Data;
                end      
            case 1 % 1 : start a scan
                seqdata.doscan      = 1;
                seqdata.scancycle = 1;
            case 2 % Continue the scan
                seqdata.doscan      = 1;
        end  
        runSequenceCB;        
    end

    function bStopCB(~,~)
        switch bgRun.SelectedObject.String
            case 'single'
                warning('HOW DID YOU GET HERE BAD');                
            case 'scan'
                disp('Stopping the scan. Wait until next iteration is complete.');
                seqdata.doscan=0; 
        end  
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

data.pWaitBar = pWaitBar;
data.tWaitTime1 = tWaitTime1;
data.tWaitTime2 = tWaitTime2;
data.pAdWinBar = pAdWinBar;
data.tAdWinTime1 = tAdWinTime1;
data.tAdWinTime2 = tAdWinTime2;
data.cycleTbl = cycleTbl;
data.Status = tStatus;
data.VarText = tScanVar;
data.SequencerWatcher = sequencer_watcher(timer_handles);
data.SequencerListener = listener(data.SequencerWatcher,'CycleComplete',@CycleComplete);
data.SequencerListener.Enabled = 0;

guidata(hF,data);

end


