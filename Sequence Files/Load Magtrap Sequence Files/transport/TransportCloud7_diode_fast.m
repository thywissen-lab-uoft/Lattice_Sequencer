
function timeout = TransportCloud7_diode_fast(timein)
% TransportCloud7_diode_fast.m
%
% Author : C. Fujiwara
% Date : 2024/07/26

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
defVar('transport_vert_va',13,'V');16;
 defVar('transport_vert_vb',14,'V');16;
 defVar('transport_vert_vc',15,'V');16;
 defVar('transport_vert_vd',15,'V');16;
 defVar('transport_vert_ve',16,'V');16;
 
v0 = getVar('transport_vert_v0');
 va = getVar('transport_vert_va');
 vb = getVar('transport_vert_vb');
 vc = getVar('transport_vert_vc');
 vd = getVar('transport_vert_vd');
 ve = getVar('transport_vert_ve');
% 
 Z = [0  0.023   0.068   0.102 0.153 0.155 0.1763];
 V = [v0 va      vb      vc    vd    vd    ve];
% 
% Z = [0  0.023 0.068 0.102 0.110 0.120 0.130 0.140 0.153 0.155 0.165 0.1763];
% V = [11 11    11    11     15 17    17    17    17    17    17    16];
% 
 z2v = @(z) interp1(Z,V,z,'makima');

%% Ramp 12a and 12b from end Horizontal to beginning vertical
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

%% Prepare GS

AnalogFunc(calctime(curtime,0),'15/16 GS', ...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    100, 100, 0,1,1);     

%% Transport to zMatch
defVar('transport_time',[2000],'ms'); % used to be 1000 ms, made longer because of weird spike in 14 influenceing 15 2024/07/25
tV = getVar('transport_time');
z_init = 0;

%% Transport to 174 mm
logNewSection('Vertical Transpot Start',calctime(curtime,0));

% Ramp all coil currents
AnalogFunc(calctime(curtime,0),'Coil 12a',...
    @(t,tt,y1,y2) z2i12a(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_12a);  
AnalogFunc(calctime(curtime,0),'Coil 12b',...
    @(t,tt,y1,y2) z2i12b(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_12b);  
AnalogFunc(calctime(curtime,0),'Coil 13',...
    @(t,tt,y1,y2) z2i13(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_13);  
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) z2i14(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_14);  
% Negative coil 15 shouldn't be a problem?
AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2) z2i15(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_15);  
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) z2i16(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_16);  


AnalogFunc(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2) z2v(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch);  
VH = V(end);

% Find the time at which Coil 15 crosses zero amps
tt = linspace(0,tV,1e4);
I15_vec=z2i15(ramp_minjerk(tt,tV,z_init,zMatch));
i0=length(tt)-find(flip(I15_vec)>0,1);
Tswitch = tt(i0);
disp(['Vertical Transport Time (ms)' num2str(tV)]);
disp(['Coil 15 Cross Over  Time (ms)' num2str(Tswitch)]);


% Turn on the 15/16 FET at the cross-over time
logNewSection('Transport Kitten Handoff : 15/16 GS On',calctime(curtime,Tswitch));
T1516delay = 0;
T_1516_ON = 25;
V_GS_HIGH = 9;
  AnalogFunc(calctime(curtime,Tswitch+T1516delay),'15/16 GS', ...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    T_1516_ON, T_1516_ON,1,V_GS_HIGH,1);   

% Kitten
dkI = 6;4.5; % Kitten offset in Amps
Tkittendelay = 0; % Time to delay turning off the kitten offset by
% Linearly decrease the kitten offset until zero
dkI_func = @(t) dkI*(1-t/(Tswitch+Tkittendelay)).*(t<=(Tswitch+Tkittendelay));
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) dkI_func(t)+z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    tV, tV, z_init,zMatch,func_k);  


% % Transport FF During Transport
% VH = 16;15;16;
% VT = v0;
% FF_start_time = 1500;
% FF_ramp_time = tV-FF_start_time;
% AnalogFunc(calctime(curtime,FF_start_time),'Transport FF',...
%     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%     FF_ramp_time, FF_ramp_time, VT,VH);




% Advance time to the match condition
curtime = calctime(curtime,tV);


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