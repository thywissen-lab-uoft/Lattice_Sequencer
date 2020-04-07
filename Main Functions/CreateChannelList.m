function [ana, dig] = CreateChannelList(seqdata)

% Creates channel list for analog and digital channels as cell array. Can
% be watched in the variable editor for debugging purposes.

    ana = cell(length(seqdata.analogchannels),2);
    dig = cell(length(seqdata.digchannels),2);

    for j = 1:length(seqdata.analogchannels);
        ana{j,1}=j;
        ana{j,2}=seqdata.analogchannels(j).name;
    end

    for j = 1:length(seqdata.analogchannels);
        dig{j,1}=j;
        dig{j,2}=seqdata.digchannels(j).name;
    end
    
end

