
function timeout = TransportCloud2(timein)
% TransportCloud2.m
%
% Author : C. Fujiwara
% Date : 2023/08/14
%
% This is CF's attempt at rewriting this code. This code really sucked to
% begin with, so forgive me if its still bad.
%
% Magnetic transport is one of the most complicated things that we do.
%
% The code for this is conceptually split into the following :
%
% (A) What are [x(t),z(t)]? Here, x(t) is horizontal transport distance and 
%     and z(t) is the vertical transport distance.  This needs to be smooth
%     to not shake the atoms around.
%
% (B) What are the gradients along the distance G_x(x,z),G_y(x,z),G_z(x,z)?
%     This characterizes the strength of the magnetic trap.  For physics
%     reasons this should held as constant as possible to avoid heating.
%
% (B) What are the set of currents {I(x,z}} given the constraints on
%     reasonable restrictions on the gradient?
%
% (D) What are the time varying currents {I(t)} to produce the desired G(t)
%     and [x(t), z(t)].
%
%
%
% (A) The distance curve is defined by the user in this code and can be
% changed if someone would like test different parts of the transport. For
% example if you wanted to test the adiabaticity of transport or you wanted
% to round trip measurements.
%
% (B) The desired gradients [G(x,z)] are specified by the user in some external
% code.  The achievable gradients are limited by the geometry of the coils
% as well as reasonable constraints on the amount of current running
% through the system.
%
% (C) The set of currents are then calculated by external code using the
% physical parameters of the coils.  This can be very tricky because it
% depends on how accurately the coils are wound and also wear they are
% mounted.
%
% (D) This is simply done by the parametrization {I((x(t),z(t))}.

%%

curtime = timein;
global seqdata;
logNewSection('TRANSPORT',curtime);

% % hor_transport_type,ver_transport_type, image_loc
% % 
horiz_length = 365;
vert_length = 174;


hor_transport_type            = 1;
ver_transport_type            = 3;
image_loc                     = 1;   

% Horitzonl used "1 : slow down in middle section curv"
% Vertical uses "3 : linear"

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

%% Vertical Transport

% Duration of each segment
vert_lin_trans_times = [450 250 450 800 450 250 500 200 150 500 500 300]; % N

% Endpoints of each segment (MAKE SURE THE FIRST IS 0 LAST ONE IS 174)
vert_lin_trans_distances = [0 20 40 60 80 100 120 140 151 154 160 173.9 174]; % N+1

if vert_lin_trans_distances(1)~=0
    error('why u no start at zero distance');
end

if vert_lin_trans_distances(end)~=174
    error('why u no end at 174 mm distance; end of transport');
end


% Convert durations in time into endpoints of time
vert_lin_total_time = zeros(size(vert_lin_trans_distances));
for ii = 2:length(vert_lin_trans_distances)
    vert_lin_total_time(ii) = vert_lin_total_time(ii-1) + vert_lin_trans_times(ii-1);
end             

% Piecewise Cubic Hermit spline to remove kinks from piecewise linear
vert_pp = pchip(vert_lin_total_time,vert_lin_trans_distances+horiz_length);  

% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,tt,aa)(ppval(aa,t)),...
    vert_lin_total_time(end),vert_lin_total_time(end),vert_pp);

%% Turn off Vertical Coils 12A-14

disp(['Transport over at ' num2str(curtime2realtime(curtime))]);
timeout = curtime;



end