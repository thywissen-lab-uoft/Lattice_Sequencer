function curtime = dipole_high_field_a(timein)
 
        curtime = timein;
        
%% Flags
        
        %This is a way of doing normal high field imaging from the ODT using the seqdata.flags.High_Field_Imaging flag from the load magtrap sequence
%     if (seqdata.flags.High_Field_Imaging)             % Use this flag if
%     you still want to ramp the high field from ODT and then load lattice
%     on the atrractive side of the resonance. 
        dispLineStr('Ramping High Field in XDT',curtime);
        time_in_HF_imaging = curtime;
                
        spin_flip_9_7 = 0;
        do_raman_spectroscopy = 0;
        spin_flip_7_5 = 0;        
        rabi_manual=0;
        rf_rabi_manual = 0;
        do_rf_spectroscopy= 0; % 
        do_rf_post_spectroscopy =0;
        shift_reg_at_HF = 0;
        ramp_field_2 = 0;
                do_rf_spectroscopy_old = 0;

        spin_flip_9_7_again = 0;
        spin_flip_7_5_again= 0;
        
        ramp_field_3 = 0;
        spin_flip_7_5_3 = 0;
        
        ramp_field_for_imaging = 0;
        spin_flip_7_5_4 = 0;

%% Feshbach Field Ramp
    HF_FeshValue_Initial_List =[190]; %200.5 201 201.5
    HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_ODT','G');
     
%     HF_FeshValue_Initial = paramGet('HF_FeshValue_Initial');
%             Define the ramp structure
            ramp=struct;
            ramp.shim_ramptime = 150;
            ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
            ramp.xshim_final = seqdata.params.shim_zero(1); 
            ramp.yshim_final = seqdata.params.shim_zero(2);
            ramp.zshim_final = seqdata.params.shim_zero(3);
            % FB coil 
            ramp.fesh_ramptime = 150;
            ramp.fesh_ramp_delay = 0;
            ramp.fesh_final = HF_FeshValue_Initial; %22.6
            ramp.settling_time = 100;    
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');

%     seqdata.params.HF_fb = HF_FeshValue_Initial;
    seqdata.params.HF_probe_fb =  HF_FeshValue_Initial;
    
%% Transfer -9/2 to -7/2

    if spin_flip_9_7
        clear('sweep');
        % Get the field to do the sweep at
        B = HF_FeshValue_Initial; 
        
        % The shift shift list
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF');        
        
        % RF pulse parameters
        sweep_pars.power =  [0];
        delta_freq =1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 100;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

        % Perform the spectroscopy
        curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        
        % Wait a hot second
        HF_wait_time_list = [30];
        HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_ODT','ms');
    
curtime = calctime(curtime,HF_wait_time);

        % What was the purpose of two sweeps? (There and back?)
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse


        % Use the ACYnc (but it refers to back in time?)
        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
    end
%%  Raman Spectroscopy
% Raman spec in ODT? What for (CF 2022/10/05); it's been a while and i
% forgot
    if do_raman_spectroscopy

        mF1=-9/2;   % Lower energy spin state
        mF2=-7/2;   % Higher energy spin state

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        Boff = 0.11;
        zshim = 0;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        

        if (abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        Raman_AOM3_freq_list =  [0]*1e-3/2+(80+...   %-88 for 300Er, -76 for 200Er
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; %-0.14239
        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        
%            freq = paramGet('Raman_freq');
%            Raman_AOM3_freq = freq*1e-3/2+(80+...   
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; 
        
        Raman_AOM3_pwr_list = 0.66; %0.66
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
    
%           RamanspecMode = 'sweep';
        RamanspecMode = 'pulse';
        
        % R3 beam settings
        switch RamanspecMode
            case 'sweep'
                Sweep_Range_list = [5]/1000;  %in MHz
                Sweep_Range = getScanParameter(Sweep_Range_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
                Sweep_Time_list = [1]; %1 in ms
                Sweep_Time = getScanParameter(Sweep_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

                str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                    Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                Raman_on_time = Sweep_Time;
                Pulse_Time = Sweep_Time;

            case 'pulse'
                Pulse_Time_list = [100];[0:0.015:0.15];
                Pulse_Time = getScanParameter(Pulse_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                Raman_on_time = Pulse_Time; %ms
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        end


        addVISACommand(Device_id, str);
        % R2 beam settings
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list = 0.30; %0.51
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
                seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
                Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

        raman_old= 1; 
        if raman_old
            %Raman spectroscopy AOM-shutter sequence
            %we have three TTLs to independatly control R1, R2 and R3
            raman_buffer_time = 10;
            shutter_buffer_time = 5;

            if Pulse_Time == 0
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R2 temporarily for shutter

                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',...
                    Raman_on_time+(raman_buffer_time)*2,0); %turn off R3 temporarily for shutter

                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep
            else
                setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 temporarily for shutter

                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 temporarily for shutter
                DigitalPulse(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 temporarily for shutter


                DigitalPulse(calctime(curtime,-shutter_buffer_time),'Raman Shutter',...
                    Raman_on_time+shutter_buffer_time*2,1);% open shutter 100ms before and close 100ms after the sweep

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 2a',raman_buffer_time,0); %turn off R2 after the sweep and turn on 150ms later

                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later
                DigitalPulse(calctime(curtime,Raman_on_time),'Raman TTL 3a',raman_buffer_time,0); %turn off R3 after the sweep and turn on 150ms later

                setDigitalChannel(calctime(curtime,Raman_on_time+ ...
                    raman_buffer_time),'Raman TTL 1',1); %turn on R1 150ms after the sweep has ended

            end
curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);
    else

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
        raman_buffer_time = 10;
        shutter_buffer_time = 5;

        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 1',0); %turn off R1 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2',0); %turn off R2 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 2a',0); %turn off R2 AOM

        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3',0); %turn off R3 AOM
        setDigitalChannel(calctime(curtime,-raman_buffer_time),'Raman TTL 3a',0); %turn off R3 AOM

        setDigitalChannel(calctime(curtime,-shutter_buffer_time),'Raman Shutter',1); %turn on shutter

        setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %turn on R2
        setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1); %turn on R2

        setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %turn on R3
        setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1); %turn on R3


        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2a',0); %turn off R2

        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 3',0); %turn off R3 after pulse
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 3a',0); %turn off R3 after pulse

curtime = calctime(curtime, Raman_on_time);

        end
    
    
    end    
%%  rf transfer from -7/2 to -5/2
        
    if spin_flip_7_5
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
        disp(sweep_pars.freq)
    
        % Sweep parameters
        sweep_pars.power =  [0];
        delta_freq = 0.1; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 10;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Wait a second
        HF5_wait_time_list = [50];
        HF5_wait_time = getScanParameter(HF5_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
     curtime = calctime(curtime,HF5_wait_time);
%          sweep_pars.delta_freq  = -delta_freq; 0.025;0.1;
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

    % ACYnc usage
    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
    end
%% Rabi oscillations 1
    if rabi_manual
        mF1=-7/2;
        mF2=-9/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        B = HF_FeshValue_Initial; 
        rf_list = [-2]*1e-3 +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_rabi_freq_HF');
        power_list =  [2.5];
        rabi.power = getScanParameter(power_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF');            
%             rf_pulse_length_list = [0.5]/15;
        rf_pulse_length_list = [0.005:0.005:.155];      
        rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF');  % also is sweep length  0.5               

        % Define the frequency
        dTP=0.1;
        DDS_ID=1; 
        sweep=[DDS_ID 1E6*rabi.freq 1E6*rabi.freq rabi.pulse_length+2];


        disp(rabi);

        % Preset RF Power
        setAnalogChannel(calctime(curtime,0),'RF Gain',rabi.power);         
        setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);             

        do_ACync_rf = 1;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,1);
            ACync_end_time = calctime(curtime,1+rabi.pulse_length+35);
            curtime=setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);                
        end         

        % Wait 5 ms to get ready
        curtime=calctime(curtime,5);           

        if rabi.pulse_length>0                
            % Trigger the DDS 1 ms ahead of time
            DigitalPulse(calctime(curtime,-1),'DDS ADWIN Trigger',dTP,1);  
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;     

            % Turn on RF
            setDigitalChannel(calctime(curtime,0),'RF TTL',1);      

            % Advance by pulse time
            curtime=calctime(curtime,rabi.pulse_length);

            % Turn off RF
            setDigitalChannel(curtime,'RF TTL',0);   
        end

        setAnalogChannel(calctime(curtime,1),'RF Gain',-10);         

        % Extra Wait Time
        curtime=calctime(curtime,35);            
    end    
        
%%  RF Rabi Oscillations 2
    if rf_rabi_manual
        mF1=-7/2;
        mF2=-9/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        Boff = 0.11;
        zshim = 0;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;            
        rf_list =  [-2]*1e-3 +... 
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6); 
        rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];       
        
          if (rabi.freq < 10)
                         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
          end
          
%           rf_pulse_length_list = [1.005:0.01:1.095 3.005:0.01:3.095];  %0.23
%           rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
%             seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               
%         
            rabi.pulse_length = paramGet('rf_rabi_time_HF');

        rabi_source = 'DDS';
%         rabi_source = 'SRS';
        
        switch rabi_source
            case 'DDS' 
                    power_list =  [2.5]; 2.5;
                    rabi.power = getScanParameter(power_list,...
                        seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF','V');            
                        %rf_pulse_length_list = [0.5]/15;
                    % Define the frequency
                    dTP=0.1;
                    DDS_ID=1; 
                    sweep=[DDS_ID 1E6*rabi.freq 1E6*rabi.freq rabi.pulse_length+2];


                    % Preset RF Power
                    setAnalogChannel(calctime(curtime,-5),'RF Gain',rabi.power);         
                    setDigitalChannel(calctime(curtime,-5),'RF/uWave Transfer',0);             

                    % Enable the ACync
                    do_ACync_rf = 0;
                    if do_ACync_rf
                        ACync_start_time = calctime(curtime,1);
                        ACync_end_time = calctime(curtime,1+rabi.pulse_length+35);
                        curtime=setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);                
                    end         

                    % Apply the RF
                    if rabi.pulse_length>0                
                        % Trigger the DDS 1 ms ahead of time
                        DigitalPulse(calctime(curtime,-1),'DDS ADWIN Trigger',dTP,1);  
                        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;     

                        % Turn on RF
                        setDigitalChannel(calctime(curtime,0),'RF TTL',1);      

                        % Advance by pulse time
                        curtime=calctime(curtime,rabi.pulse_length);
                        
                        if ~do_rf_post_spectroscopy
                        % Turn off RF
                        setDigitalChannel(curtime,'RF TTL',0);   
                        end
                    end

                    % Lower the power
                    setAnalogChannel(calctime(curtime,0),'RF Gain',-10);             

                    % Extra Wait Time
                    curtime=calctime(curtime,1);  
                    
            case 'SRS'
            %under development  
        end
       
    end  
%% RF Spectrscopy OLD
        if do_rf_spectroscopy_old
            mF1=-7/2;   % Lower energy spin state
            mF2=-5/2;   % Higher energy spin state
            
            % Get the center frequency
            B = HF_FeshValue_Initial; 
            rf_list =  [-0.105:0.01:0.085] +...
                abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
            rf_freq_HF = getScanParameter(rf_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_freq_HF','MHz');
            
            % Define the sweep parameters
            delta_freq=.02; %0.02
            rf_pulse_length_list =1;%1
            rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
                seqdata.randcyclelist,'rf_pulse_length');
            
            freq_list=rf_freq_HF+[...
                -0.5*delta_freq ...
                -0.5*delta_freq ...
                0.5*delta_freq ...
                0.5*delta_freq];            
            pulse_list=[2 rf_pulse_length 2];
            
            % Max rabi frequency in volts (uncalibrated for now)
            off_voltage=-10;
            peak_voltage=2.5;
            
            % Display the sweep settings
            disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
            disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
            disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
            disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);

    
            % Set RF gain to zero a little bit before
            setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   
            
            % Turn on RF
            setDigitalChannel(curtime,'RF TTL',1);   
        
            % Set to RF
            setDigitalChannel(curtime,'RF/uWave Transfer',0);   

            
            do_ACync_rf = 1;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-30);
                ACync_end_time = calctime(curtime,sum(pulse_list)+30);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
            
            % Trigger pulse duration
            dTP=0.1;
            DDS_ID=1;
            
            % Initialize "Sweep", ramp up power        
            sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
            DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
            curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                pulse_list(1),pulse_list(1),peak_voltage); 
            
            % Primary Sweep, constant power            
            sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
            DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
            curtime=calctime(curtime,pulse_list(2));
            
            % Final "Sweep", ramp down power
            sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
            DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
            curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                pulse_list(1),pulse_list(1),off_voltage); 
            
            % Turn off RF
            setDigitalChannel(curtime,'RF TTL',0);               
            
            % Extra Wait Time
            curtime=calctime(curtime,35);            
        end   
        
%% RF Spectroscopy
    % RF Sweep Spectroscopy new with DDS/SRS (same code as in load lattice)
    if do_rf_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        
        % Get the center frequency
        zshim = 0;
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        
%          rf_shift_list = [-20:2:10];       
%         rf_shift = getScanParameter(rf_shift_list,seqdata.scancycle,...
%                         seqdata.randcyclelist,'rf_freq_HF_shift','kHz');
         
%             rf_shift = paramGet('rf_freq_HF_shift');
        rf_shift = 0;
        
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        % Define the sweep parameters
        delta_freq= 0.1; %0.00125; %.0025;  in MHz            
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

        % RF Pulse 
        rf_pulse_length_list = 2; %ms
        rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_pulse_length');
        
%         sweep_type = 'DDS';
        sweep_type = 'SRS_HS1';
        
        switch sweep_type
            case 'DDS'
                freq_list=rf_freq_HF+[...
                    -0.5*delta_freq ...
                    -0.5*delta_freq ...
                    0.5*delta_freq ...
                    0.5*delta_freq];            
                pulse_list=[2 rf_pulse_length 2];

                % Max rabi frequency in volts (uncalibrated for now)
                off_voltage=-10;
                peak_voltage=2.5;

                % Display the sweep settings
                disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
                disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
                disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
                disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


                % Set RF gain to zero a little bit before
                setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

                % Turn on RF
                setDigitalChannel(curtime,'RF TTL',1);   

                % Set to RF
                setDigitalChannel(curtime,'RF/uWave Transfer',0);   

                do_ACync_rf = 0;
                if do_ACync_rf
                    ACync_start_time = calctime(curtime,-30);
                    ACync_end_time = calctime(curtime,sum(pulse_list)+30);
                    setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                    setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
                end

                % Trigger pulse duration
                dTP=0.1;
                DDS_ID=1;

                % Initialize "Sweep", ramp up power        
                sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),peak_voltage); 

                % Primary Sweep, constant power            
                sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=calctime(curtime,pulse_list(2));

                % Final "Sweep", ramp down power
                sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),off_voltage); 

                % Turn off RF
                setDigitalChannel(curtime,'RF TTL',0);               

                % Extra Wait Time
                curtime=calctime(curtime,10);    
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  

                rf_srs_power_list = [4];
                rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_srs_power','dBm');
%                 rf_srs_power = paramGet('rf_srs_power');
                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address='192.168.1.120';                       % K uWave ("SRS B");
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_srs_power;                           
                rf_srs_opts.Frequency = rf_freq_HF;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
                disp(['     Freq Delta   : ' num2str(delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;                    
                rf_srs_opts.SweepRange=abs(delta_freq);  
                

                
                
                % Set SRS Source to the new one
                setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

                % Set SRS Direction to RF
                setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

               

                % Set initial modulation
                setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
                rf_rabi_manual =0;
                if rf_rabi_manual
                    setDigitalChannel(calctime(curtime,...
                         rf_wait_time + extra_wait_time),'RF Source',1); 
                    setAnalogChannel(calctime(curtime,...
                         rf_wait_time + extra_wait_time),'RF Gain',rf_off_voltage);
                else    
                 % Set RF power to low
                setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);
                     
                 % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,-5),'RF Source',1);

                end
                    
                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'RF TTL',1);    

                % Ramp the SRS modulation using a TANH
                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'uWave FM/AM',...
                    @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,1);

                % Sweep the linear VVA
                AnalogFunc(calctime(curtime,...
                    rf_wait_time  + extra_wait_time),'RF Gain',...
                    @(t,T,beta) -10 + ...
                    20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta);

                % Wait for Sweep
%                             curtime = calctime(curtime,rf_pulse_length);



                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF Gain',rf_off_voltage);
                
                if ~do_rf_post_spectroscopy
                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length+1),'RF Source',0);
                setDigitalChannel(calctime(curtime,...
                     rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source',1);
                end 
                

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
                params.isProgrammedSRS = 1;
                
                 % Extra Wait Time
                 
                HF_hold_time_list = [40];
                HF_hold_time = getScanParameter(HF_hold_time_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'HF_hold_time_ODT','ms');
% %                 
%                 HF_hold_time = paramGet('HF_hold_time');
                
                curtime=calctime(curtime,HF_hold_time); 
                
                if HF_hold_time > 1
                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length-HF_hold_time),'RF TTL',0); 
                end
                
        end  
    end
    
%% RF Post Spectroscopy  
    
    if do_rf_post_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);

        % Get the center frequency
        Boff = 0.11;
        zshim =0;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
%         rf_shift = 15;

        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end
          
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

%         sweep_type = 'DDS';
        sweep_type = 'SRS_HS1';
        
        switch sweep_type
            case 'DDS'
                freq_list=rf_freq_HF+[...
                    -0.5*delta_freq ...
                    -0.5*delta_freq ...
                    0.5*delta_freq ...
                    0.5*delta_freq];            
                pulse_list=[0.1 rf_pulse_length 0.1];

                % Max rabi frequency in volts (uncalibrated for now)
                off_voltage=-10;
                peak_voltage=5;

                % Display the sweep settings
                disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
                disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
                disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
                disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


                % Set RF gain to zero a little bit before
%                 setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

                % Turn on RF
                setDigitalChannel(curtime,'RF TTL',1);   

                % Set to RF
                setDigitalChannel(curtime,'RF/uWave Transfer',0);   

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
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),peak_voltage); 

                % Primary Sweep, constant power            
                sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=calctime(curtime,pulse_list(2));

                % Final "Sweep", ramp down power
                sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),off_voltage); 

                % Turn off RF
                setDigitalChannel(curtime,'RF TTL',0);               

                % Extra Wait Time
                curtime=calctime(curtime,35);    
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  
                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address=29;                       % Rb SRS temporarily used here;
                rf_srs_opts.EnableBNC=1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_srs_power;                           
                rf_srs_opts.Frequency = rf_freq_HF;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
                disp(['     Freq Delta   : ' num2str(delta_freq*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;     
%                 rf_srs_opts.Enable=1;          % Power on
                rf_srs_opts.SweepRange=abs(delta_freq);  
                
                if rf_rabi_manual
                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,0),'RF Source',1);
                % Set SRS Source to the new one
                setDigitalChannel(calctime(curtime,0),'SRS Source',0);
                end  

% 
%                 % Set SRS Direction to RF
%                 setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set SRS source post spec to Rb one
                setDigitalChannel(calctime(curtime,0),'SRS Source post spec',1);


                % Set RF power to low
                setAnalogChannel(calctime(curtime,0),'RF Gain',rf_off_voltage);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,0),'uWave FM/AM',1);

                % Turn on the RF
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'RF TTL',1);    

                % Ramp the SRS modulation using a TANH
                % At +-1V input for +- full deviation
                % The last argument means which votlage fucntion to use
                AnalogFunc(calctime(curtime,...
                    rf_wait_time + extra_wait_time),'uWave FM/AM',...
                    @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,1);

                % Sweep the linear VVA
                AnalogFunc(calctime(curtime,...
                    rf_wait_time  + extra_wait_time),'RF Gain',...
                    @(t,T,beta) -10 + ...
                    20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta);

                % Wait for Sweep
%                             curtime = calctime(curtime,rf_pulse_length);

                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF TTL',0); 

                % Turn off VVA
                setAnalogChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length),'RF Gain',rf_off_voltage);

                % Set RF Source to SRS
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length+1),'RF Source',0);
                
                setDigitalChannel(calctime(curtime,...
                     rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source',1);
                
                 
                 setDigitalChannel(calctime(curtime,...
                      rf_wait_time + extra_wait_time+rf_pulse_length+1),'SRS Source post spec',0);

                % Program the SRS
                programSRS_BNC(rf_srs_opts); 
                params.isProgrammedSRS = 1;
                
                 % Extra Wait Time
                curtime=calctime(curtime,35);    

                
        end  
    end
%% Shift Register
    %Do shift register
    if shift_reg_at_HF
        dispLineStr('Performing shift register in XDT',curtime);
        clear('sweep');
        B = HF_FeshValue_Initial; 
        f1 = (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
        f2 = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        rf_list =(f1+f2)/2; 
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rfSR_freq_HF');
        sweep_pars.power_list =  [0];
        sweep_pars.power = getScanParameter( sweep_pars.power_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_power_HF');
        delta_freq_list = 3.5; 0.1;
        sweep_pars.delta_freq = getScanParameter(delta_freq_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_deltaFreq_HF');
        rf_pulse_length_list =40; 20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rfSR_time_HF');  % also is sweep length  0.5               

        disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);
        disp([' Sweep Delta      (MHz) : ' num2str(sweep_pars.delta_freq)]);

        n_sweeps_mix_list=[1];
        n_sweeps_mix = getScanParameter(n_sweeps_mix_list,...
            seqdata.scancycle,seqdata.randcyclelist,'n_sweeps');  % also is sweep length  0.5               

        % Perform the first sweep            
        disp(['Sweep Number ' num2str(1) ]);
%             curtime = calctime(curtime,100);
        curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Perform any additional sweeps
        for kk=2:n_sweeps_mix
            disp(['Sweep Number ' num2str(kk) ]);
            curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);%3: sweeps, 4: pulse
        end

    end
%% Field Ramp 2
seqdata.params.HF_probe_fb = HF_FeshValue_Initial;  

   if ramp_field_2
    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [209]; % 206 207 208 209 210 211
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_ODT','G');
 
    % Define the ramp structure
    ramp=struct;
    ramp.FeshRampTime = 100;
    ramp.FeshRampDelay = -0;
    ramp.FeshValue = HF_FeshValue_Final;
    ramp.SettlingTime = 50; 50;    
    
    % Ramp the magnetic Fields
curtime = rampMagneticFields(calctime(curtime,0), ramp);
    
    seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    HF_FeshValue_Initial = HF_FeshValue_Final;
    end
%  curtime = calctime(curtime,100);

 %% Spin Flip 97 again
 if spin_flip_9_7_again
    clear('sweep');
    B = HF_FeshValue_Initial; 
    rf_list =  [0] +...
        (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
    %rf_list = 48.3758; %@209G  [6.3371]; 
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_freq_HF');
    sweep_pars.power =  [0];
    delta_freq =1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = 100;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

        % Do the RF
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Wait a hot second
 HF_wait_time_list = [30];
 HF_wait_time = getScanParameter(HF_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_ODT','ms');
curtime = calctime(curtime,HF_wait_time);

    % ACYNC
    do_ACync_rf = 0;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-80);
        ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
 end
 
 %% RF 75 Flip again
  if spin_flip_7_5_again
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
        disp(sweep_pars.freq)

        sweep_pars.power =  [0];
        delta_freq = 0.1; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 10;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%double pulse sequence
% curtime = calctime(curtime,35);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,50);

    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
  end
  
%% Ramp Field 3
     if ramp_field_3

        clear('ramp');
        HF_FeshValue_List =[210];
        HF_FeshValue = getScanParameter(HF_FeshValue_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_ODT_3','G');           
%         
%         HF_FeshValue = paramGet('HF_FeshValue_ODT_3');
      
        HF_FeshValue_Initial = HF_FeshValue; %For use below in spectroscopy
        seqdata.params.HF_probe_fb = HF_FeshValue; %For imaging

        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_shimvalue_ODT_3','A');
        
        ramptime2 = 50;
          % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = ramptime2;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
        % FB coil 
        ramp.fesh_ramptime = ramptime2;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
 
    % Hold time at the end
     HF_wait_time_list = [0];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');
    
curtime = calctime(curtime,HF_wait_time);
  
     end
%% Spin Flip 75 Number 3 
% What is this? uhh some kind of shift register operation?
    if spin_flip_7_5_3
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        B = HF_FeshValue_Initial +2.35*zshim+0.11; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF_3','MHz');
        disp(sweep_pars.freq)

        sweep_pars.power =  [0];
        delta_freq = 0.1; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 10;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%double pulse sequence
curtime = calctime(curtime,35);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,50);

        do_ACync_rf = 0;
            if do_ACync_rf
                ACync_start_time = calctime(curtime,-80);
                ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
                setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
            end
    end
  
 %% Ramp field for imaging
   if ramp_field_for_imaging

    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [195]; % 206 207 208 209 210 211
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Imaging_ODT','G');
 
 % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final;
   end
%% Spin Flip 75 Number 4
 if spin_flip_7_5_4
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        B = seqdata.params.HF_probe_fb; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
        disp(sweep_pars.freq)

        sweep_pars.power =  [0];
        delta_freq = 0.1; 
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 10;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
  end

 HF5_wait_time_list = [35];
 HF5_wait_time = getScanParameter(HF5_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
end