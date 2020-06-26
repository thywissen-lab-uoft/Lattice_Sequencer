%------
%Author: David McKay
%Created: July 2009
%Summary: Stops the current cycle of ADWIN programs. NOTE: If there is a
%current program running it stops after that run is finished. Use
%abort_process() to kill a program while its running and reset all the
%channels
%------
function stop_process()

global docycle;

curstatus = getRunStatus();

switch curstatus
    case 1 %not running
        disp('Nothing to Stop');
    case 2 %waiting
        CleanUpTimers();
        disp('Wait period interrupted, cycling stopped.');
    case 3 %running
        docycle = 0;
        disp('Cycling will stop after the current process is finished executing.');
end

end