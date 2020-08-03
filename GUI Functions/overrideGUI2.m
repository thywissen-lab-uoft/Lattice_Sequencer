function hFGUI=overrideGUI2

% Initialize the sequence data
global seqdata;
start_new_sequence();
initialize_channels();

% Grab the analog and digital channels
Achs=seqdata.analogchannels;
Dchs=seqdata.digchannels;

% Get the color scheme you'd like to use
cc=[0    0.4470    0.7410;
    0.8500    0.3250    0.0980;
    0.9290    0.6940    0.1250;
    0.4940    0.1840    0.5560;
    0.4660    0.6740    0.1880;
    0.3010    0.7450    0.9330;
    0.6350    0.0780    0.1840];
cc=brighten(cc,.6);

% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name','Adwin Override','Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off');
hFGUI.Position(3:4)=[900 600];
hFGUI.Position(2)=50;
hFGUI.WindowScrollWheelFcn=@scroll;

    function scroll(~,b)
        scrll=-b.VerticalScrollCount;
        C=get(gcf,'CurrentPoint');        
        if C(2)<hpMain.Position(4)
            if C(1)<hpMain.Position(3)/2
                newVal=hDsl.Value+scrll*abs(hDsl.Min)*.05;                
                newVal=max([newVal hDsl.Min]);
                newVal=min([newVal hDsl.Max]);
                hDsl.Value=newVal;     
                DsliderCB;
            else
                newVal=hAsl.Value+scrll*abs(hAsl.Min)*.05;                
                newVal=max([newVal hAsl.Min]);
                newVal=min([newVal hAsl.Max]);
                hAsl.Value=newVal;     
                AsliderCB;
            end            
        end
    end

% Initialize uipanel that contains all channel information
hpMain=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','fontsize',12);
hpMain.Position=[0 0 hFGUI.Position(3) hFGUI.Position(4)];
w1=350;
g=50;
w2=hpMain.Position(3)-w1-g;
h=25;


%%%%%%%%%%%%%%%%%%%%% DIGITAL CHANNEL GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrapper container uipanel for digital channels
hpD=uipanel('parent',hpMain,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpD.Position=[0 0 w1 hpMain.Position(4)-60];
 

% Total container uipanel for digital channels
% (you scroll by moving the large panel inside the small one; it's clunky
% but MATLAB doesn't have a good scrollable interface for figure interace)
hpDS=uipanel('parent',hpD,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpDS.Position=[0 0 400 h*length(Dchs)];
hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4);


% button for reset to default
bDdefault=uicontrol('parent',hpMain,'style','pushbutton',...
    'backgroundcolor','w','fontsize',8,'units','pixels');
bDdefault.String='output to default values';
bDdefault.Position(1)=5;
bDdefault.Position(3:4)=[120 20];
bDdefault.Position(2)=hpD.Position(4)+30;

% Panel for labels
Dlbl=uipanel('parent',hpMain,'backgroundcolor','w',...
    'units','pixels','fontsize',10,'bordertype','none');
Dlbl.Position(3:4)=[w1 h];
Dlbl.Position(1:2)=[0 hpD.Position(4)+2];

% Channel label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',10,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];


% Override label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[175 0];

% Value label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[245 0];

% Populate the digital channels
for kk=1:length(Dchs)
    c=[cc(mod(kk-1,7)+1,:) .1];    
    
    % panel for this row
    hpDs(kk)=uipanel('parent',hpDS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','none');
    hpDs(kk).Position(3:4)=[w1 h];
    hpDs(kk).Position(1:2)=[0 hpDS.Position(4)-kk*h];    
    hpDs(kk).UserData.Channel=Dchs(kk);
    
    % Channel label
    t=uicontrol('parent',hpDs(kk),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['d' num2str(Dchs(kk).channel) ' ' Dchs(kk).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpDs(kk).Position(4)-t.Position(4))-2];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpDs(kk),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c);
%     ckOver.String=' override?';
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpDs(kk).Position(4)-ckOver.Position(4));
    ckOver.Callback={@overCBD kk};

    % Value check box
    ckValue=uicontrol('parent',hpDs(kk),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'enable','off');
    ckValue.Position(3:4)=ckValue.Extent(3:4)+50;
    ckValue.Position(1)=250;
    ckValue.Position(2)=0.5*(hpDs(kk).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    ckValue.Value=real(Dchs(kk).resetvalue);
    hpDs(kk).UserData.ckValue=ckValue;
end

% enable or disable a digital channel override
    function overCBD(a,~,ind)
        if a.Value
            hpDs(ind).UserData.ckValue.Enable='on';   
        else
            hpDs(ind).UserData.ckValue.Enable='off';            
        end     
    end

% Digital channel panel slider
hDsl = uicontrol('parent',hpD,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0);
hDsl.Callback=@DsliderCB;
hDsl.SliderStep=[0.05 .1];
hDsl.Min=-(hpDS.Position(4)-hpD.Position(4));
hDsl.OuterPosition(3:4)=[20 hpD.Position(4)];            
hDsl.Position(1:2)=[hpD.Position(3)-hDsl.Position(3) 0];     

% Callback for when the slider bar moves
    function DsliderCB(~,~)
        hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4)-hDsl.Value;   
    end

%%%%%%%%%%%%%%%%%%%%% ANALOG CHANNEL GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrapper container uipanel for analog channels
hpA=uipanel('parent',hpMain,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpA.Position=[hpD.Position(3)+g 0 w2 hpD.Position(4)];

% Total container uipanel for analog channels
hpAS=uipanel('parent',hpA,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpAS.Position=[0 0 w2 h*length(Achs)];
hpAS.Position(2)=hpA.Position(4)-hpAS.Position(4);

% button for set to default values
bAdefault=uicontrol('parent',hpMain,'style','pushbutton',...
    'backgroundcolor','w','fontsize',8,'units','pixels');
bAdefault.String='set to default values';
bAdefault.Position(1)=hpA.Position(1)+5;
bAdefault.Position(3:4)=[100 20];
bAdefault.Position(2)=hpD.Position(4)+30;

% button for set to default values
bAoutput=uicontrol('parent',hpMain,'style','pushbutton',...
    'backgroundcolor','w','fontsize',8,'units','pixels','foregroundcolor','r');
bAoutput.String='output analog channels';
bAoutput.Position(1)=hpA.Position(1)+5+110;
bAoutput.Position(3:4)=[150 20];
bAoutput.Position(2)=hpD.Position(4)+30;


% Panel for labels
Albl=uipanel('parent',hpMain,'backgroundcolor','w',...
    'units','pixel','fontsize',10,'bordertype','none');
Albl.Position(3:4)=[w2 h];
Albl.Position(1:2)=[hpA.Position(1) hpA.Position(4)+2];

% Channel label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',10,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];


% Override label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[175 0];

% Value label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[245 0];

% fucntion label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','func#');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[285 0];

% voltage label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','voltage');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[350 0];


% Populate the analog channels
for kk=1:length(Achs)
    c=[cc(mod(kk-1,7)+1,:) .1];    
    
    % panel for this row
    hpAs(kk)=uipanel('parent',hpAS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','none');
    hpAs(kk).Position(3:4)=[w2 h];
    hpAs(kk).Position(1:2)=[0 hpAS.Position(4)-kk*h];    
    hpAs(kk).UserData.Channel=Achs(kk);
    
    % Channel label
    t=uicontrol('parent',hpAs(kk),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['a' num2str(Achs(kk).channel) ' ' Achs(kk).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpAs(kk).Position(4)-t.Position(4))-2];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpAs(kk),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c);
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpAs(kk).Position(4)-ckOver.Position(4));
    ckOver.Callback={@overCBA kk};

    % Value Number
    ckValue=uicontrol('parent',hpAs(kk),'style','edit','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor','w',...
        'enable','off','String', '');
    ckValue.String=num2str(real(Achs(kk).resetvalue(1)));
    ckValue.Position(4)=ckValue.Extent(4);
    ckValue.Position(3)=40;
    ckValue.Position(1)=240;
    ckValue.Position(2)=0.5*(hpAs(kk).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    hpAs(kk).UserData.ckValue=ckValue;
    
    % Fucntion select
    pdFunc=uicontrol('parent',hpAs(kk),'style','popupmenu',...
        'units','pixels','fontsize',8,'fontname','monospaced',...
        'backgroundcolor','w','enable','off');
    pdFunc.String=strsplit(num2str(1:length(Achs(kk).voltagefunc)),' ');
    
    if length(Achs(kk).resetvalue)>1
        pdFunc.Value=Achs(kk).resetvalue(2);          
    else
        pdFunc.Value=Achs(kk).defaultvoltagefunc;
    end    
    pdFunc.Value
    foo=Achs(kk).voltagefunc{pdFunc.Value};    

    pdFunc.Position(3)=30;
    pdFunc.Position(4)=pdFunc.Extent(4);
    pdFunc.Position(1)=ckValue.Position(1)+ckValue.Position(3);
    pdFunc.Position(2)=0.5*(hpAs(kk).Position(4)-pdFunc.Position(4))+1;
    hpAs(kk).UserData.pdFunc=pdFunc;
    
    % voltage output string
    tVolt=uicontrol('parent',hpAs(kk),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor',c,...
        'enable','on','horizontalalignment','left');
    tVolt.String=[num2str(foo(real(Achs(kk).resetvalue(1)))) ' V'];
    tVolt.Position(1)=350;
    tVolt.Position(3:4)=[120 tVolt.Extent(4)];
    tVolt.Position(2)=2;
end

% enable or disable a analog channel override
    function overCBA(a,~,ind)
        if a.Value
            hpAs(ind).UserData.ckValue.Enable='on';   
            hpAs(ind).UserData.pdFunc.Enable='on';   

        else
            hpAs(ind).UserData.ckValue.Enable='off';            
            hpAs(ind).UserData.pdFunc.Enable='off';   
        end     
    end

% Analog channel panel slider
hAsl = uicontrol('parent',hpA,'Units','pixels','Style','Slider',...
    'visible','on','Tag','scroll','Max',0,'Value',0);
hAsl.Callback=@AsliderCB;
hAsl.SliderStep=[0.05 .1];
hAsl.Min=-(hpAS.Position(4)-hpA.Position(4));
hAsl.OuterPosition(3:4)=[20 hpA.Position(4)];            
hAsl.Position(1:2)=[hpA.Position(3)-hAsl.Position(3) 0];     

% Callback for when the slider bar moves
    function AsliderCB(~,~)
        hpAS.Position(2)=hpA.Position(4)-hpAS.Position(4)-hAsl.Value;   
    end
end