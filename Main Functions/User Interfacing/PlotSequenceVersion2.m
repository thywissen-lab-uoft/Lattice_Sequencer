%------
%Author: David McKay
%Created: July 2009
%Summary: Run this to plot a sequence
%------

function plothnd=PlotSequenceVersion2(fhandle,cycle,channels,times)

%---INPUTS---
%fhandle: function handle for the sequence
%cycle: cycle value
%channels: array of channels to plot
%times: array of time values to plot
%------------


global seqdata;
%close all;

%added by DCM - July 2010
%close only existing plot windows

%get the handles to all currently open windows
windowhnds = get(0,'Children');

for i = 1:length(windowhnds)
    if get(windowhnds(i),'UserData')==159 %code for a plot window
        close(windowhnds(i));
    end
end

%% Calculate the sequence
start_new_sequence();
seqdata.cycle = cycle;

%run the sequence
fhandle(0);

Axis_Min = times(1)/1000;
Axis_Max = times(end)/1000;
if(Axis_Max < Axis_Min)
    error('Max time less than min time!');
end

%Define start time, end time, and divisions per interval.
Min_Time = 0;
Max_Time = 100000;
Divisions = 10000;

%go through each of the plots
channel_type = zeros(1,length(channels)); %keep track if digital or analog
channel_names = cell(1,length(channels)); %keep track of channel name if possible

disp('Plotting')

plothnd = figure;
set(plothnd,'UserData',159);  
screensize = get(0, 'ScreenSize');
set(plothnd, 'OuterPosition', [25 (screensize(4) - 300 * ceil(length(channels)/2) - 25) 600 300 * ceil(length(channels)/2)]);

%get the channel values
for j = 1:length(channels)

    channel_data = [];
    
    if (channels(j)<0 || channels(j) > (length(seqdata.analogchannels)+length(seqdata.digchannels)))
        error('Invalid channel number');
    elseif (channels(j)<=length(seqdata.analogchannels) && ~isempty(seqdata.analogadwinlist))
        %analog channel
        ind = logical(seqdata.analogadwinlist(:,2)==channels(j));
        channel_data = seqdata.analogadwinlist(ind,:);
        channel_type(j) = 1;
        channel_names{j} = ['a' num2str(channels(j)) '  ' seqdata.analogchannels(channels(j)).name];
    elseif (channels(j)>length(seqdata.analogchannels) && channels(j)<=(length(seqdata.analogchannels)+length(seqdata.digchannels)) && ~isempty(seqdata.digadwinlist))
        %digital channel
        ind = logical(seqdata.digadwinlist(:,2)==(channels(j)-length(seqdata.analogchannels)));
        channel_data = seqdata.digadwinlist(ind,1:3);
        didx = channels(j)-length(seqdata.analogchannels);
        channel_names{j} = ['d' num2str(didx) '  ' seqdata.digchannels(didx).name];
    else
        disp('Empty adwin list for this channel. Assume 0 voltage');
    end
    
    if(~isempty(channel_data))
    
        %sort data by time
        [tempdata sort_index] = sort(channel_data(:,1));
        channel_data = channel_data(sort_index,:);

        %set the times into real units (not update cycles)
        channel_data(:,1) = channel_data(:,1)*seqdata.deltat/seqdata.timeunit;
        
        %Add in the min and max times for the plot.
        channel_data = [Min_Time channel_data(end,2:end); channel_data; Max_Time channel_data(end,2:end)];

        %Include both the start time and the end time for a particular adwin
        %voltage in channel_data.
        temp_channel_data = channel_data;
        channel_data = zeros(2 * size(channel_data,1) - 1, size(channel_data, 2));
        channel_data(1:2:end,:) = temp_channel_data;
        channel_data(2:2:end,:) = [temp_channel_data(2:end,1) temp_channel_data(1:end-1,2:3)];       
        
%         channel_data = [channel_data; [channel_data(2:end,1); channel_data(1,1)] channel_data(:,2:3)];
%         channel_data = sortrows(channel_data,1);
        
    else
        
        channel_data = [Min_Time channels(j) 0; Max_Time channels(j) 0];
        
    end
        
    %Determine the start and end times for all ramps in the channel
    %voltages.
    if(~isempty(seqdata.ramptimes))
        Channel_Ramps = seqdata.ramptimes((seqdata.ramptimes(:,1) == channels(j)), 2:3)*seqdata.deltat/seqdata.timeunit;
    else
        Channel_Ramps = [];
    end

    %Reduce the number of data points in ramps.
    if(~isempty(Channel_Ramps))
        for Counter = 1:size(Channel_Ramps,1)
            Initial_Point = find(channel_data(:,1) == Channel_Ramps(Counter,1));
            Initial_Point = Initial_Point(1);
            Final_Point = find(channel_data(:,1) == Channel_Ramps(Counter,2));
            Final_Point = Final_Point(end);
            new_channel_data = channel_data(round(Initial_Point : (Final_Point - Initial_Point) / Divisions : Final_Point), : );
            channel_data(Initial_Point : Final_Point, : ) = [ ];
            channel_data = [channel_data(1 : Initial_Point - 1, :); new_channel_data; channel_data(Initial_Point : end, :)];
        end
    end
        
%         %Create a subset of channel_data for use in plotting.
%         Plot_Data = channel_data((channel_data(:,1) >= Min_Time & channel_data(:,1) <= Max_Time), [1 3]);
% 
%         %Add values at min time and max time.
%         Max_Data = channel_data((channel_data(:,1) <= Max_Time),:);
%         if(~isempty(Max_Data))
%             Plot_Data = [Plot_Data; Max_Time Max_Data(end, 3)];
%         else
%             Plot_Data = [Plot_Data; Max_Time channel_data(end, 3)];
%         end
% 
%         Min_Data = channel_data((channel_data(:,1) <= Min_Time),:);
%         if(~isempty(Min_Data))
%             Plot_Data = [Min_Time Min_Data(end, 3); Plot_Data];
%         else
%             Plot_Data = [Min_Time channel_data(end, 3); Plot_Data];
%         end
                
%         Plot_Data = [Min_Time 0; Max_Time 0];
    
    Plot_Data = channel_data( : , [1 3]);

    subplot(ceil(length(channels)/2), 2, j);
    plot(Plot_Data(:,1)/1000,Plot_Data(:,2),'LineWidth',3);
    title([channel_names{j}]);
    grid on;
    set(gca, 'XLim', [Axis_Min Axis_Max]);

    if channel_type(j)==0 %digital channel
    %set the axes to go from -0.5:1.5 with only a tick at 0 and 1
        axis([0 1 -0.1 1.1]);
        axis 'auto x'
        set(gca, 'XLim', [Axis_Min Axis_Max]);
        set(gca,'ytick',(-0:0.25:1));
    end
    
    disp('Done Plotting')

end

%     
%     
%     %Get the value of the channel at the times indicated for the plot. For
%     %a given time always look to see the last PREVIOUS time that the
%     %channel was updated
%     cur_value = 0; %assume the channel is initially 0
%     cur_index = 0;
%     if isempty(channel_data)
%         plot_values(j,:) = 0;
%     else
%         for k = 1:length(plot_values(j,:))
%             if (cur_index>=0)
%                 if (channel_data(cur_index+1,1)>times(k))
%                     if cur_index>0
%                         cur_value = channel_data(cur_index,3);
%                     end
%                     plot_values(j,k) = cur_value;
%                 else
%                    for kk=(cur_index+1):length(channel_data(:,1))
%                        if channel_data(kk,1)>times(k)
%                            cur_index = kk-1;
%                            cur_value = channel_data(cur_index,3);
%                            plot_values(j,k) = cur_value;
%                            break
%                        end
%                        cur_index = -1;
%                        cur_value = channel_data(end,3);
%                        plot_values(j,k) = cur_value;
%                    end                  
%                 end
%             else
%                 plot_values(j,k) = cur_value;
%             end
%         end
%     end
%     %Get channel name if possible
%     %channel_names(j) = {seqdata.analogchannels(channels(j)).name};
%     
% end
% 
% %want to put these into separate plots on the same figure
% %note that only the bottom one needs the time labels
% plothnd = figure;
% set(plothnd,'UserData',159);
% num_plots = length(channels);
% plot_height = 0.9/num_plots;
% 
% for j = 1:length(channels);
%     h = axes('position',[0.1 1-j*plot_height 0.7 plot_height*0.9]);
%     plot(times,plot_values(j,:));
%     
%     if channel_type(j)==0 %digital channel
%         %set the axes to go from -0.5:1.5 with only a tick at 0 and 1
%         axis([0 1 -0.5 1.5]);
%         axis 'auto x'
%         set(h,'ytick',[0 1]);
%     end
%     
%     if j~=length(channels)
%         set(h,'xticklabel',[]);
%     end
%     
% %     annotation('textbox',[0.81 1-j*plot_height+plot_height/8 0.185 plot_height*5/8],'string',['Channel ' num2str(channels(j))  ]);  
%    annotation('textbox',[0.81 1-j*plot_height+plot_height/8 0.185 plot_height*5/8],'string',[channel_names{j} ]);  
% end
% 
% %plot all the time traces on one plot
% plothnd2 = figure;
% set(plothnd2,'UserData',159);
% hold all;
% for j = 1:length(channels)
%     plot(times,plot_values(j,:));
% end
% hold off;
% 
% %tile the windows
% plot1_pos = get(plothnd,'Position');
% plot2_pos = get(plothnd2,'Position');
% 
% set(plothnd2,'Position',[plot2_pos(1),plot1_pos(2)-plot2_pos(4)-100,plot2_pos(3),plot2_pos(4)]);
% 
% disp('Done Plotting')
% 
% 
% 
% end