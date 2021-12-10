function [params,punits,ptypes] = paramDef

% Initialize structure and objects
params = struct;        % Structure which contains all values for a parameter
punits = struct;       % Structure which contains the unit for each parameter

ptypes = struct;         % Structure which contains boolean of random for each parameter
% Is a particular parameter run randomly? Or in order?

%% Micrscope Stuff

params.obj_piezo_V          = [5];
punits.obj_piezo_V          = 'V';
ptypes.obj_piezo_V           = 'random';

%% Define Parameters

params.tof                  = [10];
punits.tof                  = 'ms';
ptypes.tof                   = 'random';

%% RF 1B
% 
% params.RF_1B_time_scale = [0.9 .8 .7 .6];
% punits.RF_1B_time_scale = 'arb';
% ptypes.RF_1B_time_scale = 'random';
%% XDT

%% XDT High Field

%% Lattice

%% Lattice High Field



% params.AM_spec_freq                   = [250]*1e3;
% punits.AM_spec_freq = 'Hz';
% ptypes.AM_spec_freq = 'random';
% 
% params.AM_spec_depth                   = [350];
% punits.AM_spec_depth = 'Er';
% ptypes.AM_spec_depth = 'random';

% params.Raman_freq                   = [10:2.5:40];
% punits.Raman_freq = 'kHz';
% ptypes.Raman_freq = 'random';

% params.latt_depth                   = [300];
% punits.latt_depth = 'Er';
% ptypes.latt_depth = 'random';


% params.rf_freq_HF_shift             = [-50];
% punits.rf_freq_HF_shift             = 'kHz';
% ptypes.rf_freq_HF_shift             = true;
% 
% params.HF_FeshValue_Spectroscopy             = [199.2 199.2];
% punits.HF_FeshValue_Spectroscopy             = 'G'; 
% ptypes.HF_FeshValue_Spectroscopy             = false;

% params.HF_hold_time              = [1 1.1 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10 12 15 20 25 30 35 40 50 60 75 90 100 150 200];
% punits.HF_hold_time = 'ms';
% ptypes.HF_hold_time = 'random';


params.A = [0 1 2 3 4 5 6];
punits.A = 'kHz';
ptypes.A = 'ordered';

params.B = @(x) 5*x;
punits.B = '5kHz';
ptypes.B = 'A';

params.C = [6 7 8 9 10 11 12];
punits.C = 'plus6khz';
ptypes.C = 'A';

params.D = [100 200 300 400 500 600 700 800 900 1000];
punits.D = 'kHz';
ptypes.D = 'random';

params.E = [10 20 30 40 50 60 70 80 90 100];
punits.E = 'bob';
ptypes.E = 'D';



end

 