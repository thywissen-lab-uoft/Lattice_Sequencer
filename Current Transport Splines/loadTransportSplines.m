function [splines,data] = loadTransportSplines
% loadTransportSplines.m
%
% Author  : CJ Fujiwara
% Date    : 2020/07/16
% This functions loads the calibration text files which define how the
% currents relate to a desired position during the magnetic transport.
%
% splines - 1x20 structure array which is a spline fit, evalulate with ppval
% data    - 539x20 vector of calibration current


xH=0:1:365; % position vector for horizontal transport
xV=366:539; % position vector for vertical transport

x0=[xH xV]; % position vector for entirety of transport

data=zeros(length(xH)+length(xV),20);


%% Load the calirations

% Get the full directory of this file, it is assumed that the calibrations
% are in this folder
str=mfilename('fullpath');
[str,~,~]=fileparts(str)
str=[str filesep];


% Read the horizontal calibrations 
% (',' delimeter, row offset 0, column 1)
MPush = dlmread([str 'Hextra1coilPush.txt'],',',0,1);
MMOT = dlmread([str 'Hextra1coilMOT.txt'],',',0,1);
M3 = dlmread([str 'Hextra1coil3.txt'],',',0,1);
M4 = dlmread([str 'Hextra1coil4.txt'],',',0,1);
M5 = dlmread([str 'Hextra1coil5.txt'],',',0,1);
M6 = dlmread([str 'Hextra1coil6.txt'],',',0,1);
M7 = dlmread([str 'Hextra1coil7.txt'],',',0,1);
M8 = dlmread([str 'Hextra1coil8.txt'],',',0,1); 
M9 = dlmread([str 'Hextra1coil9.txt'],',',0,1);
M10 = dlmread([str 'Hextra1coil10.txt'],',',0,1);
M11 = dlmread([str 'Hextra1coil11.txt'],',',0,1);
M12 = dlmread([str 'Hextra1coil12.txt'],',',0,1);
MExtra = dlmread([str 'Hextra1coilextra.txt'],',',0,1);

%vertical points to spline
M12A = dlmread([str 'rev45coil1.txt'],',',0,1);
M12B = dlmread([str 'rev45coil2.txt'],',',0,1);
M13 = dlmread([str  'rev45coil3.txt'],',',0,1);
M14 = dlmread([str  'rev45coil4.txt'],',',0,1);
M15 = dlmread([str  'rev45coil5.txt'],',',0,1);
M16 = dlmread([str  'rev45coil6.txt'],',',0,1);

%vertical fill
M17 = dlmread([str 'rev45coilpushfill.txt'],',',0,2);
M18 = dlmread([str 'rev45coilMOTfill.txt'],',',0,2);

%% Stitch the data together and make splines

% Coil 1 : PUSH COIL
Y=[MPush xV*0];
data(:,1)=Y;
splines(1)=spline(x0,Y);

% Coil 2 : MOT COIL
Y=[MMOT xV*0];
data(:,2)=Y;
splines(2)=splinefit(x0,Y,250);

% Coil 3
Y=[M3 xV*0];
data(:,3)=Y;
splines(3)=spline(x0,Y);

% Coil 4
Y=[M4 xV*0];
data(:,4)=Y;
splines(4)=spline(x0,Y);

% Coil 5
Y=[M5 xV*0];
data(:,5)=Y;
splines(5)=spline(x0,Y);

% Coil 6
Y=[M6 xV*0];
data(:,6)=Y;
splines(6)=spline(x0,Y);

% Coil 7
Y=[M7 xV*0];
data(:,7)=Y;
splines(7)=spline(x0,Y);

% Coil 8
Y=[M8 xV*0];
data(:,8)=Y;
splines(8)=spline(x0,Y);

% Coil 9
Y=[M9 xV*0];
data(:,9)=Y;
splines(9)=spline(x0,Y);

% Coil 10
Y=[M10 xV*0];
data(:,10)=Y;
splines(10)=spline(x0,Y);

% Coil 11
Y=[M11 xV*0];
data(:,11)=Y;
splines(11)=spline(x0,Y);

% Coil Extra
Y=[MExtra xV*0];
data(:,12)=Y;
splines(12)=spline(x0,Y);

% Vertical now

% Coil 12A
Y=[M12 -M12A];
data(:,13)=Y;
splines(13)=spline(x0,Y);

% Coil 12B
Y=[M12 M12B];
data(:,14)=Y;
splines(14)=spline(x0,Y);

% Coil 13
Y=[xH*0 M13];
data(:,15)=Y;
splines(15)=spline(x0,Y);

% Coil 14
Y=[xH*0 M14];
data(:,16)=Y;
splines(16)=spline(x0,Y);

% Coil 15
Y=[xH*0 M15];
data(:,17)=Y;
splines(17)=spline(x0,Y);

% Coil 16
Y=[xH*0 M16];
data(:,18)=Y;
splines(18)=spline(x0,Y);

% Push fill current
Y=[xH*0 26 1.2*M17];
data(:,19)=Y;
splines(19)=spline(x0,Y);

% MOT fill current
Y=[xH*0 18.5 1.2*M18];
data(:,20)=Y;
splines(20)=spline(x0,Y);
end

