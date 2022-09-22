function varargout = getChannelValue(sequencedata,channel,isanalog,isrealvoltage)
% varargout = getChannelValue(sequencedata,channel,isanalog,isrealvoltage)
%
% Gives last value set for specific channel (careful: this may not be
% the value set closest to curtime). For digital channels, output is 
% [value time] for analog channels output is [value voltagefunc voltage
% time] for isrealvoltage=0 and [voltage value voltagefunc time] for 1.
% ST-2013-03-02

if ~exist('isanalog','var') % default: attempt to read an analog-channel value
    isanalog = 1;
end

if ~exist('isrealvoltage','var') % default: give back last software set value instead adwin voltage
    isrealvoltage = 0;
end

if ( ischar(channel) ) % channel name lookup
    name = channel;
    channel = name_lookup(channel,isanalog);
else
    name = '';
end

out = NaN; % set to NaN to check for success at the end

if ( isanalog ) % get last value for an analog channel
    chstr = 'analog';
    if isfield(sequencedata.params,'analogch')
        if size(sequencedata.params.analogch,1) >= channel
            out = sequencedata.params.analogch(channel,:);
        end
    end
else
    chstr = 'digital'; % get last value for a digital channel
    if isfield(sequencedata.params,'digitalch')
        if length(sequencedata.params.digitalch) >= channel
            out = sequencedata.params.digitalch(channel,:);
        end
    end
end

if isnan(out) % check whether out was set to a numerical value after all
    warning(sprintf(['getChannelValue :: No value found for ' chstr ... 
        ' channel #%g (' name '). Will assume original output is zero!'],channel));
%     if (isanalog)
%        out = [0 1 0 0];
%     else 
%         out = [0 0 0];
%     end
end

if ( ~(isrealvoltage) && (isanalog) ) % reorder output if last setvalue was requested and not the last adwin voltage
   if length(out) == 3
       out = out([2 3 1]);
   else
       out = out([2 3 1 4]);
   end
end

for j = 1:max(nargout,1)
    varargout(j) = {out(j)};
end


end