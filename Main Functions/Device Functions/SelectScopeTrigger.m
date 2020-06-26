%------
%Author: Stefan Trotzky
%Created: March 2014
%Summary: Sets a scopoe trigger pulse. Pulses set this way are documented
%in seqdata
%------

function SelectScopeTrigger(tag, rem)
global seqdata

use_all = 0;
keep_all = 0;

if ~exist('rem','var'); 
    rem = 'none';
end

if ischar(tag); 
    if strcmpi(tag, 'all')
        use_all = 1; 
    end
    tag = {tag}; 
end

if ischar(rem); 
    if strcmpi(tag, 'none')
        keep_all = 1; 
    end
    rem = {rem}; 
end
    
if ~isfield(seqdata,'scopetriggers')
    disp('SelectScopeTrigger::warning -- No trigger pulses set (doing nothing). Use ScopeTriggerPulse() to set documented triggers.')
else
    if ~use_all
        found_one = 0;
        for i = 1:length(tag)
            this_tag = tag{i};
            j = 0; found = 0;
            % look for named trigger and read in values from first occurence
            while ( ~found && j<length(seqdata.scopetriggers) ) 
                j=j+1;
                if ( strcmpi(seqdata.scopetriggers{j}{3},this_tag) )
                    curtime = seqdata.scopetriggers{j}{1};
                    channel = seqdata.scopetriggers{j}{2};
                    pulse_length = seqdata.scopetriggers{j}{4};
                    found = 1;
                end
            end
            if ( found )
                % remove all triggers (= changes on ch12) and add only the
                % selected trigger pulse
                if ~found_one 
                    seqdata = clearAllScopeTriggers(seqdata);
                    found_one = 1;
                end
                DigitalPulse(calctime(curtime,0),channel,pulse_length,1);
            else
                disp(['SelectScopeTrigger::warning -- Trigger pulse ''' this_tag ''' not found. Use ScopeTriggerPulse() to set documented triggers.'])
            end
        end
    else
        if ~keep_all
            buildWarning('SelectScopeTrigger','Trigger removal option not implemented, yet.')
            for i = 1:length(rem)
                this_tag = rem{i};
                j = 0; found = 0;
                % look for named trigger and read in values from first occurence
                while ( ~found && j<length(seqdata.scopetriggers) ) 
                    j=j+1;
                    if ( strcmpi(seqdata.scopetriggers{j}{3},this_tag) )
                        found = j;
                    end
                end
                if ( found )
                    % remove all triggers (= changes on ch12) and add only the
                    % selected trigger pulse
                else
                end
            end
        end
    end
end
