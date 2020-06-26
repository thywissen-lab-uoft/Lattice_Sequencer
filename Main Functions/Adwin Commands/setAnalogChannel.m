%------
%Function call: timeout = setAnalogChannel(timein,channel,setting,voltagefuncindex)
%Author: David McKay
%Created: July 2009
%Summary: Set the Analog Channel at time 'timein' to 'setting'.
%voltagefuncindex is an index to the voltage conversion function to use. The
%default is 1, which is that the input is the channel voltage.
%------
function timeout = setAnalogChannel(timein,channel,setting,voltagefuncindex)

global seqdata;

if ( ischar(channel) ) % ST-2013-03-02 // channel name lookup feature
    channel = name_lookup(channel,1);
end

%check this is a valid channel
if (channel<0 || channel>length(seqdata.analogchannels))
    error('Invalid analog channel');
end

%default to the first voltage 
if nargin<4 && channel~=0
    voltagefuncindex = seqdata.analogchannels(channel).defaultvoltagefunc;
end


if channel==0 %transport
    seqdata.analogadwinlist = [seqdata.analogadwinlist; transport_coil_currents(timein,setting)];
else
    
    newvalue = seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(setting);
    
    %check this is a valid value
    if (newvalue<seqdata.analogchannels(channel).minvoltage || newvalue>seqdata.analogchannels(channel).maxvoltage)
        error('Invalid analog channel voltage');
    end

    seqdata.analogadwinlist(end+1,:) = [timein channel newvalue];
    seqdata.params.analogch(channel,1:4) = [newvalue setting voltagefuncindex timein];
end

timeout = timein;

end

