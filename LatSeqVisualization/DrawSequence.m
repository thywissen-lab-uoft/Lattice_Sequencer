function DrawSequence(hObject, fhandle, cycle, channels, times, handles, redraw)

    
        
	% Read in information from the sequencer GUI (basically not needed)
    seqGUI = findobj('Name','Lattice Sequencer');
    uiobj1 = findobj(seqGUI,'tag','startcycle');
    startcycle = str2double(get(uiobj1,'string'));
    uiobj1 = findobj(seqGUI,'tag','sequence');
    eval(['sequencefunc = ' get(uiobj1,'string') ';']);
    
    if ~exist('redraw','var');
        redraw = 0;
    end
   
    tsteps = 5000; % time steps to use. change this value to adapt to screen resolution
    
    if ( ~redraw ) % use current axis settings to recalculate
        times = get(hObject,'xlim');
    end
    
    times = [min(times) max(times)]; % build time vector
    times = times(1):((times(2)-times(1))/tsteps):times(2);
    
    [t, y, vals, YTickLabel] = currentSequence(sequencefunc, startcycle, channels, times); % get sequence data
    
    h = pcolor(hObject,t,y-0.5,vals); % display sequence data
    set(h,'EdgeColor','none');
    
    set(hObject,'Xlim',[min(t(1,:)) max(t(1,:))]); % set xlimits (just to be sure)
    set(hObject,'Ylim',[min(y(:,1)) max(y(:,1))]-0.5);
    
    clim = sort([get(handles.slidermax,'Value') ... % set color range
                 get(handles.slidermin,'Value')]);
    set(hObject,'CLim',clim);
    
    set(get(hObject,'XLabel'), 'String', 'Time (ms)'); % axes labels
    set(get(hObject,'YLabel'), 'String', 'Channel');
    
    set(hObject,'YTick',y(1:end-1,1)); % set yTickLabels to be channel numbers
%     YTickLabel = {};
%     for j = 1:size(y,1)-1
%         YTickLabel{j} = sprintf('#%g',channels(j));
%     end
    set(hObject,'YTickLabel',YTickLabel);

    
    % Building the colormap
%     j = [0:0.02:1]';
%     cmap = flipud(([[0.75+0.25*j j j];1-[j j 0.25*j]]).^0.8);
    cmap = colormap('jet');
    sat = abs(repmat((0:size(cmap,1)-1)'/(size(cmap,1)-1)-0.5, 1, 3));
    sat = ((2*sat).^0.7)*0.75+0.25;
    cmap = cmap.*sat + (1-sat);
%     cmap=[([3 3 3]+cmap(1,:))/5;cmap;([3 3 3]+cmap(end,:))/5];
    cmap=[[0.4 0.4 0.4];cmap;[0.8 0.8 0.8]];
    colormap(handles.axesMain,cmap);
    
    handles.firstChannelIndex = find(handles.channels == channels(1), 1);
    
    xLimits = get(hObject,'xlim'); % get new limits of axes
    yLimits = get(hObject,'ylim');
    set(hObject,'UserData',[xLimits;yLimits]); % update timer.UserData
    
    posx = get(handles.axesMain,'Position');
    posy = posx([2 4]); posx = posx(1) + posx(3) + 0.3;
    for j = 1:length(channels)
        overwrite = 0;
        thisPosy = posy(1) + (j-0.5)*posy(2)/length(channels)-0.9;
        if ( j <= length(handles.checkChannel) )
            set(handles.checkChannel(j), 'UserData', channels(j), ...
                'Position', [posx thisPosy 3 1.8],...
                'Visible','on');
                 overwrite = 1;
        else
            newCheckbox = uicontrol(handles.figure1,...
                'Style', 'checkbox', ...
                'UserData', channels(j), ...
                'Units','characters',...
                'Position', [posx thisPosy 3 1.8],...
                'Visible','on');
        end
        if ( ~overwrite )
            handles.checkChannel(j) = newCheckbox;
        end
    end
    
    %%% WHY DOES MOVING/HIDING NOT WORK?
    
    %     if length(handles.checkChannel) > length(channels)
%         for j = (length(channels)+1):length(handles.checkChannel)
%             setpixelposition(handles.checkChannel(j),[1 1 1 1]);
% %             set(handles.checkChannel(j),'Visible','off','Value',1,'Position',[0 0 1 1]);
%         end
% %         handles.checkChannel((length(channels)+1):length(handles.checkChannel)) = [];
%     end
%     
%     handles.checkChannel
         
    guidata(handles.figure1, handles);
   
end
