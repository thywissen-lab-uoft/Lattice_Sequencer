function [outputArg1,outputArg2] = KuWaveSpectroscopy(timein)
dispLineStr('Performing K uWave Spectroscopy',curtime);

global seqdata
curtime = timein;
%% Mode Select

%     uWaveMode='rabi';
%     uWaveMode='sweep_field';
%     uWaveMode='sweep_frequency_chirp';
      uWaveMode='sweep_frequency_HS1';

    use_ACSync = 1;
    %% uWave Frequency Settings   
    

    % Define the SRS frequency
    freq_list = [0] ;
    freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'uwave_freq_offset','kHz');
    
    disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);
    
    % SRS settings (may be overwritten later)
    uWave_opts=struct;
    uWave_opts.Address=28;                            % K uWave ("SRS B");
    uWave_opts.Frequency=1338.345 + freq_offset/1000; % Frequency in MHz    
    uWave_opts.Power=15;%12 15                        % Power in dBm
    uWave_opts.Enable=1;                              % Enable SRS output    

    addOutputParam('uwave_pwr',uWave_opts.Power,'dBm')
    addOutputParam('uwave_frequency',uWave_opts.Frequency,'MHz');    
    
    % Make sure RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-50),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-50),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-50),'K uWave TTL',0);

    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-40),'RF/uWave Transfer',1); 
    
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-30),'K/Rb uWave Transfer',0);

    % RF Switch for K SRS depreciated?
    setDigitalChannel(calctime(curtime,-20),'K uWave Source',1);  
    
    
    setDigitalChannel(calctime(curtime,-20),'SRS Source',1);  
    
    % Set initial modulation
    setAnalogChannel(calctime(curtime,-50),'uWave FM/AM',-1);
    
switch uWaveMode
    case 'rabi'
        disp(' uWave Rabi Oscillations');
        
        % Disable the frquency sweep
        uWave_opts.EnableSweep=0;                    
        uWave_opts.SweepRange=1;  
        
        % Time to have uWaves on
        uwave_time_list=[1];
        uwave_time = getScanParameter(uwave_time_list,seqdata.scancycle,...
            seqdata.randcyclelist,'uwave_pulse_time');
 
        % Set uWave power (func1: V, fucn2: normalized)
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',10,1);    
        %setAnalogChannel(calctime(curtime,-10),'uWave VVA',1,2);     %
        %func2: 0 : 0 rabi, 1 : max rabi

        % Set modulation to none (should be ignored regardless)
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',0);
        
        % Turn on ACync
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end       
        
        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        % Wait
        curtime = calctime(curtime,uwave_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
    case 'sweep_field'
        % THIS HAS NOT BEEN TESTED YET
        disp(' Landau-Zener Sweep B-Field');
        uWave_opts.EnableSweep=0;                    
        uWave_opts.SweepRange=1;                   

        % Set uWave power
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',10);
        
        % Sweep the magnetic field to perform Landau-Zener sweep
        
        % Define sweep range (MHz)
        delta_freq_list=[20/1000];[500/1000];  
        delta_freq=getScanParameter(delta_freq_list,seqdata.scancycle,seqdata.randcyclelist,'delta_freq');
        
        % Define sweep time (ms)
         sweep_time_list =[delta_freq*1000/5]; 
%         sweep_time_list =[6 7 8 9]; 
        sweep_time = getScanParameter(sweep_time_list,seqdata.scancycle,seqdata.randcyclelist,'sweep_time');
        
        % Convert sweep range to current of z shim
        dBz = delta_freq/(-5.714); % -5.714 MHz/A for Z shim (2015/01/29)         

        % Define the magnetic field sweep
        Bzc = getChannelValue(seqdata,'Z Shim',1,0);
        Bzi = Bzc-dBz/2;
        Bzf = Bzc+dBz/2;
        
        % Time to shift shims to intial/final values
        field_shift_time=5;      
       
        % Time wait after ramping shims (for field settling);
        field_shift_offset = 15;     
        
        % Display summary
        disp(['     Field Shift (kHz) : ' num2str(1E3*delta_freq)]);
        disp(['     Ramp Time   (ms)  : ' num2str(sweep_time)]);
        
        % Ramp Z Shim to initial field of sweep before uWave        
        ramp=struct;
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = -field_shift_offset; 
        ramp.zshim_final = Bzi;
        ramp_bias_fields(calctime(curtime,0), ramp);

        % Ramp Z Shim to final field of sweep during uWave
        ramp=struct;
        ramp.shim_ramptime = sweep_time;
        ramp.shim_ramp_delay = 0;                   
        ramp.zshim_final = Bzf;
        ramp_bias_fields(calctime(curtime,0), ramp);

        % Ramp Z Shim back to original field after uWave
        clear('ramp');
        ramp=struct;
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = sweep_time+field_shift_offset;
        ramp.zshim_final = Bzc;            
        ramp_bias_fields(calctime(curtime,0), ramp);
        
        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1); 
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
        
    case 'sweep_frequency_chirp'
        disp(' Landau-Zener Sweep uWave Frequency');
        
        
        uWave_delta_freq_list=[50];
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq','kHz');
        
        uwave_sweep_time_list =[50]; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Sweep Time   : ' num2str(sweep_time) ' ms']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq*1e-3;   

        % Set uWave power
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',2.5);
        
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        
        % Ramp the SRS modulation 
        % At +-1V input for +- full deviation
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',@(t,T) -1+2*t/T,sweep_time,sweep_time);
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
        
    case 'sweep_frequency_HS1'
        disp('HS1 Sweep Pulse');
        
        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta',beta);
        
        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp',env_amp);


        % Determine the range of the sweep
        uWave_delta_freq_list=[10]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_delta_freq');
        
        
        uwave_sweep_time_list =[50]; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time');     
        
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        % Set uWave power to low
        setAnalogChannel(calctime(curtime,-10),'uWave VVA',0);
         
        % Set initial modulation
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);
        
        if use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);    
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);
        
        % Sweep the VVA (use voltage func 2 to invert the vva transfer
        % curve (normalized 0 to 10
        AnalogFunc(calctime(curtime,0),'uWave VVA',...
            @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp,2);
        
        % Wait
        curtime = calctime(curtime,sweep_time);
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0); 
        
        % Turn off VVA
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);

        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);
    
    otherwise
        error('Invalid uwave flag request. (you fucked up)');    
end

% Turn ACync off 20 ms after pulses
if use_ACSync
    setDigitalChannel(calctime(curtime,20),'ACync Master',0);
end

% Program the SRS
programSRS(uWave_opts); 
    
% Wait a bit for future pieces of code (should get rid of this)
curtime = calctime(curtime,20);  
end

