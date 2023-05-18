%------
%Author: 
%Created: 
%Summary: 
%------

function timeout = lattice_control_test(timein)
global seqdata

curtime = timein;
curtime = calctime(curtime, 1000);
%% Rotate waveplate
wp_Trot1 = 600; % Rotation time during XDT
    
    P_RotWave_I = 0.8;
    P_RotWave_II = .99;
    
    AnalogFunc(calctime(curtime,-100-wp_Trot1),'latticeWaveplate',...
        @(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),...
        wp_Trot1,wp_Trot1,P_RotWave_II);    

scope_trigger =  'lattice control test';'Rampup ODT';

%% Set Lattices to Zero Value
    L0=seqdata.params.lattice_zero;  
    
    setAnalogChannel(calctime(curtime,-60),'Lattice Feedback Offset', -9.8,1);

    
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',0); % 0 : All on, 1 : All off

  % Ramp xLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,0),'xLattice',L0(1));

    % Ramp yLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,0),'yLattice',L0(2));

    
    % Ramp zLattice to the first value ("0Er")
    setAnalogChannel(calctime(curtime,0),'zLattice',L0(3));

    curtime = calctime(curtime,100);
    
%%  Ramp Lattices Up


Xdepth = 0;1095; 1095;
Ydepth = 0;1045;
Zdepth = 1000;
tramp = 100;

ScopeTriggerPulse(calctime(curtime,0),'lattice_ramp_up');

    
AnalogFuncTo(calctime(curtime,0),'xLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
    tramp, tramp, Xdepth);
AnalogFuncTo(calctime(curtime,0),'yLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
    tramp, tramp, Ydepth); 
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
    tramp, tramp, Zdepth);


%% Hold Here

do_lattice_hold = 1;

if do_lattice_hold 
   hold_time = 500;
   curtime = calctime(curtime,hold_time);
end

%% Lattice mod


do_lattice_mod = 0;
if do_lattice_mod
    dispLineStr('Amplitude Modulation Spectroscopy',curtime)
    
    mod_freq = 250e3;    
    mod_time = 10;%0.2; %Closer to 100ms to kill atoms, 3ms for band excitations only. 
    mod_amp = .5;
    
    AM_spec_latt_depth = 300;
    AM_spec_direction = 'Z';
   lattice_ramp = 1; %if we need to ramp up the lattice for am spec
    if lattice_ramp
        T0 = 0;

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
    

curtime = calctime(curtime,100);  %extra wait time
    end    

    
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
            mod_amp = interp1(X_prefactors(:,1),X_prefactors(:,3),AM_spec_latt_depth);

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
            mod_amp = interp1(Y_prefactors(:,1),Y_prefactors(:,3),AM_spec_latt_depth);

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

            % Find the base depth
%             mod_amp = interp1(Z_prefactors(:,1),Z_prefactors(:,3),AM_spec_latt_depth);

            % Shift for frequency dependence
%             mod_amp = mod_amp*(7e-6*(mod_freq*1e-3)^2-0.0006*(mod_freq*1e-3)+0.035);
            
            % Approximate resonant frequency
            freq_c_approx = (2*4.49*sqrt(4*AM_spec_latt_depth)-3*4.49)*1e3;

            % Frequency distance from resonance
            dfreq = (mod_freq-freq_c_approx)*1e-3/100;            

            % Amount to increase amplitude by
            d_amp = dfreq*m_slope;

            % Find the base depth
            mod_amp = interp1(Z_prefactors(:,1),Z_prefactors(:,3),AM_spec_latt_depth);
            
%             mod_amp = 1.05;
            
            mod_amp = mod_amp+d_amp;
            
            ch_on.AMPLITUDE = mod_amp;
            % Program the Rigols for modulation
            programRigol(addr_mod_xy,ch_off,ch_off);  % Turn off xy mod
            programRigol(addr_z,[],ch_on);            % Turn off z mod
    end
    
    addOutputParam('mod_amp',mod_amp);
   
    % We leave the feedback on as it cannot keep up. This + the VVA will
    % make a frequency dependent drive.
    % Trigger and wait
    ScopeTriggerPulse(calctime(curtime,0),'Lattice_Mod');
    setDigitalChannel(calctime(curtime,0),'Lattice FM',1); 
    curtime = setDigitalChannel(calctime(curtime,mod_time),'Lattice FM',0);    

curtime = calctime(curtime,1000);

        % Ramp down lattices
        AnalogFuncTo(calctime(curtime,T0),'xLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, 0);   
        AnalogFuncTo(calctime(curtime,T0),'yLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, 0);    
curtime = AnalogFuncTo(calctime(curtime,T0),'zLattice',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            AM_spec_latt_ramptime, AM_spec_latt_ramptime, 0); 

end



%%
do_ramp_down = 1;

if do_ramp_down
    tramp = 3;    
    ScopeTriggerPulse(calctime(curtime,0),'lattice_ramp_down');
    
        
    AnalogFuncTo(calctime(curtime,0),'xLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tramp, tramp, L0(1));
    AnalogFuncTo(calctime(curtime,0),'yLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tramp, tramp, L0(2)); 
    AnalogFuncTo(calctime(curtime,0),'zLattice', @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tramp, tramp, L0(3));
    curtime = calctime(curtime,tramp);    
    
    curtime = setDigitalChannel(calctime(curtime,10),'yLatticeOFF',1);%0: ON
end

%%
lattice_reset_waveplate=1;
if (lattice_reset_waveplate)
    %Rotate waveplate to divert all power to dipole traps.
    P_RotWave = 0;
    AnalogFunc(calctime(curtime,0),'latticeWaveplate',...
        @(t,tt,Pmin,Pmax) ...
        (0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
        200,200,P_RotWave,0); 
end


%% End It
curtime = calctime(curtime,1000);
timeout = curtime;


%%

% SelectScopeTrigger('lattice_ramp_up')
SelectScopeTrigger('lattice_ramp_down')
end

