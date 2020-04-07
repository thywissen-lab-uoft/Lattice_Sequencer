function out = ramp_linear(t,tt,y1,y2)
% ramp_linear(t,tt,initial,final)

    out = y1 + (y2-y1)*t/tt;
    
end