function [t, y, vals] = dummySequence(fhandle, cycle, channels, times);
    
    % rotate input vectors if necessary
    if size(times,1) > 1; times = times'; end
    if size(channels,1) > 1; channels = channels'; end
    ch = [channels channels(end)];

    % initialize output arrays
    [t, y] = meshgrid(times, 1:(length(channels)+1));
    vals = NaN*t;
    
    for j = 1:length(ch)
        thisCh = ch(j);
        if ( (thisCh > 0)&&(thisCh <= 10) )
            vals(j,:) = sin(2*pi*thisCh*times);
        else
            vals(j,:) = 20*(sin(2*pi*(thisCh-9)*times)>0) - 10;
        end
    end
    
end