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