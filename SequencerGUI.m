%------
%Author: David McKay
%Created: July 2009
%Summary: Create the lattice sequencer GUI
%------

function SequencerGUI()

%initalize sequencer
LatticeSequencerInitialize();

global seqdata;

%get the screen size
screensize = get(0,'screensize');

%first create the figure
fh = figure('MenuBar','None','Toolbar','none',...
    'name','Lattice Sequencer','Position',...
    [screensize(3)/2-150 screensize(4)/2-150 300 300]);

%place components

%get figure colour
figcolor = get(fh,'Color');

%add text
uicontrol(fh,'Style','text','String','Lattice Sequencer v1.1',...
    'Position',[20 270 250 20],'FontSize',12,...
    'BackgroundColor',figcolor);

%% add go button

uicontrol(fh,'Style','pushbutton','String','Run',...
    'Position',[170 220 50 30],...
    'callback',@pushbutton_callback,'tag','run');
uicontrol(fh,'Style','pushbutton','String','Stop',...
    'Position',[230 220 50 30],...
    'callback',@pushbutton_callback,'tag','stop');
uicontrol(fh,'Style','pushbutton','String','Abort',...
    'Position',[170 180 50 30],...
    'callback',@pushbutton_callback,'tag','abort');
uicontrol(fh,'Style','pushbutton','String','Reset',...
    'Position',[230 180 50 30],...
    'callback',@pushbutton_callback,'tag','reset');

%add scan controls
uicontrol(fh,'Style','text','String','Scan','Position',[20 160 60 15],...
    'tag','scanlabel','BackgroundColor',figcolor)
uicontrol(fh,'Style','checkbox','String','','Position',[42 145 15 15],...
    'callback',@pushbutton_callback,'tag','scan',...
    'BackgroundColor',figcolor);
uicontrol(fh,'Style','edit','String','100','Position',[30 120 40 20],...
    'tag','scanmax','BackgroundColor','white')

%add text boxes
uicontrol(fh,'Style','text','String','Start Cycle:','Position',...
    [20 240 60 15],'BackgroundColor',figcolor)
uicontrol(fh,'Style','edit','String','1','Position',[20 220 60 20],...
    'tag','startcycle','BackgroundColor','white')

uicontrol(fh,'Style','text','String','End Cycle:','Position',...
    [20 200 60 15],'BackgroundColor',figcolor)
uicontrol(fh,'Style','edit','String','1','Position',[20 180 60 20],...
    'tag','endcycle','BackgroundColor','white')

uicontrol(fh,'Style','text','String','Wait Time:','Position',...
    [90 240 50 15],'BackgroundColor',figcolor)
uicontrol(fh,'Style','edit','String','1000','Position',...
    [90 220 60 20],'tag','waittime','BackgroundColor','white')

uicontrol(fh,'Style','text','String','Target RepTime:','Position',...
    [78 200 80 15],'BackgroundColor',figcolor)
uicontrol(fh,'Style','edit','String','1000','Position',...
    [90 180 60 20],'tag','targettime','BackgroundColor','white')

uicontrol(fh,'Style','text','String','Sequence File:','Position',...
    [90 140 90 15],'BackgroundColor',figcolor)
uicontrol(fh,'Style','edit','String','@Load_MagTrap_sequence',...
    'Position',[90 120 200 20],'tag','sequence','BackgroundColor','white')

%output file options

uicontrol(fh,'Style','text','String','Create Output File',...
    'Position',[40 90 90 15],'BackgroundColor',figcolor);
uicontrol(fh,'Style','checkbox','Position',[20 90 15 15],'tag',...
    'makeoutfile','Value',seqdata.createoutfile,'BackgroundColor','white');

uicontrol(fh,'Style','edit','String',seqdata.outputfilepath,...
    'Position',[20 65 250 20],'BackgroundColor','white','tag','outfilepath');
uicontrol(fh,'Style','pushbutton','String','...','Position',...
    [275 65 20 20],'callback',@dirbutton_callback);

%build monitor
uicontrol(fh,'Style','text','String','idle','Position',...
    [100 20 185 15],'BackgroundColor',figcolor,'HorizontalAlignment','right','tag','buildmon');

%plot stuff
uicontrol(fh,'Style','pushbutton','String','Plot GUI','Position',...
    [20 20 60 30],'callback',@pushbutton_callback,'tag','plotgui');

% uicontrol(fh,'Style','text','String','Channels:','Position',[100 40 60 15],'BackgroundColor',figcolor)
% uicontrol(fh,'Style','edit','String','1','Position',[100 20 60 20],'tag','Channels','BackgroundColor','white')
% 
% uicontrol(fh,'Style','text','String','Times:','Position',[170 40 60 15],'BackgroundColor',figcolor)
% uicontrol(fh,'Style','edit','String','0:100','Position',[170 20 60 20],'tag','Times','BackgroundColor','white')



end

function dirbutton_callback(hobject,eventdata)

newpath = uigetdir(get(hobject,'string'));

if (newpath~=0)
    ui_dirtext = findobj(gcbf,'tag','outfilepath');
    set(ui_dirtext,'string',newpath);
end

end

function editbox_callback(Source, EventData)

    %get the handles to all currently open windows
    windowhnds = get(0,'Children');

    for i = 1:length(windowhnds)
        if get(windowhnds(i),'UserData')==159 %code for a plot window
            Sub_Plot_Handles = get(windowhnds(i), 'Children');
            for Counter = 1 : length(Sub_Plot_Handles)
                Limits = eval(get(Source, 'String'));
                set(Sub_Plot_Handles(Counter), 'XLim', [Limits(1)  Limits(end)] / 1000);
            end
        end
    end
    
end


%------
%Author: David McKay
%Created: July 2009
%Summary: Push button callback
%------
% Feb2015(ST): added a target cycle period "targettime" to ensure constant
% cycle lengths
function pushbutton_callback(varargin)

    global seqdata;

    hobject = varargin{1};

    if(length(varargin) > 2)
        hFigure = varargin{2};
    else
        hFigure = gcf;
    end

    %find the start cycle, end cycle, waittime and sequence files
    uiobj1 = findobj(hFigure,'tag','startcycle');
    startcycle = str2double(get(uiobj1,'string'));

    uiobj1 = findobj(hFigure,'tag','endcycle');
    endcycle = str2double(get(uiobj1,'string'));

    uiobj1 = findobj(hFigure,'tag','waittime');
    waittime = str2double(get(uiobj1,'string'));
    
    uiobj1 = findobj(hFigure,'tag','targettime');
    targettime = str2double(get(uiobj1,'string'));


    uiobj1 = findobj(hFigure,'tag','sequence');
    eval(['sequencefunc = ' get(uiobj1,'string') ';']); 

    uiobj1 = findobj(hFigure,'tag','makeoutfile');
    seqdata.createoutfile = get(uiobj1,'Value');

    % uiobj1 = findobj(gcbf,'tag','Channels');
    % eval(['plotchannels = ' get(uiobj1,'string') ';']);
    % 

    uiobj1 = findobj(hFigure,'tag','outfilepath');
    seqdata.outputfilepath = get(uiobj1,'string');


    %do different actions based on which push button was pressed
    switch get(hobject,'tag')

        case 'scan' % checkbox in GUI

            if ( get(hobject,'Value') )
                seqdata.scancycle = 0;
                seqdata.doscan = 1;
                seqdata.multiscannum = [];%Feb-2017
                scantxt = findobj(gcbf,'tag','scanmax');
                scanmax = str2double(get(scantxt,'String'));
                seqdata.randcyclelist = rand(1,scanmax);
                [void,seqdata.randcyclelist] = sort(seqdata.randcyclelist);
            else
                seqdata.scancycle = 1;
                seqdata.doscan = 0;
                seqdata.randcyclelist = 1:100;
            end

        case 'run'

            cycle_sequence(sequencefunc,waittime,targettime,startcycle,endcycle);

        case 'stop'

            stop_process();

        case 'abort'

            abort_process();

        case 'reset'

            resetADWIN;

        case 'plotgui'

            PlotGUI(hFigure);

        case 'Plot'

            CheckBoxHandles = varargin{3:end};
            uiobj1 = findobj(gcbf,'tag','Times');
            eval(['plot_times = ' get(uiobj1,'string') ';']);
            plotchannels = [ ] ;
            for Counter = 1 : length(CheckBoxHandles)
                if (get(CheckBoxHandles(Counter), 'Value') == 1)
                    plotchannels = [plotchannels; Counter];
                end
            end
            PlotSequenceVersion2(sequencefunc,startcycle,plotchannels,plot_times);

    end

end
