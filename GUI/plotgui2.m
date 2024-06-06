function foo=plotgui2(sdata)
foo=@update;
global seqdata

% Settings
funcname='@main_sequence';       
hText=20;
Tseq=0;

% Initialize data structures
aTracesShow=struct('Axis',{},'Plot',{},'Label',{},'SelecUnit',{});
dTracesShow=struct('Plot',{},'Label',{});

% Initialize seqdata and traces if possible
switch nargin
    case 1
        seqdata=sdata;
        [aTraces, dTraces]=generateTraces(sdata); 
        
        Tseq=getSequenceDuration;
    case 0
        if isfield(seqdata,'analogchannels') && ...
                ~isempty([seqdata.analogchannels]) && ...
                isfield(seqdata,'analogadwinlist') && ...
                ~isempty([seqdata.analogadwinlist])
            [aTraces, dTraces]=generateTraces(seqdata); 
            Tseq=getSequenceDuration;
            
        end
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
m1=uimenu('text','File');       % File menu
m2=uimenu('text','Digital');    % Digital channel menu
m3=uimenu('text','Analog');     % Analog Channel menu
m4=uimenu('text','Pre-sets');   % Shortcuts to saved traces

% Setting sub menu
% mRun=uimenu(m1,'text',['Compile ' funcname ' and update'],...
%     'callback',@recompile);
mUpdate=uimenu(m1,'text','Update Plots','callback',@update);
% uimenu(m1,'text','Change Sequence File','callback',@chfile);
drawnow;

    function tend=getSequenceDuration
        tend=max([max(seqdata.analogadwinlist(:,1)) max(seqdata.digadwinlist(:,1))]);
        tend=seqdata.deltat*tend;
        htbl_time.Data(4)=Tseq*1E3;
    end

% Recompile sequence and update plots
%     function recompile(~,~)
%         try        
%             start_new_sequence;             % Initialize sequence
%             seqdata.scancycle=1;            % 
% %             seqdata.randcyclelist=0;    
%             seqdata.doscan=0;    
%             initialize_channels;            % Initialize channels
%             fh = str2func(erase(funcname,'@'));       % Grab the sequence func
%             fh(0);                          % Run the sequence / update seqdata  
%             Tseq=getSequenceDuration;
%             
%             calc_sequence;                  % convert seqdata for AdWin  
% 
%             
%             refreshPlotData;                % Update plots and graphics 
% 
%         catch ME
%             warning('Error on sequence compilation');
%             warning(ME.message);
%             disp(' ');
%             for kk=length(ME.stack):-1:1
%                disp(['  ' ME.stack(kk).name ' (' num2str(ME.stack(kk).line) ')']);
%             end
%             disp(' ');  
%         end
% 
%     end

    function update(~,~)
        Tseq=getSequenceDuration;        
        refreshPlotData; 
    end

% % Call to change the sequence file
%     function chfile(~,~)       
%         dirName=['Sequence Files' filesep 'Core Sequences'];
%         % The directory of the root
%         path = fileparts(fileparts(mfilename('fullpath')));
%         defname=[path filesep dirName];
%         fstr='Select a sequence file to use...';
%         [file,~] = uigetfile('*.m',fstr,defname);          
%         if ~file
%             disp([datestr(now,13) ' Cancelling']);
%             return;
%         end        
%         funcname=['@' erase(file,'.m')];        
%         mRun.Text=['Update traces with ' funcname];
%     end

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
        if ind<=length(dCh)
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
        if ind<=length(aCh)

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
        htbl_time.Data(1:2)=ax.XLim;
        htbl_time.Data(3) = htbl_time.Data(2) - htbl_time.Data(1);
    end
    function chZoomPost(~,obj)
        ax=obj.Axes;            
        htbl_time.Data(1:2)=ax.XLim;
        htbl_time.Data(3) = htbl_time.Data(2) - htbl_time.Data(1);
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


% Figure change sizes callback
    function adjustSize(~,~)                        
        h=htbl_time.Extent(4);          % Time table height  
        pS=get(hContainer,'Position');  % Slider adjust width
        
        W=hF.Position(3)-pS(3);         % GUI width less slider width
        H=hF.Position(4)-h;             % GUI height less table height
        
        % Exit if you are resizing inappropriately
        if W <200 || H < 100
           warning(['Your making the figure too small to ' ...
               'render the graphics! Bad grad student.']); 
           return
        end
        
        % Slider position that sets analog vs digital relative size
        val=get(jSlider,'Value');
        pD=val/100;pA=1-pD;       
        
        % Resize the analog and digital panels to the slider values 
        hpA.Position=[pS(3) h+H*pD W H*pA];        
        hpD.Position=[pS(3) h W H*pD];             
        
        resizeAObj;     % Resize children of analog panel
        resizeDObj;     % Resize children of digital panel           
        
        % Left scroll bar position
        pp=[0,htbl_time.Extent(4),15,hF.Position(4)-htbl_time.Extent(4)];
        set(hContainer,'position',pp); %note container size change
              
        % Apply graphical updates
        drawnow;
    end

    function resizeAObj           
        % Adjust the analog panel scroll bar
        if hpA.Position(4)<50 || isempty(aTracesShow)
            % No slider bar to draw
            hAslider.Visible='off';
            hAslider.Value=0;
        else
            % Set the position of the analog scroll bar                
            hAslider.OuterPosition(3:4)=[20 hpA.Position(4)-10];
            hAslider.Position(1:2)=[hpA.Position(3)-hAslider.Position(3) 0];   
            
            % Calculate the range of the scroll bar
            minVal=-(aTracesShow(1).Axis.Position(2)-...
                aTracesShow(end).Axis.Position(2)-hpA.Position(4)+200);              
          
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
        
        % Resize analog plots to fit within panel
        for nn=1:length(aTracesShow)
            pos=getAxPos(hpA,nn);pxY=hAslider.Value;
            aTracesShow(nn).Axis.Position=pos;
            aTracesShow(nn).Axis.Position(2)=pos(2)-pxY;     
            aTracesShow(nn).SelectUnit.Position(2) = pos(2)-pxY;            
            aTracesShow(nn).YLimTbl.Position(2) = pos(2)+25-pxY;
            aTracesShow(nn).YLimCheck.Position(2) = pos(2)+50-pxY;            
        end   
    end

    function resizeDObj        
        % Adjust digital axis size to panel
        t=getAxPos(hpD,1);
        axD.Position(1)=t(1);
        axD.Position(3)=t(3);

        % Adjust digital label axis size to panel
        axDL.Position=axD.Position;
        axDL.Position(1)=5;
        axDL.Position(3)=axD.Position(1)-axDL.Position(1);
        
        % Top gap between digital panel and axis
        tgap=18;

        % Adjust size of axes and scroll bar
        if hpD.Position(4)<75 || isempty(dTracesShow) % If too small or nothing to show            
            hDslider.Visible='off';
            axDL.Visible='off';
            axD.Visible='off';
        else
             % Set the position of the digital scroll bar            
            hDslider.OuterPosition(3:4)=[20 hpD.Position(4)-10];            
            hDslider.Position(1:2)=[hpD.Position(3)-hDslider.Position(3) 0];     
            
            % Height to capture all digital traces
            h1=length(dTracesShow)*hText;
            % Max height the panel can accomondate            
            h2=hpD.Position(4)-tgap-50;

            % Set digital axis vertical size and position
            axD.Position(4)=min([h1 h2]);
            axD.Position(2)=hpD.Position(4)-axD.Position(4)-tgap;
            % Match digital axis label axis
            axDL.Position(4)=axD.Position(4);
            axDL.Position(2)=axD.Position(2);
                       
            % Reset the digital axis limits
            axDL.YLim=[-axDL.Position(4) 0];        
            axD.YLim=axDL.YLim;
            
            if h1<h2
                hDslider.Visible='off'; 
            else
                hDslider.Visible='on';
                hDslider.Max=0;
                hDslider.Min=h2-h1;
                hDslider.SliderStep=[.05 .1];
            end
            
            % Make Visible
            axDL.Visible='on';
            axD.Visible='on';
        end
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
htbl_time=uitable('parent',hF,'RowName',{},'ColumnEditable',[true true true false],...
    'ColumnFormat',{'numeric','numeric','numeric','numeric'},...
    'ColumnWidth',{80 80 80 80},...
    'ColumnName',{'start (ms)','end (ms)', 'span (ms)', 'total (ms)'},'Data',[0 50000 50000 0],...
    'CellEditCallback',@tblCB);
htbl_time.Position(3:4)=htbl_time.Extent(3:4);
htbl_time.Position(1:2)=[0 0];

% Add listener to update it before changing the value
    function beep(~,~)
       htbl_time.Data(1:2)=1E3*axD.XLim; 
       htbl_time.Data(3)=range(htbl_time.Data(1:2));     
       
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
        
        % If you switch the start or end point      
        if data.Indices(2)==1 || data.Indices(2)==2        
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
        end
        
        % If you change the span
        if data.Indices(2)==3
            % Make sure span is positive
            if tbl.Data(3)<=0
               disp([datestr(now,13) ' Wow, you colossal buffon,' ...
                   ' x limit span must be positive. Dummy']);
               tbl.Data(data.Indices(2))=data.PreviousData;
               return;
            end
            
            % Change span about center
            xC=mean(tbl.Data(1:2));
            tbl.Data(1:2)=xC+[-.5 .5]*tbl.Data(3);
            
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
            aTracesShow(n).SelectUnit.Position(2)=pos(2)-hAslider.Value;
            aTracesShow(n).YLimTbl.Position(2) = pos(2)+25-hAslider.Value;
            aTracesShow(n).YLimCheck.Position(2) = pos(2)+50-hAslider.Value;  
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
    'On','YTickLabel',{},'GridAlpha',1,'fontsize',10,'XLim',htbl_time.Data(1:2)*1E-3);
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

% Link the y-axis of the digital text labels
linkaxes([axDL axD],'y');

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

% Link the time limits to a table
addlistener(axD,'XLim','PostSet',@beep);

hF.SizeChangedFcn=@adjustSize;

adjustSize;

%%

% Grab the new sequenece information from seqdata and update graphical
% objects.
function refreshPlotData
    % Update all channels data
    [aTraces, dTraces]=generateTraces(seqdata); % Get traces
    Tseq=getSequenceDuration;                   % Sequence time
    
    % Update analog data for shown channels
    for nn=1:length(aTracesShow)
       in=find(aTracesShow(nn).channel==[aTraces.channel],1);
       aTracesShow(nn).data=aTraces(in).data;
    end 
    
    % Update digital data for shown channels
    for nn=1:length(dTracesShow)
       in=find(dTracesShow(nn).channel==[dTraces.channel],1);
       dTracesShow(nn).data=dTraces(in).data;
    end

    % Update the analog graphical object with new data
    for nn=1:length(aTracesShow)        
        funcnum=aTracesShow(nn).SelectUnit.Value;
        [X,Y,funcnum]=getAnalogValue(aTracesShow(nn),funcnum);
        aTracesShow(nn).SelectUnit.Value=funcnum;  
        set(aTracesShow(nn).Plot,'XData',X,'YData',Y);
    end
    
    
    for nn=1:length(dTracesShow)        
        % Grab the trace
        trc=dTracesShow(nn);                     % Get the trace

        X=trc.data(:,1)*seqdata.deltat;     % Time data
        Y=trc.data(:,2);                    % Y data
 
        if ~isempty(X)      
            j=dTracesShow(nn).pFill.UserData; % the offset
            
            % Append begining and end data
            X=[0; X; Tseq]; 
            Y=[Y(end); Y; Y(end)]; 

            % Sort the data
            [~,inds]=sort(X);
            X=X(inds);
            Y=Y(inds);

            % Convert data to row vector
            X=X';      
            Y=Y';
            % Normalize and offset Y data for plotting
            Y=(Y-j)*hText;

            % Convert data in vertices for fill
            x = [X(1) ,repelem(X(2:end),2)];
            y = [repelem(Y(1:end-1),2),Y(end)];
            xx=[x,fliplr(x)];
            yy=[y,-j*hText*ones(size(y))];
            
            set(dTracesShow(nn).pFill,'XData',xx,'YData',yy);
        else
            set(dTracesShow(nn).pFill,'XData',[],'YData',[]);         
        end
    end
  
    
    drawnow;
end

% Get the time and value for an analog channel 
function [X,Y,funcnum] = getAnalogValue(trc,funcnum)
% This a very experimental piece of code, which attempts to invert our
% voltage fucntion writes to determine what the original parameter we
% wanted to write was.  This is kinda stupid because it basically inverts
% our calibration data, but is required because we don't sensibly save the
% calibration. Ie. We store voltage = f(parameter), but this doesn't easily
% give parameter = g(voltage).
%
% This code does the inversion operation numerically by interpolation
    
    % Grab the raw data
    X=trc.data(:,1)*seqdata.deltat;
    V=trc.data(:,2);   % Voltage output to analog channels    
    
    xNaN=find(isnan(X));    
    if ~isempty(xNaN)
       warning('Found NaN times');
       X(xNaN)=[];
       V(xNaN)=[];
    end
    
    vNaN=find(isnan(V));
    if ~isempty(vNaN)
        warning('Found NaN voltages.');
        X(vNaN)=[];
        V(vNaN)=[];        
    end
    
    if isempty(X) || isempty(V)
        mstr=[trc.name ' has no data to plot'];
        warning(mstr);        
        X=X;
        Y=V;
        return;
    end
    
    
    % Numerically invert
    if nargin~=1 && ~isempty(funcnum) && funcnum~=1        
        try            
            f=trc.voltagefunc{funcnum};     % Calibration V=f(param) 
            v1 = min(V);                    % Lowest voltage written
            v2 = max(V);                    % Maximal voltage written
            
            % Edge case if no change in parameter
            if max(V)==min(V)
                p = fzero(@(x) real(f(x))-V(1),0);  % Find mapping
                Y = (V/V(1))*p;                     % Scale                
            else
                % Find zeroes
                p1 = fzero(@(x) real(f(x))-v1,0);
                p2 = fzero(@(x) real(f(x))-v2,10);

                % Evaluate function over the found paramter domain
                pVec=linspace(p1,p2,1E3);
                vVec=f(pVec);

                % Interpolate the results
                P = interp1(vVec,pVec,V,'linear','extrap');
                Y=P;                
            end
        catch ME
            warning(ME.message);
            warning('Unable to numerically invert');
            Y=V;
            funcnum=1;
        end
    else
        Y=V;
        funcnum=1;
    end
    
    
    % Add endpoints at t=0 and t=ifnity
    X = [0; X; Tseq];    
    Y = [Y(end); Y; Y(end)];   
end

% Callback function for automatic ylimits adjust
    function limCheckCB(cBox,~,ch)
        n=find(ch==[aTracesShow.channel],1);   
        if cBox.Value
            set(aTracesShow(n).Axis,'YLimMode','Auto');
            aTracesShow(n).YLimTbl.Data=aTracesShow(n).Axis.YLim;
            aTracesShow(n).YLimTbl.ColumnEditable=[false false];
        else
            set(aTracesShow(n).Axis,'YLimMode','Manual');
            aTracesShow(n).YLimTbl.ColumnEditable=[true true];
        end
    end

    function boop(~,evt,ch)
        n=find(ch==[aTracesShow.channel],1);   
        
        if aTracesShow(n).YLimCheck.Value
            set(aTracesShow(n).Axis,'YLimMode','Auto');
        else
            set(aTracesShow(n).Axis,'YLimMode','Manual');
        end       
        aTracesShow(n).YLimTbl.Data=evt.AffectedObject.YLim;

    end

    function foob(tbl,data,ch)
        n=find(ch==[aTracesShow.channel],1);   

        % Check if data is properly formatted
        if isnan(data.NewData) && isnumeric(data.NewData)
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
        
        aTracesShow(n).Axis.YLim=tbl.Data;
        

    
    end

function addAnalogChannel(ch)     
    % Create the new axis
    j=length(aTracesShow)+1;
    ax=axes('parent',hpA,'units','pixels');
    ax.Position=getAxPos(hpA,j);     
    hold on
    
    % Color for this object
    c = [co(mod(j-1,7)+1,:) .5];

    % Grab the channel data
    n=find(ch==[aTraces.channel],1);    % Find the analog channel
    trc=aTraces(n);                     % Get the trace
    
    % Generate voltage function strings
    strs={};
    for i=1:length(trc.voltagefunc)
        try 
            fstr=func2str(trc.voltagefunc{i});
        catch exception
            fstr='BAD FUNC';
        end
        strs{i}=['(' num2str(i) ') ' fstr];
    end  
    funcnum = trc.defaultvoltagefunc;
    
    % Grab the data and format by the function
    [X,Y,funcnum]=getAnalogValue(trc,funcnum);  
       
    % Pulldown menu for function
    pu = uicontrol('parent',hpA,'Style','popup','units','pixels',...
        'fontsize',8,'Position',[5 ax.Position(2) 110 20],...
        'String',strs,'Value',funcnum,'Callback',{@chAFun ch});
    
    % YLimit table
    ytbl = uitable('parent',hpA,'units','pixels','RowName',{},...
        'fontsize',8,'ColumnEditable',[false false],...
        'ColumnName',{},'ColumnWidth',{45 45},'Data',[0 1],...
        'Position',[5 pu.Position(2)+25 84 22],...
        'CellEditCallback',{@foob ch});
    ytbl.Position(3:4)=ytbl.Extent(3:4);  

    addlistener(ax,'YLim','PostSet',@(a,b) boop(a,b,ch) );    
    
    % YLimits Automatic adjust checkbox
    ylimc = uicontrol('style','checkbox','parent',hpA,'units',...
        'pixels','string','auto-ylim?','value',1,'fontsize',8,...
        'backgroundcolor','w','CallBack',{@limCheckCB, ch},...
        'Position',[5 ytbl.Position(2)+25 70 15]);
    
    % Channel text label
    mystr=['a' num2str(trc.channel,'%02.f') newline trc.name];
    tt=text(0,0,mystr,'fontsize',12,'horizontalalignment','left',...
        'verticalalignment','cap','units','pixels',...
        'fontname','monospaced','fontweight','bold','Color',c);       
    tt.Position(1)=5-ax.Position(1);
    tt.Position(2)=ax.Position(4);            


    % Plot the data; stairs interpolates the digital write calls
    p=stairs(X,Y,'color',c,'linewidth',2);
    
    % Plot a background color; this is kinda stupid
%     x = [0 Tseq; 0 Tseq; -200 200; -200 200];
%     y = [ax.YLim(1)*[1 1];ax.YLim(2)*[1 1];ax.YLim(2)*[1 1];ax.YLim(1)*[1 1]];    
%     bg=patch(x,y,[.5 .5 .5],'facealpha',.3,'edgecolor','none');


    % Format the axis
    set(gca,'fontsize',10,'linewidth',1,'xaxislocation','top',...
        'XLim',htbl_time.Data(1:2)*1E-3,'box','on');    
    
    ytbl.Data=get(gca,'YLim');
    
    % Track graphical objects
    trc.Axis=ax;                     
    trc.Label=tt;
    trc.Plot=p;
    trc.SelectUnit=pu;
    trc.YLimTbl = ytbl;
    trc.YLimCheck = ylimc;
%     trc.Bkgd = bg;
    
    
    
    
    % Add trace
    if ~isempty(aTracesShow)
        aTracesShow(end+1)=trc;          % Add the trace
    else
        aTracesShow=trc;
    end      
    
    % Change graphics sizes
    adjustSize;    
   
    % Link the x-axis of the analog plot with the digital ones
    linkaxes([aTracesShow.Axis axD],'x');
end

function removeAnalogChannel(ch)
    n=find(ch==[aTracesShow.channel],1);
    delete(aTracesShow(n).Axis);
    delete(aTracesShow(n).SelectUnit);
    delete(aTracesShow(n).YLimTbl);
    delete(aTracesShow(n).YLimCheck);
    
    aTracesShow(n)=[];           
    for n=1:length(aTracesShow)
        c=co(mod(n-1,7)+1,:);
        aTracesShow(n).Axis.Position=getAxPos(hpA,n);
        aTracesShow(n).Plot.Color=c; 
        aTracesShow(n).Label.Color=c;         
    end
    adjustSize;
end

    function chAFun(a,~,ch)
        n=find(ch==[aTracesShow.channel],1);    % Find the analog channel        
        funcnum=a.Value;
        [X,Y,funcnum]=getAnalogValue(aTracesShow(n),funcnum);                
        a.Value=funcnum;
        set(aTracesShow(n).Plot,'XData',X,'YData',Y);
        drawnow;      
    end
      

function addDigitalChannel(ch)
    j=length(dTracesShow)+1;

    % Grab the trace
    n=find(ch==[dTraces.channel],1);    % Find the analog channel
    trc=dTraces(n);                     % Get the trace
    
    X=trc.data(:,1)*seqdata.deltat;     % Time data
    Y=trc.data(:,2);                    % Y data
    
    axes(axD);
    hold on
    
    % Add t=0 and t=end of sequence values
    if ~isempty(X)
        X=[0; X; Tseq]; Y=[Y(end); Y; Y(end)]; 
        
        % Sort the data
        [~,inds]=sort(X);
        X=X(inds);
        Y=Y(inds);
        
        % Convert data to row vector
        X=X';      
        Y=Y';
        % Normalize and offset Y data for plotting
        Y=(Y-j)*hText;
        
        % Convert data in vertices for fill
        x = [X(1) ,repelem(X(2:end),2)];
        y = [repelem(Y(1:end-1),2),Y(end)];
        xx=[x,fliplr(x)];
        yy=[y,-j*hText*ones(size(y))];
        
        % Plot fill with edges
        pFill=fill(xx,yy,'r',...
        'facecolor',co(mod(j-1,7)+1,:),'FaceAlpha',0.5,...
        'edgecolor',co(mod(j-1,7)+1,:),'linewidth',.5,'UserData',j);
        
        % Add plot to traces
        trc.pFill=pFill;
    else
        % Make an empty patch
        pFill=fill([],[],'r','facealpha',0.5,'linewidth',1);
        
        % add plot to traces
        trc.pFill=pFill;
    end  
   
    
    hold on
    
    % Plot the text label rectangle
    axes(axDL)
    pL=rectangle('Position',[0 -j*hText 1 1*hText],...
        'facecolor',[co(mod(j-1,7)+1,:) 0.5]);
    
    % Fill the text label with text
    tstr=[' d' num2str(trc.channel,'%02.f') ' ' trc.name];
    tt=text(0,-(j-.5)*hText,tstr,...
        'HorizontalAlignment','left','fontsize',8,'clipping','on',...
        'units','data','verticalalignment','middle','fontname','monospaced',...
        'fontweight','bold');
        
    % Track graphical objects
    trc.Label=tt;
    trc.LabelPlot=pL;

    % Add trace
    if ~isempty(dTracesShow)
        dTracesShow(end+1)=trc;          % Add the trace
    else
        dTracesShow=trc;
    end
    
    % Add y ticks to help delineate
    axD.YTick=flip([0:1:length(dTracesShow)])*-hText;   
        
    resizeDObj;
end

function removeDigitalChannel(ch)
    % Find the trace to delete
    n=find(ch==[dTracesShow.channel],1);    
    
    % Delete the plots
    delete(dTracesShow(n).pFill);       
    delete(dTracesShow(n).Label); 
    delete(dTracesShow(n).LabelPlot);

    % Remove trace
    dTracesShow(n)=[];   
 
    % For all traces after the deleted, shift the plots
    for jj=n:length(dTracesShow)
        c=co(mod(jj-1,7)+1,:);
        
        dTracesShow(jj).pFill.YData=dTracesShow(jj).pFill.YData+hText;
        dTracesShow(jj).pFill.UserData=dTracesShow(jj).pFill.UserData-1;
        dTracesShow(jj).pFill.FaceColor=c;
        dTracesShow(jj).pFill.EdgeColor=c;

        dTracesShow(jj).LabelPlot.FaceColor=[c .5];
        dTracesShow(jj).LabelPlot.Position(2)=-jj*hText;
        dTracesShow(jj).Label.Position(2)=-(jj-.5)*hText;
    end
    axD.YTick=flip([0:1:length(dTracesShow)])*-hText;
    resizeDObj;
end



end

