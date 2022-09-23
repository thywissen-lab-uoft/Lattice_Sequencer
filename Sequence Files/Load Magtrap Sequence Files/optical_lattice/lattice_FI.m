function curtime = lattice_FI(timein,opts)
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
%
% While this code could be lumped together with plane selection, which is a
% kind of spectroscopy, I am electing to keep plane selection separate as
% plane selection occurs sequentially with imaging. So I don't think it is
% unreasonable to have them as separate pieces of code.

% Flags : 
% MicrowaveEnable
% RamanEnable
% FPumpEnable
% EITProbeEnable
% ixontrigger

% Pulse time is the time for all spectroscopy (EIT/RSC/uWave)
opts.PulseTime = 0; % in ms

% Field manipulations
opts.doInitialFieldRamp = 1;
opts.CenterField = 4.175;

% These flags enable or disable the entire section of code.  If these flags
% % are set to zero, the code will program them to be off.
% opts.EnableMicrowave = 0;
% opts.EnableFPump = 0;
% opts.EnableEITProbes = 0;
% opts.EnableRaman = 0;



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
%

global seqdata;
curtime = timein;

%% INTIAL MAGNETIC FIELD RAMP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Magnetic Field Settings %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Quantization Field
CenterField_list = 4.175;
CenterField = getScanParameter(...
    CenterField_list,seqdata.scancycle,seqdata.randcyclelist,...
    'FI_field','G');        

% Additional Magnetic field offset
X_Shim_Offset = 0;
Y_Shim_Offset = 0;
Z_Shim_Offset = 0.055;

% Selection angle between X and Y shims
theta_list = [62];
theta = getScanParameter(theta_list,...
    seqdata.scancycle,seqdata.randcyclelist,'Raman_Angle');

% Convert the quantization magnetic field to frequency (|9,-9>->|7,-7>)
df = CenterField*2.4889; % MHz

% Coefficients that convert from XY shim current (A) to frequency (MHz) 
shim_calib = [2.4889*2, 0.983*2.4889*2]; % MHz/A

% Field strength and angle into current
X_Shim_Value = df*cosd(theta)/shim_calib(1);
Y_Shim_Value = df*sind(theta)/shim_calib(2);

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
    
    
%% Wait a hot second
curtime = calctime(curtime,100);

%% EIT Settings
    
%% uWave Settings
    
%% Raman Settings

pulse_time_list = [0];
pulse_time = getScanParameter(pulse_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'pulse_time');

if pulse_time > 0
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

end

