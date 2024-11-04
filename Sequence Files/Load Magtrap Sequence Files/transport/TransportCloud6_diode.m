
function timeout = TransportCloud6_diode(timein)
% TransportCloud6_diode.m
%
% Author : C. Fujiwara
% Date : 2024/07/18

curtime = timein;
if curtime==0
    doDebug = 1;
else
    doDebug = 0;
end
global seqdata;
logNewSection('TRANSPORT',curtime);
%% Votlage Fucntions

% Voltage Function indeces that convert current to request voltage
func_12a = 3;
func_12b = 3;
func_13 = 3;
func_14 = 3;
func_15 = 5;
func_16 = 5;
func_k = 4;


%%
if doDebug
    setAnalogChannel(curtime,'15/16 GS',0,1);
    setAnalogChannel(curtime,'Coil 16',0);
    curtime=calctime(curtime,100);     
end


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

AnalogFunc(calctime(curtime,0),'15/16 GS', ...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    100, 100, 0,1,1);     


logNewSection('Transport from 12ab to Crossover region at 153 mm',curtime);
defVar('transport_stage1_time',[3000],'ms'); % used to be 1000 ms, made longer because of weird spike in 14 influenceing 15 2024/07/25
t_init2cross = getVar('transport_stage1_time');
z_init = 0;
z_cross_i = 0.153; % When Coil 15 goes to zero
z_cross_f = 0.155;


i15_cross_i = z2i15(z_cross_i);
i14_cross_i = z2i14(z_cross_i);i14_cross_f = z2i14(z_cross_f);
ik_cross_i = z2ik(z_cross_i);ik_cross_f = z2ik(z_cross_f);
i16_cross_i = z2i16(z_cross_i);i16_cross_f = z2i16(z_cross_f);



disp(['Coil 15 current at crossing is ' num2str(i15_cross_i) 'A']);

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

% Transport FF During Transport
VH = 16;15;16;
VT = v0;
FF_start_time = 591;
FF_ramp_time = t_init2cross-FF_start_time;
AnalogFunc(calctime(curtime,FF_start_time),'Transport FF',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    FF_ramp_time, FF_ramp_time, VT,VH);


% Kitten Overhead during Transport
dkI = 6; % 4.5;in AMPS
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) dkI+z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_k);  

% Advance time to the cross over
curtime = calctime(curtime,t_init2cross);



%% Coil 15 Be Sure Off
logNewSection('Transport Kitten Handoff : Coil 15 Off',curtime);

% Time to ramp Coil 15 FET request to make sure it is 100% off
T_15_OFF = 10;
curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_15_OFF, T_15_OFF, 0,-1,func_15);  
setAnalogChannel(calctime(curtime,0),'Coil 15',-1,1);

%% Turn on 15/16 FET
logNewSection('Transport Kitten Handoff : 15/16 GS On',curtime);

T_1516_ON = 50;
V_GS_HIGH = 9;
  
% curtime = calctime(curtime,T_1516_ON);
AnalogFunc(calctime(curtime,0),'15/16 GS', ...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_1516_ON, T_1516_ON,1,V_GS_HIGH,1);   
%% Remove kitten offset
% In order for kitten to actually regulate, the overhead must be removed.
% This is done "gently" to allow the FET to begin regulating

T_KITTEN_OVERHEAD_OFF = 50;      

disp(['Removing Kitten Overhead ' num2str(curtime2realtime(curtime))]);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_KITTEN_OVERHEAD_OFF, T_KITTEN_OVERHEAD_OFF, ...
    ik_cross_i+dkI,ik_cross_i,func_k); 




curtime = calctime(curtime,T_KITTEN_OVERHEAD_OFF);
    
%% Ramp to End of Transport
% Now that kitten hand-off has occured, finish the vertical transport to match to
% the end of the original transport (this can be changed).

defVar('transport_v_stage2_time',[200],'ms')
t_cross2end=getVar('transport_v_stage2_time');
disp(['ramping to end of transport start ' num2str(curtime2realtime(curtime))]);
 
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_i,zMatch,func_14);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_i,zMatch,func_k);
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
    t_cross2end, t_cross2end, z_cross_i,zMatch,func_16); 
curtime = calctime(curtime,t_cross2end);


%% Ramp to RF1A
% Transport is complete. Ramp the currents to the RF1A values.  These could
% be better optimized, and I'm not sure what the ideal RF1A currents should
% be.

I_RF1A_k=2.907;
I_RF1A_16 = 31.91;
t_2RF1A = 300;
defVar('RF1a_FF_V',[22.5],'V');22.5;
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

%% Turn off Current if in debug

if doDebug
  
    AnalogFuncTo(calctime(curtime,0),'Coil 14',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
        500, 50, 0,func_14);
    AnalogFuncTo(calctime(curtime,0),'kitten',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
        500, 500,0,func_k);    
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
        500, 500, 0,func_16); 
    
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        500, 500, 1); 

    curtime = calctime(curtime,500);
    AnalogFuncTo(calctime(curtime,0),'15/16 GS', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
        100, 100, 0,1);     
    curtime = calctime(curtime,100);

end

%%
timeout = curtime;
 
end