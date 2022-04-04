function [xLattice,yLattice,zLattice] = lattice_calibrations

global seqdata

%% Zero optical power calibration
% These voltages are the "zero" lattice levels.  Use these values when
% ramping up the lattice from totally zero power to smooth out ramps.
xLattice0_list = [-0.85];[-1.64];
xLattice0 = getScanParameter(xLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'xLatt0');

yLattice0_list =  -0.58;%-0.955;-1.05;[-1.15];
yLattice0 = getScanParameter(yLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'yLatt0');

zLattice0_list = -0.42;0.35;0.26;0.46;[0.40];0.44;
zLattice0_list = 0.03;
zLattice0 = getScanParameter(zLattice0_list,...
    seqdata.scancycle,seqdata.randcyclelist,'zLatt0');  
% These parameters could be super sensitive to cause spikes and kill atoms

seqdata.params.lattice_zero = [xLattice0 yLattice0 zLattice0];

%% Create Lattice Calibration Structure
latt_calib = struct;

%% X Lattice new
% X Lattice calibration
x_p_threshold = 0.24467;
x_m1 = 48.2126;
x_b1 = -9.6744;
x_m2 = 4.0806;
x_b2 = 1.1235;
x_ErPerW = 346;

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

%% Y Lattice new
% Y Lattice calibration
y_p_threshold = 0.213147;
y_m1 = 54.731069;
y_b1 = - 9.655506;
y_m2 = 4.166124;
y_b2 = 1.122266;
y_ErPerW = 346;

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
z_power2voltage = @(P) (P*22.724471 - 9.74512).*(P < 0.527164) + ...
    (P*1.696746 + 1.339949).*(P >= 0.527164);

z_ErPerW = 186; 

% x_lattice2voltage = @(U) x_power2voltage(U/x_ErPerW); 
zLattice = @(U) z_power2voltage(U/z_ErPerW);

% 2022/02/14
zLattice = @(U) ...
    (U>=99.9412).*(U/99.1347+1.2132) + ...
    (U<99.9412).*(U/8.3137-9.8);

%% Output Calibration
seqdata.lattice_calibration = latt_calib;
end

