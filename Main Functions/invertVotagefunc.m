function [value, varargout] = invertVotagefunc(seqdata,channel,voltage,voltagefuncindex, guess)
% Inverts an analog 'channel's voltage function to find specific output
% 'voltage'. Uses fminsearch and an initial 'guess' (default: 1) to do so.
% ST-2014-03-14

    if ~exist('guess','var'); guess = 1; end
    
    if ( ischar(channel) ) % channel name lookup
        channel = name_lookup(channel,1);
    end

    options = optimset('TolX',1e-8);
    
    % squared difference
    fun = @(val, volts) ((seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(val) - volts).^2);
    
    % finding input value
    val = fminsearch(fun, guess, voltage, options);
   
    value = val;
    
    if nargout == 2
        varargout{1} = {seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(value)};
    end
    

end