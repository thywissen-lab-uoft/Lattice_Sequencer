%------
%Author: David McKay
%Created: July 2009
%Summary: Get the current status of the program exection
%------

function y = getRunStatus()

%return 1 if the program is doing nothing
%return 2 if the program is waiting between cycles
%return 3 if the program is executing


global wait_timer;
global adwin_process_timer;

if isempty(wait_timer)||(~isvalid(wait_timer)) %wait timer is empty, either nothing is going on or the ADWIN is running
    if isempty(adwin_process_timer)||(~isvalid(adwin_process_timer))
        y = 1;
    elseif strcmp(get(adwin_process_timer,'running'),'on')
        y = 3;
    else
        y = 1;
    end
elseif strcmp(get(wait_timer,'running'),'on') %wait timer is running
    y = 2;
else %wait timer is not running
    if isempty(adwin_process_timer)||(~isvalid(adwin_process_timer)) %ADWIN process doesn't exist
        y = 1;
    elseif strcmp(get(adwin_process_timer,'running'),'on') %ADWIN is running
        y = 3;
    else
        y = 1;
    end
end

end