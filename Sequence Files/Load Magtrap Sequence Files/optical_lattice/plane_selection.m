function [curtime] = plane_selection(timein)

global seqdata
 curtime = timein;

    % Transfer atoms to |7/2,-7/2> initially. Do we need this??  
    initial_transfer = 0;   
    
    % Ramp up lattices for plane selection (typically unesasaary)
    planeselect_doPinLattices = 0; 
    
    % Establish field gradeint with QP, FB, and shim fields for plane selection
    ramp_fields = 1; 
    
    % Do you want to fake the plane selection sweep?
    %0=No, 1=Yes, no plane selection but remove all atoms.
    fake_the_plane_selection_sweep = 0; 
        
    % Pulse the vertical D2 kill beam to kill untransfered F=9/2
    planeselect_doVertKill = 1;

    % Transfer back to -9/2 via uwave transfer
    planeselect_doMicrowaveBack = 0;    
 
    % Pulse repump to remove leftover F=7/2
    planeselect_doFinalRepumpPulse = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply pinning lattice for plane selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Increase the lattice depth to pin the atoms
    % Typically unecessary as you have already pinned them
    if planeselect_doPinLattices
        disp('Ramping lattices and dipole traps.');
        setDigitalChannel(calctime(curtime,-0.1),'yLatticeOFF',0);
        
        % Ramp Lattices
        AnalogFuncTo(calctime(curtime,0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5,60); 
        AnalogFuncTo(calctime(curtime,0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 60); 
        
        % Ramp dipole traps
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, 0);
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ramp magnetic field for planes selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply a field gradient to make a spatially dependent Zeeman shift
    % that allows us to selectively choose a single plane.
    
    FB_init = getChannelValue(seqdata,37,1,0);
    if ramp_fields
        % Ramp the SHIMs, QP, and FB to the appropriate level  
        disp(' Ramping fields');
        clear('ramp');       
        
        xshimdlist = -0.257;
%         xshimdlist = 3;

        yshimdlist = 0.125;
        zshimd = -1;
        
        xshimd = getScanParameter(xshimdlist,seqdata.scancycle,...
            seqdata.randcyclelist,'xshimd','A');
        yshimd = getScanParameter(yshimdlist,seqdata.scancycle,...
            seqdata.randcyclelist,'yshimd','A');
        
        %Both these x and y values can be large and negative. Draw from the
        %'positive' shim supply when negative. Just don't fry the shim.
        ramp.xshim_final = seqdata.params. shim_zero(1)-2.548 + xshimd;% -0.7 @ 40/7, (0.46-0.008-.05-0.75)*1+0.25 @ 40/14
        ramp.yshim_final = seqdata.params. shim_zero(2)-0.276 + yshimd;
        ramp.zshim_final = seqdata.params. shim_zero(3)+zshimd; %Plane selection uses this shim to sweep... make its value larger?
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero
        
        addOutputParam('PSelect_xShim',ramp.xshim_final)
        addOutputParam('PSelect_yShim',ramp.yshim_final)
        addOutputParam('PSelect_zShim',ramp.zshim_final)

%         addOutputParam('xshimd',xshimd);
%         addOutputParam('yshimd',yshimd);
        addOutputParam('zshimd',zshimd,'A');

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = -0;
        fb_shift_list = [.6];[0.6];[0.56];%0.2 for 0.7xdt power
        fb_shift = getScanParameter(fb_shift_list,seqdata.scancycle,...
            seqdata.randcyclelist,'fb_shift');
        ramp.fesh_final = 128-fb_shift;125.829-fb_shift; 
        
        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 100;
        ramp.QP_ramp_delay = -0;
        ramp.QP_final =  14*1.78; %7 %210G/cm
        ramp.settling_time = 300; %200
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % uWave Settings for Plane Selection
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This should be cleaned up a lot, yes it should
    
    planeselect_freq = 1606.75;
    spect_pars.freq = planeselect_freq;   % |9/2,-9/2>
    spect_pars.power = 15;15;%6.5; %-15 %uncalibrated "gain" for rf
    
    ffscan_list = [100]/1000;%frequency sweep width
    ffscan = getScanParameter(ffscan_list,seqdata.scancycle,seqdata.randcyclelist,'ffscan');
    
    
    planeselect_sweep_width = ffscan;%500/1000;
    spect_pars.delta_freq = planeselect_sweep_width; %300
    spect_pars.mod_dev = planeselect_sweep_width; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
    %spect_pars.mod_dev = 80/1000; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)
    Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
    %addOutputParam('delta_freq',spect_pars.delta_freq)
    %Quick little addition to start at freq_val instead.
    if(~Cycle_About_Freq_Val)
        spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
    end

    planeselect_pulse_length = planeselect_sweep_width * 1000 / 10 * 2; %2ms per 10kHz        
    spect_pars.pulse_length = planeselect_pulse_length; % also is sweep length (max is Keithley time - 20ms)       1*16.7
    spect_pars.uwave_delay = 0; %wait time before starting pulse
    spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)
    spect_type = 2; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps
    sweep_field = 0; %0 to sweep with SRS, 1 to sweep with z Shim
    %Options for spect_type = 1
    spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk  
    spect_pars.AM_ramp_time = 2;9;  
%  spect_pars.AM_ramp_time = 9; %Used for pulse_type = 1      2*16.7

    use_ACSync = 1;

    % Define the SRS frequency
    freq_list = [355];[340];[-300];       
    
    % 2021/06/22 CF
    % Use this when Xshimd=3, zshimd=-1 and you vary yshimd
%     freq_list=interp1([-3 0.27 3],[100 -200 -500],yshimd);

    % use this when yshimd=3, zshim3=-1 an dyou vary xshimd
    % freq_list=interp1([-3 0 3],[-200 -400 -500],xshimd);

    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_freq_offset','kHz from 1606.75 MHz');
    
    disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);
    
    % SRS settings (may be overwritten later)
    uWave_opts=struct;
    uWave_opts.Address=30;                        % K uWave ("SRS B");
    uWave_opts.Frequency=1606.75+freq_offset*1E-3;% Frequency in MHz
    uWave_opts.Power= 15;%15                      % Power in dBm
    uWave_opts.Enable=1;                          % Enable SRS output    

    addOutputParam('uwave_pwr',uWave_opts.Power)
    addOutputParam('uwave_frequency',uWave_opts.Frequency);    
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
    
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);

    % RF Switch for K SRS depreciated? (1:B, 0:A)
    setDigitalChannel(calctime(curtime,-20),'K uWave Source',1); 
    setDigitalChannel(calctime(curtime,-20),'SRS Source',1);  

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Transfer atoms to |7/2,-7/2> initially.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CORA - Is this historical, can we delete it? Accroding to VV

    if initial_transfer

        %Save pulse settings for plane selection
        selection_pulse_length = spect_pars.pulse_length;
        selection_delta_freq = spect_pars.delta_freq;

        if (sweep_field == 0)
        %Transfer all atoms to F=7/2 first
        spect_pars.mod_dev = 1800/1000; %Mod dev needs to be big enough for a wide initial sweep   1800
        spect_pars.delta_freq = 3600/1000;
        spect_pars.pulse_length = 200;
        spect_pars.fake_pulse = 0;

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % first sweep (note: this one moves with the center frequency!)

curtime = calctime(curtime,200); % wait to allow SRS to settle at new frequency

        elseif (sweep_field == 1)

            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;

            %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
            dBz = 3.00 / (-5.714); % sweeping over a large range (equiv to 1800kHz) to transfer the full cloud.
            selection_pulse_length = spect_pars.pulse_length;
            spect_pars.pulse_length = 100;
            spect_pars.SRS_select = 0; %Use SRS A for the global sweep

            init_sweep_time = 80;
            field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = 40; % settling time after initial and final field shifts

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
            ramp.shim_ramptime = init_sweep_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;

            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;

            ramp_bias_fields(calctime(curtime,0), ramp);


        %Do plane selection pulse (initial transfer)

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

        %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);

        % wait time (code related -- need to accomodate for AnalogFuncTo
        % calls to the past in rf_uwave_spectroscopy)
curtime = calctime(curtime,100);

        end % end initial transfer

        clean_up_pulse = 0;
        if clean_up_pulse
            %Resonant light pulse to remove any untransferred atoms from F=9/2
            kill_probe_pwr = 1;
            kill_time = 0.2;
            kill_detuning = 90; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field            

            pulse_offset_time = -100; %Need to step back in time a bit to do the kill pulse
                                      % directly after transfer, not after the subsequent wait times

            %set probe detuning
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
            %set trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5

            %open K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time-10),30,1); %0=closed, 1=open
            %turn up analog
            setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
            %set TTL off initially
            setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);

            %pulse beam with TTL
            DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);

            %close K probe shutter
            setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),30,0);
        end


        %Reset pulse settings for plane selection
        spect_pars.pulse_length = selection_pulse_length;
        spect_pars.delta_freq = selection_delta_freq;


    end
       
ScopeTriggerPulse(curtime,'Plane Select');
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plane select via uWave application
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply microwaves inconjuction with a frequency or magnetic field
    % sweep to transfer atoms from the F=9/2 manifold to the F=7/2 in a
    % specific plane.
    
    if (sweep_field == 0) %Sweeping frequency of SRS
        disp('Using SRS to plane select');
    
        disp('HS1 Sweep Pulse');
        
        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta',beta);
        
        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp',env_amp);


        % Determine the range of the sweep
        uWave_delta_freq_list= [40] /1000; 130;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq','kHz');
        
        
        uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        % Set uWave power to low
        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);
         
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave        
        if  ~fake_the_plane_selection_sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        end
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);
        
        if  ~fake_the_plane_selection_sweep
        % Sweep the VVA (use voltage func 2 to invert the vva transfer
        % curve (normalized 0 to 10
        AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp,2);
        end
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',0);-1;
        
        % Reset the ACync
        setDigitalChannel(calctime(curtime,100),'ACync Master',0);
        
        % Program the SRS
        programSRS(uWave_opts); 
curtime = calctime(curtime,75);

    elseif (sweep_field == 1) % Sweeping field with z Shim, SRS frequency is fixed
        disp('Using Z shim to plane select');

        %SRS in pulsed mode with amplitude modulation
        spect_type = 2;

        %Take frequency range in MHz, convert to shim range in Amps
        %  (-5.714 MHz/A on Jan 29th 2015)
        if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. xdt_K_p2n_rf_sweep_freq==1)
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
        do_ACync_plane_selection = 1;
        if do_ACync_plane_selection
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
        spect_pars.fake_pulse = fake_the_plane_selection_sweep;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
        spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
            
            %Do plane selection pulse
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
% curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway
            
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Vertical Kill Beam Application
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
    % Apply a vertical *upwards* D2 beam resonant with the 9/2 manifold to 
    % remove any atoms not transfered to the F=7/2 manifold.

    if planeselect_doVertKill==1
        dispLineStr('Applying vertical D2 Kill Pulse',curtime);

        %Resonant light pulse to remove any untransferred atoms from
        %F=9/2
        kill_time_list = [1];2;
        kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'kill_time','ms'); %10 
        kill_detuning_list = [42.7];%42.7
        kill_detuning = getScanParameter(kill_detuning_list,...
            seqdata.scancycle,seqdata.randcyclelist,'kill_det');        

        %Kill SP AOM 
        mod_freq =  (120)*1E6;
        mod_amp = 1;0.05;0.1;
        mod_offset =0;
        str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
        addVISACommand(8, str);  %Device 8 is the new kill beam Rigol changed on July 10, 2021

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



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % uWave Transfer back to |9/2,-9/2>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    if planeselect_doMicrowaveBack
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Repump to kill F=7/2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    if planeselect_doFinalRepumpPulse
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
end

