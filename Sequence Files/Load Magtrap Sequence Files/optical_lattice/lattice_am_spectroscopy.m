function [curtime] = lattice_am_spectroscopy(timein)
curtime = timein;
global seqdata

if seqdata.flags.mix_at_beginning
        error('DONT DO AM SPEC WITH A SPIN MIXTURE!!')
end
    
    dispLineStr('Amplitude Modulation Spectroscopy',curtime)
    
    lattice_ramp = 0; %if we need to ramp up the lattice for am spec
    if lattice_ramp
        AM_spec_latt_depth = paramGet('AM_spec_depth');
        AM_spec_direction = paramGet('AM_direction');
        
        AM_spec_latt_ramptime_list = [50];
        AM_spec_latt_ramptime = getScanParameter(AM_spec_latt_ramptime_list,...
            seqdata.scancycle,seqdata.randcyclelist,'AM_spec_latt_ramptime','ms');
 

 AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, AM_spec_latt_depth); 
        
            x_latt_voltage = getChannelValue(seqdata,'xLattice',1,1);
            y_latt_voltage = getChannelValue(seqdata,'yLattice',1,1);
            z_latt_voltage = getChannelValue(seqdata,'zLattice',1,1);    
            
            disp(x_latt_voltage);
            disp(y_latt_voltage);
            disp(z_latt_voltage);            
            
            addOutputParam('adwin_am_spec_X',x_latt_voltage);
            addOutputParam('adwin_am_spec_Y',y_latt_voltage);
            addOutputParam('adwin_am_spec_Z',z_latt_voltage);

curtime = calctime(curtime,50);  %extra wait time
    else 
        AM_spec_direction = 'X';
        AM_spec_latt_depth = 100;
    end
        
    % Turn off ODTs before modulation (if not already off)
    switch_off_XDT_before_Lat_modulation = 0;
    if (switch_off_XDT_before_Lat_modulation == 1) 
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50,50,-1);
curtime = calctime (curtime,50);
    end
    
    curtime=calctime(curtime,100);
 
    mod_freq = paramGet('AM_spec_freq');    
    mod_time = 3;%0.2; %Closer to 100ms to kill atoms, 3ms for band excitations only. 

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
    
    addr_mod_xy = 9; % ch1 x mod, ch2 y mod
    addr_z = 5; %ch1 z lat, ch2 z mod  
    switch AM_spec_direction    
        case 'X'            
            m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            X_prefactors =[
                50 112  0.17;
                100 165 0.275;
                200 240 0.44;
                300 297 0.52;];

            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(X_prefactors(:,1),X_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');

            % Shift for frequency dependence
            mod_amp = mod_amp+d_amp;            

  
            % Program the Rigols for modulation
            ch_on.AMPLITUDE = mod_amp;
            programRigol(addr_mod_xy,ch_on,ch_off); % turn on x mod, turn off y mod
            programRigol(addr_z,[],ch_off);         % Turn off z mod
        case 'Y'     
             m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            Y_prefactors =[
                50 112  0.17;
                100 165 0.275;
                200 240 0.44;
                300 297 0.52;];

            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(Y_prefactors(:,1),Y_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');

            % Shift for frequency dependence
            mod_amp = mod_amp+d_amp;
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_on);  % Turn off x mod, turn on y mod
            programRigol(addr_z,[],ch_off);          % Turn off z mod        
        case 'Z'
             m_slope = 0.05; % Per 100 kHz increase the amplitude by this amount

%            % Lattice depth, resonant frequency, modulation amplitude
            Z_prefactors =[
                50 112  0.3;
                100 165 0.5;
                200 240 0.7;
                300 297 1.05];
        
            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance in 100kHz
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(Z_prefactors(:,1),Z_prefactors(:,3),AM_spec_latt_depth,'linear','extrap');
                        
            mod_amp = mod_amp+d_amp;
            
            mod_amp = mod_amp;
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_off);  % Turn off xy mod
            programRigol(addr_z,[],ch_on);            % Turn on z mod
        otherwise
            disp('not modulating');
            mod_amp = 0;
    end
    
    addOutputParam('mod_amp',mod_amp);
   
    % We leave the feedback on as it cannot keep up. This + the VVA will
    % make a frequency dependent drive.
    % Trigger and wait
    setDigitalChannel(calctime(curtime,0),'Lattice FM',1); 
    curtime = setDigitalChannel(calctime(curtime,mod_time),'Lattice FM',0);
    ScopeTriggerPulse(calctime(curtime,-.02),'Lattice_Mod');


curtime = calctime(curtime,1);
end

