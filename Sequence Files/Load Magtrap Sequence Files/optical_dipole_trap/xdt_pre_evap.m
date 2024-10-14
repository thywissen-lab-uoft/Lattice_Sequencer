function [curtime, I_QP, V_QP,I_shim] = xdt_pre_evap(timein, I_QP, V_QP,I_shim)
%%
curtime = timein;
global seqdata;

ScopeTriggerPulse(curtime,'xdt load');
%% Rb uWave 1 SWEEP FESHBACH FIELD
%Pre-ramp the field to 20G for transfer
if ( seqdata.flags.xdt_Rb_21uwave_sweep_field)      
    dispLineStr('uWave Rb 2-->1',curtime);    
    init_ramp_fields = 1; % Ramp field to starting value?
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Program the SRS
    %%%%%%%%%%%%%%%%%%%%%%%
    % Not currently used
    % Use this code if using the SRS (inSstead of the Anritsu) to
    % transfer atoms

    Rb_SRS=struct;
    Rb_SRS.Address=29;        % GPIB address of the Rb SRS        
    Rb_SRS_list = [0]; %in MHz
    Rb_SRS_det = getScanParameter(Rb_SRS_list,seqdata.scancycle,...
        seqdata.randcyclelist,'Rb_SRS_det');
    Rb_SRS.Frequency=6.87560 + Rb_SRS_det/1000; % Frequency in GHz
    Rb_SRS.Power=8;%8           % Power in dBm (Don't go too high)
    Rb_SRS.Enable=1;          % Whether to enable 
    Rb_SRS.EnableSweep=0;        
%    programSRS_Rb(Rb_SRS);          

    %%%%%%%%%%%%%%%%%%%%%%%%
    % Field Sweep settings
    %%%%%%%%%%%%%%%%%%%%%%%        
    % Center feshbach field
    mean_field_list =19.357;
    mean_field = getScanParameter(mean_field_list,seqdata.scancycle,...
        seqdata.randcyclelist,'Rb_Transfer_Field','G');

    % Total field sweep range
    del_fesh_current = 0.2;1;%0.10431;% before 2017-1-6 0.1; %0.1        
    addOutputParam('del_fesh_current',del_fesh_current,'G')
    
    % NOTE THAT THIS FIELD SWEEP AFFECTS TO THE K FREQ SWEEP

    %%%%%%%%%%%%%%%%%%%%%%%%
    % INITIALIZING FIELD RAMP : (mean field + delta/2)
    %%%%%%%%%%%%%%%%%%%%%%%
    if init_ramp_fields         
        clear('ramp');
        shim_ramptime_list = [2];
        shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
               
        getChannelValue(seqdata,'X Shim',1,0);
        getChannelValue(seqdata,'Y Shim',1,0);
        getChannelValue(seqdata,'Z Shim',1,0);
        % Ramp shims to the zero condition
        ramp = struct;
        ramp.shim_ramptime = shim_ramptime;
        ramp.shim_ramp_delay = 0; 
        ramp.xshim_final = seqdata.params.shim_zero(1); %0.146
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);        
        % Ramp FB to initial magnetic field
        fb_ramp_time = 50;
        ramp.fesh_ramptime = fb_ramp_time;
        ramp.fesh_ramp_delay = 0;        
        ramp.fesh_final = mean_field+del_fesh_current/2; %22.6        
        
        ramp.settling_time = 50;
        disp('Ramping the feshbach field to initial value.');

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end

    %%%%%%%%%%%%%%%%%%%%%%%%
    % uWave with Field sweep
    %%%%%%%%%%%%%%%%%%%%%%%
    % Send scope trigger
    ScopeTriggerPulse(curtime,'Rb uwave transfer');

    % Use Anritsu Source
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',0); %0 = Anritsu, 1 = Sextupler

    % Set the field sweep time
    % Anritsu needs a bit longer (100 ms).
    uWave_sweep_time_list = [100];100;60;
    uWave_sweep_time = getScanParameter(uWave_sweep_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uWave_sweep_time','ms');

    % No idea what this does
    uWave_pulse_freq = 21.52;

    % Pulse uWave during the field sweep
    do_uwave_pulse(calctime(curtime,0), 0, uWave_pulse_freq*1E6, uWave_sweep_time,0);

    % Ramp the FB field
curtime  =  AnalogFuncTo(calctime(curtime,0),'FB current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        uWave_sweep_time,uWave_sweep_time,mean_field-del_fesh_current/2);
 
    % Switch Rb microwave source to Sextupled SRS for whatever follows
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler   
    curtime = calctime(curtime,10); % wait for switches to change
end 

%% Rb uWave transfer 3 - Sweep the uWave to transfer Rb
% This section of code transfer the Rb cloud from the |2,2> to the |1,1>
% state using a uWave frequency sweep.
if ( seqdata.flags.xdt_Rb_21uwave_sweep_freq)
    % Ramp the field to the desired value
    dispLineStr('Field Ramp for RF/uWave Transfer',curtime);        

    % F=2 Rb Blow Away
    do_F2_blowaway=1;
    
    %%%%%%%%%%%%%%%%%%%%
    % Field Ramp 
    %%%%%%%%%%%%%%%%%%%%
    % Ramp the shims and FB current to the desired transfer field
    
    mean_field_list = 19.332;
    mean_field = getScanParameter(mean_field_list,seqdata.scancycle,seqdata.randcyclelist,'Rb_Transfer_Field');
       
    shim_ramptime_list = [2];
    shim_ramptime = getScanParameter(shim_ramptime_list,seqdata.scancycle,seqdata.randcyclelist,'shim_ramptime');
  
    % Initialzie Field Ramp
    clear('ramp');
    ramp=struct;
    
    % Shim ramp settings
    ramp.xshim_final = seqdata.params.shim_zero(1);
    ramp.yshim_final = seqdata.params.shim_zero(2);
    ramp.zshim_final = seqdata.params.shim_zero(3);    
    ramp.shim_ramptime = shim_ramptime;
    ramp.shim_ramp_delay = 0; % ramp earlier than FB field if FB field is ramped to zero
   
    % Feshbach Ramp settings
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = 0;
    ramp.fesh_final = mean_field;    
    ramp.settling_time = 50;
    
    disp(['     FB Current (Gauss) : ' num2str(ramp.fesh_final)]);
    disp(['     Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp(['     Settling Time (ms) : ' num2str(ramp.settling_time)]);

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
       
    %%%%%%%%%%%%%%%%%%%%
    % uWave Sweeep Prepare
    %%%%%%%%%%%%%%%%%%%%
%     use_ACSync=0;    
    dispLineStr('Sweeping uWave Rb 2-->1',curtime);   
    
    % uWave Center Frequency
    freq_list = [-0.125];
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rb_uwave_freq_offset','MHz');    
    
    uWave_delta_freq_list=[0.05];
    uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_delta_freq','MHz');
        
    uwave_sweep_time_list =[10]; 
    sweep_time = getScanParameter(uwave_sweep_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rb_uwave_sweep_time','ms');   
     
    Rb_SRS=struct;
    Rb_SRS.Address=29;        % GPIB address of the Rb SRS    
    Rb_SRS.Frequency=6.87560+freq_offset*1E-3; % Frequency in GHz
    Rb_SRS.Frequency=6.83465+2.11*1E-3*mean_field+freq_offset*1E-3; % Frequency in GHz 

    Rb_SRS.Power=9;           % Power in dBm 
    Rb_SRS.Enable=1;          % Power on
    Rb_SRS.EnableSweep=1;     % Sweep on     
    Rb_SRS.SweepRange=uWave_delta_freq; % Sweep range in MHz   
             
    addOutputParam('rb_uwave_pwr',Rb_SRS.Power,'dBm')
    addOutputParam('rb_uwave_frequency',Rb_SRS.Frequency,'GHz');            
    
    disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);
    disp(['     Sweep Range  : ' num2str(uWave_delta_freq) ' MHz']);
    disp(['     Freq Offset  : ' num2str(freq_offset) ' MHz']);     
    
    % Program the SRS    
    programSRS_Rb(Rb_SRS);      
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-35),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-35),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-35),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave) for Rb (1)
    setDigitalChannel(calctime(curtime,-30),'RF/uWave Transfer',1); 
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',1); 
    setDigitalChannel(calctime(curtime,-35),'Rb Source Transfer',0); %0 = SRS, 1 = Sextupler

    % Set initial modulation
    setAnalogChannel(calctime(curtime,-35),'uWave FM/AM',-1);    
    
    %%%%%%%%%%%%%%%%%%%%
    % uWave Sweeep 
    %%%%%%%%%%%%%%%%%%%%           
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',1);      % Turn on uWave 
    AnalogFunc(calctime(curtime,0),'uWave FM/AM',...              % Ramp +-1V
        @(t,T) -1+2*t/T,sweep_time,sweep_time);
    curtime = calctime(curtime,sweep_time);                       % Wait
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);      % Turn off uWave
    
    % Reset the uWave deviation after a while
    setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);  
    
    % Pulse F=2 to kill untransfered Rb (OUT OF DATE - NEEDS TO BE UPDATED)
%     if do_F2_blowaway
%         disp('Blowing the F=2 away');
%         %wait a bit before pulse
%         setAnalogChannel(calctime(curtime,-10),4,0.0); % set amplitude   0.7
%         AnalogFuncTo(calctime(curtime,-15),34,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,6590-237); % Ramp Rb trap laser to resonance   237
% %         AnalogFuncTo(calctime(curtime,-15),35,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,1.2,1); % Ramp FF to Rb trap beat-lock 
%         setDigitalChannel(calctime(curtime,-10),25,1); % open Rb probe shutter
%         setDigitalChannel(calctime(curtime,-10),24,1); % disable AOM rf (TTL), just to be sure
%         RbF2_kill_time_list =[1]; 3;
%         pulse_time = getScanParameter(RbF2_kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'RbF2_kill_time');
% curtime = DigitalPulse(calctime(curtime,0),24,pulse_time,0); % pulse beam with TTL   15
%         setDigitalChannel(calctime(curtime,0),25,0); % close shutter
%         
%         disp(['     Pulse Time (ms) : ' num2str(pulse_time)]);
%     end 
    
    % Extra wait a little bit
    time_list = [0];
    wait_time =  getScanParameter(time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'uwave_rf_hold_time','ms');
curtime = calctime(curtime,wait_time);
end 
  

%% Rb F=2 Blow Away

if seqdata.flags.xdt_Rb_2_kill
    dispLineStr('Blowing Rb F=2 away',curtime);
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
curtime = DigitalPulse(calctime(curtime,0),24,pulse_time,0); % pulse beam with TTL   15
       setDigitalChannel(calctime(curtime,0),25,0); % close shutter
end

%% 40K RF Sweep Init
%Sweep 40K to |9/2,-9/2> before optical evaporation   
if seqdata.flags.xdt_K_p2n_rf_sweep_freq
    % NOTE THAT THIS FREQUENCY COUPLES TO THE RB FIELD SWEEP
    
    dispLineStr('RF K Sweep 9-->-9',curtime);       
 
    % Avoid feshbach ramps to minimize time in bad spin combinations
    disp(' Applying RF sweep to transfer K state.');
    fesh_value = getChannelValue(seqdata,'FB current',1,0);    
    disp(['Feshbach Value : ' num2str(fesh_value)]);

    % RF Sweep Settings
    k_rf_freq_list = 6.1;[6.05];
    k_rf_pulsetime_list = [100];100;
    k_rf_power_list = [-3];
    k_rf_delta_list=[-1];[-1.2];[-1];-0.5;   
    
    clear('sweep');
    sweep=struct;
    sweep_pars.freq = getScanParameter(k_rf_freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'k_rftransfer_freq','MHz'); 
    sweep_pars.power = getScanParameter(k_rf_power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'k_rftransfer_power','V'); 
    sweep_pars.pulse_length = getScanParameter(k_rf_pulsetime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_pulsetime','ms');
    sweep_pars.delta_freq = getScanParameter(k_rf_delta_list,...
        seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_delta','MHz');        
    sweep_pars.fake_pulse = 0;      %Fake the pulse (for debugging)         
    disp(['     Center Freq     (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq      (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Sweep time       (ms) : ' num2str(sweep_pars.pulse_length)]);
    disp(['     Sweep Rate   (kHz/ms) : ' num2str(1E3*sweep_pars.delta_freq./sweep_pars.pulse_length)]);

    % Apply the RF      
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars); 
curtime = calctime(curtime,5);

end

%% Kill F=7/2 in ODT before evap
if (seqdata.flags.xdt_kill_K7_before_evap)
    
    % optical pumping pulse length
    repump_pulse_time_list = [1];
    repump_pulse_time = getScanParameter(repump_pulse_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_time1','ms');
    
    % optical pumping repump power
    repump_power_list = [0.7];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_power1','V');     
    
curtime = calctime(curtime,10);

    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),'K Repump Shutter',1);  
    
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),'K Repump AM',repump_power);

    %repump TTL
    curtime = DigitalPulse(calctime(curtime,0),'K Repump TTL',repump_pulse_time,0); 

    %Close Repump Shutter
    setDigitalChannel(calctime(curtime,0),'K Repump Shutter',0);
    
    %turn repump back down
    setAnalogChannel(calctime(curtime,0),'K Repump AM',0.0);
end
    
%% D1 Optical Pumping in ODT before evap!
if (seqdata.flags.xdt_d1op_start==1)
    dispLineStr('D1 Optical Pumping pre op evap',curtime);  

    op_time_list = [5];
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_time1','ms'); %optical pumping pulse length
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_op_repump_pwr1','V'); %optical pumping repump power
    D1op_pwr_list = [1]; %min: 0, max:11
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle, seqdata.randcyclelist, 'ODT_D1op_pwr1','V'); %optical power

    
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

%% Spin mixture after Optical Pumping
if seqdata.flags.xdt_rfmix_start
    dispLineStr('RF K Sweeps for -7,-9 mixture.',curtime);  

    if ~seqdata.flags.xdt_d1op_start
        disp(' Ramping the magnetic field');
        % FB coil settings
        ramp=struct;
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 20;
        ramp.settling_time = 50;

        disp('Ramping fields');
        disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
        disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

        % Ramp the bias fields
        curtime = ramp_bias_fields(calctime(curtime,0), ramp);            
    end    

    %Do RF Sweep
    clear('sweep');
    rf_k_sweep_freqs = [5.995];[5.995];
    % With delta_freq =0.1;
    % 3.01 --> (-7,-5) (a little -9)
    % 3.07 --> (-1,+1,+3); 
    rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_pre_evap');

    sweep_pars.freq=rf_k_sweep_center;
    
    rf_power_list = [-9];-9.2;
    sweep_pars.power = getScanParameter(rf_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_power_pre_evap'); 

    delta_freq_list = -1*[0.008];[0.01];%0.006; 0.01
    sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_pre_evap');
    pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
    sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_pre_evap');

    n_sweeps_mix_list=[17];11
    n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
        seqdata.scancycle,seqdata.randcyclelist,'n_sweeps_mix');  % also is sweep length  0.5               

    
    disp(['     Center Freq      (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq       (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Power              (V) : ' num2str(sweep_pars.power)]);
    disp(['     Sweep time        (ms) : ' num2str(sweep_pars.pulse_length)]);  
    disp(['     Num Sweeps             : ' num2str(n_sweeps_mix)]);  


    f1=sweep_pars.freq-sweep_pars.delta_freq/2;
    f2=sweep_pars.freq+sweep_pars.delta_freq/2;
    
ScopeTriggerPulse(curtime,'40k 97 mixing');


    T60=16.666; % 60 Hz period
    % 2023/04/04 disconnected from ACync for uwave
    do_ACync_rf = 0;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-30);
        ACync_end_time = calctime(curtime,(sweep_pars.pulse_length+T60)*n_sweeps_mix+15);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
    
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
%         disp([' Sweep Number ' num2str(kk) ]);
        rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        curtime = calctime(curtime,T60);
    end     
    curtime = calctime(curtime,15);
end

end

