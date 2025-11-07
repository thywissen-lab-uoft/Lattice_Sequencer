function [curtime] = lattice_FB(timein,override)

%% Description

% This function performs various RF, Raman, field, and lattice
% manipulations, currently used for investigating interaction induced
% effects in multi-band systems. This is similar to lattice_HF, but has
% some new functions and processes

%% Initialize settings

global seqdata
if nargin == 0;timein = 10;end
curtime = timein;

%%%%%%% Settings %%%%%%%

% Singlon filter 
% Puts singlons in to c+d states, can be distinguished in SG img
seqdata.flags.lattice_FB_filter_singlons       = 0;
defVar('lattice_FB_filter_depth_ramptime',10,'ms');        
defVar('lattice_FB_filter_depth_X',[200],'Er');
defVar('lattice_FB_filter_depth_Y',[200],'Er');
defVar('lattice_FB_filter_depth_Z',[200],'Er');
defVar('lattice_FB_filter_feshbach_time',10,'ms');
defVar('lattice_FB_filter_feshbach_field',198.5,'G');
defVar('lattice_FB_filter_feshbach_holdtime',0,'ms');

%%%%%%% Raman preparation/spectroscopy %%%%%%%
% Ramp the field
seqdata.flags.lattice_FB_field_ramp_pre_spec   = 1;
defVar('lattice_FB_pre_spec_feshbach_time',200,'ms');
defVar('lattice_FB_pre_spec_feshbach_settling_time',20,'ms');
defVar('lattice_FB_pre_spec_feshbach_field',130,'G');
defVar('lattice_FB_pre_spec_feshbach_holdtime',0,'ms');

% Ramp lattice depth
seqdata.flags.lattice_FB_spec_ramp             = 1;
defVar('lattice_FB_spec_ramptime',10,'ms');  
defVar('lattice_FB_spec_ramp_settling_time',5,'ms');
defVar('lattice_FB_spec_depth_X',[40],'Er'); 100;
defVar('lattice_FB_spec_depth_Y',[50],'Er'); 200;
defVar('lattice_FB_spec_depth_Z',[400],'Er'); 400;

% do the Raman spec
seqdata.flags.lattice_FB_raman_spec            = 0;
defVar('lattice_FB_Raman_DP_freq_shift',[-64],'kHz');-92.5;-72.5;60;61;% 100 Er: 57 kHz 9n-->7n+1 -25 n--> n, 7n-->9n+1 -73 kHz 
defVar('lattice_FB_Raman_DP_power',2.3,'V');2.3;
defVar('lattice_FB_Raman_AOM2_power',1.6,'V');1.6;

defVar('lattice_FB_Raman_DP_alt_freq_shift',[0:5:35],'kHz');
defVar('lattice_FB_Raman_DP_power_alt',1,'V');2.3;

defVar('lattice_FB_Raman_sweep_range',5,'kHz');
defVar('lattice_FB_Raman_time',[1],'ms');0.074; % 1 ms for sweep, 0.09 ms for pi pulse at -21.72 GHz cmdet 86 us pi/2
defVar('lattice_FB_post_Raman_holdtime',[0],'ms'); %[0:0.005:0.05];

% Raman_type = 'pulse';
Raman_type = 'sweep';

defVar('lattice_Raman_common_mode_det',[-21.6],'GHz');

% do a second pulse with some wait time, can also ramp lattices in between
seqdata.flags.lattice_FB_double_raman_spec             = 0;
seqdata.flags.lattice_FB_double_raman_lattice_ramp     = 0;
defVar('lattice_FB_Raman_dp_depth_X',[100],'Er');
defVar('lattice_FB_Raman_dp_depth_Y',[50],'Er');
defVar('lattice_FB_Raman_dp_depth_Z',[400],'Er'); 
defVar('lattice_FB_Raman_double_pulse_wait_time',[0.05],'ms');0.05; %used only with double raman spec, wait time between pulses, lattice ramp time if using
defVar('lattice_FB_Raman_time2',[1],'ms');0.05; % 1 ms for sweep, 0.09 ms for pi pulse at -21.72 GHz cmdet

% do a third pulse with some wait time, must have single and double on.
% useful for spin echo measurement 
%(needs to be reworked for the new Raman DP frequency source)
seqdata.flags.lattice_FB_triple_raman_spec             = 0;
echo_time = getVar('lattice_FB_Raman_double_pulse_wait_time'); % want these to be the same for spin echo measurement
defVar('lattice_FB_Raman_triple_pulse_wait_time',[echo_time],'ms'); %used only with triple raman spec, wait time between pulses 2 and 3
defVar('lattice_FB_Raman_time3',[0.01],'ms');0.05; % 1 ms for sweep, 0.09 ms for pi pulse at -21.72 GHz cmdet

% do Raman reversal - takes Raman settings and does it again but in reverse
% currently only set up for double pulse
seqdata.flags.lattice_FB_raman_reverse                  = 0;

%%%%%%% uWave spectroscopy %%%%%%%
% transfer b -> q
seqdata.flags.lattice_FB_uWave_spec            = 0;
defVar('lattice_FB_uWave_frequency_offset',[195],'kHz');
defVar('lattice_FB_uWave_range',[80],'kHz');25;
defVar('lattice_FB_uWave_power',[5],'dBm');
defVar('lattice_FB_uWave_time',[1],'ms');

% lattice depth ramp after Raman
seqdata.flags.lattice_FB_ramp_post_raman       = 0;
defVar('lattice_FB_post_raman_ramptime',[0.05],'ms');   
defVar('lattice_FB_post_raman_ramp_settling_time',[0.1],'ms');
defVar('lattice_FB_post_raman_depth_X',[100],'Er');
defVar('lattice_FB_post_raman_depth_Y',[100],'Er');
defVar('lattice_FB_post_raman_depth_Z',[400],'Er');
defVar('lattice_FB_post_raman_lattice_ramp_holdtime',[0],'ms');

% field ramp after Raman
seqdata.flags.lattice_FB_field_ramp_post_raman  = 0;
defVar('lattice_FB_post_raman_feshbach_time',10,'ms');
defVar('lattice_FB_post_raman_feshbach_settling_time',1,'ms')
defVar('lattice_FB_post_raman_feshbach_field',[132.055],'G');132.009;20;
defVar('lattice_FB_post_raman_feshbach_holdtime',[1000],'ms');

%%%%%%% Raman preparation/spectroscopy after oscillations %%%%%%%
% Ramp lattice depth (back to imbalance)
seqdata.flags.lattice_FB_post_osc_ramp             = 0;
defVar('lattice_FB_post_osc_ramptime',0.5,'ms');10; % 1  
defVar('lattice_FB_post_osc_ramp_settling_time',1,'ms');
defVar('lattice_FB_post_osc_depth_X',[250],'Er');
defVar('lattice_FB_post_osc_depth_Y',[100],'Er');
defVar('lattice_FB_post_osc_depth_Z',[400],'Er'); 

% Ramp the field
seqdata.flags.lattice_FB_post_osc_field_ramp   = 0;
defVar('lattice_FB_post_osc_feshbach_time',1,'ms');
defVar('lattice_FB_post_osc_feshbach_settling_time',1,'ms');
defVar('lattice_FB_post_osc_feshbach_field',130,'G');
defVar('lattice_FB_post_osc_feshbach_holdtime',0,'ms');

% do the Raman spec for readout
seqdata.flags.lattice_FB_post_osc_raman_spec            = 0;
defVar('lattice_FB_Raman_post_osc_DP_freq_shift',[-73],'kHz');73;60;61;% 100 Er: 57 kHz 9n-->7n+1 -25 n--> n, 7n-->9n+1-73 kHz 
defVar('lattice_FB_Raman_post_osc_DP_power',[2.3],'V');
defVar('lattice_FB_Raman_post_osc_sweep_range',[5],'kHz');
defVar('lattice_FB_Raman_post_osc_time',[0.06],'ms'); % 1 ms for sweep, 0.25 ms for pi pulse
defVar('lattice_FB_Raman_post_osc_AOM2_power',[1.6],'V');
Raman_post_osc_type = 'pulse';
% Raman_post_osc_type = 'sweep';

%%%%%%% RF spectrscopy %%%%%%%
% do the RF
seqdata.flags.lattice_FB_RF_spectroscopy       = 0;
seqdata.flags.lattice_FB_rf_spec_PID           = 0;
seqdata.flags.lattice_FB_rf_spec_ACync         = 0;
defVar('lattice_FB_RF_spec_frequency_offset',[0],'kHz');
defVar('lattice_FB_RF_spec_sweep_range',[500],'kHz');   2.5;   
defVar('lattice_FB_RF_spec_time',[50],'ms');   1;
defVar('lattice_FB_RF_spec_power',[5],'dBm');
defVar('lattice_FB_RF_spec_holdtime',[0],'ms');[0:0.025:0.4];

% field ramp after RF
seqdata.flags.lattice_FB_field_ramp_post_spec  = 0;
defVar('lattice_FB_post_spec_feshbach_time',[30],'ms');
defVar('lattice_FB_post_spec_feshbach_settling_time',10,'ms');
defVar('lattice_FB_post_spec_feshbach_field',[132.04],'G');
defVar('lattice_FB_post_spec_feshbach_holdtime',0,'ms');

% another field ramp after RF
seqdata.flags.lattice_FB_field_ramp_post_spec2  = 0;
defVar('lattice_FB_post_spec_feshbach2_time',[30],'ms');
defVar('lattice_FB_post_spec_feshbach2_settling_time',2,'ms');20;
defVar('lattice_FB_post_spec_feshbach2_field',[132.14],'G');
defVar('lattice_FB_post_spec_feshbach2_holdtime',0,'ms');

   

%% Filter out singlons 
% Puts singlons into c+d states to distinguish in SG imaging
% Steps:
% 1) Ramp lattice to ___ Er
% 2) Ramp field to ___ G
% 3) Transfer singlon b-->c (doublons shielded by s-wave int. shift)
% 4) Transfer singlon d-->c
% 5) Flip a-->b
% 6) Transfer singlon b--> c
if seqdata.flags.lattice_FB_filter_singlons
    
%%%%% Ramp lattice to 100 Er %%%%%
    % Perform the rest of the lattice ramps
   dT = getVar('lattice_FB_filter_depth_ramptime');
   Ux = getVar('lattice_FB_filter_depth_X');
   Uy = getVar('lattice_FB_filter_depth_Y');
   Uz = getVar('lattice_FB_filter_depth_Z');
   
   % Define Ramp Ups
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uy);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uz);    
    
% Wait for ramp to occur
curtime = calctime(curtime,dT);    
% Wait for ramp to settle
curtime = calctime(curtime,5); 

%%%%% Ramp to interacting field  %%%%%
     tr = getVar('lattice_FB_filter_feshbach_time');
    fesh = getVar('lattice_FB_filter_feshbach_field');

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = tr;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = tr;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = 20;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    % Hold after ramping up FB
    tFBH = getVar('lattice_FB_filter_feshbach_holdtime');
curtime=calctime(curtime,tFBH);

%%%%% Transfer singlon a-->c with linear DDS sweep %%%%%
     Bfb = getChannelValue(seqdata,'FB Current',1);    
     Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
     Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
     Boff = 0.107; % 130 G April 2025
     B = Bfb + Boff + Bz_shim;
        
    doLinear = 0;
    if doLinear
        %Do RF Sweep
        clear('sweep');
        
%         Bfb = getChannelValue(seqdata,'FB Current',1);    
%         Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
%         Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
%         Boff = 0.107; % 130 G April 2025
%     
%         B = Bfb + Boff + Bz_shim;
        
        defVar('lattice_FB_ac_freq_shift',[-20 -10 10],'kHz');
        
        sweep_pars.freq =(BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-5/2))/6.6260755e-34/1E6 + getVar('lattice_FB_ac_freq_shift')*1e-3; %Sweeps -9/2 to -5/2 at 198 G.
        sweep_pars.power =0; %-7.7
        sweep_pars.delta_freq = 20*1e-3; % end_frequency - start_frequency   0.01
        sweep_pars.pulse_length = 1; % also is sweep length  0.5
        sweep_pars.fake_pulse = 0;

        addOutputParam('RF_Filter_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
curtime = calctime(curtime, 0);

    end
    
    delta_freq_DDS = 20*1e-3;
    rf_pulse_length = 1;
    
    defVar('lattice_FB_ac_freq_shift',[-50:10:10],'kHz');
    rf_freq_HF =abs((BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-5/2))/6.6260755e-34/1E6 + getVar('lattice_FB_ac_freq_shift')*1e-3);
    
    freq_list=rf_freq_HF+[...
                    -0.5*delta_freq_DDS ...
                    -0.5*delta_freq_DDS ...
                    0.5*delta_freq_DDS ...
                    0.5*delta_freq_DDS];            
                pulse_list=[2 rf_pulse_length 2];

                % Max rabi frequency in volts (uncalibrated for now)
                off_voltage=-10;
                
                peak_voltage_list = 0;
                peak_voltage = getScanParameter(peak_voltage_list,seqdata.scancycle,...
            seqdata.randcyclelist,'DDS_RF_HFspec_gain', 'V');

                % Display the sweep settings
                disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
                disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
                disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
                disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


                % Set RF gain to zero a little bit before
                setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

                % Turn on RF
                setDigitalChannel(curtime,'RF TTL',1);   

                % Set to RF
                setDigitalChannel(curtime,'RF/uWave Transfer',0);   

                do_ACync_rf = 0;
                if do_ACync_rf
                    ACync_start_time = calctime(curtime,-30);
                    ACync_end_time = calctime(curtime,sum(pulse_list)+30);
                    setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                    setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
                end

                % Trigger pulse duration
                dTP=0.1;
                DDS_ID=1;

                % Initialize "Sweep", ramp up power        
                sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),peak_voltage); 

                % Primary Sweep, constant power            
                sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=calctime(curtime,pulse_list(2));

                % Final "Sweep", ramp down power
                sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
                DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
                seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
                curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
                    @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
                    pulse_list(1),pulse_list(1),off_voltage); 

                % Turn off RF
                setDigitalChannel(curtime,'RF TTL',0);
    
    
    
    
end
%% Field Ramps BEFORE uWave/RF Spectroscopy
% This code prepares the magnetic fields for uWave and RF spectroscopy

% Shim values for zero field found via spectroscopy
%          x_Bzero = 0.115; %0.03 minimizes field
%          y_Bzero = -0.0925; %-0.075  -0.07 minimizes field
%          z_Bzero = -0.145;% Z BIPOLAR PARAM, -0.075 minimizes the field
%          (May 20th, 2013)

%RHYS - Spectroscopy sections for calibration. Comments about lack of code
%generality from dipole_transfer apply here too: clean and generalize!

if seqdata.flags.lattice_FB_field_ramp_pre_spec
    logNewSection('Ramping magnetic fields BEFORE RF/uwave spectroscopy',curtime);

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = getVar('lattice_FB_pre_spec_feshbach_time');
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = getVar('lattice_FB_pre_spec_feshbach_time');
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = getVar('lattice_FB_pre_spec_feshbach_field');
    ramp.settling_time      = getVar('lattice_FB_pre_spec_feshbach_settling_time');

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    % Hold after ramping up FB
    curtime=calctime(curtime,getVar('lattice_FB_pre_spec_feshbach_holdtime'));
    
end

%% Ramp lattice before spectroscopy
if seqdata.flags.lattice_FB_spec_ramp
    logNewSection('Lattice Ramp for Spectroscopy',curtime)    
    ScopeTriggerPulse(curtime,'lattice_ramp_2');   
    
   % Perform the rest of the lattice ramps
   dT  = getVar('lattice_FB_spec_ramptime');
   dTS = getVar('lattice_FB_spec_ramp_settling_time');
   Ux  = getVar('lattice_FB_spec_depth_X');
   Uy  = getVar('lattice_FB_spec_depth_Y');
   Uz  = getVar('lattice_FB_spec_depth_Z');
   
   % Define Ramp Ups
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uy);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uz);    
    
    % Wait for ramp to occur
    curtime = calctime(curtime,dT);    
    % Wait for ramp to settle
    curtime = calctime(curtime,dTS);          
end

%% Raman spectroscopy
if seqdata.flags.lattice_FB_raman_spec
    
    Raman_opts.mF1                  = -9/2;
    Raman_opts.mF2                  = -7/2;
    Raman_opts.mF1_alt              = -9/2;
    Raman_opts.mF2_alt              = -9/2;
    Raman_opts.dF                   = getVar('lattice_FB_Raman_DP_freq_shift');
    Raman_opts.dF2                  = getVar('lattice_FB_Raman_DP_alt_freq_shift');
    Raman_opts.Raman_AOM2_power     = getVar('lattice_FB_Raman_AOM2_power');
    Raman_opts.Raman_AOM3_power     = getVar('lattice_FB_Raman_DP_power');
    Raman_opts.Raman_AOM3_power_alt = getVar('lattice_FB_Raman_DP_power_alt');
    Raman_opts.sweep_range          = getVar('lattice_FB_Raman_sweep_range');
    Raman_opts.time                 = getVar('lattice_FB_Raman_time');
    Raman_opts.time2                = getVar('lattice_FB_Raman_time2');
    Raman_opts.time3                = getVar('lattice_FB_Raman_time3');
    Raman_opts.pulse_wait           = getVar('lattice_FB_Raman_double_pulse_wait_time');
    Raman_opts.pulse_wait2          = getVar('lattice_FB_Raman_triple_pulse_wait_time');
    Raman_opts.Ux                   = getVar('lattice_FB_Raman_dp_depth_X');
    Raman_opts.Uy                   = getVar('lattice_FB_Raman_dp_depth_Y');
    Raman_opts.Uz                   = getVar('lattice_FB_Raman_dp_depth_Z');
    Raman_opts.doProgram            = 1;
    Raman_opts.doReversal           = seqdata.flags.lattice_FB_raman_reverse;
    Raman_opts.Source1              = 0;
    Raman_opts.Source2              = 1;
    Raman_opts.Source3              = 0;
    Raman_opts.isForward            = 1; % this changes shutter timing in a complicated way... should improve
    Raman_opts.post_hold            = getVar('lattice_FB_post_Raman_holdtime');
    
%     ScopeTriggerPulse(curtime,'Raman_spec'); 
    
    curtime = do_Raman_spectroscopy(curtime,Raman_type,Raman_opts);
%     curtime = calctime(curtime,getVar('lattice_FB_post_Raman_holdtime'));
end

%% Raman reverse spectroscopy - only works with double pulse rn
if seqdata.flags.lattice_FB_raman_reverse
    
    Raman_opts.mF1                  = -9/2;
    Raman_opts.mF2                  = -7/2;
    Raman_opts.dF                   = getVar('lattice_FB_Raman_DP_freq_shift');
    Raman_opts.dF2                  = getVar('lattice_FB_Raman_DP_alt_freq_shift');
    Raman_opts.Raman_AOM2_power     = getVar('lattice_FB_Raman_AOM2_power');
    Raman_opts.Raman_AOM3_power     = getVar('lattice_FB_Raman_DP_power');
    Raman_opts.sweep_range          = getVar('lattice_FB_Raman_sweep_range');
    Raman_opts.time                 = getVar('lattice_FB_Raman_time2');
    Raman_opts.time2                = getVar('lattice_FB_Raman_time');
%     Raman_opts.time3                = getVar('lattice_FB_Raman_time3');
    Raman_opts.pulse_wait           = getVar('lattice_FB_Raman_double_pulse_wait_time');
%     Raman_opts.pulse_wait2          = getVar('lattice_FB_Raman_triple_pulse_wait_time');
    Raman_opts.Ux                   = getVar('lattice_FB_Raman_dp_depth_Y'); % flip x and y depth
    Raman_opts.Uy                   = getVar('lattice_FB_Raman_dp_depth_X');
    Raman_opts.Uz                   = getVar('lattice_FB_Raman_dp_depth_Z');
    Raman_opts.doReversal           = seqdata.flags.lattice_FB_raman_reverse;
    Raman_opts.Source1              = 0;
    Raman_opts.Source2              = 0;
    Raman_opts.Source3              = 0;
    Raman_opts.isForward            = 0;
    Raman_opts.post_hold            = [0];
    Raman_opts.doProgram            = 0;
    
%     ScopeTriggerPulse(curtime,'Raman_spec'); 
    
    curtime = do_Raman_spectroscopy(curtime,Raman_type,Raman_opts);
%     curtime = calctime(curtime,getVar('lattice_FB_post_Raman_holdtime'));
end



%% K uWave Spectroscopy
if seqdata.flags.lattice_FB_uWave_spec
    
    logNewSection('uWave_K_Spectroscopy',curtime);
     
    % Read in settings
    freq_offset = getVar('lattice_FB_uWave_frequency_offset');
    freq_range  = getVar('lattice_FB_uWave_range');
    sweep_time  = getVar('lattice_FB_uWave_time');  
    power       = getVar('lattice_FB_uWave_power');
    
    % Calculate center frequency
%     F1      = 7/2;
%     mF1     = -5/2;
%     F2      = 9/2;
%     mF2     = -7/2;
%     
%     Bfb     = getChannelValue(seqdata,'FB Current',1);    
%     Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
%     Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
% %     Boff    = 0.1238; % 190+ G November 2024
%     Boff    = 0.107; % 130 G April 2025
%     
%     Bguess  = Bfb + Boff + Bz_shim;
%     f0      = abs((BreitRabiK(Bguess,F1,mF1) - BreitRabiK(Bguess,F2,mF2))/6.6260755e-34/1E6);
    
    f0      = 1552.225; % b to q at 130 G
    defVar('lattice_FB_uWave_frequency',f0+freq_offset/1000,'MHz');
    center_freq = getVar('lattice_FB_uWave_frequency');
    
    % Spetroscopy parameters
    spec_pars = struct;
    spec_pars.GPIB = 30;                                % SRS GPIB Address    
    spec_pars.ENBR = 1;                                 % Enable N Type
    spec_pars.Mode          = 'sweep_frequency_chirp';
    spec_pars.use_ACSync    = 0;
    
    spec_pars.FREQ          = center_freq;              % center freq in MHz
    spec_pars.FDEV          = freq_range/1000;          % freq range in MHz
    spec_pars.PulseTime     = sweep_time;               % time in ms
    spec_pars.AMPR          = power;                    % power in dBm
    
    % Do you sweep back after a variable hold time?
    spec_pars.doSweepBack = 0;
    
    defVar('lattice_FB_uWave_sweep_back_hold_time',[1],'ms');     
    spec_pars.HoldTime = getVar('lattice_FB_uWave_sweep_back_hold_time');
        
    % Do spectroscopy
    curtime = K_uWave_Spectroscopy(curtime,spec_pars);
    
    curtime = calctime(curtime,10);
end

%% Ramp lattice post raman
if seqdata.flags.lattice_FB_ramp_post_raman
    logNewSection('Lattice Ramp after Raman',curtime)    
%     ScopeTriggerPulse(curtime,'lattice_ramp_2');    
   % Perform the rest of the lattice ramps

   dT = getVar('lattice_FB_post_raman_ramptime');
   dTs = getVar('lattice_FB_post_raman_ramp_settling_time');
   Ux = getVar('lattice_FB_post_raman_depth_X');
   Uy = getVar('lattice_FB_post_raman_depth_Y');
   Uz = getVar('lattice_FB_post_raman_depth_Z');
   
%    % Define Ramp Ups
%     AnalogFuncTo(calctime(curtime,0),'xLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Ux); 
%     AnalogFuncTo(calctime(curtime,0),'yLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uy);
%     AnalogFuncTo(calctime(curtime,0),'zLattice',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uz);    

    % Define Ramp Ups
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uy);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),dT, dT, Uz);    
    
    % Wait for ramp to occur
    curtime = calctime(curtime,dT);    
    % Wait for ramp to settle
    curtime = calctime(curtime,dTs);
    % Wait additional hold time
    curtime = calctime(curtime,getVar('lattice_FB_post_raman_lattice_ramp_holdtime'));
end

%% Field Ramps AFTER uWave/Raman Spectroscopy
if seqdata.flags.lattice_FB_field_ramp_post_raman
    
    logNewSection('Ramping magnetic fields AFTER Raman spectroscopy',curtime);

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = getVar('lattice_FB_post_raman_feshbach_time');
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = getVar('lattice_FB_post_raman_feshbach_time');
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = getVar('lattice_FB_post_raman_feshbach_field');
    ramp.settling_time      = getVar('lattice_FB_post_raman_feshbach_settling_time');1;    

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    if seqdata.flags.lattice_FB_rf_spec_PID
        setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',1);
        curtime = calctime(curtime,100);
    end
    
    % Hold after ramping up FB
    curtime=calctime(curtime,getVar('lattice_FB_post_raman_feshbach_holdtime'));
end

%% Lattice ramps AFTER oscillation measurement
if seqdata.flags.lattice_FB_post_osc_ramp
    logNewSection('Lattice Ramp after oscillation measurement',curtime)    
%     ScopeTriggerPulse(curtime,'lattice_ramp_2');    
   % Perform the rest of the lattice ramps
   
   dT = getVar('lattice_FB_post_osc_ramptime');
   dTs = getVar('lattice_FB_post_osc_ramp_settling_time');
   Ux = getVar('lattice_FB_post_osc_depth_X');
   Uy = getVar('lattice_FB_post_osc_depth_Y');
   Uz = getVar('lattice_FB_post_osc_depth_Z');
   % Define Ramp Ups
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uy);
    AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),dT, dT, Uz);    
    
    % Wait for ramp to occur
    curtime = calctime(curtime,dT);    
    % Wait for ramp to settle
    curtime = calctime(curtime,dTs);          
end

%% Field Ramps AFTER oscillation measurement
if seqdata.flags.lattice_FB_post_osc_field_ramp
    
    logNewSection('Ramping magnetic fields AFTER oscillation measurement',curtime);

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = getVar('lattice_FB_post_osc_feshbach_time');
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = getVar('lattice_FB_post_osc_feshbach_time');
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = getVar('lattice_FB_post_osc_feshbach_field');
    ramp.settling_time      = getVar('lattice_FB_post_osc_feshbach_settling_time');1;    

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    if seqdata.flags.lattice_FB_rf_spec_PID
        setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',1);
        curtime = calctime(curtime,100);
    end
    
    % Hold after ramping up FB
    curtime=calctime(curtime,getVar('lattice_FB_post_osc_feshbach_holdtime'));
end
%% Raman spectroscopy AFTER oscillation measurement
if seqdata.flags.lattice_FB_post_osc_raman_spec
    
    Raman_post_osc_opts.mF1                 = -9/2;
    Raman_post_osc_opts.mF2                 = -7/2;
    Raman_post_osc_opts.dF                  = getVar('lattice_FB_Raman_post_osc_DP_freq_shift');
    Raman_post_osc_opts.Raman_AOM2_power    = getVar('lattice_FB_Raman_post_osc_AOM2_power');
    Raman_post_osc_opts.Raman_AOM3_power    = getVar('lattice_FB_Raman_post_osc_DP_power');
    Raman_post_osc_opts.sweep_range         = getVar('lattice_FB_Raman_post_osc_sweep_range');
    Raman_post_osc_opts.time                = getVar('lattice_FB_Raman_post_osc_time');
    Raman_post_osc_opts.doProgram           = 0;
    
    curtime = do_Raman_spectroscopy(curtime,Raman_post_osc_type,Raman_post_osc_opts);
end

%% RF Spectroscopy
if seqdata.flags.lattice_FB_RF_spectroscopy
        logNewSection('RF spectroscopy.',curtime);
        
        Bfb = getChannelValue(seqdata,'FB Current',1);    
        Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
        Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
        Boff = 0.107; % 130 G April 2025
    
        B = Bfb + Boff + Bz_shim;
        
    doLinear = 0;
    if doLinear
        %Do RF Sweep
        clear('sweep');
        
%         Bfb = getChannelValue(seqdata,'FB Current',1);    
%         Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
%         Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
%         Boff = 0.107; % 130 G April 2025
%     
%         B = Bfb + Boff + Bz_shim;
        
        sweep_pars.freq =(BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6 + getVar('lattice_FB_RF_spec_frequency_offset')*1e-3; %Sweeps -9/2 to -7/2 at 207.6G.
        sweep_pars.power = 5;2.7; %-7.7
        sweep_pars.delta_freq = getVar('lattice_FB_RF_spec_sweep_range')*1e-3; % end_frequency - start_frequency   0.01
        sweep_pars.pulse_length = getVar('lattice_FB_RF_spec_time'); % also is sweep length  0.5
        sweep_pars.fake_pulse = 0;

        addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
curtime = calctime(curtime, 10);

extraextraholdtime = getVar('lattice_FB_RF_spec_holdtime');
curtime = calctime(curtime,extraextraholdtime);
    end
    
        reverse_sweep = 0;
        if reverse_sweep
            clear('ramp')
            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 5;
            ramp.fesh_ramp_delay = 5;
            B_2 = 199.6;
            ramp.fesh_final = (B_2-0.1)*1.08962;%0*(0.336/20)*22.6; %1.0077*2*22.6 for same transfer as plane selection
            ramp.use_fesh_switch = 1; %Don't actually want to close the FB switch to avoid current spikes
            ramp.settling_time = 5;

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
            sweep_pars.freq = (BreitRabiK(B_2,9/2,-5/2) - BreitRabiK(B_2,9/2,-7/2))/6.6260755e-34/1E6; 
            sweep_pars.delta_freq = -sweep_pars.delta_freq;
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
        end
        
    doHS1 = 1;
    use_ACync = seqdata.flags.lattice_FB_rf_spec_ACync;
    if doHS1
        
        rf_wait_time    = 0; 
        extra_wait_time = 0;
        rf_off_voltage  = -10;
        
        % Read in sweep params
        freq_offset = getVar('lattice_FB_RF_spec_frequency_offset');
        freq_amp = getVar('lattice_FB_RF_spec_sweep_range');      
        sweep_time = getVar('lattice_FB_RF_spec_time');   
        power = getVar('lattice_FB_RF_spec_power');
        center_freq = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        
        % Configure the SRS
        RF_opts=struct;
        RF_opts.Address      = 29;                       % SRS GPIB Addr
        RF_opts.Frequency    = center_freq+(freq_offset)*1E-3; % Frequency [MHz]
        RF_opts.PowerBNC     = power;%15                    % Power [dBm]
        RF_opts.EnableBNC    = 1;                        % Enable SRS output    
        RF_opts.EnableSweep  = 1;                    
        RF_opts.SweepRange   = 1e-3*freq_amp;         % Sweep Amplitude [MHz]
        
        env_amp     = 20;             % Relative amplitude of the sweep
        beta        = asech(0.005);   % Beta defines sharpness of HS1
        
        addOutputParam('lattice_FB_RF_spec_frequency',RF_opts.Frequency);            
        addOutputParam('lattice_FB_RF_spec_beta',beta);
        addOutputParam('lattice_FB_RF_spec_HS1_amp',env_amp);
        
        logText(['     Freq         : ' num2str(RF_opts.Frequency) ' MHz']);    
        logText(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);    
        logText(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        logText(['     Freq Amp     : ' num2str(freq_amp) ' kHz']);
        
        %%%% The Sweep Code Begins Here %%%% 
        
        % Set SRS Source post spec
        setDigitalChannel(calctime(curtime,-5),'SRS Source post spec',1);

        % Set SRS Source to the new one
        setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

        % Set SRS Direction to RF
        setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

        % Set initial modulation
        setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
        
        % Set RF power to low
        setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);

        % Set RF Source to SRS
        setDigitalChannel(calctime(curtime,-5),'RF Source',1);
       
        % Enable ACync
        if use_ACync
            setDigitalChannel(calctime(curtime,-30),'ACync Master',1);
        end
        
        % Turn on the RF
        setDigitalChannel(calctime(curtime,...
            rf_wait_time + extra_wait_time),'RF TTL',1);
        
        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,...
            rf_wait_time + extra_wait_time),'uWave FM/AM',...
            @(t,T,beta) - tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);

        % Sweep the linear VVA
        AnalogFunc(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF Gain',...
            @(t,T,beta,A) -10 + ...
            A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,env_amp);
% 
curtime = calctime(curtime,sweep_time);                     % Wait for sweep        
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF TTL',0); 

        % Turn off VVA
        setAnalogChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF Gain',rf_off_voltage);

        % Set RF Source to SRS
        setDigitalChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time+30),'RF Source',0);

        setDigitalChannel(calctime(curtime,...
             rf_wait_time + extra_wait_time+30),'SRS Source',1);
        
        setDigitalChannel(calctime(curtime,...
              rf_wait_time + extra_wait_time+30),'SRS Source post spec',0);
        
        % Reset the ACync
        if use_ACync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end
        
        % Program the SRS
        programSRS_BNC(RF_opts); 
        params.isProgrammedSRS = 1;

%         % Extra Wait Time
% curtime = calctime(curtime,30);

        if seqdata.flags.lattice_FB_rf_spec_PID
            setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',0);

        end

        extraextraholdtime = getVar('lattice_FB_RF_spec_holdtime');
curtime = calctime(curtime,extraextraholdtime);
    end
    
    doPulse = 0;
    if doPulse
       
        rf_wait_time    = 0; 
        extra_wait_time = 0;
        rf_off_voltage  = -10;
        
        % Read in sweep params
        freq_offset = getVar('lattice_FB_RF_spec_frequency_offset');
        freq_amp = getVar('lattice_FB_RF_spec_sweep_range');      
        sweep_time = getVar('lattice_FB_RF_spec_time');   
        power = getVar('lattice_FB_RF_spec_power');
        center_freq = (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        
        % Configure the SRS
        RF_opts=struct;
        RF_opts.Address      = 29;                       % SRS GPIB Addr
        RF_opts.Frequency    = center_freq+(freq_offset)*1E-3; % Frequency [MHz]
        RF_opts.PowerBNC     = power;%15                    % Power [dBm]
        RF_opts.EnableBNC    = 1;                        % Enable SRS output    
        RF_opts.EnableSweep  = 0;                    
        RF_opts.SweepRange   = 1e-3*freq_amp;         % Sweep Amplitude [MHz]
        
        env_amp     = 20;             % Relative amplitude of the sweep
        beta        = asech(0.005);   % Beta defines sharpness of HS1
        
        addOutputParam('lattice_FB_RF_spec_frequency',RF_opts.Frequency);            
        addOutputParam('lattice_FB_RF_spec_beta',beta);
        addOutputParam('lattice_FB_RF_spec_HS1_amp',env_amp);
        
        logText(['     Freq         : ' num2str(RF_opts.Frequency) ' MHz']);    
        logText(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);    
        logText(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        
        %%%% The Sweep Code Begins Here %%%% 
        
        % Set SRS Source post spec
        setDigitalChannel(calctime(curtime,-5),'SRS Source post spec',1);

        % Set SRS Source to the new one
        setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

        % Set SRS Direction to RF
        setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

        % Set initial modulation
        setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);
        
        % Set RF power to low
        setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);

        % Set RF Source to SRS
        setDigitalChannel(calctime(curtime,-5),'RF Source',1);
       
        % Enable ACync
        if use_ACync
            setDigitalChannel(calctime(curtime,-30),'ACync Master',1);
        end
        
        % Turn on the RF
        setDigitalChannel(calctime(curtime,...
            rf_wait_time + extra_wait_time),'RF TTL',1);

        % Set RF Gain high
        setAnalogChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF Gain',10);
        

curtime = calctime(curtime,sweep_time);                     % Wait for pulse   
        
        % Turn off the uWave
        setDigitalChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF TTL',0); 

        % Turn off VVA
        setAnalogChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time),'RF Gain',rf_off_voltage);

        % Set RF Source to SRS
        setDigitalChannel(calctime(curtime,...
            rf_wait_time  + extra_wait_time+30),'RF Source',0);

        setDigitalChannel(calctime(curtime,...
             rf_wait_time + extra_wait_time+30),'SRS Source',1);
        
        setDigitalChannel(calctime(curtime,...
              rf_wait_time + extra_wait_time+30),'SRS Source post spec',0);
        
        % Reset the ACync
        if use_ACync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end
        
        % Program the SRS
        programSRS_BNC(RF_opts); 
        params.isProgrammedSRS = 1;

        % Extra Wait Time
curtime = calctime(curtime,30);

        if seqdata.flags.lattice_FB_rf_spec_PID
            setDigitalChannel(calctime(curtime,0),'Big Shim PID Engage',0);

        end

        extraextraholdtime = getVar('lattice_FB_RF_spec_holdtime');
curtime = calctime(curtime,extraextraholdtime);

    end
end

%% Field Ramps AFTER uWave/RF Spectroscopy
if seqdata.flags.lattice_FB_field_ramp_post_spec
    
    logNewSection('Ramping magnetic fields AFTER RF/uwave spectroscopy',curtime);
    
    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = getVar('lattice_FB_post_spec_feshbach_time');
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = getVar('lattice_FB_post_spec_feshbach_time');
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = getVar('lattice_FB_post_spec_feshbach_field'); %22.6
    ramp.settling_time      = getVar('lattice_FB_post_spec_feshbach_settling_time');10;  

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    % Hold after ramping up FB
    curtime=calctime(curtime,getVar('lattice_FB_post_spec_feshbach_holdtime'));
end

%% More Field Ramps AFTER uWave/RF Spectroscopy
if seqdata.flags.lattice_FB_field_ramp_post_spec2
    
    logNewSection('Ramping magnetic fields AFTER RF/uwave spectroscopy 2',curtime);

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = getVar('lattice_FB_post_spec_feshbach2_time');
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = getVar('lattice_FB_post_spec_feshbach2_time');
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = getVar('lattice_FB_post_spec_feshbach2_field'); %22.6
    ramp.settling_time      = getVar('lattice_FB_post_spec_feshbach2_settling_time');    

    % Ramp FB with QP
    curtime= ramp_bias_fields(calctime(curtime,0), ramp);  
    
    % Hold after ramping up FB
    curtime=calctime(curtime,getVar('lattice_FB_post_spec_feshbach2_holdtime'));
end
     


end