function buildWarning(source, msgstring, aserror)
%
%   buildMessage(source, msgstring)
%
% To throw a message to a message window for debugging
% -- S. Trotzky, April 2014
%
global seqdata
    
    if isfield(seqdata,'debug'); if (seqdata.debug)
        disp([source '::msg -- ' msgstring]);
        % to do: add a window into which to plot the messages
    end; end

end