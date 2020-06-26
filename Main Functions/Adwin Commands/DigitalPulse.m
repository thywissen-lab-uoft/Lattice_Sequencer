%------
% timeout = DigitalPulse(timein,channel,pulsetime,setting)
%Author: David McKay
%Created: July 2009
%Summary: Do a digital pulse, pulsetime is in natural time units (ie. ms).
%Setting is the for the pulse (ie. 1 makes a high pulse)
%------
function timeout = DigitalPulse(timein,channel,pulsetime,setting)

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

if pulsetime<=0
    error('Pulsetime must be positive and non-zero')
end

%recalc pulse time in cycle counts
pulsetime = calctime(timein,pulsetime);

seqdata.digadwinlist(end+1,:) = [timein channel setting seqdata.digcardchannels(seqdata.digchannels(channel).cardid) ...
    seqdata.digchannels(channel).bitpos];

seqdata.digadwinlist(end+1,:) = [pulsetime channel ~setting seqdata.digcardchannels(seqdata.digchannels(channel).cardid) ...
    seqdata.digchannels(channel).bitpos];

seqdata.params.digitalch(channel,:) = [~setting pulsetime];

timeout = pulsetime;

end

