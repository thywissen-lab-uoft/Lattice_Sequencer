function [curtime, I_QP, V_QP] = MT_rfevaporation(timein, opts, I_QP, V_QP)
% MT_rfevaporation.m
%
% This function performs RF evaporation out of the plugged magnetic
% quadrupolar trap. It assumes that the user independetly specifies the
% plug parameters.
% 
% This code assumes that the only currents on are the Coil 16 which are in
% anti-helmholtz (ie. Coil 15 and Coil 16 are symmetric, Kitten is off)

% opts.SweepTimes - duration of each peicewise segment (N)
% opts.Gains      - RF during each segment (N)
% opts.RFEnable   - TTL to enable/disable the RF during this sweep (N)
% opts.Freqs      - frequency points in Hz (N+1)
% opts.QPCurrents - Current in the QP coils (N+1)

if ~isequal(opts.QPCurrents(1),I_QP)
    error('The initial sweep current does not match the initial current');
end

doDebug=1;

curtime=timein;

global seqdata;

%% Settings

% DDS ID for RF evaporation
DDS_ID=1;

% Trigger pulse duration in ms
dTP=0.1; 

% Get the plug shim values
I0=seqdata.params.plug_shims;
Ix=I0(1);Iy=I0(2);Iz=I0(3);

% XYZ shim coefficients to maintain trap center with I_QP (amps/amps)
Cx = -0.0499;
Cy = 0.0045;
Cz = 0.0105;


%% Sequence

% The the RF/uWave switch to RF
setDigitalChannel(curtime,'RF/uWave Transfer',0);
% Iterate over each sweep
for kk=1:length(opts.SweepTimes)
    
    if doDebug
%         disp(
    end
    
    
    % Turn on/off the RF
    state = opts.RFEnable(kk);
    setDigitalChannel(curtime,'RF TTL',state);    
    
    % Trigger the DDS
    DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
    
    % Increment the number of DDS sweeps
    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;   
    
    % Define the RF sweep amd add it to the DDS sweep list
    dT=opts.SweepTimes(kk);     % Duration of this sweep in ms
    f1=opts.Freqs(kk);          % Starting Frequency in Hz
    f2=opts.Freqs(kk+1);        % Ending Frequency in Hz      
    sweep=[DDS_ID f1 f2 dT];    % Sweep data;
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;
    
    % Set the RF Gain
    G=opts.Gains(kk);           % RF gain in voltage    
    setAnalogChannel(curtime,'RF Gain',G,1); 

    % New QP Currents
    I_QP = opts.QPCurrents(kk+1);
    V_QP = I_QP * 23/30;
    
    if V_QP^2/4/(2*0.310) > 700
        error('Too much power dropped across FETS');
    end
    
    if opts.QPCurrents(kk+1)~=opts.QPCurrents(kk)
    
        % Ramp QP current to the next current in the sweep
        AnalogFuncTo(curtime,'Coil 16',@(t,tt,y1,y2) ramp_linear(t,tt,y1,y2), ...
            dT,dT,I_QP,2);
        AnalogFuncTo(curtime,'Transport FF',@(t,tt,y1,y2) ramp_linear(t,tt,y1,y2),...
            dT,dT,V_QP,2);    
        

        % Calculate change in shim currents
        dI_QP = I_QP - opts.QPCurrents(kk);
        dIx = dI_QP * Cx;
        dIy = dI_QP * Cy;
        dIz = dI_QP * Cz;

        % Calculate the new shim currents
        Ix=Ix+dIx;
        Iy=Iy+dIy;
        Iz=Iz+dIz;   

        % Ramp XYZ shims to their next value in the sweep
        AnalogFuncTo(curtime,'X Shim',@(t,tt,y1,y2)ramp_linear(t,tt,y1,y2), ...
            dT,dT,Ix,3);
        AnalogFuncTo(curtime,'Y Shim',@(t,tt,y1,y2)ramp_linear(t,tt,y1,y2), ...
            dT,dT,Iy,4); 
        AnalogFuncTo(curtime,'Z Shim',@(t,tt,y1,y2)ramp_linear(t,tt,y1,y2), ...
            dT,dT,Iz,3); 
    end
      
    % Advance time
    curtime = calctime(curtime,dT);
end


end

