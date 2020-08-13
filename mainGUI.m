function mainGUI
%MAINGUI Summary of this function goes here
%
% Author      : CJ Fujiwara
% Last Edited : 2020/08
%
% This is the primary GUI for running the lattice experiment.


%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;

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
h=250;

%%%%%%%%%%%%%%%% INITIALIZE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',fName,'color',cc,...
    'NumberTitle','off','MenuBar','none','resize','off');
clf
hF.Position(3:4)=[w h];
hF.SizeChangedFcn=@adjustSize;

function adjustSize(fig,~)    
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

cdata=imresize(imread(['GUI Functions' filesep 'browse.jpg']),[20 20]);
bBrowse=uicontrol(hpMain,'style','pushbutton','CData',cdata,...
    'backgroundcolor',cc);
bBrowse.Position(3:4)=size(cdata,[1 2]);
bBrowse.Position(1:2)=eSeq.Position(1:2)+[eSeq.Position(3)+2 0];
bBrowse.Callback=@browseCB;

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

% Manual overrride
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

% Wait Time Table
tblWait=uitable(hpMain,'RowName','Wait Time (ms)','ColumnName','',...
    'Data',1000,'ColumnWidth',{50},'ColumnEditable',true,...
    'ColumnFormat',{'numeric'});
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4);
tblWait.Position(1:2)=[5 eSeq.Position(2)-tblWait.Position(4)-5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN CYCLE %%%%%%%%%%%%%%%%%%%%%%

% Button to run the cycle
bRun=uicontrol(hpMain,'style','pushbutton','String','Run Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',10,'units','pixels',...
    'fontweight','bold');
bRun.Position(3:4)=[130 30];
bRun.Position(1:2)=[5 tblWait.Position(2)-bRun.Position(4)-5];

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

end

