function [timeout] = TransportCloud4(timein)
curtime = timein;
global seqdata;
%% Specify Vertical Transport

vertical_transport_time_1 = 3000;
data = load('transport_calcs.mat');

% Find distance where Coil 15 goes to zero (zd)
% We first transport to Coil 15 zero current as this is where kitten
% becomes relevant
zSwitch = data.zd*1e3;
i16Switch = data.i6(data.zz == data.zd);
i15Switch = data.i5(data.zz == data.zd);
i14Switch = data.i4(data.zz == data.zd);

% Minimum Jerk curve. 
% T is the ramp time; dY amount to change; t : time to evaluate [0,T] (typically a vector)
min_jerk = @(T,dY,t) (10*dY/T^3)*t.^3 - (15*dY/T^4)*t.^4 + (6*dY/T^5)*t.^5;                      

%%

iP = find(data.zz>=0.174,1);
i14_init = data.i4(iP);
i15_init = data.i5(iP);
i16_init = data.i6(iP);

ik_init = i16_init + i15_init;

Tme = 500;
AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,-.0179,i14_init,3);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme, 6.854,ik_init,3);
AnalogFunc(calctime(curtime,0),'Coil 16',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,18.36,i16_init,5);

curtime = calctime(curtime,Tme);



%% Travel Back to zd
ik_ramp_val =ik_init+5;
% ik_ramp_val =i16Switch-20;

AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,i14_init,i14Switch,3);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,ik_init,ik_ramp_val,3);
AnalogFunc(calctime(curtime,0),'Coil 16',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,i16_init,i16Switch,5);
 
 AnalogFunc(calctime(curtime,0),'Transport FF',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,12.25,25,2);
 
 curtime = calctime(curtime,Tme);
 
 AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,i14Switch,i14_init,3);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,ik_ramp_val,ik_init,3);
AnalogFunc(calctime(curtime,0),'Coil 16',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,i16Switch,i16_init,5);
  AnalogFunc(calctime(curtime,0),'Transport FF',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,25,12.25,2);
 
 curtime = calctime(curtime,Tme);
 
%%
 AnalogFunc(calctime(curtime,0),'Coil 14',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme,i14_init,-.0179,3);
AnalogFunc(calctime(curtime,0),'kitten',...
    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
    Tme, Tme, ik_init,6.854,3);
AnalogFunc(calctime(curtime,0),'Coil 16',...
     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
     Tme, Tme,i16_init,18.36,5);
curtime = calctime(curtime,Tme);
% i16Switch = data.i6(data.zz == data.zd);
% % i15Switch = data.i5(data.zz == data.zd);
% i14Switch = data.i4(data.zz == data.zd);


% curtime = doVerticalTransport_1(timein,T,D)

%% Vertical Transport 1
% % The coils change the MT to go from the center of 12a and 12b (z=0) to
% % the center of 14 and 16 (where Coil 15 current is zero).
% 
% dT1 = 0.5; % Time steps in ms
% 
% if mod(vertical_transport_time_1,dT1)
%     error('time step needs to be interger multiple of ramp time, sorru');
% end
% 
% tVec1 = (0:dT1:vertical_transport_time_1)';
% dVec1 = min_jerk(vertical_transport_time_1,zSwitch,tVec1);
% 
% AnalogFunc(calctime(curtime,0),'kitten',...
%     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%     2000, 2000, 0,60,3);
% 
% curtime = doVerticalTransport_1(calctime(curtime,0),tVec1,dVec1);

%% Switch to Kittten Regulation Mode
% % Now that the Coil 15 is nominally off, we now want to engage the 15/16
% % switch so that Coil 15 current may be run backwards.
% 
% % Setting Time
% curtime = calctime(curtime,10);
% 
% % Ramp Coil 15 to negative to make sure it is off
% curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
%     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%     200, 200, i15Switch,-1,5);
% 
% ikit_switch =i16Switch;
% 
% % Ramp the kitten regulation to the same level as Coil 16
% curtime = AnalogFunc(calctime(curtime,0),'kitten',...
%     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%     1000, 1000, 60,ikit_switch,3);
% 
% % Settling Time
% curtime = calctime(curtime,100);
% 
% % Engage 15/16 switch
% setDigitalChannel(calctime(curtime,0),'15/16 Switch',1);

%% Ramp kitten and Coil 16 to the new values
% Now that Coil 15 is reverse polarity (and is controlled using the kittena
% % and Coil 16), we move the QP trap to th
% Tfinal = 500;

% 
% curtime = AnalogFunc(calctime(curtime,0),'Transport FF',...
%     @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%     Tfinal, Tfinal,15,12.25,2);

%% Ending Stuff
timeout = curtime;

end

