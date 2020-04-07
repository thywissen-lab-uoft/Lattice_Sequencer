function [t, y, vals, names] = currentSequence(fhandle, cycle, channels, times);
    
    % rotate input vectors if necessary
    if size(times,1) > 1; times = times'; end
    if size(channels,1) > 1; channels = channels'; end
    ch = [channels channels(end)];
    
    [t, y] = meshgrid(times, 1:(length(channels)+1));
    
    seqdata = evalin('base','seqdata');
    
    % ---- this section is copied from plotSequence.m -------
%     start_new_sequence();
%     seqdata.cycle = cycle;
%     
%     fhandle(0);
    
    %go through each of the plots
    plot_values = zeros(length(channels),length(times));
    channel_type = zeros(1,length(channels)); %keep track if digital or analog
    channel_names = cell(1,length(channels)); %keep track of channel name if possible

    %get the channel values
    for j = 1:length(channels)

        if (channels(j)<0)
            error('Invalid channel number');
        elseif (channels(j)<=length(seqdata.analogchannels))
            %analog channel
            ind = logical(seqdata.analogadwinlist(:,2)==channels(j));
            channel_data = seqdata.analogadwinlist(ind,:);
            channel_data(:,3) = channel_data(:,3)*2^(-16)*20 - 10; % convert from double
            channel_type(j) = 1;
            channel_names{j} = ['a' num2str(channels(j)) '  ' seqdata.analogchannels(channels(j)).name];
        elseif (channels(j)<=(length(seqdata.analogchannels)+length(seqdata.digchannels)))
            %digital channel
            ind = logical(seqdata.digadwinlist(:,2)==(channels(j)-length(seqdata.analogchannels)));
            channel_data = seqdata.digadwinlist(ind,1:3);
            channel_data(:,3) = 20*channel_data(:,3) - 10;
            didx = channels(j)-length(seqdata.analogchannels);
            channel_names{j} = ['d' num2str(didx) '  ' seqdata.digchannels(didx).name];
        else
            error('Invalid channel number');
        end
    
        %sort data by time
        [tempdata sort_index] = sort(channel_data(:,1));
        channel_data = channel_data(sort_index,:);
    
    
        %set the times into real units (not update cycles)
        channel_data(:,1) = channel_data(:,1)*seqdata.deltat/seqdata.timeunit;
    
        %Get the value of the channel at the times indicated for the plot. For
        %a given time always look to see the last PREVIOUS time that the
        %channel was updated
        if ( channel_type == 1 )
            cur_value = 0; %assume the channel is initially 0
            cur_index = 0;
        else
            cur_value = -10; %assume the channel is initially 0
            cur_index = 0;
        end
        if isempty(channel_data)
            plot_values(j,:) = 0;
        else
            for k = 1:length(plot_values(j,:))
                if (cur_index>=0)
                    if (channel_data(cur_index+1,1)>times(k))
                        if cur_index>0
                            cur_value = channel_data(cur_index,3);
                        end
                        plot_values(j,k) = cur_value;
                    else
                       for kk=(cur_index+1):length(channel_data(:,1))
                           if channel_data(kk,1)>times(k)
                               cur_index = kk-1;
                               cur_value = channel_data(cur_index,3);
                               plot_values(j,k) = cur_value;
                               break
                           end
                           cur_index = -1;
                           cur_value = channel_data(end,3);
                           plot_values(j,k) = cur_value;
                       end                  
                    end
                else
                    plot_values(j,k) = cur_value;
                end
            end
        end
        
        %Get channel name if possible
        %channel_names(j) = {seqdata.analogchannels(channels(j)).name};
    
    end
    
    % ------------------------------------------------------
    
    vals = [plot_values;plot_values(end,:)];
    names = channel_names;
    
end