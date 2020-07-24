function hFGUI=plotgui
% plotgui.m
%
% Author CJ : Fujiwara
% Version   : 0.2
%
% This code open a GUI for the Lattice Sequencer computer.  It primary
% intent is to enable a visual interface for the user to view relevant
% sequence parameters in a graphical way.

version='0.2';
str=['PlotGUI_v' version];

%% Fetch information from the primary GUI

% Intiailize sequence data
global seqdata;
start_new_sequence();
initialize_channels();
% In the future, the plotgui should probably have seqdata as an input
% argument. If we save the seqdata with every single run of the machine,
% then we would probably want to visually compares different sequences of
% the machine.



%%%%%%%%%%%%%%%%%%% TERRIBLE
% fetch seuqnece function
% THIS IS NOT GOOD CODE! NEVER USE EVAL IF YOU AVOID IT
    
    fh = findobj('Type','Figure','Name','Lattice Sequencer');
    if ~isempty(fh)
        uiobj1 = findobj(fh,'tag','sequence');
        eval(['sequencefunc = ' get(uiobj1,'string') ';']); 

        uiobj1 = findobj(fh,'tag','startcycle');
        startcycle = str2double(get(uiobj1,'string'));
    else
        warning('no lattice sequencer gui, manual override in loadmagtrap');
            % manual override    
        sequencefunc=@Load_MagTrap_sequence;
        startcycle=1;
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


seqdata.scancycle = 1;
seqdata.doscan = 0;
seqdata.randcyclelist = 1:100;


%%%%%%%%%%%%%%%%%%%% END TERRIBLE


% initialize structure of analog channels to show
aCHshow=seqdata.analogchannels(1);
aCHshow(:)=[];

% initialzie structure of digital channels to show
dCHshow=seqdata.digchannels(1);
dCHshow(:)=[];

%%%%%%%%%%%%%%% Primary graphical objects %%%%%%%%%%%%

% Initialize main figure
hFGUI=figure(99);
clf
set(hFGUI,'color','w','Name',str,'Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off');
hFGUI.Position(3:4)=[500 600];
hFGUI.Position(2)=50;

% Initialize uipanel that contains all channel information
hpAllChannels=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','Title','All Channels','fontsize',12);
hpAllChannels.Position=[4 4 hFGUI.Position(3)-8 350];

% Initialize the uipanel that contains the information for the plotter
hpPlot=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','Title','Plotter','fontsize',12);
hpPlot.Position=[4 4 hFGUI.Position(3)-8 250];
hpPlot.Position(2)=hpAllChannels.Position(2)+...
    hpAllChannels.Position(4)+2;

%%%%%%%%%%%%%%% Analog Channel Table  %%%%%%%%%%%%

% Analog channels table
htbl_aCH=uitable('parent',hpAllChannels,'RowName',{},'FontName',...
    'Monospaced');
htbl_aCH.ColumnName={'#', 'Name','show'};
htbl_aCH.ColumnWidth={20,150,40};
htbl_aCH.ColumnFormat={'char', 'char', 'logical'};
htbl_aCH.ColumnEditable=[false false true];
htbl_aCH.Position(3)=htbl_aCH.Extent(3)+17;
htbl_aCH.CellEditCallback=@AtblCB;
 
htbl_aCH.Position(1)=15;
htbl_aCH.Position(2)=5;
htbl_aCH.Position(4)=300;

drawnow;

% populate the table 
 for kk=1:length(seqdata.analogchannels)
    ch=seqdata.analogchannels(kk);
    rr=ch.channel;
    htbl_aCH.Data{rr,1}=num2str(rr,'%02.f');
    htbl_aCH.Data{rr,2}=ch.name;
    htbl_aCH.Data{rr,3}=false;
 end 
 
 % callback function for the analog table 
    function AtblCB(htbl,data)
        % get what row is initiating the callback
        r=data.Indices(1);        
        
        % check to see if the cell was edited
        if data.NewData && ~data.PreviousData
            % if going from 0->1 add the channel to the selected list
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([seqdata.analogchannels.channel]==chNum,1);
            aCH=seqdata.analogchannels(ind);
            aCHshow(end+1)=aCH;      
            disp(['Showing analog CH' ...
                num2str(chNum,'%02.f') ' : ' aCH.name]);
            
        elseif ~data.NewData && data.PreviousData
            % if going from 1->0 remove the channel from the selected list
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([aCHshow.channel]==chNum,1);
            disp(['Hiding  analog CH' ...
                num2str(chNum,'%02.f') ' : ' aCHshow(ind).name]);
            aCHshow(ind)=[];   
        end 
        % update the table of selected channels
        updateShowTBLA;
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
htbl_dCH=uitable('parent',hpAllChannels,'RowName',{},'FontName',...
    'Monospaced');
htbl_dCH.ColumnName={'#', 'Name','show'};
htbl_dCH.ColumnWidth={20,150,40};
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
        % get what row is initiating the callback
        r=data.Indices(1);       
        
        % check to see if the cell was edited      
        if data.NewData && ~data.PreviousData
            % if going from 0->1 add the channel to the selected list
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([seqdata.digchannels.channel]==chNum,1);
            dCH=seqdata.digchannels(ind);
            dCHshow(end+1)=dCH;      
            disp(['Showing digital CH' num2str(chNum,'%02.f') ...
                ' : ' dCH.name]);
            
        elseif ~data.NewData && data.PreviousData
            % if going from 1->0 remove the channel from the selected list
            chNum=str2num(htbl.Data{r,1}); 
            ind=find([dCHshow.channel]==chNum,1);
            disp(['Hiding  digital CH' num2str(chNum,'%02.f') ...
                ' : ' dCHshow(ind).name]);
            dCHshow(ind)=[];   
        end 
        updateShowTBLD;
    end

% string label for all available digital channels
str='Digital Channels';
tD=uicontrol('style','text','string',str,'fontweight','bold',...
    'fontname','arial','fontsize',10,'backgroundcolor','w',...
    'horizontalalignment','left');
tD.Position(1)=htbl_dCH.Position(1);
tD.Position(2)=htbl_dCH.Position(2)+htbl_dCH.Position(4)+5;
tD.Position(3)=htbl_dCH.Position(3);
 


%%%%%%%%%%%%%%% Plotter   %%%%%%%%%%%%

% Plot button
hbut_plot=uicontrol('style','pushbutton','string','plot',...
    'fontsize',12,'fontname','arial','units','pixels',...
    'parent',hpPlot);
hbut_plot.Position(3:4)=[50 25];
hbut_plot.Position(1)=5;
hbut_plot.Position(2)=hpPlot.Position(4)-hbut_plot.Position(4)-40;
hbut_plot.Callback=@plotCB;


hF_Plot=[];
    function plotCB(~,~)
       plottimes=htbl_time.Data;       
       plotchannels=[aCHshow.channel];
       tt=[dCHshow.channel]+length(seqdata.analogchannels);
       plotchannels=[plotchannels tt];      
       
%        [aTraces, dTraces]=generateTraces(seqdata);      
%         hF_Plot=PlotSequenceVersion2(sequencefunc,startcycle,plotchannels,plottimes);    
% 
        hF_Plot=plotSequence(sequencefunc,startcycle,...
            [aCHshow.channel],[dCHshow.channel],plottimes);    

    end

    function tblCB(tbl,data)

        if isnan(data.NewData) & isnumeric(data.NewData)
            disp([datestr(now,13) ' You inputted a non-numerical input' ...
                ' to the limits of the plot. Shameful']);
            tbl.Data(data.Indices(2))=data.PreviousData;
            return;
        end
        
        if isempty(hF_Plot)
            disp([datestr(now,13) ' You haven''t initialize the plot ' ...
                '. Shameful']);
            return;
        end
        
        if ~isvalid(hF_Plot)
            disp([datestr(now,13) ' I can''t plot because the figure ' ...
                'was deleted! (Shameful)']);
            return;
        end
        
        
        if ~isequal(data.NewData,data.PreviousData)
            disp([datestr(now,13) ' Changing the plot limits.']);  
            
            if tbl.Data(2)<tbl.Data(1)
               disp([datestr(now,13) ' Wow, you colossal buffoon,' ...
                   ' plot limits must in increasing order. Shameful']);
               tbl.Data(data.Indices(2))=data.PreviousData;
               return
            end
            
            
            chldrn=get(hF_Plot,'Children');
            for n=1:length(chldrn)
               try
                   chldrn(n).XLim=tbl.Data/1E3;             
               end
            end               
        end  
    end


% time limits table
htbl_time=uitable('parent',hpPlot);
htbl_time.ColumnName={'start','end'};
htbl_time.RowName={};
htbl_time.ColumnEditable=[true true];
htbl_time.ColumnFormat={'numeric','numeric'};
htbl_time.Data=[0 100000];
htbl_time.ColumnWidth={80 80};
htbl_time.Position(3:4)=htbl_time.Extent(3:4);
htbl_time.Position(1)=hbut_plot.Position(1)+hbut_plot.Position(3)+5;
htbl_time.Position(2)=hbut_plot.Position(2);
htbl_time.CellEditCallback=@tblCB;


% selected analog channels table
htbl_SelaCH=uitable('parent',hpPlot,'RowName',{},'Fontname',...
    'monospaced');
htbl_SelaCH.ColumnName={'#', 'Name'};
htbl_SelaCH.ColumnWidth={20,190};
htbl_SelaCH.ColumnFormat={'char', 'char'};
htbl_SelaCH.ColumnEditable=[false false true];
htbl_SelaCH.Position(4)=150;
htbl_SelaCH.Position(3)=htbl_SelaCH.Extent(3)+17;
htbl_SelaCH.Position(2)=4;
htbl_SelaCH.Position(1)=htbl_aCH.Position(1);

% callback for the selected analog channels table
    function updateShowTBLA
        htbl_SelaCH.Data={};
        [~,inds]=sort([aCHshow.channel]);
        aCHshow=aCHshow(inds);   

        for k=1:length(aCHshow)
        htbl_SelaCH.Data{end+1,1}=num2str(aCHshow(k).channel,'%02.f');
        htbl_SelaCH.Data{end,2}=aCHshow(k).name;
        end             
    end

% selected analog channels table
htbl_SeldCH=uitable('parent',hpPlot,'RowName',{},'Fontname',...
    'monospaced');
htbl_SeldCH.ColumnName={'#', 'Name'};
htbl_SeldCH.ColumnWidth={20,190};
htbl_SeldCH.ColumnFormat={'char', 'char'};
htbl_SeldCH.ColumnEditable=[false false true];
htbl_SeldCH.Position(4)=150;
htbl_SeldCH.Position(3)=htbl_SeldCH.Extent(3)+17;
htbl_SeldCH.Position(2)=4;
htbl_SeldCH.Position(1)=htbl_SelaCH.Position(1)+htbl_SelaCH.Position(3)+5;

% callback for the selected digital channels table
    function updateShowTBLD
        htbl_SeldCH.Data={};
        [~,inds]=sort([dCHshow.channel]);
        dCHshow=dCHshow(inds);   

        for k=1:length(dCHshow)
        htbl_SeldCH.Data{end+1,1}=num2str(dCHshow(k).channel,'%02.f');
        htbl_SeldCH.Data{end,2}=dCHshow(k).name;
        end         
    end

 
end

