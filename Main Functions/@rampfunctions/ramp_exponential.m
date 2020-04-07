function out = ramp_exponential(t,tt,y1,y2,tau)
% ramp_exponential(t,tt,initial,final,tau)

    if nargin == 4; tau = tt; end
    
    out = (y1-y2)*(exp(-t/tau)-exp(-tt/tau))/(1-exp(-tt/tau)) + y2;
        
end
