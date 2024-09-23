function [curtime] = xdt_spin_transfers(timein)
curtime= timein;
global seqdata

% This code transfers atoms from the 2+9/2 spin combo to the 1+-9/2 spin
% combo.  Plese keep this code as simple as possible. It needs to be as
% fast as possible in order to minimized atom losses.
%% Flags and Variables
seqdata.flags.xdt_spin_xfer_prep_field  = 1;
seqdata.flags.xdt_spin_xfer_ramp_field  = 1;
seqdata.flags.xdt_spin_xfer_transfer_Rb = 1;
seqdata.flags.xdt_spin_xfer_transfer_K  = 1;
seqdata.flags.xdt_spin_xfer_Rb_2_kill   = 0;
seqdata.flags.xdt_spin_xfer_Rb_2_kill2  = 1;


tSweep = defVar('xdt_spin_transfer_rb_sweep_time',[300],'ms');
defVar('xdt_spin_field',19.425+[.9]);
defVar('xdt_spin_field_sweep_width',.1);


% New Try
defVar('xdt_spin_field_1',[19.4]);
defVar('xdt_spin_field_delta',[1]);
defVar('xdt_spin_field_ramp_time',getVar('xdt_spin_field_delta')*100/.1);    % 100 ms/(.1 Gauss) is a good speed for us
t0_rb=defVar('xdt_spin_rb_start_time',[60],'ms');
tp_rb=defVar('xdt_spin_rb_pulse_time',50,'ms'); % 

t0_k=defVar('xdt_spin_k_delay_time',25);
tp_k=defVar('xdt_spin_K_pulse_time',getVar('xdt_spin_field_ramp_time')-(t0_rb+tp_rb+t0_k));


tStart = curtime;
% %% Prepare Feshbach Field
% if seqdata.flags.xdt_spin_xfer_prep_field
%     tR = defVar('xdt_spin_transfer_t1',10,'ms');10;
%     tS = defVar('xdt_spin_transfer_tS',20,'ms');10; % Settling time
% 
%     Is = seqdata.params.shim_zero;
%     Ix = Is(1);
%     Iy = Is(2);
%     Iz = Is(3);
%  
%    % Ramp the FB Field
%     AnalogFuncTo(calctime(curtime,0),'FB Current',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         tR,tR,getVar('xdt_spin_field') + getVar('xdt_spin_field_sweep_width')/2);
%     
%     % Ramp shims to eliminate labs background field
%     AnalogFuncTo(calctime(curtime,0),'X Shim',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         tR,tR,Ix);
%     AnalogFuncTo(calctime(curtime,0),'Y Shim',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         tR,tR,Iy);
%      AnalogFuncTo(calctime(curtime,0),'Z Shim',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%         tR,tR,Iz);   
%     
%     % Wait for field and settling time
%     curtime=calctime(curtime,tS+tR);
% else 
%     curtime=calctime(curtime,10);
% end
%% Prepare Feshbach Field
% Prepare the magnetic field for Rb transfers which occur at around 19.5
% Gauss. Only ramp the shims because the FB coils have low inductance.
if seqdata.flags.xdt_spin_xfer_prep_field
    dispLineStr('Preperatory Field Ramp',curtime);

    tR = defVar('xdt_spin_transfer_t1',20,'ms'); 
   % Ramp the FB Field
    AnalogFuncTo(calctime(curtime,0),'FB Current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tR,tR,getVar('xdt_spin_field_1'));   
    curtime=calctime(curtime,tR);
end

%% Rb Transfer |2,2> to |1,1> Using Anritsu + Field Sweep
% Pulse the Rb uWave.  We rely on a field sweep in order to perform the
% Landau Zener transition
if seqdata.flags.xdt_spin_xfer_transfer_Rb       
    dispLineStr('uWave Rb Pulse',calctime(curtime,t0_rb));       
    
    % Anritsu frequency is 6.8756 GHz, which is 19.5 Ga to linear order in
    % B

    % Prepare
    setDigitalChannel(calctime(tStart,-30),'Rb uWave TTL',0);           % RF OFF
    setDigitalChannel(calctime(tStart,-20),'RF/uWave Transfer',1);      % 0: RF, 1: uwave      
    setDigitalChannel(calctime(tStart,-20),'K/Rb uWave Transfer',1);    % 0: K, 1: Rb     
    setDigitalChannel(calctime(tStart,-20),'Rb Source Transfer',0);     % 0 = Anritsu, 1 = Sextupler        
    
    % Pulse
    setDigitalChannel(calctime(curtime,t0_rb),'Rb uWave TTL',1);        % uWave on
    setDigitalChannel(calctime(curtime,t0_rb+tp_rb),'Rb uWave TTL',0);        % uWave off
    setDigitalChannel(calctime(curtime,t0_rb+tp_rb),'RF/uWave Transfer',0);   % 0: RF, 1: uwave   
end

% %% Rb Transfer |9/2,9/2> to |9/2,-9/2> Using DDS Freq sweep
% % Pulse the K RF during the eventual field sweep
% 
% if seqdata.flags.xdt_spin_xfer_transfer_K
%     % NOTE THAT THIS FREQUENCY COUPLES TO THE RB FIELD SWEEP    
%     dispLineStr('RF K Sweep 9-->-9',curtime);       
%  
%     % Avoid feshbach ramps to minimize time in bad spin combinations
%     disp(' Applying RF sweep to transfer K state.');
%     fesh_value = getChannelValue(seqdata,'FB current',1,0);    
%     disp(['Feshbach Value : ' num2str(fesh_value)]);
% 
%     % RF Sweep Settings
%     k_rf_freq_list = [5.8];[6.05];
%     k_rf_pulsetime_list = [100];100;
%     k_rf_power_list = [-3];
%     k_rf_delta_list=[-1];[-1.2];[-1];-0.5;   
%     
%     clear('sweep');
%     sweep=struct;
%     sweep_pars.freq = getScanParameter(k_rf_freq_list,seqdata.scancycle,...
%         seqdata.randcyclelist,'k_rftransfer_freq','MHz'); 
%     sweep_pars.power = getScanParameter(k_rf_power_list,seqdata.scancycle,...
%         seqdata.randcyclelist,'k_rftransfer_power','V'); 
%     sweep_pars.pulse_length = getScanParameter(k_rf_pulsetime_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_pulsetime','ms');
%     sweep_pars.delta_freq = getScanParameter(k_rf_delta_list,...
%         seqdata.scancycle,seqdata.randcyclelist,'k_rftransfer_delta','MHz');        
%     sweep_pars.fake_pulse = 0;      %Fake the pulse (for debugging)         
%     disp(['     Center Freq     (MHz) : ' num2str(sweep_pars.freq)]);
%     disp(['     Delta Freq      (MHz) : ' num2str(sweep_pars.delta_freq)]);
%     disp(['     Sweep time       (ms) : ' num2str(sweep_pars.pulse_length)]);
%     disp(['     Sweep Rate   (kHz/ms) : ' num2str(1E3*sweep_pars.delta_freq./sweep_pars.pulse_length)]);
% 
%     % Apply the RF      
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars); 
% curtime = calctime(curtime,5);
% end
% 

%%
if seqdata.flags.xdt_spin_xfer_Rb_2_kill2
    tKill = defVar('xdt_spin_transfer_rb_kill_time',2);

    % Approximate field
    B0 = 19.5;
    df = 1.39 * B0; % 2-->3 transition zeeman shift
    
    dispLineStr('Blowing Rb F=2 away',curtime);
    probe32_trap_detuning = 0;
    f_osc = calcOffsetLockFreq(probe32_trap_detuning,'Probe32');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,-15),DDS_id,f_osc*1e6,f_osc*1e6,1); 
    
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); % open Rb probe shutter
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);     % disable AOM rf (TTL), just to be sure   

    % Pulse AOM 1 ms after uWave transfer is complete
    DigitalPulse(calctime(curtime,t0_rb+tp_rb+1), 'Rb Probe/OP TTL',tKill,0); % pulse beam with TTL   15
    setDigitalChannel(calctime(curtime,t0_rb+tp_rb+tKill+1),'Rb Probe/OP shutter',0); % close shutter 
    
end
%% K Transfer |9/2,9/2> to |9/2,-9/2> Using DDS Freq sweep
% Pulse the K RF. We rely on a field ramp to sweep the states.

if seqdata.flags.xdt_spin_xfer_transfer_K
    % NOTE THAT THIS FREQUENCY COUPLES TO THE RB FIELD SWEEP    
    dispLineStr('RF K Sweep 9-->-9',curtime);  
    
    DDS_ID=1;

    G = defVar('spin_transfer_RF_gain',-2);
    f1 = 1e6*defVar('spin_transfer_K_freq',6.3,'MHz');6.40
    f2 = f1-.001; %( Don't actually sweep the frequency');
    
    % Turn on RF some time after Rb
    setDigitalChannel(calctime(curtime,t0_rb+tp_rb+t0_k),'RF TTL',1);           % RF ON 
    setAnalogChannel(calctime(curtime,t0_rb+tp_rb+t0_k-1),'RF Gain',G,1);       % Gain Set
    DigitalPulse(calctime(curtime,t0_rb+tp_rb+t0_k),'DDS ADWIN Trigger',5,1);   % DDS Trigger
    
    % Increment the number of DDS sweeps
    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;   
%     
    dT=tp_k;                    % Duration of this sweep in ms
    sweep=[DDS_ID f1 f2 dT];    % Sweep data;
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;    
     tsw = getVar('xdt_spin_field_ramp_time');

    setDigitalChannel(calctime(curtime,tsw),'RF TTL',0);           % RF OFF 
    setAnalogChannel(calctime(curtime,tsw),'RF Gain',-10);           % Gain Set
end


%% Ramp Feshbach Field

if seqdata.flags.xdt_spin_xfer_ramp_field
    dispLineStr('Field Ramp',curtime);    
    tsw = getVar('xdt_spin_field_ramp_time');

    AnalogFuncTo(calctime(curtime,0),'FB current',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tsw,tsw,getVar('xdt_spin_field_1')+getVar('xdt_spin_field_delta'));
    curtime = calctime(curtime,tsw);
end

    
%% Rb F=2 Blow Away

if seqdata.flags.xdt_spin_xfer_Rb_2_kill
    dispLineStr('Blowing Rb F=2 away',curtime);
    setAnalogChannel(calctime(curtime,-10),4,0.0); % set amplitude   0.7
    AnalogFuncTo(calctime(curtime,-15),34,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,6590-237); % Ramp Rb trap laser to resonance   237

    probe32_trap_detuning = 0;
    f_osc = calcOffsetLockFreq(probe32_trap_detuning,'Probe32');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,-15),DDS_id,f_osc*1e6,f_osc*1e6,1);   

    AnalogFuncTo(calctime(curtime,-15),35,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,1.2,1); % Ramp FF to Rb trap beat-lock 
    setDigitalChannel(calctime(curtime,-10),25,1); % open Rb probe shutter
    setDigitalChannel(calctime(curtime,-10),24,1); % disable AOM rf (TTL), just to be sure
    RbF2_kill_time_list =[2]; 3;
    pulse_time = getScanParameter(RbF2_kill_time_list,seqdata.scancycle,seqdata.randcyclelist,'RbF2_kill_time');
curtime = DigitalPulse(calctime(curtime,0), 'Rb Probe/OP TTL',pulse_time,0); % pulse beam with TTL   15
       setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); % close shutter
end

%% Wait

tW = defVar('xdt_hold_time',20);
curtime = calctime(curtime,tW);

% curtime=xdt_evap_stage_1(curtime,0,0,0)


dispLineStr('Ending spintransfer',curtime);
end

