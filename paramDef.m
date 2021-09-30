function [params,punits] = paramDef

% Initialize structure and objects
params = struct;
punits  = struct;

%% Define Parameters

params.tof = [10];
punits.tof = 'ms';

params.Freq = [-30:10:100];
punits.Freq = 'kHz';

params.Bfield = [203 204 205];
punits.Bfield = 'seconds';

params.obj_piezo_V = [5];
punits.obj_piezo_V = 'V';

end

