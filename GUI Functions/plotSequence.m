function hF=plotSequence(fhandle,cycle,Achs,Dchs,times)
% plotSequence.m
% 
% Plots the sequence for a given set of analog and digital channels.
% 
% Authors: C Fujiwara
%
% This code is meant to be update the old sequence visualizer code
% PlotSequenceVersion2.m.  Therefore it has some historical forms which
% should be changed in future versions of this code.
%
%   fhandle - sequence function handle
%   cycle - cycle
%   Achs - which analog channels to analyze 
%   Dchs - which digital channels to analyze
%   times - the time limits on which to plot

fName='Plot Sequence';

% initizlize the seqdata object
global seqdata;


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

%% Calculate the sequence
start_new_sequence();
seqdata.cycle = cycle;

%run the sequence
fhandle(0);

% Should be updated.  You may want to visualize old sequences which
% therefore would not require another run of the sequence code.

%% Grab the channel data

% Sort the analog and digital data by traces
[aTraces, dTraces]=generateTraces(seqdata);

% Structure of channels to show
aTracesSHOW=aTraces;aTracesSHOW(:)=[];
dTracesSHOW=dTraces;dTracesSHOW(:)=[];

% Only keep the channels you want to plot
for kk=1:length(aTraces)
   if ismember(aTraces(kk).channel,Achs)
       aTracesSHOW(end+1)=aTraces(kk);
   end    
end

% Only keep the channels you want to plot
for kk=1:length(dTraces)
   if ismember(dTraces(kk).channel,Dchs)
       dTracesSHOW(end+1)=dTraces(kk);
   end  
end


%% Make the figure

% Initialize the GUI figure
hF=figure;
set(hF,'color','w','Name',fName);
hF.Position(1:4)=[100 100 500 800];
hF.SizeChangedFcn=@chFigSize;

% Figure change sizes callback
    function chFigSize(~,~)
        h=htbl_time.Extent(4);
        
        W=hF.Position(3);
        H=hF.Position(4);
        
        
        % Position of the analog panel
        hpA.Position(3:4)=[W (H-h)*.70];
        hpA.Position(1:2)=[0 H-hpA.Position(4)];
        
        % Position of the digial panel
        hpD.Position(3:4)=[W (H-h)*.30];
        hpD.Position(1:2)=[0 h];   
        
        % Position of the scrollbar
        hScroll.OuterPosition(3:4)=[20 hpA.Position(4)-10];
        hScroll.Position(1:2)=[hpA.Position(3)-hScroll.Position(3) 0];
        
        % Position of the scrollbar
        hScrollD.OuterPosition(3:4)=[20 hpD.Position(4)-10];
        hScrollD.Position(1:2)=[hpD.Position(3)-hScrollD.Position(3) 0];
       
       
        % Update analog channel axis limits
        for nn=1:length(axs)
            axs{nn}.Position=getAxPos(axs{nn},nn);
            ts{nn}.Position(1:2)=axs{nn}.Position(3:4)-[5 0];
        end        

        
        % Rescale the value of the analog scrollbar
        hScroll.Value=0;        
        minVal=-(axs{1}.Position(2)-axs{end}.Position(2)-hpA.Position(4)+200);        
        if minVal>=0
           hScroll.Visible='off'; 
        else
            hScroll.Min=minVal;
        end
       
        % Update digital axis limits
        axD.Position(1)=axs{1}.Position(1);
        axD.Position(3)=axs{1}.Position(3);
        axD.Position(2)=50;
        axD.Position(4)=hpD.Position(4)-axD.Position(2)-50;
        
        axDL.Position(1)=5;
        axDL.Position(3)=axD.Position(1)-axDL.Position(1);
        axDL.Position(2)=axD.Position(2);
        axDL.Position(4)=axD.Position(4);
        axDL.YLim=[-axDL.Position(4) 0];
        
        axD.YLim=axDL.YLim;
                
%         % Rescale the value of the digital scrollbar
%         hScrollD.Value=0;        

%         if minVal>=0
%            hScroll.Visible='off'; 
%         else
%             hScroll.Min=minVal;
%         end
       

        drawnow;
    end

% Set an axis set
    function pos=getAxPos(ax,ind)        
        
        
        % [left, right, bottom, top] boundaries between figure
        B=[150 40 50 50];

        % vertical separation between axes
        dY=30;
        nR=4;

        % axes width and height
        w=ax.Parent.Position(3)-B(1)-B(2);
        h=(ax.Parent.Position(4)-B(3)-B(4)-dY*(nR-1))/nR;
        
        % manually set the height of each axis
        h=100;


        % update the position
        pos=[B(1) ax.Parent.Position(4)-B(4)-ind*h-(ind-1)*dY w h];
    end

%% Settings 


% time limits table
htbl_time=uitable('parent',hF);
htbl_time.ColumnName={'start (ms)','end (ms)'};
htbl_time.RowName={};
htbl_time.ColumnEditable=[true true];
htbl_time.ColumnFormat={'numeric','numeric'};
htbl_time.Data=[0 100000];
htbl_time.ColumnWidth={120 120 120};
htbl_time.Position(3:4)=htbl_time.Extent(3:4);
htbl_time.Position(1:2)=[0 0];
htbl_time.CellEditCallback=@tblCB;


    function tblCB(tbl,data)

        if isnan(data.NewData) & isnumeric(data.NewData)
            disp([datestr(now,13) ' You inputted a non-numerical input' ...
                ' to the limits of the plot. Shameful']);
            tbl.Data(data.Indices(2))=data.PreviousData;
            return;
        end      
        
        if tbl.Data(2)<tbl.Data(1) 
            disp([datestr(now,13) ' Wow, you colossal buffoon,' ...
                ' plot limits must in increasing order. Shameful']);
           tbl.Data(data.Indices(2))=data.PreviousData;
            return;
        end
        
        if isequal(data.NewData,data.PreviousData)
            return;
        end          

        disp([datestr(now,13) ' Changing the plot limits.']);               
           
        for n=1:length(axs)
           axs{n}.XLim=tbl.Data(1:2)*1E-3;
           axD.XLim=tbl.Data(1:2)*1E-3;
        end              
        
    end  
    



%% Analog Channels panel
% analog channels window pane
hpA=uipanel('parent',hF,'units','pixels','Title','Analog',...
    'backgroundcolor','w');

% Create analog channels axes
axs={};
ts={};


for kk=1:length(aTracesSHOW)  
    axs{kk}=axes('parent',hpA,'units','pixels');
    axs{kk}.Position=getAxPos(axs{kk},kk);
    
    X=aTracesSHOW(kk).data(:,1);
    X=X*seqdata.deltat/seqdata.timeunit;
    Y=aTracesSHOW(kk).data(:,2);
    
    % add starting and ending values to curve. Do this because the list of
    % values are the WRITE commands (the values are held constant until
    % the next write command
    if ~isempty(X)
        X=[0; X; 1E6];
        Y=[Y(end); Y; Y(end)]; 
    else
        wStr=['Channel ' num2str(aTracesSHOW(kk).channel) ' : ' ...
            aTracesSHOW(kk).name ' has no data! Cant''t plot it.'];
        warning(wStr);
    end

    % Plot the data.  The stairs function interpolates the write as a
    % square wave which is indicative of the physical voltages that are
    % currently outputed at that time.
    stairs(X*1E-3,Y,'color','k','linewidth',2);
    
    
    % Change the limits
    axs{kk}.XLim=times*1E-3;
    drawnow
    
    % text label
    str=['a' num2str(aTracesSHOW(kk).channel) ' ' aTracesSHOW(kk).name];
    ts{kk}=text(0,0,str,'fontsize',10,'horizontalalignment','right',...
        'verticalalignment','cap','units','pixels');

    set(gca,'fontsize',10,'linewidth',1);
    drawnow;
end


% set up the scrollbar
hScroll = uicontrol('parent',hpA,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll');
hScroll.Max=0;
hScroll.Value=0;
hScroll.Callback=@scrollCB;
hScroll.SliderStep=[0.05 .1];
% set(gcf,'WindowScrollWheelFcn',@wheelScroll)      

    function scrollCB(a,~)        
        for nn=1:length(axs)
            pos=getAxPos(axs{nn},nn);
            axs{nn}.Position(2)=pos(2)-a.Value;
        end        
    end


    function wheelScroll(~,~)
       disp('whoooooooooooah this is going to be fucking complicated'); 
    end

%% Digital channels
hText=20;

% digital channels window pane
hpD=uipanel('parent',hF,'units','pixels','Title','Digital',...
    'backgroundcolor','w');

axD=axes('parent',hpD,'units','pixels','box','on','linewidth',1,...
    'YTick',hText*(-length(dTracesSHOW):0),'YGrid','On','YTickLabel',{},...
    'GridAlpha',1);
xlabel('time (ms)');
co=get(gca,'colororder');
for i=1:length(dTracesSHOW)
    X=dTracesSHOW(i).data(:,1);
    X=X*seqdata.deltat/seqdata.timeunit;
    Y=dTracesSHOW(i).data(:,2);
    

    
    % add starting and ending values to curve. Do this because the list of
    % values are the WRITE commands (the values are held constant until
    % the next write command
    if ~isempty(X)
        X=[0; X; 1E6];
        Y=[Y(end); Y; Y(end)]; 
    else
        wStr=['Channel ' num2str(dTracesSHOW(i).channel) ' : ' ...
            dTracesSHOW(i).name ' has no data! Cant''t plot it.'];
        warning(wStr);
    end
    
    [~,inds]=sort(X);
    X=X(inds);
    Y=Y(inds);

    % Plot the data.  The stairs function interpolates the write as a
    % square wave which is indicative of the physical voltages that are
    % currently outputed at that time.
 
    for np=1:(length(X)-1)
        p=[1E-3*X(np) -i*hText 1E-3*(X(np+1)-X(np)) hText];
        
        if Y(np)
        rectangle('Position',p,...
            'facecolor',co(mod(i-1,7)+1,:),'linestyle','none');
        end
        
    end
    
    hold on
    xlim(times*1E-3);

end


axDL=axes('parent',hpD,'units','pixels','box','on','linewidth',1,...
    'fontname','monospaced','XTick',[],'YTick',[]);
xlim([0 1]);

co=get(gca,'colororder');

for i=1:length(dTracesSHOW)
    rectangle('Position',[0 -i*hText 1 1*hText],'facecolor',co(mod(i-1,7)+1,:))
    text(.5,-(i-.5)*hText,dTracesSHOW(i).name,...
        'HorizontalAlignment','center','fontsize',10,'clipping','on',...
        'units','data','verticalalignment','middle');
end
% ylim([1 10]);



% set up the scrollbar
hScrollD = uicontrol('parent',hpD,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll');
hScrollD.Max=0;
hScrollD.Value=0;
hScrollD.Callback=@scrollCBD;
hScrollD.SliderStep=[0.05 .1];

    function scrollCBD(~,~)        
        axDL.YLim=[-axDL.Position(4) 0]+hScrollD.Value;        
        axD.YLim=axDL.YLim;
    end


hScrollD.Min=-length(dTracesSHOW);
hScrollD.Max=0;

%% Finish

chFigSize;

end

