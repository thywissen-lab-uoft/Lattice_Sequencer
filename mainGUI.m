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
h=270;

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
       
       if ~isempty(timerfind('Name',adwinTimeName)) && ...
               isequal(timeAdwin.Running,'on')
           tt=['The sequence is still running.  Are you sure you want ' ...
               'to close the GUI? The sequence data has already been ' ...
               'sent to the Adwin and the experiment will still be ' ...
               'running.'];
           tit='Sequence is still running!';
           
           f2=figure;
           set(f2,'Name',tit,'color','w','NumberTitle','off',...
               'windowstyle','modal','units','pixels','resize','off');
           f2.Position(3:4)=[400 140];
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

%%%%%%%%%%%%%%%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%%%%% Wait Time Interface %%%%

% Text label for inter cycle wait time
cWait=uicontrol(hpMain,'style','checkbox','string','inter cycle wait?',...
    'fontsize',10,'units','pixels','backgroundcolor',cc,'value',1);
cWait.Position(3:4)=cWait.Extent(3:4)+[20 0];
cWait.Position(1:2)=[5 eSeq.Position(2)-cWait.Position(4)-5];
cWait.Callback=@cWaitCB;

% Table for storing value of wait time
tblWait=uitable(hpMain,'RowName','','ColumnName','',...
    'Data',10,'ColumnWidth',{30},'ColumnEditable',true,...
    'ColumnFormat',{'numeric'},'fontsize',8);
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4);
tblWait.Position(1:2)=[cWait.Position(1)+cWait.Position(3) ...
    eSeq.Position(2)-tblWait.Position(4)-5];

% Seconds label for the wait time.
tWait=uicontrol(hpMain,'style','text','string','sec.',...
    'fontsize',8,'units','pixels','backgroundcolor',cc);
tWait.Position(3:4)=tWait.Extent(3:4);
tWait.Position(1)=tblWait.Position(1)+tblWait.Position(3);
tWait.Position(2)=tblWait.Position(2);

% Callback for enabling/disabling the wait timer.
    function cWaitCB(cBox,~)        
        if cBox.Value
            disp('Enabling intercycle wait timer.');
            tblWait.Enable='on';    % Enable wait time table            
        else
            disp('Disabling intercycle wait timer.');
            tblWait.Enable='off';   % Disable wait time table
            stop(timeWait);
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN CYCLE %%%%%%%%%%%%%%%%%%%%%%
% Button to run the cycle
bRun=uicontrol(hpMain,'style','pushbutton','String','Run Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold');
bRun.Position(3:4)=[130 30];
bRun.Position(1:2)=[5 tblWait.Position(2)-bRun.Position(4)-5];
bRun.Callback=@bRunCB;

% Checkbox for repeat cycle
cRpt=uicontrol(hpMain,'style','checkbox','string','Repeat',...
    'backgroundcolor',cc,'Fontsize',8,'units','pixels');
cRpt.Position(3:4)=[100 cRpt.Extent(4)];
cRpt.Position(1:2)=[10+bRun.Position(3) bRun.Position(2)];
cRpt.Callback=@cRptCB;

    function cRptCB(c,~)
        if c.Value
            disp(['Enabling sequence repeat. Reminder : The sequence ' ...
                'recompiles every iteration.']);
        else
            disp('Disabling sequence repeat.');
        end        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN LIST %%%%%%%%%%%%%%%%%%%%%%

% Button run a list
bList=uicontrol(hpMain,'style','pushbutton','String','Run List',...
    'backgroundcolor',[199 234 70]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off');
bList.Position(3:4)=[130 30];
bList.Position(1:2)=[5 bRun.Position(2)-bList.Position(4)-5];

% Checkbox to run the list randomly
cRand=uicontrol(hpMain,'style','checkbox','string','Random',...
    'backgroundcolor',cc,'Fontsize',8,'units','pixels');
cRand.Position(4)=cRand.Extent(4);
cRand.Position(3)=100;
cRand.Position(1:2)=[10+bList.Position(3) bList.Position(2)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN LIST ITERATION %%%%%%%%%%%%%%%%%%%%%%

% Button to run an iteration of a list
bIter=uicontrol(hpMain,'style','pushbutton','String','Run Iteration (1)',...
    'backgroundcolor',[199 234 70]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off');
bIter.Position(3:4)=[130 30];
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ABORT  %%%%%%%%%%%%%%%%%%%%%%
ttStr=['Interrupts AdWIN and sends all digital and analog voltage ' ...
    'outputs to their reset value.  DANGEROUS'];
bAbort=uicontrol(hpMain,'style','pushbutton','String','ABORT',...
    'backgroundcolor','r','FontSize',10,'units','pixels',...
    'fontweight','bold','Tooltip',ttStr);
bAbort.Position(3:4)=[80 30];
bAbort.Position(1:2)=[5 bIter.Position(2)-bAbort.Position(4)-5];
bAbort.Position(1:2)=[hpMain.Position(3)-bAbort.Position(3)-5 ...
    hpMain.Position(4)-bAbort.Position(4)-5];

jButton= findjobj(bAbort);
set(jButton,'Enabled',false);
set(jButton,'ToolTipText',ttStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WAIT BARS  %%%%%%%%%%%%%%%%%%%%%%
% Graphical objects for a timer bar, this will be used for both the adwin
% bar

% Graphical bar and commands for the adwin progress bar.
adwinbarcolor=[0.67578 1 0.18359];
axAdWinBar=axes('parent',hpMain,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axAdWinBar.Position=[10 10 hpMain.Position(3)-20 20];
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1], adwinbarcolor);
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','left','units','pixels','verticalalignment','bottom');
tAdWinTime1.Position=[5 21];
tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',10,...
    'horizontalalignment','right','units','pixels','verticalalignment','bottom');
tAdWinTime2.Position=[axAdWinBar.Position(3) 21];
tAdWinLabel=text(.5,1.05,'adwin progress','fontsize',10,...
    'horizontalalignment','center','verticalalignment','bottom','fontweight','bold');


% Graphical bar and commands for the wait bar.
waitbarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',hpMain,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1)=tWait.Position(1)+tWait.Position(3)+5;
axWaitBar.Position(4)=tblWait.Position(4);
axWaitBar.Position(3)=hpMain.Position(3)-axWaitBar.Position(1)-10;
axWaitBar.Position(2)=tblWait.Position(2);
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],waitbarcolor);


%% TIMERS
%%%%% Adwin progress timer %%%
% After the sequence is run, this timer keeps tracks of the Adwin's
% progress. It doesn't have direct access to the Adwin so it assumes the
% timing based on the results of the sequence compliation.

% The adwin progress timer object
timeAdwin=timer('Name',adwinTimeName,'ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateAdwinBar,'StartFcn',@sAdwin,'Period',.1);

% Function to run when the adwin starts the sequence.
    function sAdwin(~,~)
        % Notify the user
        disp(['Sequence started. ' num2str(seqdata.sequencetime,'%.2f') ...
            ' seconds run time.']);
                
        % Give the progress timer a new start time as userdata
        timeAdwin.UserData=now;        
        % Note that the function now is days since date (January 0, 0000)        
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
            stop(timeAdwin);                 % Stop the adwin timer
            disp('Sequence complete.');      % Message the user
            pAdWinBar.XData = [0 1 1 0];     % Fill out the bar
            drawnow;                         % Update graphics
            if cWait.Value
               start(timeWait);              % Start wait timer if needed
            else
                % Repeat the sequence if necessary
                if cRpt.Value
                    disp('Repeating the sequence.');
                    bRunCB; 
                end               
            end
        end
    end

%%%%% Intecycle wait timer %%%
% After a seqeunce runs, we typically insert a mandatory wait time before
% the sequence may run again.  This is because certain parts of the machine
% (CATs) will get hot. This time allows the water cooling to cool down the
% system to sufficiently safe levels.

% The wait timer object
timeWait=timer('Name',waitTimeName,'ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateWaitBar,'startdelay',0,'period',.1,...
    'StartFcn',@startWait,'StopFcn',@stopWait);

% Function to run when the wait timer begins
    function startWait(~,~)
        % Notify the user
        disp(['Starting the wait timer. ' ...
            num2str(tblWait.Data,'%.2f') ' seconds wait time.']);       
        
        % Give the wait timer a new start as userdata
        timeWait.UserData=now;         
        % Note that the function now is days since date (January 0, 0000)
    end

% Function to run when the wait timer is complete.
    function stopWait(~,~)
        disp('Inter cycle wait complete.'); % Notify the user
        pWaitBar.XData = [0 1 1 0];         % Fill out the bar
        drawnow;                            % Update graphics        
        % Repeat the sequence if necessary
        if cRpt.Value
           disp('Repeating the sequence.');
           bRunCB; % Should probably change some of these fucntion calls
        end  
    end

% Timer callback fucntion updates the wait bar graphics
    function updateWaitBar(~,~)
        tstart=timeWait.UserData;       % When the wait started
        dT0=tblWait.Data;               % Duration of wait        
        dT=(now-tstart)*24*60*60;       % Current wait duration
        
        % Update graphical progress bar for wait time
        pWaitBar.XData = [0 dT/dT0 dT/dT0 0];    
        drawnow;
        
        % Stop the timer.
        if dT>dT0
            stop(timeWait);  
        end
    end

%% AdWin Callbacks
% This section of the code defines the callbacks for running the sequencer.
%  It is separated by a different section in order to visually separate
%  front end GUI stuff from the actual sequence code.

% Run button callback.
    function bRunCB(~,~)    
        doDebug=1;        
        
        % Initialize the sequence if seqdata is not defined
        % Should this just happen every single time?
        if isempty(seqdata)
            LatticeSequencerInitialize();
        end
        
        % Am I allowed to run the sequene?
        if ~safeToRun
           return 
        end    
        
        disp([datestr(now,13) ' Running the cycle']);  
        fh = str2func(erase(eSeq.String,'@'));           

        % Compile the code
        disp(' ');
        disp(['     Compiling sequence  ' eSeq.String]);     
        disp(' ');
        tC1=now;                         % compile start time
        start_new_sequence;             % initialize new sequence
        
        % Put these in so no error. I think it should do nothing. It's from
        % the way that we do scan (which will change).
        seqdata.cycle = 1;   
        seqdata.scancycle = 1;
        seqdata.doscan = 0;
        seqdata.randcyclelist = 1:100;        
        
        % Finish compiling the code
        fh(0);                          % run sequence function                  
        calc_sequence();                % convert seqdata for AdWin        
        if ~doDebug
            load_sequence();                % load the sequence onto adwin
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

        % Update progress bars
        start(timeAdwin);
               
        % Seqdata history
        
        % update flag monitor
        
        % create output file

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
end


