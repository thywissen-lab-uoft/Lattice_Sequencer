%------
%Author: Stefan Trotzky
%Created: March 2014
%Summary: Clears all scope triggers (ch12) that are set in the cycle build
%       so far. To help with scope triggering for diagnostics
%------

function out = test_sequence(seqdata)

out = seqdata;

ch_scope = 12; % channel 12 is the scope trigger

for j = 1:length(ch_scope) % remove all changes of schope trigger channels from the digadwinlist
    out.digadwinlist(out.digadwinlist(:,2)==ch_scope(j),:) = [];
end

end
