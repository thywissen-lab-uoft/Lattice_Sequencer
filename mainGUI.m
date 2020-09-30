function mainGUI
% This is the primary GUI for running the lattice experiment. You should
% be able to run the entirety of the experiment from the graphics interface
% here.  However, edits to the actual sequence need to be done in the code.
% Please refer to the relevant sequence files to edit those.
%
% Author      : CJ Fujiwara
% Last Edited : 2020/08
%
% This GUI is written using the figure interface rather than the uifigure
% coding environment.  This is done because CF is not very familiar with
% the uifigure interface, but has made many GUIs in the default MATLAB
% figure interface. I am electing to not use GUIDE, because GUIDE is a
% piece of shit coding interface in my opinion (why use a GUI to make a
% GUI?)
%
% I have attemtped to extensively comment this code so that students of the
% lab may edit and improve this GUI.  However, the comments assume a base
% level of understanding of the MATLAB coding interface, specifcally with
% the GUI elements and callbacks of uicontrol.
%
% The design of this GUI is inspired after the Cicero Word Generator, which
% was designed by Aviv Keshet at MIT around 2008. This stylistic choice was
% done because CF used Cicero in the past and found it to be very
% intuititive.  Moreover, many MIT/Ketterle "children" groups tend to use
% Cicero (IDK if this will be true in the future), and it is the author's
% hope that this will enable future group members to learn the software of
% this group more quickly. (It took me many months to become comfortable
% with it).
%
% In order to make this code work with the existing code in the lab
% designed by D. McKay (an early graduate student), many aspects of this
% code have been "Frakenstein'ed" together. It is the author's desire that
% this code be optimized and simplified.

%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;

global adwin_booted;
global adwinprocessnum;
global adwin_processor_speed;
global adwin_connected;
global adwin_process_path;

seqdata.outputfilepath='Y:\Experiments\Lattice\_communication\';
seqdata.outputfilepath='C:\Users\coraf\Desktop\LAB';

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
%% Initialize Graphics

%%%%%%%%%%%%%%% Initialize Graphics %%%%%%%%%%%%%%%%%
figName='Lattice Sequencer';

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
w=350;
h=350;

%%%%%%%%%%%%%%%% INITIALIZE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',figName,'color',cc,...
    'NumberTitle','off','MenuBar','none','resize','off');
clf
hF.Position(3:4)=[w h];
hF.CloseRequestFcn=@closeFig;

% Callback for a close request function. The close request function handles
% whether the adwin is running or other potential timer issues.
    function closeFig(fig,~)
       disp('Requesting to close the sequencer GUI.'); 
       
       if (~isempty(timerfind('Name',adwinTimeName)) && ...
               isequal(timeAdwin.Running,'on')) || ...
               (cRpt.Value && isequal(timeWait.Running,'on'))
           tt=['The sequence is still running or repitions are engaged '...
               'with the wait timer running. '...
               'Are you sure you want to close the GUI? ' ... 
               'If the sequence data has already been ' ...
               'sent to the Adwin, the experiment will still be ' ...
               'running.'];
           tit='Sequence is still running!';
           
           f2=figure;
           set(f2,'Name',tit,'color','w','NumberTitle','off',...
               'windowstyle','modal','units','pixels','resize','off');
           f2.Position(3:4)=[400 200];
           f2.Position(1:2)=fig.Position(1:2)+[-50 100];
           
           tt=uicontrol('style','text','String',tt,'parent',f2,...
               'fontsize',10,'units','normalized','horizontalalignment',...
               'center','backgroundcolor','w');
           tt.Position=[0.05 0.5 0.9 0.35];
           
           b1=uicontrol('style','pushbutton','string','yes','parent',f2,...
               'fontsize',10','units','normalized','backgroundcolor',...
               [253 106 2]/255);
           b1.Position=[.25 .15 .2 .2];
           b1.Callback=@doClose;
  
           b2=uicontrol('style','pushbutton','string','cancel','parent',f2,...
               'fontsize',10','units','normalized','backgroundcolor','w');
           b2.Position=[.55 .15 .2 .2];
           b2.Callback=@(~,~) close(f2);          

       else
            disp('Closing the sequencer GUI. Goodybe. I love you'); 
            try
                stop(timeAdwin);
                stop(timeWait);
                delete(timeAdwin);
                delete(timeWait);              
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
tTit=uicontrol(hpMain,'style','text','string','Lattice Sequencer',...
    'FontSize',18,'fontweight','bold','units','pixels',...
    'backgroundcolor',cc);
tTit.Position(3:4)=tTit.Extent(3:4);
tTit.Position(1:2)=[5 hpMain.Position(4)-tTit.Position(4)];

%% Settings Graphical Objects

% Sequence File label
tSeq=uicontrol(hpMain,'style','text','String','Sequence File:',...
    'units','pixels','fontsize',10,'backgroundcolor',cc);
tSeq.Position(3:4)=tSeq.Extent(3:4);
tSeq.Position(1:2)=[5 tTit.Position(2)-tSeq.Position(4)];

% Sequence File edit box
str='@Load_MagTrap_sequence';
eSeq=uicontrol(hpMain,'style','edit','string',str,...
    'horizontalalignment','left','fontsize',10,'backgroundcolor',cc);
eSeq.Position(3)=210;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 tSeq.Position(2)-eSeq.Position(4)];

% Button for file selection of the sequenece file
cdata=imresize(imread(['GUI Functions' filesep 'browse.jpg']),[20 20]);
bBrowse=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc);
bBrowse.Position(3:4)=size(cdata,[1 2]);
bBrowse.Position(1:2)=eSeq.Position(1:2)+[eSeq.Position(3)+2 0];
bBrowse.Callback=@browseCB;

% Button to plot the sequence
bPlot=uicontrol(hpMain,'style','pushbutton','String','plot',...
    'backgroundcolor',cc,'FontSize',10,'units','pixels',...
    'fontweight','normal');
bPlot.Position(3:4)=[30 20];
bPlot.Position(1:2)=[bBrowse.Position(1)+bBrowse.Position(3)+5 ...
    bBrowse.Position(2)];
bPlot.Callback=@bPlotCB;

    function bPlotCB(~,~)
        fh = str2func(erase(eSeq.String,'@'));        
        plotgui(fh);
    end

% Button to open the manual override GUI
bOver=uicontrol(hpMain,'style','pushbutton','String','override',...
    'backgroundcolor',cc,'FontSize',10,'units','pixels',...
    'fontweight','normal');
bOver.Position(3:4)=[60 20];
bOver.Position(1:2)=[bPlot.Position(1)+bPlot.Position(3)+5 ...
    bPlot.Position(2)];
bOver.Callback=@bOverCB;

    function bOverCB(~,~)
       overrideGUI2; 
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
    'backgroundcolor',cc,'UserData',0);
bgWait.Position(3:4)=[w 90];
bgWait.Position(1:2)=[1 eSeq.Position(2)-bgWait.Position(4)-5];
bgWait.SelectionChangedFcn=@waitCB;
              
% Create three radio buttons in the button group. The user data holds the
% selected mode (0,1,2) --> (no wait, intercyle, target time)
r1=uicontrol(bgWait,'Style','radiobutton', 'String','no wait',...
    'Position',[5 50 100 20],'Backgroundcolor',cc,'UserData',0);  
r2=uicontrol(bgWait,'Style','radiobutton','String','intercycle wait',...
    'Position',[75 50 100 20],'Backgroundcolor',cc,'UserData',1);
r3=uicontrol(bgWait,'Style','radiobutton','String','target time',...
    'Position',[175 50 100 20],'Backgroundcolor',cc,'UserData',2);              

% Table for storing value of wait time
tblWait=uitable(bgWait,'RowName','','ColumnName','',...
    'Data',10,'ColumnWidth',{30},'ColumnEditable',true,...
    'ColumnFormat',{'numeric'},'fontsize',8,'Enable','off');
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

% Wait bar text label
% tWaitLabel=text(.5,1.05,'Wait Timer','fontsize',10,...
%     'horizontalalignment','center','verticalalignment','bottom','fontweight','bold');

%% Run mode graphics and callbacks

% Run sequence mode
bgRun = uibuttongroup('Parent',hpMain,'units','pixels','Title','run mode',...
    'backgroundcolor',cc,'UserData',0);
bgRun.Position(3:4)=[w 130];
bgRun.Position(1:2)=[1 50];
bgRun.SelectionChangedFcn=@runModeCB;
        
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
            case 'scan'
                disp('Changing run mode to scan mode.');
                cScanFinite.Enable='on';
                tblMaxScan.Enable='on';
                cRpt.Enable='off';
                tCycle.Enable='on';
                bRun.String='Scan Sequence';
                bStop.String='Stop Scan';
                bStop.Visible='on';
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

%% Old run list code and iteration
% This is code that CF wanted to use for Cicero styel interafce. It might
% be brought back from the dead one day, but its arhcitecture requires
% restructuring of how we sepcify our scan parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN LIST %%%%%%%%%%%%%%%%%%%%%%
%{
% Button run a list
bScanStart=uicontrol(hpMain,'style','pushbutton','String','Start Scan',...
    'backgroundcolor',[199 234 70]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','on','callback',@bScanStartCB);
bScanStart.Position(3:4)=[80 40];
bScanStart.Position(1:2)=[5 bRun.Position(2)-bScanStart.Position(4)-5];

% Button run a list
bScanStop=uicontrol(hpMain,'style','pushbutton','String','Stop Scan',...
    'backgroundcolor',[255,165,0]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off','callback',@bScanStopCB);
bScanStop.Position(3:4)=[80 40];
bScanStop.Position(1:2)=[bScanStart.Position(1)+bScanStart.Position(3)+5 ...
    bRun.Position(2)-bScanStop.Position(4)-5];

% Checkbox to run the list randomly
cRand=uicontrol(hpMain,'style','checkbox','string','random?',...
    'backgroundcolor',cc,'Fontsize',8,'units','pixels','Value',1,...
    'callback',@cRandCB);
cRand.Position(4)=cRand.Extent(4);
cRand.Position(3)=80;
cRand.Position(1:2)=[bScanStop.Position(1)+bScanStop.Position(3)+5 bScanStop.Position(2)];

    function cRandCB(src,~)
       if src.Value
           disp('Scan will run parameter in random order.');
       else
           disp('Scan will run parameters in sequential order.');
       end
    end

% Checkbox to run the list randomly
cMaxIter=uicontrol(hpMain,'style','checkbox','string','fixed number?',...
    'backgroundcolor',cc,'Fontsize',8,'units','pixels','Value',0,...
    'callback',@cMaxIterCB);
cMaxIter.Position(4)=cMaxIter.Extent(4);
cMaxIter.Position(3)=90;
cMaxIter.Position(1:2)=[bScanStop.Position(1)+bScanStop.Position(3)+5 bScanStop.Position(2)+20];

    function cMaxIterCB(src,~)
        if src.Value
           disp('Enabling limiting of scan iterations to a value');
           tblMaxScan.Enable='on';
        else
            disp('Disabling limiting the scan iterations.  Will run forever');
            tblMaxScan.Enable='off';
        end
    end

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN LIST ITERATION %%%%%%%%%%%%%%%%%%%%%%
%{
% Button to run an iteration of a list
bIter=uicontrol(hpMain,'style','pushbutton','String','Run Iteration (1)',...
    'backgroundcolor',[199 234 70]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off');
bIter.Position(3:4)=[130 40];
bIter.Position(1:2)=[5 bList.Position(2)-bIter.Position(4)-5];

% Table that stores the iteration to run
tblIter=uitable(hpMain,'RowName','','ColumnName','','Data',1,...
    'ColumnWidth',{30},'ColumnEditable',true,'ColumnFormat',{'numeric'});
tblIter.Position(3:4)=tblIter.Extent(3:4);
tblIter.Position(4)=tblIter.Position(4);
tblIter.Position(1:2)=[10+bIter.Position(3) bIter.Position(2)+5];
tblIter.CellEditCallback=@chiter;

% Callback upon changing the iteration (natural number)
function chiter(tbl,data)
    if isnan(data.NewData) && isnumeric(data.NewData)
        disp([datestr(now,13) ' You inputted a non-numerical input' ...
            ' to the limits of the plot. Shameful']);
        tbl.Data(data.Indices(2))=data.PreviousData;
        return;
    end      
    tbl.Data=max([1 ceil(tbl.Data)]);
    bIter.String=['Run Iteration (' num2str(tblIter.Data) ')'];
end

% Button to decrease iteration value by 1
bIterDown=uicontrol(hpMain,'style','pushbutton','string','<',...
    'backgroundcolor',cc,'fontsize',8,'units','pixels','enable','on');
bIterDown.Position(3:4)=[15 tblIter.Position(4)];
bIterDown.Position(1:2)=[tblIter.Position(1)+tblIter.Position(3)+1 ...
    tblIter.Position(2)];
bIterDown.Callback=@cbDown;
    function cbDown(~,~)
        tblIter.Data=max([tblIter.Data-1 1]);
        bIter.String=['Run Iteration (' num2str(tblIter.Data) ')'];
        drawnow;
    end

% Button to increase iteration value by 1
bIterUp=uicontrol(hpMain,'style','pushbutton','string','>',...
    'backgroundcolor',cc,'fontsize',8,'units','pixels','enable','on');
bIterUp.Position(3:4)=[15 tblIter.Position(4)];
bIterUp.Position(1:2)=[bIterDown.Position(1)+bIterDown.Position(3)+1 ...
    bIterDown.Position(2)];
bIterUp.Callback=@cbUp;
    function cbUp(~,~)
        tblIter.Data=tblIter.Data+1;
        bIter.String=['Run Iteration (' num2str(tblIter.Data) ')'];
        drawnow;
    end


%}

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
bRun.Position(3:4)=[165 40];
bRun.Position(1:2)=[5 5];
bRun.Callback=@bRunCB;
bRun.Tooltip='Compile and run the currently selected sequence.';


% Button to stop
bStop=uicontrol(hpMain,'style','pushbutton','String','Stop',...
    'backgroundcolor',[255	218	107]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off','visible','off');
bStop.Position(3:4)=[165 40];
bStop.Position(1:2)=[bRun.Position(1)+bRun.Position(3)+5 5];
bStop.Callback=@bStopCB;
bStop.Tooltip='Compile and run the currently selected sequence.';


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
        disp(['Sequence started. ' num2str(seqdata.sequencetime,'%.2f') ...
            ' seconds run time.']);
        
        % Disable reset and enable abort
        set(jbAbort,'Enabled',true);
        set(jbReset,'Enabled',false);

        % Give the progress timer a new start time as userdata
        timeAdwin.UserData=now;        
        % Note that the function now is days since date (January 0, 0000)        
    end

    function stopAdwinTimer(~,~)
        disp('Sequence complete.');      % Message the user
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

%% other

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
    end

    % What to do if the sequener is in scan mode.
case 'scan'                
    if seqdata.doscan
        if isequal(cScanFinite.Enable,'on') && tblMaxScan.Data<=seqdata.scancycle
            % The scan is complete
            disp(['Scan complete at ' num2str(seqdata.scancycle) ' cycles']);
            bRun.Enable='on';
            rScan.Enable='on';
            rSingle.Enable='on';       
            bStop.Enable='off';
        else
            % Increment the scan and run the sequencer again
            disp(['Incrementing the scan ' num2str(seqdata.scancycle) ...
                ' --> ' num2str(seqdata.scancycle+1)]);
            seqdata.scancycle=seqdata.scancycle+1;   
            runSequence;
        end                  
    else
        if cScanFinite.Value
            disp(['Scan stopped at ' num2str(seqdata.scancycle) ...
                ' cycles of ' num2str(tblMaxScan.Data)]);
        else
            disp(['Scan stopped at' num2str(seqdata.scancycle) ' cycles']);
        end
        
        bRun.Enable='on';
        rScan.Enable='on';
        rSingle.Enable='on';
        bStop.Enable='off';
        
        end
    end            
end


%% AdWin Callbacks
% This section of the code defines the callbacks for running the sequencer.
%  It is separated by a different section in order to visually separate
%  front end GUI stuff from the actual sequence code.

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
                seqdata.randcyclelist=uint16(randperm(1000));    
                seqdata.doscan=1; 
                bStop.Enable='on';
                rSingle.Enable='off';
        end   
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

        
        disp([datestr(now,13) ' Running the sequence']);  
        fh = str2func(erase(eSeq.String,'@'));  
        
        % Compile the code
        disp(' ');
        disp(['     Compiling sequence  ' eSeq.String]);     
        disp(' ');
        tC1=now;                         % compile start time
        
        % Finish compiling the code
        fh(0);                          % run sequence function                  
        calc_sequence;                  % convert seqdata for AdWin        
        try
            load_sequence;              % load the sequence onto adwin
        catch exception
            disp('Unable to load sequence onto Adwin');
            warning(exception.message);
        end        
        tC2=now;                         % compile end time
        buildTime=(tC2-tC1)*(24*60*60);   % Build time in seconds   
        
        % Display compiling results
        disp(' ');
        disp('     Completed compiling! (did I actually work?)');
        disp(['     Build Time        : ' num2str(round(buildTime,2))]);
        disp(['     Sequence Run Time : ' ...
            num2str(round(seqdata.sequencetime,1)) 's']);    
        disp(' ');
       
        % Run the sequence
        try
            Start_Process(adwinprocessnum);
        catch exception
            disp('Unable to start the Adwin');
            warning(exception.message);            
        end

        % Update progress bars
        start(timeAdwin);
               
        % Seqdata history
                
        % create output file
        makeControlFile;
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
%         
        
        filenametxt = fullfile(seqdata.outputfilepath, 'control.txt');
        filenamemat=fullfile(seqdata.outputfilepath, 'control.mat');             

        disp(' ')
        disp([datestr(now,13) ' Saving sequence parameters']);
        disp(['     ' filenametxt]);
        disp(['     ' filenamemat]);

        [path,name,ext] = fileparts(filenametxt);
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
        fprintf(fid,'Execution Date: %s \n',datestr(now));
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
        %close the file
        fclose(fid);        
        %% Making a mat file witht the parameters
        outparams=struct;
        for kk=1:length(seqdata.outputparams)
            a=seqdata.outputparams{kk};
            outparams.(a{1})=a{2};
        end        
        params=seqdata.params;        
        % output both outparams and params
        save(filenamemat,'outparams','params');
        
        disp(' ');
    end


end


