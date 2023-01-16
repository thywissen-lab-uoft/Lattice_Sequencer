%------
%Function call
%Author: Stefan Trotzky
%Created: May 2014
%Summary: Executes a sequence of FB coil and zShim coil pulses aimed at
%   demagnetizing magnetized components near the chamber. To be called at
%   the end of a cycle before next cycle starts. Can in principle run
%   during MOT. Function assumes that FB field has been ramped to zero
%   before. Note: this is fairly brutal on the FB fast switch and may
%   decrease its lifetime.
%------
function timeout = demagnetize_chamber(timein)

global seqdata;

curtime = calctime(timein,0);

    FB_high = 22.6; % where to start with the field pulses
    FB_pulselength = 5; % length of each current pulse (ms)
    FB_pulsesep = 5; % time between pulses (ms)
    FB_pulses_hi = 10; % number of pulses to do with the FB coils
    FB_pulses_exp = 15; % number of pulses to do with the FB coils
    FB_current_tau = 25; % tau with which current pulses are reduced in amplitude
    FB_waittime = FB_pulses_hi*(FB_pulselength+FB_pulsesep);
    FB_ramptime = FB_pulses_exp*(FB_pulselength+FB_pulsesep);

    % Close FB fast switch and set analog value high.
    SetDigitalChannel(calctime(curtime,0),31,0);
    setAnalogChannel(calctime(curtime,0),37,FB_high);
    
    % Some value to let the FB set value settle (is low-pass filtered)
curtime = calctime(curtime,20);

    % Exponentially ramping down the FB set value
    AnalogFuncTo(calctime(curtime,FB_waittime),37,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),FB_ramptime,FB_ramptime,0,FB_current_tau);
    % Pulse FB coil with fast switch
    ScopeTriggerPulse(curtime,'Demag pulses');
    for j = 1:(FB_pulses_hi+FB_pulses_exp)
        DigitalPulse(calctime(curtime,(j-1)*(FB_pulselength+FB_pulsesep)),31,FB_pulselength,1);
    end
curtime = calctime(curtime,FB_ramptime+FB_waittime);

    zShimVal = getChannelValue(seqdata,'Z Shim',1);
    zShim_ramptime = 200;
    zShim_amplitude = 1.2;
    zShim_frequency = 0.2;

    ramp_fun = @(t,tt,A,f)(A*sqrt(2*exp(1))*(4*t/tt).*exp(-(4*t/tt).^2).*sin(2*pi*f*t));
    
curtime = AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,A,f)(ramp_fun(t,tt,A,f)+zShimVal),zShim_ramptime,zShim_ramptime,zShim_amplitude,zShim_frequency,3);
    
    
timeout = calctime(curtime,0);

end