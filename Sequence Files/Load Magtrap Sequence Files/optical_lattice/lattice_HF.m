function [curtime] = lattice_HF(timein)
global seqdata
curtime = timein;
 % Typical Experimental Sequence
    % - Ramp lattices up to 200Er
    % - Ramp field up to 197G
    % - Create 99 doublons via Raman n-->n+1 pulse
    
    dispLineStr('Ramping High Field in Lattice',curtime);

    ScopeTriggerPulse(curtime,'Lattice HF');

    time_in_HF_imaging = curtime;
    HF_FeshValue_Initial = getChannelValue(seqdata,'FB current');
    seqdata.params.HF_probe_fb = HF_FeshValue_Initial;
    addOutputParam('HF_FeshValue_Initial_Lattice',HF_FeshValue_Initial,'G');
    zshim = 0;
    
    % Get the calibrated magnetic field
    Boff = 0.11;
    B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;       
  
    %% Flags

    % Initialization of Field And Lattice
    lattice_ramp_1                  = 0;       % Initial lattice ramp    
    field_ramp_init                 = 1;       % Ramp field away from initial  
    
    % Initial Spectroscopy 
    do_raman_phantom                = 0;       % Apply a phatom Raman pulse to kill atoms
    rf_97_flip_init                 = 0;       % RF Pre Flip 9<-->7data.params       
    
    % Initialize p-wave state
    lattice_ramp_2                  = 0;       % Secondary lattice ramp before spectroscopy
    pulse_raman                     = 0;       % apply a Raman pulse with only the R2 beam
    do_raman_spectroscopy           = 0; 

    % Alternative Raman preparation (??)
    raman_short_sweep               = 0;
    
    spin_flip_7_5                   = 0;       % 75 spectroscpoy/flip
    
    % Field and Lattice Ramp
    field_ramp_2                    = 0;       % ramp field after raman before rf spectroscopy   
    lattice_ramp_3                  = 0;       % between raman and rf spectroscopy
    
    % More RF Stuff (?)
    rf_rabi_manual                  = 0;
    doPA_pulse                      = 1;
    do_rf_spectroscopy              = 0; 
    do_rf_post_spectroscopy         = 0; 
        
    do_raman_spectroscopy_post_rf   = 0;        % Raman Spectroscopy
    
    % Feshbach field ramps
    field_ramp_img                  = 1;       % Ramp field for imaging
    
    % Other RF Manipulations
    shift_reg_at_HF                 = 0;
    spin_flip_9_7_5                 = 0;
    spin_flip_9_7_post_spectroscopy = 0;
    
  

%% Lattice ramp Init
% Ramp the lattices to their initial depth
    if lattice_ramp_1    
%         Select the depth to ramp
        HF_latt_depth_list = [100];
        HF_latt_depth = getScanParameter(HF_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_depth','Er');
        
        
        % How quickly to ramp
        HF_latt_ramptime_list = [50];
        HF_latt_ramptime = getScanParameter(HF_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_latt_ramptime','ms');
        
        T0 = 0; %pointless offset time
        
        %New calibrations from Feb 18
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_latt_ramptime, HF_latt_ramptime, (HF_latt_depth+0.033)/0.969);
    end   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare Lattice and State %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Feshbach ramp
    
    if field_ramp_init
        % Feshbach Field ramp
        HF_FeshValue_Initial_List = [206]; [197];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_Lattice','G');
        
        
        HF_FeshValue_Initial = paramGet('HF_FeshValue_Initial_Lattice');
%         addOutp
        
        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_zshim_Initial_Lattice','A');

                  % Define the ramp structure
                ramp=struct;
                ramp.shim_ramptime = 150;
                ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
                ramp.xshim_final = seqdata.params.shim_zero(1); 
                ramp.yshim_final = seqdata.params.shim_zero(2);
                ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
                % FB coil 
                ramp.fesh_ramptime = 150;
                ramp.fesh_ramp_delay = 0;
                ramp.fesh_final = HF_FeshValue_Initial; %22.6
                ramp.settling_time = 50;    
    curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
            ScopeTriggerPulse(curtime,'FB_ramp');

        seqdata.params.HF_fb = HF_FeshValue_Initial;
        seqdata.params.HF_probe_fb = HF_FeshValue_Initial;

    end
    
%% Phantom raman pulse
    
    if do_raman_phantom

    Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

    % 
    B = HF_FeshValue_Initial_List;

    Raman_AOM3_freq_list =  [1]/2+(80+...
        abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6))/2; %-0.14239

    Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
    Raman_AOM3_pwr_list = [0.33];
    Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
%         RamanspecMode = 'sweep';
    RamanspecMode = 'pulse';
    RamanMode = RamanspecMode;


    %R3 beam settings
    switch RamanspecMode
        case 'sweep'
            Sweep_Range_list = [10]/1000;  %in MHz
            Sweep_Range = getScanParameter(Sweep_Range_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
            Sweep_Time_list = [1]; %1 in ms
            Sweep_Time = getScanParameter(Sweep_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

            str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
            Raman_on_time = Sweep_Time;

        case 'pulse'
            Pulse_Time_list = [0.1];
            Pulse_Time = getScanParameter(Pulse_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
            Raman_on_time = Pulse_Time; %ms
            str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                Raman_AOM3_freq, Raman_AOM3_pwr);
    end
    addVISACommand(Device_id, str);

    %R2 beam settings
    Device_id = 1;
    Raman_AOM2_freq = 80*1E6;

    Raman_AOM2_pwr_list = 0.4;
    Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

    Raman_AOM2_offset = 0;
    str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

    addVISACommand(Device_id, str);


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

    end   
    
%% RF Sweep -9 to -7

    if rf_97_flip_init
        clear('sweep');
        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        rf_list =  [0.00] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF_pre_spec');
        sweep_pars.power =  [2.5];
        delta_freq = 0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 100;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Display the sweep settings
        disp(['RF Transfer Freq Center    (MHz) : [' num2str(sweep_pars.freq) ']']);
        if (sweep_pars.freq < 1)
            error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end        
curtime = calctime(curtime,35);
    end
%% Lattice ramp 2

    if lattice_ramp_2
        HF_Raman_latt_depth_list = [50];
        HF_Raman_latt_depth = getScanParameter(HF_Raman_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_latt_depth','Er');

        HF_Raman_latt_ramptime_list = [50];
        HF_Raman_latt_ramptime = getScanParameter(HF_Raman_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_latt_ramptime','ms');
        
%New calibrations from Feb 18
 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_Raman_latt_ramptime, HF_Raman_latt_ramptime, (HF_Raman_latt_depth+0.033)/0.969); 

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Perform Spectroscopy Measurements %%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%% Pulse_raman
    
    if pulse_raman
        %only useful in conjuction with raman spec code below. Otherwise
        %shutter won't turn off which is BAAAAD!!!
        Raman_on_time = paramGet('Raman_Pulse_Time');
        
        if Raman_on_time == 0
           curtime = calctime(curtime,25);
 
        else
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
        
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time),'Raman TTL 2a',0); %turn off R2
        curtime = calctime(curtime,25+Raman_on_time);
        end
    end
    
%% Raman spectrscopy
     
    if do_raman_spectroscopy

        mF1=-9/2;   % Lower energy spin state
        mF2=-7/2;   % Higher energy spin state

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;
        

        if (abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6) < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end      
        
        
        Raman_AOM3_freq_list =  [-75]*1e-3/2+(80+...   %-88 for 300Er, -76 for 200Er
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; %-0.14239
        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
%         
%            freq = paramGet('Raman_freq');
%            Raman_AOM3_freq = freq*1e-3/2+(80+...   
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6))/2; 
%            addOutputParam('Raman_AOM3_freq',Raman_AOM3_freq);
% 
%         
        
        Raman_AOM3_pwr_list = 0.680; %0.740
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
                Pulse_Time_list = [0.08];
                Pulse_Time = getScanParameter(Pulse_Time_list,...
                    seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                Raman_on_time = Pulse_Time; %ms
                str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                    Raman_AOM3_freq, Raman_AOM3_pwr);
        end


        addVISACommand(Device_id, str);

        % R2 beam settings
        if ~Raman_transfers     %Rigol cannot be programmed more than once in a sequence
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list = 0.490; %0.51
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
                seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',...
                Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

        end 

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
    
%%  Raman spectroscopy 2
    
    if raman_short_sweep
        %R2 beam settings
        Device_id = 1;
        Raman_AOM2_freq = 80*1E6;

        Raman_AOM2_pwr_list = 0.50;
        Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

        Raman_AOM2_offset = 0;
        str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

        addVISACommand(Device_id, str);


        %R3 beam settings

        Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 
        B = HF_FeshValue_Initial + 2.35*zshim;

        Raman_AOM3_freq_list =  [-63]*1e-3/2+(80+...
            abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6))/2; %-0.14239

        Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
        Raman_AOM3_pwr_list = [0.36];
        Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');



            Sweep_Range_list = [10]/1000;  %in MHz
            Sweep_Range = getScanParameter(Sweep_Range_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
            Sweep_Time_list = [0.1 0.2 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5]; %in ms, resolution = 10us
            Sweep_Time = getScanParameter(Sweep_Time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

        if (Sweep_Time >=1)
            %Do the normal sweep if the sweep time is greater than or equal to
            %1
            str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
            Raman_on_time = Sweep_Time;


            addVISACommand(Device_id, str);


            %Raman spectroscopy AOM-shutter sequence
            %we have three TTLs to independatly control R1, R2 and R3
            raman_buffer_time = 10;
            shutter_buffer_time = 5;

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

            curtime = calctime(curtime, Raman_on_time+(raman_buffer_time)*2);


        else 
            %TTL sequence for shorter sweep
            Rigol_sweep_time = 1;
            Rigol_sweep_range = round(Rigol_sweep_time/Sweep_Time*Sweep_Range,2);

           str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Rigol_sweep_time, Raman_AOM3_freq, Rigol_sweep_range, Raman_AOM3_pwr);


           addVISACommand(Device_id, str);


           AOM_start_time = (Rigol_sweep_time - Sweep_Time)/2;
           AOM_end_time = (Rigol_sweep_time + Sweep_Time)/2;


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

            setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %Trigger R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_start_time),'Raman TTL 2a',1); %turn on R2 AOM

            setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %Trigger R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_start_time),'Raman TTL 3a',1); %turn on R3


            setDigitalChannel(calctime(curtime,Rigol_sweep_time),'Raman TTL 2',0); %turn off R2 Rigol
            setDigitalChannel(calctime(curtime,AOM_end_time),'Raman TTL 2a',0); %turn off R2

            setDigitalChannel(calctime(curtime,Rigol_sweep_time),'Raman TTL 3',0); %turn off R3 Rigol
            setDigitalChannel(calctime(curtime,AOM_end_time),'Raman TTL 3a',0); %turn off R3 after pulse

            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + shutter_buffer_time),'Raman Shutter',0); %turn off shutter

            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 1',1); %turn back on R1 AOM
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 2',1); %turn back on R2 AOM    
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 2a',1); %turn back on R2 AOM  
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 3',1); %turn back on R3 AOM
            setDigitalChannel(calctime(curtime,...
                Rigol_sweep_time + raman_buffer_time),'Raman TTL 3a',1); %turn back on R3 AOM      

            curtime = calctime(curtime, Rigol_sweep_time+(raman_buffer_time)*2);

         end
    end
    
%% Do rf transfer from -7/2 to -5/2
    
    if spin_flip_7_5
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;

        % Get the center frequency
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
        disp(sweep_pars.freq)

        sweep_pars.power =  [-7.5];
        delta_freq = 0.10; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 5;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%      HF5_wait_time_list = [1:10 12:2:20 25:5:100];
%      HF5_wait_time = getScanParameter(HF5_wait_time_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');

%Double pulse sequence
    HF5_wait_time = paramGet('HF_wait_time_5');
    curtime = calctime(curtime,HF5_wait_time);
         
     
     sweep_pars.delta_freq  = -delta_freq; 0.025;0.1;
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);


    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
        
curtime = calctime(curtime,50);

    end
    
%% Feshbach field ramp Another     
    
    if field_ramp_2
        clear('ramp');
        HF_FeshValue_Spectroscopy_List =[200.1];
        HF_FeshValue_Spectroscopy = getScanParameter(HF_FeshValue_Spectroscopy_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Spectroscopy','G');           
%         
%         HF_FeshValue_Spectroscopy = paramGet('HF_FeshValue_Spectroscopy');
      
        HF_FeshValue_Initial = HF_FeshValue_Spectroscopy; %For use below in spectroscopy
        seqdata.params.HF_probe_fb = HF_FeshValue_Spectroscopy; %For imaging

        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_shimvalue_Spectroscopy','A');

%         zshim = paramGet('HF_shimvalue_Spectroscopy');
        
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
        ramp.fesh_final = HF_FeshValue_Spectroscopy;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
 
    % Hold time at the end
     HF_wait_time_list = [0];
     HF_wait_time = getScanParameter(HF_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');
    
curtime = calctime(curtime,HF_wait_time);
    seqdata.params.HF_fb = HF_FeshValue_Spectroscopy;
    seqdata.params.HF_probe_fb = HF_FeshValue_Spectroscopy;

    end         
%% lattice_ramp_3
    if lattice_ramp_3
        HF_spec_latt_depth_list = [300];
        HF_spec_latt_depth = getScanParameter(HF_spec_latt_depth_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_depth','Er');

%         HF_spec_latt_depth = paramGet('HF_spec_latt_depth');

        HF_spec_latt_ramptime_list = [75];
        HF_spec_latt_ramptime = getScanParameter(HF_spec_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_spec_latt_ramptime','ms');
        

%%
%New calibrations from Feb 18
 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth-5.057)/0.898);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth+3.568)/1.095);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            HF_spec_latt_ramptime, HF_spec_latt_ramptime, (HF_spec_latt_depth+0.033)/0.969); 
        
%             disp(x_latt_voltage);
%             disp(y_latt_voltage);
%             disp(z_latt_voltage);            
%             
%             addOutputParam('latt_ramp3_X',x_latt_voltage);
%             addOutputParam('latt_ramp3_Y',y_latt_voltage);
%             addOutputParam('latt_ramp3_Z',z_latt_voltage);
 

curtime = calctime(curtime,5);  %extra wait time
    end
    
%% RF Rabi Oscillations
   
    if rf_rabi_manual
        mF1=-7/2;
        mF2=-9/2;    

        disp(' Rabi Oscillations Manual');
        clear('rabi');
        rabi=struct;          

        Boff = 0.11;
        B = HF_FeshValue_Initial+ Boff+ 2.35*zshim;            
        
%         rf_list =  [15.15]*1e-3 +... 
%             abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6); 
%         rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
%             seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];    
        
        rf_rabi_freq_HF_shift = paramGet('rf_rabi_freq_HF_shift');
        rabi.freq =  rf_rabi_freq_HF_shift*1e-3 +... 
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        addOutputParam('rf_rabi_freq_HF',rabi.freq,'MHz');       

          if (rabi.freq < 10)
                         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
          end
          
%           rf_pulse_length_list = [0.005:0.005:0.075];  %0.23
%           rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
%             seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               
        
       rabi.pulse_length = paramGet('rf_rabi_time_HF');
        
        rabi_source = 'DDS';
%         rabi_source = 'SRS';
        
        switch rabi_source
            case 'DDS' 
                    power_list =  [-1]; 2.5;
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
    
%% PA Pulse

if doPA_pulse
   curtime = PA_pulse(curtime); 
end
    
%% RF Sweep Spectroscopy
    
    if do_rf_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        ScopeTriggerPulse(curtime,'rf_spectroscopy');
        
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        % Get the center frequency
        Boff = 0.11;
        B = HF_FeshValue_Initial + Boff + 2.35*zshim; 
%         
     
         rf_shift_list = [62];
%          rf_shift_list= 10;
         rf_shift = getScanParameter(rf_shift_list,seqdata.scancycle,...
                         seqdata.randcyclelist,'rf_freq_HF_shift','kHz');
                    
%         rf_shift = paramGet('rf_shift');
    
         
%             rf_shift = paramGet('rf_freq_HF_shift');
%         rf_shift = 10;
        
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

        % Define the sweep parameters
        delta_freq_SRS= 0.0025; 0.0025; %0.00125; %.0025;  in MHz            
        addOutputParam('rf_delta_freq_HF_SRS',delta_freq_SRS,'MHz');
        
        delta_freq_DDS = 0.01;
        addOutputParam('rf_delta_freq_HF_DDS',delta_freq_DDS,'MHz');

        % RF Pulse 
        rf_pulse_length_list = 1; 2; %ms
        rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_pulse_length');
        
        sweep_type = 'DDS';
%         sweep_type = 'SRS_HS1';
        
        switch sweep_type
            case 'DDS'
                freq_list=rf_freq_HF+[...
                    -0.5*delta_freq_DDS ...
                    -0.5*delta_freq_DDS ...
                    0.5*delta_freq_DDS ...
                    0.5*delta_freq_DDS];            
                pulse_list=[2 rf_pulse_length 2];

                % Max rabi frequency in volts (uncalibrated for now)
                off_voltage=-10;
                
                peak_voltage_list = 2.5;
                peak_voltage = getScanParameter(peak_voltage_list,seqdata.scancycle,...
            seqdata.randcyclelist,'DDS_RF_HFspec_gain', 'V');

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
                curtime=calctime(curtime,35);    
                
                
            case 'SRS_HS1'
                rf_wait_time = 0.00; 
                extra_wait_time = 0;
                rf_off_voltage =-10;


                disp('HS1 SRS Sweep Pulse');  

                rf_srs_power_list = [5];
                rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'rf_srs_power','dBm');
%                 rf_srs_power = paramGet('rf_srs_power');
                sweep_time = rf_pulse_length;

                rf_srs_opts = struct;
                rf_srs_opts.Address = 28;          
                rf_srs_opts.EnableBNC = 1;                         % Enable SRS output 
                rf_srs_opts.PowerBNC = rf_srs_power;                           
                rf_srs_opts.Frequency = rf_freq_HF;
                % Calculate the beta parameter
                beta=asech(0.005);   
                addOutputParam('rf_HS1_beta',beta);

                disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
                disp(['     Freq Delta   : ' num2str(delta_freq_SRS*1E3) ' kHz']);
                disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
                disp(['     Beta         : ' num2str(beta)]);

                % Enable uwave frequency sweep
                rf_srs_opts.EnableSweep=1;                    
                rf_srs_opts.SweepRange=abs(delta_freq_SRS);     
                
                % Set SRS Source post spec
                setDigitalChannel(calctime(curtime,-5),'SRS Source post spec',0);
                
                % Set SRS Source to the new one
                setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

                % Set SRS Direction to RF
                setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

                % Set initial modulation
                setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
                
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
                            curtime = calctime(curtime,rf_pulse_length);

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
                 
                HF_hold_time_list = [35]+rf_pulse_length;
                HF_hold_time = getScanParameter(HF_hold_time_list,seqdata.scancycle,...
                    seqdata.randcyclelist,'HF_hold_time','ms');
% %                 
%                 HF_hold_time =  rf_pulse_length+ paramGet('HF_hold_time');
                
                curtime=calctime(curtime,HF_hold_time); 
                
                if HF_hold_time > 1
                % Turn off the uWave
                setDigitalChannel(calctime(curtime,...
                    rf_wait_time  + extra_wait_time+rf_pulse_length-HF_hold_time),'RF TTL',0); 
                end
                
        end  
    end
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Post Spectropscy Operations %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% do_rf_post_spectroscopy
   
 if do_rf_post_spectroscopy
        dispLineStr('RF Sweep Spectroscopy',curtime);
        mF1=-7/2;   % Lower energy spin state
        mF2=-9/2;   % Higher energy spin state

        
        % Get the center frequency
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
%         rf_shift = 15;

        rf_freq_HF = f0+rf_shift*1e-3;
        addOutputParam('rf_freq_HF',rf_freq_HF,'MHz');       

        if (rf_freq_HF < 1)
             error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
        end

       

        % Define the sweep parameters
        delta_freq= 0.025; %.0025;  in MHz            
        addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

        % RF Pulse 
%         rf_pulse_length_list = 1; %ms
%         rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
%             seqdata.randcyclelist,'rf_pulse_length');

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

%                 rf_srs_power_list = [6];[10];
%                 rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
%                     seqdata.randcyclelist,'rf_srs_power','dBm');

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
%% do_raman_spectroscopy_post_rf          
    if do_raman_spectroscopy_post_rf
        reset_rigol=0;
        if reset_rigol 

            Device_id = 7; %Rigol for D1 lock(Ch. 1) and Raman 3(Ch. 2). Do not change any Ch. 1 settings here. 

        % 
            B = HF_FeshValue_Initial;

%         Raman_AOM3_freq_list =  [-1]/2+(80+...
%             abs((BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6))/2; %-0.14239

            Raman_AOM3_freq = getScanParameter(Raman_AOM3_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_freq','MHz');
            Raman_AOM3_pwr_list = [0.5];
            Raman_AOM3_pwr = getScanParameter(Raman_AOM3_pwr_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM3_pwr','MHz');
    %         RamanspecMode = 'sweep';
            RamanspecMode = 'pulse';


            %R3 beam settings
            switch RamanspecMode
                case 'sweep'
                    Sweep_Range_list = [10]/1000;  %in MHz
                    Sweep_Range = getScanParameter(Sweep_Range_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_range','MHz');
                    Sweep_Time_list = [1]; %1 in ms
                    Sweep_Time = getScanParameter(Sweep_Time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_Raman_sweep_time','ms');

                    str = sprintf('SOURce2:SWEep:STATe ON;SOURce2:SWEep:TRIGger:SOURce: EXTernal;SOURce2:SWEep:TIME %gMS;SOURce2:FREQuency:CENTer %gMHZ;SOURce2:FREQuency:SPAN %gMHZ;SOURce2:VOLT %g;', ...
                        Sweep_Time, Raman_AOM3_freq, Sweep_Range, Raman_AOM3_pwr);
                    Raman_on_time = Sweep_Time;

                case 'pulse'
                    Pulse_Time_list = [0.020];
                    Pulse_Time = getScanParameter(Pulse_Time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Pulse_Time','ms');
                    Raman_on_time = Pulse_Time; %ms
                    str = sprintf('SOURce2:SWEep:STATe OFF;SOURce2:MOD:STATe OFF; SOURce2:FREQuency %gMHZ;SOURce2:VOLT %gVPP;', ...
                        Raman_AOM3_freq, Raman_AOM3_pwr);
            end


            addVISACommand(Device_id, str);

            %R2 beam settings
            if ~Raman_transfers     %Rigol cannot be programmed more than once in a sequence
            Device_id = 1;
            Raman_AOM2_freq = 80*1E6;

            Raman_AOM2_pwr_list = 0.4;
            Raman_AOM2_pwr = getScanParameter(Raman_AOM2_pwr_list,...
            seqdata.scancycle,seqdata.randcyclelist,'Raman_AOM2_pwr','MHz');

            Raman_AOM2_offset = 0;
            str=sprintf(':SOUR2:APPL:SIN %f,%f,%f;',Raman_AOM2_freq,Raman_AOM2_pwr,Raman_AOM2_offset);

            addVISACommand(Device_id, str);

            end 

        end
        Raman_on_time_2 = Pulse_Time; %ms 

        %Raman spectroscopy AOM-shutter sequence
        %we have three TTLs to independatly control R1, R2 and R3
        raman_buffer_time = 10;
        shutter_buffer_time = 5;

        setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1); %turn on R2
        setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1); %turn on R2

        setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1); %turn on R3
        setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1); %turn on R3
        
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 2',0); %turn off R2
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 2a',0); %turn off R2

        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 3',0); %turn off R3 after pulse
        setDigitalChannel(calctime(curtime,Raman_on_time_2),'Raman TTL 3a',0); %turn off R3 after pulse

        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + shutter_buffer_time),'Raman Shutter',0); %turn off shutter
        
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 1',1); %turn back on R1 AOM
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 2',1); %turn back on R2 AOM     
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 2a',1); %turn back on R2 AOM    
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 3',1); %turn back on R3 AOM
        setDigitalChannel(calctime(curtime,...
            Raman_on_time_2 + raman_buffer_time),'Raman TTL 3a',1); %turn back on R3 AOM
        
curtime = calctime(curtime, Raman_on_time_2+(raman_buffer_time)*2);

        % Extra Wait Time
curtime=calctime(curtime,35);  
           
           
    end
    
%% RF shift register
    
    if shift_reg_at_HF
        dispLineStr('Shift register high field in Lattice',curtime);
        clear('sweep');
        B = HF_FeshValue_Initial; 
        f1 = (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
        f2 = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        rf_list =(f1+f2)/2; 
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_SR');
        sweep_pars.power =  [0];
        delta_freq = +3;-3.5; 0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;[40]; 20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'shift_reg_length');  % also is sweep length  0.5               

        disp([' Center Frequency (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Sweep Time        (ms) : ' num2str(sweep_pars.pulse_length)]);
        disp([' Sweep Delta      (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp([' f_low      (MHz) : ' num2str(sweep_pars.freq-0.5*sweep_pars.delta_freq)]);
        disp([' f_high      (MHz) : ' num2str(sweep_pars.freq+0.5*sweep_pars.delta_freq)]);

        n_sweeps_list=[1];
        n_sweeps = getScanParameter(n_sweeps_list,...
            seqdata.scancycle,seqdata.randcyclelist,'n_sweeps');  % also is sweep length  0.5               

        % Perform any additional sweeps
        for kk=1:n_sweeps
            disp([' Sweep Number ' num2str(kk) ]);
            curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);%3: sweeps, 4: pulse
        end   
    end
    
    %% RF Sweep flip 9 <-->7 then 7<-->5
 
    if spin_flip_9_7_5
        clear('sweep');
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF');
        sweep_pars.power =  [0];
        delta_freq =0.2; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        clear('sweep');
        B = HF_FeshValue_Initial; 
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-5/2) - BreitRabiK(B,9/2,-7/2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF');
        sweep_pars.power =  [0];
        delta_freq =0.2; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 20;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,15),3,sweep_pars);%3: sweeps, 4: pulse
    end
                        
    % RF Sweep
    if spin_flip_9_7_post_spectroscopy
        mF1 = -7/2;
        mF2 = -9/2;
        
        clear('sweep');
        Boff = 0.11;
        B = HF_FeshValue_Initial +Boff + 2.35*zshim; 
        rf_list =  [0.0] +...
            abs(BreitRabiK(B,9/2,mF1) - BreitRabiK(B,9/2,mF2))/6.6260755e-34/1E6;
        %rf_list = 48.3758; %@209G  [6.3371]; 
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF_post_spec');
        sweep_pars.power =  [2.5];
        delta_freq =0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 1;100;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,10);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
    end

% seqdata.params.HF_probe_fb = seqdata.params.HF_fb;

%% High Field Imaging Field Ramp
% Imaging is performed at a "standard" field value of 195 G for time of
% flight. Ramp the magnetic field when all manipulations are complete.

if field_ramp_img

    % Feshbach Field ramp Field ramp
    HF_FeshValue_Final_List = 207;195;
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_Lattice','G');

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime = 100;
    ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
    ramp.xshim_final = seqdata.params.shim_zero(1); 
    ramp.yshim_final = seqdata.params.shim_zero(2);
    ramp.zshim_final = seqdata.params.shim_zero(3);
    % FB coil 
    ramp.fesh_ramptime = 100;
    ramp.fesh_ramp_delay = 0;
    ramp.fesh_final = HF_FeshValue_Final;
    ramp.settling_time = 50;    

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

    seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    
     rampGradient  = 0;
     if rampGradient
        % Current / Field gradient to ramp to (unsure of units)
        QP_Coil_15 = 1;

        % Make sure QP coils are off
        setAnalogChannel(curtime,'Coil 15',0);
        setAnalogChannel(curtime,'Coil 16',0);
        setDigitalChannel(curtime, 'Coil 16 TTL', 1);

        curtime = calctime(curtime,10);
        
        % Set switches to enable current through coil 15
        setDigitalChannel(curtime,'Kitten Relay',1);
        setDigitalChannel(curtime,'15/16 Switch',0);
        curtime = calctime(curtime,10);

        % Allow current to pass through the kitten
        setAnalogChannel(curtime,'kitten',6.52,1);
        
        % voltage FF on delta supply    
        QP_FF = 23*(QP_Coil_15/30); 
            
        % Ramp up transport supply voltage
        ramp_time = 50;
        AnalogFuncTo(curtime,'Transport FF',@(t,tt,y1,y2) ...
            (ramp_linear(t,tt,y1,y2)),QP_FF,ramp_time,QP_FF);       
        
        AnalogFuncTo(curtime,'Coil 15',@(t,tt,y1,y2) ...
            (ramp_linear(t,tt,y1,y2)),QP_Coil_15,ramp_time,QP_Coil_15);
        
        curtime = calctime(curtime,50);

         
     end
    
end

%% Ending

% Hold time at the end
 HF_wait_time_list = [0];
 HF_wait_time = getScanParameter(HF_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');

curtime = calctime(curtime,HF_wait_time);

time_out_HF_imaging = curtime;        
if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
    error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
end
end