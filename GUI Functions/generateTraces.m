function [aTraces, dTraces]=generateTraces(seqdata)
%GENERATETRACES Summary of this function goes here
%   Detailed explanation goes here

disp('Generating digital and analog time traces from seqdata.');

aTraces=struct;
dTraces=struct;

aTraces=seqdata.analogchannels;
aTraces(1).data=[];

dTraces=seqdata.digchannels;
dTraces(1).data=[];


for kk=1:length(aTraces)
    chnum=aTraces(kk).channel;
    inds=find(seqdata.analogadwinlist(:,2)==chnum);  
    aTraces(kk).data=[seqdata.analogadwinlist(inds,1) ...
        seqdata.analogadwinlist(inds,3)];
end

for kk=1:length(dTraces)
    chnum=dTraces(kk).channel;
    inds=find(seqdata.digadwinlist(:,2)==chnum);
    dTraces(kk).data=[seqdata.digadwinlist(inds,1) ...
        seqdata.digadwinlist(inds,3)];
end

end

