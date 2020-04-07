%------
%Author: David McKay
%Created: July 2009
%Summary: Kills the current program in an emergency (ie coil is
%overheating) and resets all the lines to 0
%------

%NOT TESTED
function abort_process()

global adwinprocessnum;
global adwin_connected;

curstatus = getRunStatus();

switch curstatus
    case 1 %not running
        disp('Nothing to Abort');
    case 2 %waiting
        CleanUpTimers();
        disp('Wait period interrupted, cycling stopped.');
    case 3 %running
        CleanUpTimers();
        if adwin_connected
            Stop_Process(adwinprocessnum);
        end
        disp('Process Aborted!!');
end

disp('Resetting the ADWIN');

%need to wait about a second here for some reason or else the reset won't
%work properly
pause(0.5);

%reset all the channels
resetADWIN();

end