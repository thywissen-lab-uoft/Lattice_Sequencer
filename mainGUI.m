function mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.  However, edits to the actual sequence need to be done in the code.
% Please refer to the relevant sequence files to edit those.
%
% Author      : CJ Fujiwara
% Last Edited : 2020/08
%
% In order to make this code work with the existing code in the lab
% designed by D. McKay (an early graduate student), many aspects of this
% code have been "Frakenstein'ed" together. It is the author's desire that
% this code be optimized and simplified.

%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;
% global adwin_booted;
global adwinprocessnum;
% global adwin_processor_speed;
% global adwin_connected;
% global adwin_process_path;

waitDefault=30;
compath='Y:\_communication';

defaultSequence='@test_sequence';

figName='Lattice Sequencer';

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
cc='w';
w=350;h=350;

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,'NumberTitle','off',...
    'MenuBar','figure','resize','off','CloseRequestFcn',@closeFig);
clf
hF.Position(3:4)=[w h];
set(hF,'WindowStyle','docked');

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
%             delete(hFGUI);
       end
       
        function doClose(~,~)
            close(f2);
            disp('Closing the sequencer GUI. Goodybe. I love you');
            stop(timeAdwin);
            stop(timeWait);
            pause(0.5);
            delete(fig);
%             delete(hFGUI);
        end       
    end

% Main uipanel
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','etchedin');
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];
hpMain.OuterPosition=[0 hF.Position(4)-h w h];

% Title String
tTit=uicontrol(hpMain,'style','text','string','Lattice Sequencer',...
    'FontSize',18,'fontweight','bold','units','pixels','backgroundcolor',cc);
tTit.Position(3:4)=tTit.Extent(3:4);
tTit.Position(1:2)=[5 hpMain.Position(4)-tTit.Position(4)];

%% Settings Graphical Objects

% Sequence File label
tSeq=uicontrol(hpMain,'style','text','String','Sequence File:',...
    'units','pixels','fontsize',10,'backgroundcolor',cc);
tSeq.Position(3:4)=tSeq.Extent(3:4);
tSeq.Position(1:2)=[5 tTit.Position(2)-tSeq.Position(4)];

% Sequence File edit box
eSeq=uicontrol(hpMain,'style','edit','string',defaultSequence,...
    'horizontalalignment','left','fontsize',10,'backgroundcolor',cc);
eSeq.Position(3)=210;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 tSeq.Position(2)-eSeq.Position(4)];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI Functions' filesep 'browse.jpg']),[20 20]);
bBrowse=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc,'Callback',@browseCB);
bBrowse.Position(3:4)=size(cdata,[1 2]);
bBrowse.Position(1:2)=eSeq.Position(1:2)+[eSeq.Position(3)+2 0];

% Button to plot the sequence
bPlot=uicontrol(hpMain,'style','pushbutton','String','plot',...
    'backgroundcolor',cc,'FontSize',10,'units','pixels',...
    'fontweight','normal','callback',@bPlotCB);
bPlot.Position(3:4)=[30 20];
bPlot.Position(1:2)=[bBrowse.Position(1)+bBrowse.Position(3)+5 ...
    bBrowse.Position(2)];

    function bPlotCB(~,~)
        fh = str2func(erase(eSeq.String,'@'));        
%         plotgui(fh);
        plotgui2;
    end

% % Button to open the manual override GUI
% bOver=uicontrol(hpMain,'style','pushbutton','String','override',...
%     'backgroundcolor',cc,'FontSize',10,'units','pixels',...
%     'fontweight','normal','enable','off');
% bOver.Position(3:4)=[60 20];
% bOver.Position(1:2)=[bPlot.Position(1)+bPlot.Position(3)+5 ...
%     bPlot.Position(2)];
% bOver.Callback=@bOverCB;
% 
%     function bOverCB(~,~)
% %        hFGUI.Visible='on'; 
%     end

% Button to recompile seqdata
bCompile=uicontrol(hpMain,'style','pushbutton','String','compile',...
    'backgroundcolor',cc,'FontSize',10,'units','pixels',...
    'fontweight','normal','enable','on');
bCompile.Position(3:4)=[60 20];
bCompile.Position(1:2)=[bPlot.Position(1)+bPlot.Position(3)+5 ...
    bPlot.Position(2)];
bCompile.Callback=@bCompileCB;

    function bCompileCB(~,~)
        start_new_sequence;             % Initialize sequence
        seqdata.scancycle=1;            % 
        seqdata.randcyclelist=0;    
        seqdata.doscan=0; 
        initialize_channels;            % Initialize channels

        fName=eSeq.String;
        fh = str2func(erase(fName,'@'));     
        fh(0);                          % Run the sequence / update seqdata  
        calc_sequence;                  % convert seqdata for AdWin  
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

%% Wait Timer Graphical interface

% Button group for selecting wait mode. The user data holds the selected
% button
bgWait = uibuttongroup('Parent',hpMain,'units','pixels','Title','wait mode',...
    'backgroundcolor',cc,'UserData',1,'SelectionChangedFcn',@waitCB);
bgWait.Position(3:4)=[w 90];
bgWait.Position(1:2)=[1 eSeq.Position(2)-bgWait.Position(4)-5];

% Create three radio buttons in the button group. The user data holds the
% selected mode (0,1,2) --> (no wait, intercyle, target time)
uicontrol(bgWait,'Style','radiobutton', 'String','no wait',...
    'Position',[5 50 100 20],'Backgroundcolor',cc,'UserData',0,'value',0);  
uicontrol(bgWait,'Style','radiobutton','String','intercycle wait',...
    'Position',[75 50 100 20],'Backgroundcolor',cc,'UserData',1,'value',1);
uicontrol(bgWait,'Style','radiobutton','String','target time',...
    'Position',[175 50 100 20],'Backgroundcolor',cc,'UserData',2,'value',0);              


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
                bgWait.UserData=0;               
                tblWait.Enable='off';
                tWaitTime1.String='n/a';
                tWaitTime2.String='n/a';
                stop(timeWait);
            case 1
                disp(['Wait timer engaged. Inter-cycle wait time mode. ' ...
                    ' This will be updated at end of next cycle.']);
                bgWait.UserData=1;
                tblWait.Enable='on';           
                tWaitTime1.String='~ s';
                tWaitTime2.String='~ s';
            case 2
                disp(['Wait timer engaged. Total sequence wait time mode. ' ...
                    ' This will be updated at end of next cycle.']);
                bgWait.UserData=2;
                tblWait.Enable='on';
                tWaitTime1.String='~ s';
                tWaitTime2.String='~ s';
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
bgRun.Position(3:4)=[w 130];
bgRun.Position(1:2)=[1 50];
        
    function runModeCB(~,evnt)
        switch evnt.NewValue.String
            case 'single'
                disp('Changing run mode to single iteration');
                cScanFinite.Enable='off';
                tblMaxScan.Enable='off';
                cRpt.Enable='on';
                tCycle.Enable='off';
                bRun.String='Run Sequence';
                bStop.String='Stop Sequence';
                bStop.Visible='off';
                tCycleLbl.Visible='off';
            case 'scan'
                disp('Changing run mode to scan mode.');
                cScanFinite.Enable='on';
                tblMaxScan.Enable='on';
                cRpt.Enable='off';
                tCycle.Enable='on';
                bRun.String='Scan Sequence';
                bStop.String='Stop Scan';
                bStop.Visible='on';
                tCycleLbl.Visible='on';
        end
        
    end

% Radio button for single mode
rSingle=uicontrol(bgRun,'Style','radiobutton', 'String','single',...
    'Position',[5 85 65 30],'Backgroundcolor',cc,'UserData',0,...
    'fontsize',12);  

% Checkbox for repeat cycle
cRpt=uicontrol(bgRun,'style','checkbox','string','repeat?','fontsize',8,...
    'backgroundcolor',cc,'units','pixels','Callback',@cRptCB);
cRpt.Position(3:4)=[60 cRpt.Extent(4)];
cRpt.Position(1:2)=[80 rSingle.Position(2)+4];
cRpt.Tooltip='Enable or disable automatic repitition of the sequence.';

% Callback for changing the repeat. This simply displays and update
    function cRptCB(src,~)
        if src.Value
            disp(['Enabling sequence repeat. Reminder : The sequence ' ...
                'recompiles every iteration.']);
        else
            disp('Disabling sequence repeat.');
        end        
    end

% Radio button for scan mode
rScan=uicontrol(bgRun,'Style','radiobutton','String','scan',...
    'Position',[5 60 100 20],'Backgroundcolor',cc,'UserData',1,...
    'FontSize',12);

% Checkbox for running scan finite number of times
cScanFinite=uicontrol(bgRun,'style','checkbox','string','stop scan afer',...
    'backgroundcolor',cc,'Fontsize',8,'units','pixels','enable','off');
cScanFinite.Position(3:4)=[92 cScanFinite.Extent(4)];
cScanFinite.Position(1:2)=[80 rScan.Position(2)];

% Table that stores the iteration to run
tblMaxScan=uitable(bgRun,'RowName','','ColumnName','','Data',100,...
    'ColumnWidth',{30},'ColumnEditable',true,'ColumnFormat',{'numeric'},...
    'fontsize',6,'enable','off');
tblMaxScan.Position(3:4)=tblMaxScan.Extent(3:4);
tblMaxScan.Position(1:2)=[cScanFinite.Position(3)+cScanFinite.Position(1) ...
    cScanFinite.Position(2)-2];

% Extra text label for the cycles
tCycle=uicontrol(bgRun,'style','text','String','cycles','fontsize',8,...
    'backgroundcolor',cc,'units','pixels','enable','off');
tCycle.Position(3:4)=tCycle.Extent(3:4);
tCycle.Position(1:2)=[tblMaxScan.Position(1)+tblMaxScan.Position(3)+1 tblMaxScan.Position(2)];


%%%%%%%%%%%%%%%%%%%%% ADWIN PROGRESS BAR  %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create axis object for the bar
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',bgRun,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=[10 10 bgRun.Position(3)-20 20];

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
tAdWinLabel=text(.5,1.05,'adwin progress','fontsize',10,...
    'horizontalalignment','center','verticalalignment','bottom','fontweight','bold');

%% Interrupt buttons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ABORT  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
    'outputs to their reset value.  DANGEROUS'];
bAbort=uicontrol(hpMain,'style','pushbutton','String','abort',...
    'backgroundcolor','r','FontSize',10,'units','pixels',...
    'fontweight','bold','Tooltip',ttStr,'Callback',@bAbortCB);
bAbort.Position(3:4)=[60 25];
bAbort.Position(1:2)=[hpMain.Position(3)-bAbort.Position(3)-5 ...
    hpMain.Position(4)-bAbort.Position(4)-5];

jbAbort= findjobj(bAbort);
set(jbAbort,'Enabled',false);
set(jbAbort,'ToolTipText',ttStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESET  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Reinitialize channels and reset Adwin outputs ' ...
    'to default values.'];
bReset=uicontrol(hpMain,'style','pushbutton','String','reset',...
    'backgroundcolor',[255,165,0]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','Tooltip',ttStr);
bReset.Position(3:4)=[60 25];
bReset.Position(1:2)=[bAbort.Position(1)-bReset.Position(3) ...
    bAbort.Position(2)];
bReset.Callback=@bResetCB;

jbReset= findjobj(bReset);
set(jbReset,'Enabled',true);
set(jbReset,'ToolTipText',ttStr);

%% Start and Stop Buttons
% Button to run the cycle
bRun=uicontrol(hpMain,'style','pushbutton','String','Run Sequence',...
    'backgroundcolor',[152 251 152]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold');
bRun.Position(3:4)=[135 40];
bRun.Position(1:2)=[5 5];
bRun.Callback=@bRunCB;
bRun.Tooltip='Compile and run the currently selected sequence.';


% Button to stop
bStop=uicontrol(hpMain,'style','pushbutton','String','Stop',...
    'backgroundcolor',[255	218	107]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off','visible','off');
bStop.Position(3:4)=[135 40];
bStop.Position(1:2)=[bRun.Position(1)+bRun.Position(3)+5 5];
bStop.Callback=@bStopCB;
bStop.Tooltip='Compile and run the currently selected sequence.';


defaultSequence=['1'];
tCycleLbl=uicontrol(hpMain,'style','text','string',defaultSequence,...
    'backgroundcolor','w','fontsize',16,'units','pixels',...
    'fontweight','bold','visible','off','horizontalalignment','center');
tCycleLbl.Position(3:4)=[60 35];
tCycleLbl.Position(1:2)=[bStop.Position(1)+bStop.Position(3) 3];


%% TIMERS
%%%%% Adwin progress timer %%%
% After the sequence is run, this timer keeps tracks of the Adwin's
% progress. It doesn't have direct access to the Adwin so it assumes the
% timing based on the results of the sequence compliation.

% The adwin progress timer object
timeAdwin=timer('Name',adwinTimeName,'ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateAdwinBar,'StartFcn',@startAdwinTimer,'Period',.05,...
    'StopFcn',@stopAdwinTimer);

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
% This section of the code defines the callbacks for running the sequencer.
%  It is separated by a different section in order to visually separate
%  front end GUI stuff from the actual sequence code.



% This function is called when the sequence has finished running an
% iteration.  It is called either at the end of an adwin sequence or at the
% end of the wait timer.  It's purpose is to decide what to do after the
% iteration of the sequence is complete.
% Options - Stop running, run on repeat, continue scanning, stop scanning
function cycleComplete
    
switch bgRun.SelectedObject.String
    
    % End condition if the sequener is in single mode
case 'single'
    if cRpt.Value
        disp('Repeating the sequence');
        runSequence;
    else
        bRun.Enable='on';
        rScan.Enable='on';
        rSingle.Enable='on';
        
        bPlot.Enable='on';
%         bOver.Enable='on';
        bCompile.Enable='on';

        bBrowse.Enable='on';
        eSeq.Enable='on';
    end

    % What to do if the sequener is in scan mode.
case 'scan'                
    if seqdata.doscan
        if isequal(cScanFinite.Enable,'on') && tblMaxScan.Data<=seqdata.scancycle ...
                && cScanFinite.Value
            % The scan is complete
            disp(['Scan complete at ' num2str(seqdata.scancycle) ' cycles']);
            bRun.Enable='on';
            rScan.Enable='on';
            rSingle.Enable='on';       
            bStop.Enable='off';

            bPlot.Enable='on';
%             bOver.Enable='on';
            bCompile.Enable='on';
            bBrowse.Enable='on';
            eSeq.Enable='on';
        else
            % Increment the scan and run the sequencer again
            disp(['Incrementing the scan ' num2str(seqdata.scancycle) ...
                ' --> ' num2str(seqdata.scancycle+1)]);
            seqdata.scancycle=seqdata.scancycle+1;   
            tCycleLbl.String=[num2str(seqdata.scancycle)];           
            runSequence;
        end                  
    else
        if cScanFinite.Value
            disp(['Scan stopped at ' num2str(seqdata.scancycle) ...
                ' cycles of ' num2str(tblMaxScan.Data)]);
        else
            disp(['Scan stopped at ' num2str(seqdata.scancycle) ' cycles']);
        end
        
        bRun.Enable='on';
        rScan.Enable='on';
        rSingle.Enable='on';
        bStop.Enable='off';
        bPlot.Enable='on';
%         bOver.Enable='on';
        bCompile.Enable='on';

        bBrowse.Enable='on';
        eSeq.Enable='on';
        
    end
end  

end



% Run button callback.
    function bRunCB(~,~)    
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
        seqdata.scancycle=1;      

        % Check the run mode
        switch bgRun.SelectedObject.String
            case 'single'
                seqdata.randcyclelist=0;    
                seqdata.doscan=0;    
                rScan.Enable='off';                
            case 'scan'
                
                tCycleLbl.String='1';           
                seqdata.randcyclelist=uint16(randperm(1000));    
                seqdata.doscan=1; 
                bStop.Enable='on';
                rSingle.Enable='off';
        end  
        
        
%         bPlot.Enable='off';
%         bOver.Enable='off';
%         bCompile.Enable='off';

        bBrowse.Enable='off';
        eSeq.Enable='off';
        
        bRun.Enable='off';
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
        start_new_sequence;
        initialize_channels;
        
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
        tC2=now;
        compileTime=(tC2-tC1)*24*60*60;
%         disp([' Compiling sequence took ' num2str(round(compileTime,2)) ' s.']);
        
        % Generate hardware commands
        disp(repmat('-',1,60));
        disp(' Converting seqdata into Adwin and hardware calls ...');      
        disp(repmat('-',1,60));
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
        tC3=now;
        hwTime=(tC3-tC2)*24*60*60;

%         disp([' Hardware command generation took ' num2str(round(hwTime,2)) ' s.']);

        % Load adwin
        disp(repmat('-',1,60));
        disp(' Loading adwin ...');           
        disp(repmat('-',1,60));
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
        tC4=now;                         % compile end time
        loadTime=(tC4-tC3)*(24*60*60);   % Build time in seconds   
%         disp([' Adwin load time ' num2str(round(loadTime,2))]);
        disp(repmat('-',1,60));

        makeControlFile;

        
        % Display compiling results
        disp(repmat('-',1,60));
        disp([fName ' READY. Duration is '  ...
            num2str(round(seqdata.sequencetime,1)) 's']);
        disp(' ');
        disp('STARTING ADWIN');
        disp(' ');
        

        % Run the sequence
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
            return;
        end

        % Update progress bars
        start(timeAdwin);
               
        % Seqdata history
                

    end

    function resetAfterError
        warning(['Resetting the GUI after an error on sequence ' ...
            'run call. Unknown if the Adwin is in a stable state']);

        switch bgRun.SelectedObject.String

            % Renable buttons on single
            case 'single'
                bRun.Enable='on';
                rScan.Enable='on';
                rSingle.Enable='on';

                bPlot.Enable='on';
%                 bOver.Enable='on';
                            bCompile.Enable='on';

                bBrowse.Enable='on';
                eSeq.Enable='on';        

            % Renable buttons on single
            case 'scan'                
                bRun.Enable='on';
                rScan.Enable='on';
                rSingle.Enable='on';
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
    

%% Control Files

    % This function creates files which indicate the configuration of the
    % most recent cycle run.
    function makeControlFile
        % Dispaly output parameters to control prompt        
%         disp(' ');
%         disp('--Lattice Sequencer Output Parameters--');        
%         for n = 1:length(seqdata.outputparams)
%             %the first element is a string and the second element is a number
%             fprintf(1,'%s: %g \n',seqdata.outputparams{n}{1},seqdata.outputparams{n}{2});
%         end        
%         disp('----------------------------------------');     
        
        tExecute=now;
        seqdata.outputfilepath=compath;
        filenametxt = fullfile(seqdata.outputfilepath, 'control.txt');
        filenamemat=fullfile(seqdata.outputfilepath, 'control.mat');  
        filenamemat2=fullfile(seqdata.outputfilepath, 'control2.mat');  
        

        disp(['Saving sequence parameters to ' seqdata.outputfilepath filesep 'control']);
        [path,~,~] = fileparts(filenametxt);
        
        % If the location of the control file doesnt exist, make it
        if ~exist(path,'dir')
            try
                mkdir(path);
            catch 
                warning('Unable to create output file location');
            end
        end        
        [fid,~]=fopen(filenametxt,'wt+'); % open file, overrite permission, discard old
        %output the header (date/time,function handle,cycle)
        fprintf(fid,'Lattice Sequencer Output Parameters \n');
        fprintf(fid,'------------------------------------\n');
        fprintf(fid,'Execution Date: %s \n',datestr(tExecute));
        fprintf(fid,'Function Handle: %s \n',erase(eSeq.String,'@'));
        fprintf(fid,'Cycle: %g \n', seqdata.cycle);
        fprintf(fid,'------------------------------------\n');    
        
        
        %output the parameters
        if ~isempty(seqdata.outputparams)
            for n = 1:length(seqdata.outputparams)
                %the first element is a string and the second element is a number
                fprintf(fid,'%s: %d \n',seqdata.outputparams{n}{1},seqdata.outputparams{n}{2});
            end
        end
        fclose(fid);     % close the file   
        %% Making a mat file with the parameters
        outparams=struct;       
        for kk=1:length(seqdata.outputparams)
            a=seqdata.outputparams{kk};
            outparams.(a{1})=a{2};
        end        
        assignin('base','seqparams',outparams)

        params=seqdata.params;        
        % output both outparams and params
        save(filenamemat,'outparams','params');        
        %% Save new output mat
        try
        vals=seqdata.output_vars_vals;
        units=seqdata.output_vars_units;        
        flags=seqdata.flags;
        
        vals.ExecutionDate=datestr(tExecute);        
        units.ExecutionDate='str';
        
        save(filenamemat2,'vals','units','flags');        
        end
    end


%% Override GUI
% This GUI is meant to override the digital and analog channels of the
% experiment.  Its purpose is to provide an easy platform to diagnose and
% calibrate the controls to the experiment. It is not designed to perform
% custom test sequences for more complicated diagnoses, such as ramps or
% measuring delays.

%{

disp('Initializing override GUI...');

% Grab the analog and digital channels
Achs=seqdata.analogchannels;
Dchs=seqdata.digchannels;

% Define the RGB color scheme for the rows in the table
cc=[255	255	255;
    221 235 247]/255;
bc=[47	117	181]/255;



% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name','Adwin Override','Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off','Visible','off');
hFGUI.Position(3:4)=[900 600];
hFGUI.Position(2)=50;
hFGUI.WindowScrollWheelFcn=@scroll;
hFGUI.CloseRequestFcn=@(src,~) set(src,'Visible','off');



% Callback function for mouse scroll over the figure.
    function scroll(~,b)
        scrll=-b.VerticalScrollCount;
        C=get(gcf,'CurrentPoint');        
        if C(2)<hpOver.Position(4)                  
            if C(1)<hpOver.Position(3)/2
                % mouse in in digital side
                newVal=hDsl.Value+scrll*abs(hDsl.Min)*.05;                
                newVal=max([newVal hDsl.Min]);
                newVal=min([newVal hDsl.Max]);
                hDsl.Value=newVal;     
                DsliderCB;
            else
                % mouse is in analog side
                newVal=hAsl.Value+scrll*abs(hAsl.Min)*.05;                
                newVal=max([newVal hAsl.Min]);
                newVal=min([newVal hAsl.Max]);
                hAsl.Value=newVal;     
                AsliderCB;
            end            
        end
    end

% Initialize uipanel that contains all channel information
hpOver=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','fontsize',12);
hpOver.Position=[0 0 hFGUI.Position(3) hFGUI.Position(4)];

% Define the respective size of the digital and analog panels
w1=350;
g=50;
w2=hpOver.Position(3)-w1-g;
h=25;


%%%%%%%%%%%%%%%%%%%%% DIGITAL CHANNEL GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrapper container uipanel for digital channels
hpD=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpD.Position=[0 0 w1 hpOver.Position(4)-60];
 

% Total container uipanel for digital channels
% (you scroll by moving the large panel inside the small one; it's clunky
% but MATLAB doesn't have a good scrollable interface for figure interace)
hpDS=uipanel('parent',hpD,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpDS.Position=[0 0 400 h*length(Dchs)];
hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4);


% Panel for labels
Dlbl=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',10,'bordertype','none');
Dlbl.Position(3:4)=[w1 h];
Dlbl.Position(1:2)=[0 hpD.Position(4)+2];

% Channel namel label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',10,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];

% Override label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[175 0];

% Value label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[245 0];


% Populate the digital channels
for nn=1:length(Dchs)
    % Grab the color
    c=[cc(mod(nn-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpDs(nn)=uipanel('parent',hpDS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpDs(nn).Position(3:4)=[w1 h+1];
    hpDs(nn).Position(1:2)=[0 hpDS.Position(4)-nn*h];    
    hpDs(nn).UserData.Channel=Dchs(nn);    
    
    % Channel label
    t=uicontrol('parent',hpDs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['d' num2str(Dchs(nn).channel) ' ' Dchs(nn).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpDs(nn).Position(4)-t.Position(4))-3];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'Callback',{@overCBD nn});
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpDs(nn).Position(4)-ckOver.Position(4));

    % Value check box
    ckValue=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'enable','off');
    ckValue.Position(3:4)=ckValue.Extent(3:4)+50;
    ckValue.Position(1)=250;
    ckValue.Position(2)=0.5*(hpDs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    ckValue.Value=real(Dchs(nn).resetvalue);
    hpDs(nn).UserData.ckValue=ckValue;    
end


% enable or disable a digital channel override
    function overCBD(a,~,ind)
        if a.Value
            hpDs(ind).UserData.ckValue.Enable='on';   
        else
            hpDs(ind).UserData.ckValue.Enable='off';            
        end     
    end

% Digital channel panel slider
hDsl = uicontrol('parent',hpD,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0);
hDsl.Callback=@DsliderCB;
hDsl.SliderStep=[0.05 .1];
hDsl.Min=-(hpDS.Position(4)-hpD.Position(4));
hDsl.OuterPosition(3:4)=[20 hpD.Position(4)];            
hDsl.Position(1:2)=[hpD.Position(3)-hDsl.Position(3) 0];     

% Callback for when the slider bar moves
    function DsliderCB(~,~)
        hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4)-hDsl.Value;   
    end



%%%%%%%%%%%%%%%%%%%%% ANALOG CHANNEL GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrapper container uipanel for analog channels
hpA=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpA.Position=[hpD.Position(3)+g 0 w2 hpD.Position(4)];

% Total container uipanel for analog channels
hpAS=uipanel('parent',hpA,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpAS.Position=[0 0 w2 h*length(Achs)];
hpAS.Position(2)=hpA.Position(4)-hpAS.Position(4);


% button to output analog channels
bAoutput=uicontrol('parent',hpOver,'style','pushbutton',...
    'backgroundcolor','w','fontsize',10,'units','pixels',...
    'foregroundcolor','k');
bAoutput.String='output analog channels';
bAoutput.Position(1)=hpA.Position(1)+5;
bAoutput.Position(3:4)=[150 25];
bAoutput.Position(2)=hpD.Position(4)+30;


% Panel for labels
Albl=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixel','fontsize',10,'bordertype','none');
Albl.Position(3:4)=[w2 h];
Albl.Position(1:2)=[hpA.Position(1) hpA.Position(4)+2];

% Channel label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',10,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];


% Override label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[175 0];

% Value label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[245 0];

% fucntion label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','func#');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[285 0];

% voltage label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','voltage');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[350 0];


% Populate the analog channels
for nn=1:length(Achs)
    c=[cc(mod(nn-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpAs(nn)=uipanel('parent',hpAS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpAs(nn).Position(3:4)=[w2 h+1];
    hpAs(nn).Position(1:2)=[0 hpAS.Position(4)-nn*h];    
    hpAs(nn).UserData.Channel=Achs(nn);
    
    % Channel label
    t=uicontrol('parent',hpAs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['a' num2str(Achs(nn).channel) ' ' Achs(nn).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpAs(nn).Position(4)-t.Position(4))-2];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpAs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c);
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpAs(nn).Position(4)-ckOver.Position(4));
    ckOver.Callback={@overCBA nn};

    % Value Number
    ckValue=uicontrol('parent',hpAs(nn),'style','edit','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor','w',...
        'enable','off','String', '');
    ckValue.String=num2str(real(Achs(nn).resetvalue(1)));
    ckValue.Position(4)=ckValue.Extent(4);
    ckValue.Position(3)=40;
    ckValue.Position(1)=240;
    ckValue.Position(2)=0.5*(hpAs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    hpAs(nn).UserData.ckValue=ckValue;
    
    % Function select pull-down menu
    pdFunc=uicontrol('parent',hpAs(nn),'style','popupmenu',...
        'units','pixels','fontsize',8,'fontname','monospaced',...
        'backgroundcolor','w','enable','off');
    pdFunc.String=strsplit(num2str(1:length(Achs(nn).voltagefunc)),' ');
    
    % case where we specify value not using the defaultfunc (value,func#)
    if length(Achs(nn).resetvalue)>1
        pdFunc.Value=Achs(nn).resetvalue(2);          
    else
        pdFunc.Value=Achs(nn).defaultvoltagefunc;
    end    
    foo=Achs(nn).voltagefunc{pdFunc.Value};    

    pdFunc.Position(3)=30;
    pdFunc.Position(4)=pdFunc.Extent(4);
    pdFunc.Position(1)=ckValue.Position(1)+ckValue.Position(3);
    pdFunc.Position(2)=0.5*(hpAs(nn).Position(4)-pdFunc.Position(4))+1;
    hpAs(nn).UserData.pdFunc=pdFunc;
    
    % voltage output string
    tVolt=uicontrol('parent',hpAs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor',c,...
        'enable','on','horizontalalignment','left');
    tVolt.String=[num2str(foo(real(Achs(nn).resetvalue(1)))) ' V'];
    tVolt.Position(1)=350;
    tVolt.Position(3:4)=[120 tVolt.Extent(4)];
    tVolt.Position(2)=2;
end


% enable or disable a analog channel override
    function overCBA(a,~,ind)
        if a.Value
            hpAs(ind).UserData.ckValue.Enable='on';   
            hpAs(ind).UserData.pdFunc.Enable='on';   

        else
            hpAs(ind).UserData.ckValue.Enable='off';            
            hpAs(ind).UserData.pdFunc.Enable='off';   
        end     
    end

% Analog channel panel slider
hAsl = uicontrol('parent',hpA,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0);
hAsl.Callback=@AsliderCB;
hAsl.SliderStep=[0.05 .1];
hAsl.Min=-(hpAS.Position(4)-hpA.Position(4));
hAsl.OuterPosition(3:4)=[20 hpA.Position(4)];            
hAsl.Position(1:2)=[hpA.Position(3)-hAsl.Position(3) 0];     

% Callback for when the slider bar moves
    function AsliderCB(~,~)
        hpAS.Position(2)=hpA.Position(4)-hpAS.Position(4)-hAsl.Value;   
    end

%}
end


