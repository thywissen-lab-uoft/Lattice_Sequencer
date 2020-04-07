function out = ramp_exp_lat(t,tt,tau,yf,yi)
% tt: total ramp time, tau: exp_tau
% from yi, ramp to yf

if yf > yi
    out = (yi+(yf-yi)/(exp(tt/tau)-1)*(exp(t/tau)-1));
else
    out = yf+sign(yf-yi)*(yf-yi)/(exp(tt/tau)-1)*(exp((tt-t)/tau)-1);
end

end
