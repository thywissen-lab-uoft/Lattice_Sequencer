function curtime = lattice_FL(curtime,override)
global seqdata

    if ~isfield(seqdata,'flags')
       seqdata.flags = struct; 
    end
    
    if ~isfield(seqdata.flags,'misc_program4pass')
        seqdata.flags.misc_program4pass = 1;
    end
    
    if ~isfield(seqdata.CameraControl,'IxonMultiExposures')
       seqdata.CameraControl.IxonMultiExposures=[]; 
    end
    
    if ~isfield(seqdata.CameraControl,'IxonMultiPiezos')
       seqdata.CameraControl.IxonMultiPiezos=[]; 
    end


%% Optical/uWave Radiation Flags + Pulse Time
% This controls how radiation is applied during the imaging period.  Here,
% the pulse time controls all pulse times for every radiation.
%
% Details of the settings are found later in the code.

    fluor=struct;

    % uWave
    fluor.EnableUWave           = 0;        % Use uWave freq sweep for n-->n  (happens before cooling light turns on)  
    % Laser Beams
    fluor.EnableFPump           = 1;        % Use FPUMP beam DOESNT WORK ZIF LOW???
    fluor.EnableEITProbe        = 1;        % Use EIT Probe beams
    fluor.EnableRaman           = 1;        % Use Raman Beams    
    
    % Sets the total time of radiation (optical or otherwise)
    pulse_list = [4000]; %         
    pulse_time = getScanParameter(...
        pulse_list,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_pulse_time','ms');      
    fluor.PulseTime             = pulse_time;     % [ms]   
    % 1 ms is typical for Raman spectroscopy
    % 1 ms is typical for uWave spectroscopy
    % 2000 ms is typical for fluoresence imaging    
    % FPUMP 1000Er, 83% transfer at 1 ms, 0.1 V
    % EIT Probe 1 , 45% transfer at 0.1 ms, 0.05 rel power
    % EIT Probe 2 , 60% transfer at 0.1 ms, 0.1 rel power

%% Ixon Camera Settings

% Whether to trigger the ixon at all.
fluor.TriggerIxon          = 1;         % Trigger the ixon?
    
    
% Frame Transfer Enabled, Trigger : External (mode 1)
fluor.IxonFrameTransferMode = 1;
% The exposure time is set by the time between triggers. Here, the 
% storage sensor is read out while the image sensor is exposed.  The
% minimum exposure time is the readout time (~300 ms).  The camera is
% always exposing itself after the first exposure.
%
% Example Run :
% Trigger 1 : Wipe camera (finish exposure 1); start exposure 2
% Trigger 2 : stop exposure 2; start exposure 3
% Trigger 3 : stop exposure 3; start exposure 4
% Trigger 4 : stop exposure 4;
%
% Frame Transfer Disabled, Trigger : External Exposure(mode 7)
%     fluor.IxonFrameTransferMode = 0;
% The exposure time is set by how long the IxonTrigger is high. After 
% exposing the camera needs around 400 ms to read out the image before it 
% can accept a new trigger.

if fluor.IxonFrameTransferMode
    
    
    switch seqdata.flags.lattice_fluor_multi_mode
        case 0
            % Basic    : 1 Image
            fluor.NumberOfImages       = 1;     
            fluor.ExposureTime         = fluor.PulseTime;
        case 1 
            % Fidelity : 2 Images with equal exposure time
            fluor.NumberOfImages       = 2;        
            fluor.ExposureTime         = fluor.PulseTime*0.5*[1 1];  
            fluor.ObjectivePiezoShiftTime  = zeros(1,fluor.NumberOfImages);
            fluor.ObjectivePiezoShiftValue = zeros(1,fluor.NumberOfImages);    
        case 2
            % Focusing : 4 Images with equal exposure time
            fluor.NumberOfImages           = 4;        
            fluor.ObjectivePiezoShiftTime  = 100; % in ms
            fluor.ObjectivePiezoShiftValue = [0 0.05 0.0 -0.05];    
            fluor.ExposureTime         = ones(1,fluor.NumberOfImages)*fluor.PulseTime/fluor.NumberOfImages-fluor.ObjectivePiezoShiftTime; 
        otherwise
            % Basic    : 1 Image
            fluor.NumberOfImages       = 1;     
            fluor.ExposureTime         = fluor.PulseTime;
    end
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
end
%% Ixon Trigger and Programming

    if fluor.TriggerIxon 
        if fluor.IxonFrameTransferMode
            dispLineStr('Triggering iXon Frame Transfer Mode',curtime);
            tpre=-50;
            
            % Initial trigger to start aqsuitision
            DigitalPulse(calctime(curtime,tpre),'iXon Trigger',10,1)       
            disp(['Trigger : ' num2str(curtime2realtime(calctime(curtime,-tpre))) ' ms']);

            seqdata.CameraControl.IxonMultiExposures(end+1) = NaN;
            seqdata.CameraControl.IxonMultiPiezos(end+1) = NaN;
            
            if seqdata.flags.lattice_fluor_multi_mode== 2
                V_piezo_init = getChannelValue(seqdata,'objective Piezo Z',1);    
                dT_piezo = fluor.ObjectivePiezoShiftTime;
                
                AnalogFuncTo(calctime(curtime,-2*dT_piezo+tpre),'objective Piezo Z',...
                    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
                    dT_piezo,dT_piezo,V_piezo_init+fluor.ObjectivePiezoShiftValue(1));
            end

            % In frame transfer mode a trigger ends the exposure
            t0=0;
            for kk=1:fluor.NumberOfImages                 
                seqdata.CameraControl.IxonMultiPiezos(end+1) = getChannelValue(seqdata,'objective Piezo Z',1);
                
                t0 = t0 + fluor.ExposureTime(kk);
                disp(['Trigger : ' num2str(curtime2realtime(calctime(curtime,t0))) ' ms']);
                DigitalPulse(calctime(curtime,t0),...
                    'iXon Trigger',10,1); 
                seqdata.CameraControl.IxonMultiExposures(end+1) = fluor.ExposureTime(kk);
                
                % If multi-shot focusing, move the piezo the next value
                % Note that the camera will be exposing during the focusing
                % movement, this is inevitable in frame transfer mode
                if seqdata.flags.lattice_fluor_multi_mode==2
                    if  kk<fluor.NumberOfImages
                        % Move to next value
                        V_piezo_value = V_piezo_init+fluor.ObjectivePiezoShiftValue(kk+1);
                    else
                        % You're at the end. Move to the original value
                        V_piezo_value = V_piezo_init;
                    end
                    AnalogFuncTo(calctime(curtime,t0),'objective Piezo Z',...
                        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
                        dT_piezo,dT_piezo,V_piezo_value); 
                end    
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
                seqdata.CameraControl.IxonMultiExposures(end+1) = fluor.IxonExposureTime;

            end            
        end 
    end      

%% EIT FPUMP Settings
% This code set the Fpump power regulation and the 4 pass frequency

    % Power that the Fpump beam regulates to
    F_Pump_List = [0.85];.8;[0.7];[0.9];
    
    % Frequency of the FPUMP single pass (MHz)
    fluor.F_Pump_Frequency = 80;
    
    fluor.F_Pump_Power = getScanParameter(F_Pump_List,...
        seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power','V');    

    addOutputParam('qgm_FPUMP_Frequency',fluor.F_Pump_Frequency,'MHz');

    %% EIT Probe Settings   
    
    % Voltage corresponding to maximum AOM deflection
    EIT1_max_voltage = 1.1;
    EIT2_max_voltage = .850;
    
    defVar('qgm_EIT1_power',.8,'normalized');0.8;
    defVar('qgm_EIT2_power',.8,'normalized');0.8;

    % Relative power choice (0 to 1)
%     EIT_probe_rel_pow_list =[.4:.05:1];
%     EIT_probe_rel_pow = getScanParameter(EIT_probe_rel_pow_list, ...
%         seqdata.scancycle,seqdata.randcyclelist,'qgm_eit_rel_pow','arb');
    
    % Voltage that gets written to Rigol
    fluor.EIT1_Power = EIT1_max_voltage*getVar('qgm_EIT1_power');
    fluor.EIT2_Power = EIT2_max_voltage*getVar('qgm_EIT2_power');
    
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

    uWave_Freq_Shift_List = [100];    
    uwave_freq_shift = getScanParameter(...
        uWave_Freq_Shift_List,seqdata.scancycle,seqdata.randcyclelist,...
        'qgm_uWave_freq_shift','kHz');         
    uWave_SweepRange_list = 200;[20];    
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

%% Raman Powers Settings
% 2024/06/01 Raman 1 is vertical, Raman 2 is horizontal (this can change by
% rearranging fibers)

% Maximum AOM deflection efficiency voltage on the Rigol (V)
Raman1_V0 = 1.3;
Raman2_V0 = 1.36;

% Relative power to use during the experiment
defVar('qgm_Raman1_power',0.4,'normalized');0.4;
defVar('qgm_Raman2_power',0.4,'normalized');0.4;

% Detunings to modify the Raman condition (shouldn't this always be zero?)
% CF : Since I believe Raman two photon should be the same as EIT two
% photon
defVar('qgm_Raman1_shift',[-80],'kHz');-110;
defVar('qgm_Raman2_shift',0,'kHz');

%Set the range of the frequency sweeps for Raman spectroscopy
defVar('qgm_Raman1_sweepRange',[50],'kHz');
defVar('qgm_Raman2_sweepRange',50,'kHz');

%% Raman 1 Settings          
    fluor.Raman1_EnableSweep = 0;
    fluor.Raman1_Power = Raman1_V0*getVar('qgm_Raman1_power');
    fluor.Raman1_Frequency = 110*1e6 + getVar('qgm_Raman1_shift')*1e3;
    fluor.Raman1_SweepRange = getVar('qgm_Raman1_sweepRange')*1e3;
%% Raman 2 Settings    
    fluor.Raman2_EnableSweep = 0;
    fluor.Raman2_Power = Raman2_V0*getVar('qgm_Raman2_power');
    fluor.Raman2_Frequency = 80*1e6 + getVar('qgm_Raman2_shift')*1e3;
    fluor.Raman2_SweepRange = getVar('qgm_Raman2_sweepRange')*1e3;
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

