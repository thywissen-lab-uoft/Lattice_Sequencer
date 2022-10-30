function curtime = feshbach_test(timein)
curtime = timein;

global seqdata;
%%  Wait a hot second for backwards in time
curtime=calctime(curtime,1000);

% set innitiail vfalue to low so that the code doesn't throw a hissy fit
setAnalogChannel(curtime,'FB current',0);

%% Settigns
zshim = 0/2.35;
B_HF = 212;
B_off = 0;

T_on = 100;
%% Ramp Up




%   Define the ramp structure
ramp=struct;
% ramp.shim_ramptime = 150;
% ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
% ramp.xshim_final = seqdata.params.shim_zero(1); 
% ramp.yshim_final = seqdata.params.shim_zero(2);
% ramp.zshim_final = seqdata.params.shim_zero(3);
% FB coil 
ramp.fesh_ramptime = 500;
ramp.fesh_ramp_delay = 0;
ramp.fesh_final = B_HF; %22.6
ramp.settling_time = 100;    

disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);


curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

%% Wait
curtime = calctime(curtime,T_on);

ScopeTriggerPulse(curtime,'FB_hold');

%% Ramp Down



%   Define the ramp structure
ramp=struct;
% ramp.shim_ramptime = 150;
% ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
% ramp.xshim_final = seqdata.params.shim_zero(1); 
% ramp.yshim_final = seqdata.params.shim_zero(2);
% ramp.zshim_final = seqdata.params.shim_zero(3);
% FB coil 
ramp.fesh_ramptime = 500;
ramp.fesh_ramp_delay = 0;
ramp.fesh_final = B_off; %22.6
ramp.settling_time = 100;    

disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);


curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

SelectScopeTrigger('FB_hold');

    
end

