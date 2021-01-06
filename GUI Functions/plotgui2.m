function foo=plotgui2(sdata)
global seqdata
aTracesShow=struct('Axis',{},'Plot',{},'Label',{});
dTracesShow=struct('Plot',{},'Label',{});


funcname='@Load_MagTrap_sequence';       

if nargin==1
    seqdata=sdata;
    [aTraces, dTraces]=generateTraces(sdata);    
end

%% Initialize figure
dCh=seqdata.digchannels;
aCh=seqdata.analogchannels;

hF=figure('menubar','none','color','w','toolbar','figure',...
    'NumberTitle','off','name','PlotGUI');
hF.Position(1:4)=[100 100 500 800];
hF.AutoResizeChildren='off';
set(hF,'WindowState','maximized');
clf

%%%%%%%%%%%%%%%%%%%%%%%%%% UI MENU %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create menu bars
m1=uimenu('text','File');   % Setting menu
m2=uimenu('text','Digital');    % Digital channel menu
m3=uimenu('text','Analog');     % Analog Channel menu

% Setting sub menu
% uimenu(m1,'text','Auto Update','checked','on');
mRun=uimenu(m1,'text',['Run ' funcname ' and update'],...
    'callback',@runupdate);
mUpdate=uimenu(m1,'text','Update Plots',...
    'callback',@update);
uimenu(m1,'text','Change Sequence File','callback',@chfile);
drawnow;

foo=@update;

    function runupdate(~,~)
        % Reinitialize the sequence
        start_new_sequence;
        seqdata.scancycle=1;      
        seqdata.randcyclelist=0;    
        seqdata.doscan=0;    
        initialize_channels;        

        
        fh = str2func(erase(funcname,'@'));       
        fh(0);               
        updatePlots;
    end

    function update(~,~)
       updatePlots; 
    end

    function chfile(~,~)       
        dirName=['Sequence Files' filesep 'Core Sequences'];
        % The directory of the root
        path = fileparts(fileparts(mfilename('fullpath')));
        defname=[path filesep dirName];
        fstr='Select a sequence file to use...';
        [file,~] = uigetfile('*.m',fstr,defname);          
        if ~file
            disp([datestr(now,13) ' Cancelling'])
            return;
        end        
        funcname=['@' erase(file,'.m')];        
        mRun.Text=['Update traces with ' funcname];
    end


% Get java menu
jFrame = get(handle(hF),'JavaFrame');
jMenuBar = jFrame.fHG2Client.getMenuBar;
jMenuD = jMenuBar.getComponent(1);          % Digital channel menu
jMenuA = jMenuBar.getComponent(2);          % Analog channel menu


% Populate digital channel submenus
for ll=1:ceil(length(dCh)/20)
    str=['d' num2str((ll-1)*20+1,'%02.f') '-' 'd' num2str(ll*20,'%02.f') ];
    mD(ll)=uimenu(m2,'text',str);
    for ii=1:20
        ind=(ll-1)*20+ii;        
        if ind<length(dCh)
            tstr=['d' num2str(dCh(ind).channel,'%02.f') ' ' dCh(ind).name];
            uimenu(mD(ll),'text',tstr,'callback',...
                {@addDigitalChannelW,[ll dCh(ind).channel]}); 
        end
    end    
end

% Populate analog channel submenus
for ll=1:ceil(length(aCh)/20)
    str=['a' num2str((ll-1)*20+1,'%02.f') '-' 'a' num2str(ll*20,'%02.f') ];
    mA(ll)=uimenu(m3,'text',str);
    for ii=1:20
        ind=(ll-1)*20+ii;        
        if ind<length(aCh)
            tstr=['a' num2str(aCh(ind).channel,'%02.f') ' ' aCh(ind).name];
            uimenu(mA(ll),'text',tstr,...
                'callback',{@addAnalogChannelW,[ll aCh(ind).channel]}); 
        end
    end    
end

% Analog channel wrapper callback function
    function addAnalogChannelW(m,~,v)
        if isequal(m.Checked,'off')
            m.Checked='on';
            ch=v(2);
            addAnalogChannel(ch);
        else
            m.Checked='off';
            ch=v(2);
            removeAnalogChannel(ch);
        end
        jMenuA.getMenuComponent(v(1)-1).doClick;
    end

% Digital channel wrapper callback function
    function addDigitalChannelW(m,~,v)
        if isequal(m.Checked,'off')
            m.Checked='on';
            ch=v(2);
            addDigitalChannel(ch);
        else
            m.Checked='off';
            ch=v(2);
            removeDigitalChannel(ch);
        end
        jMenuD.getMenuComponent(v(1)-1).doClick;
    end


%%%%%%%%%%%%%%%%%%%%% WHAT OBJECTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hZ=zoom(hF);

% Assign callbacks to zoom function.  This only works if you had clicked on
% the zoom function and there doesn't work very well at this moment
hZ.ActionPreCallback=@chZoomPre;
hZ.ActionPostCallback=@chZoomPost;

    function chZoomPre(~,obj)
        ax=obj.Axes;            
        htbl_time.Data=ax.XLim;
    end
    function chZoomPost(~,obj)
        ax=obj.Axes;            
        htbl_time.Data=ax.XLim;
    end

% Add a left hand slider to control the relative size of the analog and
% digital channels
warning off % supress the warnings that JAVACOMPONENT is going to be removed
% I like this slider and matlab has shitty default sliders.
jSlider = javax.swing.JSlider;
[jhSlider, hContainer]=javacomponent(jSlider,[0,60,15,hF.Position(4)-30]);
set(jSlider, 'Value',30, 'PaintLabels',false, 'PaintTicks',true,...
    'Orientation',1);  % with ticks, no labels
set(jSlider, 'StateChangedCallback', @adjustSize);  %alternative
warning on


% Figure change sizes callback; this is the main callback function
    function adjustSize(~,~)
        % The time table size; (it doesn't change size)
        h=htbl_time.Extent(4);
        
        % Get slider size
        pS=get(hContainer,'Position');
        val=get(jSlider,'Value');
        pD=val/100;
        pA=1-pD;
        
        % Get the main GUI figure size modulo settings size
        W=hF.Position(3)-pS(3);
        H=hF.Position(4)-h;    
        
        if W <200 || H < 100
           warning(['Your making the figure too small to ' ...
               'render the graphics! Bad grad student.']); 
           return
        end
        
        % Set the size of the analog panel               
        hpA.Position(3:4)=[W H*pA];
        hpA.Position(1:2)=[pS(3) h+H*pD];               
          
        % Set the position and properties of the scrollbar
        if pA*H<50 || isempty(aTracesShow)
            % No slider bar to draw
            hAslider.Visible='off';
            hAslider.Value=0;
        else
            % Set the position of the analog scroll bar                
            hAslider.OuterPosition(3:4)=[20 hpA.Position(4)-10];
            hAslider.Position(1:2)=[hpA.Position(3)-hAslider.Position(3) 0];   
            
            % Calculate the range of the scroll bar
            minVal=-(aTracesShow(1).Axis.Position(2)-aTracesShow(end).Axis.Position(2)-...
                hpA.Position(4)+200);               
          
            if minVal>=0
                % No scroll bar to plot since the panel is large enough
                hAslider.Visible='off';
                hAslider.Value=0;
            else
                % Visible scroll bar; check the limits to be good
                hAslider.Visible='on';
                hAslider.Value=max([minVal hAslider.Value]);
                hAslider.Min=minVal;  
            end      
        end        
        
        % Assign new positions to analog channel traces
        for nn=1:length(aTracesShow)
            pos=getAxPos(hpA,nn);
            aTracesShow(nn).Axis.Position=pos;
            aTracesShow(nn).Axis.Position(2)=pos(2)-hAslider.Value;
        end        
      
        % Set the size of the digital panel
        hpD.Position(3:4)=[W H*pD];
        hpD.Position(1:2)=[pS(3) h];  
                
        if H*pD>75        
            % Set the position of the digital scroll bar            
            hDslider.OuterPosition(3:4)=[20 hpD.Position(4)-10];            
            hDslider.Position(1:2)=[hpD.Position(3)-hDslider.Position(3) 0];     
            
            % Update digital axis position
            t=getAxPos(hpD,1);
            axD.Position(1)=t(1);
            axD.Position(3)=t(3);
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
            
            % Make Visible
            hDslider.Visible='on';
            axDL.Visible='on';
        else
            axD.Position(1)=aTracesShow(1).Axis.Position(1);
            axD.Position(3)=aTracesShow(1).Axis.Position(3);
            hDslider.Visible='off';
            axDL.Visible='off';
            axD.Position(4)=30;           
        end        
        
        % Left scroll bar position
        pp=[0,htbl_time.Extent(4),15,hF.Position(4)-htbl_time.Extent(4)];
        set(hContainer,'position',pp); %note container size change
              
        % Apply graphical updates
        drawnow;
    end

% Calculate the analog axis position
    function pos=getAxPos(prnt,ind)    
        % [left, right, bottom, top] boundaries between figure
        B=[150 40 50 50];        
        B(3)=0; % manually set the bottom boundary

        % vertical separation between axes
        dY=30;dY=25;
        nR=4; 

        % axes width
        w=prnt.Position(3)-B(1)-B(2);
        
        % axis height using the desired number of plots to show
        h=(prnt.Position(4)-B(3)-B(4)-dY*(nR-1))/nR;
        
        % manually set the pixel height of each axis
        h=100;

        % assemble the entire calcualted position vector
        pos=[B(1) prnt.Position(4)-B(4)-ind*h-(ind-1)*dY w h];
    end


%% Settings 

% Time limits table
htbl_time=uitable('parent',hF);
htbl_time.ColumnName={'start (ms)','end (ms)'};
htbl_time.RowName={};
htbl_time.ColumnEditable=[true true];
htbl_time.ColumnFormat={'numeric','numeric'};
htbl_time.Data=[0 50]*1E3;
htbl_time.ColumnWidth={120 120 120};
htbl_time.Position(3:4)=htbl_time.Extent(3:4);
htbl_time.Position(1:2)=[0 0];
htbl_time.CellEditCallback=@tblCB;

% Add listener to update it before changing the value
    function beep(~,~)
       htbl_time.Data=1E3*axD.XLim; 
    end

% Callback for editing the time table
    function tblCB(tbl,data)

        % Check if data is properly formatted
        if isnan(data.NewData) & isnumeric(data.NewData)
            disp([datestr(now,13) ' You inputted a non-numerical input' ...
                ' to the limits of the plot. Shameful']);
            tbl.Data(data.Indices(2))=data.PreviousData;
            return;
        end      
        
        % Make sure limits are in ascending order
        if tbl.Data(2)<tbl.Data(1) 
            disp([datestr(now,13) ' Wow, you colossal buffoon,' ...
                ' plot limits must in increasing order. Shameful']);
           tbl.Data(data.Indices(2))=data.PreviousData;
            return;
        end
        
        % Check that data is actually different
        if isequal(data.NewData,data.PreviousData)
            return;
        end          
        
        % Change the plot limits
        disp([datestr(now,13) ' Changing the plot limits.']);  
        for n=1:length(aTracesShow)
           aTracesShow(n).Axis.XLim=tbl.Data(1:2)*1E-3;
        end  
       axD.XLim=tbl.Data(1:2)*1E-3;

    end      

%% Analog Channels panel
% analog channels window pane
hpA=uipanel('parent',hF,'units','pixels','Title','Analog',...
    'backgroundcolor',hF.Color);
hpA.Position(3:4)=[hF.Position(3)-15 hF.Position(4)*.6];
hpA.Position(1:2)=[15 hF.Position(4)*(.4)];

axs={};

% Apply graphical updates
drawnow;

% Analog channel panel slider
hAslider = uicontrol('parent',hpA,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0,'Callback',...
    @AsliderCB,'SliderStep',[0.05 .1]);

% Callback for when the slider bar moves
    function AsliderCB(~,~)        
        for n=1:length(aTracesShow)
            pos=getAxPos(hpA,n);
            aTracesShow(n).Axis.Position(2)=pos(2)-hAslider.Value;
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
% Digital channels window pane
hpD=uipanel('parent',hF,'units','pixels','Title','Digital',...
    'backgroundcolor',hF.Color);

% Axis for digital channel data
axD=axes('parent',hpD,'units','pixels','box','on','linewidth',1,'YGrid',...
    'On','YTickLabel',{},'GridAlpha',1,'fontsize',10,'XLim',htbl_time.Data*1E-3);
xlabel('time (s)');
co=get(gca,'colororder');
hold on

% Axis for digital channel labels
axDL=axes('parent',hpD,'units','pixels','box','on','linewidth',1,...
    'fontname','monospaced','XTick',[],'YTick',[],'XLim',[0 1]);

% Disable interactivity with this axis because it's only a label
disableDefaultInteractivity(axDL)
setAxesZoomConstraint(hZ,axD,'x')

% Digital channel panel slider
hDslider = uicontrol('parent',hpD,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0,...
    'SliderStep',[0.05 .1],'Callback',@DsliderCB);

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

% Link the time limits to a table
addlistener(axD,'XLim','PostSet',@beep);

hF.SizeChangedFcn=@adjustSize;

adjustSize;

%%

function updatePlots
    [aTraces, dTraces]=generateTraces(seqdata);
    for nn=1:length(aTracesShow)
       in=find(aTracesShow(nn).channel==[aTraces.channel],1);
       aTracesShow(nn).data=aTraces(in).data;
    end
    
    for nn=1:length(dTracesShow)
       in=find(dTracesShow(nn).channel==[dTraces.channel],1);
       dTracesShow(nn).data=dTraces(in).data;
    end

    for nn=1:length(aTracesShow)
        
        X=aTracesShow(nn).data(:,1)*seqdata.deltat;     % Time data (seconds)
        Y=aTracesShow(nn).data(:,2);                    % Y Data

        % Add t=0 and t=infty values
        if ~isempty(X)
            X=[0; X; 500];Y=[Y(end); Y; Y(end)]; 
        end   
        
        set(aTracesShow(nn).Plot,'XData',X,'YData',Y);
    end
    drawnow;
    
    for j=1:length(dTracesShow)
        % Delete old digital plots
        pps=dTracesShow.Plot;
        for in=1:length(pps)
           delete(pps(in)); 
        end
        
        % Grab the trace
        X=dTracesShow(j).data(:,1)*seqdata.deltat;     % Time data
        Y=dTracesShow(j).data(:,2);                    % Y data

        % Add t=0 and t=infty values
        if ~isempty(X)
            X=[0; X; 500]; Y=[Y(end); Y; Y(end)]; 
        end

        % Sort the data
        [~,inds]=sort(X);
        X=X(inds);
        Y=Y(inds);

        axes(axD);
        hold on

        % Plot the data as series of rectangles
        s=1;
        for np=1:(length(X)-1)
            p=[X(np) -j*hText (X(np+1)-X(np)) hText];        
            if Y(np)
                r=rectangle('Position',p,'linestyle','-',...
                    'facecolor',[co(mod(j-1,7)+1,:) .5],'linewidth',.5,...
                    'EdgeColor',[co(mod(j-1,7)+1,:)]);
                pps(s)=r;s=s+1;
            end        
        end

        if ~exist('pps')
            pps=[];
        end

        % Plot a gray box to indicate unused
        if isempty(X)
            p=[0 -j*hText 1E6 hText]; 
            rectangle('Position',p,'linestyle','none','facecolor',[.5 .5 .5]);
        end    
        hold on
        
        dTracesShow(j).Plot=pps;
    end

end

function addAnalogChannel(ch)        
    % Create the new axis
    j=length(aTracesShow)+1;
    ax=axes('parent',hpA,'units','pixels');
    ax.Position=getAxPos(hpA,j); 

    % Grab the trace
    n=find(ch==[aTraces.channel],1);    % Find the analog channel
    trc=aTraces(n);                     % Get the trace
    X=trc.data(:,1)*seqdata.deltat;     % Time data (seconds)
    Y=trc.data(:,2);                    % Y Data

    % Add t=0 and t=infty values
    if ~isempty(X)
        X=[0; X; 500];Y=[Y(end); Y; Y(end)]; 
    end    

    % Plot the data; stairs interpolates the digital write calls
    p=stairs(X,Y,'color',co(1,:),'linewidth',2);
    p.Color='k';
    p.Color=[co(mod(j-1,7)+1,:) .5];
    % Channel text label
    str=['a' num2str(trc.channel,'%02.f') newline trc.name];
    tt=text(0,0,str,'fontsize',12,'horizontalalignment','left',...
        'verticalalignment','top','units','pixels',...
        'fontname','monospaced','fontweight','bold','Color',p.Color);       
    tt.Position(1)=15-ax.Position(1);
    tt.Position(2)=ax.Position(4);

    set(gca,'fontsize',10,'linewidth',1,'xaxislocation','top',...
        'XLim',htbl_time.Data*1E-3); 
    
    % Track graphical objects
    trc.Axis=ax;                     
    trc.Label=tt;
    trc.Plot=p;
    % Add trace
    if ~isempty(aTracesShow)
        aTracesShow(end+1)=trc;          % Add the trace
    else
        aTracesShow=trc;
    end
    adjustSize;    
end

function removeAnalogChannel(ch)
    n=find(ch==[aTracesShow.channel],1);
    delete(aTracesShow(n).Axis);
    aTracesShow(n)=[];           
    for n=1:length(aTracesShow)
        c=co(mod(n-1,7)+1,:);
%         c='k';
        aTracesShow(n).Axis.Position=getAxPos(hpA,n);
        aTracesShow(n).Plot.Color=c; 
        aTracesShow(n).Label.Color=c; 
    end
    adjustSize
end
    hText=20;
function addDigitalChannel(ch)
    j=length(dTracesShow)+1;

    % Grab the trace
    n=find(ch==[dTraces.channel],1);    % Find the analog channel
    trc=dTraces(n);                     % Get the trace
    
    X=trc.data(:,1)*seqdata.deltat;     % Time data
    Y=trc.data(:,2);                    % Y data
    
    % Add t=0 and t=infty values
    if ~isempty(X)
        X=[0; X; 500]; Y=[Y(end); Y; Y(end)]; 
    end
    
    % Sort the data
    [~,inds]=sort(X);
    X=X(inds);
    Y=Y(inds);
    
    axes(axD);
    hold on

    
    % Plot the data as series of rectangles
    s=1;
    for np=1:(length(X)-1)
        p=[X(np) -j*hText (X(np+1)-X(np)) hText];        
        if Y(np)
            r=rectangle('Position',p,'linestyle','-',...
                'facecolor',[co(mod(j-1,7)+1,:) .5],'linewidth',.5,...
                'EdgeColor',[co(mod(j-1,7)+1,:)]);
            pps(s)=r;s=s+1;
        end        
    end
    
    if ~exist('pps')
        pps=[];
    end
    
    % Plot a gray box to indicate unused
    if isempty(X)
        p=[0 -j*hText 1E6 hText]; 
        rectangle('Position',p,'linestyle','none','facecolor',[.5 .5 .5]);
    end    
    hold on
    
    
    axes(axDL)
    rectangle('Position',[0 -j*hText 1 1*hText],...
        'facecolor',[co(mod(j-1,7)+1,:) 0.5])
    tstr=[' d' num2str(trc.channel,'%02.f') ' ' trc.name];
    tt=text(0,-(j-.5)*hText,tstr,...
        'HorizontalAlignment','left','fontsize',8,'clipping','on',...
        'units','data','verticalalignment','middle','fontname','monospaced',...
        'fontweight','bold');
    
    
    % Track graphical objects
    trc.Label=tt;
    trc.Plot=pps;
    
    % Add trace
    if ~isempty(dTracesShow)
        dTracesShow(end+1)=trc;          % Add the trace
    else
        dTracesShow=trc;
    end
    
    axD.YTick=flip([0:1:length(dTracesShow)])*-hText;
    
end

function removeDigitalChannel(ch)
    n=find(ch==[dTracesShow.channel],1);
    for kk=1:length(dTracesShow(n).Plot)
        delete(dTracesShow(n).Plot(kk));
    end
    delete(dTracesShow(n).Label); 
    dTracesShow(n)=[];   

    for n=1:length(dTracesShow)
        c=co(mod(n-1,7)+1,:);
        dTracesShow(n).Label.Color=c; 

        for kk=1:length(dTracesShow(n).Plot)
            p=dTracesShow(n).Plot(kk);
            p.FaceColor=c;
            p.Position(2)=-n*hText;
        end
    end
    axD.YTick=flip([0:1:length(dTracesShow)])*-hText;

end


end

