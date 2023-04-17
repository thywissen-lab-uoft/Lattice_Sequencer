function curtime = opticalpumpingD1(timein,opts)
%OPTICALPUMPINGD1 Summary of this function goes here
%   Detailed explanation goes here
global seqdata;

curtime = timein;

%% Default Settings

if nargin == 1
   opts = struct;
   opts.op_time = 5;
   opts.fpump_power = 0.2;
   opts.d1op_power = 8; 
   opts.fpump_extratime = 2;
   
   opts.leave_on = 1;
end

if ~isfield(opts,'leave_on')
   opts.leave_on = 0; 
end

%% Input Settings
% Grab settings so you don't have to deal with structures all the time.

op_time = opts.op_time;                     % Optical pumping time
fpump_power = opts.fpump_power;             % fpump power (repumps F=7/2);
fpump_extratime = opts.fpump_extratime;     % fpump extra time on
d1op_power = opts.d1op_power;               % optical pumping power (AM)

disp(['     Pumping time (ms)     ' num2str(op_time)]);
disp(['     Pumping AM (V)        ' num2str(d1op_power)]);
disp(['     Fpump power (V)       ' num2str(fpump_power)]);
disp(['     Fpump extra time (ms) ' num2str(fpump_extratime)]);

% Flag to keep the beams on after calling this function.  This is useful
% for debugging purposes.
leave_on = opts.leave_on;

%% Extra Initial Wait
% If you are leaving the beams on at the end, you are presumably debugging
% the sequence, so add some extra time so calls backwards in time are okay.

if leave_on
   curtime = calctime(curtime,50); 
end

%% Ramp Mangetic Field for optical pumping
% The quantization is set along the optical pumping axis (FPUMP)
    
    %Determine the requested frequency offset from zero-field resonance
    frequency_shift = (4)*2.4889;(4)*2.4889;
    Selection_Angle = 62.0;
    addOutputParam('Selection_Angle',Selection_Angle)

    %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
    Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to

    %Determine how much to turn on the X and Y shims to get this frequency
    %shift at the requested angle
    X_Shim_Value = frequency_shift * cosd(Selection_Angle) / Shim_Calibration_Values(1);
    Y_Shim_Value = frequency_shift * sind(Selection_Angle) / Shim_Calibration_Values(2);
    X_Shim_Offset = 0;
    Y_Shim_Offset = 0;
    Z_Shim_Offset = 0.055;0.055;

    %Ramp the magnetic fields so that we are spin-polarized.
    newramp = struct('ShimValues',seqdata.params.shim_zero + [X_Shim_Value+X_Shim_Offset, Y_Shim_Value+Y_Shim_Offset, Z_Shim_Offset],...
            'FeshValue',0.01,'QPValue',0,'SettlingTime',200);

    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);   

    disp(' Ramping magnetic fields ...');

%% Prepare Light

    % Make sure EIT shutter is closed (EIT Probes) (necessary? already
    % closed?)
    setDigitalChannel(calctime(curtime,-20),'EIT Shutter',0); %0 = closed
    setDigitalChannel(calctime(curtime,-20),'D1 Shutter', 0);%2
      
    % Break the thermal stabilzation of AOMs by turning them off
    setDigitalChannel(calctime(curtime,-10),'EIT Probe TTL',0);        % EIT probe off
    setAnalogChannel(calctime(curtime,-10),'F Pump',-1);        % fpump regulation low
    setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);    % fpump aom off
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);     % d1 AOM off
    setAnalogChannel(calctime(curtime,-10),'D1 AM',d1op_power); % d1 AOM AM set
    
%% Turn on beams
    disp(' Pulsing light');

    % Open D1 shutter (FPUMP + OPT PUMP + EIT Probe) (EIT Shutter still
    % closed)
    setDigitalChannel(calctime(curtime,-8),'D1 Shutter', 1); % 1: light; 0: no light
        
    % Flash light (FPUMP optical pumping AOMS (allow light) and regulate F-pump
    setDigitalChannel(calctime(curtime,0),'FPump Direct',0);        % Enable regulatoin
    setAnalogChannel(calctime(curtime,0),'F Pump',fpump_power);     % regulation set point
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);          % Fpump AOM TTL (0 : off)
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);           % optical pumping AOM TTL (1 : on)

%% Advance Time
    
    %Optical pumping time
curtime = calctime(curtime,op_time);

%% Turn off beams
% Turn off beams

if ~leave_on    
    disp(' Turning off beams');

    % Turn off OP before F-pump to ensure F=9/2 population
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',0);
    
    % Disable light with AOMs
    setDigitalChannel(calctime(curtime,fpump_extratime),'F Pump TTL',1);%1
    setAnalogChannel(calctime(curtime,fpump_extratime),'F Pump',-1);%1
    setDigitalChannel(calctime(curtime,fpump_extratime),'FPump Direct',1);
    
    % Close D1 shutter shutter
    setDigitalChannel(calctime(curtime,fpump_extratime),'D1 Shutter', 0);%2
    
    % After shutters are closed, turn on all AOMs for thermal stabilzation    
    setDigitalChannel(calctime(curtime,fpump_extratime + 5),'EIT Probe TTL',1);
    setDigitalChannel(calctime(curtime,fpump_extratime + 5),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,fpump_extratime + 5),'D1 OP TTL',1);        
end
    
    % Advance time
curtime = calctime(curtime,fpump_extratime + 5);

clear('ramp');

%% Ramp Magnetic Field Back to operating
disp(' Ramping field back');

% Define new structure
newramp = struct('ShimValues',seqdata.params.shim_zero,...
            'FeshValue',20,'QPValue',0,'SettlingTime',100);        
        
    % Ramp fields for pumping
curtime = rampMagneticFields(calctime(curtime,0), newramp);   
    
% Extra wait time (why not just put it into the settling time?)
curtime = calctime(curtime,50);

end

