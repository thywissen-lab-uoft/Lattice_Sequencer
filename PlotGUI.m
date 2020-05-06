function PlotGUI(hFigure)
% CJF - This function is poolry defined. If it is a child function of
% sequener GUI, then it should be defined in the code of SequencerGUI.m,
% or, one of it's input arguments should be the additional info on
% channels.
% It shouldn't be using the same callback function as another GUI; that's
% just silly and makes dependencies complicated.

    %Need to know about channels existing in seqdata in order to create the
    %GUI.
    global seqdata;
    start_new_sequence();
    initialize_channels();

    %Get the screen size
    screensize = get(0,'screensize');

    %Create the figure.
    Figure_Outer_Width = 500;
    Figure_Outer_Height = 1000;
    Child_Vector = get(0, 'children');
    if(~strcmp(get(Child_Vector, 'name'), 'Plot GUI'))
        fh = figure('MenuBar','None','Toolbar','none','name','Plot GUI','OuterPosition',[(screensize(3) - Figure_Outer_Width - 25) (screensize(4) - Figure_Outer_Height - 25) Figure_Outer_Width Figure_Outer_Height]);

        Figure_Size = get(fh, 'Position');

        %Get its colour.
        figcolor = get(fh,'Color');

        %Create the objects.
        Check_Height = 16;
        Check_Width = 16;
        Space_x = 10;
        Start_x = 10;
        End_x = 10;
        Start_y = 50;
        End_y = 10;
        Step_y = (Figure_Size(4) - Start_y - End_y) / length(seqdata.digchannels);
        Text_Width = (Figure_Size(3) - Start_x - End_x - Space_x - 2 * Check_Width) / 2;
        Text_Height = 16;
        Position_y = Figure_Size(4) - Start_y - Text_Height;
        Check_Handles = zeros(length(seqdata.analogchannels) + length(seqdata.digchannels), 1);

        %Timing and pushbutton.
        Push_Handle = uicontrol(fh,'Style','pushbutton','String','Plot','Position',[Start_x (Figure_Size(4) - 25) 40 20],'tag','Plot');

        uicontrol(fh,'Style','text','String','Times:','Position',[(Start_x + 50) (Figure_Size(4) - 25) 40 20],'BackgroundColor',figcolor)
        uicontrol(fh,'Style','edit','String','0:100000','Position',[(Start_x + 100) (Figure_Size(4) - 25) 100 20],'tag','Times','BackgroundColor','white','Callback',@editbox_callback)

        uicontrol(fh, 'Style', 'Text', 'FontWeight', 'Bold', 'BackgroundColor', figcolor, 'String', 'Analog Channels', 'Position', [Start_x (Figure_Size(4) - Text_Height - 30) Text_Width Text_Height], 'HorizontalAlignment', 'Left');

        for Counter = 1 : length(seqdata.analogchannels)

            uicontrol(fh, 'Style', 'Text', 'BackgroundColor', figcolor, 'String', [int2str(Counter) ' - ' seqdata.analogchannels(Counter).name], 'Position', [Start_x Position_y Text_Width Text_Height], 'HorizontalAlignment', 'Left');
            Check_Handles(Counter) = uicontrol(fh, 'Style', 'Checkbox', 'Position', [Start_x + Text_Width Position_y Check_Width Check_Height]);
            Position_y = Position_y - Step_y;

        end

        Start_x = Space_x/2 + Figure_Size(3) / 2;
        Position_y = Figure_Size(4) - Start_y - Text_Height;

        uicontrol(fh, 'Style', 'Text', 'FontWeight', 'Bold', 'BackgroundColor', figcolor, 'String', 'Digital Channels', 'Position', [Start_x (Figure_Size(4) - Text_Height - 30) Text_Width Text_Height], 'HorizontalAlignment', 'Left');

        for Counter = 1 : length(seqdata.digchannels)

            uicontrol(fh, 'Style', 'Text', 'BackgroundColor', figcolor, 'String', [int2str(Counter) ' - ' seqdata.digchannels(Counter).name], 'Position', [Start_x Position_y Text_Width Text_Height], 'HorizontalAlignment', 'Left');
            Check_Handles(length(seqdata.analogchannels) + Counter) = uicontrol(fh, 'Style', 'Checkbox', 'Position', [Start_x + Text_Width Position_y Check_Width Check_Height]);
            Position_y = Position_y - Step_y;

        end   

        set(Push_Handle, 'Callback', @(src, evnt) pushbutton_callback(Push_Handle, hFigure, Check_Handles));
        
    else
        
        figure(Child_Vector(strcmp(get(Child_Vector, 'name'), 'Plot GUI')));
        
    end
end
