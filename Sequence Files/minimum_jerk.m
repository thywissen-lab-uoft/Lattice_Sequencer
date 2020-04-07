%------
%Author: DJ
%Created: October 2009
%Summary: This function makes a minimum jerk curve
%------

function y = minimum_jerk(t,tt,dt)
                            %t is the time unit, tt is the total time of
                            %the ramp, dt is the maximum value to ramp to
                            %from zero

%time and distance are both zero
if tt==0 && dt==0
    y = 0;
    return;
end

if tt==0 && dt~=0
    error('In min jerk must have finite time to go finite distance');
end


y = (10*dt/tt^3)*t.^3 - (15*dt/tt^4)*t.^4 + (6*dt/tt^5)*t.^5;

if sum(isnan(y))~=0
    
    error('Minimum Jerk Returns NAN value');
    
end


end