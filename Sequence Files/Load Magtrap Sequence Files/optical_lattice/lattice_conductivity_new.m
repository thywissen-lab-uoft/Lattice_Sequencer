function [curtime] = lattice_conductivity_new(timein)
global seqdata
curtime = timein;

% Mod off
setAnalogChannel(curtime,'Modulation Ramp',-10,1);      

%% Flags
seqdata.flags.conductivity_ODT1_mode            = 2; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ODT2_mode            = 2; % 0:OFF, 1:SINE, 2:DC

seqdata.flags.conductivity_ramp_FB              = 1; % Ramp FB field to resonance

seqdata.flags.conductivity_enable_mod_ramp      = 1;
seqdata.flags.conductivity_QPD_trigger          = 1; % Trigger QPD monitor LabJack/Scope 

seqdata.flags.conductivity_snap_and_hold        = 1; % Diabatically turn off mod for quench measurement

seqdata.flags.conductivity_dopin                = 1; % Pin after modulation

%% Modulation Settings

% VISA Address of Rigol
rigol_address = 12;           

defVar('conductivity_mod_freq',[40],'Hz')       % Modulation Frequency
defVar('conductivity_mod_time',[50],'ms');       % Modulation Time
defVar('conductivity_mod_ramp_time',300,'ms');  % Ramp Time
    
% Modulation amplitude not to exceed +-4V.
defVar('conductivity_ODT1_mod_amp',[4],'V');  % ODT1 Mod Depth
defVar('conductivity_ODT2_mod_amp',[4],'V');  % ODT2 Mod Depth

%% Calculate Timings and Phase

if seqdata.flags.conductivity_enable_mod_ramp
    total_mod_time = getVar('conductivity_mod_ramp_time') + ...
        getVarOrdered('conductivity_mod_time');
else
    total_mod_time = getVarOrdered('conductivity_mod_time');
end

% Phase at the end of modulation (for setting the burst idle value)
end_mod_phase = 2*pi*getVar('conductivity_mod_freq')*(total_mod_time/1000);

%% Program Rigol
% Sets the channels of the Rigol DG831(2)

switch seqdata.flags.conductivity_ODT1_mode  
    case 0
        ch1_off = struct;
        ch1_off.STATE = 'OFF';
        programRigol(rigol_address,ch1_off,[]);
    case 1
        ch1_on=struct;
        ch1_on.FREQUENCY=getVar('conductivity_mod_freq');
        ch1_on.OFFSET = 0;
        ch1_on.AMPLITUDE = abs(getVar('conductivity_ODT1_mod_amp'))*2;
        ch1_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
        ch1_on.FUNC = 'SIN';
        ch1_on.BURST_PHASE = 0;
        ch1_on.SWEEP='OFF';
        ch1_on.MOD='OFF';
        ch1_on.BURST='ON';             % Burst MODE 
        ch1_on.BURST_MODE='GATED';     % Trig via the gate
        ch1_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
        ch1_on.BURST_TRIGGER='EXT';    % External trigger.   
        ch1_on.BURST_IDLE = (2^16-1)*(sin(end_mod_phase)+1)/2;% Idle at last value sine burst
        ch1_on.STATE = 'ON';    
        programRigol(rigol_address,ch1_on,[]);
    case 2
        ch1_on = struct;
        ch1_on.STATE='ON';
%         ch1_on.DC = ['1,1,' num2str(getVar('conductivity_ODT1_mod_amp'))];  
        ch1_on.DC = ['1,1,' num2str(getVarOrdered('conductivity_ODT1_mod_amp'))];  

        programRigol(rigol_address,ch1_on,[]);
end

switch seqdata.flags.conductivity_ODT2_mode  
    case 0
        ch2_off = struct;
        ch2_off.STATE = 'OFF';
        programRigol(rigol_address,[],ch2_off);
    case 1           
        ch2_on=struct;
        ch2_on.FREQUENCY=getVar('conductivity_mod_freq');
        ch2_on.OFFSET = 0;
        ch2_on.AMPLITUDE = abs(getVar('conductivity_ODT2_mod_amp'))*2;
        ch2_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
        ch2_on.FUNC = 'SIN';
        ch2_on.BURST_PHASE = 0;
        ch2_on.SWEEP='OFF';
        ch2_on.MOD='OFF';
        ch2_on.BURST='ON';             % Burst MODE 
        ch2_on.BURST_MODE='GATED';     % Trig via the gate
        ch2_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
        ch2_on.BURST_TRIGGER='EXT';    % External trigger.   
        ch2_on.BURST_IDLE = (2^16-1)*(sin(end_mod_phase)+1)/2;% Idle at last value sine burst
        ch2_on.STATE = 'ON';    
        programRigol(rigol_address,[],ch2_on);
    case 2
        ch2_on = struct;
        ch2_on.STATE='ON';
%         ch2_on.DC = ['1,1,' num2str(getVar('conductivity_ODT2_mod_amp'))];  
        ch2_on.DC = ['1,1,' num2str(getVarOrdered('conductivity_ODT2_mod_amp'))];  

        programRigol(rigol_address,[],ch2_on);
end

%% Ramp FB field to s-wave resonance
   
if seqdata.flags.conductivity_ramp_FB
 
      % Feshbach Field ramp
        HF_FeshValue_Initial_List = [185]; 
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
            seqdata.scancycle,seqdata.randcyclelist,'conductivity_FB_field','G');
         
        zshim_list = [0];
        zshim = getScanParameter(zshim_list,...
            seqdata.scancycle,seqdata.randcyclelist,'conductivity_zshim','A');

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
        
        % wait for things to thermalize ??
curtime = calctime(curtime,200);        
end
%% Modulation
    
if seqdata.flags.conductivity_QPD_trigger
    DigitalPulse(calctime(curtime,-100),'QPD Monitor Trigger',50,1);
end

setDigitalChannel(curtime,'ODT Piezo Mod TTL',1);

if seqdata.flags.conductivity_enable_mod_ramp
    curtime = AnalogFunc(calctime(curtime,0),'Modulation Ramp',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        getVar('conductivity_mod_ramp_time'),...
        getVar('conductivity_mod_ramp_time'),-10,9.999,1);    
else
    setAnalogChannel(curtime,'Modulation Ramp',9.999,1);
end

% Wait for modulation to finish
curtime = calctime(curtime,getVarOrdered('conductivity_mod_time'));

% Stop Modulation
setDigitalChannel(curtime,'ODT Piezo Mod TTL',0);

%% Additional hold
% For decay/quench measurement


if seqdata.flags.conductivity_snap_and_hold
    defVar('conductivity_snap_and_hold_time',0:2.5:75,'ms');  

    % Turn off modulation envelope (go back to initial position
    % diabatically)
%     setAnalogChannel(calctime(curtime,0),'Modulation Ramp',-10,1);

    % Ramp it down smoothly
    AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 5, 5, -9.999,1);    
    
    curtime = calctime(curtime,getVarOrdered('conductivity_snap_and_hold_time'));


end
%% Pin atoms
% Ramp lattices to in atoms
if seqdata.flags.conductivity_dopin    
    pin_time = 0.1;
    pin_depth = 60;
    
    % Ramp lattices to pin
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth)
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth);    
    curtime = calctime(curtime,pin_time); % Wait for pin
    
    % Settling Time
    curtime = calctime(curtime,10);
    
    % Turn off modulation amplitude after atoms are pinned
    setAnalogChannel(calctime(curtime,0),'Modulation Ramp',-10,1);
    
    % Wait a bit
    curtime = calctime(curtime,5);

   % Turn off XDT
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 10, 10, -0.2);
curtime=AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 10, 10, -0.2);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);

%     setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.2);
%     setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-0.2);
end  

    
%% Ramp FB field back down to 20 G
   
if seqdata.flags.conductivity_ramp_FB
 
          % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 150;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = 150;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = 20; %22.6
        ramp.settling_time = 50;   
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');

end


end

