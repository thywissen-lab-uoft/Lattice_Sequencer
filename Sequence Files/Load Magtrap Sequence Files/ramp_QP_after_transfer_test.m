%------
%Author: Vijin
%Created: Dec 2020
%Summary: Ramp the QP to a different gradient without changing the trap
%center
%------


function [timeout I_QP I_kitt V_QP I_fesh] = ramp_QP_after_transfer_test(timein, ramp_down_QP_before_transfer, I_QP, I_kitt, V_QP, I_fesh)


curtime = timein;
global seqdata;

if ramp_down_QP_before_transfer

% Get the kitten and QP currents. Also grab the voltage set point
QP_value = I_QP;                % QP Current
Kitten_curval = I_kitt;         % Kitten Vlalue
Kitten_value = Kitten_curval;
vSet = V_QP;
    
%Final Gradient ramp factor
ramp_factor_list = [1];
ramp_factor = getScanParameter(ramp_factor_list,seqdata.scancycle,...
    seqdata.randcyclelist,'ramp_factorB');

% Ramp time list
QP_ramp_time_list = [100];
QP_ramp_time = getScanParameter(QP_ramp_time_list,seqdata.scancycle,...
    seqdata.randcyclelist,'QP_ramptime');
QP_curval = QP_value;

% Grab the initial shim currents. It is assumed that the shims have already
% been set the plug shim values (CF: is this correct?)
Zshim_curval = seqdata.params.plug_shims(3); % The current, current value  
Yshim_curval = seqdata.params.plug_shims(2);
Xshim_curval = seqdata.params.plug_shims(1);


% This doesn't appear to be used?
%Feshval = 0;
Feshval = I_fesh ;
    

% The new QP current value
QP_value = QP_curval*ramp_factor; 

% The new feed forawrd voltage level
vSet_ramp = 22.0*ramp_factor*1.2; %24 %DCM added 1.2 Aug 18

% The plug new plug shim value
% Xshim_value = -1.32*ramp_factor+0.098; % 2020/12/11
% Yshim_value = Yshim_curval*ramp_factor;
% Zshim_value = 0.1*ramp_factor+0.025;    % 2020/12/11

% Calbiration by CF on 12/25/2020

% Get the RF1B currents. This is the MT center you want to maintain.
I_QP0=26.4;
I0=seqdata.params.plug_shims;
Ix0=I0(1);Iy0=I0(2);Iz0=I0(3);

% How much the QP currents have changed by
dI_QP=QP_value-I_QP0;

% The shift in currents is linearly proportional to the QP currents shift
dIx=dI_QP*-0.0499;
dIy=dI_QP*0.0045;
dIz=dI_QP*0.0105;

% Calculate the new shim
Xshim_value=Ix0+dIx;
Yshim_value=Iy0+dIy;
Zshim_value=Iz0+dIz;


disp('%%%%%%');
disp(['  I_QP init : ' num2str(I_QP)]);
disp(['  I_K init : ' num2str(I_kitt)]);
disp(['  I_X init : ' num2str(Xshim_curval)]);
disp(['  I_Y init : ' num2str(Yshim_curval)]);
disp(['  I_Z init : ' num2str(Zshim_curval)]);
disp(' ');
disp(['  I_QP end : ' num2str(QP_value)]);
disp(['  I_K end  : ' num2str(I_kitt)]);
disp(['  I_X end  : ' num2str(Xshim_value)]);
disp(['  I_Y end  : ' num2str(Yshim_value)]);
disp(['  I_Z end  : ' num2str(Zshim_value)]);
disp('%%%%%');


    
if vSet_ramp^2/4/(2*0.310) > 700
    error('Too much power dropped across FETS');
end

 % Ramp Feshbach if necessary
 if Feshval>0
    AnalogFunc(calctime(curtime,0),38,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+Feshval),QP_ramp_time,QP_ramp_time,Feshval);
 end

% Ramp voltage feed forward
 AnalogFunc(calctime(curtime,20),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet),QP_ramp_time,QP_ramp_time,vSet_ramp-vSet);

% Ramp coil 16
 AnalogFunc(calctime(curtime,20),1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_curval),QP_ramp_time,QP_ramp_time,QP_value-QP_curval);

% Ramp shims and advance time
AnalogFunc(calctime(curtime,20),'Y Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Yshim_curval),QP_ramp_time,QP_ramp_time,Yshim_value-Yshim_curval,4); 
AnalogFunc(calctime(curtime,20),'X Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Xshim_curval),QP_ramp_time,QP_ramp_time,Xshim_value-Xshim_curval,3); 
curtime = AnalogFunc(calctime(curtime,20),'Z Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Zshim_curval),QP_ramp_time,QP_ramp_time,Zshim_value-Zshim_curval,3); 
    

%set kitten gate voltage to zero
if Kitten_value==0        
    setAnalogChannel(calctime(curtime,0),3,0,1);        
    %physical disconnect kitten
    %make kitten relay an open switch
    setDigitalChannel(calctime(curtime,30),29,0);        
end

% Hold at the new ramp factor
hold_time_list = [50];
hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'QP_hold_time');
curtime = calctime(curtime,hold_time);
%     
% Ramp voltage feed forward
AnalogFunc(calctime(curtime,0),18,@(t,tt,dt)(minimum_jerk(t,tt,dt)+vSet_ramp),QP_ramp_time,QP_ramp_time,-vSet_ramp+vSet);

% Ramp coil 16 back to original value
AnalogFunc(calctime(curtime,0),1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_value),QP_ramp_time,QP_ramp_time,-QP_value+QP_curval);

% Ramp shims to original values and advance time
AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Yshim_value),QP_ramp_time,QP_ramp_time,-Yshim_value+Yshim_curval,4); 
AnalogFunc(calctime(curtime,0),'X Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Xshim_value),QP_ramp_time,QP_ramp_time,-Xshim_value+Xshim_curval,3); 
curtime = AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,dt)(minimum_jerk(t,tt,dt)+Zshim_value),QP_ramp_time,QP_ramp_time,-Zshim_value+Zshim_curval,3); 

% Wait an additional 10 ms
curtime = calctime(curtime,10);
    
% Output the current values       
I_QP  = QP_value;
I_kitt = Kitten_value;
V_QP = vSet_ramp;
I_fesh = Feshval;
    
else
    
%     I_QP  = QP_value;
%     I_kitt = Kitten_curval;
%     V_QP = vSet;

end


timeout = curtime;

end