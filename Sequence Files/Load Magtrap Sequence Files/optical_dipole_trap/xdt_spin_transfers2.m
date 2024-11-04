function [curtime] = xdt_spin_transfers2(timein)
curtime= timein;
global seqdata

%% Flags and Variables


% % WORKS FOR IFB = 2;
% % Rb uWave SRS Frequency Sweep
% seqdata.flags.xdt_spin_xfer_transfer_Rb_freq_sweep  = 1;
% defVar('Rb_uWave_freq0',6834.7,'MHz');f0 = 6834.7; % zero field splitting
% defVar('Rb_uWave_transfer_freq_shift',[4.02],'MHz');
% defVar('Rb_uWave_transfer_freq',...
%     getVar('Rb_uWave_freq0')+getVar('Rb_uWave_transfer_freq_shift'),'MHz');
% defVar('Rb_uWave_transfer_power',9,'dBm');
% defVar('Rb_uWave_transfer_freq_amp',40,'kHz');50;
% defVar('Rb_uWave_transfer_time',[50],'ms');10;
% 
% 
% seqdata.flags.xdt_spin_xfer_transfer_K              = 1;
% defVar('xdt_spin_xfer_K_freq',0.6,'MHz');
% defVar('xdt_spin_xfer_K_freq_amp',0.1,'MHz');
% defVar('xdt_spin_xfer_K_gain',-9,'V'); % if you make this too high you will perturb Rb
% defVar('xdt_spin_xfer_K_time',50,'ms');
% 
% seqdata.flags.xdt_spin_xfer_Rb_2_kill               = 1;

%% Flags and Variables


% WORKS FOR IFB = 5;
% Rb uWave SRS Frequency Sweep
seqdata.flags.xdt_spin_xfer_transfer_Rb_freq_sweep  = 1;
defVar('Rb_uWave_freq0',6834.7,'MHz');f0 = 6834.7; % zero field splitting
defVar('Rb_uWave_transfer_freq_shift',[10.34],'MHz');10.34;
defVar('Rb_uWave_transfer_freq',...
    getVar('Rb_uWave_freq0')+getVar('Rb_uWave_transfer_freq_shift'),'MHz');
defVar('Rb_uWave_transfer_power',[13],'dBm');%-10dBm to +13 dBm is VALID
defVar('Rb_uWave_transfer_freq_amp',50,'kHz');50;%50kHz~24 mG
defVar('Rb_uWave_transfer_time',[15],'ms');10;

seqdata.flags.xdt_spin_xfer_Rb_2_kill               = 1;


% Better spni purity, worse number
seqdata.flags.xdt_spin_xfer_transfer_K              = 1;
defVar('xdt_spin_xfer_K_freq',[1.6],'MHz');1.52;
defVar('xdt_spin_xfer_K_freq_amp',0.25,'MHz');.15;
defVar('xdt_spin_xfer_K_gain',-3,'V');0; % if you make this too high you will perturb Rb
defVar('xdt_spin_xfer_K_time',50,'ms');20;

% Worse Spin purity, but better number after evap
defVar('xdt_spin_xfer_K_freq',[1.52],'MHz');1.52;
defVar('xdt_spin_xfer_K_freq_amp',0.15,'MHz');.15;
defVar('xdt_spin_xfer_K_gain',0,'V');0; % if you make this too high you will perturb Rb
defVar('xdt_spin_xfer_K_time',20,'ms');20;

seqdata.flags.xdt_spin_xfer_hold_after = 0;
defVar('xdt_hold_time',[0],'ms');

seqdata.flags.xdt_d1op_start =1;
%% Estimate Magnetic Field

 % Estimate the frequency shift based on the FB field (Gauss or Amps?)
    % Use this value if you are tryign to find the center frequency
    I_FB = getChannelValue(seqdata,'FB Current',1);     
    logText([' Feshbach ' num2str(round(I_FB,2)) ' A? or Gauss?']);
    
    % Rubidium Frequency Shift  Transition MHz/Gauss (2,2-->1,1)    
    kappa_rb = 2.1;
    dRb=kappa_rb*I_FB;    
    logText([' Est. Rb uWave Shift : FB*' num2str(round(kappa_rb,2)) 'MHz/G =' num2str(round(dRb,2)) ' MHz']);
    
    % Potassium Frequency Shift 9/2,9/2-->9/2,7/2
    % gF=2/9, muB = 1.4 MHz/Gauss
    kappa_K = 2/9*1.4; % Transition MHz/Gauss (2,2-->1,1)
    dK=kappa_K*I_FB;    
    logText([' Est. K RF Shift     : FB*' num2str(round(kappa_K,2))  'MHz/G ='  num2str(round(dK,2)) ' MHz']);
    
    % Rubidium RF Frequency Shift 2,2->2,1 UNDESIRED
    % gF=1/2, muB = 1.4 MHz/Gauss
    kappa_rb_rf = 1/2*(2-1)*1.4; % gF*deltaM*muB
    drb_rf=kappa_rb_rf*I_FB;    
    logText([' Est. Rb RF Shift    : FB*' num2str(round(kappa_rb_rf,2))  'MHz/G ='  num2str(round(drb_rf,2)) ' MHz']);   
    
%% Rb Transfer |2,2> to |1,1> Using SRS + Freq sweep
% Pulse the Rb uWave.  We rely on a field sweep in order to perform the
% Landau Zener transition

if seqdata.flags.xdt_spin_xfer_transfer_Rb_freq_sweep       
    logNewSection('uWave Rb Pulse',calctime(curtime,0));       
    % 6834.7 MHz is approximately the zero field value     
    % Anritsu frequency is 6875.6 MHz  (~19.5 Gauss)    
    
   
    % At 2.1 MHz/Gauss a 50 mG field shift 100 kHz, so may not want to go
    % signifcantly below this.
    
    % Prepare Switches
    setDigitalChannel(calctime(curtime,-30),'RF TTL',0);                 % RF OFF
    setDigitalChannel(calctime(curtime,-30),'Rb uWave TTL',0);           % V1 low
    setDigitalChannel(calctime(curtime,-30),'Rb uWave SRS TTL',0);       % V2 low
    setDigitalChannel(calctime(curtime,-30),'RF/uWave Transfer',1);      % 0: RF, 1: uwave      
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',1);    % 0: K, 1: Rb     
    %setDigitalChannel(calctime(curtime,-30),'Rb Source Transfer',0);     % 0 = Anritsu, 1 = Sextupler  
    
    % Prepare Analog Levels (VVA and Frequency)     
    setAnalogChannel(calctime(curtime,-30),'uWave VVA',0);      % Set uWave to low
    setAnalogChannel(calctime(curtime,-30),'uWave FM/AM',-1);   % Set initial modulation    
    
    % Configure the SRS
    uWave_opts=struct;
    uWave_opts.Address      = 27;                       % SRS GPIB Addr
    uWave_opts.Frequency    = getVar('Rb_uWave_transfer_freq'); % Frequency [MHz]
    uWave_opts.Power        = getVar('Rb_uWave_transfer_power');                  % Power [dBm]
    uWave_opts.Power
    uWave_opts.Enable       = 1;                        % Enable SRS output    
    uWave_opts.EnableSweep  = 1;                    
    uWave_opts.SweepRange   = 1e-3*getVar('Rb_uWave_transfer_freq_amp');         % Sweep Amplitude [MHz]

    logText(['     Freq         : ' num2str(getVar('Rb_uWave_transfer_freq')) ' MHz']);    
    logText(['     Pulse Time   : ' num2str(getVar('Rb_uWave_transfer_time')) ' ms']);
    logText(['     Freq Amp     : ' num2str(getVar('Rb_uWave_transfer_freq_amp')) ' kHz']);

    setDigitalChannel(calctime(curtime,0),'Rb uWave SRS TTL',1);    % Turn on the uWave
    % Ramp up rabi frequency
curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),0.5,0.5,0,10,1);  
    ScopeTriggerPulse(curtime,'Rb uWave transfer');
    % Linearly ramp the frequency
curtime = AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
        @(t,T) -1+2*t/T,...
        getVar('Rb_uWave_transfer_time'),getVar('Rb_uWave_transfer_time'),1);
   % Ramp down rabi frequency
curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        0.5,0.5,10,0,1); 
    setDigitalChannel(calctime(curtime,0),'Rb uWave SRS TTL',0);    % uWave off
    setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);   % 0: RF, 1: uwave   
    setAnalogChannel(calctime(curtime,0),'uWave VVA',0);            % Turn off VVA        
%     programSRS(uWave_opts);                                         % Program the SRS  
        programSRS_Rb2(uWave_opts);                                         % Program the SRS  

    t_uWaveComplete = curtime;
end


%% Rb F=2 Blow Away

if seqdata.flags.xdt_spin_xfer_Rb_2_kill
    logNewSection('Blowing Rb F=2 away',curtime);
    setAnalogChannel(calctime(curtime,-10),4,0.0); % set amplitude   0.7
    AnalogFuncTo(calctime(curtime,-15),34,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,6590-237); % Ramp Rb trap laser to resonance   237

    probe32_trap_detuning = 0;
    f_osc = calcOffsetLockFreq(probe32_trap_detuning,'Probe32');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,-15),DDS_id,f_osc*1e6,f_osc*1e6,1);   

%     AnalogFuncTo(calctime(curtime,-15),35,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,1.2,1); % Ramp FF to Rb trap beat-lock 
    setDigitalChannel(calctime(curtime,-10),25,1); % open Rb probe shutter
    setDigitalChannel(calctime(curtime,-10),24,1); % disable AOM rf (TTL), just to be sure
    RbF2_kill_time_list =[2]; 3;
    pulse_time = getScanParameter(RbF2_kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'RbF2_kill_time');
curtime = DigitalPulse(calctime(curtime,0), 'Rb Probe/OP TTL',pulse_time,0); % pulse beam with TTL   15
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); % close shutter
end
%% K RF 

% Pulse the K RF. We rely on a field ramp to sweep the states.

if seqdata.flags.xdt_spin_xfer_transfer_K
    % NOTE THAT THIS FREQUENCY COUPLES TO THE RB FIELD SWEEP    
    logNewSection('RF K Sweep 9-->-9',curtime);  
    
 

    if seqdata.flags.xdt_spin_xfer_transfer_Rb_freq_sweep   
         curtime = calctime(curtime,20);   % Wait for uWave switches to go to RF
    else
        setDigitalChannel(calctime(curtime,-20),'RF/uWave Transfer',0);   % 0: RF, 1: uwave   
        setDigitalChannel(calctime(curtime,-5),'RF TTL',0);               % RF OFF
    end
    setAnalogChannel(calctime(curtime,-10),'RF Gain',-10,1);       % Gain Set
    

    tsw = getVar('xdt_spin_xfer_K_time');

    DDS_ID=1;
    f1 = 1e6*(getVar('xdt_spin_xfer_K_freq')-getVar('xdt_spin_xfer_K_freq_amp'));
    f2 = 1e6*(getVar('xdt_spin_xfer_K_freq')+getVar('xdt_spin_xfer_K_freq_amp')); %( Don't actually sweep the frequency');
    dT=getVar('xdt_spin_xfer_K_time');                    % Duration of this sweep in ms

    % Add a DDS Sweep
    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1; 
    sweep=[DDS_ID f1 f2 dT];    % Sweep data;
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;       
    
    % Turn on RF some time after Rb
    pulseRF = 1;
    if pulseRF
        setDigitalChannel(calctime(curtime,0),'RF TTL',1);           % RF ON 
    end
    DigitalPulse(calctime(curtime,0),'DDS ADWIN Trigger',5,1);   % DDS Trigger
    
    setAnalogChannel(calctime(curtime,-10),'RF Gain',-10,1);       % Gain Set
    G = getVar('xdt_spin_xfer_K_gain'); % if you make this too high you will perturb Rb

    % Ramp Up Gain Smoothly
    tR = 2;
    curtime = AnalogFunc(calctime(curtime,0),'RF Gain',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tR,tR,-10,G,1); 
    curtime = calctime(curtime,tsw-2*tR); 
    curtime = AnalogFunc(calctime(curtime,0),'RF Gain',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tR,tR,G,-10,1); 
    
    setDigitalChannel(calctime(curtime,0),'RF TTL',0);           % RF OFF 
    setAnalogChannel(calctime(curtime,0),'RF Gain',-10);         % Gain Set
end


%% D1 Optical Pumping in ODT before evap!
if (seqdata.flags.xdt_d1op_start==1)
    logNewSection('D1 Optical Pumping pre op evap',curtime);  

    op_time_list = [5];
    optical_pump_time = getScanParameter(op_time_list, ...
    seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_time1','ms'); %optical pumping pulse length
    repump_power_list = [.2];
    repump_power =getScanParameter(repump_power_list,...
        seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_repump_pwr1','V'); %optical pumping repump power
    D1op_pwr_list = [.5]; %min: 0, max:1
    D1op_pwr = getScanParameter(D1op_pwr_list,...
        seqdata.scancycle, seqdata.randcyclelist, 'ODT_D1op_pwr1','V'); %optical power

    
    %Determine the requested frequency offset from zero-field resonance
    frequency_shift = (4)*2.4889;(4)*2.4889;
    Selection_Angle = 62.0;
    addOutputParam('Selection_Angle',Selection_Angle)

    %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
    Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to

    %Determine how much to turn on the X and Y shims to get this frequency
    %shift at the requested angle
    X_Shim_Value = frequency_shift * cosd(Selection_Angle) / Shim_Calibration_Values(1);
    Y_Shim_Value = frequency_shift * sind(Selection_Angle) / Shim_Calibration_Values(2);
    X_Shim_Offset = 0;
    Y_Shim_Offset = 0;
    Z_Shim_Offset = 0.055;0.055;

    %Ramp the magnetic fields so that we are spin-polarized.
    newramp = struct('ShimValues',seqdata.params.shim_zero + [X_Shim_Value+X_Shim_Offset, Y_Shim_Value+Y_Shim_Offset, Z_Shim_Offset],...
            'FeshValue',0.01,'QPValue',0,'SettlingTime',200);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);   

    % Close EIT Probe Shutter
    setDigitalChannel(calctime(curtime,-20),'EIT Shutter',0);
    
    % Break the thermal stabilzation of AOMs by turning them off
    setDigitalChannel(calctime(curtime,-10),'EIT Probe TTL',0);
    setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
    setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);    
    setAnalogChannel(calctime(curtime,-10),'D1 OP AM',D1op_pwr); 

%     
    % Open D1 shutter (FPUMP + OPT PUMP)
    setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1);%1: turn on laser; 0: turn off laser
        
    % Open optical pumping AOMS (allow light) and regulate F-pump
    setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
    setAnalogChannel(calctime(curtime,0),'F Pump',repump_power);
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
    
    %Optical pumping time
curtime = calctime(curtime,optical_pump_time);
    
    % Turn off OP before F-pump so atoms repumped back to -9/2.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);

    op_repump_extra_time = 2;
    % Close optical pumping AOMS (no light)
    setDigitalChannel(calctime(curtime,op_repump_extra_time),'F Pump TTL',1);%1
    setAnalogChannel(calctime(curtime,op_repump_extra_time),'F Pump',-1);%1
    setDigitalChannel(calctime(curtime,op_repump_extra_time),'FPump Direct',1);
    
    % Close D1 shutter shutter
    setDigitalChannel(calctime(curtime,5),'D1 Shutter', 0);%2
    
    %After optical pumping, turn on all AOMs for thermal stabilzation
    
    setDigitalChannel(calctime(curtime,10),'EIT Probe TTL',1);
    setDigitalChannel(calctime(curtime,10),'F Pump TTL',0);
%     setAnalogChannel(calctime(curtime,10),'D1 OP AM',10); 

curtime =  setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);    

clear('ramp');     

        % Ramp the bias fields
newramp = struct('ShimValues',seqdata.params.shim_zero,...
            'FeshValue',20,'QPValue',0,'SettlingTime',100);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);       

    curtime = calctime(curtime,50);
end

%% Hold after spin transfer
if  seqdata.flags.xdt_spin_xfer_hold_after
   curtime=calctime(curtime,getVar('xdt_hold_time'));
end

   % Ramp the FB Field
    %AnalogFuncTo(calctime(curtime,0),'FB Current',...
    %    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    %    50,50,19.5);   
    %curtime=calctime(curtime,50);
    
    
logNewSection('Ending spintransfer',curtime);
end


