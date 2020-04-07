function out = ramp_exp(t,tt,tau,y2,y1)

    out = (y1+(y2-y1)/(exp(tt/tau)-1)*(exp(t/tau)-1));

end