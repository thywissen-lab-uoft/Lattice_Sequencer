function curtime = lattice_FL(curtime,override)
global seqdata

%% Flags

    fluor=struct;

    % uWave
    fluor.EnableUWave           = 0;        % Use uWave freq sweep for n-->n
    
    % Laser Beams
    fluor.EnableFPump           = 1;        % Use FPUMP beam
    fluor.EnableEITProbe        = 1;        % Use EIT Probe beams
    fluor.EnableRaman           = 1;        % Use Raman Beams
    
    % Sets the total time of radiation (optical or otherwise)
        pulse_list = [10000];

    pulse_time = getScanParameter(...
        pulse_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_pulse_time','ms');  
    
    fluor.PulseTime             = pulse_time;     % [ms]
    
    
    % 1 ms is typical for Raman spectroscopy
    % 1 ms is typical for uWave spectroscopy
    % 2000 ms is typical for fluoresence imaging
    
    % Camera
    fluor.TriggerIxon          = 1;         % Trigger the ixon?
    
    % Camera Exposure
    % The exposure time is set by how long the IxonTrigger is high if the
    % camera is in "External Exposure" Mode.
    % Warning : Dont make the exposure times longer than the total light time or else
    % the camera will be exposing without fluoresence.
    % Warning : After exposing the camera needs around 400 ms to read out
    % the image before it can accept a new trigger.
    
    
    fluor.NumberOfImages       = 1;     % Normal operation
%     fluor.NumberOfImages       = 10;     % For hopping
   
    % Calculate Xposures
    fluor.DwellTime            = 600; % Wait Time beween shots for readout
    fluor.IxonExposureTime     = (fluor.PulseTime-(fluor.NumberOfImages-1)*fluor.DwellTime)/fluor.NumberOfImages;  

  

    % Mangetic Field
    fluor.doInitialFieldRamp    = 1;        % Auto specify ramps       
    fluor.doInitialFieldRamp2   = 0;        % Manuualy specify ramps
    
        
    if ~isfield(seqdata,'flags')
       seqdata.flags = struct; 
    end
    
    if ~isfield(seqdata.flags,'misc_program4pass')
        seqdata.flags.misc_program4pass = 1;
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
%% Magnetic Field Settings
% This sets the quantizing field along the fpump axis. It is assumed that
% you are imaging along the FPUMP axis
    
    B0 = 4;         % Quantization Field
    B0_shift_list =[.19]; [0.21];[.17];
    
    % Quantization Field 
    B0_shift = getScanParameter(...
        B0_shift_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_field_shift','G');  
    
    fluor.CenterField = B0 + B0_shift;
    
    addOutputParam('qgm_field',fluor.CenterField,'G');   
%% EIT FPUMP Settings
% This code set the Fpump power regulation and the 4 pass frequency

    % Power that the Fpump beam regulates to
    F_Pump_List = [1.3];
    
    % Voltage of the Rigol output (this sets the max RF power after the
    % ALPS box)
    fluor.F_Pump_Voltage = 1.1;
    
    % Frequency of the FPUMP single pass (MHz)
    fluor.F_Pump_Frequency = 80;
    
    fluor.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V');    

    addOutputParam('qgm_FPUMP_Rigol_V',fluor.F_Pump_Voltage,'V');
    addOutputParam('qgm_FPUMP_Frequency',fluor.F_Pump_Voltage,'MHz');

    %% EIT Probe Settings   
    
    % Voltage corresponding to maximum AOM deflection
    EIT1_max_voltage = 1.1;
    EIT2_max_voltage = .850;

    % Relative power choice (0 to 1)
    EIT_probe_rel_pow_list =[.5];
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
        DDS_sweep(10,2,DDSFreq,DDSFreq,calctime(10,1));
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
    fluor.uWave_Frequency = 1296.824 + uwave_freq_shift/1000;
    
    % Specifiy Frequency using 4pass
    fluor.uWave_Frequency = (4*DDSFreq)/1e6;
    
    
    fluor.uWave_SweepRange = uWave_SweepRange;
    fluor.uWave_Power = 15;
    
    addOutputParam('qgm_uWave_Frequency',fluor.uWave_Frequency,'MHz');    

%%

raman_rel_pow_list = [0.5];
  raman_rel_pow = getScanParameter(raman_rel_pow_list,...
        seqdata.scancycle,seqdata.randcyclelist,'qgm_raman_rel_pow','arb');     
    
%% Raman 1 Settings      
    V10 = 1.3;
    Raman1_Power_List = V10*raman_rel_pow;V10*[1];
    Raman1_ShiftFreq_List = [-80];        % kHz
    
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

