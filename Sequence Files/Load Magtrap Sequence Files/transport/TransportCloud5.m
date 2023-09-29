
function timeout = TransportCloud5(timein)
% TransportCloud2.m
%
% Author : C. Fujiwara
% Date : 2023/09/28
%

curtime = timein;
global seqdata;
dispLineStr('TRANSPORT',curtime);

%% Horizontal Transport
% This is still done using the old transport code
%Distance to the second zone and time to get there
D1 = 300; %300
T1 = 1800; %1800
%Distance to the third zone and time to get there
Dm = 45; %45
Tm =1000; %1000
%Distance to the fourth zone and time to get there
D2 = 20; %15
T2 = 500; %600

% Where the currents actually get set (special arguement)
curtime = AnalogFunc(calctime(curtime,0),0, ...
    @(t,d1,t1,dm,tm,d2,t2) (for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)), ...
    T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);

%% Vertical Transport Splines
data=load('transport_calcs_60G.mat');


% Boundary condition which matches with horizontal transport
i12a_hf = 18.889;i12b_hf = -18.889;
i12a_vi = -data.i1(1); i12b_vi = -data.i2(1);

defVar('transport_vert_t_match_horz',100,'ms')

% Boundary condition which matches with "old" transport
zMatch = 0.1763;     % Position chosen to match end of normal transport
i14_Match = [0 interp1(data.zz,data.i4,zMatch)];
i15_Match = [-10.21 interp1(data.zz,data.i5,zMatch)];
i16_Match = [18.35 interp1(data.zz,data.i6,zMatch)];  
t_h2v = 500;
defVar('transport_vert_t_match_vert',500,'ms')


t_v2e = 500;

% Convert position along transport into currents
z2i12a = @(z) interp1(data.zz,-data.i1,z);
z2i12b = @(z) interp1(data.zz,-data.i2,z);
z2i13 = @(z) interp1(data.zz,data.i3,z);
z2i14 = @(z) interp1(data.zz,data.i4,z);
z2i15 = @(z) interp1(data.zz,data.i5,z);
z2i16 = @(z) interp1(data.zz,data.i6,z);
z2ik = @(z) interp1(data.zz,data.i6+data.i5,z);

% Voltage Function indeces that convert current to request voltage
func_12a = 3;
func_12b = 3;
func_13 = 3;
func_14 = 3;
func_15 = 5;
func_16 = 5;
func_k = 4;

%% Ramp 12a and 12b from end Horizontal to beggining vertical

AnalogFunc(calctime(curtime,0),'Coil 12a',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_h2v, t_h2v, i12a_hf,i12a_vi,func_12a);
AnalogFunc(calctime(curtime,0),'Coil 12b',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_h2v, t_h2v, i12b_hf,i12b_vi,func_12b);
curtime = calctime(curtime,t_h2v);

%% Transport to 153 mm
t_init2cross = 3000;
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

% Kitten doesn't regulate during this time, so have it request a bit more
% than what it needs to and it will rail its output
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) 1+z2ik(ramp_minjerk(t,tt,y1,y2)), ...
    t_init2cross, t_init2cross, z_init,z_cross_i,func_k);  

curtime = calctime(curtime,t_init2cross);

%% Handoff from 153 to 155 mm

V0 = 5.5;
VM = 2.7;
VL = 2.1;


t_prep = 10;      % Time to prepare for switch over
t_cross = 200;    % Crossover time
t_prep2 = 50;    % Time to ramp up GS voltage all the way


% Calculate currents at the crossing region
i14_cross_i = z2i14(z_cross_i);i14_cross_f = z2i14(z_cross_f);
ik_cross_i = z2ik(z_cross_i);ik_cross_f = z2ik(z_cross_f);
i16_cross_i = z2i16(z_cross_i);i16_cross_f = z2i16(z_cross_f);


%%%%%% Prepare for handoff %%%%%

% Ramp Coil 15 to negative to make sure it is off
AnalogFunc(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_prep, t_prep, 0,-1,func_15);  
% Ramp 15/16 GS to right below where the current begins regulating
AnalogFunc(calctime(curtime,0),'15/16 GS',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_prep, t_prep, 0,VL,1);  
curtime = calctime(curtime,t_prep);
%%%%%%% Perform the Handoff %%%%%%%

% Ramp GS of 15/16 to allow current through
AnalogFunc(calctime(curtime,0),'15/16 GS',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_cross, t_cross, VL,VM,1);   
% Ramp Coil 16
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_cross, t_cross, i16_cross_i,i16_cross_f,func_16);  
% Ramp Coil 14
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_cross, t_cross, i14_cross_i,i14_cross_f,func_14); 
% Ramp Kitten
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
    t_cross, t_cross, ik_cross_i+1,ik_cross_f,func_k);       
curtime = calctime(curtime,t_cross);

%%%%%%% Allow for maximum current %%%%%%%

curtime =  AnalogFunc(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            t_prep2, t_prep2, VM,V0,1); 


%% Ramp to End of Transport
t_cross2end = 1000;

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
      
%% Match Boundary Condition


AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_v2e, t_v2e, i14_Match(2),i14_Match(1),func_14);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_v2e, t_v2e, i16_Match(2)+i15_Match(2),i16_Match(1)+i15_Match(1),func_k);
AnalogFunc(calctime(curtime,0),'Coil 16',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    t_v2e, t_v2e, i16_Match(2),i16_Match(1),func_16);    
curtime = calctime(curtime,t_v2e);
%%
timeout = curtime;
 
end