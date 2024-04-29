function [timeout,I_QP,V_QP,P_dip,I_shim] =  xdt(timein, I_QP, V_QP,I_shim)


P_dip = [];

curtime = timein;
global seqdata;

%% Flags


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