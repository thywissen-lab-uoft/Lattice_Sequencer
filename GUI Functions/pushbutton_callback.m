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

            % old plot GUI, after further bug testing, we should delete
            % this call and eventyually the old plotgui function itself.
            % For now, we'll leave this in?
%             PlotGUI(hFigure);
            plotgui;

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