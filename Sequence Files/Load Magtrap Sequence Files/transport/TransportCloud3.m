
function timeout = TransportCloud3(timein)
% TransportCloud2.m
%
% Author : C. Fujiwara
% Date : 2023/08/14

if nargin==0
    timein = 1000;
end

%% Settings

c15_vfunc = 5;
c15_vfunc = 5;

%%
curtime = timein;
global seqdata;

%% Horizontal Transport

%Distance to the second zone and time to get there
D1 = 300; %300
T1 = 1800; %1800
%Distance to the third zone and time to get there
Dm = 45; %45
Tm =1000; %1000
%Distance to the fourth zone and time to get there
D2 = 20; %15
T2 = 500; %600

% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,d1,t1,dm,tm,d2,t2) (for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)), ...
    T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);

%% Specify Vertical Transport

vertical_transport_time_1 = 3000;
data = load('transport_calcs.mat');

% Find distance where Coil 15 goes to zero (zd)
% We first transport to Coil 15 zero current as this is where kitten
% becomes relevant
zSwitch = data.zd*1e3;
i16Switch = data.i6(data.zz == data.zd);
i15Switch = data.i5(data.zz == data.zd);
i14Switch = data.i4(data.zz == data.zd);

% Minimum Jerk curve. 
% T is the ramp time; dY amount to change; t : time to evaluate [0,T] (typically a vector)
min_jerk = @(T,dY,t) (10*dY/T^3)*t.^3 - (15*dY/T^4)*t.^4 + (6*dY/T^5)*t.^5;                      

%% 12a 12 b ramp

i12a_0 = -data.i1(1);
i12b_0 = -data.i2(1);

AnalogFunc(calctime(curtime,0),'Coil 12a',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    100, 100,18.89,i12a_0,3);
curtime = AnalogFunc(calctime(curtime,0),'Coil 12b',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    100, 100,-18.89,i12b_0,3);

%% Vertical Transport 1
% The coils change the MT to go from the center of 12a and 12b (z=0) to
% the center of 14 and 16 (where Coil 15 current is zero).

dT1 = 0.5; % Time steps in ms

if mod(vertical_transport_time_1,dT1)
    error('time step needs to be interger multiple of ramp time, sorru');
end

tVec1 = (0:dT1:vertical_transport_time_1)';
dVec1 = min_jerk(vertical_transport_time_1,zSwitch,tVec1);

AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    2000, 2000, 0,60,3);

curtime = doVerticalTransport_1(calctime(curtime,0),tVec1,dVec1);

%% Switch to Kittten Regulation Mode
% Now that the Coil 15 is nominally off, we now want to engage the 15/16
% switch so that Coil 15 current may be run backwards.

% Setting Time
curtime = calctime(curtime,10);

% Ramp Coil 15 to negative to make sure it is off
curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    200, 200, i15Switch,-1,5);

ikit_switch =i16Switch;

% Ramp the kitten regulation to the same level as Coil 16
curtime = AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    1000, 1000, 60,ikit_switch,3);

% Settling Time
curtime = calctime(curtime,100);

% Engage 15/16 switch
setDigitalChannel(calctime(curtime,0),'15/16 Switch',1);

%% Ramp kitten and Coil 16 to the new values
% Now that Coil 15 is reverse polarity (and is controlled using the kittena
% and Coil 16), we move the QP trap to th
Tfinal = 500;
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tfinal, Tfinal,i14Switch,0,3);

AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tfinal, Tfinal, ikit_switch,6.8,3);

curtime = AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tfinal, Tfinal, i16Switch,18,5);

curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tfinal, Tfinal,15,12.25,2);

%% Compress Trap
% With the cloud at the at the RF1A position, we want to increase the field
% % gradient
% Tcompress = 1000;
% [33 4];
% 
% iRF1A = [9.7 21.3793 ];

%% Ending Stuff
timeout = curtime;

end