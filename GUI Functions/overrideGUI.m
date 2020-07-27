function hFGUI=overrideGUI
global seqdata;
start_new_sequence();
initialize_channels();


% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name','Adwin Override','Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off');
hFGUI.Position(3:4)=[710 600];
hFGUI.Position(2)=50;

% Initialize uipanel that contains all channel information
hpMain=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','fontsize',12);
hpMain.Position=[0 0 hFGUI.Position(3) hFGUI.Position(4)];


%%%%%%%%%%%%%%% Analog Channel Table  %%%%%%%%%%%%

% Analog channels table
htbl_aCH=uitable('parent',hpMain,'RowName',{},'FontName',...
    'Monospaced');
htbl_aCH.ColumnName={'#', 'Name','override?','value','func#'};
htbl_aCH.ColumnWidth={20,150,60,50,50};
htbl_aCH.ColumnFormat={'char', 'char', 'logical','numeric','numeric'};
htbl_aCH.ColumnEditable=[false false true true true];
htbl_aCH.Position(3)=htbl_aCH.Extent(3)+17;
% htbl_aCH.CellEditCallback=@AtblCB;
 
htbl_aCH.Position(1)=15;
htbl_aCH.Position(2)=5;
htbl_aCH.Position(4)=hpMain.Position(4)-50;

drawnow;

% populate the table 
 for kk=1:length(seqdata.analogchannels)
    ch=seqdata.analogchannels(kk);
    rr=ch.channel;
    htbl_aCH.Data{rr,1}=num2str(rr,'%02.f');
    htbl_aCH.Data{rr,2}=ch.name;
    htbl_aCH.Data{rr,3}=false;
    val=real(ch.resetvalue);val=val(1);
    htbl_aCH.Data{rr,4}=val;
    htbl_aCH.Data{rr,5}=ch.defaultvoltagefunc;
 end 
 
 % callback function for the analog table 
    function AtblCB(htbl,data)
        % get what row is initiating the callback
     
    end

% string label for all available analog channels
str='Analog Channels';
tA=uicontrol('style','text','string',str,'fontweight','bold',...
    'fontname','arial','fontsize',10,'backgroundcolor','w',...
    'horizontalalignment','left');
tA.Position(1)=htbl_aCH.Position(1);
tA.Position(2)=htbl_aCH.Position(2)+htbl_aCH.Position(4)+5;
tA.Position(3)=htbl_aCH.Position(3);

%%%%%%%%%%%%%%% Digital Channel Table  %%%%%%%%%%%%

% digital channels table
htbl_dCH=uitable('parent',hpMain,'RowName',{},'FontName',...
    'Monospaced');
htbl_dCH.ColumnName={'#', 'Name','override?','state'};
htbl_dCH.ColumnWidth={20,150,60,40};
htbl_dCH.ColumnFormat={'char', 'char', 'logical'};
htbl_dCH.ColumnEditable=[false false true true];
htbl_dCH.Position(2:4)=htbl_aCH.Position(2:4);
htbl_dCH.Position(3)=htbl_dCH.Extent(3)+17;
htbl_dCH.Position(1)=htbl_aCH.Position(1)+htbl_aCH.Position(3)+50;
% htbl_dCH.CellEditCallback=@DtblCB;

% populate the table 
 for kk=1:length(seqdata.analogchannels)
    ch=seqdata.digchannels(kk);
    rr=ch.channel;
    htbl_dCH.Data{rr,1}=num2str(rr,'%02.f');
    htbl_dCH.Data{rr,2}=ch.name;
    htbl_dCH.Data{rr,3}=false;    
    
    val=logical(real(ch.resetvalue));
    htbl_dCH.Data{rr,4}=val;

 end 
 
  % callback function
    function DtblCB(htbl,data)
        % get what row is initiating the callback
       
    end

% string label for all available digital channels
str='Digital Channels';
tD=uicontrol('style','text','string',str,'fontweight','bold',...
    'fontname','arial','fontsize',10,'backgroundcolor','w',...
    'horizontalalignment','left');
tD.Position(1)=htbl_dCH.Position(1);
tD.Position(2)=htbl_dCH.Position(2)+htbl_dCH.Position(4)+5;
tD.Position(3)=htbl_dCH.Position(3);
 



end

