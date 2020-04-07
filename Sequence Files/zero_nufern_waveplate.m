%------
%Author: Graham Edge
%Created: December 2014
%Summary: Rotate the power control waveplate back to the initial position
%           (before re-setting the home position with serial communication)
%------

function timeout = zero_nufern_waveplate(timein)

curtime = timein;

global seqdata;

rotation_time = 1000;   % The time to rotate the waveplate
P_lattice = 0.00;        % The fraction of power that will be transmitted 

curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);

timeout = curtime;
        
end