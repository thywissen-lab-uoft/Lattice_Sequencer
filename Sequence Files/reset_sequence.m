%------
%Author: David McKay
%Created: July 2009
%Summary: Resets all the channels
%------
function timeout = reset_sequence(timein)

global seqdata;

curtime = timein;

%reset all the lines
for i = 1:length(seqdata.analogchannels)
    setAnalogChannel(curtime,i,0,1);
end

for i = 1:length(seqdata.digchannels)
    setDigitalChannel(curtime,i,0);
end

%If a special 'reset value' is specified in initialize_channels, set channel
%to that rather than zero
Reset_Channels(calctime(curtime,0))

%when we incorporate DDS lines, send resets to all those switches

timeout = curtime;

end