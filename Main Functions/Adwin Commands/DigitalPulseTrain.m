%------
%Author: David McKay
%Created: July 2009
%Summary: Do a digital pulse, pulsetime is in natural time units (ie. ms).
%Setting is the for the pulse (ie. 1 makes a high pulse)
%------
function timeout = DigitalPulseTrain(timein,channel,pulsetime,offtime,n_repetitions,setting)

global seqdata;

%% Do all of the if statements once

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

%% Calculate pulse train


repetition_time = pulsetime + offtime;

for i=1:n_repetitions
    
    %recalc pulse time in cycle counts
    t_on = calctime(timein,(i-1)*repetition_time);
    t_off = calctime(timein,(i-1)*repetition_time + pulsetime);

    seqdata.digadwinlist(end+1,:) = [t_on channel setting seqdata.digcardchannels(seqdata.digchannels(channel).cardid) ...
        seqdata.digchannels(channel).bitpos];

    seqdata.digadwinlist(end+1,:) = [t_off channel ~setting seqdata.digcardchannels(seqdata.digchannels(channel).cardid) ...
        seqdata.digchannels(channel).bitpos];

    %Update list of dig channel changes?
    seqdata.params.digitalch(channel,:) = [~setting (i-1)*repetition_time + pulsetime];

end

timeout = (n_repetitions-1)*repetition_time + pulsetime;

end

