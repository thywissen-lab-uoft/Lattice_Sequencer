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

% Name of the figure
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

% run the sequence
fhandle(0);

% Should be updated.  You may want to visualize old sequences which
% therefore would not require another run of the sequence code.

%% Grab the channel data

% Sort the analog and digital data by traces
[aTraces, dTraces]=generateTraces(seqdata);

% Initialize structure of analog and digital channels to show
aTracesSHOW=aTraces;aTracesSHOW(:)=[];
dTracesSHOW=dTraces;dTracesSHOW(:)=[];

% From all the analog channels keep ones you want to plot
for kk=1:length(aTraces)
   if ismember(aTraces(kk).channel,Achs)
       aTracesSHOW(end+1)=aTraces(kk);
   end    
end

% From all the digital channels keep ones you want to plot
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
hZ=zoom(hF);

% Assign callbacks to zoom function.  This only works if you had clicked on
% the zoom function and there doesn't work very well at this moment
hZ.ActionPreCallback=@chZoomPre;
hZ.ActionPostCallback=@chZoomPost;

    function chZoomPre(~,obj)
        ax=obj.Axes;            
        disp('hipre');
        htbl_time.Data=ax.XLim;
    end
    function chZoomPost(~,obj)
        ax=obj.Axes;            
        htbl_time.Data=ax.XLim;
        disp('hipost');
    end

% Figure change sizes callback
    function chFigSize(~,~)
        % The time table size; (it doesn't change size)
        h=htbl_time.Extent(4);
        
        % Get the main GUI figure size
        W=hF.Position(3);
        H=hF.Position(4);        
        
        % Set the size of the analog panel
        hpA.Position(3:4)=[W (H-h)*.70];
        hpA.Position(1:2)=[0 H-hpA.Position(4)];
        
        % Set the position of the analog scroll bar
        hAslider.OuterPosition(3:4)=[20 hpA.Position(4)-10];
        hAslider.Position(1:2)=[hpA.Position(3)-hAslider.Position(3) 0];
        
        % Set the size of the digital panel
        hpD.Position(3:4)=[W (H-h)*.30];
        hpD.Position(1:2)=[0 h];   
        
        % Set the position of the digital scroll bar
        hDslider.OuterPosition(3:4)=[20 hpD.Position(4)-10];
        hDslider.Position(1:2)=[hpD.Position(3)-hDslider.Position(3) 0];
               
        % Reset the location of all the axes to the default
        for nn=1:length(axs)
            axs{nn}.Position=getAxPos(axs{nn},nn);
            ts{nn}.Position(1:2)=axs{nn}.Position(3:4)-[5 0];
        end        
        
        % Edge case for no analog traces (there is a better way to do this)
        if ~isempty(aTracesSHOW)
            % Rescale the value of the analog scrollbar
            hAslider.Value=0;        
            minVal=-(axs{1}.Position(2)-axs{end}.Position(2)-...
                hpA.Position(4)+200);      

            % Rescale the analog scrollbar
            if minVal>=0
               hAslider.Visible='off'; 
            else
                hAslider.Min=minVal;
            end         
        end
       
        % Update digital axis position
        axD.Position(1)=axs{1}.Position(1);
        axD.Position(3)=axs{1}.Position(3);
        axD.Position(2)=50;
        axD.Position(4)=hpD.Position(4)-axD.Position(2)-17;
        
        % Update digital label axis position
        axDL.Position(1)=5;
        axDL.Position(3)=axD.Position(1)-axDL.Position(1);
        axDL.Position(2)=axD.Position(2);
        axDL.Position(4)=axD.Position(4);
        
        % Reset the digital axis limits
        axDL.YLim=[-axDL.Position(4) 0];        
        axD.YLim=axDL.YLim;
                
        % Apply graphical updates
        drawnow;
    end

% Calcualte the analog axis position
    function pos=getAxPos(ax,ind)    
        % [left, right, bottom, top] boundaries between figure
        B=[150 40 50 50];

        % vertical separation between axes
        dY=30;
        nR=4; 

        % axes width
        w=ax.Parent.Position(3)-B(1)-B(2);
        
        % axis height using the desired number of plots to show
        h=(ax.Parent.Position(4)-B(3)-B(4)-dY*(nR-1))/nR;
        
        % manually set the pixel height of each axis
        h=100;

        % assemble the entire calcualted position vector
        pos=[B(1) ax.Parent.Position(4)-B(4)-ind*h-(ind-1)*dY w h];
    end

%% Settings 


% Time limits table
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


% Callback for editing the time table
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

% Analog channels axes cell list
axs={};

% Analog channels labels cell list
ts={};

for kk=1:length(aTracesSHOW)  
    % Create the axis for this channel
    axs{kk}=axes('parent',hpA,'units','pixels');
    axs{kk}.Position=getAxPos(axs{kk},kk);


    % Collect and format the data
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
    
    % Analog channel text label
    str=['a' num2str(aTracesSHOW(kk).channel) ' ' aTracesSHOW(kk).name];
    ts{kk}=text(0,0,str,'fontsize',10,'horizontalalignment','right',...
        'verticalalignment','cap','units','pixels');
    
    % Some formatting
    set(gca,'fontsize',10,'linewidth',1);    
end

% Apply graphical updates
drawnow;

% Analog channel panel slider
hAslider = uicontrol('parent',hpA,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll');
hAslider.Max=0;
hAslider.Value=0;
hAslider.Callback=@AsliderCB;
hAslider.SliderStep=[0.05 .1];

% Callback for when the slider bar moves
    function AsliderCB(~,~)        
        for nn=1:length(axs)
            pos=getAxPos(axs{nn},nn);
            axs{nn}.Position(2)=pos(2)-hAslider.Value;
        end        
    end

% Add listener to update it before changing the value
addlistener(hAslider,'Value','PreSet',@AsliderCB);

% Assign a callback when mouse wheel is scrolled over the slider bar
jAScroll = findjobj(hAslider);
jAScroll.MouseWheelMovedCallback = @AscrollStep;

% Callback when the mouse wheel is scrolled over the slider bar
    function AscrollStep(~,b)   
        % Scroll wheel information is a string; process it
        c=char(b);
        qStr='wheelRotation=';
        try
        % Get scroll wheel direction
            ind=strfind(c,qStr)+length(qStr);
            N=hAslider.Value;
            dN=(hAslider.Max-hAslider.Min)/20;            
            if isequal(c(ind),'1') 
                % Scrolling down
               hAslider.Value=max([hAslider.Min N-dN]);
            else 
               hAslider.Value=min([hAslider.Max N+dN]);
            end
        catch
            warning('Bad scroll bar');
        end
    end

%% Digital channels panel
hText=20;

% digital channels window pane
hpD=uipanel('parent',hF,'units','pixels','Title','Digital',...
    'backgroundcolor','w');

% Axis for digital channel data
axD=axes('parent',hpD,'units','pixels','box','on','linewidth',1,...
    'YTick',hText*(-length(dTracesSHOW):0),'YGrid','On','YTickLabel',{},...
    'GridAlpha',1);
xlabel('time (ms)');
co=get(gca,'colororder');

% Plot digital channel data
for i=1:length(dTracesSHOW)
    % Process data for this digital channel
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
    
    % Sort the data
    [~,inds]=sort(X);
    X=X(inds);
    Y=Y(inds);

    % Plot the data as series of rectangles
    for np=1:(length(X)-1)
        p=[1E-3*X(np) -i*hText 1E-3*(X(np+1)-X(np)) hText];        
        if Y(np)
            rectangle('Position',p,'linestyle','none',...
                'facecolor',[co(mod(i-1,7)+1,:) .5]);
        end        
    end
    
    % Plot a gray box to indicate unused
    if isempty(X)
        p=[0 -i*hText 1E6 hText];        

        rectangle('Position',p,'linestyle','none',...
                'facecolor',[.5 .5 .5]);
    end
    
    hold on
    xlim(times*1E-3);
end

% Axis for digital channel labels
axDL=axes('parent',hpD,'units','pixels','box','on','linewidth',1,...
    'fontname','monospaced','XTick',[],'YTick',[]);
xlim([0 1]);
co=get(gca,'colororder');

% Plot rectangles and text objects
for i=1:length(dTracesSHOW)
    rectangle('Position',[0 -i*hText 1 1*hText],...
        'facecolor',[co(mod(i-1,7)+1,:) 0.5])
    text(.5,-(i-.5)*hText,dTracesSHOW(i).name,...
        'HorizontalAlignment','center','fontsize',10,'clipping','on',...
        'units','data','verticalalignment','middle');
end

% Disable interactivity with this axis because it's only a label
disableDefaultInteractivity(axDL)
setAxesZoomConstraint(hZ,axD,'x')

% Digital channel panel slider
hDslider = uicontrol('parent',hpD,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll');
hDslider.Max=0;
hDslider.Value=0;
hDslider.Callback=@DsliderCB;
hDslider.SliderStep=[0.05 .1];
hDslider.Min=-length(dTracesSHOW);
hDslider.Max=0;

% Callback for when the slider bar moves
    function DsliderCB(~,~)        
        axDL.YLim=[-axDL.Position(4) 0]+hDslider.Value;        
        axD.YLim=axDL.YLim;     
    end

% Add listener to update it before changing the value
addlistener(hDslider,'Value','PreSet',@DsliderCB);

% Assign a callback when mouse wheel is scrolled over the slider bar
jDScroll = findjobj(hDslider);
jDScroll.MouseWheelMovedCallback = @DscrollStep;

% Callback when the mouse wheel is scrolled over the slider bar
    function DscrollStep(~,b)   
        % Scroll wheel information is a string; process it
        c=char(b);
        qStr='wheelRotation=';
        try
        % Get scroll wheel direction
            ind=strfind(c,qStr)+length(qStr);
            N=hDslider.Value;
            dN=(hDslider.Max-hDslider.Min)/20;            
            if isequal(c(ind),'1') 
                % Scrolling down
               hDslider.Value=max([hDslider.Min N-dN]);
            else 
               hDslider.Value=min([hDslider.Max N+dN]);
            end
        catch
            warning('Bad scroll bar');
        end
    end

%% Finish
% Link the x-axis of digital and analog plots
linkaxes([axs{:} axD],'x');

% Link the y-axis of the digital text labels
linkaxes([axDL axD],'y');

chFigSize;

end

