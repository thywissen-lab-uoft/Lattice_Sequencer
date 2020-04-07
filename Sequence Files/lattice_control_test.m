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
      P_lattice = 0.6; %0.5/0.9        % The fraction of power that will be transmitted 
      curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
      curtime = calctime(curtime,1000);
% %       setDigitalChannel(calctime(curtime,0),'yLatticeOFF',0);
% %       setDigitalChannel(calctime(curtime,10),'yLatticeOFF',1);
%       
%       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %      setAnalogChannel(calctime(curtime,0),'Plug Beam',10,1);
% %         freq_list = [1e-3]; 
% %         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% %         mod_amp=0.01;
% %         pzt_ref_xdt1_list= [0:0.5:10];
% % %         pzt_ref_xdt2_list= [10];
% %         pzt_xdt1_ref = getScanParameter(pzt_ref_xdt1_list,seqdata.scancycle,seqdata.randcyclelist,'pzt_xdt1_ref')-mod_amp/2;
% % %         pzt_xdt2_ref = getScanParameter(pzt_ref_xdt2_list,seqdata.scancycle,seqdata.randcyclelist,'pzt_xdt2_ref')-mod_amp/2;
% % %         pzt_xdt2_ref = sqrt(25-(pzt_xdt1_ref-5)^2)+5;
% % %         addOutputParam('pzt_xdt2_ref',pzt_xdt2_ref);
% %      str1 = sprintf('SOUR1:APPL:SQUare;SOUR1:FREQ %g;SOUR1:VOLT %g;SOUR1:VOLT:OFFS %g;',mod_freq, mod_amp, pzt_xdt1_ref);   
% % % str1 = sprintf('SOUR1:APPL:SQUare;SOUR1:FREQ %g;SOUR1:VOLT %g;SOUR1:VOLT:OFFS %g;SOUR2:APPL:SQUare;SOUR2:FREQ %g;SOUR2:VOLT %g;SOUR2:VOLT:OFFS %g;',mod_freq, mod_amp, pzt_xdt1_ref,mod_freq, mod_amp, pzt_xdt2_ref);
% %         addVISACommand(2, str1);       
% %         
% %         ScopeTriggerPulse(curtime,'ttl_test');
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
% %         curtime = calctime(curtime,500);
% %         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);
%       
%       
% % %       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %     setDigitalChannel(calctime(curtime,-15),'Plug TTL',1);%turn off AOM TTL
% %     setDigitalChannel(calctime(curtime,0),'Plug Shutter',1);% turn ON AOM shutter
% %     setDigitalChannel(calctime(curtime,0),'Plug TTL',0);% turn ON AOM TTL
% %     setDigitalChannel(calctime(curtime,0),'Plug Mode Switch',0);
% %     setAnalogChannel(calctime(curtime,0),'Plug Beam',5,1);% Plug power reference voltage
% %     curtime = calctime(curtime, 5000);
% % %     setDigitalChannel(calctime(curtime,0),'Plug Shutter',1);% turn ON AOM shutter
% % %     setDigitalChannel(calctime(curtime,20),'Plug Mode Switch',0);
% %    
% %    
% %    
% %     
% %     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% turn ON AOM shutter
% %     setDigitalChannel(calctime(curtime,0),'Plug Mode Switch',1);
% %     setAnalogChannel(calctime(curtime,0),'Plug Beam',10,1);% Plug power reference voltage
% 
% %     curtime = calctime(curtime, 20000);
% %     setAnalogChannel(calctime(curtime,0),'Plug Beam',0,1);
% %     curtime = calctime(curtime, 400);
% %      curtime =AnalogFuncTo(calctime(curtime,0),'Plug Beam',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 100, 100,5.5,1);
% %      curtime = calctime(curtime, 1000);
% %      curtime = AnalogFuncTo(calctime(curtime,0),'Plug Beam',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1000, 1000,-10,1);
% % % %     setAnalogChannel(calctime(curtime,0),'Plug Beam',-1,1);
% %      setDigitalChannel(calctime(curtime,0),'Plug TTL',1);
% %      setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);  % turn off shutter
% %      setDigitalChannel(calctime(curtime,30),'Plug TTL',0); % turn on AOM TTL
% 
% %     setAnalogChannel(calctime(curtime,30),'Plug Beam',1,1);
% %     curtime = calctime(curtime, 35);
% %       
%       
% %       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %       
% %       
%       
% %       
% % %       % % %     
% % % % % % %     setDigitalChannel(calctime(curtime,0),11,0);%11: x lattice off
% % % % % %     
% % % % %     lattice_depth = 0.1 * [0.1*111 0.1*111 0.1*111; 0.1*80 0.1*80 0.1*80; 0.1*20 0.1*20 0.1*20]/0.4;
%     xxx=800;
    atomscale = 0.4;
    lattice_depth = [-0.625 6.3 6.15]/atomscale;  [1.1 1.17 1.24]/atomscale;[3 2.33 800]; %[0 0.82 0.87]
%        lattice_depth = [xxx,xxx,xxx]/atomscale;
% % %     lattice_depth = 1 * [111 111 111; 73 73 73; 33 33 33]/0.4;
    ramp_time = 50;
    
    voltage_func = 2;
    zero = [-9.99,0];
    
    curtime = calctime(curtime,100);    
    
    setAnalogChannel(calctime(curtime,-70),'yLattice',-10,1);
    setAnalogChannel(calctime(curtime,-70),'zLattice',-10,1);
    setAnalogChannel(calctime(curtime,-70),'xLattice',-0.3,1);
    
    % enable rf output and use integrator
%     setDigitalChannel(calctime(curtime,-5),'xLatticeOFF',0);%0: ON
    setDigitalChannel(calctime(curtime,-3),'yLatticeOFF',0);%0: ON
%     setDigitalChannel(calctime(curtime,-5),'Z Lattice TTL',0);%0: ON
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',0);% 0: Enable Feedback
        setDigitalChannel(calctime(curtime,0),'ScopeTrigger',0);
    setDigitalChannel(calctime(curtime,1),'ScopeTrigger',1);
%     setAnalogChannel(curtime,'zLattice',5,1);
%     curtime=calctime(curtime,5000);
%     setAnalogChannel(curtime,'zLattice',-10,1);

%     ScopeTriggerPulse(calctime(curtime,110),'Load lattices');
%     %ramp up lattice

% ScopeTriggerPulse(curtime,'lattice control test');
%     AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, -1,-1,voltage_func);
%     AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, -1,-1,voltage_func);
%     curtime = AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,-1, -1,voltage_func);
    curtime = calctime(curtime,100);

    AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),lattice_depth(1),voltage_func);
    AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, zero(voltage_func),lattice_depth(2),voltage_func);
    curtime = AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,zero(voltage_func), lattice_depth(3),voltage_func);
% 
    curtime = calctime(curtime,1000);
    %ramp down lattice
    AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,-1,1);
    AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,zero(1),1);
    curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time,zero(2),1);
% % % %     setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);
% % % %     setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
% % % %     setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);
% %     
%     
    % waiting 10 ms
    curtime = calctime(curtime,10);

%     setDigitalChannel(calctime(curtime,5),'xLatticeOFF',1);%0: ON
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);%0: ON
%     setDigitalChannel(calctime(curtime,5),'Z Lattice TTL',1);%0: ON
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);
% %     
    curtime = calctime(curtime,5000);
    P_End = 1.0;
    AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_lattice,P_End); 
    curtime = calctime(curtime,500);

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

