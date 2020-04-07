%------
%Author: David McKay
%Created: April 2012
%Summary: Lienar Ramp of Final QP
%------

function timeout = ramp_qp(timein,I0,I1,ramp_time, v0_override)

%I0,I1 are three vectors [kitten,bleed,coil16]
curtime = timein;

if nargin < 5
    v0_override = -1; %this is an override for the start value of the voltage
end

r_coil = 0.345;

%do a quick check of currents
t = 0:ramp_time;

I_bleed = I0(2) + (I1(2)-I0(2))*t/ramp_time;
I_16 = I0(3) + (I1(3)-I0(3))*t/ramp_time;
I_kitt = I0(1) + (I1(1)-I0(1))*t/ramp_time;
Vsupp = r_coil*(2*I_16-I_kitt+I_bleed)+0.75 +2.25; %dylan added + 2.25 for 300G/cm (coil wasn't turning off quickly enough otherwise)

if v0_override > 0
    Vsupp = Vsupp.*(v0_override/Vsupp(1).*(1+(Vsupp(1)/v0_override-1).*t/ramp_time));
end

V1 = Vsupp-(I_16-I_kitt+I_bleed)*r_coil; 
V2 = Vsupp-(2*I_16-I_kitt+I_bleed)*r_coil;

%return voltage
if flag == 1
    timeout = Vsupp(end);
    return;
end

%Check that kitten and bleed are not on at the same time
if sum((I_bleed>0 & I_kitt>0))~=0
    error('Kitten and Bleed cannot be on at the same time.');
end

%Check power drop is not too high
%Note: These are not inherently foolproof!
if sum((V1.*I_bleed)>700)~=0
    error('Too much power dropped in bleed FET');
end

if sum((V1.*I_bleed)>500)~=0
    warning('Close to max power in bleed FET');
end

if sum((V2.*I_16)>700)~=0
    error('Too much power dropped in 16 FET');
end

if sum((V2.*I_16)>500)~=0
    warning('Close to max power in 16 FET');
end

if sum(((Vsupp-V2).*I_kitt)>700)~=0
    error('Too much power dropped in Kitten FET');
end

if sum(((Vsupp-V2).*I_kitt)>500)~=0
    warning('Close to max power in Kitten FET');
end

%ramp supply
if Vsupp(end)<Vsupp(1)
    %ramping down
    t_volt_lag = 100;
else
    t_volt_lag = -200;
end

AnalogFunc(calctime(curtime,t_volt_lag),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),ramp_time,ramp_time, Vsupp(end), Vsupp(1));

%ramp kitten
if (I0(1)~=I1(1))
    AnalogFunc(curtime,3,@(t,tt,dt)(minimum_jerk(t,tt,dt)+I0(1)),ramp_time,ramp_time,I1(1)-I0(1));
end

%ramp bleed
if (I0(2)~=I1(2))
    AnalogFunc(curtime,37,@(t,tt,dt)(minimum_jerk(t,tt,dt)+I0(2)),ramp_time,ramp_time,I1(2)-I0(2));
end

%ramp 16
if (I0(3)~=I1(3))
    AnalogFunc(curtime,1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+I0(3)),ramp_time,ramp_time,I1(3)-I0(3));
end

curtime = calctime(curtime,ramp_time);

timeout = curtime;

end