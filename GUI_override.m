function GUI_override
%% Override GUI
% This GUI is meant to override the digital and analog channels of the
% experiment.  Its purpose is to provide an easy platform to diagnose and
% calibrate the controls to the experiment. It is not designed to perform
% custom test sequences for more complicated diagnoses, such as ramps or
% measuring delays.

% Relevant ADWIN FUNCTIONS
% (Pp. 29) SetData_double Set the channels of the adwin
% (Pp. 30) GetData_double Read the channels of the adwin
% process_status Get the status of the adwin

% Name of the GUI
guiname='Adwin Override';

disp('Initializing override GUI...');

% Close instances of the GUI incase you ran this without closing 
a=groot;
for kk=1:length(a.Children)
    try
       if isequal(a.Children(kk).Name,guiname)
          figure(a.Children(kk));
          disp('Already found instance of override GUI.');
          return;
       end
    end
end


global seqdata

initialize_channels()


% Grab the analog and digital channels
Achs=seqdata.analogchannels;
Dchs=seqdata.digchannels;

% Define the RGB color scheme for the rows of digital channels
ccD=[221 235 247;
    255	255	255]/255;

% Define the RGB color scheme for the rows of analog channels
ccA=[245,230,255;
    255	255	255]/255;


bcD=[47	117	181]/255;
bcA=[0.4940 0.1840 0.5560];

%% Graphical Initialize

% Initialize main figure
hFGUI=figure(101);
clf
set(hFGUI,'color','w','Name',guiname,'Toolbar','none',...
    'NumberTitle','off','Resize','on','Visible','off','Tag','GUI');
hFGUI.Position(3:4)=[900 600];
hFGUI.Position(2)=50;
hFGUI.WindowScrollWheelFcn=@scroll;
% hFGUI.CloseRequestFcn=@(src,~) set(src,'Visible','off');
hFGUI.SizeChangedFcn=@chSize;

    function chSize(fig,~)
        % Get figure size
        W = fig.Position(3);H = fig.Position(4);

        if H>100 && W >100

            % Resize main panels
            hpOver.Position(3:4)=[W H];
            
            w1=350;
            w2=hpOver.Position(3)-w1-g;
            
            % Digital Resize
            if W>100
                hpD.Position(3:4)=[w1 hpOver.Position(4)-60];

                % Digital Channel Labels
                Dlbl.Position(3:4)=[w1 h];
                Dlbl.Position(1:2)=[0 hpD.Position(4)+2];
                
                % Digital Channel Slider Bar
                hDsl.OuterPosition(3:4)=[20 hpD.Position(4)];   

                hDsl.Min=-(hpDS.Position(4)-hpD.Position(4));
                if hDsl.Value<hDsl.Min
                    hDsl.Value=hDsl.Min;
                end
            end
            
            if W>400

                % Digital and Analog Panel size
                hpA.Position(3:4)=[w2 hpOver.Position(4)-60];                
                hpAS.Position(3)=w2;

                % Analog Channel Labels
                Albl.Position(3:4)=[w2 h];
                Albl.Position(1:2)=[hpA.Position(1) hpA.Position(4)+2];

                % Anlaog output button
                bAoutput.Position(1)=hpA.Position(1)+5;
                bAoutput.Position(3:4)=[150 25];
                bAoutput.Position(2)=hpD.Position(4)+30;

                % Analog Channel slider bar
                hAsl.OuterPosition(3:4)=[20 hpA.Position(4)];            
                hAsl.Position(1:2)=[hpA.Position(3)-hAsl.Position(3) 0];  
                hAsl.Min=-(hpAS.Position(4)-hpA.Position(4));


                if hAsl.Value<hAsl.Min
                    hAsl.Value=hAsl.Min;
                end
            end

            DsliderCB;
            AsliderCB;

        end

        drawnow;
    end



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

% Width of digital panel
w1=350;

% Gao between panels
g=10;

% Width of analog panel
w2=hpOver.Position(3)-w1-g;

% Heigh of each channel
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
    'units','pixels','fontsize',12,'clipping','on','bordertype','none');
hpDS.Position=[0 0 400 h*length(Dchs)+6];
hpDS.Position(2)=hpD.Position(4)-hpDS.Position(4);


% Panel for labels
Dlbl=uipanel('parent',hpOver,'backgroundcolor','w',...
    'units','pixels','fontsize',10,'bordertype','none');
Dlbl.Position(3:4)=[w1 h];
Dlbl.Position(1:2)=[0 hpD.Position(4)+2];

% Channel namel label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',10,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','Digital Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];

% Override label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[225 0];

% Value label
t=uicontrol('parent',Dlbl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[295 0];

tic
% Populate the digital channels
for nn=1:length(Dchs)
    % Grab the color
    c=[ccD(mod(nn-1,size(ccD,1))+1,:) .1];    
    
    % panel for this row
    hpDs(nn)=uipanel('parent',hpDS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bcD,'borderwidth',1);
    hpDs(nn).Position(3:4)=[w1 h+1];
    hpDs(nn).Position(1:2)=[0 hpDS.Position(4)-nn*h-3];    
    hpDs(nn).UserData.Channel=Dchs(nn);    
    
    % Channel label
    t=uicontrol('parent',hpDs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','fontweight','bold',...
        'backgroundcolor',c);
    t.String=['d' num2str(Dchs(nn).channel) ' ' Dchs(nn).name];      
    t.Position(3:4)=t.Extent(3:4);
    t.Position(1:2)=[10 0.5*(hpDs(nn).Position(4)-t.Position(4))-4];
 
    % Override Checkbox
    ckOver=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'Callback',{@overCBD nn});
    ckOver.Position(3:4)=ckOver.Extent(3:4)+50;
    ckOver.Position(1)=250;
    ckOver.Position(2)=0.5*(hpDs(nn).Position(4)-ckOver.Position(4));

    % Value check box
    ckValue=uicontrol('parent',hpDs(nn),'style','checkbox','units','pixels',...
        'fontsize',6,'fontname','monospaced','backgroundcolor',c,...
        'enable','off');
    ckValue.Position(3:4)=ckValue.Extent(3:4)+50;
    ckValue.Position(1)=300;
    ckValue.Position(2)=0.5*(hpDs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    ckValue.Value=real(Dchs(nn).resetvalue);
    hpDs(nn).UserData.ckValue=ckValue;    
end

toc
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
    'units','pixels','fontsize',12,'clipping','on','BorderType','none');
hpAS.Position=[0 0 w2 h*length(Achs)+6];
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
'backgroundcolor','w','String','Analog Channel Name');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[10 0];


% Override label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','override?');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[225 0];

% Value label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','value');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[295 0];

% fucntion label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','func#');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[335 0];

% voltage label
t=uicontrol('parent',Albl,'style','text','units','pixels',...
'fontsize',8,'fontname','monospaced','fontweight','bold',...
'backgroundcolor','w','String','voltage');
t.Position(3:4)=t.Extent(3:4);
t.Position(1:2)=[400 0];

tic




% Populate the analog channels
for nn=1:length(Achs)
    c=[ccA(mod(nn-1,size(ccA,1))+1,:) .1];    
    
    % panel for this row
    hpAs(nn)=uipanel('parent',hpAS,'backgroundcolor',c,...
        'units','pixels','fontsize',10,'bordertype','line',...
        'highlightcolor',bcA,'borderwidth',1);
    hpAs(nn).Position(3:4)=[w2+1000 h+1];
    hpAs(nn).Position(1:2)=[0 hpAS.Position(4)-nn*h-3];    
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
    ckOver.Position(1)=250;
    ckOver.Position(2)=0.5*(hpAs(nn).Position(4)-ckOver.Position(4));
    ckOver.Callback={@overCBA nn};

    % Value Number
    ckValue=uicontrol('parent',hpAs(nn),'style','edit','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor','w',...
        'enable','off','String', '');
    ckValue.String=num2str(real(Achs(nn).resetvalue(1)));
    ckValue.Position(4)=ckValue.Extent(4);
    ckValue.Position(3)=60;
    ckValue.Position(1)=290;
    ckValue.Position(2)=0.5*(hpAs(nn).Position(4)-ckValue.Position(4));
    ckValue.Enable='off';        
    hpAs(nn).UserData.ckValue=ckValue;
     
%     tbl=uitable('parent',hpAs(nn),'columnname',{},'rowname',{},...
%         'units','pixels','columnwidth',{60},'data',0,'enable','off',...
%         'columneditable',[true]);
%     tbl.Position(1)=290;
%     tbl.Position(3) = 40;
%     tbl.Position(3:4) = tbl.Extent(3:4);
%         tbl.Position(2)=0.5*(hpAs(nn).Position(4)-tbl.Position(4));
%     hpAs(nn).UserData.TableValue=tbl;

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
%     pdFunc.Position(1)=tbl.Position(1)+tbl.Position(3);

    pdFunc.Position(2)=0.5*(hpAs(nn).Position(4)-pdFunc.Position(4))+1;
    hpAs(nn).UserData.pdFunc=pdFunc;
    
    % voltage output string
    tVolt=uicontrol('parent',hpAs(nn),'style','text','units','pixels',...
        'fontsize',8,'fontname','monospaced','backgroundcolor',c,...
        'enable','on','horizontalalignment','left');
    tVolt.String=[num2str(foo(real(Achs(nn).resetvalue(1)))) ' V'];
    tVolt.Position(1)=400;
    tVolt.Position(3:4)=[120 tVolt.Extent(4)];
    tVolt.Position(2)=2;
end
toc

% enable or disable a analog channel override
    function overCBA(a,~,ind)
        if a.Value
            hpAs(ind).UserData.ckValue.Enable='on';   
            hpAs(ind).UserData.pdFunc.Enable='on';   
%             hpAs(ind).UserData.TableValue.Enable='on';

        else
            hpAs(ind).UserData.ckValue.Enable='off';            
            hpAs(ind).UserData.pdFunc.Enable='off';   
%             hpAs(ind).UserData.TableValue.Enable='off';

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

%% Show the Figure

hFGUI.Visible='on';

disp('Override GUI is initialized');

end

