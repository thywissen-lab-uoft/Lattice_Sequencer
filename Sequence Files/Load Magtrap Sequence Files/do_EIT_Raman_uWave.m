function timeout = do_EIT_Raman_uWave(timein,opt)
% do_EIT_Raman_uWave.m
% C Fujiwara
%
% This function applies EIT light, Raman Light, and/or uwave radiation to
% the cloud.
%
% The primary purpose of this function is to apply the fluorescence imaging
% light while the atoms are in pinned lattice. This code will also 
% trigger the ixon camera.
%
% Since it is often useful to diagnose the Fluoresence imaging in its
% separate components, various flags can be implemented to set the
% EIT, Raman, and uWave beams in different configurations.  While the uWave
% radiation is not used in Fluorescence imaging, it be can useful to
% benchmark n-->n against Raman trasitions.
%
% Lattice specification and plane selection are assumed to have occured
% before this function is called.

%% Initialize
global seqdata;
curtime = timein;

%% Example Inputs
% If you do not input an options argument these are the default values
% which perform Fluorescence imaging.  Please don't do that.  It's up to
% the user to neatly specify the options in the parent function.
if nargin==1

    opt=struct;

    BField=struct;
    uWave=struct;
    EIT=struct;
    Raman=struct;

    %%%%% Ixon Settings %%%%%
    iXonTriggerTimes=[0];                   % When to trigger ixon

    %%%%% Magnetic Field Settings %%%%%
    % Ramp fields?
    BField.RampUp           = 1;            % Ramp field before?
    BField.RampDown         = 0;            % Ramp field back down?

    % Shim options
    BField.Offset_Field     = 4;            % Magnitude of quantizing field
    BField.Field_Shift      = 0.155;        % Shift in magnitude of quantizing field
    BField.X_Shim_Offset    = 0;            % X Field offset
    BField.Y_Shim_Offset    = 0;            % Y Field offset
    BField.Z_Shim_Offset    = 0.055;        % Z Field offset
    BField.Angle=62;                        % Quantization Angle (XY)

    % Feshbach and QP
    BField.Feshbach         = 0.01;         % Feshbach field (G)
    BField.QP               = 0;            % QP Field

    %%%%% uWave Settings %%%%%
    uWave.Enable            = 0;
%     uWave.Mode              = 'lin_sweep';
    uWave.Mode              = 'hs1_sweep';
%     uWave.Mode              = 'pulse';
    uWave.Freq              = 1285.8 + 11.025;
    uWave.Power             = 15;   % dBm
    uWave.Addr              = 27;
    uWave.DeltaFreq         = 100;  % kHz
    uWave.PulseTime         = 2000; % ms

    %%%%% Raman Settings %%%%%
    Raman.Enable            = 1;
%     Raman.Mode              = 'lin_sweep';
    Raman.Mode              = 'pulse';
    Raman.Pow1              = 2;    % Rigol V
    Raman.Pow2              = 2;    % Rigol V
    Raman.Freq1             = 110;  % MHz
    Raman.Freq2             = 80;   % MHz
    Raman.PulseTime         = 2000; % ms

    %%%%% EIT Settings %%%%%
    EIT.EnableFPump         = 1;  
    EIT.EnableProbe         = 1;
    EIT.FPumpPower          = 0.7;  % ALPS V
    EIT.PulseTime           = 2000; % ms
end
%% Error Checking

if uWave.Enable && (Raman.Enable || EIT.EnableFPump || EIT.EnableProbe)
    warning(['Both uWave and Raman are enabled. Behavior not guaranteed.' ...
        ' Will active uWave first and then Raman']);
end

if EIT.EnableProbe && ~EIT.EnableFPump
   warning('EIT Probe is active while Fpump is off.'); 
end

if ~BField.RampUp && BField.RampDown
   warning(['Requesting a ramp down without a ramp up is pointless. ' ...
       ' But I will waste time doing it anyway']);
end

%% Display Settings
dispLineStr('Applyg EIT/Raman/uWave',curtime);

if BField.RampUp
   disp(BField); 
end

if uWave.Enable
   disp(uWave); 
end

if Raman.Enable
   disp(Raman); 
end

if EIT.EnableFPump || EIT.EnableProbe
   disp(EIT); 
end

%% Ramp Magnetic Fields

%Determine the requested frequency offset from zero-field resonance
frequency_shift = (BField.Offset_Field + BField.Field_Shift)*2.4889;

%Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
Shim_Calibration_Values = [2.4889*2, 0.983*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to

%Determine how much to turn on the X and Y shims to get this frequency
%shift at the requested angle
X_Shim_Value = frequency_shift * cosd(BField.Angle) / Shim_Calibration_Values(1);
Y_Shim_Value = frequency_shift * sind(BField.Angle) / Shim_Calibration_Values(2);


if BField.RampUp
    Xs=X_Shim_Value+BField.X_Shim_Offset;
    Ys=Y_Shim_Value+BField.Y_Shim_Offset;
    Zs=BField.Z_Shim_Offset;
    newramp = struct('ShimValues',seqdata.params.shim_zero + [Xs,Ys,Zs],...
        'FeshValue',BField.Feshbach,...
        'QPValue',BField.QP,...
        'SettlingTime',100);
curtime = rampMagneticFields(calctime(curtime,0), newramp);
end

%% uWave

%% Raman

if Raman.Enable

    % Program the Rigol

    
    DigitalPulse(calctime(curtime,-100),'Raman Shutter',Raman.PulseTime+3100,1);% CF 2021/03/30 new shutter

    %Raman excitation beam AOM-shutter sequence.
    DigitalPulse(calctime(curtime,-150),'Raman TTL 1',150,0);
    DigitalPulse(calctime(curtime,-150),'Raman TTL 2',150,0);
    DigitalPulse(calctime(curtime,-150),'Raman TTL 3',5200,0);




    DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 1',3050,0);
    DigitalPulse(calctime(curtime,opt.Microwave_Pulse_Length),'Raman TTL 2',3050,0);
end


%% EIT

%Turn off F-Pump and probe AOMs before use. 
setAnalogChannel(calctime(curtime,-10),'F Pump',-1);
setDigitalChannel(calctime(curtime,-10),'F Pump TTL',1);
setDigitalChannel(calctime(curtime,-10),'D1 TTL',0);

% Open D1 Shutter if any beam is used
if EIT.EnableFPump || EIT.EnableProbe
    setDigitalChannel(calctime(curtime,-5),'D1 Shutter',1);
    setDigitalChannel(calctime(curtime,EIT.PulseTime),'D1 Shutter',0);
end

% Fpump Beam
if EIT.EnableFPump
    % Turn on FPump beam and its feedback
    setAnalogChannel(calctime(curtime,0),'F Pump',EIT.FPumpPower);
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'FPump Direct',0);
    
    % Turn off FPump beam and its feedback
    setAnalogChannel(calctime(curtime,EIT.PulseTime),'F Pump',-1);
    setDigitalChannel(calctime(curtime,EIT.PulseTime),'F Pump TTL',1);
    setDigitalChannel(calctime(curtime,EIT.PulseTime),'FPump Direct',1);      
    
    % Turn on FPump Feedback to thermalize AOM
    setAnalogChannel(calctime(curtime,EIT.PulseTime+15),'F Pump',9.99);
    setDigitalChannel(calctime(curtime,EIT.PulseTime+15),'F Pump TTL',0);    
end

% EIT Probe
if EIT.EnableProbe
    % Turn on EIT Probe
    setDigitalChannel(calctime(curtime,-5),'EIT Shutter',1);
    setDigitalChannel(calctime(curtime,0),'D1 TTL',1);   
    
    % Turn off EIT Probe
    setDigitalChannel(calctime(curtime,EIT.PulseTime),'EIT Shutter',0);
    setDigitalChannel(calctime(curtime,EIT.PulseTime),'D1 TTL',0);   
end
          
        
%% iXon





%% Time out
timeout = curtime;

end

