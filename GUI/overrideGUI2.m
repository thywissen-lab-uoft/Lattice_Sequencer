function hFGUI=overrideGUI2

% overrrideGUI
%
% Author : CJ Fujiwara
%
% This GUI is meant to override the digital and analog channels of the
% experiment.  Its purpose is to provide an easy platform to diagnose and
% calibrate the controls to the experiment. It is not designed to perform
% custom test sequences for more complicated diagnoses, such as ramps or
% measuring delays.

% The design of the interface is modeled after the Cicero Word Generator.
% The author used this at their previously institution and found it
% intuitive. Further, this design will hopefully make it easier for future
% lab members coming from "MIT-children" institutions to learn the lab.

% Initialize the sequence data
global seqdata;


start_new_sequence();
initialize_channels();

% Grab the analog and digital channels
Achs=seqdata.analogchannels;
Dchs=seqdata.digchannels;

% Define the RGB color scheme for the rows in the table
cc=[255	255	255;
    221 235 247]/255;
bc=[47	117	181]/255;



% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name','Adwin Override','Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off');
hFGUI.Position(3:4)=[900 600];
hFGUI.Position(2)=50;
hFGUI.WindowScrollWheelFcn=@scroll;

% Callback function for mouse scroll over the figure.
    function scroll(~,b)
        scrll=-b.VerticalScrollCount;
        C=get(gcf,'CurrentPoint');        
        if C(2)<hpMain.Position(4)                  
            if C(1)<hpMain.Position(3)/2
                % mouse in in digital side
                newVal=hDsl.Value+scrll*abs(hDsl.Min)*.05;                
                newVal=max([newVal hDsl.Min]);
                newVal=min([newVal hDsl.Max]);
                hDsl.Value=newVal;     
                DsliderCB;
            else
                % mouse is in analog side
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

% Define the respective size of the digital and analog panels
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


% Panel for labels
Dlbl=uipanel('parent',hpMain,'backgroundcolor','w',...
    'units','pixels','fontsize',10,'bordertype','none');
Dlbl.Position(3:4)=[w1 h];
Dlbl.Position(1:2)=[0 hpD.Position(4)+2];

% Channel namel label
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
    % Grab the color
    c=[cc(mod(kk-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpDs(kk)=uipanel('parent',hpDS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpDs(kk).Position(3:4)=[w1 h+1];
    hpDs(kk).Position(1:2)=[0 hpDS.Position(4)-kk*h];    
    hpDs(kk).UserData.Channel=Dchs(kk);    
    
    % Channel label
    t=uicontrol('parent',hpDs(kk),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['d' num2str(Dchs(kk).channel) ' ' Dchs(kk).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpDs(kk).Position(4)-t.Position(4))-3];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpDs(kk),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'Callback',{@overCBD kk});
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpDs(kk).Position(4)-ckOver.Position(4));

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


% button to output analog channels
bAoutput=uicontrol('parent',hpMain,'style','pushbutton',...
    'backgroundcolor','w','fontsize',10,'units','pixels',...
    'foregroundcolor','k');
bAoutput.String='output analog channels';
bAoutput.Position(1)=hpA.Position(1)+5;
bAoutput.Position(3:4)=[150 25];
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
    c=[cc(mod(kk-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpAs(kk)=uipanel('parent',hpAS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpAs(kk).Position(3:4)=[w2 h+1];
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
    
    % Function select pull-down menu
    pdFunc=uicontrol('parent',hpAs(kk),'style','popupmenu',...
        'units','pixels','fontsize',8,'fontname','monospaced',...
        'backgroundcolor','w','enable','off');
    pdFunc.String=strsplit(num2str(1:length(Achs(kk).voltagefunc)),' ');
    
    % case where we specify value not using the defaultfunc (value,func#)
    if length(Achs(kk).resetvalue)>1
        pdFunc.Value=Achs(kk).resetvalue(2);          
    else
        pdFunc.Value=Achs(kk).defaultvoltagefunc;
    end    
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


%% Override GUI
% This GUI is meant to override the digital and analog channels of the
% experiment.  Its purpose is to provide an easy platform to diagnose and
% calibrate the controls to the experiment. It is not designed to perform
% custom test sequences for more complicated diagnoses, such as ramps or
% measuring delays.

%{

disp('Initializing override GUI...');

% Grab the analog and digital channels
Achs=seqdata.analogchannels;
Dchs=seqdata.digchannels;

% Define the RGB color scheme for the rows in the table
cc=[255	255	255;
    221 235 247]/255;
bc=[47	117	181]/255;



% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name','Adwin Override','Toolbar','none','menubar','none',...
    'NumberTitle','off','Resize','off','Visible','off');
hFGUI.Position(3:4)=[900 600];
hFGUI.Position(2)=50;
hFGUI.WindowScrollWheelFcn=@scroll;
hFGUI.CloseRequestFcn=@(src,~) set(src,'Visible','off');



% Callback function for mouse scroll over the figure.
    function scroll(~,b)
        scrll=-b.VerticalScrollCount;
        C=get(gcf,'CurrentPoint');        
        if C(2)<hpOver.Position(4)                  
            if C(1)<hpOver.Position(3)/2
                % mouse in in digital side
                newVal=hDsl.Value+scrll*abs(hDsl.Min)*.05;                
                newVal=max([newVal hDsl.Min]);
                newVal=min([newVal hDsl.Max]);
                hDsl.Value=newVal;     
                DsliderCB;
            else
                % mouse is in analog side
                newVal=hAsl.Value+scrll*abs(hAsl.Min)*.05;                
                newVal=max([newVal hAsl.Min]);
                newVal=min([newVal hAsl.Max]);
                hAsl.Value=newVal;     
                AsliderCB;
            end            
        end
    end

% Initialize uipanel that contains all channel information
hpOver=uipanel('parent',hFGUI,'backgroundcolor','w',...
    'units','pixels','fontsize',12);
hpOver.Position=[0 0 hFGUI.Position(3) hFGUI.Position(4)];

% Define the respective size of the digital and analog panels
w1=350;
g=50;
w2=hpOver.Position(3)-w1-g;
h=25;


%%%%%%%%%%%%%%%%%%%%% DIGITAL CHANNEL GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrapper container uipanel for digital channels
hpD=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpD.Position=[0 0 w1 hpOver.Position(4)-60];
 

% Total container uipanel for digital channels
% (you scroll by moving the large panel inside the small one; it's clunky
% but MATLAB doesn't have a good scrollable interface for figure interace)
hpDS=uipanel('parent',hpD,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpDS.Position=[0 0 400 h*length(Dchs)];
hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4);


% Panel for labels
Dlbl=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',10,'bordertype','none');
Dlbl.Position(3:4)=[w1 h];
Dlbl.Position(1:2)=[0 hpD.Position(4)+2];

% Channel namel label
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
for nn=1:length(Dchs)
    % Grab the color
    c=[cc(mod(nn-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpDs(nn)=uipanel('parent',hpDS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpDs(nn).Position(3:4)=[w1 h+1];
    hpDs(nn).Position(1:2)=[0 hpDS.Position(4)-nn*h];    
    hpDs(nn).UserData.Channel=Dchs(nn);    
    
    % Channel label
    t=uicontrol('parent',hpDs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['d' num2str(Dchs(nn).channel) ' ' Dchs(nn).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpDs(nn).Position(4)-t.Position(4))-3];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'Callback',{@overCBD nn});
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpDs(nn).Position(4)-ckOver.Position(4));

    % Value check box
    ckValue=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'enable','off');
    ckValue.Position(3:4)=ckValue.Extent(3:4)+50;
    ckValue.Position(1)=250;
    ckValue.Position(2)=0.5*(hpDs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    ckValue.Value=real(Dchs(nn).resetvalue);
    hpDs(nn).UserData.ckValue=ckValue;    
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
hpA=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpA.Position=[hpD.Position(3)+g 0 w2 hpD.Position(4)];

% Total container uipanel for analog channels
hpAS=uipanel('parent',hpA,'backgroundcolor','w',...
    'units','pixels','fontsize',12,'clipping','on');
hpAS.Position=[0 0 w2 h*length(Achs)];
hpAS.Position(2)=hpA.Position(4)-hpAS.Position(4);


% button to output analog channels
bAoutput=uicontrol('parent',hpOver,'style','pushbutton',...
    'backgroundcolor','w','fontsize',10,'units','pixels',...
    'foregroundcolor','k');
bAoutput.String='output analog channels';
bAoutput.Position(1)=hpA.Position(1)+5;
bAoutput.Position(3:4)=[150 25];
bAoutput.Position(2)=hpD.Position(4)+30;


% Panel for labels
Albl=uipanel('parent',hpOver,'backgroundcolor','w',...
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
for nn=1:length(Achs)
    c=[cc(mod(nn-1,size(cc,1))+1,:) .1];    
    
    % panel for this row
    hpAs(nn)=uipanel('parent',hpAS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bc,'borderwidth',1);
    hpAs(nn).Position(3:4)=[w2 h+1];
    hpAs(nn).Position(1:2)=[0 hpAS.Position(4)-nn*h];    
    hpAs(nn).UserData.Channel=Achs(nn);
    
    % Channel label
    t=uicontrol('parent',hpAs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['a' num2str(Achs(nn).channel) ' ' Achs(nn).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpAs(nn).Position(4)-t.Position(4))-2];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpAs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c);
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=200;
    ckOver.Position(2)=0.5*(hpAs(nn).Position(4)-ckOver.Position(4));
    ckOver.Callback={@overCBA nn};

    % Value Number
    ckValue=uicontrol('parent',hpAs(nn),'style','edit','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor','w',...
        'enable','off','String', '');
    ckValue.String=num2str(real(Achs(nn).resetvalue(1)));
    ckValue.Position(4)=ckValue.Extent(4);
    ckValue.Position(3)=40;
    ckValue.Position(1)=240;
    ckValue.Position(2)=0.5*(hpAs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    hpAs(nn).UserData.ckValue=ckValue;
    
    % Function select pull-down menu
    pdFunc=uicontrol('parent',hpAs(nn),'style','popupmenu',...
        'units','pixels','fontsize',8,'fontname','monospaced',...
        'backgroundcolor','w','enable','off');
    pdFunc.String=strsplit(num2str(1:length(Achs(nn).voltagefunc)),' ');
    
    % case where we specify value not using the defaultfunc (value,func#)
    if length(Achs(nn).resetvalue)>1
        pdFunc.Value=Achs(nn).resetvalue(2);          
    else
        pdFunc.Value=Achs(nn).defaultvoltagefunc;
    end    
    foo=Achs(nn).voltagefunc{pdFunc.Value};    

    pdFunc.Position(3)=30;
    pdFunc.Position(4)=pdFunc.Extent(4);
    pdFunc.Position(1)=ckValue.Position(1)+ckValue.Position(3);
    pdFunc.Position(2)=0.5*(hpAs(nn).Position(4)-pdFunc.Position(4))+1;
    hpAs(nn).UserData.pdFunc=pdFunc;
    
    % voltage output string
    tVolt=uicontrol('parent',hpAs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor',c,...
        'enable','on','horizontalalignment','left');
    tVolt.String=[num2str(foo(real(Achs(nn).resetvalue(1)))) ' V'];
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

%}