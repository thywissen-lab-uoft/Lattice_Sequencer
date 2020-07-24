function mainGUI
%MAINGUI Summary of this function goes here
%   Detailed explanation goes here


%%%%%%%%%%%%%%% Initialize Sequence Data %%%%%%%%%%%%%%%%%
LatticeSequencerInitialize();
global seqdata;

%%%%%%%%%%%%%%% Initialize Graphics %%%%%%%%%%%%%%%%%
fName='Lattice Sequencer';

% Acquire the figure handle for the plottter in case you already opened it.
windowhnds = get(0,'Children');

% Close any figure with the same name.  Only one instance of the plotter is
% allowed.  (Maybe want to chage this in the future if we want to compare
% sequences?)
for i = 1:length(windowhnds)
    if isequal(windowhnds(i).Name,fName)
       close(fName); 
    end
end

% Figure color
cc='w';

% Initialize the figure graphics objects
hF=figure('toolbar','none','Name',fName,'color',cc,...
    'NumberTitle','off');

% Main uipanel
hpMain=uipanel('parent',hF,'units','pixels','backgroundcolor',cc,...
    'bordertype','none');
hpMain.OuterPosition=[0 0 hF.Position(3) hF.Position(4)];

% Title String
tTit=uicontrol(hpMain,'style','text','string','Lattice Sequencer',...
    'FontSize',18,'fontweight','bold','units','pixels',...
    'backgroundcolor',cc);
tTit.Position(3:4)=tTit.Extent(3:4);
tTit.Position(1:2)=[5 hpMain.Position(4)-tTit.Position(4)];

% Sequence File label
tSeq=uicontrol(hpMain,'style','text','String','Sequence File:',...
    'units','pixels','fontsize',10,'backgroundcolor',cc);
tSeq.Position(3:4)=tSeq.Extent(3:4);
tSeq.Position(1:2)=[5 tTit.Position(2)-tSeq.Position(4)];

% Sequence File edit box
str='@Load_MagTrap_sequence';
eSeq=uicontrol(hpMain,'style','edit','string',str,...
    'horizontalalignment','left','fontsize',10,'backgroundcolor',cc);
eSeq.Position(3)=250;
eSeq.Position(4)=eSeq.Extent(4);
eSeq.Position(1:2)=[5 tSeq.Position(2)-eSeq.Position(4)];

% Wait Time Table
tblWait=uitable(hpMain);
tblWait.RowName='Wait Time (ms)';
tblWait.ColumnName='';
tblWait.Data=1000;
tblWait.ColumnWidth={50};
tblWait.ColumnEditable=true;
tblWait.ColumnFormat={'numeric'};
tblWait.Position(3:4)=tblWait.Extent(3:4);
tblWait.Position(4)=tblWait.Position(4)-2;
tblWait.Position(1:2)=[5 eSeq.Position(2)-tblWait.Position(4)-5];


bRun=uicontrol(hpMain,'style','pushbutton','String','Run Cycle',...
    'backgroundcolor',[152 251 152]/255,'FontSize',14,'units','pixels',...
    'fontweight','bold');
bRun.Position(3:4)=[130 30];
bRun.Position(1:2)=[5 tblWait.Position(2)-bRun.Position(4)-5];

cRpt=uicontrol(hpMain,'style','checkbox','string','Repeat',...
    'backgroundcolor',cc,'Fontsize',10,'units','pixels');
cRpt.Position(4)=cRpt.Extent(4);
cRpt.Position(3)=100;
cRpt.Position(1:2)=[10+bRun.Position(3) bRun.Position(2)];

bList=uicontrol(hpMain,'style','pushbutton','String','Run List',...
    'backgroundcolor',[199 234 70]/255,'FontSize',14,'units','pixels',...
    'fontweight','bold','enable','off');
bList.Position(3:4)=[130 30];
bList.Position(1:2)=[5 bRun.Position(2)-bList.Position(4)-5];

bStop=uicontrol(hpMain,'style','pushbutton','String','Stop',...
    'backgroundcolor','#FF5E13','FontSize',14,'units','pixels',...
    'fontweight','bold','enable','off');
bStop.Position(3:4)=[130 30];
bStop.Position(1:2)=[5 bList.Position(2)-bStop.Position(4)-5];

bAbort=uicontrol(hpMain,'style','pushbutton','String','ABORT',...
    'backgroundcolor','r','FontSize',14,'units','pixels',...
    'fontweight','bold','enable','off');
bAbort.Position(3:4)=[130 30];
bAbort.Position(1:2)=[5 bStop.Position(2)-bAbort.Position(4)-5];


end

