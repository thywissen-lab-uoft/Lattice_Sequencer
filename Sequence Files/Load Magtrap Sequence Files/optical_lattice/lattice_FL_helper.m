function curtime = lattice_FL_helper(timein,opts)
% Author : CJ Fujiwara
%
% This code is meant to run the fluoresence imaging.  Due to the complexity
% of fluorescence imaging and how one debugs it, this code is written in
% what I consider to be the simplest form.
%
% Fluoresence imaging is at it's heart a manipulation of the internal
% degrees of freedom via the EIT and RSC beams.  However, it is useful to
% sometimes to debug the system using uWave as thid does not require laser
% alignment.


%% CODE SUMMARY
%
% MAGNETIC FIELD
% For imaging a small magnetic field establishes a quantization axis along
% the FPUMP direction.  This means that the QP gradient needs to be off,
% the feshbach needs to be off, and the shims need to be set appropriately
% to elimnate Z fields and to rotate them to be correct.
%
%
% APPLY RSC, EIT, UWAVE,
% With a quantization axis specified, the atomic states are manipulated
% with application of RSC, EIT, and/or uWaves.  These can be pulsed or
% frequency sweeps if one desires to measure the Rabi frequency. (We will
% not include field sweeps because it makes the code more complicated). If
% we are performing imaging (say EIT, RSC, or EIT+RSC), the iXon should be
% triggerable.
%
% This particular code CONSTRAINS all of these times and triggers to happen
% at the same time (since this is realistic for fluoresence imaging).  


global seqdata;
curtime = timein;

pulse_time = opts.PulseTime;

%% uWave Settings

if opts.EnableUWave && pulse_time > 0
    % Spetroscopy parameters
    spec_pars = struct;
    spec_pars.Mode='sweep_frequency_chirp';
    spec_pars.use_ACSync = 0;
    spec_pars.PulseTime = pulse_time;
    
    spec_pars.FREQ =  opts.uWave_Frequency;          % Center in MHz
    spec_pars.FDEV = (opts.uWave_SweepRange/2)/1000; % Amplitude in MHz
    spec_pars.AMPR = opts.uWave_Power;               % Power in dBm
    spec_pars.ENBR = 1;                              % Enable N Type
    spec_pars.GPIB = 30;                             % SRS GPIB Address    

    K_uWave_Spectroscopy(curtime,spec_pars);    
end

%% D1 and EIT Shutter Open and Close

if (opts.EnableFPump || opts.EnableEITProbe) && pulse_time > 0
    
        % Turn off optical pumping AOM
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);   
    
    
    % Open Shutter
    setDigitalChannel(calctime(curtime,-5),'D1 Shutter',1);    
    if opts.EnableEITProbe
        setDigitalChannel(calctime(curtime,-5),'EIT Shutter',1);
    end
    

    % Close Shutter
    setDigitalChannel(calctime(curtime,pulse_time+5),'D1 Shutter',0);    
    if opts.EnableEITProbe
        setDigitalChannel(calctime(curtime,pulse_time+5),'EIT Shutter',0);
    end   
    % Turn on optical pumping AOM for thermal stability
    setDigitalChannel(calctime(curtime,pulse_time+5),'D1 OP TTL',1);
end

%% FPump Settings and Pulse Sequence

if opts.EnableFPump && pulse_time > 0
    % Turn off P Pump AOM and Regulation
    setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
    setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
    
    % Turn on F Pump
    setAnalogChannel(calctime(curtime,0),'F Pump',opts.F_Pump_Power);
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
    
    % Turn off F Pump
    setAnalogChannel(calctime(curtime,pulse_time),'F Pump',-1);
    setDigitalChannel(calctime(curtime,pulse_time),'F Pump TTL',1);
    setDigitalChannel(calctime(curtime,pulse_time),'FPump Direct',1);  
    
    % Turn it back on for thermal stability (not sure if very helpful)
    setAnalogChannel(calctime(curtime,pulse_time+20),'F Pump',9);
    setDigitalChannel(calctime(curtime,pulse_time+20),'F Pump TTL',0);    
end

%% EIT Probe Settings

if opts.EnableEITProbe && pulse_time > 0
    
    if isfield(opts,'EIT1_Power')
       ch1 = struct;
        ch1.AMPLITUDE = opts.EIT1_Power;    
        InternalAddress = 11;    
        programRigol(InternalAddress,ch1,[])   
    end
    
    if isfield(opts,'EIT2_Power')
        ch2 = struct;
        ch2.AMPLITUDE = opts.EIT2_Power;    
        InternalAddress = 10;    
        programRigol(InternalAddress,[],ch2)    
    end
    

    
%     
%     probe_power_list = [10];
%     probe_power = getScanParameter(probe_power_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'probe_power','V');
%     setAnalogChannel(calctime(curtime,-100),58,probe_power);

    
    % Make sure EIT Probe is off
    setDigitalChannel(calctime(curtime,-10),'EIT Probe TTL',0);

    % Turn on Probe beams
    setDigitalChannel(calctime(curtime,0),'EIT Probe TTL',1);

    % Turn off Probe beams
    setDigitalChannel(calctime(curtime,pulse_time),'EIT Probe TTL',0);
    
    % Turn on probe beams after shutter closed for thermal stability
    setDigitalChannel(calctime(curtime,pulse_time+20),'EIT Probe TTL',1);
    

end
    
%% Raman Settings Pulse Sequence

% Raman Settings
if opts.EnableRaman
    
    ch1 = struct;
    ch1.STATE= 'ON';
    ch1.FREQUENCY = opts.Raman1_Frequency;
    ch1.AMPLITUDE = opts.Raman1_Power;    
    if opts.Raman1_EnableSweep 
        ch1.SWEEP = 1; 
        ch1.SWEEP_FREQUENCY_CENTER = opts.Raman1_Frequency; 
        ch1.SWEEP_FREQUENCY_SPAN = opts.Raman1_SweepRange; 
        ch1.SWEEP_TIME = pulse_time;
        ch1.SWEEP_TRIGGER = 'EXT'; 
    end

    ch2 = struct;
    ch2.STATE= 'ON';
    ch2.FREQUENCY = opts.Raman2_Frequency;
    ch2.AMPLITUDE = opts.Raman2_Power;
    if opts.Raman2_EnableSweep 
        ch2.SWEEP = 1; 
        ch2.SWEEP_FREQUENCY_CENTER = opts.Raman2_Frequency; 
        ch2.SWEEP_FREQUENCY_SPAN = opts.Raman2_SweepRange; 
        ch2.SWEEP_TIME = pulse_time;
        ch2.SWEEP_TRIGGER = 'EXT'; 
    end
    
    InternalAddress=1;    
    programRigol(InternalAddress,ch1,ch2)    
end

%% Raman Pulse Sequence
if opts.EnableRaman && pulse_time > 0
    % Make sure Raman beams are off ahead of time
    % We have them on to keep them thermally stable
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 1',0); % (1: ON, 0:OFF) Raman 1 ZASWA + Rigol Trigger
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 2a',0);% (1: ON, 0:OFF) Raman 2 ZASWA
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 3a',0);% (1: ON, 0:OFF) Raman 3 ZASWA

    % Make sure Raman shutter is closed
    setDigitalChannel(calctime(curtime,-50),'Raman Shutter',0);

    % Open Shutter (1: ON, 0: OFF)
    setDigitalChannel(calctime(curtime,-10),'Raman Shutter',1);

    % Turn on raman beam
    setDigitalChannel(curtime,'Raman TTL 1',1);  % Vertical Raman (1: ON, 0:OFF)
    setDigitalChannel(curtime,'Raman TTL 2a',1); % Horizontal Raman (1: ON, 0:OFF)    

    % Turn off beams
    setDigitalChannel(calctime(curtime,pulse_time),'Raman TTL 1',0);
    setDigitalChannel(calctime(curtime,pulse_time),'Raman TTL 2a',0);

    % Close Shutter
    setDigitalChannel(calctime(curtime,pulse_time),'Raman Shutter',0);    

    % Turn on beams
    setDigitalChannel(calctime(curtime,pulse_time+1000),'Raman TTL 1',1);
    setDigitalChannel(calctime(curtime,pulse_time+1000),'Raman TTL 2a',1);       
    
end

    
    
    
%% Wait for Pulse
    curtime = calctime(curtime,pulse_time);

end

