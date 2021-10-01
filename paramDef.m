function [params,punits] = paramDef

% Initialize structure and objects
params = struct;
punits  = struct;

%% Micrscope Stuff

params.obj_piezo_V = [5];
punits.obj_piezo_V = 'V';

%% Define Parameters

params.tof = [10];
punits.tof = 'ms';

%% RF 1B

params.RF_1B_time_scale = [0.9 .8 .7 .6];
punits.RF_1B_time_scale = 'arb';

%% XDT

%% XDT High Field

%% Lattice

%% Lattice High Field

params.Freq = [-30:10:100];
punits.Freq = 'kHz';

params.Bfield = [203 204 205];
punits.Bfield = 'Gauss';

end

