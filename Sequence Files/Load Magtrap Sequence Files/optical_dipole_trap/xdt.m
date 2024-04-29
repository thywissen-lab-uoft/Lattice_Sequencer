function [timeout,I_QP,V_QP,P_dip,I_shim] =  xdt(timein, I_QP, V_QP,I_shim)


P_dip = [];

curtime = timein;
global seqdata;

%% Flags

seqdata.flags.xdt_unlevitate_evap       = 0; % Unclear what this is for

% 

%%%%%%%%%%%%%%%%%%%%%%%%%%
%After Evaporation (unless CDT_evap = 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%
seqdata.flags.xdt_do_dipole_trap_kick   = 0;    % Kick the dipole trap, inducing coherent oscillations for temperature measurement
seqdata.flags.xdt_do_hold_end           = 0;
seqdata.flags.xdt_am_modulate           = 0;    % 1: ODT1, 2:ODT2

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spectroscopy after Evaporation
%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load the Dipole Trap from the Magnetic Trap

% CF Testing
if seqdata.flags.xdt_load
    [curtime, I_QP, V_QP,I_shim] = xdt_load(curtime, I_QP, V_QP,I_shim);
end

%% Pre-evaporation 

if seqdata.flags.xdt_pre_evap
    [curtime, I_QP, V_QP,I_shim] = xdt_pre_evap(curtime, I_QP, V_QP,I_shim);
end

%% Evaporation Stage 1
if seqdata.flags.xdt_evap_stage_1
    [curtime, I_QP, V_QP,I_shim] = xdt_evap_stage_1(curtime, I_QP, V_QP,I_shim);
end

%% Post Evap Stage 1
if seqdata.flags.xdt_post_evap_stage1
   curtime = xdt_post_evap_stage_1(curtime); 
end

%% The End!

timeout = curtime;
dispLineStr('Dipole Transfer complete',curtime);

end