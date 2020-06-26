%------
%Author: DJ
%Created: October 2009
%Summary: This function makes a minimum jerk curve; modified: ST 2014-03-12
%         Now, it also adds a sinusoidal modulation on top
%------

function out = ramp_minjerk_mod(t,tt,y1,y2,A,f)
% ramp_exponential(t,tt,initial,final)

if tt==0 && (y2-y1)==0
    y = 0;
    return;
end

if tt==0 && dt~=0
    error('In min jerk must have finite time to go finite distance');
end


out = y1 + (10*(y2-y1)/tt^3)*t.^3 - (15*(y2-y1)/tt^4)*t.^4 + (6*(y2-y1)/tt^5)*t.^5 + A*sin(2*pi*f*t);

if sum(isnan(out))~=0
    error('Minimum Jerk Returns NAN value');
end


end