function curtime = lattice_FL(curtime,override)
global seqdata

    if ~isfield(seqdata,'flags')
       seqdata.flags = struct; 
    end
    
    if ~isfield(seqdata.flags,'misc_program4pass')
        seqdata.flags.misc_program4pass = 1;
    end
    
    if ~isfield(seqdata,'IxonMultiExposures')
       seqdata.IxonMultiExposures=[]; 
    end
    
    if ~isfield(seqdata,'IxonMultiPiezos')
       seqdata.IxonMultiPiezos=[]; 
    end


%% Optical/uWave Radiation Flags + Pulse Time
% This controls how radiation is applied during the imaging period.  Here,
% the pulse time controls all pulse times for every radiation.
%
% Details of the settings are found later in the code.

    fluor=struct;

    % uWave
    fluor.EnableUWave           = 0;        % Use uWave freq sweep for n-->n    
    % Laser Beams
    fluor.EnableFPump           = 1;        % Use FPUMP beam DOESNT WORK ZIF LOW???
    fluor.EnableEITProbe        = 1;        % Use EIT Probe beams
    fluor.EnableRaman           = 1;        % Use Raman Beams    
    
    % Sets the total time of radiation (optical or otherwise)
    pulse_list = [2000]; %         
    pulse_time = getScanParameter(...
        pulse_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_pulse_time','ms');      
    fluor.PulseTime             = pulse_time;     % [ms]   
    % 1 ms is typical for Raman spectroscopy
    % 1 ms is typical for uWave spectroscopy
    % 2000 ms is typical for fluoresence imaging    
    % FPUMP 1000Er, 83% transfer at 1 ms, 0.1 V
    
%% Magnetic Field Flags
% Flags for controlling the magnetic field during the fluorescence image.
% Details of the magnetic field are found later.

% Mangetic Field
    fluor.doInitialFieldRamp    = 1;        % Auto specify ramps       
    fluor.doInitialFieldRamp2   = 0;        % Manually specify ramps    
    
%% Ixon Camera Settings

% Whether to trigger the ixon at all.
    fluor.TriggerIxon          = 1;         % Trigger the ixon?
    
    
% Frame Transfer Enabled, Trigger : External (mode 1)
    fluor.IxonFrameTransferMode = 1;
% The exposure time is set by the time between triggers. Here, the 
% storage sensor is read out while the image sensor is exposed.  The
% minimum exposure time is the readout time (~300 ms).  The camera is
% always exposing itself after the first exposure.

% Frame Transfer Disabled, Trigger : External Exposure(mode 7)
%     fluor.IxonFrameTransferMode = 0;
% The exposure time is set by how long the IxonTrigger is high. After 
% exposing the camera needs around 400 ms to read out the image before it 
% can accept a new trigger.

if fluor.IxonFrameTransferMode
%     fluor.NumberOfImages       = 4;     % Normal operation     
%     fluor.ExposureTime         = [2000 500 500 500];
%     fluor.ObjectivePiezoShift  = [0 .15 -.15 0];        
    fluor.NumberOfImages       = 1;     % Normal operation     
    fluor.ExposureTime         = [2000];
    fluor.ObjectivePiezoShift  = [0];    
else
    fluor.NumberOfImages       = 1;     % Normal operation     
    fluor.DwellTime            = 600; % Wait Time beween shots for readout  
    fluor.IxonExposureTime     = (fluor.PulseTime-(fluor.NumberOfImages-1)*fluor.DwellTime)/fluor.NumberOfImages;     
end    

%% Override flags if desired

if nargin == 2
    fnames = fieldnames(override);
    for kk=1:length(fnames)
        fluor.(fnames{kk}) = override.(fnames{kk});
    end
end    
    
    
    %% Edge cases
% In case you run from here
if nargin==0 || curtime == 0
   curtime = 0; 
   main_settings;
   curtime = calctime(curtime,500);
      
   % If running code as a separate module, DO NOT change shims unless you 
   % really mean to as they can overheat
    fluor.doInitialFieldRamp2 = 0;
    fluor.doInitialFieldRamp = 0;
end
%% Ixon Trigger and Programming

    if fluor.TriggerIxon 
        if fluor.IxonFrameTransferMode
            dispLineStr('Triggering iXon Frame Transfer Mode',curtime);
            tpre=-50;
            DigitalPulse(calctime(curtime,tpre),...
                    'iXon Trigger',10,1)       
            disp(['Trigger : ' num2str(curtime2realtime(calctime(curtime,-tpre))) ' ms']);

            seqdata.IxonMultiExposures(end+1) = NaN;
            seqdata.IxonMultiPiezos(end+1) = NaN;

            % In frame transfer mode a trigger ends the exposure
            t0=0;
            for kk=1:fluor.NumberOfImages
                if seqdata.flags.misc_moveObjective
                    vNew = getVarOrdered('objective_piezo')+fluor.ObjectivePiezoShift(kk);
                    setAnalogChannel(calctime(curtime,t0),'objective Piezo Z',...
                        vNew,1);
                    seqdata.IxonMultiPiezos(end+1) = vNew;
                else
                    seqdata.IxonMultiPiezos(end+1) = NaN;
                end 
                
                t0 = t0 + fluor.ExposureTime(kk);
                disp(['Trigger : ' num2str(curtime2realtime(calctime(curtime,t0))) ' ms']);
                DigitalPulse(calctime(curtime,t0),...
                    'iXon Trigger',10,1); 
                seqdata.IxonMultiExposures(end+1) = fluor.ExposureTime(kk);
            end
        else
            dispLineStr('Triggering iXon External Exposure Mode',curtime);
            tpre=-500;
            DigitalPulse(calctime(curtime,tpre),...
                    'iXon Trigger',10,1)    
                
            tlist = (opts.IxonExposureTime+opts.DwellTime)*[0:(fluor.NumberOfImages-1)];  
            for kk=1:fluor.NumberOfImages
                 DigitalPulse(calctime(curtime,tlist(kk)),...
                       'iXon Trigger',fluor.IxonExposureTime,1);
                seqdata.IxonMultiExposures(end+1) = fluor.IxonExposureTime;

            end            
        end 
    end      

%% EIT FPUMP Settings
% This code set the Fpump power regulation and the 4 pass frequency

    % Power that the Fpump beam regulates to
    F_Pump_List = [1.1];[1.1];1.1;    
    
    % Frequency of the FPUMP single pass (MHz)
    fluor.F_Pump_Frequency = 80;
    
    fluor.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V');    

    addOutputParam('qgm_FPUMP_Frequency',fluor.F_Pump_Frequency,'MHz');

    %% EIT Probe Settings   
    
    % Voltage corresponding to maximum AOM deflection
    EIT1_max_voltage = 1.1;
    EIT2_max_voltage = .850;

    % Relative power choice (0 to 1)
    EIT_probe_rel_pow_list =[1];
    EIT_probe_rel_pow = getScanParameter(EIT_probe_rel_pow_list, ...
        seqdata.scancycle,seqdata.randcyclelist,'qgm_eit_rel_pow','arb');
    
    % Voltage that gets written to Rigol
    fluor.EIT1_Power = EIT1_max_voltage*EIT_probe_rel_pow;
    fluor.EIT2_Power = EIT2_max_voltage*EIT_probe_rel_pow;
    
    % Frequency (MHz) that gets written to Rigol
    fluor.EIT1_Frequency = 80;
    fluor.EIT2_Frequency = 80.01;
    
    % Set 4-Pass Frequency
    detuning_list = [5];
    df = getScanParameter(detuning_list, seqdata.scancycle, ...
        seqdata.randcyclelist, 'qgm_eit_4pass_shift','kHz');
    DDSFreq = 324.206*1e6 + df*1e3/4;

    % Hyperfine splitting at zero field
    df0 = 714.327+571.462;

    addOutputParam('qgm_eit_4pass_freq',DDSFreq*1e-6,'MHz');
    addOutputParam('qgm_eit_2photon_detuning',...
        ((4*DDSFreq*1e-6)-df0)*1e3,'kHz');
    
    if seqdata.flags.misc_program4pass
%         DDS_sweep(10,2,DDSFreq,DDSFreq,calctime(10,1));        
%         uWave_opts=struct;
%         uWave_opts.Address=29;                        % K uWave ("SRS B");
%         uWave_opts.Frequency= DDSFreq*1e-6;% Frequency in MHz
%         uWave_opts.Power= 3;%15                      % Power in dBm
%         uWave_opts.Enable=1;                          % Enable SRS output%         
%         programSRS(uWave_opts);                     % Program the SRS         
    end
    
    % Eventually program the EIT probe frequencies
%%  uWave Settings
% If the uWave flag is enabled these settings are used to apply a uWave
% frequency sweep in order to find the n-->n resonance location. It is
% suggested that you match the frequency to the 4Pass frequency and then
% vary the field since the 4Pass AOM will only remain coupled for a finite
% range of frequencies.

    uWave_Freq_Shift_List = [0];    
    uwave_freq_shift = getScanParameter(...
        uWave_Freq_Shift_List,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_uWave_freq_shift','kHz');     
    
    uWave_SweepRange_list = [20];    
    uWave_SweepRange = getScanParameter(...
        uWave_SweepRange_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_uWave_SweepRange','kHz');     
    
    % Specify Frequency manually
    fluor.uWave_Frequency = 1296.770 + uwave_freq_shift/1000;
    
    % Specifiy Frequency using 4pass
%     fluor.uWave_Frequency = (4*DDSFreq)/1e6; 1296.829;
    
    
    fluor.uWave_SweepRange = uWave_SweepRange;
    fluor.uWave_Power = 15;
    
    addOutputParam('qgm_uWave_Frequency',fluor.uWave_Frequency,'MHz');    

%%

raman_rel_pow_list = 0.5;[0.5];
  raman_rel_pow = getScanParameter(raman_rel_pow_list,...
        seqdata.scancycle,seqdata.randcyclelist,'qgm_raman_rel_pow','arb');     
    
%% Raman 1 Settings      
    V10 = 1.3;
    Raman1_Power_List = V10*raman_rel_pow;V10*[1];
    Raman1_ShiftFreq_List = [-100];[-80];        % kHz
        V20 = 1.36;   

%     r1 = linspace(0,1,10);
%     r2 = linspace(0,1,10);
%     [R1,R2]=meshgrid(r1,r2);
%     
%     R1 = V10*R1(:);
%     R2 = V20*R2(:);
%     
%     Raman1_Power = getScanParameter(R1,...
%         seqdata.scancycle,seqdata.randcyclelist,'Raman1_Power','V'); 
%         Raman2_Power = getScanParameter(R2,...
%         seqdata.scancycle,seqdata.randcyclelist,'Raman2_Power','V'); 

    Raman1_Freq_Shift = getScanParameter(Raman1_ShiftFreq_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman1_Freq_Shift','kHz');       
    Raman1_Power = getScanParameter(Raman1_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman1_Power','V'); 
    
    fluor.Raman1_EnableSweep = 0;
    fluor.Raman1_Power = Raman1_Power;
    fluor.Raman1_Frequency = 110*1e6 + Raman1_Freq_Shift*1e3;    
%% Raman 2 Settings
    V20 = 1.36;   
    Raman2_Power_List = V20*raman_rel_pow;V20*[1];
    Raman2_ShiftFreq_List = [0];       % kHz
    
    Raman2_Freq_Shift = getScanParameter(Raman2_ShiftFreq_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman2_Freq_Shift','kHz');       
    Raman2_Power = getScanParameter(Raman2_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Raman2_Power','V'); 
    
    fluor.Raman2_EnableSweep = 0;
    fluor.Raman2_Power = Raman2_Power;
    fluor.Raman2_Frequency = 80*1e6 + Raman2_Freq_Shift*1e3;        
 %% Raman EOM Settings 
    % Eventually the Raman EOM should be programmed 
    raman_eom_freq = 1266.924;
%% Raman Calcuation
% Based on the Raman AOM frequencies, calculate the 2photon detuning of the
% Raman transition.  Ideally this should match the EIT 2photon detuning   
    
    raman_2photon_freq = (raman_eom_freq + fluor.Raman1_Frequency*1e-6) - ...
        fluor.Raman2_Frequency*1e-6;
    raman_2photon_detuning = (raman_2photon_freq - seqdata.constants.hyperfine_ground)*1e3;

    addOutputParam('qgm_raman_eom_freq',raman_eom_freq,'MHz');    
    addOutputParam('qgm_raman1_freq',fluor.Raman1_Frequency,'MHz');
    addOutputParam('qgm_raman2_freq',fluor.Raman2_Frequency,'MHz');
    addOutputParam('qgm_raman_2photon_freq',raman_2photon_freq,'MHz');
    addOutputParam('qgm_raman_2photon_detuning',raman_2photon_detuning,'kHz');  
       
%% Run Sub Function
     
    curtime = lattice_FL_helper(curtime,fluor);  
end

