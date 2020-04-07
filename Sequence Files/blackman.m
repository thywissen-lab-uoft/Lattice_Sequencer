%------
%Author: ge
%Created: Sept 2013
%Summary: This function gives a Blackman pulse of length tau 
%    reaching max Pmax
%------

function y = blackman(t,tau,Pmax)

%time and distance are both zero
if tau==0 && Pmax==0
    y = 0;
    return;
end

if tau==0 && Pmax~=0
    error('Blackman pulse must have finite length!');
end


y = Pmax * (0.42323 + 0.49755*cos(2*pi*(t-tau/2)/tau) + 0.07922*cos(4*pi*(t-tau/2)/tau));

if sum(isnan(y))~=0  
    error('Blackman has somehow evaluated to NAN?');  
end


end