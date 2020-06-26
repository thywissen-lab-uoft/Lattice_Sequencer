%------
%Author: DJ
%Created: July 2010
%Summary: This function makes a minimum jerk curve in which the there is a
%middle section where the velocity is nonzero
%------

function y = for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)

%time and distance are both zero
if t1==0 && d1==0 && dm==0 && tm==0 && d2==0 && t2==0
    y = 0;
    return;
end

%preallocate array
y = zeros(size(t));

%Go through each of the array elements
for i=1:length(y)

%Calculate distance curve based on what time it is:
    if (t(i)>=0) && (t(i)<t1);
        
        y(i) = (10*d1/t1^3-4*dm/tm/t1^2)*t(i)^3+(-15*d1/t1^4+7*dm/tm/t1^3)*t(i)^4+(6*d1/t1^5-3*dm/tm/t1^4)*t(i)^5;
        
    elseif (t(i) >= t1 ) && (t(i) < tm+t1);
        
        y(i) = d1+dm/tm*(t(i)-t1);

    elseif (t(i) >= t1 + tm ) && (t(i) < tm+t1 + t2);
        
        y(i) = d1+dm+d2-((10*d2/t2^3-4*dm/tm/t2^2)*(abs(t(i)-t1-tm-t2))^3+(-15*d2/t2^4+7*dm/tm/t2^3)*(abs(t(i)-t1-tm-t2))^4+...
            (6*d2/t2^5-3*dm/tm/t2^4)*(abs(t(i)-t1-tm-t2))^5);
        
        
    end
end



if sum(isnan(y))~=0
    
    error('Minimum Jerk Returns NAN value');
    
end


end