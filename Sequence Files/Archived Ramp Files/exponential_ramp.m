%------
%Author: ST
%Created: January 2013
%Summary: This function makes an exponential curve
%------

function y = exponential_ramp(t,tt,dt,tau)

%time and distance are both zero
if tt==0 && dt==0
    y = 0;
    return;
end

if tt==0 && dt~=0
    error('In exponential ramp must have finite time to go finite distance');
end

y = dt*(exp(-t/tau)-exp(-tt/tau))/(1-exp(-tt/tau));

if sum(isnan(y))~=0
    
    error('Exponential Ramp Returns NAN value');
    
end


end