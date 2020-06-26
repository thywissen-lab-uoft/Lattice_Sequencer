%------
%Author: David McKay
%Created: July 2009
%Summary: This is the default function for when the sequence stops
%------

function default_seq_stopped(obj,event)

%display that the process has been completed
disp('ADWIN Sequence completed');

%delete the timer
stop(obj)
delete(obj);

end