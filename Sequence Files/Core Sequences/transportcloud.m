function timeout = transportcloud(timein)
% transportcloud.m
% This function modifies the seqdata to include the magnetic transport.
%
% The basic idea of the code is to specify a z(t) where z is the position
% along the transport and t is the time at which that position occurs.
% There is an internal mapping which maps the position z to a set of 
% currents I_n {I_n}(z). This then yields a current curve {I_n(z(t))}.
%
% The transport is also characterized by a horizontal and vertical portion
% which need to be separated.  Ideally the horizontal acceleration should
% be reduced to zero before increasing the z acceleration. The currents
% don't really know about this and it is up to the user to specify a z(t)
% which accounts for the deccelleration required.
%
% Of particular import are the lengths of the horizontal and vertical
% transport sections. These are given by the following distance varibles in
% millimeters below:

DH = 365;     % Length of horizontal transport in mm
DV = 174;      % Length of vertical transport in mm

%% Minimum Jerk Curves

% Practically speaking, it is useful to specify the transport curves in
% terms of two curves Dh(t) and Dv(t) which correspond to z(t) along the
% horizontal and vertical portions respectively.
%
% The ideal curve for transport minizmes the integrated jerk over the
% entire transport. See the Jervis Thesis (2014) Pp. 33 for details. The
% curve between two end points xf and xi during a time from t=0 to t=T is
% given by the following polynomial
%
% x(t) = xi+(xf-xi)*(10*(t/T)^3-15*(t/T)^4+6*(t/T)^5)
%
% This curve basically looks like and erf curve. Experimentally, we
% occasionally specify the transport in a piecewise linear fashion as well.
% At the end of the day, the curves are optimized emperically.
%


%% Initialize

if nargin==0
   timein=0; 
end



curtime = timein;
global seqdata;

%% Load the splines
% Load the spline data which converts the transport distance to the set of
% coil currents {I_n(z)}
% 
mydir=pwd;
splinedir='C:\Users\coraf\Documents\GitHub\Lattice_Sequencer\Current Transport Splines';
cd(splinedir)

[splines,data] = loadTransportSplines;

cd(mydir);

%% Transport

%%%%%%%%%% Horizontal Transport %%%%%%%%%

% Specify Dh(t)
[yH,tH]=Dh_modified;
% yH=0:365;tH=0:365;

% Calculate the analog writes
analog = transport_coil_currents_kitten_troubleshoot_raise_topQP(calctime(curtime,tH),yH);
% Append analog write commands
seqdata.analogadwinlist = [seqdata.analogadwinlist; analog];

% Advance time
curtime=calctime(curtime,tH(end));

%%%%%%%%%% Vertical Transport %%%%%%%%%

% Specify Dh(t)
[yV,tV]=Dv_modified;
% yV=1:174;tV=1:174;

% Calculate the analog writes
analog = transport_coil_currents_kitten_troubleshoot_raise_topQP(calctime(curtime,tV),yV+DH);

% Append analog write commands
seqdata.analogadwinlist = [seqdata.analogadwinlist; analog];

% Advance time
curtime=calctime(curtime,tV(end));

% Exit
timeout=curtime;   

%% Plot

hF=figure(1235);
plot([tH, tV+tH(end)],[yH yV+yH(end)],'k-');
end

function [y,t] = Dv_modified
% This is the modified vertical transport curve. It is characterized as a
% piecewise linear transport curve

% Piecewise linear points
yP=[0 20  40  60  80  100 120 140 151 154 160 173.9 174];

% dT between each of yP (number of points is one less than yP)
tD=[450 250 450 800 450 250 500 200 150 500 500 300];

% Convert time intervals into time total times y(t)
tP=[0 cumsum(tD)];

% Create smoothing polynomial function
pp = pchip(tP,yP);

% Create time vector
dT=0.5;     % time spacing in ms
Tf=tP(end); % ending time in ms
t = 0:dT:Tf;

% Make sure you end at Tf
if t(end)~=Tf
   t(end+1)=Tf; 
end

% Evalute smoothing function at the desired mesh
y=ppval(pp,t);
end

function [y,t] = Dv_minjerk
% This is the ideal vertical minimum jerk transport curve.
    Tf=4800;
    D=174;    
    dT=0.5;
    t=0:dT:Tf;    
    y=0+(D-0)*(10*(t/Tf).^3-15*(t/Tf).^4+6*(t/Tf).^5);   
end

function [y,t] = Dh_minjerk
% This is the ideal horitzonal minimum jerk transport curve.
    Tf=3300;
    D=365;    
    dT=0.5;
    t=0:dT:Tf;    
    y=0+(D-0)*(10*(t/Tf).^3-15*(t/Tf).^4+6*(t/Tf).^5);   
end

function [y,t] = Dh_modified
% This is the modified horizontal transport curve. Is characterzied by two
% regions of minimum jerk transport which are joined by a linear piecewise
% part.

    time_scaling=1;

    % Horizontal transport parameters for for_hor_minimum_jerk
    % Distance to the second zone and time to get there
    D1 = 300;               % 300 mm
    T1 = 1800*time_scaling; % 1800 ms
    %Distance to the third zone and time to get there
    Dm = 45;                % 45 mm
    Tm =1000*time_scaling;  % 1000 ms
    %Distance to the fourth zone and time to get there
    D2 = 20;                % 20 mm
    T2 = 500*time_scaling;  % 500 ms

    Tf=T1+Tm+T2;  
    
    dT=0.5;
    t=0:dT:Tf;
    
    % Make sure you end at Tf
    if t(end)~=Tf
       t(end+1)=Tf; 
    end
        
    % preallocate array
    y = zeros(size(t));
    % Go through each of the array elements
    for i=1:length(y)
        %   Calculate distance curve based on what time it is:
        if (t(i)>=0) && (t(i)<T1)        
            y(i) = (10*D1/T1^3-4*Dm/Tm/T1^2)*t(i)^3+(-15*D1/T1^4+7*Dm/Tm/T1^3)*t(i)^4+(6*D1/T1^5-3*Dm/Tm/T1^4)*t(i)^5;        
        elseif (t(i) >= T1 ) && (t(i) < Tm+T1)        
            y(i) = D1+Dm/Tm*(t(i)-T1);
        elseif (t(i) >= T1 + Tm ) && (t(i) <= (Tm+T1 + T2+1E-10))        
            y(i) = D1+Dm+D2-((10*D2/T2^3-4*Dm/Tm/T2^2)*(abs(t(i)-T1-Tm-T2))^3+(-15*D2/T2^4+7*Dm/Tm/T2^3)*(abs(t(i)-T1-Tm-T2))^4+...
                (6*D2/T2^5-3*Dm/Tm/T2^4)*(abs(t(i)-T1-Tm-T2))^5);        
        else        
            error('Undefined time for horizontal min jerk');
        end
    end
    if sum(isnan(y))~=0    
        error('Minimum Jerk Returns NAN value');    
    end
end
