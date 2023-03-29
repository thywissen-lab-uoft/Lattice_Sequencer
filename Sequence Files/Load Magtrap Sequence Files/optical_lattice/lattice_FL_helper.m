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
% APPLY RSC, EIT, UWAVE, TRIGGER IXON
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

%% INTIAL MAGNETIC FIELD RAMP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Magnetic Field Settings %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Additional Magnetic field offset
X_Shim_Offset = 0;
Y_Shim_Offset = 0;
Z_Shim_Offset = 0.055;

% Selection angle between X and Y shims
theta_list = [62];
theta = getScanParameter(theta_list,...
    seqdata.scancycle,seqdata.randcyclelist,'qgm_Bfield_angle','deg');

% Convert the quantization magnetic field to frequency (|9,-9>->|7,-7>)
df = opts.CenterField*2.4889; % MHz

% Coefficients that convert from XY shim current (A) to frequency (MHz) 
shim_calib = [2.4889*2, 0.983*2.4889*2]; % MHz/A

% Field strength and angle into current
X_Shim_Value = df*cosd(theta)/shim_calib(1);
Y_Shim_Value = df*sind(theta)/shim_calib(2);
%%
% Ramp up gradient and Feshbach field  
if opts.doInitialFieldRamp

    % What the code should do :
    % Turn off Feshbachbach Field (close switch as well)
    % Turn off QP Field (should probably set FF to zero)
    % Ramp the shims to the correct value

    newramp = struct('ShimValues',seqdata.params.shim_zero + ...
        [X_Shim_Value+X_Shim_Offset, ...
        Y_Shim_Value+Y_Shim_Offset, ...
        Z_Shim_Offset],...
        'FeshValue',0.01,...
        'QPValue',0,...
        'SettlingTime',100);
curtime = rampMagneticFields(calctime(curtime,0), newramp);
end      

%% Magnetic Field Ramp 2

if opts.doInitialFieldRamp2
    tShimRamp = 100;
    tShimSettle = 10;
    tFBRamp = 100;
    tFBSettle = 50;
    
    Ix = X_Shim_Value + X_Shim_Offset + seqdata.params.shim_zero(1);
    Iy = Y_Shim_Value + Y_Shim_Offset + seqdata.params.shim_zero(2);
    Iz = Z_Shim_Offset + seqdata.params.shim_zero(3);    
    
    %Ramp shim fields
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Ix,3);
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Iy,4);
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tShimRamp,tShimRamp,Iz,3);
    curtime = calctime(curtime,tShimRamp);
    
    curtime = calctime(curtime,tShimSettle);
    
    % Turn off FB and any QP Field
    
    % Turn off FB Current
    AnalogFuncTo(calctime(curtime,0),'FB current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFBRamp,tFBRamp,0);
    
    % Turn off transport supply
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFBRamp,tFBRamp,0);
    
    curtime = calctime(curtime,tFBRamp);    
    curtime = calctime(curtime,tFBSettle); 
end
    
%% Extra Settling Time

curtime = calctime(curtime,100);


%% uWave Settings

if opts.EnableUWave && pulse_time > 0
    % Spetroscopy parameters
    spec_pars = struct;
    spec_pars.Mode='sweep_frequency_chirp';
    spec_pars.use_ACSync = 0;
    spec_pars.PulseTime = pulse_time;
    
    spec_pars.FREQ =  opts.uWave_Frequency;                % Center in MHz
    spec_pars.FDEV = (opts.uWave_SweepRange/2)/1000; % Amplitude in MHz
    spec_pars.AMPR = opts.uWave_Power;               % Power in dBm
    spec_pars.ENBR = 1;                         % Enable N Type
    spec_pars.GPIB = 30;                        % SRS GPIB Address    

    K_uWave_Spectroscopy(curtime,spec_pars);    
end

%% D1 and EIT Shutter Open and Close

if (opts.EnableFPump || opts.EnableEITProbe) && pulse_time > 0
    
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
    
    % Make sure EIT Probe is off
    setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);

    % Turn on Probe beams
    setDigitalChannel(calctime(curtime,0),'D1 TTL',1);

    % Turn off Probe beams
    setDigitalChannel(calctime(curtime,pulse_time),'D1 TTL',0);
    
    % Turn on probe beams after shutter closed for thermal stability
    setDigitalChannel(calctime(curtime,pulse_time+20),'D1 TTL',1);
end
    
%% Raman Settings Pulse Sequence

% Raman Settings
if opts.EnableRaman
    
    ch1 = struct;
    ch1.FREQUENCY = opts.Raman1_Frequency;
    ch1.AMPLITUDE = opts.Raman1_Power;    
    if opts.Raman1_EnableSweep 
        ch1.SWEEP = 1; 
        ch1.SWEEP_FREQUENCY_CENTER = opts.Raman1_Frequency; 
        ch1.SWEEP_FREQUENCY_SPAN = opts.Raman1_SweepRange; 
        ch1.SWEEP_TIME = pulse_time;
        ch1.SWEEP_TRIGGER = 'EXT'; 
    end

    % Hmm what about rabi oscillations with a burst?
    
    % Program it
    
    ch2 = struct;
    ch2.FREQUENCY = opts.Raman1_Frequency;
    ch2.AMPLITUDE = opts.Raman1_Power;
    if opts.Raman2_EnableSweep 
        ch2.SWEEP = 1; 
        ch2.SWEEP_FREQUENCY_CENTER = opts.Raman2_Frequency; 
        ch2.SWEEP_FREQUENCY_SPAN = opts.Raman2_SweepRange; 
        ch2.SWEEP_TIME = pulse_time;
        ch2.SWEEP_TRIGGER = 'EXT'; 
    end
    
    % Program it

    
end

%% Raman Pulse Sequence
if opts.EnableRaman && pulse_time > 0
    % Make sure Raman beams are off ahead of time
    % We have them on to keep them thermally stable
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 1',0); % (1: ON, 0:OFF)
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 2a',0);% (1: ON, 0:OFF)
    setDigitalChannel(calctime(curtime,-50),'Raman TTL 3a',0);% (1: ON, 0:OFF)

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
 
    curtime = calctime(curtime,pulse_time);
end

%% Ixon Trigger and Programming
    if (opts.TriggerIxon)        
        % Pre Trigger a while before to flush camera?
        DigitalPulse(calctime(curtime,-6000),...
            'iXon Trigger',1,1);        
        
        % Trigger camera evenly throughout the pulse time
        ts = linspace(0,opts.PulseTime,opts.NumberOfImages+1);
        for kk=1:(length(ts)-1)
            DigitalPulse(calctime(curtime,ts(kk)),...
                'iXon Trigger',1,1);
        end        
    end     
        
end

