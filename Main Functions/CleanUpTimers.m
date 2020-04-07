%------
%Author: David McKay
%Created: July 2009
%Summary: Stop, delete and clear all timers
%------

function CleanUpTimers()

global wait_timer;
global adwin_process_timer;

if ~isempty(wait_timer) %wait timer is empty, either nothing is going on or the ADWIN is running
    if isvalid(wait_timer)
        %stop the timer
        if strcmp(get(wait_timer,'running'),'on')
            stop(wait_timer)
        end
        %delete the timer
        delete(wait_timer);
    end
    
    %clear the timer
    clear wait_timer;
end

if ~isempty(adwin_process_timer) %wait timer is empty, either nothing is going on or the ADWIN is running
    if isvalid(adwin_process_timer)
        %stop the timer
        if strcmp(get(adwin_process_timer,'running'),'on')
            stop(adwin_process_timer)
        end
        %delete the timer
        delete(adwin_process_timer);
    end
    
    %clear the timer
    clear adwin_process_timer;
end

end