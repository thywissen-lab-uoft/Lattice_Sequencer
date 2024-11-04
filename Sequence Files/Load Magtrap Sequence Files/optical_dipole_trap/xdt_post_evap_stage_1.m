function curtime = xdt_post_evap_stage_1(timein)

curtime = timein;
global seqdata;

%% AM Modulate Dipole Powers
% AM modulate the dipole trap powers to measure the trap depth. 
% CF : I dont recall ever using this? Kick measurements are likely easier.
% Also, it makes more sense to not modulate the requests because that
% requires the PID to follow. Use the modulation control directly on the
% regulation boxes

if seqdata.flags.xdt_am_modulate
    logNewSection('Modulate Dipole trap beam power',curtime);    

    % Oscillate with a sinuisoidal function
    dip_osc = @(t,freq,y2,y1)(y1 +y2*sin(2*pi*freq*t/1000));

    dip_osc_time = 500; 1000;       % Duration to modulate             

    dip_osc_offset = exp_end_pwr;   % CDT_rampup_pwr;
    dip_osc_amp = 0.05;             % Oscillation amplitude
    dip_osc_freq_list = [400:10:500 650];
    dip_osc_freq = getScanParameter(dip_osc_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'dip_osc_freq');

    % Modify time slightly to ensure complete cycles
    Ncycle = ceil((dip_osc_time*1E-3)*dip_osc_freq);
    dip_osc_time = 1E3*(Ncycle/dip_osc_freq);

    disp(['     Frequency (Hz) : ' num2str(dip_osc_freq)]);
    disp(['     Offset     (W) : ' num2str(dip_osc_offset)]);
    disp(['     Amplitude  (W) : ' num2str(dip_osc_amp)]);
    disp(['     Time      (ms) : ' num2str(dip_osc_time)]);                


    switch seqdata.flags.xdt_am_modulate
        case 1
            AnalogFunc(calctime(curtime,0),'dipoleTrap1',...
                    @(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),...
                    dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);
        case 2
            AnalogFunc(calctime(curtime,0),'dipoleTrap2',...
                  @(t,freq,y2,y1)(dip_osc(t,freq,y2,y1)),...
                  dip_osc_time,dip_osc_freq,dip_osc_amp,dip_osc_offset);   
        otherwise
            error('oh no')
    end 

    % Wait for modulation Time
    curtime=calctime(curtime,dip_osc_time);
    
    % Trigger the scope 
    DigitalPulse(curtime,'ScopeTrigger',10,1);

    % Wait time
    curtime = calctime(curtime,100);    
end

%% Remove Rb from XDT
% After optical evaporation, it is useful to only have K in the trap. Do
% this by pulsing resonant Rb light

if (seqdata.flags.xdt_kill_Rb_after_evap && seqdata.flags. CDT_evap == 1)

    %repump atoms from F=1 to F=2, and blow away these F=2 atoms with
    %the probe
    %open shutter
    %probe

    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %0=closed, 1=open
    %repump
    setDigitalChannel(calctime(curtime,-10),'Rb Sci Repump',1);
    %open analog
    %probe
    setAnalogChannel(calctime(curtime,-10),'Rb Probe/OP AM',0.7);
    %repump (keep off since no TTL)

    %set TTL
    %probe
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);
    %repump doesn't have one

    %set detuning (Make sure that the laser is not coming from OP
    %resonance... it will take ~75ms to reach the cycling transition)
    setAnalogChannel(calctime(curtime,-10),'Rb Beat Note FM',6590-237);

    % Rb Probe Detuning    
    % Not optimized!!
    f_osc = calcOffsetLockFreq(10,'Probe32');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,-10),DDS_id,f_osc*1e6,f_osc*1e6,1)    



    %pulse beam with TTL 
    %TTL probe pulse
    DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',5,0);
    %repump pulse
    setAnalogChannel(calctime(curtime,0),'Rb Repump AM',0.7);
curtime = setAnalogChannel(calctime(curtime,5),'Rb Repump AM',0.0);

    %close shutter
    setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); %0=closed, 1=open
curtime = setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0);

curtime=calctime(curtime,100);
end   

%% D1 Optical Pumping in ODT
% After optical evaporation, ensure mF spin polarization via D1 optical
% pumping.

if (seqdata.flags.xdt_d1op_end==1 && seqdata.flags.CDT_evap==1)
    logNewSection('D1 Optical Pumping post optical evaporation',curtime);  

    % optical pumping pulse length
    op_time_list = [5];[1]; %1
    optical_pump_time = getScanParameter(op_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_time2','ms');
    
    % optical pumping repump power
    repump_power_list = [0.2];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_repump_pwr2','V'); 
    
    %optical power
    D1op_pwr_list = [1]; %min: 0, max:1
    D1op_pwr = getScanParameter(D1op_pwr_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_D1op_pwr2','V'); 

    % fpump extra time
    op_repump_extra_time_list = [2];
    op_repump_extra_time = getScanParameter(op_repump_extra_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'ODT_op_time_extra2','ms');  
    
    % values
    op_after_options = struct;
    op_after_options.op_time = optical_pump_time;
    op_after_options.fpump_power = repump_power;
    op_after_options.d1op_power = D1op_pwr;
    op_after_options.fpump_extratime = op_repump_extra_time;    
    op_after_options.leave_on = 0;    
    
    % Perform optical pumping
    curtime = opticalpumpingD1(curtime,op_after_options);    
end        
    
%% Remix at end: Ensure a 50/50 mixture after spin-mixture evaporation

if (seqdata.flags.xdt_rfmix_end==1 && seqdata.flags.CDT_evap==1)      

    if ~seqdata.flags.xdt_d1op_end
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
    
        logNewSection('RF K Sweeps for -7,-9 mixture.',curtime);  

        %Do RF Sweep
        clear('sweep');
                
        
        rf_k_sweep_freqs = [5.995];
        % With delta_freq =0.1;
        % 3.01 --> (-7,-5) (a little -9)
        % 3.07 --> (-1,+1,+3); 
        rf_k_sweep_center = getScanParameter(rf_k_sweep_freqs,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_freq_post_evap','MHz');
        
        sweep_pars.freq=rf_k_sweep_center;    
        
        sweep_pars.power =-5; -8.5;      
        delta_freq_list =-.01;[0.0040];%0.006; 0.01
        
        
        sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_post_evap','MHz');
        pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
        
        sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_post_evap','ms');
                
        disp(['     Center Freq (MHz) : ' num2str(sweep_pars.freq)]);
        disp(['     Delta Freq  (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp(['     Power         (V) : ' num2str(sweep_pars.power)]);
        disp(['     Sweep time   (ms) : ' num2str(sweep_pars.pulse_length)]);          
        
        f1=sweep_pars.freq-sweep_pars.delta_freq/2;
        f2=sweep_pars.freq+sweep_pars.delta_freq/2;
        
        n_sweeps_mix_list=[10];
        n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
            seqdata.scancycle,seqdata.randcyclelist,'n_sweeps_mix');  % also is sweep length  0.5               
        T60=16.666; % 60 Hz period        
        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-30);
            ACync_end_time = calctime(curtime,(sweep_pars.pulse_length+T60)*n_sweeps_mix+30);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
        
        %%%%%%%%%% Manual specification %%%%%%%%%%%%%%
                % DDS Trigger Settings
%         dTP=0.1;        % Pulse duration
%         DDS_ID=1;       % DDS ID
        % Pre-set RF gain and TTL state
%         setAnalogChannel(calctime(curtime,-35),'RF Gain',sweep_pars.power); 
%         setDigitalChannel(calctime(curtime,-35),'RF TTL',0);        
%         for kk=1:n_sweeps_mix        
%             disp([' Sweep Number ' num2str(kk) ]);
% 
%             % Define a frequency sweep        
%             sweep=[DDS_ID 1E6*f1 1E6*f2 sweep_pars.pulse_length];     
%             seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
%             seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;          
%             
%             % Trigger DDS
%             DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
%             
%             % Enable the RF
%             DigitalPulse(curtime,'RF TTL',sweep_pars.pulse_length,1);  
% 
%             % Advance time by 60 Hz period
%             curtime=calctime(curtime,T60);        
%         end        
%         setAnalogChannel(calctime(curtime,1),'RF Gain',-10);         
                 
        %%%%%%%%%% Automatic specification %%%%%%%%%%%%%%
        for kk=1:n_sweeps_mix
            disp([' Sweep Number ' num2str(kk) ]);
            rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
            curtime = calctime(curtime,T60);
        end      
curtime = calctime(curtime,10);

end

%% uWave_K_Spectroscopy
if (seqdata.flags.xdt_uWave_K_Spectroscopy)
    logNewSection('uWave_K_Spectroscopy',curtime);      
%     
    % FB coil settings
    ramp=struct;
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 20;
    ramp.settling_time = 200;

    disp('Ramping fields');
    disp(['     Field         (G) : ' num2str(ramp.fesh_final)]);
    disp(['     Ramp Time    (ms) : ' num2str(ramp.fesh_ramptime)]);

    % Ramp the bias fields
    curtime = ramp_bias_fields(calctime(curtime,0), ramp);   
    
    % Frequency
    freq_shift_list = [5]; % Offset in kHz
    f0 = 1335.811;         % MHz

    uwave_freq_shift = getScanParameter(freq_shift_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_freq_shift','kHz');    
    uwave_freq = uwave_freq_shift/1000 + f0;
    
    addOutputParam('uWave_freq',uwave_freq,'MHz');
    
    % Frequency Shift
    % Only used for sweep spectroscopy
    uwave_delta_freq_list = [200];
    uwave_delta_freq=getScanParameter(uwave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq','kHz');
        
    % Time
    uwave_time_list = [30];
    uwave_time = getScanParameter(uwave_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_time','ms');    
    
    % Power
    uwave_power_list = [15];
    uwave_power = getScanParameter(uwave_power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uWave_power','dBm');  
        
    % Spetroscopy parameters
    spec_pars = struct;
    spec_pars.Mode='sweep_frequency_chirp';
    spec_pars.use_ACSync = 0;
    spec_pars.PulseTime = uwave_time;
    
    spec_pars.FREQ = uwave_freq;                % Center in MHz
    spec_pars.FDEV = (uwave_delta_freq/2)/1000; % Amplitude in MHz
    spec_pars.AMPR = uwave_power;               % Power in dBm
    spec_pars.ENBR = 1;                         % Enable N Type
    spec_pars.GPIB = 30;                        % SRS GPIB Address    
    
    % Do you sweep back after a variable hold time?
    spec_pars.doSweepBack = 0;
    uwave_hold_time_list = [10];
    uwave_hold_time  = getScanParameter(uwave_hold_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'hold_time','ms');     
    spec_pars.HoldTime = uwave_hold_time;
        
    curtime = K_uWave_Spectroscopy(curtime,spec_pars);    
end

%% Get rid of F = 7/2 K using a repump pulse

if (seqdata.flags.xdt_kill_K7_after_evap && seqdata.flags.CDT_evap == 1)
    
    % optical pumping pulse length
    repump_pulse_time_list = [10];
    repump_pulse_time = getScanParameter(repump_pulse_time_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_time2','ms');
    
    % optical pumping repump power
    repump_power_list = [0.7];
    repump_power =getScanParameter(repump_power_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'kill7_power2','V');     
    
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


%% RF Rabi Oscillation

if (seqdata.flags.xdt_k_rf_rabi_oscillation)      
    logNewSection('RF K Rabi Oscillations',curtime);  

    do_ramp_field=1;
    if do_ramp_field
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

    % RF Frequency
    rf_k_freqs=[3.0495];%3.048 [1.8353];3.01;
    rf_k_freq = getScanParameter(rf_k_freqs,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_freq');
    
    % Time for pulse
    pulse_length_list = [.1:.1:1];
    pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_time');
    
    % RF Power
    rf_power_list = [-9];
    rf_power = getScanParameter(rf_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_rabi_power');   
    
    rabi_pars=struct;
    rabi_pars.delta_freq   = 0;
    rabi_pars.freq         = rf_k_freq;        
    rabi_pars.power        = rf_power;     
    rabi_pars.pulse_length = pulse_length;

    disp(['     Freq (MHz) : ' num2str(rabi_pars.freq)]);
    disp(['     Power         (V) : ' num2str(rabi_pars.power)]);
    disp(['     Time   (ms) : ' num2str(rabi_pars.pulse_length)]);  

    do_ACync_rf = 1;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-30);
        ACync_end_time = calctime(curtime,rabi_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end

    % Set source to RF
    setDigitalChannel(calctime(curtime,-35),'RF/uWave Transfer',0);   
    
    % Make sure RF is off
    setDigitalChannel(calctime(curtime,-35),'RF TTL',0);   
    
    % Preset RF Gain
    setAnalogChannel(calctime(curtime,-35),'RF Gain',rabi_pars.power);   
            

    % Trigger pulse duration
    dTP=0.1;
    DDS_ID=1;                
        
    % Primary Sweep, constant power            
    sweep=[DDS_ID 1E6*rabi_pars.freq 1E6*rabi_pars.freq rabi_pars.pulse_length+20];    
    DigitalPulse(calctime(curtime,-10),'DDS ADWIN Trigger',dTP,1);      
    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;        
    
    % Pulse the RF
    setDigitalChannel(curtime,'RF TTL',1);         
curtime=calctime(curtime,rabi_pars.pulse_length);            
    setDigitalChannel(curtime,'RF TTL',0); 
    
    % Reset RF power to low
    setAnalogChannel(calctime(curtime,10),'RF Gain',-10);       
    
    
%     curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
%     curtime = calctime(curtime,30);
end


    %% Kick the dipole trap
    %RHYS - An alterative way to measure trap frequency using a piezo mirror to
    %give the atoms a kick. 
    if seqdata.flags.xdt_do_dipole_trap_kick
        logNewSection('Kicking the dipole trap',curtime);
        %How Long to Wait After Kick
        kick_ramp_time = 100;
        curtime = calctime(curtime, kick_ramp_time+20);
        kick_voltage = 10;
        time_list = [0:0.75:15];
        kick_wait_time =getScanParameter(time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = getScanParameter(time_list,seqdata.scancycle,seqdata.randcyclelist,'kick_wait_time');
        %kick_wait_time = 0;
        %addOutputparam('kick_wait_time',kick_wait_time);
       
        kick_channel=54;
    
        %Ramp the Piezo Mirror to a Displaced Position
        AnalogFuncTo(calctime(curtime,-kick_ramp_time),kick_channel,...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),kick_ramp_time,kick_ramp_time,kick_voltage);

        %Jump the Piezo Mirror Back to Trap Geometry
        setAnalogChannel(curtime,kick_channel,0,1);

%         %Turn off the ODT1 to measure ODT2 trap frequency only
%         setAnalogChannel(curtime,'dipoleTrap1',-1); 

        %Piezo mirror is reset to 0 at the beginning of Load_MagTrap_Sequence
    end
  
 
    %% Keep XDT On for Some Time
    %RHYS - Either hold for some time after using dipole trap kick, or just
    %holds a bit in general. The one second hold time seems useful for loading
    %the lattice as it gives the rotating waveplate time to turn before the
    %lattice turns on.
    if seqdata.flags.xdt_do_dipole_trap_kick
        curtime = calctime(curtime,kick_wait_time);
    else
        % Why is this hold time here?
        exxdthold_list= [100];100;
        exxdthold = getScanParameter(exxdthold_list,...
            seqdata.scancycle,seqdata.randcyclelist,'exxdthold','ms');
        curtime=calctime(curtime,exxdthold);%for sparse image
    end
    
    
%% Ramp FB field up before loading lattice

% Before loading the lattices, it is sometimes useful to control the
% magnetic field to establish the interaction (attractive versus repulsive)
% during the loading. Attractive interactions tend to create a larger
% number of doubly occupied sites.
if seqdata.flags.xdt_ramp_up_FB_for_lattice     
    seqdata.params.time_in_HF = curtime;
    Lattice_loading_field_list =[207];
    Lattice_loading_field = getScanParameter(Lattice_loading_field_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Lattice_loading_field','G');

    % Coarse initial ramp to 195 G
    clear('ramp');
    ramp.fesh_ramptime = 150;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 195;
    ramp.settling_time = 100;
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    
    % Secondary ramp to final field
    clear('ramp');
    ramp.fesh_ramptime = 2;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = Lattice_loading_field;
    ramp.settling_time = 50;
    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
end
    
%% Dipole Trap High Field Operations 1
% Perform operations in the dipole trap at high magnetic field.

if (seqdata.flags.xdt_high_field_a)    
    logNewSection('Dipole Trap High Field a',curtime);
    curtime = dipole_high_field_a(curtime);  
end
     
%% Ramp Feshbach and QP Coils
% To characerize field gradients, it is useful to ramp the FB and QP coils
% at the end of evaporation. Strong field gradients kick atoms out of the
% trap. And a "round trip" magnetic field ramp tests this.
if seqdata.flags.xdt_ramp_QP_FB_and_back
    logNewSection('Ramping Fields Up and Down',curtime);

    % Feshvalue to ramp to
    HF_FeshValue_Initial_List =[195];
    HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_Fesh_RampUpDown','G');    

    clear('ramp');       
    doRampQPPre=1;
   if doRampQPPre
    % QP Value to ramp to
    HF_QP_List =  [0.117];.14;0.115;
    HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'LF_QPReverse','V');  

    % Ramp C16 and C15 to off values
    pre_ramp_time = 100;
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 

    curtime = calctime(curtime,50);
    % Turn off 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',0); 
    curtime = calctime(curtime,10);

    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage
    QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        100,100,QP_FFValue);
    curtime = calctime(curtime,50);

    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 
   end

       % Ramp the Feshbach Coils.
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = -0;   
    ramp.FeshValue = HF_FeshValue_Initial;
    ramp.SettlingTime = 50; 


    disp(['     Ramp Time     (ms) : ' num2str(ramp.FeshRampTime)]);
    disp(['     Settling Time (ms) : ' num2str(ramp.SettlingTime)]);
    disp(['     Fesh Value     (G) : ' num2str(ramp.FeshValue)]);

curtime = rampMagneticFields(calctime(curtime,0), ramp);

    wait_time = 5000;
curtime = calctime(curtime,wait_time);

    clear('ramp');
    % Ramp Back to original values
    ramp.SettlingTime = 50;
    
    % Feshbach Ramp
    ramp.FeshRampTime = 150;
    ramp.FeshRampDelay = 0;   
    ramp.FeshValue = 20;
    
%     % Ramp the QP Coils off
%     ramp.QPRampTime = ramp.FeshRampTime;
%     
%     if doRampQPNormal
%         ramp.QPReverse = 0;
%         ramp.QPValue = 0;  
%     end
    
    curtime = rampMagneticFields(calctime(curtime,0), ramp);
%     
    if doRampQPPre
%         curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0.062,1);  
             curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1); 
        
        curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            5,5,0);   
    end
%     
%     % Go back to "normal" configuration
%     curtime = calctime(curtime,10);
%     % Turn off reverse QP switch
%     setDigitalChannel(curtime,'Reverse QP Switch',0);
%     curtime = calctime(curtime,10);
% 
%     % Turn on 15/16 switch
%     setDigitalChannel(curtime,'15/16 Switch',1);
%     curtime = calctime(curtime,10);
% 


end

%% Unlevitate
if seqdata.flags.xdt_unlevitate_evap 
    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1); 
    curtime = calctime(curtime,100);
end


%% XDT Hold

if seqdata.flags.xdt_do_hold_end 
    logNewSection('Holding XDT at End',curtime);
    xdt_wait_time_list = [10000];
    xdt_wait_time = getScanParameter(xdt_wait_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'xdt_wait_time','ms');   
    curtime = calctime(curtime,xdt_wait_time);
end
%% The End!

timeout = curtime;
logNewSection('Dipole Transfer complete',curtime);
end

