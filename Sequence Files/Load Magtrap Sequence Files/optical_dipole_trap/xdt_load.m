function [timeout, I_QP, V_QP,I_shim] = xdt_load(timein, I_QP, V_QP,I_shim)
%% xdt_load.m
% Author : C Fujiwara
%
% This code loads the dipole trap from the magnetic trap.  The loading is
% done in two stages.  In the first stage, the magnetic field gradient is
% ramped down to relax the trap, while the optical powers are turned up.
%
% In the second stage the magnetic field gradient is ramped completely off
% while the feshbach field is increaesd to maintain the quantization axis.
% The optical powers are also ramped to their final values.
%
% After the optical trap has been loaded, the plug beam is turned off.

%%
curtime = timein;
global seqdata;

ScopeTriggerPulse(curtime,'xdt_load');

%% Flags

seqdata.flags.xdt_qp_ramp_down1         = 1;
seqdata.flags.xdt_qp_ramp_down2         = 1;
seqdata.flags.xdt_plug_off              = 1;

ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt); %try linear versus min jerk
%ramp_func = @(t,tt,y2,y1)(minimum_jerk(t,tt,y2-y1)+y1); 
    
%% XDT Powers

P1_load = getVar('xdt1_load_power');  
P2_load = getVar('xdt2_load_power');  

dipole_ramp_up_time = getVar('xdt_load_time');

DT2_power(2)=  P2_load;
DT1_power(2) = P1_load; 

% Plug Shim Z Slope delta
dCz_list = [-0.005];-.002;[-.0025];
dCz = getScanParameter(dCz_list,seqdata.scancycle,...
    seqdata.randcyclelist,'dCz','arb.');  

%% XDT Optical Power Ramp up
% Optical powers are increased to load into the optical dipole trap.

logNewSection('ODT ramp up started at',calctime(curtime,0));

% Turn on XDT AOMs
setDigitalChannel(calctime(curtime,-10),'XDT TTL',0);  
% Ramp dipole 1 trap on
AnalogFunc(calctime(curtime,0),...
    'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    dipole_ramp_up_time,dipole_ramp_up_time,seqdata.params.ODT_zeros(1),P1_load);
% Ramp dipole 2 trap on
AnalogFunc(calctime(curtime,0),...
    'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    dipole_ramp_up_time,dipole_ramp_up_time,seqdata.params.ODT_zeros(2),P2_load);
    
%% Ramp the QP Down    
% Ramp QP currents down to release the magnetic trap. A very small residual
% magnetic trap is left in order to maintain a quantiziation field

% Make sure shims are allowed to be bipolar (not necessary?)
setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);

% QP1 Value
QP_ramp_end1_list = [0.9];0.9;
QP_ramp_end1 = getScanParameter(QP_ramp_end1_list*1.78,seqdata.scancycle,...
    seqdata.randcyclelist,'QP_ramp_end1');

% QP1 Time
qp_ramp_down_time1_list = [300];[250];[250];
qp_ramp_down_time1 = getScanParameter(qp_ramp_down_time1_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time1','ms');        

% QP2 Value
QP_ramp_end2 = 0*1.78; 
qp_ramp_down_time2_list = [100];100;
qp_ramp_down_time2 = getScanParameter(qp_ramp_down_time2_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qp_ramp_down_time2','ms');        

% Fesh values
%Calculated resonant fesh current. Feb 6th. %Rb: 21, K: 21
mean_fesh_current = 5.25392;%before 2017-1-6   22.6/4; 
fesh_current = mean_fesh_current;

% Transport supply voltage check
vSet_ramp = 1.07*V_QP; %24   
% Check thermal power dissipation
if vSet_ramp^2/4/(2*0.310) > 700
    error('Too much power dropped across FETS');
end

%% QP Ramp Down
if seqdata.flags.xdt_qp_ramp_down1  
    logNewSection('QP RAMP DOWN 1',curtime);

    % Calculate the change in QP current
    dI_QP=QP_ramp_end1-I_QP; 

    % Calculate the change in shim currents
    Cx = seqdata.params.plug_shims_slopes(1);
    Cy = seqdata.params.plug_shims_slopes(2);
    Cz = seqdata.params.plug_shims_slopes(3)+dCz;

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   

    % Calculate the new shim values
    I_shim = I_shim + [dIx dIy dIz];        

    % Ramp the XYZ shims to new shim values
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(3),3); 
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(2),4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,I_shim(1),3); 

    % Ramp down FF.
    AnalogFuncTo(calctime(curtime,0),...
        'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1*23/30);

    % Ramp down QP and advance time
    curtime = AnalogFuncTo(calctime(curtime,0),...
        'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time1,qp_ramp_down_time1,QP_ramp_end1);

    % Some extra advances in time (WHAT IS THIS FOR?)
    if (dipole_ramp_up_time)>(qp_ramp_down_time1)
        curtime =   calctime(curtime,...
            (dipole_ramp_up_time)-(qp_ramp_down_time1));
    end

    I_QP  = QP_ramp_end1; 
end
    
%% QP-FB Ramp Ramp Down 2
% Completely turn off the QP fields and ramp up the Feshbach field to
% establish the quantization field.

if seqdata.flags.xdt_qp_ramp_down2

    logNewSection('QP RAMP DOWN 2',curtime);

    XDT_pin_time_list = [0];
    XDT_pin_time = getScanParameter(XDT_pin_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'XDT_pin_time'); 
   
    % Ramp ODT2
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        XDT_pin_time,XDT_pin_time,DT2_power(2));

    % Ramp ODT1
    curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        XDT_pin_time,XDT_pin_time,DT1_power(2));

    % Ramp Feshbach field
    FB_time_list = [0];
    FB_time = getScanParameter(FB_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'FB_time');
    setDigitalChannel(calctime(curtime,-100-FB_time),'fast FB Switch',1); %switch Feshbach field on
    setAnalogChannel(calctime(curtime,-95-FB_time),'FB current',0.05); %switch Feshbach field closer to on
    setDigitalChannel(calctime(curtime,-100-FB_time),'FB Integrator OFF',0); %switch Feshbach integrator on            
    
    % Ramp up FB Current
    AnalogFunc(calctime(curtime,0-FB_time),'FB current',...
        @(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),...
        qp_ramp_down_time2+FB_time,qp_ramp_down_time2+FB_time, fesh_current,0.05);
    fesh_current_val = fesh_current;    

    % Ramp down Feedforward voltage
    AnalogFuncTo(calctime(curtime,0),...
        'Transport FF',@(t,tt,y2,y1)(ramp_func(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2*23/30);      

    % Ramp down QP currents
    AnalogFuncTo(calctime(curtime,0),...
        'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,QP_ramp_end2);

    % Calculate the change in QP currents
    dI_QP=QP_ramp_end2-QP_ramp_end1; 

    % Calculate the change in shim currents
    Cx = seqdata.params.plug_shims_slopes(1);
    Cy = seqdata.params.plug_shims_slopes(2);
    Cz = seqdata.params.plug_shims_slopes(3)+dCz;         

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;    

    % Calculate the new shim values
    I_shim = I_shim + [dIx dIy dIz];

    % Ramp shims
    AnalogFuncTo(calctime(curtime,0),'Z shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(3),3); 
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(2),4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim'....
        ,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        qp_ramp_down_time2,qp_ramp_down_time2,I_shim(1),3);

    % Save the shim values (appears unused?)
    seqdata.params.yshim_val = I_shim(2);
    seqdata.params.xshim_val = I_shim(1);
    seqdata.params.zshim_val = I_shim(3);

    % Advance time (CF: this seems weirdly defined?)
    curtime = calctime(curtime,qp_ramp_down_time2);   

    I_QP  = QP_ramp_end2;

    if QP_ramp_end2 <= 0 % second rampdown segment concludes QP rampdown
        setAnalogChannel(calctime(curtime,0),1,0);%1
        %set all transport coils to zero (except MOT)
        for i = [7 8 9:17 22:24 20] 
            setAnalogChannel(calctime(curtime,0),i,0,1);
        end
    end
end

V_QP = vSet_ramp;

%% Plug Turn off
% Turn off the plug beam now that the QP coils are off
if seqdata.flags.xdt_plug_off
    plug_turnoff_time_list =[0]; -200;
    plug_turnoff_time = getScanParameter(plug_turnoff_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'plug_turnoff_time');
    setDigitalChannel(calctime(curtime,plug_turnoff_time),'Plug Shutter',0);%0:OFF; 1:ON; -200
    logNewSection('Turning off plug ',calctime(curtime,plug_turnoff_time));
end
%% Turn Off Voltage on Transport and Shim Supply 

ScopeTriggerPulse(calctime(curtime,0),'Transport Supply Off');
%Use QP TTL to shut off coil 16 
setDigitalChannel(calctime(curtime,0),'Coil 16 TTL',1);
%Turn Coil 15 FET off
setAnalogChannel(calctime(curtime,0),'Coil 15',0,1);

%% Extra Wait

if ~seqdata.flags.xdt_pre_evap
   curtime = calctime(curtime,100); 
end


%% Exit

timeout = curtime;
end

