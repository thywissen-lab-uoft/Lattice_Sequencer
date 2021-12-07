function [params,punits,prands] = paramDef

% Initialize structure and objects
params = struct;        % Structure which contains all values for a parameter
punits = struct;       % Structure which contains the unit for each parameter

prands = struct;         % Structure which contains boolean of random for each parameter
% Is a particular parameter run randomly? Or in order?

%% Micrscope Stuff

params.obj_piezo_V          = [5];
punits.obj_piezo_V          = 'V';
prands.obj_piezo_V           = true;

%% Define Parameters

params.tof                  = [10];
punits.tof                  = 'ms';
prands.tof                   = true;

%% RF 1B
% 
% params.RF_1B_time_scale = [0.9 .8 .7 .6];
% punits.RF_1B_time_scale = 'arb';
% prand.RF_1B_time_scale = true;
%% XDT

%% XDT High Field

%% Lattice

%% Lattice High Field



% params.AM_spec_freq                   = [250 285 295 305 315]*1e3;
% punits.AM_spec_freq = 'Hz';
% prands.AM_spec_freq = true;
% 
% params.AM_spec_depth                   = [350];
% punits.AM_spec_depth = 'Er';
% prands.AM_spec_depth = false;


% params.Raman_freq                   = [10:2.5:40];
% punits.Raman_freq = 'kHz';
% prands.Raman_freq = true;

% params.latt_depth                   = [300];
% punits.latt_depth = 'Er';
% prands.latt_depth = false;

params.rf_freq_HF_shift             = [-50 -50];
punits.rf_freq_HF_shift             = 'kHz';
prands.rf_freq_HF_shift             = true;

% params.HF_hold_time              = [1 1.1 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10 12 15 20 25 30 35 40 50 60 75 90 100 150 200];
% punits.HF_hold_time = 'ms';
% prands.HF_hold_time = true;

end

