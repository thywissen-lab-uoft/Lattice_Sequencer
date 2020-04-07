%------
%Author: Stefan Trotzky
%Created: March 2014
%Summary: Sets a scopoe trigger pulse. Pulses set this way are documented
%in seqdata
%------

function ShowScopeTriggers()
global seqdata

    if ~isfield(seqdata,'scopetriggers')
        disp('No trigger pulses set. Use ScopeTriggerPulse() to set documented triggers.')
    else
        disp('time , channel , length , tag ')
        for j = 1:length(seqdata.scopetriggers)
            disp(sprintf(['%gms , ch%g , %gms , ' seqdata.scopetriggers{j}{3}],...
                seqdata.scopetriggers{j}{1}*seqdata.deltat/seqdata.timeunit, ...
                seqdata.scopetriggers{j}{2},seqdata.scopetriggers{j}{4}));
        end
    end
    
end
