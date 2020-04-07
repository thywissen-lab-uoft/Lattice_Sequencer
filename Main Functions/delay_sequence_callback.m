%------
%Author: Stefan Trotzky
%Created: February
%Summary: This is the callback function for delaying the start of a cycle
%------
% Working with the existing code here, aiming at minimal conceptual change.
% There may be better ways to code this!
function delay_sequence_callback(obj,event,curcycle,endcycle,fhandle,waittime,targettime)

global seqdata

    run_sequence({@cycle_sequence_callback,curcycle,endcycle,fhandle,waittime,targettime,0});

end