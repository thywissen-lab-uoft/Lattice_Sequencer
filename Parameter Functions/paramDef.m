function [params,punits,ptypes] = paramDef

% Initialize structure and objects
params = struct;        % Structure which contains all values for a parameter
punits = struct;       % Structure which contains the unit for each parameter

ptypes = struct;         % Structure which contains boolean of random for each parameter

% Descriptions
%
% params.(var_name) - the list of values that defines the vector
% punits.(var_name) - a string which defines the units, for plotting
%                       purposes only
% ptypes.(var_name) - how the variable is scanned
%                       - 'ordered' : scan the variable in order and
%                       independently of all other variables
%                       - 'random' : scan the variable in random order and
%                       independently of all other variables
%                       - 'var_name2' : scan the variable in concert with
%                       another variable 'var_name2'
%                       For example if you have two param lists A and B and
%                       the sequencer chooses an index I to run. The values
%                       chosen will be A(I) and B(I). To run properly A and
%                       B MUST be the same length.


%% Micrscope Stuff

% params.obj_piezo_V          = [5];
% punits.obj_piezo_V          = 'V';
% ptypes.obj_piezo_V           = 'random';

%% Define Parameters
% 
% params.tof                  = [10];
% punits.tof                  = 'ms';
% ptypes.tof                   = 'random';

%% RF 1B
% 
% params.RF_1B_time_scale = [0.9 .8 .7 .6];
% punits.RF_1B_time_scale = 'arb';
% ptypes.RF_1B_time_scale = 'random';
%% XDT

%% XDT High Field

%% Lattice

%% Raman
% params.Raman_V_Voltage = linspace(1.2*.1,1.2,10);
% punits.Raman_V_Voltage = 'V';
% ptypes.Raman_V_Voltage = 'ordered';
% 
% params.Raman_H1_Voltage = linspace(.1,1,10);
% punits.Raman_H1_Voltage = 'V';
% ptypes.Raman_H1_Voltage = 'random';

%% Photoassociation Pulses

% If using the lattice, this variable SHOULD be assigned to the field
% params.HF_FeshValue_Initial_Lattice = [206]; 
% punits.HF_FeshValue_Initial_Lattice = 'G';
% ptypes.HF_FeshValue_Initial_Lattice = 'ordered';

%%% For defining time in a relative sort of way
% params.pulse_time_rel = [linspace(0,1,20)  1.5 2 3 3.5];
% punits.pulse_time_rel = 'arb';
% ptypes.pulse_time_rel = 'random';
% 
% params.pulse_time_max = [1];
% punits.pulse_time_max = 'arb';
% ptypes.pulse_time_max = 'random';


% For defining it absolutely
%params.pulse_time = [0:1:15];
% params.pulse_time = [0];
% punits.pulse_time = 'ms';
% ptypes.pulse_time = 'random';

% Control voltage
% params.PA_rel_pow = 0.35; 0.1;
% punits.PA_rel_pow = 'V';
% ptypes.PA_rel_pow = 'ordered';
%% Lattice High Field

% params.detuning = [-49.6];
% punits.detuning = 'GHz';
% ptypes.detuning = 'ordered';
% 
% % params.rf_shift = [repelem(-46:2:-26,3) -14:2:0];
% params.rf_shift = [-35];
% punits.rf_shift = 'kHz';
% ptypes.rf_shift = 'random';

% params.do_fake = [0,1];
% ptypes.do_fake = 'ordered';

% params.PA_FB_field = [204]; %+3G from zshim

% punits.PA_FB_field = 'G';
% ptypes.PA_FB_field = 'ordered';

%params.PA_pulse_time_rel = [repelem([linspace(0,1,10) 1.25 1.5 2 4],3)];
% params.PA_pulse_time_rel = 1;
% 
% punits.PA_pulse_time_rel = 'arb.';
% ptypes.PA_pulse_time_rel = 'random';

% 
% params.pulse_time = [0.7];
% punits.pulse_time = 'ms';
% ptypes.pulse_time = 'random';
% % 
% params.PA_rel_pow = [.25];
% punits.PA_rel_pow = 'arb.';
% ptypes.PA_rel_pow = 'ordered';

params.AM_spec_depth                   = [200];
punits.AM_spec_depth = 'Er';
ptypes.AM_spec_depth = 'ordered';
% % % % 
params.AM_direction                   = ['X'];
punits.AM_direction = '';
ptypes.AM_direction = 'ordered';
% % % 
% % % % %    300 = [260:5:340 295:1:325]*1e3; 48 points
% % % % %     200 = [200:5:300]*1e3; 21 points
% % % % %     100 = [100:10:180 140:1:165]*1e3; 43 points
% % % % %     60 = [70:5:150 110:1:145]*1e3; 53 points
% % % % %     250 [220:5:320 260:1:285]*1e3
params.AM_spec_freq = [200:5:300]*1e3;
punits.AM_spec_freq = 'Hz';
ptypes.AM_spec_freq = 'random';
% 

% params.Raman_freq                   = [10:2.5:40];
% punits.Raman_freq = 'kHz';
% ptypes.Raman_freq = 'random';

% params.latt_depth                   = [100];
% punits.latt_depth = 'Er';
% ptypes.latt_depth = 'ordered';
% 
% params.HF_wait_time_5 =[5]; [1:10];
% punits.HF_wait_time_5 = 'ms';
% ptypes.HF_wait_time_5 = 'random';

% % 
% params.HF_spec_latt_depth = [60];
% punits.HF_spec_latt_depth = 'Er';
% ptypes.HF_spec_latt_depth = 'ordered';

% params.latt_depth = [300];
% punits.latt_depth = 'Er';
% ptypes.latt_depth = 'ordered'; 
% 
%  params.HF_FeshValue_Final = [198.5 198.5];
%  punits.HF_FeshValue_Final = 'G';
%  ptypes.HF_FeshValue_Final = 'random';
 
%  params.rf_srs_power = [8 8 4 4];
%  punits.rf_srs_power = 'dBm';
%  ptypes.rf_srs_power = 'HF_FeshValue_Spectroscopy';
% %  


% 

% % % 
%  params.HF_FeshValue_Spectroscopy = [205 206 203 208];
%  punits.HF_FeshValue_Spectroscopy = 'G';
%  ptypes.HF_FeshValue_Spectroscopy = 'ordered';
% %  
%   params.HF_shimvalue_Spectroscopy = [0 0 0 0];
%  punits.HF_shimvalue_Spectroscopy = 'G';
%  ptypes.HF_shimvalue_Spectroscopy = 'HF_FeshValue_Spectroscopy';
% 
% % %  
%  params.rf_freq_HF_shift = [-10:2:50 -10:2:50];
%  punits.rf_freq_HF_shift = 'kHz';
%  ptypes.rf_freq_HF_shift = 'random';
%  
%   
%  params.Raman_Pulse_Time = [0 0.5 1 1.5 2 5];
%  punits.Raman_Pulse_Time = 'ms';
%  ptypes.Raman_Pulse_Time = 'ordered';
% %  
% %  
%  params.Raman_freq = [-140:5:-40 -140:5:-40];
%  punits.Raman_freq = 'kHz';
%  ptypes.Raman_freq = 'random';
 
% % % 
%  params.rf_rabi_freq_HF_shift = [29.85];
%  punits.rf_rabi_freq_HF_shift = 'kHz';
%  ptypes.rf_rabi_freq_HF_shift = 'HF_FeshValue_Spectroscopy';
% 
% 
%  params.rf_rabi_time_HF = [0.005:0.02:1.6];
%  punits.rf_rabi_time_HF = 'ms';
%  ptypes.rf_rabi_time_HF = 'random';
% % % % 




% 
%  params.HF_FeshValue_Initial = [198];
%  punits.HF_FeshValue_Initial = 'G';
%  ptypes.HF_FeshValue_Initial = 'ordered';
% % 

 
%  
% params.HF_hold_time              = [0.1 0.5 1.1 1.2 1.5 2 2.5 3 3.5 4 5 6 7 8 9 10 12 13 14 15 17 20 25 30 35 40 50 60 75 90 100 110 120 130 150 200];
% punits.HF_hold_time = 'ms';
% ptypes.HF_hold_time = 'random';



%  
% % % params.B = @(x) 5*x;
% % % punits.B = '5kHz';[-10:2:16 -7 -5 -3 -1 17:1:30 32:2:36]
% % % ptypes.B = 'A';
% % % 

% % % 
% % % 
% % % params.E = [10 20 30 40 50 60 70 80 90 100];
% % % punits.E = 'bob';
% % % ptypes.E = 'D';



end

 