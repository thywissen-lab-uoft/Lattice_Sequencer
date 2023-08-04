function [curtime] = lattice_conductivity_new(timein)
global seqdata
curtime = timein;

% Mod off
setAnalogChannel(curtime,'Modulation Ramp',-10,1);      

%% Flags
seqdata.flags.conductivity_ODT1_mode            = 1; % 0:OFF, 1:SINE, 2:DC
seqdata.flags.conductivity_ODT2_mode            = 1; % 0:OFF, 1:SINE, 2:DC

seqdata.flags.conductivity_enable_mod_ramp      = 1;
seqdata.flags.conductivity_QPD_trigger          = 0; % Trigger QPD monitor LabJack/Scope 
seqdata.flags.conductivity_dopin                = 0; % Pin after modulation

%% Modulation Settings

% VISA Address of Rigol
rigol_address = 12;           

defVar('conductivity_mod_freq',[40],'Hz')       % Modulation Frequency
defVar('conductivity_mod_time',[280],'ms');       % Modulation Time
defVar('conductivity_mod_ramp_time',400,'ms');  % Ramp Time
    
% Modulation amplitude not to exceed +-4V.
defVar('conductivity_ODT1_mod_amp',[4],'V');  % ODT1 Mod Depth
defVar('conductivity_ODT2_mod_amp',[4],'V');  % ODT1 Mod Depth

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
        ch1_on.DC = ['1,1,' num2str(getVar('conductivity_ODT1_mod_amp'))];  
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
        ch2_on.DC = ['1,1,' num2str(getVar('conductivity_ODT2_mod_amp'))];  
        programRigol(rigol_address,[],ch2_on);
end
    
%% Test DC
% if seqdata.flags.conductivity_test_DC    
%     ch1_on = struct;
%     ch1_on.STATE='ON';
%     ch1_on.DC = '1,1,5';  
%     programRigol(rigol_address,ch1_on,[]);
% end

    
%     %Modulation Parameters
%     mod_freq = 50; %Hz
%     mod_amp = 2; %Vpp
%     mod_offset = 0; %V
%     mod_time = 100; %ms
%     addr_odt1 = 12;
%     
%     % ON Channel Settings
%     ch_on=struct;
%     ch_on.FREQUENCY=mod_freq;     % Modulation Frequency
%     ch_on.OFFSET = mod_offset;
%     ch_on.AMPLITUDE = mod_amp;
%     ch_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
%     ch_on.SWEEP='OFF';
%     ch_on.MOD='OFF';
%     ch_on.BURST='ON';             % Burst MODE 
%     ch_on.BURST_MODE='GATED';     % Trig via the gate
%     ch_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
%     ch_on.BURST_TRIGGER='EXT';    % External trigger.    
%     ch_on.STATE = 'ON';

%     defVar('ODT1_piezo_mod_Vpp',[-5:1:5],'V')
% 
%     mod_pp = abs(getVar('ODT1_piezo_mod_Vpp')); %V
%     mod_time = 200; %ms
%     mod_freq = 0.5/(mod_time*0.001);
%     
%     mod_offset = getVar('ODT1_piezo_mod_Vpp')/2;
%     if mod_offset > 0
%         mod_phase = 359;
%     else
%       mod_phase = 179;
%     end
%     
%     
%     addr_odt1 = 12;
%     
%         % ON Channel Settings
%     ch_on=struct;
% 
%     ch_on.FREQUENCY=mod_freq;     % Modulation Frequency
%     ch_on.OFFSET = mod_offset;
%     ch_on.AMPLITUDE = mod_pp;
%     ch_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
%     ch_on.FUNC = 'SQU';
%     ch_on.BURST_PHASE = mod_phase;
%     ch_on.SWEEP='OFF';
%     ch_on.MOD='OFF';
%     ch_on.BURST='ON';             % Burst MODE 
%     ch_on.BURST_MODE='GATED';     % Trig via the gate
%     ch_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
%     ch_on.BURST_TRIGGER='EXT';    % External trigger.    
%     ch_on.STATE = 'ON';
%     
%     
%     
%     %Turn on odt1 modulation
%     programRigol(addr_odt1,ch_on,[]);
%     
%     setDigitalChannel(calctime(curtime,0),'ODT Piezo Mod TTL',1);
%     
%     %Keep on for a set time
% %     curtime=calctime(curtime,mod_time); 
%     
%     %Turn off odt1 modulation
% %     setDigitalChannel(calctime(curtime,0),'ODT Piezo Mod TTL',0);

% end


%% Modulation
    
if seqdata.flags.conductivity_QPD_trigger
    DigitalPulse(curtime,'QPD Monitor Trigger',50,1);
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

% Turn off modulation amplitude after 1 ms for pinning
setAnalogChannel(calctime(curtime,1),'Modulation Ramp',-10,1);


%% Pin atoms
% Ramp lattices to in atoms

if seqdata.flags.conductivity_dopin    
    pin_time = 0.1;
    pin_depth = 60;
    
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth)
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), pin_time, pin_time, pin_depth);

    curtime = calctime(curtime,pin_time);

   % Turn off XDT
   AnalogFuncTo(calctime(curtime,50),'dipoleTrap1',...
       @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);
   AnalogFuncTo(calctime(curtime,50),'dipoleTrap2',...
       @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), 50, 50, -0.2);

end  

%% legacy
% %% Do modulation
%     
%     % Wait a lukewarm second
% curtime = calctime(curtime,10);
% 
% 
%     % Program Rigol for conductivity
%    
%     
%     if seqdata.flags.conductivity_modulate_ODT2
%         programRigol(mod_device,[],ch2_on);
%     end
%     
%   
%     
%     % Ramp on the modulation
% 
% 
% %     
% 
% %     % Ramp the modulation on with the VGAs
% %     if mod_time > mod_ramp_time        
% %         AnalogFunc(calctime(curtime,0),'Modulation Ramp',...
% %             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_ramp_time, mod_ramp_time,-10,final_mod_amp,1); 
% %     else        
% % curtime = AnalogFunc(calctime(curtime,0),'Modulation Ramp',...
% %     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), mod_time, mod_time,-10,final_mod_amp*mod_time/mod_ramp_time,1); 
% %   
% %     end
% 
%     %Do the modulation
% %     if mod_time > mod_ramp_time
% %         curtime=calctime(curtime,mod_time); 
% %     end


    
     


end

