function [timeout,I_QP,V_QP,P_dip,I_shim] =  xdt(timein, I_QP, V_QP,I_shim)
%% xdt.m
% Author : C Fujiwara
%
% This code is a glorify wrapper function to call all tasks in the optical
% dipole trap.  The code is segmented in this way because I think it make
% logical sense and also this prevents the optical dipole trap code from
% getting too long.

%% Initialize
P_dip = [];
curtime = timein;
global seqdata;

%% Load the Dipole Trap from the Magnetic Trap
if seqdata.flags.xdt_load
    [curtime, I_QP, V_QP,I_shim] = xdt_load(curtime, I_QP, V_QP,I_shim);
end
% curtime = calctime(curtime,500);
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