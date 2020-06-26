function [aTraces, dTraces]=generateTraces(seqdata)
%GENERATETRACES Summary of this function goes here
%   Detailed explanation goes here

aTraces=struct;
dTraces=struct;

for kk=1:length(seqdata.analogchannels)
    chnum=seqdata.analogchannels(kk).channel;
    name=seqdata.analogchannels(kk).name;
    inds=find(seqdata.analogadwinlist(:,2)==chnum);
    aTraces(kk).channel=chnum;
    aTraces(kk).name=name;
    aTraces(kk).data=[seqdata.analogadwinlist(inds,1) ...
        seqdata.analogadwinlist(inds,3)];
end

for kk=1:length(seqdata.digchannels)
    chnum=seqdata.digchannels(kk).channel;
    name=seqdata.digchannels(kk).name;
    inds=find(seqdata.digadwinlist(:,2)==chnum);
    dTraces(kk).channel=chnum;
    dTraces(kk).name=name;
    dTraces(kk).data=[seqdata.digadwinlist(inds,1) ...
        seqdata.digadwinlist(inds,3)];
end

end

