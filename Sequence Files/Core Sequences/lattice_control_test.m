%------
%Author: 
%Created: 
%Summary: 
%------

function timeout = lattice_control_test(timein)

curtime = timein;
curtime = calctime(curtime, 1000);

scope_trigger =  'lattice control test';'Rampup ODT';
%%
      rotation_time = 1000;   % The time to rotate the waveplate
      P_lattice = 1.0; %0.5/0.9        % The fraction of power that will be transmitted 
      curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
      curtime = calctime(curtime,1000);
        
        lattice_depth = [-10 -10 -10];  [1.1 1.17 1.24];[3 2.33 800]; %[0 0.82 0.87]
        ramp_time = 50;
        voltage_func = 2;
        zero = [-9.99,0];

 
    % Initialize lattice depths to zero
    curtime = calctime(curtime,100);   
    setAnalogChannel(calctime(curtime,-70),'yLattice',-0.1,1);
    setAnalogChannel(calctime(curtime,-70),'zLattice',-0.1,1);
    setAnalogChannel(calctime(curtime,-70),'xLattice',-0.3,1);
    
    % Turn on Lattice RF
%     setDigitalChannel(calctime(curtime,-5),'xLatticeOFF',0);%0: ON
    setDigitalChannel(calctime(curtime,-3),'yLatticeOFF',0);%0: ON
%     setDigitalChannel(calctime(curtime,-5),'Z Lattice TTL',0);%0:  ON

    % Enable lattice integrator feedback
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',0);% 0: Enable Feedback
    

    

% Ramp up lattices
    curtime = calctime(curtime,1000);
    
        % Trigger the scope
    setDigitalChannel(calctime(curtime,0),'ScopeTrigger',0);
    setDigitalChannel(calctime(curtime,1),'ScopeTrigger',1);
    
    AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),lattice_depth(1),voltage_func);
%     AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),7.5,1);
    
    AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),lattice_depth(2),voltage_func);
    curtime = AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),lattice_depth(3),voltage_func);
%     curtime = AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),0,1);

    curtime = calctime(curtime,200);
    %ramp down lattice
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,-1,1);
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,zero(1),1);
    curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,zero(2),1);
% % %     setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);
% % %     setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
% % %     setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);


%     % Lattice mode test    
%     ch2=struct;
%     ch2.FREQUENCY=200E3;
%     ch2.AMPLITUDE_UNIT='VPP';
%     ch2.AMPLITUDE=1.1E-5*(ch2.FREQUENCY/1000)^2-0.00092*(ch2.FREQUENCY/1000)+0.04;
%     
%     ch2.AMPLITUDE=1.1E-5*(60+ch2.FREQUENCY/1000)^2-0.00092*(60+ch2.FREQUENCY/1000)+0.04;
% 
%     ch2.BURST='ON';
%     ch2.BURST_MODE='GATED';
%     ch2.BURST_TRIGGER_SLOPE='POS';
%     ch2.BURST_TRIGGER='EXT';    
%     
%     programRigol(5,[],ch2);
%     setDigitalChannel(calctime(curtime,0),51,0);
%     setDigitalChannel(calctime(curtime,0),51,1);
%     ScopeTriggerPulse(calctime(curtime,0),'Lattice_Mod');
%     SelectScopeTrigger('Lattice_Mod');
% %     setDigitalChannel(calctime(curtime,-1),'Lattice Direct Control',1);
% 
%     curtime = calctime(curtime,10);
%     setDigitalChannel(calctime(curtime,0),51,0);
%     setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',0);

% %     
%     % waiting 10 ms
%     curtime = calctime(curtime,10);

    % Turn lattices RF off
%     setDigitalChannel(calctime(curtime,5),'xLatticeOFF',1);%0: ON
%     setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);%0: ON
%     setDigitalChannel(calctime(curtime,5),'Z Lattice TTL',1);%0: ON
% %     
%     curtime = calctime(curtime,5000);
%     P_End = 1.0;
%     AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_lattice,P_End); 
%     curtime = calctime(curtime,500);
%     setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',0);



%% xdt power

%       rotation_time = 1000;   % The time to rotate the waveplate
%       P_latticeI = 0; %0.5/0.9        % The fraction of power that will be transmitted 
%       curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_latticeI);
% curtime = calctime (curtime,3000);
%       
%     xdt1_power=0.2;
%     xdt2_power=0.2;
% 
%     dipole_ramp_up_time = 50;
%     setDigitalChannel(calctime(curtime,0),'XDT TTL',0);
%     %ramp dipole 1 trap on
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0)
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0)
%     AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_ramp_up_time,dipole_ramp_up_time,xdt1_power);
%     %ramp dipole 2 trap on
%     AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_ramp_up_time,dipole_ramp_up_time,xdt2_power);
% curtime = calctime (curtime,3000);
%     ScopeTriggerPulse(curtime,'Rampup ODT');
%     
%     
%     rotation_time = 1000;   % The time to rotate the waveplate
%     P_latticeII = 0; %0.5/0.9        % The fraction of power that will be transmitted 
% curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),rotation_time,rotation_time,P_latticeI,P_latticeII); 
% 

%% new ramp
% curtime = calctime(curtime,1000);
% setAnalogChannel(curtime,'xLattice',10);
% setAnalogChannel(curtime,'yLattice',10);
% setAnalogChannel(curtime,'zLattice',10);
% 
% tau1=100;
% 
%         AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,tau,y2)(ramp_exp_lat(t,tt,tau,y2,y1)),1000,1000,tau1,20);
%% new control
% %       rotation_time = 1000;   % The time to rotate the waveplate
% %       P_lattice = 0.8; %0.5/0.9        % The fraction of power that will be transmitted 
% %       curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
% %       curtime = calctime(curtime,1000);
% %       
% %       
% %       
% %     atomscale = 0.4;
% %     lattice_depth = [2.2 2.3 2.2]/atomscale;[1.1 1.17 1.24]/atomscale;[3 2.33 800]; %[0 0.82 0.87]
% %     ramp_time = 50;
% %     
% %     setAnalogChannel(calctime(curtime,-70),'yLattice',-10,1);
% %     setAnalogChannel(calctime(curtime,-70),'zLattice',-10,1);
% %     setAnalogChannel(calctime(curtime,-70),'xLattice',-0.3,1);
% %   
% %     setDigitalChannel(calctime(curtime,-5),'yLatticeOFF',0);%0: ON
% %     setDigitalChannel(calctime(curtime,-5),'ScopeTrigger',1);
% %     setDigitalChannel(calctime(curtime,1),'ScopeTrigger',0);
% %     
% % %         setAnalogChannel(calctime(curtime,1),'xLattice',1,1);
% %  curtime= AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1000, 1000, 4,1);
% % %  curtime =    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 1000, 1000,1,1);
% % %       curtime = calctime(curtime,500);
% %     
% %     curtime = calctime(curtime,2000);
% %     setDigitalChannel(calctime(curtime,-5),'yLatticeOFF',1);%0: ON
% %     curtime = calctime(curtime,2000);
%     
%% End
%       rotation_time = 1000;   % The time to rotate the waveplate
%       P_lattice = 0.0; %0.5/0.9        % The fraction of power that will be transmitted 
%       curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
%       curtime = calctime(curtime,1000);


curtime = calctime(curtime,1000);
timeout = curtime;

% SelectScopeTrigger('Load lattices')
end

