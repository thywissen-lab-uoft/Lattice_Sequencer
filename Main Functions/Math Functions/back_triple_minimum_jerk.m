%------
%Author: DJ
%Created: July 2010
%Summary: This function makes a minimum jerk curve in which the there is a
%middle section where the velocity is nonzero
%------

function y = back_triple_minimum_jerk(t,D1,T1,D2,T2,D3,T3)

%time and distance are both zero
if D1==0 && T1==0 && D2==0 && T2==0 && D3==0 && T3==0
    y = 0;
    return;
end

%preallocate array
y = zeros(size(t));

%redefine distances

d1=-D3;
 d2=-D2;
 d3=-D1;

%redefine time
 t1=T3;
 t2=T2;
 t3=T1;

%Go through each of the array elements
for i=1:length(y)

%Calculate distance curve based on what time it is:
    if (t(i)>=0) && (t(i) < t1);
        
        y(i) = -(d1+d2+d3) + ((10*d1)/t1^3 - (4*d2)/(t1^2*t2))*t(i)^3 + (-((15*d1)/t1^4) + (7*d2)/(t1^3*t2))*t(i)^4 + ((6*d1)/t1^5 - (3*d2)/(t1^4*t2))*t(i)^5;
    
    elseif (t(i) >= t1 ) && (t(i) < t1 + t2);
        
        y(i) = -(d1+d2+d3)+d1 + (d2*(-t1 + t(i)))/t2 - (4*(-(d2/t2) + d3/t3)*(-t1 + t(i))^3)/t2^2 +...
            (7*(-(d2/t2) + d3/t3)*(-t1 + t(i))^4)/t2^3 - (3*(-(d2/t2) + d3/t3)*(-t1 + t(i))^5)/t2^4;

    elseif (t(i) >= t1 + t2 ) && (t(i) < t1 + t2+ t3);
        
        y(i) = -(d1+d2+d3)+d1 + d2 + (d3*(-t1 - t2 + t(i)))/t3 + (4*d3*(-t1 - t2 + t(i))^3)/t3^3 - (7*d3*(-t1 - t2 + t(i))^4)/t3^4 +...
            (3*d3*(-t1 - t2 + t(i))^5)/t3^5;
        
        
    end
end



if sum(isnan(y))~=0
    
    error('Minimum Jerk Returns NAN value');
    
end


end