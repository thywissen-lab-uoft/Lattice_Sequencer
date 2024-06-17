
function timeout = TransportCloud5(timein)
% TransportCloud2.m
%
% Author : C. Fujiwara
% Date : 2023/09/28
%



curtime = timein;

if curtime==0
   curtime=calctime(curtime,100); 
end
global seqdata;
dispLineStr('TRANSPORT',curtime);

%% Horizontal Transport

% This is still done using the old transport code
%Distance to the second zone and time to get there
D1 = 300; %300
T1 = 1800; %1800
%Distance to the third zone and time to get there
Dm = 45; %45
Tm = 1000; %1000

%Distance to the fourth zone and time to get there
D2 = 20; %15
T2 = 500; %600

% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,d1,t1,dm,tm,d2,t2) (for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)), ...
    T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);


%% Vertical Transport Splines
data=load('transport_calcs_80G.mat');

% Boundary condition which matches with horizontal transport
i12a_hf = 18.889;i12b_hf = -18.889;
i12a_vi = -data.i1(1); i12b_vi = -data.i2(1);

defVar('transport_vert_t_match_horz',100,'ms')

% Boundary condition which matches with "old" transport
defVar('transport_vert_match_pos',0.1763,'ms');
zMatch = getVar('transport_vert_match_pos');
i14_Match = [0 interp1(data.zz,data.i4,zMatch)];
i15_Match = [-10.21 interp1(data.zz,data.i5,zMatch)];
i16_Match = [18.35 interp1(data.zz,data.i6,zMatch)];  
defVar('transport_vert_t_match_vert',500,'ms')
t_v2e = 100;

% Create functions that map position to current
z2i12a = @(z) interp1(data.zz,-data.i1,z);  %12a
z2i12b = @(z) interp1(data.zz,-data.i2,z);  %12b
z2i13 = @(z) interp1(data.zz,data.i3,z);    %13
z2i14 = @(z) interp1(data.zz,data.i4,z);    %14
z2i15 = @(z) interp1(data.zz,data.i5,z);    %15
z2i16 = @(z) interp1(data.zz,data.i6,z);    %16
z2ik = @(z) interp1(data.zz,data.i6+data.i5,z); %kitten

% Voltage Function indeces that convert current to request voltage
func_12a = 3;
func_12b = 3;
func_13 = 3;
func_14 = 3;
func_15 = 5;
func_16 = 5;
func_k = 4;

%% Transport Voltage piecwise
% 
defVar('transport_vert_v0',11,'V');16;
% defVar('transport_vert_va',11,'V');16;
% defVar('transport_vert_vb',11,'V');16;
% defVar('transport_vert_vc',10,'V');16;
% defVar('transport_vert_vd',14,'V');16;
% defVar('transport_vert_ve',7,'V');16;
% 
v0 = getVar('transport_vert_v0');
% va = getVar('transport_vert_va');
% vb = getVar('transport_vert_vb');
% vc = getVar('transport_vert_vc');
% vd = getVar('transport_vert_vd');
% ve = getVar('transport_vert_ve');
% 
% Z = [0  0.023   0.068   0.102 0.153 0.155 0.1763];
% V = [v0 va      vb      vc    vd    vd    ve];
% 
% Z = [0  0.023 0.068 0.102 0.110 0.120 0.130 0.140 0.153 0.155 0.165 0.1763];
% V = [11 11    11    11     15 17    17    17    17    17    17    16];
% 
% z2v = @(z) interp1(Z,V,z,'makima');


%% Ramp 12a and 12b from end Horizontal to beggining vertical
defVar('transport_H2V_time',100,'ms');
t_h2v = getVar('transport_H2V_time');

AnalogFunc(calctime(curtime,0),'Coil 12a',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_h2v, t_h2v, i12a_hf,i12a_vi,func_12a);
AnalogFunc(calctime(curtime,0),'Coil 12b',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_h2v, t_h2v, i12b_hf,i12b_vi,func_12b);
AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_h2v, t_h2v, 10,v0);
curtime = calctime(curtime,t_h2v);

%% Transport to 153 mm
dispLineStr('Transport from 12ab to Crossover region at 153 mm',curtime);
defVar('transport_stage1_time',[1000],'ms')
t_init2cross = getVar('transport_stage1_time');
z_init = 0;
z_cross_i = 0.153;
z_cross_f = 0.155;

AnalogFunc(calctime(curtime,0),'Coil 12a',...
    @(t,tt,y1,y2) z2i12a(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_12a);  
AnalogFunc(calctime(curtime,0),'Coil 12b',...
    @(t,tt,y1,y2) z2i12b(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_12b);  
AnalogFunc(calctime(curtime,0),'Coil 13',...
    @(t,tt,y1,y2) z2i13(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_13);  
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_14);  
AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2) z2i15(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_15);  
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_16);  

%% Transport FF During Transport
%Ramp up the FF for when Coil 16 ramps up
VH = 16;16;
VT = v0;
FF_start_time = 591;
FF_ramp_time = t_init2cross-FF_start_time;
AnalogFunc(calctime(curtime,FF_start_time),'Transport FF',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    FF_ramp_time, FF_ramp_time, VT,VH);

%% Kitten Overhead during Transport
% Kitten doesn't regulate until the cross-over region, so have it request a bit more
% than what it needs to and it will rail its output

% Kitten "overhead". Extra current to make sure Kitten is railed
dkI = 4.5; % in AMPS

AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) dkI+z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_k);  

curtime = calctime(curtime,t_init2cross);

%% Calculate currents at the crossing region
% These are the "ideal" current values during the cross-over region

i14_cross_i = z2i14(z_cross_i);i14_cross_f = z2i14(z_cross_f);
ik_cross_i = z2ik(z_cross_i);ik_cross_f = z2ik(z_cross_f);
i16_cross_i = z2i16(z_cross_i);i16_cross_f = z2i16(z_cross_f);

% Duration of time to ramp over the cross-over
T_RAMP_CROSS_OVER = 200;    

%% 15/16 GS Ramp Parameters
dispLineStr('Transport Kitten Handoff',curtime);

%%%%%% 15/16 GS Ramp Parameters %%%%%
% V_GS_LOW is the "low" GS voltage, supposed to be right below turn on
V_GS_LOW = 3.6; 
T_RAMP_0_TO_L = 500;

% V_GS_MED is the "medium" GS voltage.  This allows a small amount of current
% through 15/16 FET
V_GS_MED = 4.6;
T_RAMP_L_TO_M = 300;

% V_GS_HIGH is the "high" GS voltage.  This allows maximal current through
% 15/16 FET
V_GS_HIGH = 9;
T_RAMP_M_TO_H = 1000;

% Ramp 15/16 to just below threshold
AnalogFunc(calctime(curtime,-T_RAMP_0_TO_L),'15/16 GS',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_RAMP_0_TO_L, T_RAMP_0_TO_L, 0,V_GS_LOW,1);  

% Kitten overhead off ramp time
T_KITTEN_OVERHEAD_OFF = 100;      

%% Ramp Coil 15 to negative to make sure it is off

% Time to ramp Coil 15 FET request to make sure it is 100% off
T_15_OFF = 100;

curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_15_OFF, T_15_OFF, 0,-1,func_15);  
setAnalogChannel(calctime(curtime,0),'Coil 15',-1,1);

%% Remove kitten offset
% In order for kitten to actually regulate, the overhead must be removed.
% This is done "gently" to allow the FET to begin regulating

disp(['Removing Kitten Overhead ' num2str(curtime2realtime(curtime))]);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_KITTEN_OVERHEAD_OFF, T_KITTEN_OVERHEAD_OFF, ...
    ik_cross_i+dkI,ik_cross_i,func_k); 
curtime = calctime(curtime,T_KITTEN_OVERHEAD_OFF);

%% Perform the 15/16 GS Ramps %%%%%%%
% We ramp the 15/16 GS in two stages to (1) allow a small amount of current
% and (2) allow a big amount of current.  This is because this is how the
% ideal current ramps look like.  We also DO NOT advance curtime here so we
% can specify the 15/16 GS ramp indepdently of the current ramp.  

disp(['ramping 15/16 GS ' num2str(curtime2realtime(curtime))]);

% Ramp GS of 15/16 to allow current through
AnalogFunc(calctime(curtime,0),'15/16 GS',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_RAMP_L_TO_M, T_RAMP_L_TO_M, V_GS_LOW,V_GS_MED,1);   
AnalogFunc(calctime(curtime,T_RAMP_L_TO_M),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            T_RAMP_M_TO_H, T_RAMP_M_TO_H, V_GS_MED,V_GS_HIGH,1); 
      
%% Ramp currents across the cross over %%%%%%%
% Ramp Coil 16, Coil 14, and Kitten curents across the cross over

% Ramp Coil 16
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_RAMP_CROSS_OVER, T_RAMP_CROSS_OVER, i16_cross_i,i16_cross_f,func_16);  
% Ramp Coil 14
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_RAMP_CROSS_OVER, T_RAMP_CROSS_OVER, i14_cross_i,i14_cross_f,func_14); 
% Ramp Kitten
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_RAMP_CROSS_OVER, T_RAMP_CROSS_OVER, ik_cross_i,ik_cross_f,func_k);       
curtime = calctime(curtime,T_RAMP_CROSS_OVER);

%% Ramp to End of Transport
% Now that cross-over has ended, finish the vertical transport to match to
% the end of the original transport (this can be changed).

defVar('transport_v_stage2_time',[200],'ms')
t_cross2end=getVar('transport_v_stage2_time');

disp(['ramping to end of transport start ' num2str(curtime2realtime(curtime))]);
 
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_f,zMatch,func_14);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_f,zMatch,func_k);
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_f,zMatch,func_16); 
curtime = calctime(curtime,t_cross2end);


%% Ramp to RF1A
% Transport is complete. Ramp the currents to the RF1A values.  These could
% be better optimized, and I'm not sure what the ideal RF1A currents should
% be.

I_RF1A_k=2.907;
I_RF1A_16 = 31.91;
t_2RF1A = 300;
defVar('RF1a_FF_V',[21.5],'V');22.5;
RF1a_V = getVar('RF1a_FF_V');
    
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_2RF1A, t_2RF1A, z2i14(zMatch),0,func_14);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_2RF1A, t_2RF1A,z2ik(zMatch),I_RF1A_k,func_k);
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_2RF1A, t_2RF1A, z2i16(zMatch),I_RF1A_16,func_16); 
AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_2RF1A, t_2RF1A, VH,RF1a_V); 

curtime = calctime(curtime,t_2RF1A);

%%
timeout = curtime;
 
end