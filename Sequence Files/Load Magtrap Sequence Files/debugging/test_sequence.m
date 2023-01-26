%------
%Author: David McKay
%Created: July 2009
%Summary: This is a test sequence
%------

function timeout = test_sequence(timein)

curtime = timein;

global seqdata;

RF_switch_gain_test = 0;
acync_test = 0;

% setAnalogChannel(calctime(curtime,0),43,-1)
% DigitalPulse(calctime(curtime,0),'RaspPi Trig',1000,1)

%% Test iXon with new function

% seqdata.flags. load_lattice = 1;
% seqdata.flags. SRS_programmed = [0 0];
% seqdata.flags. do_stern_gerlach = 0;
% seqdata.flags. do_imaging_molasses = 1;
% 
% % obj_piezo_V = 5.25;
% % piezo_ramptime = 5000;
% % piezo_dV = 0.0;
% % setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V + piezo_dV/2,1);
% % AnalogFuncTo(calctime(curtime,0),'objective Piezo Z',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),piezo_ramptime,piezo_ramptime,obj_piezo_V - piezo_dV/2);
% 
% curtime = calctime(curtime,15500);
% 
% 
% curtime = Load_Lattice(calctime(curtime,0));
% [curtime,molasses_offset] = imaging_molasses(calctime(curtime,0));
% % AnalogFuncTo(calctime(curtime,-molasses_offset),'objective Piezo Z',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),piezo_ramptime,piezo_ramptime,obj_piezo_V + piezo_dV/2);
% 
% curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',505);

%% Test iXon + Pixelfly Image and Fit

% %Unimportant analog channel set to initialize analogadwinlist.
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% % 
% % %Clear iXon and Pixelfly buffers.
% % DigitalPulse(calctime(curtime,0),'iXon Trigger',0.1,1);
% % DigitalPulse(curtime,'PixelFly Trigger',0.1,1);
% % 
% % %Wait. Simulate taking fluorescence image in iXon.
% curtime = calctime(curtime,400);
% % DigitalPulse(calctime(curtime,5),'iXon Trigger',0.1,1);
% 
% % %Turn on Lattice Beam
% % setDigitalChannel(calctime(curtime,0),34,0);
% % % %Simulate an absorption image.
% DigitalPulse(curtime,'PixelFly Trigger',0.1,1);
% 
% k_probe_detuning =8;
% k_probe_pwr = 0.15;
% K_probe_time = 0.15;
% probe_on_delay = 0;
% 
%             setAnalogChannel(calctime(curtime,-25),'K Probe/OP FM',190); %202.5 for 2G shim
%             setAnalogChannel(calctime(curtime,-25),'K Trap FM',k_probe_detuning); %40 for 2G shim
%             %Set AM for Optical Pumping
%             setAnalogChannel(calctime(curtime,-25),'K Probe/OP AM',k_probe_pwr,1);%0.65
%             %Open Shutter and Turn on Beam
%             DigitalPulse(calctime(curtime,probe_on_delay),'K Probe/OP TTL',K_probe_time,0); %0.3
%             DigitalPulse(calctime(curtime,probe_on_delay-5),'K Probe/OP Shutter',K_probe_time+10,1);
% 
% % 
% % %Turn off lattice beam
% % setDigitalChannel(calctime(curtime,10),34,1);
% 
%     
% curtime = calctime(curtime,400);
% % % 
% % % %Wait. Simulate absorption image reference.
% % % curtime = calctime(curtime, 200);
% DigitalPulse(curtime,'PixelFly Trigger',0.1,1);
% 
% %Wait. Simulate taking reference image in iXon.
% curtime = calctime(curtime,1300);
% DigitalPulse(calctime(curtime,0),'iXon Trigger',0.1,1);


%% Test iXon Camera

% setDigitalChannel(curtime,'Rb Probe/OP TTL',1);
% 
% flush camera with first exposure
% curtime = DigitalPulse(curtime,'iXon Trigger',0.1,1);
% wait some time for second exposure
% curtime = calctime(curtime,1000);
% 
% %keep beam off with TTL
% % setDigitalChannel(calctime(curtime,-60),'Rb Probe/OP TTL',1);
% % set Probe intensity
% % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% % open probe shutter
% %  setDigitalChannel(calctime(curtime,-0),'Rb Probe/OP Shutter',1);
% 
% 
% 
% 
% % trigger camera for second image
% % DigitalPulse(curtime,'iXon Trigger',0.1,1);
% % pulse AOM with fast TTL
% % DigitalPulse(calctime(curtime,0.0),'Rb Probe/OP TTL',0.2,0);
% 
% %wait for some time before second image
% % curtime = calctime(curtime,50);
% 
% % trigger camera for second image
% % DigitalPulse(curtime,'iXon Trigger',0.1,1);
% % pulse AOM with fast TTL
% %  DigitalPulse(calctime(curtime,0.0),'Rb Probe/OP TTL',0.2,0);
% % % % set Probe intensity
%    setAnalogChannel(calctime(curtime,+5),'Rb Probe/OP AM',0);
% % 
% % 
% % % setDigitalChannel(calctime(curtime,10),'Rb Probe/OP Shutter',0);
% % % 
% % %iXon test fluorescence with vertical blue beam
% % 
% 
%Lattice off to start
% setDigitalChannel(calctime(curtime,0),34,1);  %0: ON / 1: OFF
% 
% % 
%  k_D1_detuning_trap_power = 6;
% % % % k_probe_pwr = 0.7;
% % % % rb_probe_pwr = 0.7;
% % % % % 
%  setAnalogChannel(calctime(curtime,0),47,k_D1_detuning_trap_power,1);
% % % % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',rb_probe_pwr,1); 
% % % % setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',k_probe_pwr,1);
% % % % setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% % % % % 
% % % % % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% % % % setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1);
% % % % % % 
%Expose iXon Once to Clear Buffer
%  DigitalPulse(calctime(curtime,0 ),'iXon Trigger',1,1);
% % % % % % 
% % % % % % 
% %Wait 1.5s
%  curtime = calctime(curtime,2500);
% % % % % % 
% Camera trigger at start of D1 molasses
% % % % %  DigitalPulse(curtime,'405nm Shutter',400.0,1);
% % % % %  DigitalPulse(calctime(curtime,4),'405nm TTL',1.0,1);
%     setDigitalChannel(calctime(curtime,-10),35,0);
%     DigitalPulse(calctime(curtime,-5),'D1 Shutter',1055,1);   %Opens Shutter early
%     DigitalPulse(calctime(curtime,0),35,1050,1);     %Pulses Beam with TTL
% lattice_on_time = 500;
% lat_rampup_time = 50;
% lat_rampup_depth = 900;
% 
% DigitalPulse(calctime(curtime,0),34,lattice_on_time,0);  %0: ON / 1: OFF
% setDigitalChannel(calctime(curtime,-25),'Lattice Direct Control',0);
% setAnalogChannel(calctime(curtime,-10),'zLattice',-10,1);
% setAnalogChannel(calctime(curtime,-10),'yLattice',-10,1);
% setAnalogChannel(calctime(curtime,-10),'xLattice',-10,1);
% % setAnalogChannel(calctime(curtime,0),'zLattice',400);
% % AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(1), lat_rampup_time(1), 0, lat_rampup_depth);
% % AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(1), lat_rampup_time(1), 0, lat_rampup_depth);
% AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, lat_rampup_depth);
% setAnalogChannel(calctime(curtime,lattice_on_time-lat_rampup_time),'xLattice',-10,1);
% setAnalogChannel(calctime(curtime,lattice_on_time-lat_rampup_time),'yLattice',-10,1);
% setAnalogChannel(calctime(curtime,lattice_on_time-lat_rampup_time),'zLattice',-10,1);
% % % % DigitalPulse(calctime(curtime, -10),'Rb Probe/OP shutter',20,1); %-10 
% % % % DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',2,0);
%  DigitalPulse(calctime(curtime,50),'iXon Trigger',1,1);
%  ScopeTriggerPulse(calctime(curtime,0),'Start Fluorescence Capture',0.1);
% % % % % % % 
%  curtime = calctime(curtime,2500);
% % % % % % 


%Expose iXon Again to Clear Buffer for BG Image
%  DigitalPulse(calctime(curtime,0 ),'iXon Trigger',1,1);
% % % % % % 
% % % % % % 
% %Wait 1.5s
%  curtime = calctime(curtime,2500);
% 



%Camera trigger 
%     setDigitalChannel(calctime(curtime,-10),35,0);
%     DigitalPulse(calctime(curtime,-5),'D1 Shutter',1055,1);   %Opens Shutter early
%     DigitalPulse(calctime(curtime,0),35,1050,1);     %Pulses Beam with TTL
% % % DigitalPulse(calctime(curtime,0),34,1000,0);  %0: ON / 1: OFF
% % % 
% DigitalPulse(calctime(curtime,50),'iXon Trigger',1,1);
% % % % 
% % % % 
% % % % % 
% curtime = calctime(curtime,2000);
% % % 
%Turn D1 AOM back on to keep warm
% setDigitalChannel(calctime(curtime,10),35,1);

%% Test iXon Camera (Rb Absorption)

% setDigitalChannel(curtime,'Rb Probe/OP TTL',1);
% 
% flush camera with first exposure
% curtime = DigitalPulse(curtime,'iXon Trigger',0.1,1);
% wait some time for second exposure
% curtime = calctime(curtime,1000);
% 
% %keep beam off with TTL
% % setDigitalChannel(calctime(curtime,-60),'Rb Probe/OP TTL',1);
% % set Probe intensity
% % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% % open probe shutter
% %  setDigitalChannel(calctime(curtime,-0),'Rb Probe/OP Shutter',1);
% 
% 
% 
% 
% % trigger camera for second image
% % DigitalPulse(curtime,'iXon Trigger',0.1,1);
% % pulse AOM with fast TTL
% % DigitalPulse(calctime(curtime,0.0),'Rb Probe/OP TTL',0.2,0);
% 
% %wait for some time before second image
% % curtime = calctime(curtime,50);
% 
% % trigger camera for second image
% % DigitalPulse(curtime,'iXon Trigger',0.1,1);
% % pulse AOM with fast TTL
% %  DigitalPulse(calctime(curtime,0.0),'Rb Probe/OP TTL',0.2,0);
% % % % set Probe intensity
%    setAnalogChannel(calctime(curtime,+5),'Rb Probe/OP AM',0);
% % 
% % 
% % % setDigitalChannel(calctime(curtime,10),'Rb Probe/OP Shutter',0);
% % % 
% % %iXon test fluorescence with vertical blue beam
% % 
% 
%Lattice off to start
% setDigitalChannel(calctime(curtime,0),34,1);  %0: ON / 1: OFF
% 
% % 
% k_D1_detuning_trap_power = 7;
% k_probe_pwr = 0.7;
% rb_probe_pwr = 0.7;
% % 
% setAnalogChannel(calctime(curtime,0),47,k_D1_detuning_trap_power,1);
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',rb_probe_pwr,1); 
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',k_probe_pwr,1);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% % 
% % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1);
% % % 
%Expose iXon Once to Clear Buffer
%  DigitalPulse(calctime(curtime,0 ),'iXon Trigger',1,1);
% % % 
% % % 
%Wait 1.5s
%  curtime = calctime(curtime,1500);
% % % 
% % % Camera trigger at start of D1 molasses
% % %  DigitalPulse(curtime,'405nm Shutter',400.0,1);
% % %  DigitalPulse(calctime(curtime,4),'405nm TTL',1.0,1);
%     setDigitalChannel(calctime(curtime,-10),35,1);
% %     DigitalPulse(calctime(curtime,-5),'D1 Shutter',1005.0,1);   %Opens Shutter early
% %     DigitalPulse(calctime(curtime,0),35,50,1);     %Pulses Beam with TTL
% % DigitalPulse(calctime(curtime,0),34,1000,0);  %0: ON / 1: OFF
% DigitalPulse(calctime(curtime, -10),'Rb Probe/OP shutter',20,1); %-10 
% DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',2,0);
%  DigitalPulse(calctime(curtime,0),'iXon Trigger',1,1);
%  ScopeTriggerPulse(calctime(curtime,0),'Start Fluorescence Capture',0.1);
% % % 
%  curtime = calctime(curtime,1500);
% %  
% %Camera trigger 
%     % setDigitalChannel(calctime(curtime,-10),35,0);
%     % DigitalPulse(calctime(curtime,-5),'D1 Shutter',1005.0,1);   %Opens Shutter early
%     % DigitalPulse(calctime(curtime,0),35,50,1);     %Pulses Beam with TTL
% DigitalPulse(calctime(curtime,0),34,1000,0);  %0: ON / 1: OFF

% DigitalPulse(calctime(curtime,0),'iXon Trigger',1,1);
% % 
% % 
% % % 
% % curtime = calctime(curtime,10);
% 
% %Turn D1 AOM back on to keep warm
% setDigitalChannel(calctime(curtime,1500),35,1);

%% Turn on Probe
%     %analog
%     setAnalogChannel(calctime(curtime,0),4,1,1);
%     %TTL (1 = "light off", 0 = "light on")
%     setDigitalChannel(calctime(curtime,0),8,0);
%      %Shutter (1 = "light on", 0 = "light off")
%     setDigitalChannel(calctime(curtime,0),4,1);
% 
% % turn_on_beam(calctime(curtime,2),3,0.1);
% % 
%  turn_off_beam(calctime(curtime,100),3);


%% Turn on push
    %analog
%     setAnalogChannel(calctime(curtime,0),7,3,2);
%     setAnalogChannel(calctime(curtime,1500),7,3,2);
    
%% Bias Fields
    
% %Y-direction (Transport direction/Push coil)
% setAnalogChannel(curtime,14,0,1); %0.5 %0
% %setAnalogChannel(calctime(curtime,2000),14,0,1)
% 
% %Z-direction (up/down)
% setAnalogChannel(curtime,15,3,1); %0
% setAnalogChannel(calctime(curtime,2000),15,0,1)
% 
% %X-direction (North-South)
% setAnalogChannel(curtime,16,0,1); %4 %0.8



%% Test new card

% curtime = calctime(curtime,100);
% setAnalogChannel(calctime(curtime,100),45,-10)
% % % setAnalogChannel(calctime(curtime,100),32,0,1)
% % % setDigitalChannel(calctime(curtime,200),65,0);
% % setDigitalChannel(calctime(curtime,300),1,0);
% setDigitalChannel(calctime(curtime,400),26,0);
% % setDigitalChannel(calctime(curtime,500),31,1);
% % setDigitalChannel(calctime(curtime,500),64,1);

% 
% 
% %ramp on
% curtime = AnalogFunc(curtime+5,33,@(t,tt,pwr)(pwr*t/tt),200,200,0.7*4);
% 
% %off
% curtime = setAnalogChannel(calctime(curtime,1000),33,0.0);
% 
% curtime=setDigitalChannel(curtime+5,10,0);

%% Test Rf switch
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.7);
% %  %DigitalPulse(curtime,20,20,1);
%  curtime=setDigitalChannel(curtime,19,0); %0: off, 1: on
%  setAnalogChannel(curtime,39,-5);
%  setDigitalChannel(calctime(curtime,50),'RF/uWave Transfer',0) %0: RF, 1: uWaves
%  curtime = calctime(curtime, 1000);

%% Rf switch
% %turn on the Z (top/bottom) shim 
%     %curtime = setAnalogChannel(calctime(curtime,0),28,0.01671340); 
%     curtime = setAnalogChannel(calctime(curtime,0),28,0.01671341); 
%     
% %turn off the Z (top/bottom) shim 
%     curtime = setAnalogChannel(calctime(curtime,5000),28,0); 

% curtime = calctime(curtime,100);
% 
% %shutter
% setDigitalChannel(calctime(curtime,-10),5,1);
% %analog
% setAnalogChannel(calctime(curtime,-5),2,0.1); %0.11
% %TTL
% setDigitalChannel(calctime(curtime,-5),9,0);

%% Test CATS 2

 %turn on voltage
%  curtime = setAnalogChannel(calctime(curtime,0),18,10);

%  %turn off voltage
%  curtime = setAnalogChannel(calctime(curtime,5000),18,0);
 
% 
% DigitalPulse(calctime(curtime,100),12,10,1);
% 
% vert_channels = [22 23 24 20 21 1 3];
% on_time = 1000;
% turn_off = 1;
% 
% % %12a
% setAnalogChannel(calctime(curtime,100),22,-0.5,1);
% 
% %12b
% setAnalogChannel(calctime(curtime,100),23,0,1);
% 
% % curtime = AnalogFunc(calctime(curtime,100),23,@(t,tt)(-20*t/tt),100,100);
% % curtime = AnalogFunc(calctime(curtime,100),23,@(t,tt)(20*t/tt-20),100,100);
% % %curtime = AnalogFunc(curtime,23,@(t,tt)(4*t/tt-2),100,100);
% % curtime = AnalogFunc(curtime,23,@(t,tt)(20*t/tt+0),100,100);
% 
% %13
% setAnalogChannel(calctime(curtime,100),24,0.0,1);
% 
% % curtime = AnalogFunc(calctime(curtime,100),24,@(t,tt)(-20*t/tt),100,100);
% % curtime = AnalogFunc(calctime(curtime,100),24,@(t,tt)(20*t/tt-20),100,100);
% % curtime = AnalogFunc(curtime,24,@(t,tt)(20*t/tt+0),100,100);
% 
% %14
% setAnalogChannel(calctime(curtime,100),20,0,1);
% 
% % curtime = AnalogFunc(calctime(curtime,100),20,@(t,tt)(-20*t/tt),100,100);
% % curtime = AnalogFunc(calctime(curtime,100),20,@(t,tt)(20*t/tt-20),100,100);
% % curtime = AnalogFunc(curtime,20,@(t,tt)(20*t/tt+0),100,100);
% 
% %Kitten 15/16 (16-15)
% setAnalogChannel(calctime(curtime,100),3,0,1); %0.7
% %setAnalogChannel(calctime(curtime,400),3,2.3,1);
% 
% % %15/16 switch
% setDigitalChannel(calctime(curtime,100),22,0);
% 
% %Coil 16 Fast Switch
% setDigitalChannel(calctime(curtime,100),21,0);
% 
% %Kitten Relay
% setDigitalChannel(calctime(curtime,100),29,0);
% 
% %15 lower sensor
% setAnalogChannel(calctime(curtime,100),21,0,1);  %1.0
% 
% 
% %16 total current
% setAnalogChannel(calctime(curtime,100),1,0,1);
% 
% %curtime = AnalogFunc(calctime(curtime,100),1,@(t,tt)(20*t/tt+0),300,300);
% 
% curtime = calctime(curtime,on_time);
% % %turn off voltage
% % curtime = setAnalogChannel(calctime(curtime,0),18,0/6.6);
% 
% 
% %transport
% curtime = AnalogFunc(calctime(curtime,105),0,@(t,tt)(170*t/tt+360),2000,2000);
% curtime = AnalogFunc(calctime(curtime,10),0,@(t,tt)(-170*t/tt+360+170),2000,2000);
% 
% %turn all off 
% if turn_off
%     for i = 1:length(vert_channels)
%         setAnalogChannel(curtime,vert_channels(i),0);
%     end
%     setDigitalChannel(calctime(curtime,0),22,0);
% end

% setAnalogChannel(calctime(curtime,0),24,0,1);

 %% Transport test
% 
% setDigitalChannel(curtime,'Kitten Relay',0); %0: OFF, 1: ON
% setDigitalChannel(curtime,'15/16 Switch',0); %0: OFF, 1: ON
% setDigitalChannel(curtime,'Coil 16 TTL',1); %1: turns coil off; 0: coil can be on
% 
% curtime = calctime(curtime,500);
%  
% pulsetime = 2000;
% 
% %Ramp off MOT
% setAnalogChannel(calctime(curtime,-50),8,10);
% AnalogFuncTo(calctime(curtime,0),8,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);
%  
% curtime = calctime(curtime,500);
% 
% current = 0;
% channel = 1;
% 
% is_bipolar = 0;
% 
% ramp_iparabola = @(t,tt,y0,y1) (y1-y0)*(1-(2*t/tt-1).^2)+y0;%(y1-y0)*(1-(tt-t)/tt)+y0;
% ramp_cosine = @(t,tt,y0) y0/2*(1-cos(2*pi*t/tt));
% 
% %set FF
% % setAnalogChannel(calctime(curtime,-200),18,25*(abs(current)/30)/3 + 0.5);
% % %use the following for QT coil
% AnalogFunc(calctime(curtime,-200),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0.5,25*(abs(current)/30)/1 + 0.5);
% 
% % use the following for other transfer coils
% % AnalogFunc(calctime(curtime,-200),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0.5,8*(abs(current)/30)/1 + 0.5);
% 
% %Kitten to max current for the ramp if using coil 15 or 16 alone.
% setAnalogChannel(calctime(curtime,-175),3,0,1); % current set to 5 for fully on   
% 
% %"Turn on" coil to 0
% setAnalogChannel(calctime(curtime,-50),channel,0,1); %Start at zero for AnalogFuncTo
% 
% % %Test for coil 16
% % setAnalogChannel(calctime(curtime,-200),'coil 15',0,1);
% 
% %Turn on coil for pulsetime 
% % curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_cosine(t,tt,y0),pulsetime,pulsetime,current,3);
% % curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_cosine(t,tt,y0),pulsetime,pulsetime,-current,3);
% 
% % Analog ramps
% %digital trigger
% DigitalPulse(calctime(curtime,0),'ScopeTrigger',10,1);
% %Turn on if using kitten (for channels 15/16). 
% %           AnalogFunc(calctime(curtime,0),3,@(t,tt,y1)ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,0.3*current,2);
% curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y1)ramp_iparabola(t,tt,0.0,y1),pulsetime,pulsetime,current,2);
% if (is_bipolar)
%     curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y1)ramp_iparabola(t,tt,0,y1),pulsetime,pulsetime,-current,2);
% end
% % 
% % % setAnalogChannel(calctime(curtime,0),3,6,1);
% % % curtime = AnalogFunc(calctime(curtime,0),channel,@(t,tt,y0)ramp_iparabola(t,tt,y0),pulsetime,pulsetime,current,2);
% % % % curtime = AnalogFuncTo(calctime(curtime,0),channel,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,current,2);
% % % % curtime = AnalogFuncTo(calctime(curtime,pulsetime),channel,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);
% % % setAnalogChannel(calctime(curtime,20),3,0);
% % % curtime = calctime(curtime,2000);
% 
% % % setAnalogChannel(calctime(curtime,0),3,6,1);
% % % setAnalogChannel(calctime(curtime,0),channel,current);
% % % curtime = setAnalogChannel(calctime(curtime,pulsetime),channel,0.0);
% % % setAnalogChannel(calctime(curtime,pulsetime),3,0);
% % % 
% curtime = calctime(curtime,1000);
% 
% %Go back to MOT gradient for wait time
% gradient = 2;
% % curtime = calctime(curtime,2000);
% %set FF
% setAnalogChannel(calctime(curtime,-30),18,23*(gradient/30) + 0.5);
% 
% %Turn on Coil
% curtime = setAnalogChannel(calctime(curtime,0),8,gradient,2);
% % 
%     %set all transport coils to zero (except MOT)
%     for i = [7 9:17 22:24 20] 
%         setAnalogChannel(calctime(curtime,0),i,0,1);
%     end
%     %Turn off QP Coils
%     setAnalogChannel(calctime(curtime,0),'Coil 15',-.8,1); %15
% curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1); %16
% curtime = setAnalogChannel(curtime,3,0,1); %kitten
% curtime = setDigitalChannel(curtime,'15/16 Switch',0);
% % 
% % % % 
% % 


%% Test Offset Lock
%curtime = calctime(curtime,100);
%setAnalogChannel(calctime(curtime,0),34,6834);


%setAnalogChannel(calctime(curtime,1000),35,-1.10);
%setAnalogChannel(calctime(curtime,1000),34,6834);

%DigitalPulse(calctime(curtime,2000),12,10,1);
% setAnalogChannel(calctime(curtime,2000),35,0);
% setAnalogChannel(calctime(curtime,2000),34,6834);

% DigitalPulse(calctime(curtime,100),3,100,1);

%% Test Offset Piezo FF
% DigitalPulse(calctime(curtime,100),12,10,1);
% setAnalogChannel(calctime(curtime,100),35,-1);

%setAnalogChannel(calctime(curtime,2000),35,0);

%% test absorption sequence

% function do_abs_pulse(curtime,pulse_length)
%         %Camera trigger
%         DigitalPulse(curtime,1,pulse_length,1);
%         %Probe pulse
%         DigitalPulse(curtime,8,pulse_length,0);
%         %Repump pulse
%         DigitalPulse(curtime,7,pulse_length,0);
% end
% 
% tof = 2.0
% 
% curtime = calctime(curtime,1000);
% 
% DigitalPulse(calctime(curtime,0),12,10,1);
% 
% % Open Probe Shutter
% setDigitalChannel(calctime(curtime,-10),4,1); %-10
% 
% % %Open Repump Shutter
% % setDigitalChannel(calctime(curtime,-5),3,1);  
% % %turn repump back up
% % setAnalogChannel(curtime,25,0.7);
% % %repump TTL
% % setDigitalChannel(calctime(curtime,-5),7,1);
% 
% 
% % %set detuning
% % setAnalogChannel(calctime(curtime,tof-0.5),5,27);%27 %26 in trap %time is 1.9 %29.6 MHz is resonance (no Q field), 33.4MHz is resonance (with 4G field), 32.4 MHz (with 3G field), found had to change to 27MHz (Aug10)
% 
% %Prepare Probe (analog on, but keep light off with TTL)   
% %analog
% setAnalogChannel(calctime(curtime,-5),4,1,1); %.1
% %TTL
% setDigitalChannel(calctime(curtime,-5),8,1);
% 
% 
% 
% % Take 1st probe picture
% 
% pulse_length = 1;
% 
% %Trigger
% curtime = calctime(curtime,tof);
% do_abs_pulse(curtime,pulse_length);
% 
% 
% curtime = calctime(curtime,1000);

%% test probe

%  DigitalPulse(calctime(curtime,0),12,10,1);
% % 
% %  %turn on trap
%  setAnalogChannel(curtime,26,0.7);
%  
% %turn on probe shutter
% setDigitalChannel(calctime(curtime,0),4,1);
% % turn on probe AM
% setAnalogChannel(calctime(curtime,0),4,1,1)
% %turn on probe TTL
% setDigitalChannel(calctime(curtime,0),8,0);
% curtime = calctime(curtime,1000);
% % 
% setDigitalChannel(calctime(curtime,100),'K Probe/OP shutter',0)
% %setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% %setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',190);
% %setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.0005);
% setAnalogChannel(calctime(curtime,0),64,0);
% 
% % 
% curtime = calctime(curtime,1000);
% %curtime = calctime(curtime,1000);
% wait_time = 5.2;
% 
% %turn on probe shutter
% setDigitalChannel(calctime(curtime,wait_time),4,0);
% %turn on probe AM
% setAnalogChannel(calctime(curtime,wait_time),4,0,1)
% %turn on probe TTL
% setDigitalChannel(calctime(curtime,wait_time),8,1);



% for 40K

% % %advance in time
% curtime = calctime(curtime,20);
% 
%     kill_detuning = 42.5;  %400ER: 33  
%     kill_probe_pwr = 0.2;   %0.2  0.22   4*k_probe_scale*0.17
%     kill_time = 0.5; %0.5
%     
%     %set probe detuning
%     setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',190); %195
%     %set trap AOM detuning to change probe
%     setAnalogChannel(calctime(curtime,-10),'K Trap FM',kill_detuning); %54.5
%     
%     ScopeTriggerPulse(calctime(curtime,0),'Probe Pulse');
%     
%     %open K probe shutter
%     setDigitalChannel(calctime(curtime,-5),30,1); %0=closed, 1=open
%     %turn up analog
%     setAnalogChannel(calctime(curtime,-5),29,kill_probe_pwr);
%     %set TTL off initially
%     setDigitalChannel(calctime(curtime,-5),9,1);
%     
%     %pulse beam with TTL
%     curtime = DigitalPulse(calctime(curtime,0),9,kill_time,0);
%     
%     %close K probe shutter
%     setDigitalChannel(calctime(curtime,0),30,0);

%% Test blue

%setAnalogChannel(calctime(curtime,0),33,-10.110+0.08323*206.20);


% setAnalogChannel(calctime(curtime,100),26,0.7);
% 
% setAnalogChannel(calctime(curtime,200),25,0.7);
% 
% %trap shutter
% setDigitalChannel(calctime(curtime,220),2,0);
% 
% %blue shutter
%setAnalogChannel(calctime(curtime,200),8,0);
%setDigitalChannel(calctime(curtime,200),23,1);

%setDigitalChannel(calctime(curtime,240),23,0);
%setAnalogChannel(calctime(curtime,240),8,10);
% 
% setAnalogChannel(calctime(curtime,220),25,0.7);
% 
% %blue shutter
% curtime = setDigitalChannel(calctime(curtime,2000),23,0);
% setDigitalChannel(calctime(curtime,0),2,1);
% setAnalogChannel(calctime(curtime,0),25,0.7);


% timeout = curtime;

%% Test Shutter speed

% %repump
% setAnalogChannel(calctime(curtime,100),26,0.7);
% 
% %trigger and turn off
% curtime = DigitalPulse(calctime(curtime,200),12,1,1);  
% setDigitalChannel(curtime, 23, 0);
% 
% setDigitalChannel(calctime(curtime,200),23,1);

%% Test transport channels

% % %set voltage on supply
% setAnalogChannel(calctime(curtime,0),18,0);
% % 
% %set which transport channel with TTL ( ttl = 0 -> coil 3 on, ttl = 1 ->
% %coil extra on)
% setDigitalChannel(calctime(curtime,1000),28,1);
% 
% %DigitalPulse(calctime(curtime,1000),12,10,1);
% 
% setDigitalChannel(calctime(curtime,1100),28,0);
% 
% DigitalPulse(calctime(curtime,1100),12,10,1);
% 
% % 
% % %set analog
% % setAnalogChannel(calctime(curtime,0),9,0*0.7,1);

%% repump power aom

% %  setAnalogChannel(curtime,25,0.3);
% %  setAnalogChannel(calctime(curtime,5000),25,0.3);
% ScopeTriggerPulse(calctime(curtime,10),'Start Fluorescence Capture',0.1);
%   setAnalogChannel(calctime(curtime,10),25,0.3);
%  setDigitalChannel(calctime(curtime,0),3,1);
%  setDigitalChannel(calctime(curtime,10),7,0)
%  
%  curtime = calctime(curtime,10.5);
% 
%  setDigitalChannel(calctime(curtime,0),3,0);
%  setDigitalChannel(calctime(curtime,0),7,1)
%% Blue shutter

%   blue_detuning = 209.0;
% % 
% % %setDigitalChannel(calctime(curtime,0),23,0);
%  setAnalogChannel(calctime(curtime,0),33,-10.110+0.08323*blue_detuning);
% %  
% %  setAnalogChannel(calctime(curtime,10),8,10)

%% Test camera 

% pulse_length = 10;
% 
% %Camera trigger
% 
% DigitalPulse(curtime,1,pulse_length,1);

%% turn on MOT coil
% 
% BGrad = 0*25; %370
% coil11_current = 1*3;
% time_on = 1500;
% voltage = 1*6.5;
% 
% channelnumber = 17;
% 
% %turn on MOT
%     %Feed Forward
%     setAnalogChannel(calctime(curtime,100),18,voltage); 
%     %CATS
%     %setAnalogChannel(calctime(curtime,100),8,BGrad); %13G/cm
%     %Science Cell QP (1.5A for 15G/cm)
%     %TTL
%     %curtime = setDigitalChannel(calctime(curtime,100),16,0); %MOT TTL
% %turn on coil 11
%     setAnalogChannel(calctime(curtime,100),channelnumber,coil11_current);
%     
%     %set digital trigger
%     DigitalPulse(calctime(curtime,100),12,time_on,1);
%     
% 
% %turn off MOT    
%     %Feed Forward
%     %setAnalogChannel(calctime(curtime,time_on),18,0); 
%     %CATS
%     %setAnalogChannel(calctime(curtime,time_on),8,0); %13G/cm
%     %Science Cell QP (1.5A for 15G/cm)
% %turn off coil 11
%     setAnalogChannel(calctime(curtime,time_on),channelnumber,0);
% %     
    
%% Test timing

% % put a string of square pulses of determined width and frequency
% 
% blue_detuning1 = 220.0;
% blue_detuning2 = 180.0;
% 
% pulse_width = 500;
% pulse_period = 1000;
% 
% for step = 1:10
% 
%  %setDigitalChannel(calctime(curtime,0),23,0);
%   curtime = setAnalogChannel(calctime(curtime,pulse_period-pulse_width),33,-10.110+0.08323*blue_detuning1);
%   curtime = setAnalogChannel(calctime(curtime,pulse_width),33,-10.110+0.08323*blue_detuning2);
% 
% end
% %% Rb Offset lock
% 
% VCO_freq = 6700;
% 
% %set VCO frequency 
% curtime = setAnalogChannel(calctime(curtime,0),34,VCO_freq);
% 
% %% Blue detuning
% 
% AOM200MHz = 1;
% AOM100MHz = 0;
% 
%  blue_flicker = 1;
% 
% if blue_flicker 
% 
% blue_detuning1 = 64;
% blue_detuning2 = 64;
% 
% 
% for step = 1:1
% 
%     if AOM200MHz
%  %setDigitalChannel(calctime(curtime,0),23,0);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-10.110+0.08323*blue_detuning1);
%   curtime = setAnalogChannel(calctime(curtime,1000),33,-10.110+0.08323*blue_detuning2);
% 
%     elseif AOM100MHz
%   %setDigitalChannel(calctime(curtime,0),23,0);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-11.74178+0.18006*blue_detuning1);
%   curtime = setAnalogChannel(calctime(curtime,1000),33,-11.74178+0.18006*blue_detuning2);
%         
%         
% end
%  end
% 
% %% Blue detuning sweep
% 
% AOM200MHz = 1;
% AOM100MHz = 0;
% 
% 
% blue_detuning_sweep =  0;
% 
% if blue_detuning_sweep 
% %parameters
% sweep_time = 8E3;
% 
% blue_detuning1 = 190;
% blue_detuning2 = 230.0;
% 
% %pulse on resonance twice to calibrate time
%     %pulse detunings
%     pulse_on = 205;
%     pulse_off = 195;
% 
%        
%  if AOM200MHz 
%   %pulse once
%   curtime = setAnalogChannel(calctime(curtime,1000),33,-10.110+0.08323*pulse_on);
%   %trigger at end of pulse
%   DigitalPulse(curtime,12,500,1);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-10.110+0.08323*pulse_off);
% 
%  %piecewise sweep
% %  for i = 1:1000
% %   time = calctime(curtime,20E3/1000);
% %   setAnalogChannel(time,33,200+i/(20E3*1000)*(230-200));
% %  end
%   
%   %sweep blue detuning
% curtime = AnalogFunc(calctime(curtime,0),33,@(t,d1,d2,tt)(-10.110+0.08323*(d1+(d2-d1)*t/tt)),sweep_time,blue_detuning1,blue_detuning2,sweep_time);
% 
% 
% %pulse at end
%     %pulse once
%   curtime = setAnalogChannel(calctime(curtime,0),33,-10.110+0.08323*pulse_on);
%   %trigger at end of pulse
%   DigitalPulse(curtime,12,500,1);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-10.110+0.08323*pulse_off);
%   
%  elseif AOM100MHz
%   
%      %pulse once
%   curtime = setAnalogChannel(calctime(curtime,1000),33,-11.74178+0.18006*pulse_on);
%   %trigger at end of pulse
%   DigitalPulse(curtime,12,500,1);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-11.74178+0.18006*pulse_off);
% 
%  %piecewise sweep
% %  for i = 1:1000
% %   time = calctime(curtime,20E3/1000);
% %   setAnalogChannel(time,33,200+i/(20E3*1000)*(230-200));
% %  end
%   
%   %sweep blue detuning
% curtime = AnalogFunc(calctime(curtime,0),33,@(t,d1,d2,tt)(-11.74178+0.18006*(d1+(d2-d1)*t/tt)),sweep_time,blue_detuning1,blue_detuning2,sweep_time);
% 
% 
% %pulse at end
%     %pulse once
%   curtime = setAnalogChannel(calctime(curtime,0),33,-11.74178+0.18006*pulse_on);
%   %trigger at end of pulse
%   DigitalPulse(curtime,12,500,1);
%   curtime = setAnalogChannel(calctime(curtime,500),33,-11.74178+0.18006*pulse_off);
%      
%  end
%   
% end

%curtime = setAnalogChannel(calctime(curtime,1000),2,0.5,1);
% curtime = setAnalogChannel(calctime(curtime,5),5,1.0,1);
% curtime = setAnalogChannel(calctime(curtime,5),25,1.5,1);
% curtime = setAnalogChannel(calctime(curtime,5),26,0.25,1);
% 
%curtime = setDigitalChannel(curtime+5,5,0);

% setAnalogChannel(curtime+10,36,0.7);
% setDigitalChannel(curtime+5,24,0);
% setDigitalChannel(curtime+5,25,1);


%% Test Lattice (and names)
% % % 
%       rotation_time = 1000;   % The time to rotate the waveplate
%       P_lattice = 1.0; %0.5/0.9        % The fraction of power that will be transmitted 
% % % % % % %                             % through the PBS to lattice beams
% % % % % %                             % 0 = dipole, 1 = lattice
% % % % % %     
% % % %       setAnalogChannel(calctime(curtime,0),'latticeWaveplate',0);
% % curtime = calctime(curtime, 500);
% % % % %       curtime = AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rotation_time,rotation_time,P_lattice,2);
%      curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
% % % % % %     
% % % %     setDigitalChannel(calctime(curtime,0),11,0);%11: x lattice off
% % %     
%     lattice_depth = 1 * [1*111 1*111 1*111; 1*80 1*80 1*80; 1*20 1*20 1*20]/0.4;
% % %     lattice_depth = 1 * [111 111 111; 73 73 73; 33 33 33]/0.4;
%     ramp_time = 100;
% % % % % 
% % % % % 
%     curtime = calctime(curtime,100);
% %     setDigitalChannel(calctime(curtime,-20),34,0);%34 y lattice off;
% %     setDigitalChannel(calctime(curtime,-20),'Lattice Direct Control',0);
% %     setAnalogChannel(calctime(curtime,-50),'xLattice',0.01);
% % % % %     
% % 
% %     AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, 0, lattice_depth(1));
% %     AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, 0, lattice_depth(3));
% %     curtime = AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ramp_time, ramp_time, 0, lattice_depth(2));
% % % % % % 
% %     curtime = calctime(curtime,100);
% % % % % %     
%     setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
%     setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);
%     setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);
% %         ScopeTriggerPulse(curtime,'Load lattices');
% % % % % %     
%     curtime = calctime(curtime,10);
%     
% %     setAnalogChannel(calctime(curtime,-50),'xLattice',0.01);
% % % % %     
%     setDigitalChannel(calctime(curtime,25),34,1);
%     setDigitalChannel(calctime(curtime,25),'Lattice Direct Control',1);

%% Test Probe Beam AOMs

% %Resonant light pulse to remove any untransferred atoms from F=9/2
%                 kill_probe_pwr = 0.3;
%                 kill_time = 0.5;
%                 kill_detuning = 48; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field
%                 
%                 pulse_offset_time = +100; %Need to step back in time a bit to do the kill pulse
%                                           % directly after transfer, not after the subsequent wait times
%                 
%               ScopeTriggerPulse(calctime(curtime,pulse_offset_time),'Plane Select');
%                                           
%                 %set probe detuning
%                 setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
%                 %set trap AOM detuning to change probe
%                 setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5
%                 
%                 %open K probe shutter
%                 setDigitalChannel(calctime(curtime,pulse_offset_time-10),30,1); %0=closed, 1=open
%                 %turn up analog
%                 setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
%                 %set TTL off initially
%                 setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);
%                 
%                 %pulse beam with TTL
%                 DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);
%                 
%                 %close K probe shutter
%                 setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),30,0);
% 
%% Test 15/16

% %set voltage
%  curtime = setAnalogChannel(calctime(curtime,100),'a18',10);
% 
% %runtime = 1000;
% 
% %trigger
% %DigitalPulse(curtime,12,0.1,1); %trigger
% 
%  I_16 = 5;
% % 
% % SG_time = -2;
%  kitten_relay  = 1; %(0 = no current, 1 = current flows)
%  kitten_analog = 5;
% % 
% % 
% setAnalogChannel(curtime,3,0); %kitten
% setDigitalChannel(curtime,22,1); %15/16  (0 = no current, x = analog current flows)
% setAnalogChannel(curtime,21,0); %coil 15
% setAnalogChannel(curtime,1,5); %coil 16
% setDigitalChannel(curtime,29,0); %kitten relay (0 = no current, 1 = current flows)
% %fast switch
% setDigitalChannel(curtime,21,0); %(0 = current flows , 1 = no current) 
% % 
% % 
%  curtime = calctime(curtime,1000);
% % 
% % %trigger
% % DigitalPulse(curtime,12,10,1);
% % 
% setAnalogChannel(curtime,3,0); %kitten
% setDigitalChannel(curtime,22,0); %15/16 switch (0 = no current, x = analog current flows)
% setAnalogChannel(curtime,21,0,1); %coil 15
% setAnalogChannel(curtime,1,0,1); %coil 16
% setDigitalChannel(curtime,29,0); %kitten relay (0 = no current, 1 = current flows)
% %fast switch
% setDigitalChannel(curtime,21,1); %(0 = current flows , 1 = no current) 
% % %set voltage
%  curtime = setAnalogChannel(calctime(curtime,100),18,0);

% % 
%  curtime = calctime(curtime,100);
% % 
% % %make sure everything is shut off
% % for i = [7:17 20:24]
% %     setAnalogChannel(curtime,i,0,1);
% % end

% SetAnalogChannel(curtime,33,0.9);
% SetAnalogChannel(calctime(curtime,3000),33,0.0);

%% Test DDS

% seqdata.numDDSsweeps = 0;
% 
% setAnalogChannel(curtime,29,0.01);
% 
% ontime=10;
% 
% curtime = calctime(curtime,500);
% 
% SetDigitalChannel(calctime(curtime,-150),32,0);
% SetDigitalChannel(calctime(curtime,-100),31,1); %switch Feshbach field on
% %SetDigitalChannel(calctime(curtime,-100),32,0); %switch Feshbach field integrator on
% %SetAnalogChannel(calctime(curtime,-100),37,10); %switch Feshbach field closer to on
% curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y2,y1)(y1+(y2-y1)*t/tt),500,500, 10,0.01);
% 
% for i = 1:10
%     setAnalogChannel(curtime,37,10);
%     curtime = setAnalogChannel(calctime(curtime,100),37,0);
%     curtime = calctime(curtime,100);
% end
% 
% ramp up and down
% ramp_current = 0.2;
% sweep_ramp_time = 100;
% curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y2,y1)(y1+(y2-y1)*t/tt),sweep_ramp_time,sweep_ramp_time, 10+ramp_current,10);
% curtime = calctime(curtime,50);
% curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y2,y1)(y1+(y2-y1)*t/tt),sweep_ramp_time,sweep_ramp_time, 10,10+ramp_current);
% 
% 
% SetAnalogChannel(calctime(curtime,ontime),37,-0.3,1);
% SetDigitalChannel(calctime(curtime,ontime),31,0);
% %SetDigitalChannel(calctime(curtime,ontime),32,1);
% 
% curtime = calctime(curtime, ontime);
% 
% curtime  = do_uWave_pulse(calctime(curtime,0), 0, 20*1E6/3*0.99,0.005,0);
% 
% setAnalogChannel(calctime(curtime,50),18,10); 
% curtime = setAnalogChannel(calctime(curtime,50),8,10);
% 
% setAnalogChannel(calctime(curtime,3000),18,0); 
% setAnalogChannel(calctime(curtime,3000),8,0,1);
% 
% curtime = calctime(curtime,1000);
% 
% curtime=DigitalPulse(calctime(curtime,5000),11,100,1);
% 
% curtime  = do_uWave_pulse(calctime(curtime,0), 0,20*1E6 ,5000,0); %20*1E6/3*0.99
% 
% RF_gain = 0;
% % %sweep parameters
% start_sweep_freq = 10*1E6;
% end_sweep_freq = 30*1E6;
% sweep_time = 5000;
% %
% 
% %turn RF on:
% curtime = setDigitalChannel(calctime(curtime,100),19,1);
% %set RF gain:
% curtime = setAnalogChannel(calctime(curtime,0),39,RF_gain);
% 
% % for
% %    set 
% % end
% %
% 
% %sweep 1 
% curtime = calctime(curtime, 1000);
% curtime = DDS_sweep(calctime(curtime,0),1,start_sweep_freq,end_sweep_freq,sweep_time);
% curtime = DDS_sweep(calctime(curtime,0),2,4E9,6E9,sweep_time);
% curtime = calctime(curtime, 1000);
% %curtime = DDS_sweep(calctime(curtime,0),1,2*start_sweep_freq,2*end_sweep_freq,sweep_time);
% %curtime = DDS_sweep(calctime(curtime,0),1,3*start_sweep_freq,3*end_sweep_freq,sweep_time);
% % 
% % %turn DDS (Rf) off:
% curtime = setDigitalChannel(calctime(curtime,0),19,0);


%% Test uWave

%setAnalogChannel(calctime(curtime,250),5,5,1);
%setAnalogChannel(calctime(curtime,250),5,60);

%
%  freqs_1b = [8 4 1.5 ]*1E6; 
%     RF_gain_1b = [-4 -4 -7]; 
%     sweep_times_1b = [4000 2000 ]*6/6;
%   
%      freqs_1b = [10 10 ]*1E6; 
%    
%     sweep_times_1b = [20000  ]*6/6;
%     
%     %Do uWave evaporation
%     curtime = do_uwave_evap_stage(curtime, 0, freqs_1b*3, sweep_times_1b, 0);
%     
%     %setDigitalChannel(calctime(curtime,10),14,1);
%     
%     %curtime = DDS_sweep(calctime(curtime,0),1,106*1E6,106*1E6,5000);
% 
% %turn RF/uWave switch to low (uWave off)
%  setDigitalChannel(calctime(curtime,500),17,0);
% % %turn uWave switch to "off"
%  curtime = setDigitalChannel(calctime(curtime,500),14,0);

%%

% curtime = calctime(curtime,500);
% 
% MHz = 1E6;
%  freqs_1 = [42 28 15 12]*MHz; %7.5
% RF_gain_1 = [9 9 9 9]*(5)/9*0.75; %9 9 9
% sweep_times_1 = [16000 8000 3000 ].*1.0*0.95;
% 
% 
% curtime = do_evap_stage(curtime, 0, freqs_1, sweep_times_1, RF_gain_1, 0, 1);


% % %turn on
% setDigitalChannel(calctime(curtime,0),13,1);
% curtime = setDigitalChannel(calctime(curtime,100),19,1);
% % 
% %sweep array parameters:
% start_freq = 1;
% freqs_1 = [start_freq start_freq]*1E6;
% RF_gain_1 = [9];
% sweep_times_1 = [5000 ];
% 
% for i = 1:length(sweep_times_1)
%             setAnalogChannel(curtime, 39, RF_gain_1(i),1);
%             curtime = DDS_sweep(calctime(curtime,10),1,freqs_1(i),freqs_1(i+1),sweep_times_1(i));
% end
% 
% %turn on
% setDigitalChannel(calctime(curtime,100),13,0);
% curtime = setDigitalChannel(calctime(curtime,100),19,0);
%  
% 
% setAnalogChannel(curtime,18,10);

%% Test CATS Channels

%voltage
%setAnalogChannel(calctime(curtime,100),18,5);

%turn channel on and off
% for i = 1:20
%     
%     curtime = setDigitalChannel(calctime(curtime,1000),22,mod(i,2));
%     setDigitalChannel(calctime(curtime,0),16,mod(i,2));
%     
% end
% 
% curtime = setDigitalChannel(calctime(curtime,100),4,1);
% setAnalogChannel(calctime(curtime,50), 18, 2);
% setAnalogChannel(calctime(curtime,50), 8, 2);

%% Test QP Pair

% turn_off = 1;
% 
% setDigitalChannel(curtime,21,0); %QT fast switch
% setDigitalChannel(curtime,22,1); %15/16 switch
% setAnalogChannel(curtime,3,0); %kitten
% setAnalogChannel(curtime,21,0); %bottom QP
% setAnalogChannel(curtime,1,0,1); %top QP
% setAnalogChannel(curtime,20,0,1); %14
% setDigitalChannel(curtime,29,1);
% 
% QP_curval = 18.9;
% Kitten_curval = 11.2;
% vset0 = 12.25;
% 
% curtime = calctime(curtime,500);
% 
% %start with 30 in QP pair
% setAnalogChannel(curtime,1,40); %top qp
% setAnalogChannel(curtime,21,0); %bottom QP
% setAnalogChannel(curtime,3,0); %kitten
% %setAnalogChannel(curtime,20,5); %14
% setAnalogChannel(curtime,18,20); %FF voltage
% % 
% % DigitalPulse(curtime,12,5,1);
% % 
% % %curtime = ramp_qp(calctime(curtime,0),[0 0 0],[Kitten_curval 0 QP_curval],500);
% % 
% % setAnalogChannel(curtime,18,vset0);
% % setAnalogChannel(curtime,3,Kitten_curval); %kitten
% % setAnalogChannel(curtime,1,QP_curval); %top QP
% % 
% % %wait 500ms
%  curtime = calctime(curtime,10000);
% % 
% % 
% %  QP_ramp_time = 500;
% %     
% %     QP_value = 30; %new value of the QP %30
% %     Kitten_value = 6.2;  %6.2, 0.206*QP_value
% %     %addOutputParam('Kitten_value',Kitten_value);
% % 
% %     %     %"cold" resistance is 0.68-0.69 Ohms, but as the coil heats up this
% % %     %resistance increase
% %     vSet = 12.25;
% %     %vSet_ramp = 0.755*QP_value/0.9+0.75 ;
% %     vSet_ramp = 20;  %24.5 for QP = 35 @10s %21.5 hold %17.5 for ramping just top QP to 30, 19 for kitten to 6.2, 20 for kitten to 0
% %    
% %     
% %     if vSet^2/4/(2*0.310) > 700
% %         error('Too much power dropped across FETS');
% %     end
% %     
% %     
% %      %ramp up voltage supply depending on transfer
% %          AnalogFunc(calctime(curtime,10),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),QP_ramp_time,QP_ramp_time, vSet_ramp, vSet);
% % 
% %     %ramp coil 16
% %      AnalogFunc(curtime,1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+QP_curval),QP_ramp_time,QP_ramp_time,QP_value-QP_curval);
% %     
% %     %ramp Kitten
% %      curtime = AnalogFunc(curtime,3,@(t,tt,dt)(minimum_jerk(t,tt,dt)+Kitten_curval),QP_ramp_time,QP_ramp_time,Kitten_value-Kitten_curval);
% %  
% %      curtime = calctime(curtime,100);
% % 
% % % %bleed off some current
% % % Bleed_value = 2;
% % % QP_transfer_time = 1000;
% % %         
% % % %resistance increase
% % % vSet_ramp = 0.755*(QP_initial_current+0*Bleed_value/1.8)+0.75;
% % % 
% % % %ramp up voltage supply depending on transfer
% % % AnalogFunc(calctime(curtime,-200),18,@(t,tt,v2,v1)((v2-v1)*t/tt+v1),QP_transfer_time,QP_transfer_time, vSet_ramp, vSet);
% % % 
% % % addOutputParam('Bleed_value',Bleed_value);
% % % curtime = AnalogFunc(curtime,37,@(t,tt,dt)(minimum_jerk(t,tt,dt)),QP_transfer_time,QP_transfer_time,Bleed_value);
% % %        
% % % %wait 1s
% % % curtime = calctime(curtime,500);
% % 
% %turn everything off
% if turn_off
%     setDigitalChannel(calctime(curtime,30),22,0); %15/16 switch 
%     setAnalogChannel(curtime,1,0); %top qp
%     setAnalogChannel(curtime,3,0); %kitten
%     setAnalogChannel(curtime,21,0); %bottom QP
%     setAnalogChannel(curtime,37,0); %Bleed FET
%     setAnalogChannel(curtime,20,0)
%     setAnalogChannel(calctime(curtime,50),18,0)
%     
% end
% 
% curtime = calctime(curtime,100);

%% Test new supply with Feshbach coils

% % % %turn on coils
% curtime=calctime(curtime,500);
% setDigitalChannel(calctime(curtime,-400),42,0);
% setAnalogChannel(calctime(curtime,-395),37,-0.5);
% setDigitalChannel(calctime(curtime,-400),31,1);
% 
% DigitalPulse(calctime(curtime,0),'ScopeTrigger',1,1)
% curtime=AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),200,200,0,1*22.6);
% 
% curtime = calctime(curtime,800);
% 
% setAnalogChannel(calctime(curtime,0),37,-0.5);
% setDigitalChannel(calctime(curtime,30),31,0);

% curtime=AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),200,200,0,20);
% 
% curtime = AnalogFunc(calctime(curtime,500),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),200,200,-2.0,0);
% 
% 
% 
% %turn off coils
% setAnalogChannel(calctime(curtime,50),37,0.5,1);
% setDigitalChannel(calctime(curtime,0),31,1);


% % setAnalogChannel(calctime(curtime,1500),37,0.0,1);
% setAnalogChannel(calctime(curtime,150),37,-0.5,1);
% setDigitalChannel(calctime(curtime,200),31,0);

%% Test Shim Relay

%Dummy analog set
% setAnalogChannel(curtime,38,-0.1);

% setDigitalChannel(curtime,43,0);

%% Test Dipole beam

% %Rotate waveplate
% SetAnalogChannel(calctime(curtime,0),'latticeWaveplate',0.0,1);
% % 
% curtime = calctime(curtime,100);
% % % 
% % %turn on
% setDigitalChannel(calctime(curtime,-10),'XDT TTL',1);
% setDigitalChannel(calctime(curtime,0),'XDT Direct Control',0);
% SetAnalogChannel(curtime,'dipoleTrap1',0); 
% SetAnalogChannel(curtime,'dipoleTrap2',0);
% % % 
% % drive = 0;
% % 
% % if drive 
% % 
% %     %parameters
% %     amp=0.1;
% %     offset=1;
% %     freq = 5500;
% %     osc_time = 1000;
% % 
% %     %put
% %     curtime = AnalogFunc(curtime,38, @(t,y1,y2,freq)(y1+y2*sin(2*3.14*freq*t/1000)),osc_time,offset,amp,freq);
% % 
% % else
% %     curtime = calctime(curtime,0);
% % end
% % 
% curtime = calctime(curtime,5000);
% % ScopeTriggerPulse(calctime(curtime,-250),'XDT On');
% % scope_trigger = 'XDT On';
% % 
% %turn off
% setDigitalChannel(calctime(curtime,10),'XDT TTL',1);
% SetAnalogChannel(curtime,'dipoleTrap1',-9,1); 
% SetAnalogChannel(curtime,'dipoleTrap2',-9,1);

% %  %%%
% %         exp_end_pwr =1;
% %         
% %         CDT_power = 10
% %         
% %         exp_evap_time = 5000;
% %         exp_tau = exp_evap_time/3.0; %exp_evap_time/4
% %         
% %         evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));
% % 
% %  %ramp down dipole 1 
% %         AnalogFunc(calctime(curtime,0),40,@(t,tt,tau,y2,y1)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_time,exp_tau,exp_end_pwr,CDT_power);
% %         %ramp down dipole 2 
% %         curtime = AnalogFunc(calctime(curtime,0),38,@(t,tt,tau,y2,y1)(evap_exp_ramp(t,tt,tau,y2,y1)),exp_evap_time,exp_evap_time,exp_tau,exp_end_pwr,CDT_power);
        
%%

% %% turn on OP
% 
%  %AM
%  setAnalogChannel(curtime,36,0.5,1);
%  %TTL
%  setDigitalChannel(curtime,24,0);
%  %Shutter
%  setDigitalChannel(curtime,25,1);
% % 

%% look @ elliptical beam
% 
% % %turn on dipole 2
 %SetAnalogChannel(curtime,38,6.0); 
% % %turn on dipole 1
%SetAnalogChannel(curtime,40,4.5); 
% %trigger camera
% curtime = DigitalPulse(calctime(curtime,0),26,0.2,1);

% % % %rampon dipole
% dip_ramptime = 3000;
% dip1_pwr_end=3.25;
% dip2_pwr_end=2*dip1_pwr_end;
% dip1_pwr_start=0;
% dip2_pwr_start=0;
% % 
% %turn on dipole 1
%  Analogfunc(calctime(curtime,0),40,@(t,tt,y0,y1)(y1*t/tt+y0),dip_ramptime,dip_ramptime,dip1_pwr_start,dip1_pwr_end);
% %turn on dipole 2
% curtime = Analogfunc(calctime(curtime,0),38,@(t,tt,y0,y1)(y1*t/tt+y0),dip_ramptime,dip_ramptime,dip2_pwr_start,dip2_pwr_end);

% %Turn on Lattice Beam
% setDigitalChannel(curtime,11,0)
% setDigitalChannel(curtime,34,0)

%turn on beam
%SetAnalogChannel(calctime(curtime,200),38,0.7); 
%SetAnalogChannel(calctime(curtime,2000),40,0); 

%turn off beam
%SetAnalogChannel(calctime(curtime,5000),38,-0.3,1); 
%SetAnalogChannel(calctime(curtime,2000),40,-0.3,1); 

% % % %Dummy analog channel set
%  setAnalogChannel(curtime,36,0.0,1);
% %  
%  curtime = calctime(curtime,2000);
% % % % 
% %     %trigger camera
%     curtime = DigitalPulse(calctime(curtime,10),26,0.2,1);
% % % %  
%     %trigger camera
%     curtime = DigitalPulse(calctime(curtime,2000),26,0.2,1);
% % % % 
% % % 
% % % %Turn off lattice beam
%   setDigitalChannel(curtime,34,1)

 %% Take Image of the D1 Molasses Beams Using CCD
% % 
% %Dummy analog channel set
% setAnalogChannel(curtime,40,0.0,1);
% % % % % 
% %D1 Starts Off so Shutter can Open
% setDigitalChannel(curtime,35,0);
% % 
% % 
% curtime = calctime(curtime,10);
% % % % 
% %Turn on D1 Beam
% setDigitalChannel(curtime,35,1);
% % 
% %open the D1 Shutter
% setDigitalChannel(calctime(curtime,-3),36,1);
% % 
% % % %Turn on D1 AM Control (currently channel 47, will change later)
% % % setAnalogChannel(curtime,47,0,1);
% % % 
% % % %Ramp up D1 Power
% % % D1_startpower = 0;
% % % D1_endpower = 2;
% % % D1_ramptime = 0.4;
% % % 
% % % Analogfunc(calctime(curtime,0),47,@(t,tt,y0,y1)(y1*t/tt+y0),D1_ramptime,D1_ramptime,D1_startpower,D1_endpower);
% % 
% % %trigger camera
%  curtime = DigitalPulse(calctime(curtime,2000),26,0.2,1);
% % % 
% curtime = calctime(curtime,15);
% % % % 
% %Turn off D1 Beam
% setDigitalChannel(curtime,35,0)
% % % 
% %close the D1 Shutter
% setDigitalChannel(curtime,36,0);
% % % % 
% % % % %Turn off D1 AM Control (currently channel 47, will change later)
% % % % setAnalogChannel(curtime,47,0.0,1);
% % 
% %trigger camera
%  curtime = DigitalPulse(calctime(curtime,500),26,0.2,1);


%% Ramp Dipole
% 
% dipole_channels = [1 1];
% 
% setAnalogChannel(curtime,38,-0.0,1);
% setAnalogChannel(curtime,40,-0.0,1);
% % 
% curtime = calctime(curtime,2000);
% % 
% dipole_ramp_start_time = -500;
% dipole_ramp_up_time = 500; %500
% % 
% CDT_power = 3.4;
% % 
% dipole1_power = CDT_power;
% dipole2_power = CDT_power; %Voltage = 0.328 + 0.2375*dipole_power...about 4.2Watts/V when dipole 1 is off
% %  
% % %ramp dipole 1 trap on
% if dipole_channels(1)
%     AnalogFuncTo(calctime(curtime,dipole_ramp_start_time),40,@(t,tt,y2,y1)(ramp_linear(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole1_power);
% end
% 
% if dipole_channels(2)
%     %ramp dipole 2 trap on
% %     AnalogFunc(calctime(curtime,dipole_ramp_start_time),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole2_power,0);
%     AnalogFuncTo(calctime(curtime,dipole_ramp_start_time),38,@(t,tt,y2,y1)(ramp_linear(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole2_power);
% end
% % 
% curtime = calctime(curtime,3000);
% 
% ScopeTriggerPulse(curtime,'Mid ODT');
% scope_trigger = 'Mid ODT';
% 
% curtime = calctime(curtime,3000);
% % 
% %  CDT_pwrs = [CDT_power 0.75];
% %     CDT_times = [2500]*1.5;
% %     
% % %          CDT_power_list=[10 8 6 4 3 2 1.5 1];
% % %          CDT_times = [2000];
% % %          CDT_pwrs = [CDT_power CDT_power];
% % %         % 
% % %         % %Create linear list
% % %         %index=seqdata.cycle;
% % %         % 
% % %         % %Create Randomized list
% % %         index=seqdata.randcyclelist(seqdata.cycle);
% % %         % 
% % %         CDT_pwrs(2) = CDT_power_list(1);
% % %         addOutputParam('CDT_power', CDT_pwrs(2));    
% %     
% %     for i = 1:length(CDT_times)
% %         CDT_start_pwr1 = CDT_pwrs(i);
% %         CDT_end_pwr1 = CDT_pwrs(i+1);
% %         CDT_evap_time1 = CDT_times(i);
% %         %ramp down dipole 1 
% %         if dipole_channels(1)
% %             AnalogFunc(calctime(curtime,0),40,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),CDT_evap_time1,CDT_evap_time1,CDT_end_pwr1,CDT_start_pwr1);
% %         end
% %         if dipole_channels(2)
% %             %ramp down dipole 2
% %             AnalogFunc(calctime(curtime,0),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),CDT_evap_time1,CDT_evap_time1,CDT_end_pwr1,CDT_start_pwr1);
% %         end
% %         
% %         curtime = calctime(curtime,CDT_evap_time1);
% %         
% %     end
% % 
% setAnalogChannel(curtime,38,-0.1,1);
% setAnalogChannel(curtime,40,-0.1,1);

%% Test QP Ramp Down

% %Turn on coil 16
% 
% %make sure fast switch is off
% setDigitalChannel(curtime,21,0);
% 
% %15/16 switch is on
% setDigitalChannel(curtime,22,0);
% 
% curtime = calctime(curtime,20);
% 
% %23.1, 15.4
% 
%  %ramp up voltage supply depending on transfer
%  %AnalogFunc(calctime(curtime,0),18,@(t,tt,v0)((v0-5)/tt*t+5),100,100,15.4);
% %setAnalogChannel(curtime,18,15.4);
% setAnalogChannel(curtime,1,0); %16
% setAnalogChannel(curtime,21,0); %15
% setAnalogChannel(curtime,3,0,1); %kitten
% %disconnect kitten
% setDigitalChannel(calctime(curtime,0),29,0);
% 
% %15/16 switch is on
% setDigitalChannel(calctime(curtime,20),22,1);
% 
% %relay
% %setDigitalChannel(calctime(curtime,0),28,0);
%  
% %ramp coil 16
% setAnalogChannel(curtime,18,15);
% curtime = setAnalogChannel(calctime(curtime,250),1,23.1);
%  
% % freqs_1b = [10*0.8 4 1.0 0.38]*1E6; %0.28 %0.315
% %     RF_gain_1b = [-4 -4 -4]; %-4
% %     sweep_times_1b = [3000 1500 1500]; %1500
% % %  
% % curtime = do_evap_stage(curtime, 1, freqs_1b, sweep_times_1b, RF_gain_1b, 0, 1);
% % 
% 
%  
%  %turn off
%  curtime = calctime(curtime,5000);
%  
%  %ramp down in 200ms
%   curtime = AnalogFunc(calctime(curtime,150),1,@(t,tt,I0)((I0-23.1)/tt*t+23.1),200,200,5);
%  
%  curtime = calctime(curtime,500);
%  
%   %ramp up voltage supply depending on transfer
%  setAnalogChannel(curtime,18,0);
%  setAnalogChannel(curtime,1,0,1);
% setAnalogChannel(curtime,9,0,1);
 
%% Test Rotating Waveplate

%     curtime = calctime(curtime,1000);
%     
% %     set rotating waveplate back to full dipole power UNCALIBRATED
%     setAnalogChannel(curtime,'latticeWaveplate',0.9);
%     AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),1000,1000,0.0);
%     curtime = calctime(curtime,1000);
    

%Voltage control on channel 41
%     %function 3 is power transmitted to lattice AOMs expressed in (0,1)
% setAnalogChannel(curtime,41,0.3,3);
% 
% setAnalogChannel(calctime(curtime,0),45,5,2);
% setDigitalChannel(calctime(curtime,0),34,0);
% %   
%   curtime = calctime(curtime,1000);
%DigitalPulse(curtime,26,0.1,1); 
%curtime = calctime(curtime,1000);
%DigitalPulse(curtime,26,0.1,1);  
%   
% 
%  %Shutter
%     setDigitalChannel(calctime(curtime,50),36,0);
%     
%     DigitalPulse(calctime(curtime,250),36,500,1);

%curtime = calctime(curtime,1000);
% for i=1:100
% 
% setAnalogChannel(curtime,41,1,3);
% 
% curtime = calctime(curtime,300);
% 
% setAnalogChannel(curtime,41,0.5,3);
% 
% curtime = calctime(curtime,300);
% 
% setAnalogChannel(curtime,41,0,3);
% 
% curtime = calctime(curtime,300);
% 
% setAnalogChannel(curtime,41,0.5,3);
% 
% curtime = calctime(curtime,300);
% 
% end

% %Ramp up
% P_final = 1;
% ramp_time = 3000;
% 
% curtime = AnalogFunc(curtime,41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),ramp_time,ramp_time,P_final);
% 
%  %Ramp down
% curtime = AnalogFunc(curtime,41,@(t,tt,Pmax)(0.5*asind(sqrt((1)*(1-t/tt)))/9.36),500,500,0);


%Ramp up


% curtime = calctime(curtime,2000);
% 
% setAnalogChannel(curtime,41,0,3);

%% Pulse Lattice

%setAnalogChannel(curtime,41,0.0,3);
%   
% curtime = calctime(curtime,1000);
% 
% lattice_pulse_time = 0.040;
% 
% DigitalPulse(calctime(curtime,0),34,lattice_pulse_time+0,0);

%setAnalogChannel(calctime(curtime,200),41,0.0,1);

 %% Test Vertical Lattice beam
% 
% % % LaVsetting = 0.0;
% % % 
% startPower = 0;
% endPower = 0;
% latt_ramptime = 100;
% % % 
% % % 
%Turn rotating waveplate to shift some power to the lattice beams
%  rotation_time = 1000;   %The time to rotate the waveplate
%  P_lattice = 0.9;    %The fraction of power that will be transmitted through the PBS to lattice beams
% 
% %  setAnalogChannel(calctime(curtime,250),19,0,1);
% %  % %                         %0 = dipole, 1 = lattice
% % % % 
% curtime = calctime(curtime,1500);
% % % % %      
% Enable rf output on ALPS3 (fast rf-switch -- 0: ON / 1: OFF)
%     setDigitalChannel(calctime(curtime,0),34,0);
% % % 
%  AnalogFunc(calctime(curtime,-100-rotation_time),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
% % % % 
% % setDigitalChannel(calctime(curtime,500),34,0);
% % % setAnalogChannel(calctime(curtime,0),43,0,2);
% % setAnalogChannel(calctime(curtime,0),45,-10,1);
% % % % setAnalogChannel(calctime(curtime,1000),43,-2,1);
% % AnalogFunc(calctime(curtime,500),45,@(t,tt,dt)(minimum_jerk(t,tt,dt)+startPower),latt_ramptime,latt_ramptime,endPower,2);
% % % 
% % %AnalogFunc(calctime(curtime,dipole_ramp_start_time),38,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),dipole_ramp_up_time,dipole_ramp_up_time,dipole2_power,0);
% % 
% % setDigitalChannel(calctime(curtime,1000),34,1);
% % setAnalogChannel(calctime(curtime,1000),43,-10,1);

 %% Test Feshbach Field Stability
% 
%     FB_value = 18;
% 
%     setDigitalChannel(calctime(curtime,0),'FB offset select',0);
%     setDigitalChannel(calctime(curtime,0),'FB sensitivity select',0);
%     setDigitalChannel(calctime(curtime,0),'FB Integrator off',0);
%     setDigitalChannel(calctime(curtime,0),'fast FB switch',0);
%     setAnalogChannel(calctime(curtime,0),'FB current',-0.5);
%         
%     curtime = calctime(curtime,100);
% %     setDigitalChannel(calctime(curtime,0),'FB Integrator off',0);
%     setDigitalChannel(calctime(curtime,0),'fast FB switch',1);
% 
%     setAnalogChannel(calctime(curtime,0),'FB current',0);
%     AnalogFunc(calctime(curtime,100),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,FB_value);
%     
%     %Hand over to fine control
%     curtime = calctime(curtime,250);
%     DigitalPulse(calctime(curtime,0),'ScopeTrigger',10,0);
%     setDigitalChannel(calctime(curtime,0),'FB offset select',0);
%     setDigitalChannel(calctime(curtime,0),'FB sensitivity select',1);
%     setAnalogChannel(calctime(curtime,0.05),'FB current',FB_value,4);
%     
%     
%     curtime = calctime(curtime,100);
%     
%     
%     
%     
%     
%     curtime = calctime(curtime,100);
%     setDigitalChannel(calctime(curtime,0),'FB offset select',0);
%     setDigitalChannel(calctime(curtime,0),'FB sensitivity select',0);        
%     curtime = AnalogFunc(calctime(curtime,0.00),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,FB_value,0);
%     
%     setDigitalChannel(calctime(curtime,0),'FB offset select',0);
%     setDigitalChannel(calctime(curtime,0),'FB sensitivity select',0);
%     setDigitalChannel(calctime(curtime,0),'FB Integrator off',0);
%     setDigitalChannel(calctime(curtime,0),'fast FB switch',0);
%     setAnalogChannel(calctime(curtime,0),'FB current',-0.5);
 



%% Test Feshbach Field Stability

% ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);

%dummy set shim
 %   curtime = setAnalogChannel(calctime(curtime,250),19,0,1);
 %     curtime = setAnalogChannel(calctime(curtime,250),5,0.0);

 %setAnalogChannel(calctime(curtime,0),37,1,1);
 %AnalogFunc(curtime,37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),10,10,20,0);
 %setDigitalChannel(calctime(curtime,-100),31,1);
 
 %setAnalogChannel(calctime(curtime,1000),37,0.0,1);
 %setDigitalChannel(calctime(curtime,1100),31,0);
 
 %setAnalogChannel(curtime,46,0,1);
      %DigitalPulse(calctime(curtime,500),26,1,1);
      
      %DigitalPulse(calctime(curtime,3500),26,1,1);
    
%test new Digital channel
    %setDigitalChannel(calctime(curtime,150),33,0);

    %channel_test = 20;
    
% %TURN ON
%     %set supply voltage
%     setAnalogChannel(calctime(curtime,100),18,5);
%     %set CATS current
%     curtime=setAnalogChannel(calctime(curtime,100),channel_test,5);
%     
% %TURN OFF
%     %set supply voltage
%     setAnalogChannel(calctime(curtime,3000),18,0);
%     %set CATS current
%     setAnalogChannel(calctime(curtime,3000),channel_test,0,1);
% %     
%     

    
%     DigitalPulse(calctime(curtime,350),27,10,1);
% %     
%     fesh_test_ramptime = 300;
%     fesh_test_current = 4*21.45;
%     fesh_test_sweep = -0.2;
%     fesh_test_ontime = 10000;
%     
% 
%ramp Feshbach field
%         SetDigitalChannel(calctime(curtime,10),31,1); %switch Feshbach field on with Digital
%         curtime = SetAnalogChannel(calctime(curtime,160),37,0.0); %switch Feshbach field to 0 with Analog
        %linear ramp up
%          curtime=AnalogFunc(calctime(curtime,100),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_test_ramptime,fesh_test_ramptime, fesh_test_current,0);
%          %linear ramp up
%          DigitalPulse(calctime(curtime,fesh_test_ontime),12,1,1);
         %curtime=AnalogFunc(calctime(curtime,fesh_test_ontime),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),10,10, fesh_test_sweep+fesh_test_current,fesh_test_current);
%         DigitalPulse(calctime(curtime,20),27,10,1);    
         
% %hold on
%     curtime=calctime(curtime,fesh_test_ontime);
%     
% %shut off fesh field
%     setDigitalChannel(calctime(curtime,5),31,0); %fast switch
%     setAnalogChannel(calctime(curtime,0),37,-0.1,1);%0
% 
% QP_recap_time = 100;
% 
%  %kitten and coil 15 must be off
%             setAnalogChannel(calctime(curtime,QP_recap_time),3,0,1);
%             setAnalogChannel(calctime(curtime,QP_recap_time),21,0,1);
%             %turn on 15/16 switch (10 ms later)
%             setDigitalChannel(calctime(curtime,QP_recap_time),22,0);
%             %coil 16
%             setAnalogChannel(calctime(curtime,QP_recap_time),1,0);
%             %fast switch
%             setDigitalChannel(calctime(curtime,QP_recap_time),21,1);

%% Test shims
% 
% setDigitalChannel(curtime,'Shim Relay',0);
% setDigitalChannel(curtime,'Shim Multiplexer',1);%%0 = MOT Shims (unipolar)
% curtime = calctime(curtime,500);
% curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);
% curtime = calctime(curtime,500);
% setAnalogChannel(calctime(curtime,0),'X Shim',0,3);
% setAnalogChannel(calctime(curtime,0),'Y Shim',0,4);
% setAnalogChannel(calctime(curtime,0),'Z Shim',-0.25,3);
% 
% DigitalPulse(calctime(curtime,0),12,10,1);   
% 
% relay = 5;
% 
% %Z coil polarity: 0=regular, 5=switch
%      setAnalogChannel(calctime(curtime,0),47,relay,1);
% 
%     %set time
%     curtime=calctime(curtime,300);
%     
%     current_set  =-0.0026; %-0.0035
%     
%     %set shims
%         %parameters
%         shim_ramp_time = [200 200 200];
%         x_Bzero = [-0.5 -0.5 -0.5 -0.5 0]; %-0.5
%         y_Bzero = [-0.5 -0.5 -0.5 -0.5 0]; %0.5
%         z_Bzero = [-0.5 -0.5 -0.5 -0.5 0];
%         Extra_Bzero = [current_set current_set current_set current_set current_set];
%         %Extra2_Bzero = [0 1 0 0];
%         
%         setAnalogChannel(calctime(curtime,0),'Z Shim',z_Bzero(1),1);
%         setAnalogChannel(calctime(curtime,0),'X Shim',x_Bzero(1),1);
%         setAnalogChannel(calctime(curtime,0),48,Extra_Bzero(1),1);
%         %setAnalogChannel(calctime(curtime,0),47,Extra2_Bzero(1),2);
%         curtime = setAnalogChannel(calctime(curtime,0),'Y Shim',y_Bzero(1),1);
%         
%         %curtime=calctime(curtime,300);
%     
%         AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(1),shim_ramp_time(1), y_Bzero(2),y_Bzero(1),1);
%         AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(1),shim_ramp_time(1),z_Bzero(2),z_Bzero(1),1);
%         AnalogFunc(calctime(curtime,0),48,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(1),shim_ramp_time(1),Extra_Bzero(2),Extra_Bzero(1),1);
%         %AnalogFunc(calctime(curtime,0),47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(1),shim_ramp_time(1),Extra2_Bzero(2),Extra2_Bzero(1),2);
%         curtime = AnalogFunc(calctime(curtime,0),'X Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(1),shim_ramp_time(1),x_Bzero(2),x_Bzero(1),1);
%         
%         %curtime = calctime(curtime,700);
%        
%         
%         AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(2),shim_ramp_time(2), y_Bzero(3),y_Bzero(2),1);
%         AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(2),shim_ramp_time(2),z_Bzero(3),z_Bzero(2),1);
%         AnalogFunc(calctime(curtime,0),48,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(2),shim_ramp_time(2),Extra_Bzero(3),Extra_Bzero(2),1);
%         %AnalogFunc(calctime(curtime,0),47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(2),shim_ramp_time(2),Extra2_Bzero(3),Extra2_Bzero(2),2);
%         curtime = AnalogFunc(calctime(curtime,0),'X Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(2),shim_ramp_time(2),x_Bzero(3),x_Bzero(2),1);
%         
%         curtime = calctime(curtime,700);
%         
%                 setAnalogChannel(calctime(curtime,0),47,relay,1);
%         
%         curtime = calctime(curtime,300);
%         
%         AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(3),shim_ramp_time(3), y_Bzero(4),y_Bzero(3),1);
%         AnalogFunc(calctime(curtime,0),'Z Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(3),shim_ramp_time(3),z_Bzero(4),z_Bzero(3),1);
%         AnalogFunc(calctime(curtime,0),48,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(3),shim_ramp_time(3),Extra_Bzero(4),Extra_Bzero(3),1);
%         %AnalogFunc(calctime(curtime,0),47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(3),shim_ramp_time(3),Extra2_Bzero(4),Extra2_Bzero(3),2);
%         curtime = AnalogFunc(calctime(curtime,0),'X Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time(3),shim_ramp_time(3),x_Bzero(4),x_Bzero(3),1);
% 
% 
% %           
% %             setAnalogChannel(calctime(curtime,0),'Z Shim',z_Bzero(2),1);
% %             setAnalogChannel(calctime(curtime,0),'X Shim',x_Bzero(2),1);
% %             curtime = setAnalogChannel(calctime(curtime,0),'Y Shim',y_Bzero(2),1);
% % 
%  curtime=calctime(curtime,1700);
%     
%     %set frequency   
%     
%         sweep_uwave = 0;
%     
%         if sweep_uwave
%             %parameters
%             start_freq =0.7; %2.625MHz/V and 2.1MHz/G means 0.8 G/V
%             end_freq = start_freq-0.1;
%             sweep_uwave_time = 7000;
%              do_uwave_pulse(calctime(curtime,500), 0, 0*1E6, sweep_uwave_time,2);
%              setAnalogChannel(calctime(curtime,0),46,start_freq,1);
%              curtime = AnalogFunc(calctime(curtime,500+50),46,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),sweep_uwave_time,sweep_uwave_time, end_freq,start_freq);
%         else
%             freq_val = -1.0;
%             uwave_time = 2000;
%             setAnalogChannel(calctime(curtime,50),46,freq_val,1);
%             curtime = do_uwave_pulse(calctime(curtime,50), 0, 0*1E6, uwave_time,2);
%         end
% %         
% %     %shut off shims
%             setAnalogChannel(calctime(curtime,50),'Z Shim',z_Bzero(end),1);
%             curtime = setAnalogChannel(calctime(curtime,50),'X Shim',x_Bzero(end),1);
%             setAnalogChannel(calctime(curtime,50),48,Extra_Bzero(end),1);
%             %setAnalogChannel(calctime(curtime,50),47,Extra2_Bzero(end),1);
%             curtime = setAnalogChannel(calctime(curtime,50),'Y Shim',y_Bzero(end),1);
%     
%             curtime=calctime(curtime,300);
%             
% %         curtime = calctime(curtime,200);
% %         
% %                 setAnalogChannel(calctime(curtime,0),47,5,1);
% %         
% %         curtime = calctime(curtime,200);
%             
%             
%                   %setAnalogChannel(calctime(curtime,0),47,0,1);
% %             DigitalPulse(curtime,12,10,1);
% %             
% %      %always switch coil back to normal
% %      setAnalogChannel(calctime(curtime,0),48,0,1);
% %      curtime = calctime(curtime,50);
% %      
% %     

% setAnalogChannel(curtime,47,0,2);
% 
% setAnalogChannel(curtime,46,0.0,1);

%% uWave
% % Preset analog channel
% setAnalogChannel(calctime(curtime,0),57,-1);
% 
% % Enable ACync
% curtime=setDigitalChannel(calctime(curtime,10),56,1);
% 
% 
% % AnalogFunc(calctime(curtime,15),57,@(t,tt,y2,y1)(ramp_linear(t,tt,y2,y1)),2,2,-1,1,1);
% % 
% % AnalogFunc(calctime(curtime,20),57,@(t,tt,y2,y1)(ramp_linear(t,tt,y2,y1)),2,2,1,-1,1);
% 
% % setAnalogChannel(calctime(curtime,100),62,0);
% 
% % setAnalogChannel(calctime(curtime,100),'z shim',-1,1);
% % setAnalogChannel(calctime(curtime,110),'z shim',9,1);
% 
% sweep_time=10;
% beta=asech(0.01);
%          AnalogFunc(calctime(curtime,0),57,...
%             @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
%             sweep_time,sweep_time,beta,1);
%         
% % setDigitalChannel(calctime(curtime,100),39,1);
% % setDigitalChannel(calctime(curtime,110),39,0);
% 
% 
% setDigitalChannel(calctime(curtime,25),56,0);
% 
% curtime = calctime(curtime, 2000)
% % 
% % setDigitalChannel(calctime(curtime,1300),14,0);
%% Test Objective piezo

% obj_piezo_V = 0;
% % 
% setAnalogChannel(calctime(curtime,100),42,obj_piezo_V,1);
% 
% setAnalogChannel(calctime(curtime,3000),42,obj_piezo_V,1);
% % 
%% Test uWave Source

%setAnalogChannel(curtime,46,0);

%% Ramp FM of 405nm Double Pass AOM
% 
% curtime = calctime(curtime,1000);
% 
% offset = 174.2;
% freq1 = 210;
% %freq2 = 200;
% %freq_time = 100;
% % 
% %Blue FM
%setAnalogChannel(calctime(curtime,100),47,202);
% %Blue AM (best diffraction at 0.4V)
%setAnalogChannel(calctime(curtime,100),48,0.5);
% %Blue Shutter
% setDigitalChannel(calctime(curtime,50),23,1)
% 
% %AnalogFunc(curtime,47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),freq_time,freq_time,(-11.703+0.09098*freq2),(-11.703+0.09098*freq1),1);
% 
% setDigitalChannel(calctime(curtime,500),23,0);

%% Test D1 TTL and Analog
% % 
% warm_time = 100;
% pulse_time = 5000;
% % ramp_time = 1000;
% % 
% % ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
% % % 
% % %Set D1 Detuning 
% setAnalogChannel(calctime(curtime,0),48,187);
% % % 
% % % %Set D1 Raman AM
% % % setAnalogChannel(calctime(curtime,0),49,-1);
% % % 
% % % %Wait for some time
% % curtime = calctime(curtime,1000);
% % % 
% % % %Analog Ramp
% % % curtime = AnalogFunc(curtime,49,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramp_time,ramp_time,0,-1,1);
% % % 
% % % %Warm Up AOM with TLL and Analog while Shutter is Closed
% % % % 
%     setDigitalChannel(calctime(curtime,0),'D1 TTL B',1);
%     setAnalogChannel(curtime,38,-0.5,1);
%     setDigitalChannel(calctime(curtime,0),36,0);
% % % 
% % % %Wait for some Warm Up Time
%     curtime = calctime(curtime,warm_time);
% % % 
% % % %Turn off AOM with TTL briefly before opening shutter, then turn on with
% % % %TTL
% %     %TTL OFF
%     setDigitalChannel(calctime(curtime,-7),35,0);
% % %     %Set Analog to 0 Initially
%      setAnalogChannel(calctime(curtime,-2),47,6.3);
% %     Shutter Open
%     setDigitalChannel(calctime(curtime,-4),36,1);
% %     %TTL ON (pulse)
% curtime = DigitalPulse(calctime(curtime,0),35,pulse_time,1);
% %     %TTL ON (no pulse)
% %     setDigitalChannel(calctime(curtime,0),35,0);
% %     %Analog Ramp
% % curtime = AnalogFunc(curtime,47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramp_time,ramp_time,6.5,0,1);
% % %     
% %     %Wait for some time
%     curtime = calctime(curtime,10);
% %     %Turn Beam off with TTL
%     setDigitalChannel(calctime(curtime,0),35,1);
% %     
% %     
%     %Close Shutter After
%     setDigitalChannel(calctime(curtime,0),36,0);
% %     %Set AOM Back to Warming Mode after some time
% %     wait_time=100;
% %     setDigitalChannel(calctime(curtime,wait_time),35,1);
%     setAnalogChannel(calctime(curtime,wait_time),47,6.5,1);
% 
% % % % % % % % %     k_D1_detuning_trap_power = 1.0;
%     k_D1_detuning = 192.5;
% % % % % % % % %     img_molasses_time = 5000;
% % % % % % % % % % 
% % % % % % % % %       curtime = calctime(curtime,1001);
% % % % % % % % % % 
% % % % % % % % % %     %turn on D1 AOM 20s before it's being used in order for it to
% % % % % % % % %         %warm up
%         setAnalogChannel(calctime(curtime,0),47,4.5,1);
% % % % % % % % % %             
% % % % % % % % %         %AOM is usually ON to keep warm, so turn off TTL before opening shutter
% % % % % % % % %         setDigitalChannel(calctime(curtime,-5),35,0);
% % % % % % % % % % %  
% % % % % % % % % % 
% % % % % % % % %         %Turn on beam with TTL
% % % % % % % % %             %Set Detuning
%             setAnalogChannel(calctime(curtime,0),48,k_D1_detuning);
% % % % % % % % %             %Shutter  
% % % % % % % % %             setDigitalChannel(calctime(curtime,-4),36,1);
% % % % % % % % %             %TTL ON
% % % % % % % % %             setDigitalChannel(calctime(curtime,0),35,1);
% % % % % % % % % %             
% % % % % % % % % %                       
% % % % % % % % % %     %do molasses for sometime
% % % % % % % % % %     curtime = calctime(curtime,img_molasses_time);
% % % % % % % % % % %     
% % % % % % % % % %         %Turn off D1
% % % % % % % % %     setDigitalChannel(calctime(curtime,0),36,0); %Shutter
% % % % % % % % %     setDigitalChannel(calctime(curtime,0),35,0); %TTL
% % % % % % % % % 
% % % % % % % % %    
% % % % % % % % %     %After some time, turn TTL and Analog back on to keep AOM Warm
% % % % % % % % %     setDigitalChannel(calctime(curtime,500),35,1);
% % % % % % % % %     setAnalogChannel(calctime(curtime,500),47,k_D1_detuning_trap_power,1);
% % % % % % % % %     
% % % % % % % % %     %Set Repump Sidebands to Full Power Until D1 Comes On Again
% % % % % % % % %     setAnalogChannel(calctime(curtime,-5),49,0);
            
%% Test Shims

% % Set Shim Multiplexer (0 = MOT, 1 = Science)
% setDigitalChannel(calctime(curtime,0),'Shim Multiplexer',1);
% 
% curtime = calctime(curtime,100);
% % Reset magnetometer.
% curtime = sense_Bfield(curtime);
%  
% % Current shim field-zeroing values:
% shim_zero = [(0.1585-0.016), (-0.0432-0.022), (-0.0865-0.015)];
% 
% % Set Shims to zero before opening relay.
% curtime = calctime(curtime,50);
% setAnalogChannel(curtime,'X Shim',0.0,3);
% setAnalogChannel(curtime,'Y Shim',0.0,4);
% setAnalogChannel(curtime,'Z Shim',0.0,3);
% 
% % Open Science Cell Shim Relay
% setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);
% 
% curtime = calctime(curtime,50);
% 
% % Trigger the scope. 
% DigitalPulse(curtime,'ScopeTrigger',1,1);
% 
% % Do a linear ramp if desired.
% % shim_ramptime = 250;
% % img_xshim = 1;
% % AnalogFuncTo(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,img_xshim,3);
% 
% % Set shim values to desired. 
% setAnalogChannel(calctime(curtime,0),'Z Shim',0.3,3); 
% setAnalogChannel(calctime(curtime,0),'Y Shim',0.3,4); 
% setAnalogChannel(calctime(curtime,0),'X Shim',0.3,3);
% 
% curtime = calctime(curtime,100);
% 
% % Reset everything. 
% setAnalogChannel(curtime,'X Shim',0.0,3);
% setAnalogChannel(curtime,'Y Shim',0.0,4);
% setAnalogChannel(curtime,'Z Shim',0.0,3);
% setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);
% setDigitalChannel(calctime(curtime,0),'Shim Multiplexer',0);

%% Check Tuning Range of K Trap AOM

%  curtime = calctime(curtime,100);
% % 
%  k_detuning =20;
% % 
%  setAnalogChannel(calctime(curtime,0),5,k_detuning);
%  setAnalogChannel(calctime(curtime,10),5,k_detuning);
%  

% setAnalogChannel(calctime(curtime,-0.5),'K Probe/OP FM',190);

% setAnalogChannel(calctime(curtime,-10),'K Probe/OP AM',0.7);
% 
% %shutter
% setDigitalChannel(calctime(curtime,-10),'K Probe/OP Shutter',1);
% 
% curtime = DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',100,0);
% 
% setDigitalChannel(calctime(curtime,2),'K Probe/OP Shutter',0);

% plugpwr =1*1000E-3;
% 
% %open plug shutter
%     setDigitalChannel(calctime(curtime,0),10,1);
%     %ramp on plug beam
%     %AnalogFunc(calctime(curtime,plug_offset+1),33,@(t,tt,pwr)(pwr*t/tt),100,100,plugpwr);
%     setAnalogChannel(calctime(curtime,0+2),33,plugpwr);
%     
%     curtime = calctime(curtime,5);
%     
%     setAnalogChannel(calctime(curtime,0),33,0);
%     setDigitalChannel(calctime(curtime,10),10,0);

%% Test OP/Probe AOM
% curtime = calctime(curtime,1000);
% k_detuning = 3;
%         setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0);
% % set probe detuning
%         setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',190); %195
% %         SET trap AOM detuning to change probe
%         setAnalogChannel(calctime(curtime,0),'K Trap FM',k_detuning); %54.5
% 
%         setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.9);
%         setAnalogChannel(calctime(curtime,0),'K Trap AM',0.8);
%         
%         setDigitalChannel(calctime(curtime,0),'K Probe/OP shutter',0);
        

% curtime = calctime(curtime,1000);
%         setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1);
%         % set probe detunings
%         rb_op_detuning = 5;
% 
%         setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FF',0.047-0.1254/32.71*(rb_op_detuning-23),1); %0.05-0.1254/32.71*(rb_op_detuning-23)
%         %offset detuning ... should be close to the MOT detuning
%         setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FM',6590+rb_op_detuning);
% 
%         setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.9);
%         
%         setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0);
        
%         
% %         %set probe detuning
% %          setAnalogChannel(curtime,'K Probe/OP FM',202.5); %202.5
% %         %SET trap AOM detuning to change probe
% %         setAnalogChannel(curtime,'K Trap FM',42); %54.5
% %         %AM
% %         setAnalogChannel(curtime,'K Probe/OP AM',0.0,1);%0.65
%         
%         curtime = calctime(curtime,1000);

%% Recalibrate Transport Coil Current
% 
% setAnalogChannel(curtime,18,2.0,1);
% setAnalogChannel(calctime(curtime,10),20,-10);
% 
% DigitalPulse(curtime,12,10,1)
% 
% curtime = calctime(curtime,500);
% 
% setAnalogChannel(curtime,18,0);
% setAnalogChannel(calctime(curtime,-10),20,0);

%     curtime = calctime(curtime,1000);
% 
% %  %% Test Lattice     
%   curtime = calctime(curtime,1500);
% % % % % % % % 
% % % % % % % % 
%  rotation_time = 1000;   %The time to rotate the waveplate
%  P_lattice = 0.5;    %The fraction of power that will be transmitted through the PBS to lattice beams
%  
% 
%  AnalogFunc(calctime(curtime,-100-rotation_time),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
% % % 
% % % % setDigitalChannel(calctime(curtime,0),50,1); %0: ON / 1: OFF
% % % % setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);
% % % % curtime = calctime(curtime,1000);    
% % % %     
% % % curtime = calctime(curtime,100);
% % % % % %      
% % depth = 40/0.4; %Channel is calibrated to units of Rb recoil energy
% % Enable RF Output
% setDigitalChannel(calctime(curtime,-15),34,0); %0: ON / 1: OFF
% setDigitalChannel(calctime(curtime,-15),'Lattice Direct Control',0);
% % % % % % 
% %Set Lattice Powers
% % setAnalogChannel(curtime,45,depth);
% % setAnalogChannel(curtime,44,depth);
% % setAnalogChannel(curtime,43,depth);
%  lat_rampup_time = 25;
% %  depth = [600 600 600]/0.4;
%  depth = [1100 1000 350]/0.4;
% % % % 
% % % Default voltage functions.
% AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(1));
% AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(2));
% AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(3));
% % % Direct voltages.
% % % AnalogFunc(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(1), 1);
% % % AnalogFunc(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(2), 1);
% % % AnalogFunc(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time, lat_rampup_time, 0, depth(3), 1);
% % % % 
% % % % % 
% % %  curtime = calctime(curtime,3000);
% ScopeTriggerPulse(calctime(curtime,0),'Lattice Regulation');
% curtime = calctime(curtime,100);
% % % % % % 
% setAnalogChannel(curtime,45,-10,1);
% setAnalogChannel(curtime,44,-5.0,1);
% setAnalogChannel(curtime,'zLattice',-10,1);
% % % % % % 
% setDigitalChannel(calctime(curtime,5),34,1); %0: ON / 1: OFF
% setDigitalChannel(calctime(curtime,10),'Lattice Direct Control',1);
% 
% 
% %Rotate waveplate back to zero at the end
% AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),1000,1000,0,1);
%% Test K uWaves
% % % 
% % % % setAnalogChannel(curtime,38,-0.3,1);
% % % % % % % % % 
% % % % % % % % 
% % % % % % % % % ScopeTriggerPulse(calctime(curtime,0),'D1 Molasses Start');
% % % % % % % % 
% % % % % % % % % %Open K uWave switch.
% % % % curtime = calctime(curtime,100)
% % % % setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',1);
% % % % setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',0);
% % % % setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
% % % % setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
% % % % setAnalogChannel(calctime(curtime,0),'uWave VVA',9.9);
% % % % % % % 
% % % % % % % setAnalogChannel(curtime,46,-1,1);
% % % % % % % % 
% % % % seqdata.flags. SRS_programmed(1) = 0;
% % % % seqdata.flags. SRS_programmed(2) = 0;
% % % % 
% % % % spect_pars.fake_pulse = 0;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
% % % % spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
% % % % spect_pars.SRS_select = 1; %0: Use SRS A, 1: Use SRS B
% % % % spect_pars.delta_freq = 100/1000;
% % % % spect_pars.mod_dev = spect_pars.delta_freq/2; 
% % % % spect_pars.power = 14;
% % % % spect_pars.freq = 1606.75;
% % % % spect_pars.pulse_type = 1;  
% % % % spect_pars.AM_ramp_time = 2;
% % % % spect_pars.pulse_length = 20;
% % % % 
% % % % spect_type = 1; %1: sweeps, 2: pulse
% % % % ScopeTriggerPulse(curtime,'State Transfer');
% % % % scope_trigger = 'State Transfer';
% % % % curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
% % % % 
% % % % % % % Open Rb uWave switch (0 is off)
% % % % % % setDigitalChannel(calctime(curtime,50),14,0);
% % % % % 
% % % % % % setAnalogChannel(calctime(curtime,0.4),'Y Shim',3.5);
% % % % % 
% % % % % %Open Probe Shutter
% % % % % % setDigitalChannel(calctime(curtime,0),'K Probe/OP Shutter',1);
% % % % % % %analog
% % % % % % setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.7);
% % % % % % setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',190.5);
% % % % % % setAnalogChannel(calctime(curtime,0),'K Trap FM',12.5);
% % % % % %TTL
% % % % % % DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',1,0);
% % % % % 
% % % % % % curtime = calctime(curtime,1000);
% % % % % 
% % % % % % setAnalogChannel(calctime(curtime,0.0),'Y Shim',0,1);

%% K Probe OP

% %set probe detuning
% setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',190); %195
% setAnalogChannel(calctime(curtime,0),'K Trap FM',3);
% 
% % % %SET trap AOM detuning to change probe
%  setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1); %0.3
% % setAnalogChannel(calctime(curtime,0),'K Trap FM',34); %54.5
% setAnalogChannel(calctime(curtime,10),'K Probe/OP AM',0.7);
% % setAnalogChannel(calctime(curtime,0),'K Repump AM',0.3);
% 
% setDigitalChannel(calctime(curtime,0),24,0)
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0.8); %0.11
    %TTL


%% Test 405 TTL Control

%     set rotating waveplate back to full dipole power
% setAnalogChannel(curtime,'latticeWaveplate',0.00,3);



% setAnalogChannel(curtime,40,4.2);
%   setAnalogChannel(curtime,38,1.7);
% %   
%   curtime = calctime(curtime,300);
% % %   
%   setAnalogChannel(curtime,40,-0.5,1);
%   setAnalogChannel(curtime,38,-0.5,1);
  
  
% setAnalogChannel(curtime,45,-10,1);
% setDigitalChannel(calctime(curtime,0),34,1);  %0: ON / 1: OFF
% setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);

%  setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0,1);
%  %Turn 405 TTL off/on -> off = 0, on = 1. 
%  setDigitalChannel(calctime(curtime,0),23,0)
%  setDigitalChannel(calctime(curtime,50),38,1);

% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0,1);
% 
% img_molasses_time = 100;
% ramp_time = 0;
% % Amount of time to do pulses
% pulse_window = img_molasses_time-50;
% 
% % Hand over digital control of D1 and blue to Rigol generator
% setDigitalChannel(calctime(curtime,ramp_time),'405nm TTL',0);
% setDigitalChannel(calctime(curtime,ramp_time),'D1 TTL',0);
% DigitalPulse(calctime(curtime,ramp_time),51,pulse_window,1);
% curtime = calctime(curtime,100);

%% Test Offset Chip Laser TTL

%  setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
%  setDigitalChannel(calctime(curtime,0),'Offset TTL',1); %1: off, 0: on

 %% Test 5P1/2 TTL
%  setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
%  setDigitalChannel(calctime(curtime,0),'404.8nm TTL',1); %0: off, 1: on

%% Test RF From DDS
% 
% setAnalogChannel(curtime,40,4,2);
% setAnalogChannel(curtime,38,2.5,2);
% % 
% curtime = calctime(curtime,600);
% % 
% setAnalogChannel(curtime,40,-0.3,1);
% setAnalogChannel(curtime,38,-0.3,1);
% %setAnalogChannel(curtime,39,0);
% setDigitalChannel(calctime(curtime,0),19,0);

%% Test D1 Sidebands
% 
% ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
% 
% %Set Repump Sidebands to Zero Initially
% setAnalogChannel(calctime(curtime,0),49,-1);
%       
% setAnalogChannel(calctime(curtime,0),48,250);

% sideband_ramp_time = 5000;
%             
% %Ramp on the Repump Sideband
% AnalogFunc(calctime(curtime,10),49,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),sideband_ramp_time,sideband_ramp_time,0,-1,1);
% 
% k_D1_detuning_trap_power = 3.5;
% setAnalogChannel(calctime(curtime,0),47,k_D1_detuning_trap_power,1);

%% Test Transport Relay
%  setDigitalChannel(curtime,28,0);
%  setAnalogChannel(curtime,38,-1);

%% Test Lattice FM

% curtime = calctime(curtime,10);
% 
% ScopeTriggerPulse(calctime(curtime,0),'D1 Molasses Start');
% 
% %initial channel values to enable Rigol control
% setDigitalChannel(curtime,'K Probe/OP TTL',1);
% setDigitalChannel(calctime(curtime,-5),'K Probe/OP Shutter',1);
% 
% setDigitalChannel(curtime,'D1 TTL',1);
% setDigitalChannel(calctime(curtime,-5),36,1);
% 
% 
% k_D1_detuning_trap_power = 5.5;
% ramp_time = 5;
% 
% %Linear ramp function
% ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
% %Set Analog to 0 Initially
% setAnalogChannel(calctime(curtime,-8),47,0);
% %Ramp Analog over 1ms
% curtime = AnalogFunc(curtime,47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramp_time,ramp_time,k_D1_detuning_trap_power,0,1);
% 
% setDigitalChannel(calctime(curtime,0.5),'K Probe/OP TTL',0);
% setDigitalChannel(calctime(curtime,0.5),'D1 TTL',0);
% curtime = DigitalPulse(curtime,51,10,1);
% 
% %Turn off Probe Beam
% setDigitalChannel(calctime(curtime,5),'K Probe/OP TTL',1);
% setDigitalChannel(calctime(curtime,5),'K Probe/OP Shutter',0);
% 
% %Close D1 shutter
% setDigitalChannel(curtime,36,0);
% 
% %Wait for Final probe Pulse
% curtime = calctime(curtime,10);
% 
% %Final Probe Pulse
% DigitalPulse(curtime,'K Probe/OP Shutter',10,1);
% DigitalPulse(curtime,'K Probe/OP TTL',5,0);
% 
% %Keep warm
% setDigitalChannel(calctime(curtime,50),'D1 TTL',1);

% k_probe_pwr = 1*0.3;
% %Set AM for Optical Pumping
% setDigitalChannel(curtime,'K Probe/OP TTL',0);
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',k_probe_pwr,1);%0.65


%% Test Spectroscopy
% setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',1);
% setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',0); %0: K, 1: Rb
% 
% 
% curtime = calctime(curtime,500);
%         
%         freq_val = [-7 ];
%                 % -8.65 for |7/2,7/2> to |9/2,9/2>
%                 % -6.5 for |7/2,5/2> to |9/2,7/2>
% %        spect_pars.freq = 1285.8+freq_val; %MHz
%         spect_pars.power = -5; %uncalibrated "gain" for rf
% %         freq_list = (265:2.5:275)/1000;%
% %         spect_pars.delta_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'freq_val');
%         spect_pars.delta_freq = 2;
%         Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
%         
%         %Quick little addition to start at freq_val instead.
%         if(~Cycle_About_Freq_Val)
%             spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
%         end
%         
%         spect_pars.pulse_length = 1000; % also is sweep length
%         spect_type = 8; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps 8: Multiple sweeps
%         
%             %Some trial code for multiple microwave sweeps.
%         for Counter = 1 : length(freq_val)
%             spect_pars.freq = 1285.8 + freq_val(Counter);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0), spect_type, spect_pars);   
%         end

% %% Ramp Fields
% ramp_fields = 1;
% 
%     if ramp_fields
%         
%         
%         
%         %Time to hold at the field settins
%         holdtime = 1500;
%         
%         %Close Science Cell Shim Relay for Plugged QP Evaporation
%         setDigitalChannel(calctime(curtime,0),37,1); 
%         setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1);
%         SetDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);
%         setDigitalChannel(calctime(curtime,0),31,1);
%         curtime = calctime(curtime,1000);
%         
%         %Set initial values for the coils
%         ramp.fesh_init = 0;
%         setAnalogChannel(calctime(curtime,0),37,ramp.fesh_init);
%         
%         shim_init = 0;
%         setAnalogChannel(calctime(curtime,0),19,shim_init,4);
%         setAnalogChannel(calctime(curtime,0),27,shim_init,3);
%         setAnalogChannel(calctime(curtime,0),28,shim_init,3);
% 
%         
%         clear('ramp');
%        
% %         getChannelValue(seqdata,27,1,0)
% %         getChannelValue(seqdata,19,1,0)
% %         getChannelValue(seqdata,28,1,0)
% %         
%         %First, ramp on a quantizing shim.
%         ramp.shim_ramptime = 50;
%         ramp.shim_ramp_delay = -0;
%         ramp.xshim_final = 1;
%         ramp.yshim_final = 1;%1.61;
%         ramp.zshim_final = 1; %0.065 for -1MHz   getChannelValue(seqdata,28,1,0)
%         
%         %Give ramp shim values if we want to do spectroscopy using the
%         %shims instead of FB coil. If nothing set here, then
%         %ramp_bias_fields just takes the getChannelValue (which is set to
%         %field zeroing values)
%         %ramp.xshim_final = getChannelValue(seqdata,27,1,0);
% %         ramp.yshim_final = 1;
%         %ramp.zshim_final = getChannelValue(seqdata,28,1,0);
%         
% %         % FB coil settings for spectroscopy
% %         ramp.fesh_ramptime = 50;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = 1.0105*2*22.6; %1.0077*2*22.6 for same transfer as plane selection
%         
%         % FB coil settings for spectroscopy
% %         ramp.fesh_ramptime = 50;
% %         ramp.fesh_ramp_delay = -0;
% %         ramp.fesh_final = 5*22.6;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
%         
% %         % QP coil settings for spectroscopy
% %         ramp.QP_ramptime = 50;
% %         ramp.QP_ramp_delay = -0;
% %         ramp.QP_final =  0*1.78; %7
% 
%         
%         ramp.settling_time = 100;
%         
% curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
%     
%     
%     %Hold for some time
%     curtime = calctime(curtime,holdtime);
%     
%     
%     %Ramp back down to zero
%     
%     %Shims
%         ramp.xshim_final = 0;
%         ramp.yshim_final = 0;%1.61;
%         ramp.zshim_final = 0;
%     
%     % FB coil settings for spectroscopy
%         ramp.fesh_ramptime = 50;
%         ramp.fesh_ramp_delay = -0;
%         ramp.fesh_final = 0.0*22.6; %18
%         
% %         % QP coil settings for spectroscopy
% %         ramp.QP_ramptime = 50;
% %         ramp.QP_ramp_delay = -0;
% %         ramp.QP_final =  0; %18
% %         ramp.settling_time = 100;
% 
%         
%         ramp.settling_time = 100;
%         
% curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
%     
% 
% ScopeTriggerPulse(curtime,'Start TOF',0.1);
%     
%     
%     
%     
%     
%     end

%% Test DDS for 4-Pass AOM
% MHz=10^6;
% curtime = calctime(curtime,100);
% DDSFreq = 324.20625*MHz;
% DDS_sweep(calctime(curtime,-10),2,DDSFreq,DDSFreq,100);
% 
% % setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
% setAnalogChannel(calctime(curtime,0),47,10,1);


%% Test B Field Impulse Response

% source = 2; % 0 = Nothing, 1 = Feshbach, 2 = Z-Shim, 3 = Coil 16
% 
% curtime = calctime(curtime,100);
% setAnalogChannel(curtime,'no name',0);
% curtime = sense_Bfield(curtime); %First, reset the magnetometer.
% 
% switch source
%     case 0
%         %Do nothing.    
%     case 1 %FB
%         SetDigitalChannel(calctime(curtime,0),'fast FB Switch',1); %This is no longer used, but perhaps should be.
%         setAnalogChannel(calctime(curtime,0),'FB current',0);
%         curtime = calctime(curtime, 100);
%         ScopeTriggerPulse(curtime,'Pulse Field');
%         setAnalogChannel(calctime(curtime,0),'FB current',2); %Bring this to 2G. 
%         curtime = calctime(curtime,100);
%         SetDigitalChannel(calctime(curtime,0),'fast FB Switch',0); %This is no longer used, but perhaps should be.
%         setAnalogChannel(calctime(curtime,0),37,-0.5); %Wait 100ms and set back to 0. 
%     case 2 %Z-Shim
%         % Set Shim Multiplexer (0 = MOT, 1 = Science)
%         setDigitalChannel(calctime(curtime,0),'Shim Multiplexer',1);
%         setAnalogChannel(curtime,'Z Shim',0,3);
%         curtime = calctime(curtime, 100);
%         ScopeTriggerPulse(curtime,'Pulse Field');
%         setAnalogChannel(curtime,'Z Shim',1,3); %Pulse on the z-shim to a small value.
%         curtime = calctime(curtime, 100);
%         setAnalogChannel(curtime,'Z Shim',0,3);
%         setDigitalChannel(calctime(curtime,0),'Shim Multiplexer',0);
%     case 3 %Coil 16
%         setDigitalChannel(curtime,'Kitten Relay',1); %0: OFF, 1: ON
%         setDigitalChannel(curtime,'15/16 Switch',0); %0: OFF, 1: ON
%         setDigitalChannel(curtime,'Coil 16 TTL',0); %1: off; 0: on
%         curtime = calctime(curtime,100);
%         %Ramp off MOT
%         setAnalogChannel(calctime(curtime,-50),8,2);
%         AnalogFuncTo(calctime(curtime,0),8,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0,2);
%         curtime = calctime(curtime,100);
%         current = 2;
%         channel = 1;
%         %set FF
%         %use the following for QT coil
%         AnalogFunc(calctime(curtime,0),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0.5,25*(abs(current)/30)/1 + 0.5);
%         %Kitten to max current for the ramp if using coil 15 or 16 alone.
%         setAnalogChannel(calctime(curtime,25),3,5,1); % current set to 5 for 15 on   
%         %"Turn on" coil to 0
%         setAnalogChannel(calctime(curtime,50),channel,0,1); %Start at zero for AnalogFuncTo
%         %digital trigger
%         ScopeTriggerPulse(calctime(curtime,75),'Pulse Field');
%         setAnalogChannel(calctime(curtime,75),channel,0.75,1);
%         setAnalogChannel(calctime(curtime,175),channel,0,1);
%         setAnalogChannel(calctime(curtime,175),3,0,1);
%         %Go back to MOT gradient for wait time
%         gradient = 2;
%         % curtime = calctime(curtime,2000);
%         %set FF
%         setAnalogChannel(calctime(curtime,300),18,23*(gradient/30) + 0.5);
%         %Turn on Coil
%         curtime = setAnalogChannel(calctime(curtime,300),8,gradient,2);
%         % 
%         %set all transport coils to zero (except MOT)
%         for i = [7 9:17 22:24 20] 
%             setAnalogChannel(calctime(curtime,325),i,0,1);
%         end
%         %Turn off QP Coils
%         setAnalogChannel(calctime(curtime,325),'Coil 15',0,1); %15
%         curtime = setAnalogChannel(calctime(curtime,325),'Coil 16',0,1); %16
%         curtime = setAnalogChannel(calctime(curtime,325),3,0,1); %kitten
%         curtime = setDigitalChannel(calctime(curtime,325),'15/16 Switch',0);
% 
% end
% 
% scope_trigger = 'Pulse Field';



%% Test Feshbach Coil Movement
% curtime = calctime(curtime, 300);
% 
% SetDigitalChannel(calctime(curtime,0),31,1);
% setAnalogChannel(calctime(curtime,0),37,0);
% % 
% curtime = calctime(curtime, 500);

% ScopeTriggerPulse(curtime,'Feshbach Noise');
% scope_trigger = 'Feshbach Noise';
% 
% Repetitions = 1;
% for Counter = 1 : Repetitions
%     % FB coil settings for spectroscopy
%     clear('ramp')
%     ramp.fesh_ramptime = 100;
%     ramp.fesh_ramp_delay = -250;
%     ramp.fesh_final = 20;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
%     ramp.use_fesh_switch = 0; %Don't actually want to close the FB switch to avoid current spikes
% 
%     ramp.settling_time = 200;
% 
%     curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
% 
%     Wait_Time = 200;
%     
%     curtime = calctime(curtime, Wait_Time);
%     
%     clear('ramp')
%     ramp.fesh_ramptime = 100;
%     ramp.fesh_ramp_delay = -250;
%     ramp.fesh_final = 0;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
%     ramp.use_fesh_switch = 0; %Don't actually want to close the FB switch to avoid current spikes
% 
%     ramp.settling_time = 200;
% 
%     curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
% 
% end
% 
% SetDigitalChannel(calctime(curtime,0),31,0);
% SelectScopeTrigger(scope_trigger);


%% Test Raman Beams
% setAnalogChannel(calctime(curtime,0),64,0.0);

% curtime = calctime(curtime, 1000);
% setAnalogChannel(calctime(curtime,0),64,0);
% AOM_Frequency = 109;
% Raman_Power1 = 1;
% Raman_Power2 = Raman_Power1;
% 
% curtime = calctime(curtime,500);
% str = sprintf('SOURce1:SWEep:STATe OFF;SOURce1:MOD:STATe OFF;SOURce1:FREQuency %gMHZ;SOURce1:VOLT %g;SOURce2:VOLT %g;', AOM_Frequency, Raman_Power1, Raman_Power2);
% addVISACommand(4, str); 
% 
% curtime = calctime(curtime, 1000);

% %Raman excitation beam AOM-shutter sequence.
% DigitalPulse(calctime(curtime,-150),'Raman TTL',150,0);
% DigitalPulse(calctime(curtime,-100),'Raman Shutter',Pulse_Length+3100,0);
% DigitalPulse(calctime(curtime,Pulse_Length),'Raman TTL',3050,0);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
%% Test Dimple Trap
% 
%  setDigitalChannel(calctime(curtime,0),'Dimple TTL',0);
%  setDigitalChannel(calctime(curtime,0),'Dimple Shutter',1);
%  setAnalogChannel(calctime(curtime,0),'Dimple Pwr',1);
%  
%  setAnalogChannel(calctime(curtime,3000),'Dimple Pwr',0.1);

%% Test K trap negative shim imaging 
%SET trap AOM detuning to change probe
 %      setAnalogChannel(curtime,'K Trap FM',50); %54.5
%         setAnalogChannel(curtime,'K Trap AM',0.8,1); %54.5

%% Test F-Pump Feedback Control
% 
% setDigitalChannel(calctime(curtime,0),'D1 TTL B',0);
% setAnalogChannel(calctime(curtime,0),'F Pump',-1);
% %% Test DMD
% setAnalogChannel(calctime(curtime,0),63,0);
% % setDigitalChannel(calctime(curtime,0),'DMD TTL',0);%1 off 0 on
% % setDigitalChannel(calctime(curtime,100),'DMD TTL',1); %pulse time does not matter
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
% setAnalogChannel(calctime(curtime,1),'DMD Power',-1);
% 
% % setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
% 

%% Test Kill BEam
% % open K probe shutter
% setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0); %0=closed, 1=open
% setDigitalChannel(calctime(curtime,10),'Kill TTL',0);%0= off, 1=on

%% Test modulation code

% setDigitalChannel(calctime(curtime,0),'Dimple TTL',0);
% setAnalogChannel(calctime(curtime,0),'Dimple Pwr',1);
% 
% curtime = calctime(curtime, 50);
% 
% freq_list = [20]*1e3; %560
% mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% 
% time_list = [50];
% mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_time');
% mod_amp = 0.4;
% addOutputParam('mod_amp',mod_amp);
% mod_wait_time = 0;
%     
% % Apply the lattice modulation   
% curtime = applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_time, ...
%     'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod');
% % Wait for some time
% 
% setDigitalChannel(calctime(curtime,0),'Dimple TTL',1);
% setAnalogChannel(calctime(curtime,0),'Dimple Pwr',0);


%% Test dimple

% setAnalogChannel(calctime(curtime,0),'Dimple Pwr',0);
% 
%     Dimple_Power = 4;%maximum is 6
%     Dimple_Ramp_Time = 100; %50
%     
%     setDigitalChannel(calctime(curtime,0),'Dimple TTL',0);%0
% %     AnalogFunc(calctime(curtime,50),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, 0, Dimple_Power); 
%     
% curtime = AnalogFuncTo(calctime(curtime,50),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, Dimple_Power); 
% 
% curtime = calctime(curtime, 1500);
% 
%     Dimple_Ramp_Time = 100;%50
%     AnalogFuncTo(calctime(curtime,0),'Dimple Pwr',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), Dimple_Ramp_Time, Dimple_Ramp_Time, -0.933); %0
%     curtime = setDigitalChannel(calctime(curtime,110),'Dimple TTL',1);
%     
%     setAnalogChannel(calctime(curtime,0),'Dimple Pwr',0);
%% push beam test
% %     %Additional Rb probe to separate K and Rb atoms during MOT loading.
% % %     Rb_Push_Power = 0.7;
% curtime = calctime(curtime, 1000);
% %     
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',0);
%     setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0);
%     setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',-1,4);


%% Test Rb Probe/OP 
% curtime = calctime(curtime, 1000);
%     %shutter
%     setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP Shutter',0);
%     %analog
%     setDigitalChannel(calctime(curtime,5),'Rb Probe/OP TTL',1); % inverted logic
%     setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0); %0.11
%     %TTL
%     setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1); % inverted logic
%      
% curtime = calctime(curtime, 1000);
    
%% Test Raman VVA

% curtime = calctime(curtime,500);

% Pulse_Time = 1;
% Rise_Time = 0.01;

% DigitalPulse(calctime(curtime,-150-Rise_Time),'Raman TTL',150,0);
% DigitalPulse(calctime(curtime,-100-Rise_Time),'Raman Shutter',Pulse_Time+2*Rise_Time+3100,0);
% DigitalPulse(calctime(curtime,Pulse_Time+Rise_Time),'Raman TTL',3050,0);

% setAnalogChannel(calctime(curtime,-10),'Raman VVA',0);
% 
% AnalogFuncTo(calctime(curtime,0-Rise_Time),'Raman VVA',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Rise_Time,Rise_Time,9.9);
% curtime = AnalogFuncTo(calctime(curtime,Pulse_Time),'Raman VVA',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),Rise_Time,Rise_Time,0);        
% curtime = calctime(curtime,30);
% ScopeTriggerPulse(curtime,'Raman Plane Select');
% setAnalogChannel(calctime(curtime,0),'Raman VVA',10);  

    
    %% Test Dipole beam modulation by Pizeo_mirror_mount
    
% 
%         curtime = calctime(curtime,500);
% % %           
%         setAnalogChannel(calctime(curtime,-10),'Raman VVA',0); 
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);
% % %         
% % %         setDigitalChannel(calctime(curtime,0),'d15',0)
% % %         setDigitalChannel(calctime(curtime,10),'d15',1)
% %         
% %         freq_list = [1]; %560
% %         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% % 
% %         time_list = [1000];
% %         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_time');
% %         mod_amp = 1;
% %         addOutputParam('mod_amp',mod_amp);
% %         mod_wait_time = 0;
% %         
% %         mod_offset_list = [5 ]- mod_amp/2;
% %         mod_offset = getScanParameter(mod_offset_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_offset1');
% %         addOutputParam('mod_offset',mod_offset + mod_amp/2);
% % %         mod_offset = mod_amp/2;
% % 
%         mod_freq1 = 10;
%         mod_amp1 = 1;
%         mod_offset1 = 1;
%         str1 = sprintf('SOURce1:APPL:SIN;SOURce1:FREQ %g;SOURce1:VOLT %g;SOURce1:VOLT:OFFS %g;',mod_freq1, mod_amp1, mod_offset1);
%         addVISACommand(2, str1);
%         
%         mod_freq2=10;
%         mod_amp2= 10;
%         mod_offset2 = -5;
%         str2 = sprintf('SOURce2:APPL:SIN;SOURce2:FREQ %g;SOURce2:VOLT %g;SOURce2:VOLT:OFFS %g;',mod_freq2, mod_amp2, mod_offset2);
%         addVISACommand(2,str2);
% %         
% 
% %     Apply the lattice modulation   
% curtime = applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_offset, mod_time, ...
%         'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod'); 
%         
%     
    
    
%     
%     ScopeTriggerPulse(curtime,'shaking_XDT');
%     scope_trigger = 'shaking_XDT';
%         
%         freq_list = [100]; %560
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
% 
%         time_list = [1000];
%         mod_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_time');
%         mod_amp = 6;
%         addOutputParam('mod_amp',mod_amp);
%         mod_wait_time = 0;
%         
%         mod_offset = 0/2;
%         
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
% %         setDigitalChannel(calctime(curtime,1),'Lattice FM',0);
% curtime = calctime(curtime,mod_time);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);
% %         setDigitalChannel(calctime(curtime,1),'Lattice FM',0);
%         
% %     Apply the lattice modulation   
% curtime = applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_offset, mod_time, ...
%         'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod');

% SetAnalogChannel(curtime,32,0,1)

%% Test variable gain box for PZT modulation

%     setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0.1);
%     setDigitalChannel(calctime(curtime,0),'Lattice FM',0);


%% Test external frequency modulation of shear mode aom

%         mod_freq = 100;
%         mod_time = 150;
%         mod_amp = 1;
%         
%         mod_offset = 0;
%         final_mod_amp_ref = 5;
% 
%         mod_ramp_time = 50; %1000/mod_freq*2
%         AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp_ref); 
%         
%     % Apply the lattice modulation   
% curtime = applyLatticeModulation(calctime(curtime,0), mod_freq, mod_amp, mod_offset, mod_time, ...
%         'Lattice', 'zlattice', 'RampLatticeDelta', 0, 'ScopeTrigger', 'Lattice_Mod');
% curtime = calctime(curtime,-0.5); 
% 
% setAnalogChannel(curtime,'Modulation Ramp',0.1)

%    %Lattices to pin.  
%     AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40/atomscale); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40/atomscale)
% curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 0.5, 0.5, 40/atomscale);

%% Test getmultiScanParameter
% setAnalogChannel(calctime(curtime,0),'Modulation Ramp',10,1);
% setDigitalChannel(calctime(curtime,0),'Lattice FM',1);  
% freq_list = [100 200]; 
% mod_freq = getmultiScanParameter(freq_list,seqdata.scancycle,'Forcing_Freq',1,2);
% time_list = [3*mod_freq 4*mod_freq];
% mod_time = getmultiScanParameter(time_list,seqdata.scancycle,'Forcing_Time',1,1);

%%%%--------------------set Rigol DG1022Z----------
% str011=sprintf(':SOUR1:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
% str012=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:OUTP1 ON;');
% str021=sprintf(':SOUR2:APPL:SIN %f,%f,%f,%f;',mod_freq,1,0,0);%freq = mod_freq,amp = 1, offset =0,phase =0;
% str022=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:OUTP2 ON;');
% str01=[str011, str012];
% addVISACommand(3,str01);
%%%%--------------------set Rigol DG1022Z----------


%% test kill beam
% setAnalogChannel(curtime,'uWave FM/AM',0);
% setDigitalchannel(curtime,'XDT TTL',0);
% setAnalogChannel(curtime,'dipoleTrap1',0.05);
% curtime=calctime(curtime,5000);
% 
% setDigitalchannel(curtime,'XDT TTL',1)
% setAnalogChannel(curtime,'dipoleTrap1',-2)
% setDigitalchannel(calctime(curtime,5000),'Kill TTL,1')
% sDigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,0);
% 
% setAnalogChannel(curtime,'Dimple Pwr',-10);
% % DigitalPulse(curtime,'Lattice FM',100,1);
% DigitalPulse(curtime,'Lattice FM',100,1);
%% rotate wave plate
%     rotation_time_I = 600; %happens before lattice rampup (during XDT)
% 
%     P_RotWave = 0.10; 
%     
%     AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time_I,rotation_time_I,P_RotWave);
% curtime = calctime(curtime,1000);

%% test rigol
% 
%         %Initialize modulation ramp to off.
%         setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0);
% 
%         %Parameters for rotation-induced effective B field.
%         rot_freq_list = [200];
%         rot_freq = getScanParameter(rot_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rot_freq');
%         rot_amp_list = [2];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         rot_amp = 1*getScanParameter(rot_amp_list,seqdata.scancycle,seqdata.randcyclelist,'rot_amp');
%         rot_offset_list = [0];
%         rot_offset = getScanParameter(rot_offset_list,seqdata.scancycle,seqdata.randcyclelist,'rot_offset');
%         rot_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         %These amplitudes and angles probably need to be tweaked!
%         rot_dev_chn1 = rot_amp;
%         rot_dev_chn2 = rot_amp*16.95/13.942;
%         rot_offset1 = rot_offset;
%         rot_offset2 = rot_offset*16.95/13.942;
%         rot_phase1 = 0;
%         rot_phase2 = 90;
%         
%         %Parameters for linearly-polarized conductivity modulation. This
%         %needs to rotate in time.
%         freq_list = [10];
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list = [0:160/mod_freq:2000/mod_freq];%[0:160/mod_freq:2000/mod_freq];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [1]; %Should probably be less than rot_amp.
%         mod_amp = 1*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp');
%         offset_list = [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         
%         mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_dev_chn1*16.95/13.942;%modulate along x_lat direction,when mod_angle=30
% %         mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;% %modulate along y_lat directio
%         mod_offset1 = mod_offset;
%         mod_offset2 = mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;%modulate along x_lat direction
% %       mod_offset2 =-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%modulate along y_lat direction
% 
%         mod_phase1 = 0;
%         mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
% 
%   
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn1,rot_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',rot_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',rot_freq,rot_dev_chn2,rot_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',rot_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);
% %         %-------------------------set Rigol DG1022 ---------
% %         str211=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
% %         str212=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
% %         str221=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
% %         str222=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
% %         str231=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
% %         str3=[str212,str211,str221,str222,str231];
% %         addVISACommand(3, str3);
%         
%         %-------------------------end:set Rigol-------------       
%         
%         %ramp the modulation amplitude
%         mod_ramp_time_list = [150];%150 sept28
%         mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
%         final_mod_amp = 1;
%         mod_wait_time = 50;
%         offset = 5; %XDT piezo offset
%                 
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity_modulation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
%         
%         %Need to use Adwin to generate linear modulation.
%         %Need to use Adwin to generate linear modulation.
%         XDT1_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * cos(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))) .* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         XDT2_Func = @(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)((rot_amp * sin(2*pi*f_rot*t) .* (1 + mod_amp/rot_amp*cos(2*pi*f_drive*t))).* (((y2-y1) .* (t/ramp_time) + y1).*(t<ramp_time) + y2.*(t>=ramp_time)) + offset);
%         Drive_Time = mod_time+mod_ramp_time+mod_wait_time;
%         AnalogFunc(calctime(curtime,0),'XDT1 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT1_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn1,rot_freq/1000,mod_dev_chn1,mod_freq/1000,0,1,mod_ramp_time,offset);
%         AnalogFunc(calctime(curtime,0),'XDT2 Piezo',@(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)(XDT2_Func(t,rot_amp,f_rot,mod_amp,f_drive,y1,y2,ramp_time,offset)),Drive_Time,rot_dev_chn2,rot_freq/1000,mod_dev_chn2,mod_freq/1000,0,1,mod_ramp_time,offset);
% 
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
% 
% curtime = calctime(curtime,mod_wait_time);
% 
% curtime = calctime(curtime,mod_time);
%         setAnalogChannel(curtime,'XDT1 Piezo',5);
%         setAnalogChannel(curtime,'XDT2 Piezo',5);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT
%         post_mod_wait_time_list = [0];  
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
% 
% curtime = calctime(curtime,post_mod_wait_time);
%% Test AC Coupled Scope Response
% setAnalogChannel(calctime(curtime,0),'Plug Beam',1);
% setDigitalChannel(calctime(curtime,0),'Plug TTL',0);
% curtime = calctime(curtime,500);
% setDigitalChannel(calctime(curtime,0),'Plug TTL',1);

%% Test Plug and TiSapph

% % % %Plug beam
% setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %0: off, 1: on
% setAnalogChannel(calctime(curtime,0),'Plug Beam',5,1);
% % % 
%         setAnalogChannel(curtime,'Rb Repump AM',0.2); %0.14  
% % setDigitalChannel(calctime(curtime,2000),'Rb Trap Shutter',0)%1: ON, 0: OFF
% % setDigitalChannel(calctime(curtime,4000),'Rb Trap Shutter',1)%1: ON, 0: OFF
% % setDigitalChannel(calctime(curtime,6000),'Rb Trap Shutter',0)%1: ON, 0: OFF
% curtime=calctime(curtime,8000);
% % 
% % %Compensation beams
% setDigitalChannel(calctime(curtime,0),'Compensation Shutter',1); %0: on, 1: off
% setAnalogChannel(calctime(curtime,0),'Compensation Power',0);
% setDigitalChannel(calctime(curtime,0),'Compensation Direct',1); %0: off, 1: on
% setDigitalChannel(calctime(curtime,0),'Plug TTL',0); %0: on, 1: off


%% Test K trap and repump AOM
% curtime = calctime(curtime,1000);
%         setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',180); %195
%         %SET trap AOM detuning to change probe
%         setAnalogChannel(calctime(curtime,0),'K Trap FM',42-20.5);%54.5
%         setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.8);%54.5
%         setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% curtime = calctime(curtime,1000);


%% Test K trap and repump AOM during D2 Grey Molasses

% % % % curtime = calctime(curtime,1000);
% % % %  
% % % %  K_molasses_repump_detuning_list = [0];
% % % %  
% % % %  K_molasses_repump_detuning = getScanParameter(K_molasses_repump_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_grey_molasses_repump_det');  %in MHZ
% % % %  
% % % %  K_molasses_trap_detuning_list = 0;
% % % %  K_molasses_trap_detuning = getScanParameter(K_molasses_trap_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_grey_molasses_trap_det');
% % % %   
% % % % % %Parameters
% % % %         %K_repump double pass AOM- Rigol Channel 1
% % % %         K_molasses_repump_freq = 81.31 + K_molasses_repump_detuning; %This is multiplied by 4 using two doublers %83.71 78.1
% % % %         K_molasses_repump_amp = 0.6; 
% % % %         K_molasses_repump_offset = 0;
% % % %         
% % % %         %K_repump shear mode AOM path
% % % %         setDigitalChannel(curtime,'gray molasses shear mod AOM TLL',1); %0: AOM off; 1: AOM on
% % % %         setDigitalChannel(calctime(curtime,-2),'K Repump 0th Shutter',0); % 0:Turn off zeroth order beam 1: Turn on zeroth order beam
% % % %         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);% turn on K repump shear mode -1th power for K D2 molasses
% % % %         
% % % %         %K_trap double pass AOM - Rigol Channel 2
% % % %         K_molasses_trap_freq = 117 + K_molasses_trap_detuning;
% % % %         K_molasses_trap_amp = 1.5;
% % % %         K_molasses_trap_offset = 0;
% % % %         
% % % %         %K_trap single pass AOM -SRS Generator
% % % %         addGPIBCommand(27,'FREQ 321.4 MHz; AMPR 10 dBm; MODL 0; DISP 2; ENBR 1;'); 
% % % %         
% % % %        %-------------------------set Rigol DG4162 ---------
% % % %         str111=sprintf(':SOUR1:APPL:SIN %gMHz,%f,%f;',K_molasses_repump_freq,K_molasses_repump_amp,K_molasses_repump_offset);
% % % %         str121=sprintf(':SOUR2:APPL:SIN %gMHz,%f,%f;',K_molasses_trap_freq,K_molasses_trap_amp,K_molasses_trap_offset);
% % % %         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');
% % % %         str2=[str111,str121,str131];
% % % %         addVISACommand(2, str2);
% % % %         
% % % %         
% % % %         setAnalogChannel(calctime(curtime,0),'Compensation Power',0);
% % % %         
% % % %         
% % % %         setDigitalChannel(curtime,'Gray Molasses switch',0)   %0: MOT Beam sources 1: D2 Molsses Beam sources
% % % %         setAnalogChannel(calctime(curtime,0),'K Trap AM',0.8);
% % % %         setAnalogChannel(calctime(curtime,0),'K Trap FM',18);
% % % % 
% % % % %         curtime = calctime(curtime,K_grey_molasses_time);
% % % % %         
% % % % %         setAnalogChannel(curtime,'Grey Molasses switch',0) % Switch back to MOT sources
% % % % %         setAnalogChannel(calctime(curtime,0),'K Repump 0th Shutter',5);
% % % % % %         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);
% % % % %         curtime = calctime(curtime,0.1);
% % % % %  end
% % % % %  
% % % % % %lag for trap shutter (1.7ms)
% % % % % % curtime = calctime(curtime,0.0);
% % % % curtime = calctime(curtime,1000);
%% 
% curtime = calctime(curtime,1000);
% setAnalogChannel(curtime,'test',1);
% K_gray_molasses_time = 3;
%  
%  if 1
%      %set shim coil values:
% %         gray_molasses_x_shim_list=[0.025];%0.25
% %         gray_molasses_x_shim= getScanParameter(gray_molasses_x_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_x_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'X Shim',gray_molasses_x_shim);
% %      
% %         gray_molasses_y_shim_list=[0.1];%0.25
% %         gray_molasses_y_shim= getScanParameter(gray_molasses_y_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_y_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'Y Shim',gray_molasses_y_shim);
% %         
% %         gray_molasses_z_shim_list=[-0.1];%0.25
% %         gray_molasses_z_shim= getScanParameter(gray_molasses_z_shim_list,seqdata.scancycle,seqdata.randcyclelist,'gray_molasses_z_shim');  %in MHZ
% %         setAnalogChannel(calctime(curtime,-1),'Z Shim',gray_molasses_z_shim);
%  
%         K_molasses_repump_detuning_list = [0]; 
%         K_molasses_repump_detuning = getScanParameter(K_molasses_repump_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_det');  %in MHZ
%   
%         K_molasses_trap_detuning_list = [0];
%         K_molasses_trap_detuning = getScanParameter(K_molasses_trap_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_det');
%   
% % %Parameters
%         %K_repump double pass AOM- Rigol Channel 1
%         K_molasses_repump_freq = 81.31 + K_molasses_repump_detuning; %This is multiplied by 4 using two doublers %83.71 78.1
%         K_molasses_repump_amp_list = [0.6]; 
%         K_molasses_repump_amp = getScanParameter(K_molasses_repump_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_repump_power');
%         K_molasses_repump_offset = 0;
%         
%         %K_repump shear mode AOM path
%         setDigitalChannel(curtime,'gray molasses shear mod AOM TLL',1); %0: AOM off; 1: AOM on
%         setDigitalChannel(calctime(curtime,-2),'K Repump 0th Shutter',0); % 0:Turn off zeroth order beam 1: Turn on zeroth order beam
%         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);% turn on K repump shear mode -1th power for K D2 molasses
%         
%         %K_trap double pass AOM - Rigol Channel 2
%         K_molasses_trap_freq = 117 + K_molasses_trap_detuning;
%         K_molasses_trap_amp =1.25; %1.25
%         K_molasses_trap_offset = 0;
%         
%         %K_trap single pass AOM -SRS Generator
%         K_molasses_trap_SRS_amp_list = [10]; %
%         K_molasses_trap_SRS_amp = getScanParameter(K_molasses_trap_SRS_amp_list,seqdata.scancycle,seqdata.randcyclelist,'K_gray_molasses_trap_SRS_power');
%         strSRS = sprintf('FREQ 321.4 MHz; AMPR %g dBm; MODL 0; DISP 2; ENBR 1;',K_molasses_trap_SRS_amp)
%         addGPIBCommand(27,strSRS); 
%         
%        %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %gMHz,%f,%f; :OUTPut1 ON;',K_molasses_repump_freq,K_molasses_repump_amp,K_molasses_repump_offset);
%         str121=sprintf(':SOUR2:APPL:SIN %gMHz,%f,%f; :OUTPut2 ON;',K_molasses_trap_freq,K_molasses_trap_amp,K_molasses_trap_offset);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');
%         str141=sprintf(':SYSTem:ROSCillator:SOURce EXTernal;');
%         str2=[str111,str121,str131,str141];
%         addVISACommand(2, str2);
%         
% %         setAnalogChannel(calctime(curtime,-0.1),'K Repump AM',)
%         setDigitalChannel(curtime,'Gray Molasses switch',1)  %0: MOT Beam sources 1: D2 Molsses Beam source        
% 
%         curtime = calctime(curtime,K_gray_molasses_time);        
%         
%         setDigitalChannel(curtime,'gray Molasses switch',0) % Switch back to MOT sources
% %         setDigitalChannel(calctime(curtime,0),'K Repump 0th Shutter',5);
% %         setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);
%         curtime = calctime(curtime,0.1);
%  end   
% curtime = calctime(curtime,1000); 
% setAnalogChannel(calctime(curtime,0),'F Pump',0);

%% test channel
%          curtime = calctime(curtime,1000);
%          setAnalogChannel(calctime(curtime,0),'Grey Molasses switch',0);%0: MOT; 5: Gray Molasses
%          setAnalogChannel(calctime(curtime,0),'K Trap FM',5.5); %765
%          setAnalogChannel(calctime(curtime,0),'K Repump FM',-30,2); %765
%          curtime = calctime(curtime,1000);

%% test shutter response
% curtime = calctime(curtime,1000);
% curtime = calctime(curtime,1000);
% on_time = 3; 
% setAnalogChannel(calctime(curtime,-1500),'K Repump 0th Shutter',5);
% setDigitalChannel(curtime,'K Repump Shutter',1);
% 
% % setDigitalChannel(curtime,'K Repump Shutter',1);
% 
% ScopeTriggerPulse(curtime,'shutter',on_time);
% 
% curtime = calctime(curtime,on_time);
% 
% % setAnalogChannel(curtime,'K Repump 0th Shutter',0);
% setDigitalChannel(curtime,'K Repump Shutter',0);
% % 
% % curtime = calctime(curtime,2000);
% % setAnalogChannel(curtime,'K Repump 0th Shutter',5);
% 
% curtime = calctime(curtime,1000);
% 
% %% Oprical Pumping after MOT Test
% curtime = calctime(curtime,1000);
% setAnalogChannel(curtime,'K Trap FM',-2,5); %0.3
% setAnalogChannel(curtime,'K Trap AM',0.5); %0.3
% setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
% curtime = calctime(curtime,1000);

% 
% setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);
% setDigitalChannel(curtime,'Gray Molasses switch',0);
% setDigitalChannel(curtime,'gray molasses shear mod AOM TLL',1);
% setDigitalChannel(calctime(curtime,-2),'K Repump 0th Shutter',0);
% 
% K_repump_power_for_OP = 0.37;
% setAnalogChannel(curtime,'K Repump AM',K_repump_power_for_OP); %0.3
% setAnalogChannel(curtime,'K Repump FM',0,2);
% 
% curtime = calctime(curtime,1000);
%% test visa address
%  freq_list = [44]; %was 120
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list =0;[0:160/mod_freq:2000/mod_freq];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = [1];%displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = 1.0*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp1');
%         offset_list = [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_dev_chn1*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;%modulate along x_lat direction,when mod_angle=30
% %         mod_dev_chn2 = mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;% %modulate along y_lat directio
%         mod_offset1 =mod_offset;
%         mod_offset2 =mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*16.95/13.942;%modulate along x_lat direction
% %         mod_offset2 =-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%modulate along y_lat direction
%         mod_phase1 = 0;
%         mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
% 
%         %Provides modulation.
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);

%% test DDS
% curtime = calctime(curtime,1000);
%         setDigitalChannel(calctime(curtime,0),17,0)
%         %Do RF Sweep
%        clear('sweep');
%        rf_list =  [31]; 31.3812; 
%        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,seqdata.randcyclelist,'rf_freq')
%        rf_power_list = [10];
%        sweep_pars.power = getScanParameter(rf_power_list,seqdata.scancycle,seqdata.randcyclelist,'rf_transfer_power');  -5.7; %-7.7
%        delta_freq = 0;
%        sweep_pars.delta_freq = delta_freq;  -0.2; % end_frequency - start_frequency   0.01
%        rf_pulse_length_list = [0.1];
%        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5        
% 
%        acync_time_start=curtime;
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),4,sweep_pars);%3: sweeps, 4: pulse
%     total_pulse_length = sweep_pars.pulse_length;
% 
%             do_ACync_plane_selection = 1;
%             if do_ACync_plane_selection
%                 ACync_start_time = calctime(acync_time_start,-80);
%                 ACync_end_time = calctime(curtime,total_pulse_length+40);
%                 setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
%                 setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
%             end
% 
% curtime = calctime(curtime,1000);

%% test rf pulse
% % %    do_RF_spectroscopy_test=1;
% % % if (do_RF_spectroscopy_test == 1)
% % %     curtime = calctime(curtime,500);
% % %     rf_power=10;
% % %     rf_freq =31.3812;
% % %     delta_freq = 0;    
% % %     start_freq=rf_freq-delta_freq/2;
% % %     end_freq=rf_freq+delta_freq/2;
% % %     pulse_length_list = [1];
% % %     pulse_length = getScanParameter(pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  
% % %     
% % %     
% % %     %do a pulse
% % %     pulse_start_time = curtime;
% % %     pulse_end_time = calctime(curtime,pulse_length);
% % %     
% % %     %trigger    
% % %     ScopeTriggerPulse(pulse_start_time,'rf_pulse_test');
% % %     
% % %     %Set RF power
% % %     setAnalogChannel(calctime(pulse_start_time,0),'RF Gain',rf_power,1);
% % %     %set RF freq
% % %     DDS_sweep(calctime(pulse_start_time,-10),1,start_freq,end_freq,1);% DDS_id = 1: use the rf evap DDS
% % %     %DDS trigger
% % %     setDigitalChannel(calctime(pulse_start_time,-10),'DDS ADWIN Trigger',1);
% % %     setDigitalChannel(pulse_start_time,'DDS ADWIN Trigger',0);
% % %     %turn on 'RF/uWave Transfer' switch to RF
% % %     setDigitalChannel(pulse_start_time,'RF/uWave Transfer',0);%0:rf; 1: uWave
% % %     %turn on RF TTL
% % %     setDigitalChannel(pulse_start_time,'RF TTL',1); % 0: power off, 1: power on
% % %     %turn off RF TTL
% % %     setDigitalChannel(pulse_end_time,'RF TTL',0); % 0: power off, 1: power on
% % %     %turn off 'RF/uWave Transfer' switch to RF
% % %     setDigitalChannel(pulse_start_time,'RF/uWave Transfer',1);%0:rf; 1: uWave
% % %     %set RF power to -10
% % %     setAnalogChannel(calctime(pulse_end_time,0.1),'RF Gain',rf_power,1);
% % %     %wait 1ms after turn off TTL
% % %     curtime = calctime(pulse_end_time,1);
% % %     
% % %     acync_time_start = calctime(pulse_start_time,0);
% % %     total_pulse_length = pulse_length;
% % %     
% % % end
% % %         curtime = calctime(curtime,500);
%% test kill beam

%             kill_probe_pwr = 0.1;
% %             kill_time_list = [0.01]; %10
% %             kill_time = getScanParameter(kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'kill_time');
%             kill_detuning = 42.7; %27 for 80G
%             
%             %Kill SP AOM 
%             mod_freq =  (120)*1E6;
%             mod_amp = 1;0.1;
%             mod_offset =0;
%             str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
%             addVISACommand(6, str);
%             % Set trap AOM detuning to change probe
%             setAnalogChannel(calctime(curtime,0),'K Trap FM',kill_detuning); %54.5
% 
%             % open K probe shutter
%             setDigitalChannel(calctime(curtime,10),'Downwards D2 Shutter',1); %0=closed, 1=open
%             
%             % Set TTL off initially
%             setDigitalChannel(calctime(curtime,20),'Kill TTL',1);%0= off, 1=on
%             
% %             kill_lat_ramp_time = 3;
% %             AnalogFuncTo(calctime(curtime,pulse_offset_time-kill_lat_ramp_time),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), kill_lat_ramp_time, kill_lat_ramp_time, 60/atomscale); %30?                                      
%             
%             %pulse beam with TTL
% %             DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',kill_time,1);


%% test PZT mirror displacement
% enable_modulation=1;
%    if enable_modulation
% 
%         freq_list = [50]; %was 120
%         mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'mod_freq');
%         time_list =10000;[0:160/mod_freq:2000/mod_freq];
%         mod_time = time_list(mod(seqdata.scancycle-1,length(time_list))+1);%getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_time');
%         addOutputParam('mod_time',mod_time);
%         amp_list = 0;[1.3]; %displacement of XDT beam; unit is um; chn1: 227.3um/MHz; chn2: 226.5um/MHz;
%         mod_amp = 1.0*getScanParameter(amp_list,seqdata.scancycle,seqdata.randcyclelist,'mod_amp1');
%         offset_list =2; [0];
%         mod_offset = getScanParameter(offset_list,seqdata.scancycle,seqdata.randcyclelist,'mod_offset');
%         mod_angle = 30;%unit is deg, fluo.image x-direction means 90 deg; fluo.image y-direction means 00 deg;
%         mod_dev_chn1 = mod_amp;
%         mod_dev_chn2 = mod_amp*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85;16.95/13.942;%modulate along x_lat direction,when mod_angle=30
% %         mod_dev_chn2 = mod_dev_chn1*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;% %modulate along y_lat directio
%         mod_offset1 =mod_offset;
%         mod_offset2 =0;mod_offset*sind(26.23+mod_angle)/sind(90-mod_angle-25.95)*0.85;16.95;16.95/13.942;%modulate along x_lat direction
% %         mod_offset2 =-mod_offset*cosd(26.23+mod_angle)/cosd(90-mod_angle-25.95)*16.95/13.942;%modulate along y_lat direction
%         mod_phase1 = 0;
%         mod_phase2 = 0;%0: modulate along x_lat direction, 180: modulate along y_lat direction
% 
%         %Provides modulation.
%         %-------------------------set Rigol DG4162 ---------
%         str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);
% 
%         %-------------------------end:set Rigol-------------        
%         %ramp the modulation amplitude
%         mod_ramp_time_list = [150];%150 sept28
%         mod_ramp_time = getScanParameter(mod_ramp_time_list,seqdata.scancycle,seqdata.randcyclelist,'mod_ramp_time'); %how fast to ramp up the modulation amplitude
% %         mod_ramp_time = mod_ramp_time/3*2;
%         final_mod_amp = 1;
%         addOutputParam('mod_amp',mod_amp*final_mod_amp);
%         setAnalogChannel(curtime,'Modulation Ramp',0);%0 means output is 0* input, 1 means output is 1*input;
%         curtime = calctime(curtime,10);
% ScopeTriggerPulse(curtime,'conductivity_modulation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',1);  %send trigger to Rigol for modulation
% 
% curtime=AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time, final_mod_amp); 
%         mod_wait_time =50;
% 
% curtime = calctime(curtime,mod_wait_time);
% 
% curtime = calctime(curtime,mod_time);
% 
% 
% 
%         setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
%         setAnalogChannel(curtime,'Modulation Ramp',0);
% %         setDigitalChannel(calctime(curtime,0),'XDT TTL',1); %1: turn off XDT
%         post_mod_wait_time_list =0;
%         post_mod_wait_time = post_mod_wait_time_list(mod(seqdata.scancycle-1,length(post_mod_wait_time_list))+1);
%         addOutputParam('post_mod_wait_time',post_mod_wait_time);
% curtime = calctime(curtime,post_mod_wait_time);

%     end   
    


%% Plug TA test (currently used as the compensation beam)
% % curtime = calctime(curtime,1000);
% % % % setDigitalChannel(calctime(curtime,0),'Plug Shutter',1);
% % % % setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0);
% % setDigitalChannel(calctime(curtime,0),'Plug Shutter',1)
% % % % % % setDigitalChannel(calctime(curtime,0),'Plug TTL',0);
% setAnalogChannel(curtime,60,0);
% % % % setDigitalChannel(curtime,'Compensation Shutter',0);
% % % % 
% setDigitalChannel(calctime(curtime,0),'Plug Shutter',1);
% % curtime = calctime(curtime,1000);


%% dipole trap test

% curtime = calctime(curtime,10);
% setDigitalChannel(calctime(curtime,0),'XDT TTL',0);
% % setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);%1 on direct
% setAnalogChannel(calctime(curtime,0),'dipoleTrap1',1);% dipole trap 1 power
% setAnalogChannel(calctime(curtime,0),'dipoleTrap2',1.0);% dipole trap 1 power
% % setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0); % dipole trap 2 power
% curtime = calctime(curtime,5000);
% setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);% dipole trap 1 power
% setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);% dipole trap 1 power
% 
% setDigitalChannel(calctime(curtime,0),'XDT TTL',1);%0 on


%% dipole 1 evap ramp test
%     P1 = 1.5;1.50;1;1.5;0.5;1.5;%Can currently be about 2.0W. ~1V/W on monitor. Feb 27, 2019.
%     P1e = 1.5;0.5;1.0; %0.5
%     xdt1_end_power = 0.25;
%     %Power    Load ODT1  Load ODT2  Begin Evap      Finish Evap
%     DT1_power = 1*[P1         P1        P1e          xdt1_end_power];
%     DT2_power = 1*[P1         P1        P1e          xdt1_end_power];
%  
%  
% %     channal = 'dipoleTrap1';
%     dipole_ramp_start_time = -250;%-3000; 
%     dipole_ramp_up_time = 250; %1500
% 
%     setDigitalChannel(calctime(curtime,dipole_ramp_start_time),'XDT Direct Control',0);
%     setDigitalChannel(calctime(curtime,dipole_ramp_start_time),'XDT TTL',1); %%%%%%%%%%%%%%%%%0
%     
%     %ramp dipole 1 trap on
%     AnalogFunc(calctime(curtime,dipole_ramp_start_time),'dipoleTrap1',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_ramp_up_time,dipole_ramp_up_time,0,DT1_power(1));
%     %ramp dipole 2 trap on
%     AnalogFunc(calctime(curtime,dipole_ramp_start_time),'dipoleTrap2',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dipole_ramp_up_time,dipole_ramp_up_time,0,DT2_power(1));
%     curtime = calctime(curtime,5000);
%     
%     
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',0);% dipole trap 1 power
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',0);% dipole trap 1 power
%     setDigitalChannel(calctime(curtime,10),'XDT TTL',1);%0 on
%     setDigitalChannel(calctime(curtime,10),'XDT Direct Control',1);

    
%% Test High Field Imaging
% % curtime = calctime(curtime,1000);
% setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
% setAnalogChannel(calctime(curtime,0),'no name',0);
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);
% 
% % 
% mod_freq =  120*1E6;    
% mod_amp = 1.5;
% mod_offset =0;
% str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
% str2=[str111];
% addVISACommand(3, str2);
% 
% curtime = calctime(curtime,1000);

%% Test optical pumping
% % setDigitalChannel(calctime(curtime,5),'D1 TTL', 1);
% % setDigitalChannel(calctime(curtime,100),'D1 OP TTL',1);
% % setAnalogChannel(calctime(curtime,100),'F Pump',1);
% % setDigitalChannel(calctime(curtime,100),'FPump Direct', 1);
% 
% curtime = calctime(curtime,100);
% optical_pump_time = 100;
% repump_power = 5.0;
% 
% setDigitalChannel(calctime(curtime,-10),'EIT Shutter',0);
% %Break the thermal stabilzation of AOMs by turning them off
% setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);
% setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
% setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
% setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);
% 
% %Open shutter
% setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1);%1: turn on laser; 0: turn off laser
% 
% ScopeTriggerPulse(curtime,'Beam on');
% scope_trigger = 'Beam on';
% 
% %Open optical pumping AOMS and regulate F-pump
% setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
% setAnalogChannel(calctime(curtime,0),'F Pump',2);
% setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
% setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
% 
% %Optical pumping time
% curtime = calctime(curtime,optical_pump_time);
% 
% %Turn off OP before F-pump so atoms repumped back to -9/2.
% setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);
% 
% %Close optical pumping AOMS
% setDigitalChannel(calctime(curtime,5),'F Pump TTL',1);%1
% setAnalogChannel(calctime(curtime,5),'F Pump',-1);%1
% setDigitalChannel(calctime(curtime,5),'FPump Direct',1);
% %Close shutter
% setDigitalChannel(calctime(curtime,5),'D1 Shutter', 0);%2
% 
% %After optical pumping, turn on all AOMs for thermal stabilzation
% 
% setDigitalChannel(calctime(curtime,10),'D1 TTL',1);
% setDigitalChannel(calctime(curtime,10),'F Pump TTL',0);
% setAnalogChannel(calctime(curtime,10),'F Pump',9.99);%1
% curtime =  setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);    
    
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),'K Repump TTL',0);
% setAnalogChannel(calctime(curtime,0),'no name',0);

%     setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',205);
%% align K probe AOM (K Probe/OP FM, analog channel 30)
% probe: set to 180;
% optical pumping: set to 202.5
% for the AOM alignment: set to 190; For the optical pumping fiber alignment, set to 202.5; for the probe fiber alignment, set to 180;
% curtime = calctime(curtime,1000);
% setAnalogChannel(calctime(curtime,0),'K Trap FM',21.5+2.5); %
% setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',180);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1);
% setDigitalChannel(calctime(curtime,2),'K Probe/OP Shutter',1);
% 
% curtime = calctime(curtime,1000);
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',1);
% setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',0);


% 
% 
% 
% 
% setDigitalChannel(calctime(curtime,0),85,1);
% setDigitalChannel(calctime(curtime,0),17,0);

% setDigitalChannel(calctime(curtime,0),81,0);
% setDigitalChannel(calctime(curtime,0),96,0);


%% Test DMD
% 
% setAnalogChannel(calctime(curtime,1),63,0);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
% setAnalogChannel(calctime(curtime,0),'DMD Power',0.0);
% setDigitalChannel(calctime(curtime,0),'DMD TTL',0);%1 off 0 on
% setDigitalChannel(calctime(curtime,0+100),'DMD TTL',1); %pulse time does not matter
% % setDigitalChannel(calctime(curtime,503.5),'DMD TTL',0);%1 off 0 on
% % setDigitalChannel(calctime(curtime,503.5+100),'DMD TTL',1); %pulse time does not matter

% AnalogFuncTo(calctime(curtime,1),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
% setAnalogChannel(calctime(curtime,700),'DMD Power',-5);
% setDigitalChannel(calctime(curtime,700),'DMD AOM TTL',0);%0 off 1 on
 
% setDigitalChannel(calctime(curtime,350),'DMD AOM TTL',0);
% DMD_on_time = 1000;
% DMD_ramp_time = 10;
% DMD_power_val_list = 3; 
% DMD_power_val = getScanParameter(DMD_power_val_list,seqdata.scancycle,seqdata.randcyclelist,'DMD_power_val');
% setDigitalChannel(calctime(curtime,-200),'DMD TTL',0);%1 off 0 on
% setDigitalChannel(calctime(curtime,-200+100),'DMD TTL',1); %pulse time does not matter
% setDigitalChannel(calctime(curtime,1),'DMD AOM TTL',0);
% setAnalogChannel(calctime(curtime,2),'DMD Power',-1);
%AnalogFuncTo(calctime(curtime,1),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_ramp_time, DMD_ramp_time, DMD_power_val);
%setAnalogChannel(calctime(curtime,1+DMD_on_time+DMD_ramp_time),'DMD Power',-1);
%setDigitalChannel(calctime(curtime,1+DMD_on_time+ DMD_ramp_time),'DMD AOM TTL',0);%0 off 1 on

% setAnalogChannel(curtime,'Modulation Ramp',-10)
% setDigitalChannel(calctime(curtime,0),'Lattice FM',0);

% curtime = calctime(curtime,100);
% 
% % Power is high, shutter is closed, PID is on
% setAnalogChannel(calctime(curtime,-100),'DMD Power',1.8);
% setDigitalChannel(calctime(curtime,-100),'DMD AOM TTL',1);
% 
% % "Slowly" ramp down the power before opening the shutter (1.8V to "0V")
% % THis woudl allow PID to settle to correcty output ahead of time
% 
% 
% 
% setDigitalChannel(calctime(curtime,-10),'DMD Shutter',0); % 0 shutter light on
% setDigitalChannel(calctime(curtime,-100),'DMD TTL',1);    % 
% setDigitalChannel(calctime(curtime,0),'DMD TTL',0);
%  
%  
% setDigitalChannel(calctime(curtime,-20),'DMD AOM TTL',0);
% setDigitalChannel(calctime(curtime,-20),71,1);
% % setAnalogChannel(calctime(curtime,-20),'DMD Power',0);
% AnalogFuncTo(calctime(curtime,-30),'DMD Power',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 1, 1, 0);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1); %ON
% setDigitalChannel(calctime(curtime,0),71,0);
% 
% dmd_pow_list=[0.5];
% DMD_power_val = getScanParameter(dmd_pow_list,seqdata.scancycle,...
%     seqdata.randcyclelist,'DMD_power_val');
% 
% curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 10, 10, DMD_power_val);
% % setDigitalChannel(calctime(curtime,-10),'DMD TTL.',1);     
% 
% curtime = calctime(curtime,500);
% % setDigitalChannel(calctime(curtime,0),'DMD TTL',0);     
% 
% curtime = AnalogFuncTo(calctime(curtime,0),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 10, 10, 0);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',0);
% % setDigitalChannel(calctime(curtime,10),71,1);
% setDigitalChannel(calctime(curtime,10),'DMD Shutter',1);
% setDigitalChannel(calctime(curtime,20),'DMD AOM TTL',1);
% 
% 
% 
% 
% setAnalogChannel(calctime(curtime,20),'DMD Power',1.8);
% setAnalogChannel(calctime(curtime,2000),'DMD Power',1.8);
% 
% setDigitalChannel(calctime(curtime,1000),71,1);

% 
% 
% curtime = calctime(curtime,1000);
% 
% 
% setDigitalChannel(calctime(curtime,-10),'DMD Shutter',1);
% setDigitalChannel(calctime(curtime,-20),'DMD AOM TTL',1);










%  
% mod_freq  = 60;
% mod_dev_chn1 = 0;
% mod_offset1 = 0.5;
% mod_phase1 = 0;
% 
% mod_dev_chn2 = 0;
% mod_offset2 = 0.5;
% mod_phase2 = 0;
% 
%  str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn1,mod_offset1);
%         str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',mod_phase1);
%         str121=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_dev_chn2,mod_offset2);
%         str122=sprintf(':SOUR2:BURS ON;:SOUR2:BURS:MODE GAT;:SOUR2:BURS:GATE:POL Normal;:SOUR2:BURS:PHAS %f;:OUTP2 ON;',mod_phase2);
%         str131=sprintf(':SOUR1:PHAS:INIT;:SOUR2:PHAS:SYNC;');%align ch1 and chn2 phase   :SOUR2:PHAS:SYNC;
%         str2=[str112,str111,str121,str122,str131];
%         addVISACommand(2, str2);

%% DMD +lattice timing

% DMD_On_Time = 50;
% DMD_Ramp_Time = 50;   
% DMD_Power = 3.5;
% First_image_on_time = 200;
% setDigitalChannel(calctime(curtime,First_image_on_time),'DMD TTL',0); %1 off 0 on %1000ms is set on DMD gui
% setDigitalChannel(calctime(curtime,First_image_on_time+20),'DMD TTL',1); %pulse time should be short for two triggers
% setDigitalChannel(calctime(curtime,1000),'DMD AOM TTL',1);
% AnalogFuncTo(calctime(curtime,1000),'DMD Power',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), DMD_Ramp_Time, DMD_Ramp_Time, DMD_Power);
% Then, ramp up lattice
% Exp_Depth_y = 2;
% Exp_Depth_xz = 10;
% Pin_Depth = 200;
% lat_rampup_depth = 1*[1*[0.0 0.0 Exp_Depth_xz Exp_Depth_xz Pin_Depth Pin_Depth] * 10.75/10.0 - 6.0;
%                       1*[0.0 0.0 Exp_Depth_y Exp_Depth_y Pin_Depth Pin_Depth] * 12.6/10.0;
%                       1*[0.0 0.0 Exp_Depth_xz Exp_Depth_xz Pin_Depth Pin_Depth] * 12.3/10.0]/atomscale;   
% DMD sine pulse will always happen 200ms + 150ms + 50ms = 400ms from the
% start. 
% Lat_Ramp_Time = 50;
% Second_image_on_time_list = 
% Second_image_on_time = getScanParameter(Second_image_on_time_list,seqdata.scancycle,seqdata.randcyclelist,'Second_image_on_time');
% Lat_Hold_Time_List = 50 + 5.7 + Second_image_on_time;%5.7 is due to some delay in DMD changing pattern, might need to clibrate more carefully
% Lat_Hold_Time = getScanParameter(Lat_Hold_Time_List,seqdata.scancycle,seqdata.randcyclelist,'lattice_hold_time');%maximum is 4
% Lat_Pin_Time = 0.1;
% Pin_Hold_Time = 50;%DMD shine time ends 50ms after lattice pin happened
% Total_Time = DMD_Ramp_Time + DMD_On_Time + Lat_Ramp_Time + Lat_Hold_Time + Lat_Pin_Time + Pin_Hold_Time;
% lat_rampup_time = 1*[DMD_Ramp_Time,DMD_On_Time,Lat_Ramp_Time,Lat_Hold_Time,Lat_Pin_Time,Pin_Hold_Time]; 
% Turn off DMD
% setAnalogChannel(calctime(curtime,Total_Time+1000),'DMD Power',-5);
% setDigitalChannel(calctime(curtime,Total_Time+1000),'DMD AOM TTL',1);%0 off 1 on
% 

% setAnalogChannel(calctime(curtime,20),'DMD Power',1.5);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);%0 off 1 on

%% Rb beat note FM test



% 
% reset= 1
% if reset ~=1
%     setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590 +32);
%     setAnalogChannel(calctime(curtime,0),'Rb Beat Note FF',0.57,1);
%     setDigitalChannel(calctime(curtime,5),50,1);
% %     setAnalogChannel(calctime(curtime,6),'Rb Beat Note FF',0.57,1);0.55;-0.1;
%     setAnalogChannel(calctime(curtime,5.5),'Rb Beat Note FM',6590 -240);
%     setDigitalChannel(calctime(curtime,6),50,0);
%     setAnalogChannel(calctime(curtime,10),'Rb Beat Note FF',0,1);
% else
% %     setAnalogChannel(calctime(curtime,0),'Rb Beat Note FF',0,1);
% %     setAnalogChannel(calctime(curtime,5),'Rb Beat Note FM',6590 +32);
% %     setDigitalChannel(calctime(curtime,1),50,0);
%     setAnalogChannel(calctime(curtime,0),'Rb Beat Note FF',0,1);
%     setDigitalChannel(calctime(curtime,5),50,1);
%     setAnalogChannel(calctime(curtime,6),'Rb Beat Note FF',0,1);0.55;
%     setAnalogChannel(calctime(curtime,10),'Rb Beat Note FM',6590 +32);
%     setDigitalChannel(calctime(curtime,15),50,0);
%     setAnalogChannel(calctime(curtime,20),'Rb Beat Note FF',0,1);
% end



%     setAnalogChannel(calctime(curtime,1),'Rb Beat Note FM',6590 +32);
% ramptime=1000;
% AnalogFuncTo(calctime(curtime,0),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramptime,ramptime, 6590-238);
% AnalogFuncTo(calctime(curtime,ramptime+50),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramptime,ramptime, 6590+32);

%% End

%Test third digital card
% curtime = calctime(curtime,1000);
% setAnalogChannel(calctime(curtime,0),26,0);
% curtime = calctime(curtime,5000);
% setDigitalChannel(calctime(curtime,0),68,1);
% setDigitalChannel(calctime(curtime,0),76,1);
% setDigitalChannel(calctime(curtime,0),84,1);
% setDigitalChannel(calctime(curtime,0),92,1);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),68,0);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),76,0);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),84,0);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),92,0);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),92,1);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),84,1);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),76,1);
% curtime = calctime(curtime,0.005);
% setDigitalChannel(calctime(curtime,0),68,1);
% setDigitalChannel(calctime(curtime,0),65,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,1);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),68,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),67,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),66,0);
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,0);

% setDigitalChannel(calctime(curtime,0),69,0);
% setDigitalChannel(calctime(curtime,0),70,0);
% setDigitalChannel(calctime(curtime,0),71,0);
% setDigitalChannel(calctime(curtime,0),72,0);
% setDigitalChannel(calctime(curtime,0),73,0);
% setDigitalChannel(calctime(curtime,0),74,0);
% setDigitalChannel(calctime(curtime,0),75,0);
% setDigitalChannel(calctime(curtime,0),76,0);
% setDigitalChannel(calctime(curtime,0),77,0);
% setDigitalChannel(calctime(curtime,0),78,0);
% setDigitalChannel(calctime(curtime,0),79,0);
% setDigitalChannel(calctime(curtime,0),80,0);
% setDigitalChannel(calctime(curtime,0),81,0);
% setDigitalChannel(calctime(curtime,0),82,0);
% setDigitalChannel(calctime(curtime,0),83,0);
% setDigitalChannel(calctime(curtime,0),84,0);
% setDigitalChannel(calctime(curtime,0),85,0);
% setDigitalChannel(calctime(curtime,0),86,0);
% setDigitalChannel(calctime(curtime,0),87,0);
% setDigitalChannel(calctime(curtime,0),88,0);
% setDigitalChannel(calctime(curtime,0),89,0);
% setDigitalChannel(calctime(curtime,0),90,0);
% setDigitalChannel(calctime(curtime,0),91,0);
% setDigitalChannel(calctime(curtime,0),92,0);
% setDigitalChannel(calctime(curtime,0),93,0);
% setDigitalChannel(calctime(curtime,0),94,0);
% setDigitalChannel(calctime(curtime,0),95,0);
% setDigitalChannel(calctime(curtime,0),96,0);

% curtime = calctime(curtime,1000);
% setDigitalChannel(calctime(curtime,0),32,0);% 0:OFF; 1: ON
% curtime = calctime(curtime,1000);

%   rotation_time = 1000;   % The time to rotate the waveplate
%       P_lattice = 0.4; %0.5/0.9        % The fraction of power that will be transmitted 
%       curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
%       curtime = calctime(curtime,1000);
      
      
% curtime = calctime(curtime,1000);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP shutter',1);
% setAnalogChannel(calctime(curtime,0),'no name',1); 
% curtime = calctime(curtime,1000);
% 
% SelectScopeTrigger(scope_trigger);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0);
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',5,1);

    % %Set the frequency of the first DP AOM 
% D1_FM_List = [222.5];
% D1_FM = getScanParameter(D1_FM_List, seqdata.scancycle, seqdata.randcyclelist);%5
% setAnalogChannel(calctime(curtime,0),'D1 FM',3.80,1);
% addOutputParam('D1_DP_FM',D1_FM);

% curtime = calctime(curtime,1000);
% setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',0);
% 
% setDigitalChannel(calctime(curtime,0),65,1);
% curtime = calctime(curtime,4);
% setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
% 
% 
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,0),65,0);
% setDigitalChannel(calctime(curtime,1),'K D1 GM Shutter',1);
% curtime = calctime(curtime,1000);


% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1);
% setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',190);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% 
% setAnalogChannel(calctime(curtime,0),47,10,1);
% setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
% setDigitalChannel(calctime(curtime,0),'D1 TTL',1);

% %SRS test
%  SRSAddress = 27;
%  rf_on = 1;
%  SRSfreq = 1285.8;
%  SRSpower = 8;   %%8
% addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));
% setAnalogChannel(calctime(curtime,0),64,0);
% 
% %% Rigol Test
%     D1_freq = 0;
%     mod_freq =  (80+D1_freq)*1E6;
%     mod_amp = 1.290;
%     mod_offset =0;
%     str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
%     addVISACommand(3, str);
% setAnalogChannel(calctime(curtime,0),64,0);
% setDigitalChannel(calctime(curtime,0),1,1);
% setAnalogChannel(calctime(curtime,0),64,0);



%     %SRS 2 photon detuning
%  SRSAddress = 27;
%  rf_on = 1;
%  SRSfreq = 1285.8;
%  SRSpower = 8;   %%8
%  addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));
% 
%  % Rigol common mode detuning
%     D1_freq = 0;-10;
%     mod_freq = (80+D1_freq)*1E6;
%     mod_amp = 1.3;0.9; %power 1.290
%     mod_offset =0;
%     str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
%     addVISACommand(3, str);
% 
%  

%% Pre-initiliaze


% CF : Shall we have some kind of reset in the beginning of the sequence?

% Turn off GM Shutter
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

% MOT Load

doMOT  =0;
if doMOT
% This code initializses the MOT. This includes
% Rb+K detunings and power
% Field Gradients, Shims, and other coils
    
rb_MOT_detuning= 32; % Rb trap MOT detuning in MHz
k_MOT_detuning = 22; % K trap MOT detuning in MHz   
MOT_time = 10000;           % MOT load time in ms



curtime = calctime(curtime,100);

% Turn the UV on
setDigitalChannel(calctime(curtime,-0),'UV LED',1); % THe X axis bulb 1 on 0 off
setAnalogChannel(calctime(curtime,-0),'UV Lamp 2',3); % The y axis bubls 3V on , 0off
%%%%%%%%%%%%%%%% Set Rb MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',...          
    6590+rb_MOT_detuning);      
setAnalogChannel(calctime(curtime,0),'Rb Trap AM', 0.7);            % Rb MOT Trap power   (voltage)
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);             % Rb MOT trap TTL     (0 : ON)
setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',0);        % Rb MOT trap shutter (1 : ON)

% Repump
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0.9);           % Rb MOT repump power (voltage)
setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0);       % Rb MOT repumper shutter (1 : ON)

%%%%%%%%%%%%%%%% Set K MOT Beams %%%%%%%%%%%%%%%%
% Trap
setAnalogChannel(calctime(curtime,10),'K Trap FM',k_MOT_detuning);  % K Trap Detuning
setAnalogChannel(calctime(curtime,0),'K Trap AM',0.8);              % K MOT trap power
setDigitalChannel(calctime(curtime,0),'K Trap TTL',0);              % K MOT trap TTL
setDigitalChannel(calctime(curtime,0),'K Trap Shutter',1);          % K mot trap shutter

% Repump
setAnalogChannel(calctime(curtime,10),'K Repump FM',0,2); %765      % K Repump Detuning
setAnalogChannel(calctime(curtime,0),'K Repump AM',0.45);           % K MOT repump power
setDigitalChannel(calctime(curtime,0),'K Repump TTL',0);            % K MOT repump TTL
setDigitalChannel(calctime(curtime,0),'K Repump Shutter',1);        % K MOT repump shutter

%%%%%%%%%%%%%%%% MOT Field Gradient %%%%%%%%%%%%%%%%
% Set MOT gradient
MOTBGrad = 10; %10
setAnalogChannel(calctime(curtime,0),'MOT Coil',MOTBGrad); 
addOutputParam('MOTBGrad',MOTBGrad);

%TTL (is this a TTL to the MOT currents?)
curtime = setDigitalChannel(calctime(curtime,0),'MOT TTL',0);

%Feed Forward (why is this here? CF)
setAnalogChannel(calctime(curtime,0),18,10); 


%%%%%%%%%%%%%%%% MOT Chamber shims %%%%%%%%%%%%%%%%

% Turn on shim supply relay, this diverts shim currens to MOT chamber
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

% The MOT shims in AMPS
% shims=0:0.1:.5;
% shim=getScanParameter(shims,seqdata.scancycle,seqdata.randcyclelist,'MOT_yshim');
curtime = setAnalogChannel(calctime(curtime,0),'X Shim',0.2 ,2);  0.2;
curtime = setAnalogChannel(calctime(curtime,0),'Y Shim', 2.0  ,2); 2;
curtime = setAnalogChannel(calctime(curtime,0),'Z Shim',0.9 ,2);  0.9;

%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime = calctime(curtime,MOT_time);
addOutputParam('MOT_time',MOT_time);

% Turn UV off
setDigitalChannel(calctime(curtime,-0),'UV LED',0); % THe X axis bulb 1 on 0 off
setAnalogChannel(calctime(curtime,-0),'UV Lamp 2',0); % The y axis bubls 3V on , 0off

%% Test D1 locking
% This piece of code is useful to check if the D1 laser has gone out of
% lock by checking to see if the D1 light can be used as a repumper for the
% MOT

doKD1MOT = 0;
if doKD1MOT
    setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',0);        % Rb MOT trap shutter (1 : ON)
setDigitalChannel(calctime(curtime,0),'Rb Repump Shutter',0);       % Rb MOT repumper shutter (1 : ON)

     
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1);        % (1 : OFF)
    setDigitalChannel(calctime(curtime,-3),'K D1 GM Shutter',1);    % (1 : ON);
end    
    

end



    
%% cMOT V2. try to get best CMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
doCMOTv2 =0;        
if doCMOTv2
if ~doMOT
   error('You cannot load a CMOT without a MOT');       
end
            
% Time duration
rb_cMOT_time = 25;              % Ramp time of Rb CMOT
k_cMOT_time = 25;               % Ramp time of K CMOT
cMOT_time = 50;                 % Total CMOT time

% Rubidum
rb_cMOT_detuning = 42;          % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;  % Rubidum CMOT repump power in V

% Potassium
k_cMOT_detuning = 5; 5;         % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz

% k_cMOT_detunings=[0:2:20];
% k_cMOT_detuning= getScanParameter(k_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_detuning');  %in MHZ

% k_cMOT_times=[5:5:50];
% k_cMOT_time= getScanParameter(k_cMOT_times,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_time');  %in MHZ


% Append output parameters if desired   
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
addOutputParam('rb_cMOT_detuning',rb_cMOT_detuning);
addOutputParam('rb_cmot_repump_power',rb_cmot_repump_power); 

yshim_comp = 0.84;
xshim_comp = 0.25;
zshim_comp = 0.00;

%%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
% setAnalogChannel(calctime(curtime,-2),'Y Shim',0.84,2); 
% setAnalogChannel(calctime(curtime,-2),'X Shim',0.25,2); 
% setAnalogChannel(calctime(curtime,-2),'Z Shim',0.00,2);

%%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%
AnalogFuncTo(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rb_cMOT_time,rb_cMOT_time,6590+rb_cMOT_detuning);
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',rb_cmot_repump_power);
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Trap AM',0.1);

%%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
% setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
AnalogFuncTo(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_detuning);
% setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
AnalogFuncTo(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_repump_detuning,2);
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.25); %0.25
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.7); %0.7 %0.3 Oct 30, 2015 

%%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
CMOTBGrad=10;
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'MOT Coil',CMOTBGrad);

%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime=calctime(curtime,cMOT_time);   
end
%% cMOT V3. try to get best CMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
doCMOTv3 =0;        
if doCMOTv3
if ~doMOT
   error('You cannot load a CMOT without a MOT');       
end
            
% Time duration
rb_cMOT_time = 25;              % Ramp time of Rb CMOT
k_cMOT_time = 25;               % Ramp time of K CMOT

% Rubidum
rb_cMOT_detuning = 42;          % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;  % Rubidum CMOT repump power in V

% rb_cMOT_detunings=0:5:50;
% rb_cMOT_detuning=getScanParameter(rb_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_detuning');

% rb_cmot_repump_powers=0:.1:.9;
% rb_cmot_repump_power= getScanParameter(rb_cmot_repump_powers,seqdata.scancycle,seqdata.randcyclelist,'rb_cmot_repump_am');  %in MHZ
%  


% Potassium
k_cMOT_detuning = 5; 5;         % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz


k_cMOT_detunings=[4];
k_cMOT_detuning= getScanParameter(k_cMOT_detunings,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_detuning');  %in MHZ

k_cMOT_times=[20];
k_cMOT_time= getScanParameter(k_cMOT_times,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_time');  
rb_cMOT_time=k_cMOT_time;

cMOT_time = max([rb_cMOT_time k_cMOT_time]); [50];% Total CMOT time

% Append output parameters if desired   
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
addOutputParam('rb_cMOT_detuning',rb_cMOT_detuning);
addOutputParam('rb_cmot_repump_power',rb_cmot_repump_power); 

yshim_comp = 0.84;
xshim_comp = 0.25;
zshim_comp = 0.00;

%%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
% setAnalogChannel(calctime(curtime,-2),'Y Shim',0.84,2); 
% setAnalogChannel(calctime(curtime,-2),'X Shim',0.25,2); 
% setAnalogChannel(calctime(curtime,-2),'Z Shim',0.00,2);

%%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
% AnalogFuncTo(calctime(curtime,0),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rb_cMOT_time,rb_cMOT_time,6590+rb_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'Rb Repump AM',rb_cmot_repump_power);
setAnalogChannel(calctime(curtime,0),'Rb Trap AM',0.1);

%%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,0),'K Trap FM',k_cMOT_detuning); %765
% AnalogFuncTo(calctime(curtime,0),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_detuning);
setAnalogChannel(calctime(curtime,0),'K Repump FM',k_cMOT_repump_detuning,2); %765
% AnalogFuncTo(calctime(curtime,0),'K Repump FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),k_cMOT_time,k_cMOT_time,k_cMOT_repump_detuning,2);

K_trap_am_list = [0.5];0.7;
k_cMOT_trap_am = getScanParameter(K_trap_am_list,seqdata.scancycle,seqdata.randcyclelist,'k_cMOT_trap_am');  %in MHZ
setAnalogChannel(calctime(curtime,0),'K Repump AM',0.25); %0.25
setAnalogChannel(calctime(curtime,0),'K Trap AM',k_cMOT_trap_am); %0.7 %0.3 Oct 30, 2015 

%%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
% CMOTBGrad=10;
% setAnalogChannel(calctime(curtime,0),'MOT Coil',CMOTBGrad);

% CMOTBGrads=20;
% CMOTBGrad= getScanParameter(CMOTBGrads,seqdata.scancycle,seqdata.randcyclelist,'CMOTBGrad');  %G/cm
% AnalogFuncTo(calctime(curtime,0),'MOT Coil',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),cMOT_time,cMOT_time,CMOTBGrad);


%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime=calctime(curtime,cMOT_time);   
end


%% cMOT
% This code loads the CMOT from the MOT. This includes ramps of the 
% detunings, power, shims, and field gradients. In order to function 
% properly it needs to havethe correct parameters from the MOT.
doCMOT =0;        
if doCMOT
    
if ~doMOT
   error('You cannot load a CMOT without a MOT');       
end
            
% Time duration
rb_cMOT_time = 25;          % Duration of the Rb CMOT
k_cMOT_time = 25;           % Duration of the K CMOT
cMOT_time = 50; 

% Rubidum power
rb_cMOT_detuning = 42;      % Rubdium trap CMOT detuning in MHz
rb_cmot_repump_power = 0.0275;



    



% Potassium power
k_cMOT_detuning = 5; 5;           % K CMOT trap detuning in MHz
k_cMOT_repump_detuning = 0;     % K CMOT repump detuning in MHz

% Append output parameters if desired   
addOutputParam('k_cMOT_detuning',k_cMOT_detuning);
addOutputParam('k_cMOT_repump_detuning',k_cMOT_repump_detuning); 
addOutputParam('rb_cMOT_detuning',rb_cMOT_detuning);
addOutputParam('rb_cmot_repump_power',rb_cmot_repump_power); 

yshim_comp = 0.84;
xshim_comp = 0.25;
zshim_comp = 0.00;

%%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%
% setAnalogChannel(calctime(curtime,-2),'Y Shim',0.84,2); 
% setAnalogChannel(calctime(curtime,-2),'X Shim',0.25,2); 
% setAnalogChannel(calctime(curtime,-2),'Z Shim',0.00,2);

%%%%%%%%%%%%%%%% Set CMOT Rb Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Beat Note FM',6590+rb_cMOT_detuning); 
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Repump AM',rb_cmot_repump_power);
setAnalogChannel(calctime(curtime,cMOT_time - rb_cMOT_time),'Rb Trap AM',0.1);

%%%%%%%%%%%%%%%% Set CMOT K Beams %%%%%%%%%%%%%%%%
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap FM',k_cMOT_detuning); %765
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump FM',k_cMOT_repump_detuning,2); %765
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Repump AM',0.25); %0.25
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'K Trap AM',0.7); %0.7 %0.3 Oct 30, 2015 

%%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
CMOTBGrad=10;
setAnalogChannel(calctime(curtime,cMOT_time - k_cMOT_time),'MOT Coil',CMOTBGrad);

%%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
curtime=calctime(curtime,cMOT_time);   
end
%% Combined Molasses - K D1 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time from the CMOT phase
doMol = 0;
if doMol

%%%%%%%%%%%% Shift the fields %%%%%%%%%%%%
% Set field gradient and shim values (ideally) to zero

% Turn off field gradients
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);   

% Set the shims
setAnalogChannel(calctime(curtime,0),'X Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Y Shim',0.15,2); %0.15
setAnalogChannel(calctime(curtime,0),'Z Shim',0.00,2); %0.00

% Wait for fields to turn off (testing)
curtime=calctime(curtime,0);  

%%%%%%%%%%%% Turn off K D2  %%%%%%%%%%%%
% Turn off the K D2 light
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);   % (1: OFF)
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); % (1: OFF)



%%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%

% Rb Mol detuning setting
rb_molasses_detuning_list = 110;
rb_molasses_detuning = getScanParameter(rb_molasses_detuning_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Rb_molasses_det');  

% Rb Mol trap power setting
rb_mol_trap_power_list = 0.15;
rb_mol_trap_power = getScanParameter(rb_mol_trap_power_list,seqdata.scancycle,seqdata.randcyclelist,'rb_mol_trap_power');
% Rb Mol repump power settings
rb_mol_repump_power_list = 0.08;[0.01:0.01:0.15];
rb_mol_repump_power = getScanParameter(rb_mol_repump_power_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_mol_repump_power');
   
% Set the power and detunings
setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',6590+rb_molasses_detuning);
setAnalogChannel(curtime,'Rb Trap AM',rb_mol_trap_power); %0.7
setAnalogChannel(curtime,'Rb Repump AM',rb_mol_repump_power); %0.14 

%%%%%%%%%%%% K D1 GM Settings %%%%%%%%%%%%
% K D1 GM two photon detuning
SRS_det_list = [-1.5:0.1:0.5];%0
SRS_det = getScanParameter(SRS_det_list,seqdata.scancycle,seqdata.randcyclelist,'GM_SRS_det');

% K D1 GM two photon sideband power
SRSpower_list = [4];   %%8
SRSpower = getScanParameter(SRSpower_list,seqdata.scancycle,seqdata.randcyclelist,'SRSpower');

% Set the two-photon detuning (SRS)
SRSAddress = 27; rf_on = 1; SRSfreq = 1285.8+SRS_det;%1285.8
addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',SRSfreq,SRSpower,rf_on));

% K D1 GM double pass (single photon detuning) - shift from 70 MHz
D1_freq_list = [0];
D1_freq = getScanParameter(D1_freq_list,seqdata.scancycle,seqdata.randcyclelist,'D1_freq');

% K D1 GM Double pass - modulation depth
mod_amp_list = [1.3];
mod_amp = getScanParameter(mod_amp_list,seqdata.scancycle,seqdata.randcyclelist,'GM_power');

% Set the single photon detuning (Rigol)
mod_freq = (70+D1_freq)*1E6;
mod_offset =0;
str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
addVISACommand(3, str);

% Open the D1 shutter (3 ms pre-trigger for delay)
setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter',1);

%%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
% Total Molasses Time
molasses_time_list = [8];
molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,seqdata.randcyclelist,'molasses_time'); 

%%%%%%%%%%%% advance time during molasses  %%%%%%%%%%%%
curtime = calctime(curtime,molasses_time);

% Close the D1 Shutter (3 ms pre-trigger for delay); 
setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter 2',0); % we have a double shutter on this beam
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);     % close this shutter too

end

%% Optical Pumping
% setDigitalChannel(calctime(curtime,0),'ScopeTrigger',1);
% setDigitalChannel(calctime(curtime,1),'ScopeTrigger',0); 

doOP =0;
if doOP
% This stage using the Rb/K Pump (trap light) beam along the Y-axis to pump
% atoms into the |2,2> and |9/2,9/2> state

    % Turn off the trap beams before OP (keep repump on)    
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);    
    setDigitalChannel(calctime(curtime,-1.8),'Rb Trap Shutter',0); 
    setDigitalChannel(calctime(curtime,-1.8),'K Trap Shutter',0); 
    
    % Advance time a bit
    curtime = calctime(curtime,0.1);

    %some flags used in the script for optical pumping
    seqdata.flags.Rb_Probe_Order = 1;
%     seqdata.flags.K_D2_gray_molasses = 0;
    seqdata.flags.image_loc = 1;

    % Perform optical pumping
    curtime = optical_pumping(calctime(curtime,0.0));
    

end



%% Load into Magnetic Trap
loadMT = 0;

if loadMT 
    % Turn off Rb MOT Trap
    setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',0); 
    setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',0); 
    
    % Turn off Rb MOT Repump
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);     
    
    % Turn off Rb Probe
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'Rb Probe/OP Shutter',0); 

    % Turn of K MOT Trap
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'K Trap Shutter',0); 
    
    % Turn off K MOT Repump
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
    setDigitalChannel(calctime(curtime,-2),'K Repump Shutter',0); 

    % Turn off K Probe
    setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',0); % (0 is off for this beam)
    setDigitalChannel(calctime(curtime,-2),'K Probe/OP Shutter',0); 

    % Turn on the magtrap
    curtime = Load_MagTrap_from_MOT(curtime);    
    
%     curtime = calctime(curtime,100);    

    % Set the shims away from pumping values back to "zero" field
    setAnalogChannel(calctime(curtime,0),'X Shim',0.15,2); % 0.15
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.15,2); % 0.15
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.00,2); % 0.0    
    
    
    % Hold in magnetic trap if desired
    MTholds = [10];
    MThold =getScanParameter(MTholds,seqdata.scancycle,seqdata.randcyclelist,'MThold'); 
    curtime = calctime(curtime,MThold);    

end

%% Time of flight
% This section of code performs a time flight before doing fluorescence
% imaging with the MOT beams.
doTOF =0;

if ~doTOF && loadMT
   error('MT load is not followed by TOF. Coils will get too hot');       
end

if doTOF      

%%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%    
% Turn off the field gradient
setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1); 

% levitateGradient=[60:2:90];
% levitateGradient= getScanParameter(levitateGradient,seqdata.scancycle,seqdata.randcyclelist,'levitateGradient');  %in MHZ
% setAnalogChannel(calctime(curtime,0),'MOT Coil',levitateGradient,3); 

% Turn off the D2 beams, if they arent off already
setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

%%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%

% Set the time of flight
tof_list = [10];
tof =getScanParameter(tof_list,seqdata.scancycle,seqdata.randcyclelist,'tof_time'); 

% Increment the time (ie. perform the time of flight)
curtime = calctime(curtime,tof);

% Turn coil off in case levitation was on
% setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1); 

%%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
%turn back on D2 for imaging (or make it on resonance)  

% Set potassium detunings to resonances (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',0);
setAnalogChannel(calctime(curtime,-0.5),'K Repump FM',0,2);

% Set potassium power to standard value
setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

% Set Rubidium detunings to resonance (0.5 ms prior to allow for switching)
setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

% Set rubdium power to standard value
setAnalogChannel(calctime(curtime,-1),'Rb Trap AM', 0.7);            
setAnalogChannel(calctime(curtime,-1),'Rb Repump AM',0.9);          

% Imaging beams for K
setDigitalChannel(calctime(curtime,-5),'K Repump Shutter',1); 
setDigitalChannel(calctime(curtime,-5),'K Trap Shutter',1); 
setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 

% % Imaging beams for Rb
% setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);      
% setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1); 
% setDigitalChannel(calctime(curtime,-5),'Rb Trap Shutter',1); 

% Camera Trigger (1) : Light+Atoms
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);

% Turn off the field gradient
% setAnalogChannel(calctime(curtime,20),'MOT Coil',0,1); 

% Wait for second image trigger
curtime = calctime(curtime,3000);

% Camera Trigger (2) : Light only
setDigitalChannel(calctime(curtime,0),15,1);
setDigitalChannel(calctime(curtime,10),15,0);
 
% switich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

end


%% Optical pumping test
% curtime = calctime(curtime,1000);
% setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP Shutter',1);    
% setAnalogChannel(calctime(curtime,-5),'Rb Probe/OP AM',1); %0.11
% setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',0); % inverted logic
% % AnalogFuncTo(curtime,'Rb Beat Note FM',...
% %       @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
% %       50,50, 6590-20);
% setAnalogChannel(calctime(curtime,0.0),'Rb Beat Note FM',6590 - 20);
% % % % 
% % % 
% % setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1); 
% % setDigitalChannel(calctime(curtime,-2),'Rb Trap Shutter',1); 
% % 
% % % % % % % 
% % % % % % setAnalogChannel(calctime(curtime,0),'Y Shim',2); %0.15
% % % % % % setAnalogChannel(calctime(curtime,0),'X Shim',1); %0.15
% % % % % % setAnalogChannel(calctime(curtime,0),'Z Shim',3);%0.0 
% % % % % % 
% % curtime = calctime(curtime,1000);
% setAnalogChannel(calctime(curtime,-0.5),'K Probe/OP FM',190);%202.5); %200
% setAnalogChannel(calctime(curtime,-0.5),'K Trap FM',27.5); 
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1); % 0 is off
% setDigitalChannel(calctime(curtime,2),'K Probe/OP Shutter',1);
% % % % % % 
% % % 
% setAnalogChannel(calctime(curtime,0),59,0); %0.11

%% ODT test
% curtime = calctime(curtime,100);
% setDigitalChannel(calctime(curtime,-10),'XDT Direct Control',0);
% setDigitalChannel(calctime(curtime,-10),'XDT TTL',0);
% setAnalogChannel(calctime(curtime,0),'ZeroVolts',0); 
% % % % % % Choose the power limits
% ODT1powerLOW=-0.04;
% ODT1powerHIGH = 0.5;
% % % % 
% ODT2powerLOW=-0.04;
% ODT2powerHIGH = 0.5;
% % % % 
% % % % % % setAnalogChannel(curtime,'dipoleTrap1',-0.025); 
% AnalogFunc(calctime(curtime,0),'dipoleTrap1',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),100,100,ODT1powerLOW,ODT1powerHIGH);
%     
% AnalogFunc(calctime(curtime,0),'dipoleTrap2',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),100,100,ODT2powerLOW,ODT2powerHIGH);
% % % % 
% curtime = calctime(curtime,10000);
% 
% % setAnalogChannel(curtime,'dipoleTrap1',ODT1powerLOW); 
% % setAnalogChannel(curtime,'dipoleTrap2',ODT2powerLOW);
% % setDigitalChannel(calctime(curtime,10),'XDT TTL',1);
% % setDigitalChannel(calctime(curtime,.5),'XDT Direct Control',1);
% 
% AnalogFunc(calctime(curtime,0),'dipoleTrap1',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),100,100,ODT1powerHIGH,ODT1powerLOW);
%     
% AnalogFunc(calctime(curtime,0),'dipoleTrap2',...
%     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),100,100,ODT2powerHIGH,ODT2powerLOW);
% 
% % setAnalogChannel(curtime,54,0);
% 
% curtime = calctime(curtime,500);
% setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
% setAnalogChannel(curtime,'dipoleTrap1',-10,1); 
% setAnalogChannel(curtime,'dipoleTrap2',-10,1); 

 
% setAnalogChannel(curtime,57,0);

%% %%

%% FB test
% setDigitalChannel(calctime(curtime,0),'fast FB Switch',1);
% setAnalogChannel(calctime(curtime,0),'FB current',0,2);
% 
% setAnalogChannel(calctime(curtime,0),'FB current',10,2);
%  curtime = calctime(curtime,500);
% setAnalogChannel(calctime(curtime,0),'FB current',-0.5,2);
% setDigitalChannel(calctime(curtime,0),'fast FB Switch',0);
% 
% 
% % % % curtime = calctime(curtime,500);
% % % % fesh_current = 20;
% % % % ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt); 
% % % % 
% % % % setDigitalChannel(calctime(curtime,-100),'fast FB Switch',1); %switch Feshbach field on
% % % % setAnalogChannel(calctime(curtime,-95),'FB current',0.0); %switch Feshbach field closer to on
% % % % setDigitalChannel(calctime(curtime,-100),'FB Integrator OFF',0); %switch Feshbach integrator on            
% % % % % %         linear ramp from zero
% % % % AnalogFunc(calctime(curtime,0),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),250,250, fesh_current,0);
% % % % 
% % % % curtime = calctime(curtime,1000);
% % % % 
% % % % AnalogFunc(calctime(curtime,0),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),250,250, 0,fesh_current);
% % % % % 
% setAnalogChannel(calctime(curtime,0),54,5);
% setDigitalChannel(calctime(curtime,0),64,0);

% %%Shim test
%     %Turn shim multiplexer to Science shims
%     setDigitalChannel(calctime(curtime,-5),37,1); 
%     %Close Science Cell Shim Relay for Plugged QP Evaporation
%     setDigitalChannel(calctime(curtime,-5),'Bipolar Shim Relay',1);
%  
%     setDigitalChannel(calctime(curtime,0),12,1);
%     setDigitalChannel(calctime(curtime,5),12,0);
% 
% 
%     setAnalogChannel(calctime(curtime,0),'X Shim',0.0,3); %3
%     setAnalogChannel(calctime(curtime,0),'Y Shim',0.0,4); %4
%     setAnalogChannel(calctime(curtime,0),'Z Shim',0,3); %3
% 
% curtime = calctime(curtime, 1000)
%     setAnalogChannel(calctime(curtime,0),'X Shim',0,3); %3
%     setAnalogChannel(calctime(curtime,0),'Y Shim',0,4); %4
%     setAnalogChannel(calctime(curtime,0),'Z Shim',0,3); %3
% curtime = calctime(curtime, 1000)
% setAnalogChannel(calctime(curtime,0),59,0); 
% 
% setDigitalChannel(calctime(curtime,-10),'EIT Shutter',0);
% setDigitalChannel(calctime(curtime,-10),'D1 Shutter',0);
% 
% curtime = calctime(curtime, 1000)

% setAnalogChannel(calctime(curtime,0),62,0); 
% setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',0);
% setDigitalChannel(calctime(curtime,0),'Kill TTL',0);
% % setDigitalChannel(calctime(curtime,0),'Raman Shutter',1);

% %% Raman check
% setAnalogChannel(calctime(curtime,0),59,0); 
% curtime =  setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);    

% % setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1)
% setDigitalChannel(calctime(curtime,0),'Raman Shutter',0)
% setDigitalChannel(calctime(curtime,0),'D1 Shutter',0)
% setDigitalChannel(calctime(curtime,0),'EIT Shutter',0)
% setAnalogChannel(calctime(curtime,0),'F Pump',9.99);


% mod_freq =  (120)*1E6;
% mod_amp = 1.5;
% mod_offset =0;
% str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
% addVISACommand(6, str);

% %OP test
% curtime =  setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);    
% setAnalogChannel(calctime(curtime,0),'D1 AM',10); 
% 
% tnow=now;
% addOutputParam('now',(tnow-floor(tnow))*24*60*60);
% 
% %% kill test
% mod_freq =  (120)*1E6;
% mod_amp =1;
% mod_offset =0;
% str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
% addVISACommand(6, str);
% 
% 
% 
% 
% % Set trap AOM detuning to change probe
% setAnalogChannel(calctime(curtime,0),'K Trap FM',42.7); %54.5
% 
% % open K probe shutter
% setDigitalChannel(calctime(curtime,0),'Downwards D2 Shutter',1); %0=closed, 1=open
% 
%% Test HF Imaging 
% setDigitalChannel(calctime(curtime,0),'High Field Shutter',1); %0: off 1:on
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',0); %1: off 0:on
% % setAnalogChannel(calctime(curtime,0),63,0); 
% 
% 
% % setDigitalChannel(calctime(curtime,0),67,1); %0: off 1:on
% 
%  HF_prob_freq_list = [0];%3.75
% % %     HF_prob_freq = getScanParameter(HF_prob_freq_list,seqdata.scancycle,seqdata.randcyclelist,'HF_prob_freq')+ 1.4*(1-205)/2; %3.75 for 205G;
%     HF_prob_freq = getScanParameter(HF_prob_freq_list,seqdata.scancycle,seqdata.randcyclelist,'HF_prob_freq','MHz');
% % % 
%     mod_freq =  (120+HF_prob_freq)*1E6;
%     HF_prob_pwr_list = [1.5];
%     HF_prob_pwr = getScanParameter(HF_prob_pwr_list,seqdata.scancycle,seqdata.randcyclelist,'HF_prob_pwr','V');
%     mod_amp = HF_prob_pwr;
%     mod_offset =0;
%     str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
%     addVISACommand(6, str);
 
% curtime = calctime(curtime,1000);
% % setDigitalChannel(calctime(curtime,0),'Kill TTL',0);
% setDigitalChannel(calctime(curtime,0),'DMD AOM TTL',1);
% 
% setAnalogChannel(calctime(curtime,0),63,0);
%% Test HF Imaging/Specctroscopy SRS

% curtime = calctime(curtime,1000);                       % Wait
% 
% 
% % Turn off the uWave
% setDigitalChannel(calctime(curtime,-100),'RF TTL',0); 
% 
% % Turn off VVA
% setAnalogChannel(calctime(curtime,-100),'RF Gain',-10);
% 
% 
% rf_tof_srs_power_list = [9];
% rf_tof_srs_power = getScanParameter(rf_tof_srs_power_list,seqdata.scancycle,...
%     seqdata.randcyclelist,'rf_tof_srs_power','dBm');
% 
% sweep_time = 5000;
% 
% rf_srs_opts = struct;
% rf_srs_opts.Address='192.168.1.120'; %28:HF Imaging    '192.168.1.120':RF
% spec
% rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
% rf_srs_opts.PowerBNC = rf_tof_srs_power;                           
% rf_srs_opts.Frequency = 50;
% % Calculate the beta parameter
% beta=asech(0.005);   
% 
% 
% % Enable uwave frequency sweep
% rf_srs_opts.EnableSweep=1;
% rf_tof_delta_freq = [20]*1e-3;
% rf_srs_opts.SweepRange=abs(rf_tof_delta_freq);  
% 
% 
% % Set initial modulation
% setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
%    
% 
% % Ramp the SRS modulation using a TANH
% % At +-1V input for +- full deviation
% % The last argument means which votlage fucntion to use
% AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
%     @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
%     sweep_time,sweep_time,beta,1);
% 
% % Program the SRS
% programSRS_BNC(rf_srs_opts); 
% params.isProgrammedSRS = 1;

%% HF Testing timing double shutter
% 
% tp=.3; % Imaging pulse duration
% 
%  % Pre trigger of camera trigger to imaging light
% t1_list=[.03];
% t1=getScanParameter(t1_list,seqdata.scancycle,seqdata.randcyclelist,'cam_pretrigger');
% 
% td_list=[0.04];
% td=getScanParameter(td_list,seqdata.scancycle,seqdata.randcyclelist,'light2_delay');
% 
% 
% 
% setDigitalChannel(calctime(curtime,0),'HF freq source',1); % 0: Rigol Ch1, 1: Rigol Ch2
% 
% setDigitalChannel(calctime(curtime,0),'High Field Shutter',1); %0: off 1:on
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',1); %1: off 0:on
% setDigitalChannel(calctime(curtime,0),'PixelFly Trigger',0);
% setDigitalChannel(calctime(curtime,0),30,0); %1: off 0:on
% 
% % Wait for 100 ms
% curtime=calctime(curtime,100);
% 
% % Light pulse
% setDigitalChannel(calctime(curtime,-t1),'PixelFly Trigger',1);
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',0); %1: off 0:on
% setDigitalChannel(calctime(curtime,tp),'K High Field Probe',1); %1: off 0:on
% 
% setDigitalChannel(calctime(curtime,tp+td),'K High Field Probe',0); %1: off 0:on
% setDigitalChannel(calctime(curtime,tp+td+tp),'K High Field Probe',1); %1: off 0:on
% 
% setDigitalChannel(calctime(curtime,tp+10),'PixelFly Trigger',0);
% 
% % Wait for 100 ms
% curtime=calctime(curtime,500);
% % Trigger camera
% 
% % Light pulse
% setDigitalChannel(calctime(curtime,-t1),'PixelFly Trigger',1);
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',0); %1: off 0:on
% setDigitalChannel(calctime(curtime,tp),'K High Field Probe',1); %1: off 0:on
% 
% % Second light
% setDigitalChannel(calctime(curtime,tp+td),'K High Field Probe',0); %1: off 0:on
% setDigitalChannel(calctime(curtime,tp+td+tp),'K High Field Probe',1); %1: off 0:on
% 
% setDigitalChannel(calctime(curtime,tp+10),'PixelFly Trigger',0);
% 
%% LF Double SHutter KRB
% seqdata.flags.image_type = 0; 
% seqdata.flags.MOT_flour_image = 0;
% seqdata.flags.image_atomtype = 2;%  0:Rb; 1:K; 2: K+Rb (double shutter)
% seqdata.flags.image_loc = 1; %0: `+-+MOT cell, 1: science chamber    
% seqdata.flags.img_direction = 0; 
% seqdata.flags.do_stern_gerlach = 0; %1: Do a gradient pulse at the beginning of ToF
% seqdata.flags.iXon = 0; % use iXon camera to take an absorption image (only vertical)
% seqdata.flags.do_F1_pulse = 0; % repump Rb F=1 before/during imaging
% seqdata.flags.High_Field_Imaging = 0;
% seqdata.flags.In_Trap_imaging = 0;
% seqdata.flags.QP_imaging = 1;
% seqdata.flags.xdt_K_p2n_rf_sweep_freq=0;
% 
%         curtime = absorption_image2(calctime(curtime,0.0)); 

%% R3 beam

% 
%         Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
%         Raman_AOM3_freq =  60;
%         Raman_AOM3_pwr = 1;
% %         RamanspecMode = 'sweep'
%         RamanspecMode = 'pulse'
% 
% 
%         %R3 beam settings
%         switch RamanspecMode
%             case 'sweep'
%                 Sweep_Range = 1;  %in MHz
%                 Sweep_Time = 10; %in ms
%                 str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
%                     Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
%                 Raman_on_time = Sweep_Time;
% 
%             case 'pulse'
%                 Raman_on_time = 50; %ms
%                 str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
%                     Raman_AOM3_freq, Raman_AOM3_pwr);
%         end 
%         addVISACommand(Device_id, str);
%         Raman Shutter
% curtime = calctime(curtime,200);
% 
% setDigitalChannel(calctime(curtime,0),'Raman TTL 1',0);
% setAnalogChannel(calctime(curtime,0),57,00);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
% 
% setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
% setDigitalChannel(calctime(curtime,30),'Raman TTL 2',1);
% setDigitalChannel(calctime(curtime,30),'Raman TTL 3',1);
% 
% Raman_time = 10;
% setDigitalChannel(calctime(curtime,30+Raman_time),'Raman TTL 2',0);
% setDigitalChannel(calctime(curtime,30+Raman_time),'Raman TTL 3',0);
% 
% setDigitalChannel(calctime(curtime,30+Raman_time+5),'Raman Shutter',0);
% 
% setDigitalChannel(calctime(curtime,30+Raman_time+10),'Raman TTL 2',1);
% setDigitalChannel(calctime(curtime,30+Raman_time+10),'Raman TTL 3',1);
% 
% 
% do_ACync = 0;
% 
% if do_ACync
% ACync_start_time = calctime(curtime,20);
% ACync_end_time = calctime(curtime,Raman_time+30+20);
% setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
% setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0)
% 
% end



%% Feshbach field test

% curtime = calctime(curtime,500);
% 
% 
%  clear('ramp');
%         % FB coil settings for spectroscopy
%         ramp.FeshRampTime = 150;
%         ramp.FeshRampDelay = -0;
%         HF_FeshValue_Initial_List = 212;[202.78];
%         HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
%         ramp.FeshValue = HF_FeshValue_Initial;
%         ramp.SettlingTime = 50;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);
%         
% curtime = calctime(curtime,200);
% 
% 
%         clear('ramp');
%         % FB coil settings for spectroscopy
%         ramp.FeshRampTime = 150;
%         ramp.FeshRampDelay = -0;
%         HF_FeshValue_Initial_List = 0;[202.78];
%         HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial');
%         ramp.FeshValue = HF_FeshValue_Initial;
%         ramp.SettlingTime = 50;    
% curtime = rampMagneticFields(calctime(curtime,0), ramp);

% %% Test Acync
% if acync_test
% curtime = calctime(curtime,100);
% 
%     setDigitalChannel(calctime(curtime,-35),'ACync Master',1);
%     % 
%     setAnalogChannel(calctime(curtime,-5),57,00);
%     % 
%     % AnalogFuncTo(calctime(curtime,0),57,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2,2,10);
%     % setAnalogChannel(calctime(curtime,10),57,-10);
%     % 
%     setDigitalChannel(calctime(curtime,0),72,1);
%     setDigitalChannel(calctime(curtime,15),72,0);
%     % 
% 
%     setDigitalChannel(calctime(curtime,30),'ACync Master',0);
% end
%% Test RF 

% if RF_switch_gain_test
% 
% curtime=calctime(curtime,1000); 
%     setAnalogChannel(calctime(curtime,0),'RF Gain',-5);
%     setDigitalChannel(calctime(curtime,0),'RF Source',1);      % 1 si DDS : 0 is SRSs
%     setDigitalChannel(calctime(curtime,0),'RF TTL',1);      % 0 : off, 1 : on 
%     setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);      % 0 : RF 1 : uwave 
% curtime=calctime(curtime,50); 
%  
% end

%% K uwave Test

%     curtime=calctime(curtime,1000); 
% 
%     % Make sure RF, Rb uWave, K uWave are all off for safety
%     setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
%     setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
%     setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);
% 
%     % Switch antenna to uWaves (0: RF, 1: uWave)
%     setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
%     
%     % Switch uWave source to the K sources (0: K, 1: Rb);
%     setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);
% 
%     % RF Switch for K SRS depreciated?
%     setDigitalChannel(calctime(curtime,-20),'K uWave Source',1);  
%     
%     % Other thing
%     setDigitalChannel(calctime(curtime,-20),'SRS Source',1);  
%     
%     setDigitalChannel(calctime(curtime,-50),'K uWave TTL',1);
%     
%     setAnalogChannel(calctime(curtime,0),'uWave VVA',10);

%% Test K kill
k_kill = 0;
if k_kill
curtime=calctime(curtime,1000); 
setAnalogChannel(calctime(curtime,pulse_offset_time-50),'K Trap FM',42.7); %54.5

% open K probe shutter
setDigitalChannel(calctime(curtime,pulse_offset_time-5),'Downwards D2 Shutter',1); %0=closed, 1=open

% Set TTL off initially
setDigitalChannel(calctime(curtime,pulse_offset_time-20),'Kill TTL',1);%0= off, 1=on

curtime=calctime(curtime,1000); 
end

%% Oscillate piezo
do_piezo_oscillate=0;
if do_piezo_oscillate
    
    seqdata.flags.image_type = 0; 
    seqdata.flags.image_atomtype = 1;
    
    tof_list = [25];
    seqdata.params.tof = getScanParameter(tof_list,...
    seqdata.scancycle,seqdata.randcyclelist,'tof','ms');
    
    curtime=calctime(curtime,100); 
%     V_center = [5];
%     V_amp = [3];
%     
%     % Freqency of oscillation
%     freq = 1; % In Hz;
%     freq = freq * 1e-3;
%     
%     % Total oscillation time
%     T_tot = 5; % In s
%     T_tot = T_tot*1e3;
    
%     if (V_amp+V_center)>10 || (V_center - V_amp)<0
%        error('votlage out of range'); 
%     end
    
    % 0.1V = 700 nm, must be larger than  larger value means farther away from the window.
    setDigitalChannel(calctime(curtime,-30),'Kill TTL',1);
    setDigitalChannel(calctime(curtime,-20),'Downwards D2 Shutter',1); %0=closed, 1=open
    
    obj_piezo_V_List = [10];
    
    obj_piezo_V = getScanParameter(obj_piezo_V_List, ...
    seqdata.scancycle, 1:length(obj_piezo_V_List), 'Objective_Piezo_Z','V');

    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);   
 
% AnalogFunc (curtime, chanell name, function handle, total time to run,
% arguments to fucntion (first arumgnet is t))
%     AnalogFunc(calctime(curtime,0),'objective Piezo Z',...             
%         @(t,amp,cen,f) amp*sin(2*pi*f*t)+cen,T_tot,...
%         V_amp,V_center,freq);


    pulse_length = 0.3;

    curtime = calctime(curtime,10);
    DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);

    setDigitalChannel(calctime(curtime,50),'Downwards D2 Shutter',0); %0=closed, 1=open

    curtime = calctime(curtime,300);
    DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);

   
   

end

%% Pixel FLy Testing
do_pixel_fly_test = 0;
if do_pixel_fly_test
    curtime=calctime(curtime,1000); 

   DigitalPulse(curtime,'PixelFly Trigger',101,1);
   curtime=calctime(curtime,1000); 
   
   setAnalogChannel(calctime(curtime,0),'UV Lamp 2',0)

end

%% Test Rb uwave sweep
% curtime = calctime(curtime,1000);
%  % uWave Sweeep Prepare
%     %%%%%%%%%%%%%%%%%%%%
% %     use_ACSync=0;    
%     dispLineStr('Sweeping uWave Rb 2-->1',curtime);   
%     
%     % uWave Center Frequency
%     freq_list = [-0.125];
%     freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
%         seqdata.randcyclelist,'rb_uwave_freq_offset','MHz');    
%     
%     uWave_delta_freq_list=[10];
%     uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_delta_freq','MHz');
%         
%     uwave_sweep_time_list =[5000]; 
%     sweep_time = getScanParameter(uwave_sweep_time_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_sweep_time','ms');   
%      
%     Rb_SRS=struct;
%     Rb_SRS.Address=29;        % GPIB address of the Rb SRS    
% %     Rb_SRS.Frequency=0.5+freq_offset*1E-3; % Frequency in GHz
%     Rb_SRS.Frequency=1; % Frequency in GHz 
% 
%     Rb_SRS.Power=9;           % Power in dBm 
%     Rb_SRS.Enable=1;          % Power on
%     Rb_SRS.EnableSweep=0;     % Sweep on     
%     Rb_SRS.SweepRange=uWave_delta_freq; % Sweep range in MHz   
%              
%     addOutputParam('rb_uwave_pwr',Rb_SRS.Power,'dBm')
%     addOutputParam('rb_uwave_frequency',Rb_SRS.Frequency,'GHz');            
%     
%     disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);
%     disp(['     Sweep Range  : ' num2str(uWave_delta_freq) ' MHz']);
%     disp(['     Freq Offset  : ' num2str(freq_offset) ' MHz']);     
%     
%     % Program the SRS    
%     programSRS_Rb(Rb_SRS);      
%     
%     % Make sure RF, Rb uWave, K uWave are all off for safety
%     setDigitalChannel(calctime(curtime,-35),'RF TTL',0);
%     setDigitalChannel(calctime(curtime,-35),'Rb uWave TTL',0);
%     setDigitalChannel(calctime(curtime,-35),'K uWave TTL',0);
% 
%     % Switch antenna to uWaves (0: RF, 1: uWave) for Rb (1)
%     setDigitalChannel(calctime(curtime,-30),'RF/uWave Transfer',1); 
%     setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',1); 
%     setDigitalChannel(calctime(curtime,-35),'Rb Source Transfer',0); %0 = SRS, 1 = Sextupler
% 
%     % Set initial modulation
%     setAnalogChannel(calctime(curtime,-35),'uWave FM/AM',-1);    
%     
%     %%%%%%%%%%%%%%%%%%%%
%     % uWave Sweeep 
%     %%%%%%%%%%%%%%%%%%%%           
%     setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',1);      % Turn on uWave 
% %     AnalogFunc(calctime(curtime,0),'uWave FM/AM',...              % Ramp +-1V
% %         @(t,T) -1+2*t/T,sweep_time,sweep_time);
% % setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1,1)
% %     curtime = calctime(curtime,sweep_time);                       % Wait
%     setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);      % Turn off uWave
% %     
% %     % Reset the uWave deviation after a while
%     setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);  
 

% 
%       rotation_time = 1000;   % The time to rotate the waveplate
%       P_lattice = 0.8; %0.5/0.9        % The fraction of power that will be transmitted 
%       curtime = AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);
% 
%       
%       
%       
%       
%       ylow = -0.26;
%       ylow = -0.9;
%     yoff = -9.8;
%     yask = 10;
%     setAnalogChannel(calctime(curtime,0-250),48,yoff,1);
%     setAnalogChannel(calctime(curtime,-200),'xLattice',-10,1);
% 
% %     setAnalogChannel(calctime(curtime,0),'xLattice',ylow);
%     setDigitalChannel(calctime(curtime,-5),'Lattice Direct Control',0); % 0 : Int on; 1 : int hold    
%     curtime = calctime(curtime,1000);    
%     setDigitalChannel(calctime(curtime,0),'yLatticeOFF',0); % 0 : All on, 1 : All off
% %     setAnalogChannel(calctime(curtime,-20),'xLattice',ylow);
% %     
% 
% 
%      AnalogFunc(calctime(curtime,0),'yLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50,-0.9, yask);
%     
%     
%      AnalogFunc(calctime(curtime,0),'zLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50,-0.9, yask);
%     
%     setAnalogChannel(calctime(curtime,-20),'xLattice',ylow);
%     
%     curtime = AnalogFuncTo(calctime(curtime,0),'xLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%         150, 150, yask);
%     
%     
%     curtime = calctime(curtime,1000)
%     
%     
%     AnalogFuncTo(calctime(curtime,0),'xLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 3, 3, ylow-1);
%     
%     AnalogFuncTo(calctime(curtime,0),'zLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 3, 3, ylow-1);
%     
%      curtime = AnalogFunc(calctime(curtime,0),'yLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 3, 3,yask, -0.9-1);
%     setDigitalChannel(calctime(curtime,1),'yLatticeOFF',0); % 0 : All on, 1 : All off
%    
% %     setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',0); % 0 : Int on; 1 : int hold    
% 
%     setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);

    
    
%     setAnalogChannel(calctime(curtime,200),'xLattice',-10 ,1);
%     setDigitalChannel(calctime(curtime,400),'yLatticeOFF',1); % 0 : All on, 1 : All off

% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1); % 0 : Int on; 1 : int hold    
%     setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',6);
% 
%     setAnalogChannel(calctime(curtime,0),'K Probe/OP FM',180);%      AnalogFunc(calctime(curtime,0),'yLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50,-0.9, yask);

%     setAnalogChannel(calctime(curtime,200),'MOT Coil',10)

% setAnalogChannel(calctime(curtime,0),'Rb Trap AM', 0.3);            % Rb MOT Trap power   (voltage)
% setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0); 

% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1);
% setDigitalChannel(calctime(curtime,0),'K Probe/OP Shutter',1); % Open K Shtter with pre-trigger
% %Now at k_op_offset time because there is no TTL (turns on pulse). 
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.5)
% 
% setDigitalChannel(calctime(curtime,0),'D1 Shutter',0)
% setDigitalChannel(calctime(curtime,0),'F Pump TTL',0)
% setDigitalChannel(calctime(curtime,0),'EIT Shutter',0);
% setAnalogChannel(calctime(curtime,0),'F Pump',0.9)
% setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
% setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
%     setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',6);
% 
% setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1);
% setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1);
% setAnalogChannel(calctime(curtime,0),'F Pump',0.9)

%     curtime = calctime(curtime,1000)


%     setAnalogChannel(calctime(curtime,0),'Rb Beat Note FM',4.083,1);

% % setDigitalChannel(calctime(curtime,0),'DDS Rb Trap Trigger',0);
% seqdata.numDDSsweeps = 0;
% seqdata.DDSsweeps=[];
% 
% op_trap_detuning = -28;
% f_osc = calcOffsetLockFreq(op_trap_detuning,'MOT');
% DDS_id = 3;    
% DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,1)  
%     
% setDigitalChannel(calctime(curtime,0),'DDS Rb Trap Trigger', 1);%1: turn on laser; 0: turn off laser

    
    % Open D1 shutter (FPUMP + OPT PUMP)
%     setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1);%1: turn on laser; 0: turn off laser
%         
%     Open optical pumping AOMS (allow light) and regulate F-pump
%     setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
%     setAnalogChannel(calctime(curtime,0),'F Pump',1.2);
%     setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
%     setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
%         setAnalogChannel(calctime(curtime,0),'D1 AM',10); 

    %Optical pumping time
% curtime = calctime(curtime,optical_pump_time);
    
% setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);
% setDigitalChannel(calctime(curtime,0),'RF Source',0);
% setDigitalChannel(calctime(curtime,0),'SRS Source',1);
% setDigitalChannel(calctime(curtime,0),'SRS Source post spec',0);
% setDigitalChannel(calctime(curtime,0),'K uWave Source',1);
% setDigitalChannel(calctime(curtime,0),'RF TTL',0);
% 
% 
% setAnalogChannel(calctime(curtime,0),'F Pump',0.9)
% 
% % Switch antenna to uWaves (0: RF, 1: uWave)
% setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',1); 
% 
% % Switch uWave source to the K sources (0: K, 1: Rb);
% setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',0);



 
% MHz = 1e6;
% kHz = 1e3;
%     detuning_list = [0];[0];300;
%     df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
%     DDSFreq = 324.20625*MHz + df*kHz/4;
%     DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
%     addOutputParam('DDSFreq',DDSFreq);
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1)
% 
% setDigitalChannel(calctime(curtime,-0),'UV LED',1); % THe X axis bulb 1 on 0 off

 %%
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1)
% % setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1); 
% % setAnalogChannel(calctime(curtime,0),'K Trap FM',5);
% % setDigitalChannel(calctime(curtime,0),'K Probe/OP Shutter',1); % Open K Shtter with pre-trigger
% % 
% % setDigitalChannel(calctime(curtime,0),'Rb Probe/OP Shutter',1); % Open shutter
% % setAnalogChannel(calctime(curtime,0),'Rb Probe/OP AM',1); % Set 
% % setDigitalChannel(calctime(curtime,0),'Rb Probe/OP TTL',0); % inverted logic
% 
% 
% % Shutter 1 is usually closed (light not allowed)
% setDigitalChannel(curtime,'Vortex Shutter 1',0);
% 
% % Shutter 2 is nominally open (light allowed)
% setDigitalChannel(curtime,'Vortex Shutter 2',1);
% setDigitalChannel(curtime,'ScopeTrigger',0);
% 
% curtime = calctime(curtime,100);
% 
% 
% tD1 = -2.75;
% tD2 = -2.85;
% 
% pulse_time = 3;
% 
% % Let light through with Shutter 1
% setDigitalChannel(calctime(curtime,tD1),'Vortex Shutter 1',1);
% setDigitalChannel(curtime,'ScopeTrigger',1);
% setDigitalChannel(calctime(curtime,pulse_time),'ScopeTrigger',0);
% 
% % Stop light with shutter 2
% setDigitalChannel(calctime(curtime,tD2+pulse_time),'Vortex Shutter 2',0);
% 
% curtime=calctime(curtime,100);
% 
% % Reset
% setDigitalChannel(curtime,'Vortex Shutter 1',0);
% setDigitalChannel(curtime+10,'Vortex Shutter 2',1);

%% 2022/09/06
% Testing thermal properties of Y lattice Fiber
% 
% 
% % Turn off all lattices but turn AOM on
% setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
% setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);
% setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);
% setDigitalChannel(calctime(curtime,0),'yLatticeOFF',0);%0: ON
% 
% doRotateWaveplate=1;
% if doRotateWaveplate
%     wp_Trot1 = 600; % Rotation time during XDT
%     wp_Trot2 = 150; 
%     P_RotWave_I = 0.8;
%     P_RotWave_II = 0.99;    
% %     P_RotWave_II = 0.01;    
% 
%     dispLineStr('Rotate waveplate again',curtime)    
%         %Rotate waveplate again to divert the rest of the power to lattice beams
% curtime = AnalogFunc(calctime(curtime,0),41,...
%         @(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
%         wp_Trot2,wp_Trot2,P_RotWave_I,P_RotWave_II);             
% end
% 
% curtime=calctime(curtime,550);
% 
% % Set Y lattice depth to be high
% ScopeTriggerPulse(calctime(curtime,0),'lattice_on');
% setAnalogChannel(calctime(curtime,0),'yLattice',150,2);
% 
% % Wait 2 seconds
% curtime=calctime(curtime,2000);
% 
% setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);
%%
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',1)
% % 
% curtime = calctime(curtime,20);
% 
% % Turn off all RF, Rb uWave, K uWave are all off for safety
% setDigitalChannel(calctime(curtime,-20),'RF TTL',0);
% setDigitalChannel(calctime(curtime,-20),'Rb uWave TTL',0);
% setDigitalChannel(calctime(curtime,-20),'K uWave TTL',0);
% 
% % Switch antenna to uWaves (0: RF, 1: uWave)
% setDigitalChannel(calctime(curtime,-19),'RF/uWave Transfer',1); 
% 
% % Switch uWave source to the K sources (0: K, 1: Rb);
% setDigitalChannel(calctime(curtime,-19),'K/Rb uWave Transfer',0);
% 
% % RF Switch for K SRS depreciated?
% setDigitalChannel(calctime(curtime,-19),'K uWave Source',1);      
% 
% % Set the SRS source (SRS B);
% setDigitalChannel(calctime(curtime,-19),'SRS Source',1);  
% 
% % Set initial modulation (in case of frequency sweep)
% setAnalogChannel(calctime(curtime,-20),'uWave FM/AM',-1);    
    
%%
% setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0); 
% 
% setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1)
% % Set RF Source to SRS
% setDigitalChannel(calctime(curtime,0),'RF Source',1);
% 
% % Set SRS Direction to RF
% setDigitalChannel(calctime(curtime,0),'K uWave Source',0);
% 
% % Set RF power to low
% setAnalogChannel(calctime(curtime,0),'RF Gain',-8);
% 
% Set initial modulation
% setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1);
% Turn on the RF
% setDigitalChannel(calctime(curtime,0),'K High Field Probe',1); 
% setDigitalChannel(calctime(curtime,0),'K Probe/OP TTL',1); 
% setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0.15)

%setAnalogChannel(calctime(curtime,0),'Vortex Current Mod',0)

% setDigitalChannel(calctime(curtime,0),'F Pump TTL',0)
% setDigitalChannel(calctime(curtime,0),'FPump Direct',0);

% setDigitalChannel(calctime(curtime,0),'PA Shutter',1)

% setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);
% setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);
% 
% setDigitalChannel(0,'PA Shutter',1); %0 open
% 
% setDigitalChannel(0,'PA TTL',1); 
% 
% setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1)
% setDigitalChannel(curtime,'UV LED',1); 
% curtime = PA_pulse(curtime); 
% DigitalPulse(calctime(curtime,10),'PixelFly Trigger',1,1);
% setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0)
% setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',1)
% setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1)
% setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',0)
% setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',1)
%   setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0);


% setAnalogChannel(calctime(curtime,0),'X MOT Shim',0,1)
% setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0,1)
% setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0,1)
% 
% setAnalogChannel(calctime(curtime,0),'X Shim',0,1)
% setAnalogChannel(calctime(curtime,0),'Y Shim',0,1)
% setAnalogChannel(calctime(curtime,0),'Z Shim',0,1)

% setAnalogChannel(calctime(curtime,1000),'X Shim',0,1)
% setAnalogChannel(calctime(curtime,1000),'Y Shim',0,1)
% setAnalogChannel(calctime(curtime,1000),'Z Shim',0,1)

setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',0); %0.12
setDigitalChannel(calctime(curtime, 0),'K Probe/OP shutter',0);

setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);
setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);



timeout = curtime;
% SelectScopeTrigger('PA_Pulse');




