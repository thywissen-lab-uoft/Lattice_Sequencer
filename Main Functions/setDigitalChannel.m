%------
%Author: David McKay
%Created: July 2009
%Summary: Set the digital channel at 'timein' to 'setting' (must be 1 or 0)
%------
function timeout = setDigitalChannel(timein,channel,setting)

global seqdata;

if ( ischar(channel) ) % ST-2013-03-02 // channel name lookup feature
    channel = name_lookup(channel,0);
end

%check this is a valid digital channel
if ~(channel>0 || channel<=length(seqdata.digchannels))
    error('Invalid digital channel');
end

%setting can only be 0 or 1
if ~(setting==0 || setting==1)
    error('Digital channels can only accept 1 or 0');
end

seqdata.digadwinlist(end+1,:) = [timein channel setting seqdata.digcardchannels(seqdata.digchannels(channel).cardid) ...
    seqdata.digchannels(channel).bitpos];
seqdata.params.digitalch(channel,:) = [setting timein];

timeout = timein;

end

