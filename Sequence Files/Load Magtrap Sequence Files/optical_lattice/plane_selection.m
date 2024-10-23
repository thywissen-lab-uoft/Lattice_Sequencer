function [curtime] = plane_selection(timein,override)
global seqdata

if nargin == 0;timein = 10;end
curtime = timein;

%% Flags
opts = struct; 

opts.ramp_field_CF  = 1;                    % New field ramps
opts.dotilt = seqdata.flags.plane_selection_dotilt;
opts.useFeedback = seqdata.flags.plane_selection_useFeedback;

opts.planeselect_doVertKill = seqdata.flags.plane_selection_doKill;            % apply optical kill pulse


opts.douWave= seqdata.flags.plane_selection_douWave;

opts.fake_the_plane_selection_sweep = 0;    % Whether or not to apply uwaves
opts.planeselect_doMicrowaveBack = 0;       % uwave transfer back to F=9/2 (uneeded?)
opts.planeselect_doFinalRepumpPulse = 0;    % apply repump to kill leftover F=7/2 (uneeded?)
opts.planeselect_again = 0;                 % Repeat plane selection (does this actually help?)




% opts.SelectMode     = 'SweepFreqHS1';       % Sweep SRS HS1 frequency

opts.SelectMode = 'SweepFreqSmoothLinear';

opts.SelectModeBack = 'SweepFreqHS1';       %Sweep SRS HS1 frequency backwards

opts.use_ACSync = 1;                        % ACync 60 Hz
opts.doProgram = 1;                         % Program the SRS?

%% Overides

if nargin == 2
    fnames = fieldnames(override);
    for kk=1:length(fnames)
        opts.(fnames{kk}) = override.(fnames{kk});
    end
end    

%% Trigger labjack

    trigger_offset = -200;
    trigger_length = 50;
    
    if strcmp(seqdata.labjack_trigger,'Plane selection')
        DigitalPulse(calctime(curtime,trigger_offset-trigger_length),...
            'LabJack Trigger Transport',trigger_length,1);      
        DigitalPulse(calctime(curtime,1000),...
            'LabJack Trigger Transport',trigger_length,1);
    end
    
    
%% Prepare Switches for uWave Radiation

disp('Changing switches so that uwave are on');

% Make sure RF, Rb uWave, K uWave are all off for safety
setDigitalChannel(calctime(curtime,0),'RF TTL',0);
setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);

% Switch antenna to uWaves (0: RF, 1: uWave)
setDigitalChannel(calctime(curtime,10),'RF/uWave Transfer',1); 

% Switch uWave source to the K sources (0: K, 1: Rb);
setDigitalChannel(calctime(curtime,20),'K/Rb uWave Transfer',0);

% RF Switch for K SRS depreciated? (1:B, 0:A)
% Warning : may need to check the RF diagram for this to be correct
setDigitalChannel(calctime(curtime,25),'K uWave Source',1); 

% For SRS GPIB 30
setDigitalChannel(calctime(curtime,25),'SRS Source',1);  
        
% For SRS GPIB 29
% setDigitalChannel(calctime(curtime,25),'SRS Source post spec',1);
% setDigitalChannel(calctime(curtime,25),'SRS Source',0);

% Wait for switches to finish
curtime = calctime(curtime,30);

ScopeTriggerPulse(curtime,'Plane Select');

%% Magnetic Field Ramps 2
if opts.ramp_field_CF
    
    % Transport Feedforward Settings
    defVar('qgm_pselect_FF',56.5,'V');56.5;
    defVar('qgm_pselect_FF_ramp_time',135,'ms');

    % Timings
    defVar('qgm_pselect_ramp_time',150,'ms')
    defVar('qgm_pselect_settle_time',250,'ms');
    
    % QP Coils Current Settings
%     defVar('qgm_pselect_QP',38.9200,'A');
    defVar('qgm_pselect_QP',78,'A');
    func_qp = 2; % voltage function
    
    % Feshbach Coil Current Settings
%     defVar('qgm_pselect_FB',123.9684,'G');
    defVar('qgm_pselect_FB',123.9684,'G');
    func_fb = 2;   % voltage function  
    
    % Shim Setting
    func_x = 3; func_y = 4; func_z = 3;
%     dIx0 = -3.55;
%     dIy0 = -0.1510;
%     dIz0 = 0;         
%     
%     Ix = dIx0 + seqdata.params.shim_zero(1);
%     Iy = dIy0 + seqdata.params.shim_zero(2);
%     Iz = dIz0 + seqdata.params.shim_zero(3);  
          
        
    % Turn off Z shim (this is for using the big shim for Z)
    setDigitalChannel(calctime(curtime,0),'Z shim bipolar relay',0);
    if opts.dotilt           
        defVar('qgm_plane_tilt_dIx',[-1.8],'A');-1.85;
        defVar('qgm_plane_tilt_dIy',[3.9],'A');2;
        defVar('qgm_plane_tilt_dIz',0.0,'A');0;      
        Ix = seqdata.params.shim_zero(1) + getVar('qgm_plane_tilt_dIx');
        Iy = seqdata.params.shim_zero(2) + getVar('qgm_plane_tilt_dIy');
        Iz = seqdata.params.shim_zero(3) + getVar('qgm_plane_tilt_dIz');  
        disp('tilting');
    else
        disp('no tilt');

        % Sept 2024 calibration
        defVar('qgm_plane_notilt_dIx',[-1.7],'A');        
        x = [-3 -4.5];
        y = [-0.5 -0.55];               
        defVar('qgm_plane_notilt_dIy',interp1(x,y,getVar('qgm_plane_notilt_dIx'),'linear','extrap'),'A');   
        
        defVar('qgm_plane_notilt_dIz',0.0,'A');0;      
        Ix = seqdata.params.shim_zero(1) + getVar('qgm_plane_notilt_dIx');
        Iy = seqdata.params.shim_zero(2) + getVar('qgm_plane_notilt_dIy');
        Iz = seqdata.params.shim_zero(3) + getVar('qgm_plane_notilt_dIz');  
    end  
    
    Vff = getVar('qgm_pselect_FF');
    Tff = getVar('qgm_pselect_FF_ramp_time');
    IQP = getVar('qgm_pselect_QP');
    BFB = getVar('qgm_pselect_FB');
    Tr  = getVar('qgm_pselect_ramp_time');
    Ts  = getVar('qgm_pselect_settle_time'); 
    
    dispLineStr('Ramping Fields CF', curtime);
    val_FF = getChannelValue(seqdata,'Transport FF',1);
    val_16 = getChannelValue(seqdata,'Coil 16',1);
    val_FB = getChannelValue(seqdata,'FB Current',1);
    val_X = getChannelValue(seqdata,'X Shim',1);
    val_Y = getChannelValue(seqdata,'Y Shim',1);
    val_Z = getChannelValue(seqdata,'Z Shim',1);

    % Ramp up transport feedforward
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tff, Tff, Vff,2);    
    % Ramp up QP current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, IQP,func_qp);    
    % Ramp up Feshbach current
    AnalogFuncTo(calctime(curtime,0),'FB Current',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, BFB,func_fb); 
    % Ramp shims
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Ix,func_x);  
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Iy,func_y);  
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Iz,func_z);  
    % Wait for all ramps
    curtime = calctime(curtime,Tr);

    curtime = calctime(curtime,Ts);                     % Settling time 
    
    if seqdata.flags.plane_selection_useBigShim
        if seqdata.flags.plane_selection_dotilt == 1
            setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage 2',1);  % Engage big shim PID for stripes
        else
            setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',1); % Engage big shim PID for single plane
        end
    end
    curtime = calctime(curtime,100);                    % Wait for big shim PID
end


%% Apply the uWaves

switch opts.SelectMode      
    case 'SweepFreqSmoothLinear'
        dispLineStr('Smooth Linear Frequency Sweep',curtime);
        if ~opts.dotilt
            freq_offset = getVarOrdered('qgm_plane_uwave_frequency_offset_notilt');
            freq_amp = getVar('qgm_plane_uwave_frequency_amplitude_notilt');
        else
            freq_offset = getVar('qgm_plane_uwave_frequency_offset_tilt');
            freq_amp = getVar('qgm_plane_uwave_frequency_amplitude_tilt');
        end 
        
        sweep_time = freq_amp/10;
        % If using feedback add an additional freqeuncy offset
        if opts.useFeedback
            freq_offset = freq_offset + getVar('f_offset');
        end        
        
        sweep_time=2;
        
        uwave_ramp_on_time = 0.1;
        uwave_ramp_off_time = 0.1;
        % Define the actually used settings
        defVar('qgm_plane_uwave_frequency_offset',freq_offset,'kHz');
        defVar('qgm_plane_uwave_amplitude',freq_amp,'kHz');
        defVar('qgm_plane_uwave_power',[5],'dBm');15;
        defVar('qgm_plane_uwave_time',sweep_time,'ms')   

        % Read in the actually used settings
        freq_offset = getVar('qgm_plane_uwave_frequency_offset');
        freq_amp = getVar('qgm_plane_uwave_amplitude');
        sweep_time = getVar('qgm_plane_uwave_time');   
        power = getVar('qgm_plane_uwave_power');

        
       % Configure the SRS
        uWave_opts=struct;
        uWave_opts.Address      = 30;                       % SRS GPIB Addr
        uWave_opts.Frequency    = 1606.75+freq_offset*1E-3; % Frequency [MHz]
        uWave_opts.Power        = power;%15                    % Power [dBm]
        uWave_opts.Enable       = 1;                        % Enable SRS output    
        uWave_opts.EnableSweep  = 1;                    
        uWave_opts.SweepRange   = 1e-3*freq_amp;         % Sweep Amplitude [MHz]
        
        
        addOutputParam('qgm_plane_uwave_frequency',uWave_opts.Frequency);  
        
        disp(['     Freq         : ' num2str(uWave_opts.Frequency) ' MHz']);    
        disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);    
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Amp     : ' num2str(freq_amp) ' kHz']);


        %%%% The uWave Sweep Code Begins Here %%%%        
        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

        % Enable ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end
        % Turn on the uWave        
        if  ~opts.fake_the_plane_selection_sweep
            % Turn on TTL
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        end
         % Ramp up rabi frequency
        curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                uwave_ramp_on_time,uwave_ramp_on_time,0,10,1);  
        ScopeTriggerPulse(curtime,'Plane selection');

        % Linearly ramp the frequency
        curtime = AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T) -1+2*t/T,...
            sweep_time,sweep_time,1);
       % Ramp down rabi frequency
        curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            uwave_ramp_off_time,uwave_ramp_off_time,10,0,1); 
        
        % Trigger the Scope
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

%       Reset the ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end

        if opts.doProgram
            programSRS(uWave_opts);                     % Program the SRS        
        end
        curtime = calctime(curtime,30);             % Additional wait

    case 'SweepFreqHS1'        
        %% Sweep Frequency 
        % This does an HS1 plane frequency sweep, this is only good for one
        % plane really.
        dispLineStr('HS1 Frequency Sweep',curtime);
        
        % Read in frequency and amplitude for tilt or no tilt
        if ~opts.dotilt
            freq_offset = getVar('qgm_plane_uwave_frequency_offset_notilt');
            freq_amp = getVar('qgm_plane_uwave_frequency_amplitude_notilt');
        else
            freq_offset = getVar('qgm_plane_uwave_frequency_offset_tilt');
            freq_amp = getVar('qgm_plane_uwave_frequency_amplitude_tilt');
        end   

        if opts.useFeedback
            freq_offset = freq_offset + getVar('f_offset');
        end        
        
        % Define the actually used settings
        defVar('qgm_plane_uwave_frequency_offset',freq_offset,'kHz');
        defVar('qgm_plane_uwave_amplitude',freq_amp,'kHz');
        defVar('qgm_plane_uwave_power',[5],'dBm');15;% NEED TO MEASURE SATURATED POWER
        defVar('qgm_plane_uwave_time',16.6,'ms')   

        % Read in the actually used settings
        freq_offset = getVar('qgm_plane_uwave_frequency_offset');
        freq_amp = getVar('qgm_plane_uwave_amplitude');
        sweep_time = getVar('qgm_plane_uwave_time');   
        power = getVar('qgm_plane_uwave_power');

        
       % Configure the SRS
        uWave_opts=struct;
        uWave_opts.Address      = 30;                       % SRS GPIB Addr
%         uWave_opts.Address=29; % 4/4/2023
        uWave_opts.Frequency    = 1606.75+freq_offset*1E-3; % Frequency [MHz]
        uWave_opts.Power        = power;%15                    % Power [dBm]
        uWave_opts.Enable       = 1;                        % Enable SRS output    
        uWave_opts.EnableSweep  = 1;                    
        uWave_opts.SweepRange   = 1e-3*freq_amp;         % Sweep Amplitude [MHz]
        
        env_amp     = 1;              % Relative amplitude of the sweep (keep it at 1 for max)
        beta        = asech(0.005);   % Beta defines sharpness of HS1
        
        addOutputParam('qgm_plane_uwave_frequency',uWave_opts.Frequency);            
        addOutputParam('qgm_plane_uwave_HS1_beta',beta);
        addOutputParam('qgm_plane_uwave_HS1_amp',env_amp);
        
        disp(['     Freq         : ' num2str(uWave_opts.Frequency) ' MHz']);    
        disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);    
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Amp     : ' num2str(freq_amp) ' kHz']);


        %%%% The uWave Sweep Code Begins Here %%%%        
        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

        % Enable ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end
        % Turn on the uWave        
        if  ~opts.fake_the_plane_selection_sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
        end
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);

        if  ~opts.fake_the_plane_selection_sweep
            % Sweep the VVA (use voltage func 2 to invert the vva transfer
            % curve (normalized 0 to 10
            AnalogFunc(calctime(curtime,0),'uWave VVA',...
                @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,env_amp,2);
        end
        
        % Trigger the Scope
        ScopeTriggerPulse(curtime,'Plane selection');

        curtime = calctime(curtime,sweep_time);                     % Wait for sweep
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

%       Reset the ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end

        if opts.doProgram
            programSRS(uWave_opts);                     % Program the SRS        
        end
        curtime = calctime(curtime,30);             % Additional wait

    case 'SweepFieldLegacy'
        %% Sweep Field Legacy (Pre CF)
        disp('Using Z shim to plane select');

        % uwave freq width (gets overwritten)
        ffscan_list = [100]/1000;%frequency sweep width
        ffscan = getScanParameter(ffscan_list,seqdata.scancycle,seqdata.randcyclelist,'ffscan');
        planeselect_sweep_width = ffscan;%500/1000;

        % SRS Settings (get's overwritten)
        spect_pars.freq = 1606.75;   % |9/2,-9/2>
        spect_pars.power = 15;15;%6.5; %-15 %uncalibrated "gain" for rf
        spect_pars.delta_freq = planeselect_sweep_width; %300
        spect_pars.mod_dev = planeselect_sweep_width; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)

        % What does this mean?
        Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
        if(~Cycle_About_Freq_Val)
            spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
        end

        % uWave Timings (get's overwritten)
        planeselect_pulse_length = planeselect_sweep_width * 1000 / 10 * 2; %2ms per 10kHz        
        spect_pars.pulse_length = planeselect_pulse_length; % also is sweep length (max is Keithley time - 20ms)       1*16.7
        spect_pars.uwave_delay = 0; %wait time before starting pulse
        spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)

        %Options for spect_type = 1
        spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk  
        spect_pars.AM_ramp_time = 2;9;  

        %SRS in pulsed mode with amplitude modulation
        spect_type = 2;

        %Take frequency range in MHz, convert to shim range in Amps
        %  (-5.714 MHz/A on Jan 29th 2015)
        if (seqdata.flags.K_RF_sweep==1 || seqdata.flags.xdt_K_p2n_rf_sweep_freq==1)
            %In -ve mF state, frequency increases with field
            dBz = spect_pars.delta_freq / (5.714);
        else 
            %In +ve mF state, frequency decreases with field
            dBz = spect_pars.delta_freq / (-5.714);
        end

        field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
        field_shift_settle = 60; % settling time after initial and final field shifts

        if (Cycle_About_Freq_Val)
            %Shift field down and up by half of the desired width
            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
        else %Start at current field and ramp up
            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz;
        end

        % synchronizing this plane-selection sweep
        if opts.use_ACSync
              dispLineStr('enabling acync',curtime);

    %                 % Enable ACync right after ramping up to start field
    %                 ACync_start_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time);
    %                 % Disable ACync right before ramping back to initial field value
    %                 ACync_end_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time + ...
    %                     2*field_shift_settle + spect_pars.pulse_length);

            % Enable ACync right after ramping up to start field
            ACync_start_time = calctime(curtime,spect_pars.uwave_delay - field_shift_settle);
            % Disable ACync right before ramping back to initial field value
            ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                field_shift_settle + spect_pars.pulse_length);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end

        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_start;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim during uwave pulse to transfer atoms
        ramp.shim_ramptime = spect_pars.pulse_length;
        ramp.shim_ramp_delay = spect_pars.uwave_delay;
        ramp.zshim_final = z_shim_sweep_final;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim back to initial value after pulse is complete
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_center;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Extra Parameters for the plane selecting pulse
        spect_pars.fake_pulse = opts.fake_the_plane_selection_sweep;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
        spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value

            %Do plane selection pulse
    curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
    curtime = calctime(curtime,field_shift_settle+field_shift_time);
    % curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway

end
%% Kill Pulse
% Apply a vertical *upwards* D2 beam resonant with the 9/2 manifold to 
% remove any atoms not transfered to the F=7/2 manifold.

if opts.planeselect_doVertKill==1
    dispLineStr('Applying vertical D2 Kill Pulse',curtime);

    %Resonant light pulse to remove any untransferred atoms from
    %F=9/2
    

    
    kill_time = getVar('qgm_kill_time');    
    kill_detuning=getVar('qgm_kill_detuning');
    mod_amp =getVar('qgm_kill_power');


    %Kill SP AOM 
    mod_freq =  (120)*1E6;
    mod_offset =0;
    str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
    addVISACommand(8, str);  %Device 8 is the new kill beam Rigol changed on July 10, 2021
    % Display update about
    disp(' D2 Kill pulse');
    disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
    disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
    disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
    disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 


    if kill_time>0
        % Set trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,-50),'K Trap FM',kill_detuning); 
        % Turn off kill SP (0= off, 1=on)(we keep it on for thermal stability)
        setDigitalChannel(calctime(curtime,-20),'Kill TTL',0);
        % Open K Kill shutter (0=closed, 1=open)
        setDigitalChannel(calctime(curtime,-5),'Downwards D2 Shutter',1);           
        setDigitalChannel(curtime,'Kill TTL',1);             % Kill on              
        curtime = calctime(curtime,kill_time);               % Kill wait 
        
%         setAnalogChannel(calctime(curtime,0),'K Trap FM',kill_detuning+50); 
%         curtime = AnalogFuncTo(calctime(curtime,0),'K Trap FM',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ...
%             50, 50, kill_detuning);
    

        setDigitalChannel(curtime,'Kill TTL',0);             % Kill off
        setDigitalChannel(curtime,'Downwards D2 Shutter',0); % Close kill shutter      
        % Turn on kill SP after closed shutter (thermal stability)
        setDigitalChannel(calctime(curtime,15),'Kill TTL',1); % Kill on
    end
    
end


%% uWave Transfer Back to 9/2,-9/2
if opts.planeselect_doMicrowaveBack    
    switch opts.SelectModeBack
        case 'SweepFreqHS1'        
            %Sweep the frequency
            disp('sweeping frequency HS1');
            
            % For SRS GPIB 29
            setDigitalChannel(calctime(curtime,0),'SRS Source post spec',1);
            setDigitalChannel(calctime(curtime,0),'SRS Source',0);
            
            % Wait for switches to finish
            curtime = calctime(curtime,30);
            
            % 2021/06/22 CF
            % Use this when Xshimd=3, zshimd=-1 and you vary yshimd
            % freq_list=interp1([-3 0.27 3],[100 -200 -500],yshimd);
            % use this when yshimd=3, zshim3=-1 an dyou vary xshimd
            % freq_list=interp1([-3 0 3],[-200 -400 -500],xshimd);

            % Define the SRS frequency
            if opts.dotilt
                freq_list = 1050 + [1220];
            else
                freq_list = 1050 + [520];
            end

            freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
                seqdata.randcyclelist,'uwave_freq_offset_back','kHz from 1606.75 MHz');

            disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);

            % SRS settings (may be overwritten later)
            uWave_opts=struct;
            uWave_opts.Address=29;                        % K uWave ("SRS B");
            uWave_opts.Frequency=1606.75+freq_offset*1E-3;% Frequency in MHz
            uWave_opts.Power= 15;%15                      % Power in dBm
            uWave_opts.Enable=1;                          % Enable SRS output    

            addOutputParam('uwave_pwr_back',uWave_opts.Power)
            addOutputParam('uwave_frequency_back',uWave_opts.Frequency);    

            disp('HS1 Sweep Pulse Backwards');

            % Calculate the beta parameter
            beta=asech(0.005);   
            addOutputParam('uwave_HS1_beta_back',beta);

            % Relative envelope size (less than or equal to 1)
            env_amp=1;
            addOutputParam('uwave_HS1_amp_back',env_amp);

            % Determine the range of the sweep
            uWave_delta_freq_list= [120]/1000; [7]/1000;
            uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
                seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq_back','kHz');

            % the sweep time is based on old calibration for rabi frequency
            uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
            sweep_time = getScanParameter(uwave_sweep_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time_back');     

            disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
            disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

            % Enable uwave frequency sweep
            uWave_opts.EnableSweep=1;                    
            uWave_opts.SweepRange=uWave_delta_freq;   

            setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
            setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

            % Enable ACync
            if opts.use_ACSync
                setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
            end

            % Turn on the uWave        
            if  ~opts.fake_the_plane_selection_sweep
                disp('disabling ');
                setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
            end

            % Ramp the SRS modulation using a TANH
            % At +-1V input for +- full deviation
            % The last argument means which votlage fucntion to use
            AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
                @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,1);

            if  ~opts.fake_the_plane_selection_sweep
                % Sweep the VVA (use voltage func 2 to invert the vva transfer
                % curve (normalized 0 to 10
                AnalogFunc(calctime(curtime,0),'uWave VVA',...
                    @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,env_amp,2);
            end

            curtime = calctime(curtime,sweep_time);                     % Wait for sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
            setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
            setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

            % Reset the ACync
            if opts.use_ACSync
                setDigitalChannel(calctime(curtime,30),'ACync Master',0);
            end

            programSRS(uWave_opts);                     % Program the SRS        
            curtime = calctime(curtime,30);             % Additional wait  

        case 'SweepFieldLegacy'
            % Transfer the |7,-7> back to |9,-9>.  This sweep can be broad
            % because everything else is dead (nominally). This step is
            % also somewhat uncessary because the Raman beams during
            % imaging Rabi oscillates between the two

            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
            curtime = calctime(curtime,65);

            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;

            %Take frequency range in MHz, convert to shim range in Amps
            %(-5.714 MHz/A on Jan 29th 2015)

            final_transfer_range = 2; %MHz
            back_transfer_range = 1;
            if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. xdt_K_p2n_rf_sweep_freq==1)

                %In -ve mF state, frequency increases with field
                dBz = back_transfer_range*final_transfer_range / (5.714);
            else 
                %In +ve mF state, frequency decreases with field
                dBz = back_transfer_range*final_transfer_range / (-5.714);
            end

            spect_pars.pulse_length = 100*final_transfer_range; %Seems to give good LZ transfer for power = -12dBm peak

            final_sweep_time = back_transfer_range*spect_pars.pulse_length;
            field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = spect_pars.AM_ramp_time + 10; % settling time after initial and final field shifts

            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = final_sweep_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim back to initial value after pulse is complete
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            ramp_bias_fields(calctime(curtime,0), ramp);

        curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
        curtime = calctime(curtime,field_shift_settle+field_shift_time); 

            followup_repump_pulse = 1;1;%remove mF = -7/2 atoms
            if (followup_repump_pulse)
                %Ensure atoms are all returned to F=9/2 with repump light
                % (do this during the shim field wait time above)
                % (would be great to use FM to get the repump to resonance in the 40G field)

                %Pulse on repump beam to try to remove any atoms left in F=7/2
                repump_pulse_time = 5;
                repump_pulse_power = 0.7;

                %Open Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),3,1);
                %turn repump back up
                setAnalogChannel(calctime(curtime,-field_shift_settle-10),25,repump_pulse_power);
                %repump TTL
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),7,1);

                %Repump pulse
                DigitalPulse(calctime(curtime,-field_shift_settle),7,repump_pulse_time,0);

                %Close Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle+repump_pulse_time+5),3,0);
            end
    end
end

%% Repump Kill

if opts.planeselect_doFinalRepumpPulse
    %Pulse on repump beam to try to remove any atoms left in F=7/2
    repump_pulse_time = 5;
    repump_pulse_power = 0.7;

    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),3,1);
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),25,repump_pulse_power);
    %repump TTL
    setDigitalChannel(calctime(curtime,-10),7,1);

    %Repump pulse
    DigitalPulse(calctime(curtime,0),7,repump_pulse_time,0);

    %Close Repump Shutter
    setDigitalChannel(calctime(curtime,repump_pulse_time+5),3,0);
end 

%% Plane select a second time
if opts.planeselect_again

    
    % For SRS GPIB 30
    setDigitalChannel(calctime(curtime,0),'SRS Source',1); 
    setDigitalChannel(calctime(curtime,0),'SRS Source post spec',0);
    % Wait for switches to finish
    curtime = calctime(curtime,30);
    
    disp('HS1 Sweep Pulse');

        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta_2',beta);

        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp_2',env_amp);

        % Determine the range of the sweep
        uWave_delta_freq_list= [20]/1000; [7]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq_2','kHz');

        % the sweep time is based on old calibration for rabi frequency
        uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time_2');     

        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

        % Enable ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave        
        if  ~opts.fake_the_plane_selection_sweep
            disp('disabling ');
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
        end

        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);

 
        if  ~opts.fake_the_plane_selection_sweep
            % Sweep the VVA (use voltage func 2 to invert the vva transfer
            % curve (normalized 0 to 10
            AnalogFunc(calctime(curtime,0),'uWave VVA',...
                @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,env_amp,2);
        end

        curtime = calctime(curtime,sweep_time);                     % Wait for sweep
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

        % Reset the ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end
        curtime = calctime(curtime,30);             % Additional wait
        
        if opts.planeselect_doVertKill==1

                    %Resonant light pulse to remove any untransferred atoms from
            %F=9/2
            kill_time_list = kill_time;2;
            kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
                seqdata.randcyclelist,'kill_time_2','ms'); %10 
            kill_detuning_list = kill_detuning;[42.7];%42.7
            kill_detuning = getScanParameter(kill_detuning_list,...
                seqdata.scancycle,seqdata.randcyclelist,'kill_det_2');        
               
            %Kill SP AOM 
            mod_freq =  (120)*1E6;
            mod_amp = mod_amp;0.05;0.1; % use same power for both pulses 
            
            % Display update about
            disp(' D2 Kill pulse');
            disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
            disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
            disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
            disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 

            % Offset time of pulse (why?)
            pulse_offset_time = -5;       

            if kill_time>0
                % Set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,pulse_offset_time-50),...
                    'K Trap FM',kill_detuning); %54.5

                % Turn off kill SP (0= off, 1=on)(we keep it on for thermal stability)
                setDigitalChannel(calctime(curtime,pulse_offset_time-20),...
                    'Kill TTL',0);

                % Open K Kill shutter (0=closed, 1=open)
                setDigitalChannel(calctime(curtime,pulse_offset_time-5),...
                    'Downwards D2 Shutter',1);     

                % Pulse K Kill AOM
                DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',...
                    kill_time,1);

                % Close K Kill shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+2),...
                    'Downwards D2 Shutter',0);

                % Turn on kill SP (thermal stability)
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+5),...
                    'Kill TTL',1);

                % Advance Time
                curtime=calctime(curtime,pulse_offset_time+kill_time+5);
            end
            
        end
    
end

%% Ramp off Field
if opts.ramp_field_CF
     setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',0); % stop PID
     setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage 2',0); %stop PID
     curtime= calctime(curtime,20);
     setDigitalChannel(calctime(curtime,0),'Z shim bipolar relay',1);
    
    % Ramp up QP Feedforward
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_16,func_qp);
    
    if exist('doFBSourceSwitch','var') && doFBSourceSwitch
        setDigitalChannel(calctime(curtime,Tr+Ts+50),96,0); %Relay TTL
    else
        AnalogFuncTo(calctime(curtime,0),'FB Current',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_FB,func_fb); 
    end
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_X,func_x);  
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_Y,func_y);  
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_Z,func_z);  
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tff+20, Tff+20, val_FF); 
    curtime = calctime(curtime,Tr);
    curtime = calctime(curtime,Ts);     
end
     
end

