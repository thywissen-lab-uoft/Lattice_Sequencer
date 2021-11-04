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

params.rf_freq_HF_shift             = [-50:1:-15 0 1 2 -1 -2 -3 -4 -5  5 -10];
punits.rf_freq_HF_shift             = 'kHz';
prands.rf_freq_HF_shift             = true;

params.HF_FeshValue_Spectroscopy    = [199.7 199.7 199.7 199.7 199.9 199.9 199.9];
punits.HF_FeshValue_Spectroscopy    = 'G';
prands.HF_FeshValue_Spectroscopy     = false;

end

