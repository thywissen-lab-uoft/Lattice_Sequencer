function [curtime] = lattice_am_heating(timein)
curtime = timein;
global seqdata

if seqdata.flags.xdt_rfmix_start
    warning('DONT DO AM SPEC WITH A SPIN MIXTURE!!')
end
    
    logNewSection('Amplitude Modulation Spectroscopy',curtime)
    
%% AM Spec Parameters
    AM_heat_direction = 'X';
    AM_heat_latt_depth = 100;
    addOutputParam('AM_heat_depth',AM_heat_latt_depth);

    x_latt_voltage = getChannelValue(seqdata,'xLattice',1,1);
    y_latt_voltage = getChannelValue(seqdata,'yLattice',1,1);
    z_latt_voltage = getChannelValue(seqdata,'zLattice',1,1);    

    mod_freq = getVar('AM_heat_freq'); 
    mod_time = getVar('AM_heat_time');
    
    addOutputParam('adwin_am_heat_X',x_latt_voltage);
    addOutputParam('adwin_am_heat_Y',y_latt_voltage);
    addOutputParam('adwin_am_heat_Z',z_latt_voltage);
        
%% Turn off ODTs before modulation (if not already off)
    switch_off_XDT_before_Lat_modulation = 0;
    if (switch_off_XDT_before_Lat_modulation == 1) 
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
curtime = calctime (curtime,50);
    end
    
    curtime=calctime(curtime,100);
 
  
%% Rigol Settings
    % OFF Channel settings
    ch_off = struct;
    ch_off.STATE = 'OFF';
    ch_off.AMPLITUDE = 0;
    ch_off.FREQUENCY = 1;

    % ON Channel Settings
    ch_on=struct;
    ch_on.FREQUENCY=mod_freq;     % Modulation Frequency
    ch_on.AMPLITUDE_UNIT='VPP';   % Unit of modulation (Volts PP)
    ch_on.SWEEP='OFF';
    ch_on.MOD='OFF';
    ch_on.BURST='ON';             % Burst MODE 
    ch_on.BURST_MODE='GATED';     % Trig via the gate
    ch_on.BURST_TRIGGER_SLOPE='POS';% Positive trigger slope
    ch_on.BURST_TRIGGER='EXT';    % External trigger.    
    ch_on.STATE = 'ON';

%% Program the Rigols
    addr_mod_xy = 9; % ch1 x mod, ch2 y mod
    addr_z = 5; %ch1 z lat, ch2 z mod  
    switch AM_heat_direction    
        case 'X'            

            mod_amp = getVar('AM_heat_mod_amp');
  
            % Program the Rigols for modulation
            ch_on.AMPLITUDE = mod_amp;
            programRigol(addr_mod_xy,ch_on,ch_off); % turn on x mod, turn off y mod
            programRigol(addr_z,[],ch_off);         % Turn off z mod
            
        case 'Y'     

            mod_amp = getVar('AM_heat_mod_amp');
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_on);  % Turn off x mod, turn on y mod
            programRigol(addr_z,[],ch_off);          % Turn off z mod        
            
            
        case 'Z'
            
            mod_amp = getVar('AM_heat_mod_amp');
            
            ch_on.AMPLITUDE = mod_amp;
            
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_off);  % Turn off xy mod
            programRigol(addr_z,[],ch_on);            % Turn on z mod
            
        otherwise
            disp('not modulating');
            mod_amp = 0;
    end
    
    addOutputParam('mod_amp',mod_amp);
   

%% Run the code

% We leave the feedback on as it cannot keep up. This + the VVA will
    % make a frequency dependent drive.
    % Trigger and wait
    setDigitalChannel(calctime(curtime,0),'Lattice FM',1); 
    curtime = setDigitalChannel(calctime(curtime,mod_time),'Lattice FM',0);
    ScopeTriggerPulse(calctime(curtime,-.02),'Lattice_Mod');


curtime = calctime(curtime,1);
end
