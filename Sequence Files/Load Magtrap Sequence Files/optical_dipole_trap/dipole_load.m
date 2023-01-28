%------
%Author: C Fujiwara
%Created: Jan 2023
%Summary: Ramp the QP before QP transfer.
%Outputs are the currents/voltages
%after the ramp
%------
function [timeout,I_QP,I_shim,P1,P2] = dipole_load(timein, I_QP, V_QP,I_shim)

% This codes ramps the plugged magnetic trap into the crossed optical
% dipole trap. It also can turn on the dipole beams BACK IN TIME in case
% you want to try doing a quasi dimple during MT evaporation.
%
% Please, for the love off all that is sacred, don't make this code package
% too large. XDT operations can be done in other pieces of code.  This code
% is only meant to load the XDT initially.
%
% Becuase mode matching from the magnetic trap to the xdt is complicated
%%

curtime = timein;
global seqdata;


dispLineStr('Dipole Loading',curtime);

%% INTRODUCTION
% This code transfer the atomic cloud from the quadrupolar field into
% the crossed optical dipole trap.  This involves the following steps:
%
% (1) Ramp down the QP currents
% (2) Ramp on the ODT powers
% (3) Turn off the plug
% (4) Turn on the Feshbach bias field
% (5) Turn off transport fields
% (6) Turn off any other shims
%
% This code defins all of these ramps in a piecewise fashion

dT_TOT=0;

%% Optical Dipole Trap Settings 
% The specifications for the turn on of the optical dipole traps
% specified piecewise.  The time is in milliseconds and if reference in
% relation to the timein. The power is specified in watts

% XDT 1 
% Time and power vector for ODT 1
tXDT1 = [0 25];
pXDT1 = [0 1.5];   

% XDT 2
% Time and power vector for ODT 2
tXDT2 = [0 25];
pXDT2 = [0 1.5];       

% Display the results
disp(['XDT 1']);
disp([' Times  (ms) : ' mat2str(tXDT1)]);
disp([' Powers  (W) : ' mat2str(pXDT1)]);
disp(' ');
disp(['XDT 2']);
disp([' Times  (ms) : ' mat2str(tXDT2)]);
disp([' Powers  (W) : ' mat2str(pXDT2)]);
dT_TOT=max([tXDT1 tXDT2 dT_TOT]);
%% QP Currents Settings
% Timings and current for the QP coils.
% Vector for times and currents.
iQP = [I_QP 1.6 0];
tQP = [0    250 350];
disp(' ');
disp(['QP Currents']);
disp([' Times    (ms) : ' mat2str(tQP)]);
disp([' Currents  (A) : ' mat2str(iQP)]);
dT_TOT=max([dT_TOT tQP]);
%% Plug Settings
% Turn off the plug
tPlug = max(tQP); % Turn off plug once the QP currents are zero    
setDigitalChannel(calctime(curtime,tPlug),'Plug Shutter',0);
disp(' ');
disp('Plug');
disp([' Plug Off (ms)   : ' num2str(tPlug)]);

dT_TOT=max([dT_TOT tPlug]);
%% Feshbach Current Settings
tFB_start = tQP(end-1);
dT_FB = (tQP(end)-tQP(end-1));
iFB = 5.25392;

disp('Feshbach')
% disp([' Fesh On (ms) ' : 

dT_TOT=max([dT_TOT dT_FB+tFB_start]);
%% Optical Dipole Trap Ramp Commands    

% Enable ALPs feedback control and turn on XDTs AOMs

setDigitalChannel(calctime(curtime,min([tXDT1 tXDT2])),...
    'XDT Direct Control',0);
setDigitalChannel(calctime(curtime,min([tXDT1 tXDT2])),...
    'XDT TTL',0); 

%%%%%%%%%%%%%%%%%%%% XDT 1 Analog Ramps %%%%%%%%%%%%%%%%%%%%    
for kk=1:(length(tXDT1)-1)
    p1 = pXDT1(kk);
    p2 = pXDT1(kk+1);
    t0 = tXDT1(kk);
    dT = tXDT1(kk+1)-tXDT1(kk);   
    AnalogFunc(calctime(curtime,t0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT,dT,p1,p2);
end

%%%%%%%%%%%%%%%%%%%% XDT 2 Analog Ramps %%%%%%%%%%%%%%%%%%%%    
for kk=1:(length(tXDT2)-1)
    p1 = pXDT2(kk);
    p2 = pXDT2(kk+1);
    t0 = tXDT2(kk);
    dT = tXDT2(kk+1)-tXDT2(kk);        
    AnalogFunc(calctime(curtime,t0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT,dT,p1,p2);
end

%% QP and Shim Ramp down commands   
% XYZ shim coefficients to maintain trap center with I_QP (amps/amps)
Cx = -0.0499;
Cy = 0.0045;
Cz = 0.0105;    

% Starting shim currents;
I_shim;

if iQP(1)~=I_QP && tQP(1)~=0
   error(['The first entry of currents must be corresponding to the ' ...
       'value in RF1B']);
end

for kk=2:(length(tQP))        
    t0=tQP(kk-1);
    
    % Calculate feedforward 
    V_QP = I_QP*23/30;

    % Calculate the change in QP current
    dI_QP=(iQP(kk)-iQP(kk-1)); 

    % Calculate the change in shim currents
    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;             

    % Calculate the new shim values
    I_shim = I_shim + [dIx dIy dIz];        

    % Time interval of ramp
    dT = (tQP(kk)-tQP(kk-1));

    % Ramp the XYZ shims to new shim values
    AnalogFuncTo(calctime(curtime,t0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dT,dT,I_shim(3),3); 
    AnalogFuncTo(calctime(curtime,t0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dT,dT,I_shim(2),4); 
    AnalogFuncTo(calctime(curtime,t0),'X Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        dT,dT,I_shim(1),3); 

    % Ramp QP current
    AnalogFuncTo(calctime(curtime,t0),'Coil 16',...
        @(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),dT,dT,iQP(kk),2);

    % Ramp the feedforward
    AnalogFuncTo(calctime(curtime,t0),'Transport FF',...
        @(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),dT,dT,V_QP,2);   
end

%Use QP TTL to shut off coil 16 
setDigitalChannel(calctime(curtime,max(tQP)),21,1);

%Turn Coil 15 FET off
setAnalogChannel(calctime(curtime,max(tQP)),21,0,1);

%% Feshbach Ramp Commands
%     
% Switch Feshbach field on
setDigitalChannel(calctime(curtime,tFB_start-100),'fast FB Switch',1); 
% Switch Feshbach field closer to on
setAnalogChannel(calctime(curtime,tFB_start-95),'FB current',0.0);
% Switch Feshbach integrator on            
setDigitalChannel(calctime(curtime,tFB_start-100),'FB Integrator OFF',0); 


ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt); %try linear versus min jerk


% Linear ramp from zero
AnalogFunc(calctime(curtime,tFB_start),'FB current',...
    @(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dT_FB,dT_FB, iFB,0);

%% The end
    
% Relevant output parameters
I_QP = iQP(end);
I_shim = I_shim;
P1 = pXDT1(end);
P2 = pXDT2(end);

% Advance time based on all ramps
curtime=calctime(curtime,dT_TOT);

% Extra advance time because absorption imaging code is stupid
curtime=calctime(curtime,100);

timeout=curtime;
    
dispLineStr('Dipole Loading complete',curtime);

end
