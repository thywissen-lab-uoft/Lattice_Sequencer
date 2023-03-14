function [xLattice,yLattice,zLattice] = lattice_calibrations

global seqdata

%% Zero optical power calibration
% These voltages are the "zero" lattice levels.  Use these values when
% ramping up the lattice from totally zero power to smooth out ramps.
xLattice0_list = -0.44;
xLattice0 = getScanParameter(xLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'xLatt0');

yLattice0_list = -0.13;
yLattice0 = getScanParameter(yLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'yLatt0');

zLattice0_list = -0.44;
zLattice0 = getScanParameter(zLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'zLatt0');  
% These parameters could be super sensitive to cause spikes and kill atoms

seqdata.params.lattice_zero = [xLattice0 yLattice0 zLattice0];

%% Create Lattice Calibration Structure
latt_calib = struct;

%% X Lattice

% 2023/03/01
x_p_threshold = 0.2263;
x_m1 = 49.434;
x_b1 = -9.7368;
x_m2 = 1.377;
x_b2 = 1.1387;
x_ErPerW = 330; %12/01/22 = 330

x_power2voltage = @(P) (P*x_m1 + x_b1).*(P < x_p_threshold) + ...
    (P*x_m2 + x_b2).*(P >= x_p_threshold);
xLattice = @(U) x_power2voltage(U/x_ErPerW);

latt_calib(1).Name = 'X Lattice';
latt_calib(1).ErPerW = x_ErPerW;
latt_calib(1).power2voltage = @(P) x_power2voltage(P);
latt_calib(1).depth2voltage = @(U) xLattice(U);
latt_calib(1).m1 = x_m1;
latt_calib(1).b1 = x_b1;
latt_calib(1).m2 = x_m2;
latt_calib(1).b2 = x_b2;
latt_calib(1).P_threshold = x_p_threshold;


%% Y Lattice
% % Y Lattice calibration
y_p_threshold = 0.1274;
y_m1 = 86.983;
y_b1 = - 9.713;
y_m2 = 2.021;
y_b2 = 1.11;

% y_ErPerW = 382;
y_ErPerW = 455; % 2023/03/14

y_power2voltage = @(P) (P*y_m1 + y_b1).*(P < y_p_threshold) + ...
    (P*y_m2 + y_b2).*(P >= y_p_threshold);

yLattice = @(U) y_power2voltage(U/y_ErPerW);

latt_calib(2).Name = 'Y Lattice';
latt_calib(2).ErPerW = y_ErPerW;
latt_calib(2).power2voltage = @y_power2voltage;
latt_calib(2).depth2voltage = @yLattice;
latt_calib(2).m1 = y_m1;
latt_calib(2).b1 = y_b1;
latt_calib(2).m2 = y_m2;
latt_calib(2).b2 = y_b2;
latt_calib(2).P_threshold = y_p_threshold;

%% Z Lattice new

z_power2voltage = @(P) (P*19.372 - 9.7514).*(P < 0.5863) + ...
    (P*0.71 + 1.1905).*(P >= 0.5863); % 03/01/2023

z_ErPerW = 183; % 2023/03/14
% z_ErPerW = 176; 12/01/22;

zLattice = @(U) z_power2voltage(U/z_ErPerW);

%% Output Calibration
seqdata.lattice_calibration = latt_calib;
end

