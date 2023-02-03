function hF=mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.  However, edits to the actual sequence need to be done in the code.
% Please refer to the relevant sequence files to edit those.
%
% Author      : CJ Fujiwara
% Last Edited : 2023/02
%
% In order to make this code work with the existing code in the lab
% designed by D. McKay (an early graduate student), many aspects of this
% code have been "Frakenstein'ed" together. It is the author's desire that
% this code be optimized and simplified.

doDebug = 0;
%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;
global adwinprocessnum;
seqdata.randcyclelist = makeRandList;

evalin('base','global seqdata')
evalin('base','openvar(''seqdata'')')
evalin('base','openvar(''seqdata.flags'')')
evalin('base','openvar(''seqdata.params'')')

waitDefault=30;
compath='Y:\_communication';

camera_control_file = 'Y:\_communication\pco_control.mat';
analysis_summary_file = 'Y:\_communication\pco_analysis_summary.mat';

defaultSequence='@main_sequence';

if ~doDebug
    figName='Main GUI';
else
    figName = 'DEBUG MODE';
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

% Close any figure with the same name. Only one instance of mainGUI may be
% open at a time
figs = get(groot,'Children');
for i = 1:length(figs)
    if isequal(figs(i).Name,figName)        
       close(figName); 
    end
end

% Figure color and size settings
cc='w';w=350;h=340;

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,'NumberTitle','off',...
    'MenuBar','figure','resize','off','CloseRequestFcn',@closeFig);
clf
hF.Position(3:4)=[w h];
set(hF,'WindowStyle','docked');
data = struct;

%% Figure
% Callback for a close request function. The close request function handles
% whether the adwin is running or other potential timer issues.
    function closeFig(fig,~)
       disp('Requesting to close the sequencer GUI.');        
       if (~isempty(timerfind('Name',adwinTimeName)) && ...
               isequal(timeAdwin.Running,'on')) || ...
               (cRpt.Value && isequal(timeWait.Running,'on'))
           tt=['The sequence is still running or repitions are engaged '...
               'with the wait timer running. Are you sure you want to ' ...
               'close the GUI? If the sequence data has already been ' ...
               'sent to the Adwin, the experiment will still be running.'];
           tit='Sequence is still running!';           
           f2=figure('Name',tit,'color','w','NumberTitle','off',...
               'windowstyle','modal','units','pixels','resize','off');
           f2.Position(3:4)=[400 200];
           f2.Position(1:2)=fig.Position(1:2)+[-50 100];           
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
                stop(timeAdwin);
                stop(timeWait);
                delete(timeAdwin);
                delete(timeWait); 
            catch exception
                warning('Something went wrong stopping and deleting timers');
            end
            delete(fig);
       end
       
        function doClose(~,~)
            close(f2);
            disp('Closing the sequencer GUI. Goodybe. I love you');
            stop(timeAdwin);
            stop(timeWait);
            pause(0.5);
            delete(fig);
        end       
    end

% Main uipanel
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin');
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];
hpMain.OuterPosition=[0 hF.Position(4)-h w h];

% Title String
tTit=uicontrol(hpMain,'style','text','string','Main GUI',...
    'FontSize',10,'fontweight','bold','units','pixels','backgroundcolor',cc);
tTit.Position(3:4)=tTit.Extent(3:4);
tTit.Position(1:2)=[5 hpMain.Position(4)-tTit.Position(4)-3];

%% Settings Graphical Objects

% Sequence File label
tSeq=uicontrol(hpMain,'style','text','String','Sequence File:',...
    'units','pixels','fontsize',8,'backgroundcolor',cc);
tSeq.Position(3:4)=tSeq.Extent(3:4);
tSeq.Position(1:2)=[5 tTit.Position(2)-tSeq.Position(4)];

% Sequence File edit box
eSeq=uicontrol(hpMain,'style','edit','string',defaultSequence,...
    'horizontalalignment','left','fontsize',10,'backgroundcolor',cc);
eSeq.Position(3)=180;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 tSeq.Position(2)-eSeq.Position(4)];
data.SequenceText = eSeq;

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'browse.jpg']),[22 22]);
bBrowse=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@browseCB,'tooltip','browse file');
bBrowse.Position(3:4)=[24 24];
bBrowse.Position(1:2)=eSeq.Position(1:2)+[eSeq.Position(3)+2 0];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'folder_up.jpg']),[20 20]);
bDirUp=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) cd('..'),'tooltip','move up directory level');
bDirUp.Position(3:4)=[24 24];
bDirUp.Position(1:2)=bBrowse.Position(1:2)+[bBrowse.Position(3)+2 0];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI/images' filesep 'file.png']),[17 17]);
bFile=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@fileCB,'tooltip','open file');
bFile.Position(3:4)=[24 24];
bFile.Position(1:2)=bDirUp.Position(1:2)+[bDirUp.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'plot.jpg']),[24 24]);
bPlot=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@bPlotCB,'tooltip','plot');
bPlot.Position(3:4)=[25 25];
bPlot.Position(1:2)=bFile.Position(1:2)+[bFile.Position(3)+2 0];

    function bPlotCB(~,~)
        fh = str2func(erase(eSeq.String,'@'));        
        plotgui2;
    end

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'compile.jpg']),[20 20]);
bCompile=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@bCompileCB,'tooltip','compile sequence');
bCompile.Position(3:4)=[25 25];
bCompile.Position(1:2)=bPlot.Position(1:2)+[bPlot.Position(3)+2 0];

% Button to recompile seqdata
cdata=imresize(imread(['GUI/images' filesep 'command_window.jpg']),[20 20]);
bCmd=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@(~,~) commandwindow,'tooltip','move up directory level','tooltip','command window');
bCmd.Position(3:4)=[25 25];
bCmd.Position(1:2)=bCompile.Position(1:2)+[bCompile.Position(3)+2 0];

    function bCompileCB(~,~)    
        fName=eSeq.String;
        fh = str2func(erase(fName,'@'));     
        fcns={fh};

        compile(fcns)        
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

    function fileCB(~,~)
        fname = strrep(eSeq.String,'@','');
        try
            disp(['Opening ' fname]);
            open(fname);
        catch ME
            warning('Cant open sequence file for some reason');
        end        
    end

%% Wait Timer Graphical interface

% Button group for selecting wait mode. The user data holds the selected
% button
bgWait = uibuttongroup('Parent',hpMain,'units','pixels','Title','wait mode',...
    'backgroundcolor',cc,'UserData',1,'SelectionChangedFcn',@waitCB);
bgWait.Position(3:4)=[w 90];
bgWait.Position(1:2)=[1 180];

% Create three radio buttons in the button group. The user data holds the
% selected mode (0,1,2) --> (no wait, intercyle, target time)
uicontrol(bgWait,'Style','radiobutton', 'String','none',...
    'Position',[5 50 100 20],'Backgroundcolor',cc,'UserData',0,'value',0);  
uicontrol(bgWait,'Style','radiobutton','String','intercycle',...
    'Position',[50 50 100 20],'Backgroundcolor',cc,'UserData',1,'value',1);
uicontrol(bgWait,'Style','radiobutton','String','total',...
    'Position',[120 50 100 20],'Backgroundcolor',cc,'UserData',2,'value',0);              
uicontrol(bgWait,'Style','radiobutton','String','auto',...
    'Position',[165 50 100 20],'Backgroundcolor',cc,'UserData',3,'value',0);   

% Table for storing value of wait time
tblWait=uitable(bgWait,'RowName','','ColumnName','','Data',waitDefault,...
    'ColumnWidth',{30},'ColumnEditable',true,'ColumnFormat',{'numeric'},...
    'fontsize',8,'Enable','on');
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4);
tblWait.Position(1:2)=[260 50];

% Seconds label for the wait time.
tWait=uicontrol(bgWait,'style','text','string','seconds',...
    'fontsize',8,'units','pixels','backgroundcolor',cc);
tWait.Position(3:4)=tWait.Extent(3:4);
tWait.Position(1)=tblWait.Position(1)+tblWait.Position(3)+2;
tWait.Position(2)=tblWait.Position(2);

    function waitCB(~,rbutton)        
        switch rbutton.NewValue.UserData            
            case 0 % no wait
                disp('Disabling intercyle wait.');
                bgWait.UserData     = 0;               
                tblWait.Enable      = 'off';
                tWaitTime1.String   = 'n/a';
                tWaitTime2.String   = 'n/a';
                stop(timeWait);
            case 1
                disp(['Wait timer engaged. Inter-cycle wait time mode. ' ...
                    ' This will be updated at end of next cycle.']);
                bgWait.UserData     = 1;
                tblWait.Enable      = 'on';           
                tWaitTime1.String   = '~ s';
                tWaitTime2.String   = '~ s';
            case 2
                disp(['Wait timer engaged. Total sequence wait time mode. ' ...
                    ' This will be updated at end of next cycle.']);
                bgWait.UserData     = 2;
                tblWait.Enable      = 'on';
                tWaitTime1.String   = '~ s';
                tWaitTime2.String   = '~ s';
        end        
    end

% Axis object for plotting the wait bar
waitbarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',bgWait,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1:2)=[10 5];
axWaitBar.Position(3:4)=[bgWait.Position(3)-20 tblWait.Position(4)];
title('Wait Timer');

% Plot the wait bar
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],waitbarcolor);

% String labels for time end points
tWaitTime1 = text(0,0,'0.00 s','parent',axWaitBar,'fontsize',10,...
    'horizontalalignment','left','units','pixels','verticalalignment','bottom');
tWaitTime1.Position=[5 24];
tWaitTime2 = text(0,0,'10.00 s','parent',axWaitBar,'fontsize',10,...
    'horizontalalignment','right','units','pixels','verticalalignment','bottom');
tWaitTime2.Position=[axWaitBar.Position(3) 24];

%% Run mode graphics and callbacks

% Run sequence mode
bgRun = uibuttongroup('Parent',hpMain,'units','pixels','Title','run mode',...
    'backgroundcolor',cc,'UserData',0,'SelectionChangedFcn',@runModeCB);
bgRun.Position(3:4)=[w 180];bgRun.Position(1:2)=[1 1];
        
    function runModeCB(~,evnt)
        switch evnt.NewValue.String
            case 'single'
                disp('Changing run mode to single iteration');
                bRunIter.String     = 'Run Cycle #1';         
                bRunIter.Enable     = 'on';
                bRunIter.Visible    = 'on';                
                bStartScan.Visible  = 'off';
                bStartScan.Enable   = 'off';                    
                bContinue.Visible   = 'off';
                bContinue.Enable    = 'off';                
                bStop.Visible       = 'off';
                cycleTbl.ColumnEditable = false;
            case 'scan'
                disp('Changing run mode to scan mode.');
                bRunIter.String     = 'Run Cycle';                
                bRunIter.Enable     = 'on';
                bRunIter.Visible    = 'on';                
                bStartScan.Visible  = 'on';
                bStartScan.Enable   = 'on';                   
                bContinue.Visible   = 'on';
                bContinue.Enable    = 'on';                
                bStop.Visible       = 'on';
                cycleTbl.ColumnEditable = true;
        end        
    end

% Radio button for single mode
rSingle=uicontrol(bgRun,'Style','radiobutton', 'String','single',...
    'Position',[5 85 65 30],'Backgroundcolor',cc,'UserData',0,...
    'fontsize',12);  
rSingle.Position(2) = bgRun.Position(4)-rSingle.Position(4)-15;


% Radio button for scan mode
rScan=uicontrol(bgRun,'Style','radiobutton','String','scan',...
    'Position',[75 85 100 30],'Backgroundcolor',cc,'UserData',1,...
    'FontSize',12);
rScan.Position(2) = rSingle.Position(2);

%%%%%%%%%%%%%%%%%%%%% ADWIN PROGRESS BAR  %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create axis object for the bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',bgRun,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=[10 10 bgRun.Position(3)-20 20];
axAdWinBar.Position(2) = rScan.Position(2)-axAdWinBar.Position(4)-15;
% Plot the patch of color for the bar
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1], adwinbarcolor);

% Add some text labels for the current and end time
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','left','units','pixels','verticalalignment','bottom');
tAdWinTime1.Position=[5 21];
tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','right','units','pixels','verticalalignment','bottom');
tAdWinTime2.Position=[axAdWinBar.Position(3) 21];

% Add an overall label
text(.5,1.05,'adwin progress','fontsize',10,'horizontalalignment','center', ...
    'verticalalignment','bottom','fontweight','bold');

%% Run Controls

% Button to run the cycle
bRunIter=uicontrol(bgRun,'style','pushbutton','String','Run Cycle #1',...
    'backgroundcolor',[152 251 152]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','Callback',{@bRunCB 0});
bRunIter.Position(3:4)=[100 30];bRunIter.Position(1:2)=[5 40];
bRunIter.Tooltip='Run the current sequence.';

% Button to run the cycle
bStartScan=uicontrol(bgRun,'style','pushbutton','String','Start Scan',...
    'backgroundcolor',[152 251 152]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','Visible','off','enable','off');
bStartScan.Position(3:4)=[100 30];
bStartScan.Position(1:2)=[5 5];
bStartScan.Callback={@bRunCB 1};
bStartScan.Tooltip='Start the scan.';

% Button to run the cycle
bContinue=uicontrol(bgRun,'style','pushbutton','String','Continue Scan',...
    'backgroundcolor',[173 216 230]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','Visible','off','enable','off');
bContinue.Position(3:4)=[110 30];
bContinue.Position(1:2)=[110 5];
bContinue.Callback={@bRunCB 2};
bContinue.Tooltip='Continue the scan from current iteration.';

% Button to stop
bStop=uicontrol(bgRun,'style','pushbutton','String','Stop Scan',...
    'backgroundcolor',[255	218	107]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off','visible','off');
bStop.Position(3:4)=[100 30];
bStop.Position(1:2)=[225 5];
bStop.Callback=@bStopCB;
bStop.Tooltip='Compile and run the currently selected sequence.';


cycleTbl=uitable(bgRun,'RowName','Cycle #','ColumnName',{},...
    'ColumnEditable',[false],'Data',[1],'units','pixels',...
    'ColumnWidth',{50},'FontSize',12);
cycleTbl.Position(3:4)=cycleTbl.Extent(3:4);
cycleTbl.Position(1:2)=[110 bRunIter.Position(2)+2];

% Checkbox for repeat cycle
cRpt=uicontrol(bgRun,'style','checkbox','string','repeat cycle?','fontsize',8,...
    'backgroundcolor',cc,'units','pixels');
cRpt.Position(3:4)=[100 cRpt.Extent(4)];
cRpt.Position(1:2)=[cycleTbl.Position(1)+cycleTbl.Position(3)+5 cycleTbl.Position(2)];
cRpt.Tooltip='Enable or disable automatic repitition of the sequence.';

% Status String
tStatus=uicontrol(bgRun,'style','text','string','Sequencer is idle.',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','bold','visible','on','horizontalalignment','center');
tStatus.Position(3:4)=[axAdWinBar.Position(3) 15];
tStatus.Position(1:2)=[bStop.Position(1)+bStop.Position(3) 1];
tStatus.Position(1) = axAdWinBar.Position(1);
tStatus.Position(2) = axAdWinBar.Position(2) - 15;
data.Status = tStatus;

% Scan Var
tScanVar=uicontrol(bgRun,'style','text','string','No detected variable scanning with ParamDef/Get.',...
    'backgroundcolor','w','fontsize',8,'units','pixels',...
    'fontweight','normal','visible','on','horizontalalignment','center');
tScanVar.Position(3:4)=[axAdWinBar.Position(3) 15];
tScanVar.Position(1) = axAdWinBar.Position(1);
tScanVar.Position(2) = tStatus.Position(2) - 15;
data.StatusSub = tScanVar;

    function updateScanVarText
        if isfield(seqdata,'ScanVar') && ~isempty(seqdata.ScanVar)
            str = '';
            scan_var_names = fieldnames(seqdata.ScanVar);
            for jj=1:length(scan_var_names)
                str = [str scan_var_names{jj} ' : ' num2str(seqdata.ScanVar.(scan_var_names{jj})) '; '];
            end
            tScanVar.String = str;
        end        
    end

% Button to reseed random list
ttStr=['Reseed random list of scan indeces.'];
bRandSeed=uicontrol(bgRun,'style','pushbutton','String','reseed random',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bRandSeed.Position(3:4)=[80 20];
bRandSeed.Position(1:2)=[bgRun.Position(3)-bRandSeed.Position(3)-5  bgRun.Position(4)-bRandSeed.Position(4)-12];
bRandSeed.Callback=@bReseedRandom;

    function bReseedRandom(~,~)
       seqdata.randcyclelist = makeRandList ;
    end

%% Interrupt buttons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ABORT  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
    'outputs to their reset value.  DANGEROUS'];
bAbort=uicontrol(hpMain,'style','pushbutton','String','abort',...
    'backgroundcolor','r','FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr,'Callback',@bAbortCB);
bAbort.Position(3:4)=[40 15];
bAbort.Position(1:2)=[hpMain.Position(3)-bAbort.Position(3)-5 ...
    hpMain.Position(4)-bAbort.Position(4)-5];

jbAbort= findjobj(bAbort);
set(jbAbort,'Enabled',false);
set(jbAbort,'ToolTipText',ttStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESET  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Reinitialize channels and reset Adwin outputs ' ...
    'to default values.'];
bReset=uicontrol(hpMain,'style','pushbutton','String','reset',...
    'backgroundcolor',[255,165,0]/255,'FontSize',8,'units','pixels',...
    'fontweight','normal','Tooltip',ttStr);
bReset.Position(3:4)=[40 15];
bReset.Position(1:2)=[bAbort.Position(1)-bReset.Position(3) ...
    bAbort.Position(2)];
bReset.Callback=@bResetCB;

jbReset= findjobj(bReset);
set(jbReset,'Enabled',true);
set(jbReset,'ToolTipText',ttStr);
%% TIMERS
%%%%% Adwin progress timer %%%
% After the sequence is run, this timer keeps tracks of the Adwin's
% progress. It doesn't have direct access to the Adwin so it assumes the
% timing based on the results of the sequence compliation.

% The adwin progress timer object
timeAdwin=timer('Name',adwinTimeName,'ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateAdwinBar,'StartFcn',@startAdwinTimer,'Period',.05,...
    'StopFcn',@stopAdwinTimer);
data.adwinTimer = timeAdwin;
% Function to run when the adwin starts the sequence.
    function startAdwinTimer(~,~)
        
        % Notify the user
        disp(['Sequence timer started. ' num2str(seqdata.sequencetime,'%.2f') ...
            ' seconds.']);
        
        % Disable reset and enable abort
        set(jbAbort,'Enabled',true);
        set(jbReset,'Enabled',false);

        % Give the progress timer a new start time as userdata
        timeAdwin.UserData=now;        
        % Note that the function now is days since date (January 0, 0000)        
    end

    function stopAdwinTimer(~,~)
        disp('Sequence timer ended.');      % Message the user
        pAdWinBar.XData = [0 1 1 0];     % Fill out the bar
        drawnow;                         % Update graphics
        set(jbAbort,'Enabled',false);
        set(jbReset,'Enabled',true);
        
        set(tStatus,'String','Cycle complete.','fontweight','bold',...
            'foregroundcolor','k');drawnow;
        if bgWait.UserData
           start(timeWait);              % Start wait timer if needed
        else
            cycleComplete;
        end
    end

% Timer callback functions updates the graphics
    function updateAdwinBar(~,~)
        % Calculate the time transpired so far
        tstart=timeAdwin.UserData;  % Sequence start time
        dT0=seqdata.sequencetime;   % Duration of sequence       
        dT=(now-tstart)*24*60*60;   % Current duration in sec.

        % Update graphical progress bar for wait time      
        pAdWinBar.XData = [0 dT/dT0 dT/dT0 0];    
        tAdWinTime1.String=[num2str(dT,'%.2f') ' s'];
        tAdWinTime2.String=[num2str(dT0,'%.2f') ' s'];
        drawnow;
        
        % Stop the timer if enough time has elapsed
        if dT>dT0
            tAdWinTime1.String=[num2str(dT0,'%.2f') ' s'];
            stop(timeAdwin);                 % Stop the adwin timer            
        end
    end

%%%%% Intecycle wait timer %%%
% After a seqeunce runs, we typically insert a mandatory wait time before
% the sequence may run again.  This is because certain parts of the machine
% (CATs) will get hot. This time allows the water cooling to cool down the
% system to sufficiently safe levels.

% The wait timer object
timeWait=timer('Name',waitTimeName,'ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateWaitBar,'startdelay',0,'period',.05,...
    'StartFcn',@startWait,'StopFcn',@stopWait);

% Function to run when the wait timer begins
    function startWait(~,~)
        set(tStatus,'String','waiting ...','fontweight','bold',...
            'foregroundcolor','k');drawnow;
        
        % Notify the user
        disp(['Starting the wait timer. ' ...
            num2str(tblWait.Data,'%.2f') ' seconds wait time.']);     
        
        % Calculate the time to wait.
        switch bgWait.UserData
            case 1   
                dT0=tblWait.Data;                    
            case 2
                dT0=tblWait.Data-seqdata.sequencetime;
        end
        
        % Give the wait timer a new start as userdata
        timeWait.UserData=[now dT0];         
        % Note that the function now is days since date (January 0, 0000)
    end

% Function to run when the wait timer is complete.
    function stopWait(~,~)
        set(tStatus,'String','Inter cycle wait complete.','fontweight','bold',...
            'foregroundcolor','k');drawnow;
        
        disp('Inter cycle wait complete.'); % Notify the user
        pWaitBar.XData = [0 1 1 0];         % Fill out the bar
        drawnow;                            % Update graphics        
        cycleComplete;
    end

% Timer callback fucntion updates the wait bar graphics
    function updateWaitBar(~,~)
        tstart=timeWait.UserData(1);    % When the wait started
        dT0=timeWait.UserData(2);             % Time to wait        
        dT=(now-tstart)*24*60*60;       % Current wait duration
        
        % Update graphical progress bar for wait time
        pWaitBar.XData = [0 dT/dT0 dT/dT0 0];    
        tWaitTime1.String=[num2str(dT,'%.2f') ' s'];
        tWaitTime2.String=[num2str(dT0,'%.2f') ' s'];
        drawnow;
        
        % Stop the timer.
        if dT>dT0
            tWaitTime1.String=tWaitTime2.String;
            stop(timeWait);  
        end
    end


%% AdWin Callbacks
    function cycleComplete
        set(tStatus,'String','Cycle completed.','fontweight','bold',...
            'foregroundcolor','k');drawnow;     
        if cRpt.Value
            disp('Repeating the sequence');
            runSequence;
        else
            if seqdata.doscan
                % Increment the scan and run the sequencer again
                cycleTbl.Data = cycleTbl.Data+1;
                disp('Incrementing the cycle number.');
                runSequence;
            else
                bRunIter.Enable     = 'on';
                bStartScan.Enable   = 'on';
                bContinue.Enable    = 'on';                
                bStop.Enable        = 'off';
                rScan.Enable        = 'on';
                rSingle.Enable      = 'on';
                bBrowse.Enable      = 'on';
                eSeq.Enable         = 'on';
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
                
        % Am I allowed to run the sequene?
        if ~safeToRun
           return 
        end    
        
        start_new_sequence;   
        
        switch run_mode
            % Run a single iteration
            case 0 
                seqdata.doscan = 0;
                if isequal(bgRun.SelectedObject.String,'single')
                    cycleTbl.Data   =  1;
                    rScan.Enable    = 'off';
                else
                    bStop.Enable    = 'off';
                    rSingle.Enable  = 'off';
                end      
            case 1
            % Start the scan
                seqdata.doscan      = 1;
                cycleTbl.Data       = 1;
                bStop.Enable        = 'on';
                rSingle.Enable      = 'off';
            case 2
            % Continue the scan
                seqdata.doscan      = 1;
                bStop.Enable        = 'on';
                bStop.Enable        = 'on';
                rSingle.Enable      = 'off';
        end  
        bBrowse.Enable              = 'off';
        eSeq.Enable                 = 'off';        
        bRunIter.Enable             = 'off';
        bContinue.Enable            = 'off';
        bStartScan.Enable           = 'off';
        runSequence;        
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

    function runSequence        
        
        % Reinitialize the sequence
        set(tStatus,'String','Initializing new sequence ...');drawnow;
        start_new_sequence;
        initialize_channels;
        set(tStatus,'String','Sequence initialized.');drawnow;
        seqdata.scancycle = cycleTbl.Data;
        seqdata.ScanVar = [];
        
        % Grab the sequence function
        fName=eSeq.String;
        fh = str2func(erase(fName,'@'));  

        % Display new run call
        disp(' ');
        disp(repmat('-',1,60));
        disp(repmat('-',1,60));
        disp([' Sequence Call - ' datestr(now,14)]);  
        disp([' ' fName]);
        disp(repmat('-',1,60));
        disp(repmat('-',1,60));                
        
        % Compile the code
        disp([' Compiling seqdata from  ' fName]);     
        tC1=now;                         % compile start time        
             
        set(tStatus,'String','compiling sequence ...','fontweight','bold',...
            'foregroundcolor','r');drawnow;
        
        try
            fh(0);           
        catch ME     
            disp(' ');
            warning('Exception caught on compling sequence!');            
            disp(' ');
            for kk=length(ME.stack):-1:1
               disp(['  ' ME.stack(kk).name ' (' num2str(ME.stack(kk).line) ')']);
            end
            disp(' '); 
            resetAfterError;
            return            
        end

        set(tStatus,'String','Sequence compiled.');drawnow;
        
        updateScanVarText;      
        tC2=now;

        % Generate hardware commands
        disp(repmat('-',1,60));
        disp(' Converting seqdata into Adwin and hardware calls ...');      
        disp(repmat('-',1,60));
        set(tStatus,'String','Generating hardware commands ...','fontweight','bold',...
            'foregroundcolor','r');drawnow;
        if ~doDebug
            try
                calc_sequence;                  % convert seqdata for AdWin  
            catch ME
                warning('Unable to generate hardware commands');
                warning(ME.message);
                disp(' ');
                for kk=length(ME.stack):-1:1
                   disp(['  ' ME.stack(kk).name ' (' num2str(ME.stack(kk).line) ')']);
                end
                disp(' ');  
                resetAfterError;
                return                
            end
        else
            disp('DEBUG MODE, NOT MAKING HW COMMANDS');        
        end
        set(tStatus,'String','Hardware commands generated.');drawnow;

        tC3=now;
        hwTime=(tC3-tC2)*24*60*60;

%         disp([' Hardware command generation took ' num2str(round(hwTime,2)) ' s.']);

        % Load adwin
        disp(repmat('-',1,60));
        disp(' Loading adwin ...');           
        disp(repmat('-',1,60));
        set(tStatus,'String','Loading the adwin ...');drawnow;

        if ~doDebug
            try
                load_sequence;              % load the sequence onto adwin
            catch ME
                warning('Unable to load sequence onto Adwin');
                warning(ME.message);
                disp(' ');
                for kk=length(ME.stack):-1:1
                   disp(['  ' ME.stack(kk).name ' (' num2str(ME.stack(kk).line) ')']);
                end
                disp(' ');              
                resetAfterError;
                return
            end  
        end
        set(tStatus,'String','Adwin loaded.');drawnow;

        tC4=now;                         % compile end time
        loadTime=(tC4-tC3)*(24*60*60);   % Build time in seconds   
%         disp([' Adwin load time ' num2str(round(loadTime,2))]);
        disp(repmat('-',1,60));

        if ~doDebug
            makeControlFile;
        end

        
        % Display compiling results
        disp(repmat('-',1,60));
        disp([fName ' READY. Duration is '  ...
            num2str(round(seqdata.sequencetime,1)) 's']);
        disp(' ');
        disp('STARTING ADWIN');
        disp(' ');
        
        set(tStatus,'String','Starting adwin ...');drawnow;

        % Run the sequence
        if ~doDebug
            try
                Start_Process(adwinprocessnum);
            catch ME
                warning('Unable to start the Adwin');
                warning(ME.message);     
                disp(' ');
                for kk=length(ME.stack):-1:1
                   disp(['  ' ME.stack(kk).name ' (' num2str(ME.stack(kk).line) ')']);
                end
                disp(' '); 
                resetAfterError;
                return
            end
        else
            disp('DEBUG MODE, NOT STARTING ADWIN');
        end
        
        set(tStatus,'String','adwin is running ...','fontweight','bold',...
            'foregroundcolor','r');drawnow;
        % Update progress bars
        start(timeAdwin);   
    end

    function resetAfterError
        warning(['Resetting the GUI after an error on sequence ' ...
            'run call. Unknown if the Adwin is in a stable state']);

        switch bgRun.SelectedObject.String

            % Renable buttons on single
            case 'single'
                bRunIter.Enable='on';
                rScan.Enable='on';
                rSingle.Enable='on';

                bPlot.Enable='on';
%                 bOver.Enable='on';
                            bCompile.Enable='on';

                bBrowse.Enable='on';
                eSeq.Enable='on';        

            % Renable buttons on single
            case 'scan'                
                bRunIter.Enable='on';
                rScan.Enable='on';
                rSingle.Enable='on';
                bContinue.Enable='on';

                bStop.Enable='off';
                bPlot.Enable='on';
%                 bOver.Enable='on';
                            bCompile.Enable='on';

                bBrowse.Enable='on';
                eSeq.Enable='on';
        end  
        
    end
    
    function out=safeToRun
        out=0;        
        % Check if the function provided is valid.
        fh = str2func(erase(eSeq.String,'@'));           
        nfo = functions(fh);       
        if isempty(nfo.file)
           warning(['Could not locate the sequence function. ' ...
                ' Your input is either misformatted or the ' ...
                'sequence function does not exist in the MATLAB ' ...
                'path. ' newline ' Proper formatting : @YOURFUNCTION']);
            return;
        end  
        % Is the sequence already running?        
        if isequal(timeAdwin.Running ,'on')
           warning('The sequence is already running you dummy!');
           return;
        end        
        % Is the intercycle wait timer running?
        if isequal(timeWait.Running,'on')
           warning(['You cannot run another sequence while the wait ' ...
               'timer is engaged. Disable to wait timer to proceed.']);
           return;
        end        
        out=1;
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
    
guidata(hF,data);

end


