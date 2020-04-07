%------
%Author: Stefan Trotzky
%Function call: timeout = ScopeTriggerPulse(timein, tag, pulse_length,channel)
%Created: March 2014
%Summary: Sets a scopoe trigger pulse. Pulses set this way are documented
%in seqdata
%------

function timeout = ScopeTriggerPulse(timein, tag, pulse_length, channel)
global seqdata

    if nargin == 1
    else
        if ~ischar(tag); 
            if nargin == 3;
                channel = pulse_length;
            end
            pulse_length = tag; 
        end
    end

    if ~exist('pulse_length','var'); 
        pulse_length = 1; 
    end

    if ~exist('channel','var'); 
        channel = 12; 
    end
    
timeout = DigitalPulse(calctime(timein,0),channel,pulse_length,1);

    add = {timein, channel, tag, pulse_length};
    if ~isfield(seqdata,'scopetriggers')
        seqdata.scopetriggers = {add};
    else
        seqdata.scopetriggers{end+1} = add;
    end
end
