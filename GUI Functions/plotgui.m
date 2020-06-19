function hFGUI=plotgui
%PLOTGUI Summary of this function goes here
%   Detailed explanation goes here

% Version control string
version='0.1';
str=['PlotGUI_v' version];

% Intiailize sequence data
global seqdata;
start_new_sequence();
initialize_channels();

% initialize structure of analog channels to show
aCHshow=seqdata.analogchannels(1);
aCHshow(:)=[];

% initialzie structure of digital channels to show
dCHshow=seqdata.digchannels(1);
dCHshow(:)=[];

%%%%%%%%%%%%%%% Graphical Objects %%%%%%%%%%%%

% Initialize main figure
hFGUI=figure(99);
clf
set(hFGUI,'color','w','Name',str,'Toolbar','none','menubar','none',...
    'NumberTitle','off');
hFGUI.Position(3:4)=[500 800];
hFGUI.Position(2)=50;

%%%%%%%%%%%%%%% Channel Tables  %%%%%%%%%%%%

% Analog channels table
htbl_aCH=uitable;
htbl_aCH.RowName={};
htbl_aCH.ColumnName={'#', 'Name','show'};
htbl_aCH.ColumnWidth={20,150,40};
htbl_aCH.FontName='monospaced';
htbl_aCH.ColumnFormat={'char', 'char', 'logical'};
htbl_aCH.ColumnEditable=[false false true];
htbl_aCH.Position(3)=htbl_aCH.Extent(3)+17;
 htbl_aCH.CellEditCallback=@AtblCB;

% populate the table 
 for kk=1:length(seqdata.analogchannels)
    ch=seqdata.analogchannels(kk);
    rr=ch.channel;
    htbl_aCH.Data{rr,1}=num2str(rr,'%02.f');
    htbl_aCH.Data{rr,2}=ch.name;
    htbl_aCH.Data{rr,3}=false;
 end 
 
 % callback function
    function AtblCB(htbl,data)
        r=data.Indices(1);        
        
        if data.NewData && ~data.PreviousData
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([seqdata.analogchannels.channel]==chNum,1);
            aCH=seqdata.analogchannels(ind);
            aCHshow(end+1)=aCH;      
            disp(['Showing analog CH' num2str(chNum,'%02.f') ' : ' aCH.name]);
            
        elseif ~data.NewData && data.PreviousData
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([aCHshow.channel]==chNum,1);
            disp(['Hiding  analog CH' num2str(chNum,'%02.f') ' : ' aCHshow(ind).name]);
            aCHshow(ind)=[];   
        end 
        updateShowTBL;
    end

str='Analog Channels';
tA=uicontrol('style','text','string',str,'fontweight','bold',...
    'fontname','arial','fontsize',12,'backgroundcolor','w',...
    'horizontalalignment','left');
tA.Position(1)=htbl_aCH.Position(1);
tA.Position(2)=htbl_aCH.Position(2)+htbl_aCH.Position(4)+2;
tA.Position(3)=htbl_aCH.Position(3);

% digital channels table
htbl_dCH=uitable;
htbl_dCH.RowName={};
htbl_dCH.ColumnName={'#', 'Name','show'};
htbl_dCH.ColumnWidth={20,150,40};
htbl_dCH.FontName='monospaced';
htbl_dCH.ColumnFormat={'char', 'char', 'logical'};
htbl_dCH.ColumnEditable=[false false true];
htbl_dCH.Position(3)=htbl_dCH.Extent(3)+17;
htbl_dCH.Position(2:4)=htbl_aCH.Position(2:4);
htbl_dCH.Position(1)=htbl_aCH.Position(1)+htbl_aCH.Position(3)+5;

 htbl_dCH.CellEditCallback=@DtblCB;

% populate the table 
 for kk=1:length(seqdata.analogchannels)
    ch=seqdata.digchannels(kk);
    rr=ch.channel;
    htbl_dCH.Data{rr,1}=num2str(rr,'%02.f');
    htbl_dCH.Data{rr,2}=ch.name;
    htbl_dCH.Data{rr,3}=false;
 end 
 
  % callback function
    function DtblCB(htbl,data)
        r=data.Indices(1);        
        
        if data.NewData && ~data.PreviousData
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([seqdata.digchannels.channel]==chNum,1);
            dCH=seqdata.digchannels(ind);
            dCHshow(end+1)=dCH;      
            disp(['Showing digital CH' num2str(chNum,'%02.f') ' : ' dCH.name]);
            
        elseif ~data.NewData && data.PreviousData
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([dCHshow.channel]==chNum,1);
            disp(['Hiding  digital CH' num2str(chNum,'%02.f') ' : ' dCHshow(ind).name]);
            dCHshow(ind)=[];   
        end 
        updateShowTBL;
    end

str='Digital Channels';
tA=uicontrol('style','text','string',str,'fontweight','bold',...
    'fontname','arial','fontsize',12,'backgroundcolor','w',...
    'horizontalalignment','left');
tA.Position(1)=htbl_dCH.Position(1);
tA.Position(2)=htbl_dCH.Position(2)+htbl_dCH.Position(4)+2;
tA.Position(3)=htbl_dCH.Position(3);
 
% show channels table
htbl_show=uitable;
htbl_show.RowName={};
htbl_show.ColumnName={'#', 'Name','type'};
htbl_show.ColumnWidth={20,150,55};
htbl_show.FontName='monospaced';
htbl_show.ColumnFormat={'char', 'char', 'char'};
htbl_show.ColumnEditable=[false false true];

htbl_show.Position(3)=htbl_dCH.Extent(3)+17;
htbl_show.Position(2)=htbl_aCH.Position(2)+htbl_aCH.Position(4)+30;
htbl_show.Position(1)=htbl_aCH.Position(1);

    function updateShowTBL
       htbl_show.Data={};
       [~,inds]=sort([aCHshow.channel]);
       aCHshow=aCHshow(inds);   
       
       [~,inds]=sort([dCHshow.channel]);
       dCHshow=dCHshow(inds); 
       
          for k=1:length(aCHshow)
          htbl_show.Data{end+1,1}=num2str(aCHshow(k).channel,'%02.f');
          htbl_show.Data{end,2}=aCHshow(k).name;
          htbl_show.Data{end,3}='analog';
       end
       
       for k=1:length(dCHshow)
          htbl_show.Data{end+1,1}=num2str(dCHshow(k).channel,'%02.f');
          htbl_show.Data{end,2}=dCHshow(k).name;
          htbl_show.Data{end,3}='digital';
       end
       
    end

%%%%%%%%%%%%%%% Plotter   %%%%%%%%%%%%

 
 
 
end

