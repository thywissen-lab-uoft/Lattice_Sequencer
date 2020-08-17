function mainGUI
% This is the primary GUI for running the lattice experiment.
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

%% Initialize Graphics

%%%%%%%%%%%%%%% Initialize Graphics %%%%%%%%%%%%%%%%%
fName='Lattice Sequencer';

% Acquire the figure handle for the plottter in case you already opened it.
windowhnds = get(0,'Children');

% Close any figure with the same name. Only one instance of mainGUI may be
% open at a time
for i = 1:length(windowhnds)
    if isequal(windowhnds(i).Name,fName)
       close(fName); 
    end
end

% Figure color and size settings
cc='w';
w=350;
h=300;

%%%%%%%%%%%%%%%% INITIALIZE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',fName,'color',cc,...
    'NumberTitle','off','MenuBar','none','resize','off');
clf
hF.Position(3:4)=[w h];
hF.SizeChangedFcn=@adjustSize;

% Callback fucntion on adjust figure sizes
function adjustSize(fig,~)    
    % Adjust the main panel to fit within the new figure size
    hpMain.OuterPosition=[0 fig.Position(4)-h w h];
    drawnow;
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
            tblWait.Enable='on';    % Enable wait time table
        else
            tblWait.Enable='off';   % Disable wait time table
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STOP  %%%%%%%%%%%%%%%%%%%%%%

bStop=uicontrol(hpMain,'style','pushbutton','String','Stop',...
    'backgroundcolor','#FF5E13','FontSize',10,'units','pixels',...
    'fontweight','bold','enable','off');
bStop.Position(3:4)=[130 30];
bStop.Position(1:2)=[5 bIter.Position(2)-bStop.Position(4)-5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ABORT  %%%%%%%%%%%%%%%%%%%%%%


ttStr=['Interrupts AdWIN and sends all digital and analog voltage outputs to their ' ...
    'reset value.  DANGEROUS'];
bAbort=uicontrol(hpMain,'style','pushbutton','String','ABORT',...
    'backgroundcolor','r','FontSize',10,'units','pixels',...
    'fontweight','bold','Tooltip',ttStr);
bAbort.Position(3:4)=[80 30];
bAbort.Position(1:2)=[5 bStop.Position(2)-bAbort.Position(4)-5];
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
pAdWinBar = patch(axAdWinBar,[0 0 0 0],[0 0 1 1],...
    adwinbarcolor);
tAdWinTime1 = text(0,0,'0.00 s','parent',axAdWinBar,'fontsize',10,'horizontalalignment',...
    'left','units','pixels','verticalalignment','bottom');
tAdWinTime1.Position=[5 21];
tAdWinTime2 = text(0,0,'30.00 s','parent',axAdWinBar,'fontsize',10,'horizontalalignment',...
    'right','units','pixels','verticalalignment','bottom');
tAdWinTime2.Position=[axAdWinBar.Position(3) 21];
tAdWinLabel=text(.5,1.05,'adwin progress','fontsize',10,'horizontalalignment','center',...
    'verticalalignment','bottom','fontweight','bold');



% Graphical bar and commands for the wait bar.
waitarcolor=[106, 163, 241 ]/255;
axWaitBar=axes('parent',hpMain,'units','pixels','XTick',[],...
    'YTick',[],'box','on','XLim',[0 1],'Ylim',[0 1]);
axWaitBar.Position(1)=tWait.Position(1)+tWait.Position(3)+5;
axWaitBar.Position(4)=tblWait.Position(4);
axWaitBar.Position(3)=hpMain.Position(3)-axWaitBar.Position(1)-10;
axWaitBar.Position(2)=tblWait.Position(2);
pWaitBar = patch(axWaitBar,[0 0 0 0],[0 0 1 1],...
    waitarcolor);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TIMERS  %%%%%%%%%%%%%%%%%%%%%%

% adwin_process_timer = timer('TimerFcn',fhandle,'StartDelay',round(seqdata.sequencetime*1000)/1000,...
%     'Name','adwin_proces_timerCB');

%%%%% Adwin progress timer %%%
% After the sequence is run, this timer keeps tracks of the AdWins
% progress. It doesn't have direct access to the Adwin so it assumes the
% timing based on the results of the sequence compliation.

% The adwin progress timer object
timeAdwin=timer('Name','AdwinProgressTimer','ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateAdwinBar,'StartFcn',@sAdwin,'Period',.1);

% Function to run when the adwin starts the sequence.
    function sAdwin(~,~)
        % Display some user notifications
        disp('Sequence started.');
                
        % Give the progress timer a new start
        timeAdwin.UserData=now;        
        % Note that the function now is days since date (January 0, 0000)
        
    end

    function updateAdwinBar(~,~)
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
           stop(timeAdwin);
           disp('Sequence complete.');
           pAdWinBar.XData = [0 1 1 0];    
           if cWait.Value
               start(timeWait);
           end
        end
    end

%%%%% Intecycle wait timer %%%
% After a seqeunce runs, we typically insert a mandatory wait time before
% the sequence may run again.  This is because certain parts of the machine
% (CATs) will get hot. This time allows the water cooling to cool down the
% system to sufficiently safe levels.

% The wait timer object
timeWait=timer('Name','InterCycleWaitTimer','ExecutionMode','FixedSpacing',...
    'TimerFcn',@updateWaitBar,'startdelay',0,'period',.1,'StartFcn',@sWait);

    function sWait(~,~)
        disp(['Starting the wait timer ' ...
            num2str(tblWait.Data,'%.2f') ' seconds.']);       
        
        % Give the wait timer a new start
        timeWait.UserData=now;         
        % Note that the function now is days since date (January 0, 0000)
    end

    function updateWaitBar(~,~)
        tstart=timeWait.UserData;       % When the wait started
        dT0=tblWait.Data;               % Duration of wait        
        dT=(now-tstart)*24*60*60;       % Current wait duration
        
        % Update graphical progress bar for wait time
        pWaitBar.XData = [0 dT/dT0 dT/dT0 0];    
        drawnow;
        
        % Stop the timer.
        if dT>dT0
            disp('Inter cycle wait complete.');
            stop(timeWait);    
            pWaitBar.XData = [0 1 1 0];    
            
            % Repeat the sequence if necessary
            if cRpt.Value
               disp('Repeating the sequence.');
               bRunCB; % Should probably change some of these fucntion calls
            end
            
            
            
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
        
        
        % Display results
        disp(' ');
        disp('     Completed compiling! (did I actually work?)');
        disp(['     Build Time        : ' num2str(round(buildTime,2))]);
        disp(['     Sequence Run Time : ' ...
            num2str(round(seqdata.sequencetime,1)) 's']);    
       disp(' ');

        % Update progress bars
        start(timeAdwin);

        
        % Begin various timers
        
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
           
        % Check if the experiment is already running.
        isRun=0;
        if isRun
           warning(['The experiment is still running you dummy']);
           return
        end
        
        % Check if the wait timer is already running.
        isWait=0;
        if isWait
           warning(['The sequencer is waiting before another cycle can ' ...
               'be run. To override please the wait, please use the ' ...
               'appropriate GUI buttons.']);
           return
        end
        
        out=1;
    end


end


