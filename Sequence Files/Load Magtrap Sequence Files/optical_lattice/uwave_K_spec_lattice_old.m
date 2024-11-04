function curtime = uwave_K_spec_lattice_old(timein)
curtime = timein;
global seqdata

 logNewSection('Performing K uWave Spectroscopy',curtime);
    clear('spect_pars');

    freq_list = [0]/1000;[20]/1000;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'freq_val');

    %Currently 1390.75 for 2*22.6.
    spect_pars.freq = 1335.845 +2.5+ freq_offset;

    uwavepower_list = [15];[15];%15
    uwavepower_val = getScanParameter(uwavepower_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwavepower_val','dBm');
    
    uwavedeltafreq_list = [200]/1000;[1000]/1000;
    uwavedeltafreq_val = getScanParameter(uwavedeltafreq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwavedeltafreq_val','MHz');

    spect_pars.power = uwavepower_val; % 15 %dBm
    spect_pars.delta_freq = uwavedeltafreq_val;  % 1000/1000;
    spect_pars.mod_dev = spect_pars.delta_freq;

    pulse_time_list =[30];40;[spect_pars.delta_freq*1000/5]; %Keep fixed at 5kHz/ms.
    spect_pars.pulse_length = getScanParameter(pulse_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_pulse_time');
    spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp up and down with min-jerk
    spect_pars.AM_ramp_time = 0;5;
    spect_pars.fake_pulse = 0;
    spect_pars.uwave_delay = 0; %wait time before starting pulse
    spect_pars.uwave_window = 0; % time to wait during 60Hz sync pulse (Keithley time +20ms)
    spect_type = 2; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps 9: field sweep
    spect_pars.SRS_select = 1;

%         addOutputParam('uwave_pwr',pwr)
    addOutputParam('sweep_time',spect_pars.pulse_length);
    addOutputParam('sweep_range',spect_pars.delta_freq);
    addOutputParam('freq_val',freq_offset);
    
        do_field_sweep = 1;
        if do_field_sweep
            %Take frequency range in MHz, convert to shim range in Amps
            %  (-5.714 MHz/A on Jan 29th 2015)
            dBz = spect_pars.delta_freq / (-5.714); 
            
            field_shift_offset = 25;
            field_shift_time = 5;5;
            
            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center-dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+dBz/2;
            
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_offset; %offset from the beginning of uwave pulse
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
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_offset; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
        end
        
        use_ACSync = 1;
        if use_ACSync
                % Enable ACync 10ms before pulse
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay-15);
                % Disable ACync 150ms after pulse
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    spect_pars.pulse_length + 150);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            
        end

curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);
%change curtime for testing F pump
% curtime = calctime(curtime,20);

        do_second_sweep = 0;
        if do_second_sweep
            %Perform a second microwave sweep
            
            uwave_wait_list = [200];[200];
            uwave_wait = getScanParameter(uwave_wait_list,seqdata.scancycle,...
                seqdata.randcyclelist,'uwave_wait');
            
            curtime = calctime(curtime,uwave_wait);
            
            if do_field_sweep
                %Take frequency range in MHz, convert to shim range in Amps
                %  (-5.714 MHz/A on Jan 29th 2015)
                dBz = spect_pars.delta_freq / (-5.714); 

                field_shift_offset = 25;
                field_shift_time = 5;5;

                z_shim_sweep_center = getChannelValue(seqdata,' Z Shim',1,0);
                z_shim_sweep_start = z_shim_sweep_center-dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+dBz/2;

                %Ramp shim to start value before generator turns on
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_offset; %offset from the beginning of uwave pulse
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
                ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_offset; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_center;

                ramp_bias_fields(calctime(curtime,0), ramp);
            end
        
        if use_ACSync
                % Enable ACync 10ms before pulse
                ACync_start_time = calctime(curtime,spect_pars.uwave_delay-15);
                % Disable ACync 150ms after pulse
                ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                    spect_pars.pulse_length + 150);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            
        end
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);

        end

ScopeTriggerPulse(curtime,'K uWave Spectroscopy');

curtime = calctime(curtime,25);
end