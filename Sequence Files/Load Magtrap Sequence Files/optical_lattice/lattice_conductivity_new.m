function [curtime] = lattice_conductivity_new(timein)
global seqdata
curtime = timein;

% Mod off
setAnalogChannel(curtime,'Modulation Ramp',-10,1);      

%% Flags
seqdata.flags.conductivity_ODT1_mode            = 0; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ODT2_mode            = 0; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ramp_FB              = 1; % Ramp FB field to resonance
seqdata.flags.conductivity_ramp_QP              = 1; % Ramp QP reverse with FB (only works if ramp_FB is enabled)
seqdata.flags.conductivity_rf_spec              = 1;
seqdata.flags.conductivity_enable_mod_ramp      = 0;
seqdata.flags.conductivity_QPD_trigger          = 0; % Trigger QPD monitor LabJack/Scope
seqdata.flags.conductivity_snap_off_XDT         = 0; % Quick ramp of ODTs while atoms are displaced
seqdata.flags.conductivity_snap_and_hold        = 0; % Diabatically turn off mod for quench measurement
seqdata.flags.conductivity_dopin                = 0; % Pin after modulation
%% Modulation Settings

% VISA Address of Rigol
rigol_address = 12;           

defVar('conductivity_mod_freq',[40],'Hz')       % Modulation Frequency
defVar('conductivity_mod_time',[50],'ms');      % Modulation Time
defVar('conductivity_mod_ramp_time',300,'ms');  % Ramp Time
defVar('conductivity_rel_mod_phase',0,'deg');   % Phase shift of sinusoidal mod - should be 180 for mod along y
    
% Modulation amplitude not to exceed +-4V.
defVar('conductivity_ODT1_mod_amp',[4],'V');  % ODT1 Mod Depth   4V, 4V for X (DC) 4V, -1.7V for Y (DC);
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
        ch2_on.BURST_PHASE = getVar('conductivity_rel_mod_phase');
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
    
        Bfb = getVar('conductivity_FB_field');
        zshim = getVar('conductivity_zshim');
        Bzshim = zshim*2.35;
        Boff = 0.11;
        
        Breal = Bfb + Bzshim + Boff;

        ramptime_all_list = 150;
        ramptime_all = getScanParameter(ramptime_all_list,seqdata.scancycle,...
            seqdata.randcyclelist,'conductivity_field_ramptime','ms');
        
        if seqdata.flags.conductivity_ramp_QP            
            defVar('conductivity_QP_reverse',[0.2],'A');            
            IQP = getVar('conductivity_QP_reverse');
            QP_ramptime = ramptime_all;            
            % Turn off 15/16 switch and coil 16 TTL
            setDigitalChannel(curtime,'15/16 Switch',0); %CHANGE THIS TO 15/16 GS VOLTAGE 
            setAnalogChannel(curtime,'15/16 GS',0);
            setDigitalChannel(curtime,'Coil 16 TTL',1); 
            curtime = calctime(curtime,10);

            % Turn on reverse QP switch
            setDigitalChannel(curtime,'Reverse QP Switch',1);
            curtime = calctime(curtime,10);

            % Ramp up transport supply voltage
            QP_FFValue = 3; % voltage FF on delta supply
            curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
                    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),100,100,QP_FFValue);
            curtime = calctime(curtime,10);
        
            % Preapre Coil 15 ramp
            curtime = AnalogFunc(calctime(curtime,0),'Coil 15',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),10,10,0,0.1247,1);     
            
            % Ramp Coil 15, but don't update curtime
            AnalogFuncTo(calctime(curtime,0),'Coil 15',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,IQP,5);             
        end
    

        
          % Define the ramp structure
        ramp=struct;
        %Shims
        ramp.shim_ramptime = ramptime_all;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
        % FB coil 
        ramp.fesh_ramptime = ramptime_all;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = Bfb; %22.6
        ramp.settling_time = 50;      
       

        
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');

        seqdata.params.HF_fb = Bfb;
        
        % wait for things to thermalize ??
        curtime = calctime(curtime,200);        
end
%% Modulation
    
if seqdata.flags.conductivity_QPD_trigger
    DigitalPulse(calctime(curtime,-100),'QPD Monitor Trigger',50,1);
end

if seqdata.flags.conductivity_enable_mod_ramp    
    setDigitalChannel(curtime,'ODT Piezo Mod TTL',1);    
    curtime = AnalogFunc(calctime(curtime,0),'Modulation Ramp',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        getVar('conductivity_mod_ramp_time'),...
        getVar('conductivity_mod_ramp_time'),-10,9.999,1);      
else
    setAnalogChannel(curtime,'Modulation Ramp',9.999,1);
end

% Wait for modulation to finish
curtime = calctime(curtime,getVarOrdered('conductivity_mod_time'));

% Stop Modulation - only affects AC modulation
setDigitalChannel(curtime,'ODT Piezo Mod TTL',0);

%% Snap off ODTs while modulating
% This is useful for trap frequency measurements

if seqdata.flags.conductivity_snap_off_XDT        
        % Turn off AOMs 
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);  
        % XDT1 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',... 
            seqdata.params.ODT_zeros(1));                      
        % XDT2 Power Req. Off
curtime = setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));  
        % I think this channel is unused now
        setDigitalChannel(calctime(curtime,-1),'XDT Direct Control',1);       
end     

%% Quench the modulation
% For decay/quench measurement

if seqdata.flags.conductivity_snap_and_hold
    % Ramp it down smoothly
    defVar('piezo_diabat_ramp_time',4,'ms');4;
    piezo_diabat_ramp_time = getVar('piezo_diabat_ramp_time');       
curtime = AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), piezo_diabat_ramp_time, piezo_diabat_ramp_time, -9.999,1); 
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
    curtime = calctime(curtime,1);    
    % Turn off modulation amplitude after atoms are pinned
    curtime = AnalogFuncTo(calctime(curtime,0),'Modulation Ramp',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 4, 4, -9.999,1); 
    curtime = calctime(curtime,1);
end  

%% uWave Spectroscopy to Check field
 if seqdata.flags.conductivity_rf_spec
     dispLineStr('RF Spec',curtime);
     
    Bfb = getChannelValue(seqdata,'FB Current',1);    
    Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
    Bz_shim = Iz_shim*2.35;
    Boff = 0.11;
    
    Bguess = Bfb + Boff + Bz_shim;
    
    % Transition guess 
    h = 6.6260755e-34;
    Fi = 9/2; Ff = 9/2;
    mFi = -9/2; mFf = -7/2;
    rf0 = 1e-6*abs(BreitRabiK(Bguess,Fi,mFi) - BreitRabiK(Bguess,Ff,mFf))/h;

    rf_list =  1e-3*[-200:25:200] + rf0;           
    
    defVar('conductivity_rf_freq',rf_list,'MHz');
    defVar('conductivity_rf_power',2.5,'arb');
    defVar('conductivity_rf_delta',25,'kHz');
    defVar('conductivity_rf_time',10,'ms');
    

    sweep = struct;
    sweep.freq = getVar('conductivity_rf_freq');
    sweep.power = getVar('conductivity_rf_power');
    sweep.delta_freq = 1e-3*getVar('conductivity_rf_delta');
    sweep.pulse_length = getVar('conductivity_rf_time');
    
    disp(sweep);
    curtime = rf_uwave_spectroscopy(...
        calctime(curtime,0),3,sweep);%3: sweeps, 4: pulse

    % Display the sweep settings
    disp(['RF Transfer Freq Center    (MHz) : [' num2str(sweep.freq) ']']);
    if (sweep.freq < 1)
        error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
    end    
    curtime = calctime(curtime,10);   
 end
%% Ramp FB field back down to 20 G
   
if seqdata.flags.conductivity_ramp_FB    
        ramptime_all_list = 150;
        ramptime_all = getScanParameter(ramptime_all_list,seqdata.scancycle,...
            seqdata.randcyclelist,'conductivity_field_down_ramptime','ms');        
 
        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = ramptime_all;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = ramptime_all;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = 20; %22.6
        ramp.settling_time = 50;  
        
        if seqdata.flags.conductivity_ramp_QP
            
            QP_ramptime = ramptime_all;
            
%             AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%                  @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0,1);
             
            % Ramp Coil 15, but don't update curtime
            AnalogFuncTo(calctime(curtime,0),'Coil 15',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),QP_ramptime,QP_ramptime,0,5);  
             
            % Go back to "normal" configuration
            % Turn off reverse QP switch
            setDigitalChannel(calctime(curtime,QP_ramptime+10),'Reverse QP Switch',0);
            AnalogFuncTo(calctime(curtime,QP_ramptime),'Coil 15',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0,1);  
            
            % Turn on 15/16 switch
            setDigitalChannel(calctime(curtime,QP_ramptime+20),'15/16 Switch',1); %CHANGE THIS TO 15/16 GS VOLTAGE
            setAnalogChannel(calctime(curtime,QP_ramptime+20),'15/16 GS',5.5); 
        end
               
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');
        
        

end


end

