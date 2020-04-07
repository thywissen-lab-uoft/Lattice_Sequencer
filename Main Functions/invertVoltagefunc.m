function varargout = invertVoltagefunc(seqdata,channel,voltage,voltagefuncindex,guess)
% USAGE : [value, check] = invertVoltagefunc(seqdata,channel,voltage,voltagefuncindex,guess)
%
% Inverts a 'channel's voltage function to find the command 'value' that
% gives the respective adwin 'voltage' for the respective
% 'voltagefuncindex'. This function uses fminsearch and can be given an
% initial guess to ensure convergence. 'Check' gives the adwin voltage for
% the found 'value'.

    if ~exist('guess','var'); guess = 1; end
    
    if ( ischar(channel) ) % channel name lookup
        channel = name_lookup(channel,1);
    end

    options = optimset('TolX',1e-8);
    
    fun = @(val,volts)((seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(val)-volts).^2);
    value = fminsearch(fun, guess, options, voltage);
    
    varargout(1) = {value};
    
    if nargout == 2;
        varargout(2) = {seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(value)};
    end
     

end

