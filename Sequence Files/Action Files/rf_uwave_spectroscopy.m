function  timeout = rf_uwave_spectroscopy(timein, type, pars)
%Function call: 
%Author: Rhys ( Ctrl-C/Ctrl-V )
%Created: Apr 2013
%Summary:   Doing a spectrosopy pulse or sweep (currently programmed for K
%   only). 
%------

global seqdata
curtime = timein;
    %Votlage Divider on the Input of the SRS
    div_factor =1;
    
    if ~exist('type','var')
        type = 3; %1: K-uwave sweep; 2: K-uwave pulse,; 3: K-rf sweep; 4:K-rf pulse
    end
    
    if ~exist('pars','var')
        %SRS Modulation Setting
        pars.freq = 9.7;
        %     freq = 1238.595;%1238.71;             %MHz      1246.885
        pars.power = -7; %dBm for uwave, "gain" for rf
    %     delta_freq = 0.1; %MHz
        pars.delta_freq = 0.6;
        pars.pulse_length = 100; % also is sweep length
        pars.uwave_delay = 100;
    end
    
    if ~isfield(pars,'uwave_delay')
        %The delay before a uWave pulse was previously set to 100ms, and
        %0ms for a sweep
        if (type == 2 || type == 6)
            pars.uwave_delay = 100;
        else
            pars.uwave_delay = 0;
        end
    end
    
    if ~isfield(pars,'pulse_type')
        %Assume basic pulse unless specified
        pars.pulse_type = 0;
    end
   
    
    if ~isfield(pars,'AM_ramp_time')
        %Assume 2ms AM ramp
        pars.AM_ramp_time = 2;
    end
    
    if ~isfield(pars,'fake_pulse')
        %Don't fake pulse by default
        pars.fake_pulse = 0;
    end
    
    if ~isfield(pars,'power_scale')
        %Default power
        pars.power_scale = 1;
    end
    
    if ~isfield(pars,'SRS_select')
        %By default use SRS B
        SRSAddress = 28;
        pars.SRS_select=1;
    else
        if pars.SRS_select==1
        %SRS B
            SRSAddress = 30; % 2022/09/22 changed to addr 30 after new GPIB cables
        else
        %SRS A
            SRSAddress = 27;
        end
    end
    
    
    %Default wait time after spectroscopy
    post_wait_time = 10;

% --------------------------------------
    if ( type == 1 ) % K-uwave sweep using the SRS (GPIB controlled)
        rf_on = 1;
        pars.freq = pars.freq;  % + pars.delta_freq/2
        if isfield(pars,'mod_dev')
            %Set modulation deviation to allow a different range than
            %necessary for this sweep (for multiple sweeps)
            mod_dev = pars.mod_dev;
        else
            %Nothing specified, set generator to sweep its entire range
            mod_dev = pars.delta_freq/2/div_factor;     %Mod Dev Setting on SRS in MHz
        end
        freq_scale = mod_dev;       %Frequency scales as mod_dev because we don't use a sextupler for 40K
        
        %Send GPIB Command to the SRS
        if seqdata.flags. SRS_programmed(pars.SRS_select+1)==0
%             addGPIBCommand(27,sprintf(['FREQ %fMHz; TYPE 1; FDEV %gMHz; MFNC 5; ' ...
%                 'AMPR %gdBm; MODL 1; DISP 2; ENBR %g;'],pars.freq,mod_dev,pars.power,rf_on)); % Externally controlled frequency modulation (see SRS manual on GPIB commands)
            
            addGPIBCommand(SRSAddress,sprintf(['FREQ %fMHz; TYPE 3; SDEV %gMHz; SFNC 5; ' ...
                'AMPR %gdBm; MODL 1; DISP 2; ENBR %g;'],pars.freq,mod_dev,pars.power,rf_on)); % Externally controlled frequency modulation (see SRS manual on GPIB commands)            
     
        else
            %SRS already programmed!
        end

        start_freq = -1*pars.delta_freq/2;
        end_freq = start_freq + pars.delta_freq;
        %             sweeptime_list = [0.1 0.2 0.5:0.5:5 10]; % e.g. for LZ sweep measurements
        %             sweep_uwave_time = getScanParameter(sweeptime_list,seqdata.scancycle,seqdata.randcyclelist,'sweeptime');
        
        sweep_uwave_time = pars.pulse_length;
        uwave_delay = 0;
        
        %Open uWave switch, transfer switch, and activate SRS selection switch
        setDigitalChannel(calctime(curtime,pars.uwave_delay-5),'K uWave Source',pars.SRS_select);%0: SRS A; 1: SRS B
        do_uwave_pulse(calctime(curtime,uwave_delay), pars.fake_pulse, 0*1E6, pars.pulse_length,2,1);
        ScopeTriggerPulse(calctime(curtime,uwave_delay),'K uwave spectroscopy pulse');
        
        %Sweep FM channel on SRS
%         setAnalogChannel(calctime(curtime,-10),46,start_freq/freq_scale);
% % %         AnalogFuncTo(calctime(curtime,-50),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,start_freq/freq_scale);

setAnalogChannel(calctime(curtime,-1),'uWave FM/AM',start_freq/freq_scale);
curtime =   AnalogFunc(calctime(curtime,uwave_delay),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),sweep_uwave_time,sweep_uwave_time,start_freq/freq_scale,end_freq/freq_scale);
        setAnalogChannel(calctime(curtime,1),'uWave FM/AM',0);
% % % AnalogFuncTo(calctime(curtime,50),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),50,50,0);
        
        addOutputParam('uwave_frequency',pars.freq);
        addOutputParam('uwave_power',pars.power);

% --------------------------------------
    elseif ( type == 2 ) % K-uwave pulse using the SRS (GPIB controlled)
        rf_on = 1;
        if seqdata.flags.SRS_programmed(pars.SRS_select+1)==0    
            %AM Modulation
            if (pars.pulse_type == 1) %Set power and enable amplitude modulation
%                 addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gRMS; MODL 1; TYPE 0; MFNC 5; ADEP 100; DISP 2; ENBR %g; AMPR?',pars.freq,0.2236*sqrt(10^(pars.power/10)),rf_on));
                if SRSAddress==28                    
                    settings = struct;
                    settings.Address = '192.168.1.121';
                    settings.PowerN = pars.power;
                    settings.PowerBNC = 0;
                    settings.EnableN = 1;                    
%                     settings.EnableN = 0;                    
                    settings.EnableBNC = 0;
                    settings.EnableSweep = 0;
                    settings.SweepRange = 0;
                    settings.Frequency = pars.freq;
                    programSRSNew(settings)                     
                    pause(2)
                else     
                    addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',pars.freq,pars.power,rf_on));
                end 
            else %Set the power with no modulation     
                    addGPIBCommand(SRSAddress,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',pars.freq,pars.power,rf_on));
             end
        else 
            %SRS Already Programmed!
        end
        
        uwave_time = pars.pulse_length; %100 %91.7
        
        %Set frequency and open uWave switch and transfer switch
        %             setAnalogChannel(calctime(curtime,50),46,freq_val/freq_scale,1);
        ScopeTriggerPulse(calctime(curtime,pars.uwave_delay),'K uwave spectroscopy pulse');
        setDigitalChannel(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time-5),'K uWave Source',pars.SRS_select);
                
        sync_uwave_pulse = 0;
        
        if ( sync_uwave_pulse );
curtime =   do_linesync_uwave_pulse(calctime(curtime,pars.uwave_delay), pars.fake_pulse, 0*1E6, uwave_time,0,1);            
        else            
            if (pars.pulse_type == 1) %Amplitude modulation (pulse actually 
                % starts ramping up AM_ramp_time before the "actual pulse"
                % and finishes AM_ramp_time after)
                
                %Determine max desired power
                max_power = (-1 + 2*pars.power_scale)*0.99; %Power_scale = 1 gives max_power = 0, corresponding to the default set power on the SRS
                 
                if pars.AM_ramp_time ~=0               
                %Turn off AM initially
                setAnalogChannel(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time-10),'uWave VVA',-1);
%                 setAnalogChannel(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time-10),'uWave FM/AM',-0.99);
                
                %Ramp on with min jerk at beginning of pulse
%                 AnalogFuncTo(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pars.AM_ramp_time,pars.AM_ramp_time,max_power);
                AnalogFuncTo(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time),'uWave VVA',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pars.AM_ramp_time,pars.AM_ramp_time,9.9);
                
                %Ramp off with min jerk at end of pulse
%                 AnalogFuncTo(calctime(curtime,pars.uwave_delay+uwave_time),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pars.AM_ramp_time,pars.AM_ramp_time,-0.99);
                AnalogFuncTo(calctime(curtime,pars.uwave_delay+uwave_time),'uWave VVA',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pars.AM_ramp_time,pars.AM_ramp_time,0);
                end
                
                %Open and close uWave switch for pulse time + AM_ramp_time
curtime =   do_uwave_pulse(calctime(curtime,pars.uwave_delay-pars.AM_ramp_time), pars.fake_pulse, 0*1E6, uwave_time+2*pars.AM_ramp_time,0,1);
            
                %Set VVA back to default value of 10 (fully open)
                setAnalogChannel(calctime(curtime,10),'uWave VVA',10);

            else %Not doing AM, so just open the switch for the pulse time
                
                %Open and close uWave switch
curtime =   do_uwave_pulse(calctime(curtime,pars.uwave_delay), pars.fake_pulse, 0*1E6,uwave_time,0,1);
            end

        end        
        addOutputParam('uwave_frequency',pars.freq);
        addOutputParam('uwave_power',pars.power);   
% --------------------------------------
    elseif ( type == 3 ) % RF sweep with evaporation DDS        
        if ( pars.freq > 180 ); % half way arbitrarily chosen ... resonance frequencies at accessible fields typ. <60MHz
            buildWarning('Spectroscopy','Frequency too high for RF spectroscopy!',1);
        end        
        %Do RF Pulse
        MHz = 1E6;
        %Define RF sweep range
        freqs_sweep = [pars.freq-pars.delta_freq/2 pars.freq+pars.delta_freq/2]*MHz; %0.28 %0.315
        RF_gain_sweep = [pars.power]; %-4
        sweep_times = [pars.pulse_length];
    
        ScopeTriggerPulse(calctime(curtime,0),'RF spectroscopy pulse');
        
%Random? 1ms delays in this code. Should get rid of them.    
curtime = do_rf_sweep(calctime(curtime,0),pars.fake_pulse,freqs_sweep,sweep_times,RF_gain_sweep);
%         if(pars.multiple_sweep == 1)
%             multiple_sweep_ls = pars.multiple_sweep_list
%         end
        post_wait_time = 0; %VIJIN Oct 29 2018
% --------------------------------------
    elseif ( type == 4 ) % Rf pulse with evaporation DDS

        if ( pars.freq > 180 ); % half way arbitrarily chosen ... resonance frequencies at accessible fields typ. <60MHz
            buildWarning('Spectroscopy','Frequency too high for RF spectroscopy!',1);
        end        
        MHz = 1E6;        
        sync_rf_pulse = 0;
        
        if sync_rf_pulse
curtime =   do_linesynced_rf_pulse(calctime(curtime,0),0, pars.freq*MHz,pars.pulse_length,0,pars.power);
        else
curtime =   do_rf_pulse(calctime(curtime,0),pars.fake_pulse, pars.freq*MHz,pars.pulse_length,0,pars.power);
        end        
        post_wait_time = 0; %VIJIN Oct 29 2018  
    else        
        buildWarning('Spectroscopy','Spectroscopy type unknown!',1);    
    end 
    %Add some time at the end
    curtime = calctime(curtime,post_wait_time);    
    
    timeout = curtime;    
end