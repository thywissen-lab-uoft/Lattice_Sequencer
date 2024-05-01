% Absorption pulse function -- triggers cameras,pulses probes, and does RF
% spin flip during TOF
function params = do_HF_abs_pulses(curtime,params,flags,tD)
    global seqdata

    %Trigger the pixelfly camera
    pulse_length = params.timings.pulse_length;
    ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);
    DigitalPulse(calctime(curtime,tD),'PixelFly Trigger',pulse_length,1);

    % Pulse the imaging beam for the first time
    extra_wait_time = params.timings.wait_time;
    DigitalPulse(calctime(curtime,extra_wait_time),'K High Field Probe',pulse_length,0);
    
    % Pulse the imaging beam again
    DigitalPulse(calctime(curtime,params.timings.time_diff_two_absorp_pulses...
    +pulse_length+extra_wait_time),'K High Field Probe',pulse_length,0);                                                                                                              'K High Field Probe',pulse_length,0);                 

    mF1=-9/2;   % Lower energy spin state
    mF2=-7/2;   % Higher energy spin state

    % Get the center frequency
    Boff = 0.1238;
    B = seqdata.params.FB_imaging_value + Boff;

    if flags.Attractive
        if seqdata.flags.lattice
            rf_tof_shift = params.HF_rf_shift.attractive_lattice;
        else
            rf_tof_shift = params.HF_rf_shift.attractive_xdt;
        end
    else
        if seqdata.flags.lattice
            rf_tof_shift = params.HF_rf_shift.repulsive_lattice;
        else
            rf_tof_shift = params.HF_rf_shift.repulsive_xdt;
        end                      

    end
    addOutputParam('rf_tof_shift',rf_tof_shift,'kHz') 
    
    rf_tof_freq =  rf_tof_shift*1e-3 +... 
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);   
    addOutputParam('rf_tof_freq',rf_tof_freq,'MHz');  

    if (rf_tof_freq < 1)
         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
    end

    % RF Frequency Sweep
    rf_tof_delta_freq_list = 40*1e-3; [40]*1e-3;[35]*1e-3;[20]*1e-3;[12]*1e-3;12; %20kHz for 15ms TOF
    rf_tof_delta_freq = getScanParameter(rf_tof_delta_freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_tof_delta_freq','MHz');

    % RF Pulse Time
    rf_tof_pulse_length_list = [1];[1];%1
    rf_tof_pulse_length = getScanParameter(rf_tof_pulse_length_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_tof_pulse_length','ms');

    % RF Gain Amplitude - only used for DDS
    rf_tof_gain_list = [9.9];[9];
    rf_tof_gain = getScanParameter(rf_tof_gain_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_tof_gain','arb');

    % RF Gain Off
    rf_off_voltage=-10;-9.9;

    %sweep_type = 'DDS';
    %sweep_type = 'SRS_HS1';
    sweep_type = 'SRS_LINEAR';

    switch sweep_type
        case 'DDS'   
            rf_wait_time = 0.05;

            freq_list=rf_tof_freq+[...
                -0.5*rf_tof_delta_freq ...
                -0.5*rf_tof_delta_freq ...
                0.5*rf_tof_delta_freq ...
                0.5*rf_tof_delta_freq];    

            pulse_list=[0.1 rf_tof_pulse_length 0.1]; 

            % Display the sweep settings
            disp([' Freq Center    (MHz) : [' num2str(rf_tof_freq) ']']);
            disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
            disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
            disp([' RF Gain Range  (V) : [' num2str(rf_off_voltage) ' ' num2str(rf_tof_gain) ']']);

            % Set RF gain to zero a little bit before
            setAnalogChannel(calctime(curtime,-40),'RF Gain',rf_off_voltage);   

            % Turn on RF
            setDigitalChannel(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time),'RF TTL',1);   

            % Set to RF
    %                     setDigitalChannel(curtime,'RF/uWave Transfer',0);   

            do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-30);
                ACync_end_time = calctime(curtime,sum(pulse_list)+30);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end

            % Trigger pulse duration
            dTP=0.05;
            DDS_ID=1;

            % Initialize "Sweep", ramp up power        
            sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
            DigitalPulse(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time),'DDS ADWIN Trigger',dTP,1);               
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
            AnalogFuncTo(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time),'RF Gain',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                pulse_list(1),pulse_list(1),rf_tof_gain); 
    %                     setAnalogChannel(calctime(curtime,...
    %                         rf_wait_time + pulse_length + extra_wait_time -1),'RF Gain',peak_voltage)

            % Primary Sweep, constant power            
            sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
            DigitalPulse(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time + pulse_list(1)),'DDS ADWIN Trigger',dTP,1);  
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
    %                     curtime=calctime(curtime,pulse_list(2));
    % 
            % Final "Sweep", ramp down power
            sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
            DigitalPulse(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time+pulse_list(1)+pulse_list(2)),'DDS ADWIN Trigger',dTP,1);               
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
            AnalogFuncTo(calctime(curtime,...
                rf_wait_time + pulse_length + extra_wait_time + ...
                pulse_list(1) + pulse_list(2)),'RF Gain',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                pulse_list(3),pulse_list(3),rf_off_voltage); 

    %                     setAnalogChannel(calctime(curtime,...
    %                         rf_wait_time + pulse_length + extra_wait_time ...
    %                         + rf_pulse_length +1),'RF Gain',off_voltage)

            % Turn off RF
            setDigitalChannel(calctime(curtime,...
              rf_wait_time + pulse_length + extra_wait_time + ...
              sum(pulse_list)),'RF TTL',0);               



              % Switch RF source if imaging both
    %                     buffer_time = 0.01;
    %                     DigitalPulse(calctime(curtime,...
    %                         params.timings.time_diff_two_absorp_pulses+pulse_length+extra_wait_time-buffer_time),...
    %                     'HF freq source',pulse_length+buffer_time+buffer_time,0);   
        case 'SRS_HS1'

            if isfield(params,'isProgrammedSRS') && params.isProgrammedSRS == 0
                rf_wait_time = 0.00;   

                disp('HS1 SRS Sweep Pulse');  

                rf_tof_srs_power_list = [12];
                rf_tof_srs_power = getScanParameter(rf_tof_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_tof_srs_power','dBm');

                sweep_time = rf_tof_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address=30;                       
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_tof_srs_power;                           
                rf_srs_opts.Frequency = rf_tof_freq;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_tof_freq) ' MHz']);
                disp(['     Freq Delta   : ' num2str(rf_tof_delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_tof_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;                    
                rf_srs_opts.SweepRange=abs(rf_tof_delta_freq);  

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'RF Source',1);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'SRS Source',1);


                % Set SRS Direction to RF
                setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set RF power to low
                setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);

                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),'RF TTL',1);    

                % Ramp the SRS modulation using linear
                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),'uWave FM/AM',...
                    @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,1);

                % Sweep the linear VVA
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),'RF Gain',...
                    @(t,T,beta) -10 + ...
                    20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta);

                % Turn off the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length),'RF TTL',0); 

                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length),'RF Gain',rf_off_voltage);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length+1),'RF Source',0);

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
                params.isProgrammedSRS = 1;
            end
        case 'SRS_LINEAR'

            if isfield(params,'isProgrammedSRS') && params.isProgrammedSRS == 0
                rf_wait_time = 0.00;   

                disp('LINEAR SRS Sweep Pulse');  

                rf_tof_srs_power_list = [12];
                rf_tof_srs_power = getScanParameter(rf_tof_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_tof_srs_power','dBm');

                sweep_time = rf_tof_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address=29;                       
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_tof_srs_power;                           
                rf_srs_opts.Frequency = rf_tof_freq;     

                disp(['     Freq Center  : ' num2str(rf_tof_freq) ' MHz']);
                disp(['     Freq Delta   : ' num2str(rf_tof_delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_tof_pulse_length) ' ms']);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;                    
                rf_srs_opts.SweepRange=abs(rf_tof_delta_freq);  

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'RF Source',1);

                % Set RF Source to SRS 29
                setDigitalChannel(calctime(curtime,-5),'SRS Source post spec',1);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'SRS Source',0);                                

                % Set SRS Direction to RF
                setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set RF power to low
                setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);

                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),'RF TTL',1);    

                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),...
                    'uWave FM/AM',...
                    @(t,T) 1-2*t/T,...
                    sweep_time,sweep_time,1);

                setAnalogChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time),...
                    'RF Gain',10);

                % Turn off the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length),'RF TTL',0); 

                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length),'RF Gain',rf_off_voltage);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + pulse_length + extra_wait_time+rf_tof_pulse_length+1),'RF Source',0);

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
            end

    end

        

end