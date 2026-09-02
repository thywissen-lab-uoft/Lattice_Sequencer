function timeout = xdtB(timein)

%% Load in
global seqdata
curtime = timein;

%% Turn on levitation

if seqdata.flags.xdtB_levitate
    HF_QP = getVar('xdtB_levitate_value');
    tr = getVar('xdtB_levitate_ramptime');   
    
     %%%%%%%% Set switches for reverse QP coils %%%%%%%%%
    C15_zero_value = 0.062;
    tozero_ramp_time = 50;

    % Ramp C16 and C15 to off values
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tozero_ramp_time,tozero_ramp_time,0);    
    AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),tozero_ramp_time,tozero_ramp_time,C15_zero_value,1); 
    curtime = calctime(curtime,tozero_ramp_time);

    % Wait for PID to settle
    curtime = calctime(curtime,50);

    % Close 15/16 Gate source to reverse current through QP coils
    t1516 = 10;    
    curtime = AnalogFuncTo(calctime(curtime,0),'15/16 GS',...
            @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2), ...
            t1516, t1516, 0);         
    setDigitalChannel(curtime,'Coil 16 TTL',1);     % Turn of 16 (obsolete?)
    curtime = calctime(curtime,10);
    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);


    
%     % Ramp up transport supply voltage
%     QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
%     tFF = 100;
%     AnalogFuncTo(calctime(curtime,0),'Transport FF',...
%         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
%         tFF,tFF,QP_FFValue);
%     curtime = calctime(curtime,tFF);
%     
%     % Ramp Coil 15
%     curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,HF_QP,1); 
    
    
    % Ramp up transport supply voltage For levitation, need only 2V
    QP_FFValue = 4; 
    tFF = 100;
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFF,tFF,QP_FFValue);
    curtime = calctime(curtime,tFF);    
    % Ramp Coil 15
    I_QP_rev = getVar('xdtB_levitate_current');
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,I_QP_rev,2); 
end
%% Turn on feshbach field

if seqdata.flags.xdtB_feshbach 
    
    ScopeTriggerPulse(curtime,'xdtB_FBramp');
    
    tr = getVar('xdtB_feshbach_ramptime');
    fesh = getVar('xdtB_feshbach_field');

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
    ramp.settling_time      = 100;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
end

%% Turn on feshbach field

if seqdata.flags.xdtB_feshbach_fine   
    tr = getVar('xdtB_feshbach_fine_ramptime');
    fesh = getVar('xdtB_feshbach_fine_field');

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
    ramp.settling_time      = 100;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

curtime = calctime(curtime,getVar('xdtB_feshbach_fine_holdtime'));
end
% Wait time for troubleshooting
% curtime = calctime(curtime,5000); %REMOVE ME
%% Hop the feshbach resonance

if seqdata.flags.xdtB_feshbach_hop
    % NEEDS TO BE WRITTEN AGAIN
end

%% RF Mix at high field
if seqdata.flags.xdtB_rf_mix
    logNewSection('High Field K 9-7 Mixing.',curtime);  
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=-9/2;mF2=-7/2;   
    rf_list =  [0] +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);        
    
    sweep_pars = struct;
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'xdtB_rf_mix_freq','MHz');
    
    defVar('xdtB_rf_mix_power',[-7.8],'V');
    defVar('xdtB_rf_mix_sweep_num',21,'sweeps');

    % Define the RF sweep parameters
    sweep_pars.power =  getVar('xdtB_rf_mix_power');
    delta_freq = 0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = .5;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  

    logText([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    logText([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    logText([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    logText([' RF Power        (V) : ' num2str(sweep_pars.power)]);
    
    n_sweeps_mix=getVar('xdtB_rf_mix_sweep_num');
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
         curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
         curtime = calctime(curtime,2);
    end        
   
    % CF : This doesn't work but I'm not sure why. It should be better than
    % the old code....
    boop=0;
    if boop
        DDS_ID           = 1;                % DDS ID
        f0               = sweep_pars.freq;  % Center frequency
        delta_freq       = 0.1;              % Sweep Range (MHz)
        dT               = 0.5;              % Duration of this sweep in ms
        dTP              = 0.1;              % DDS Pulse Length
        f_low            = f0-0.5*delta_freq;    % Low Frequency (MHz)
        f_high           = f0+0.5*delta_freq;   % High Frequency (MHz)   
        
        % Set to RF and prepare Power
        setDigitalChannel(calctime(curtime,-100),'RF/uWave Transfer',0);
        setAnalogChannel(curtime,'RF Gain',getVar('xdtB_rf_mix_power'));
        curtime = calctime(curtime,1);        
        % Turn on RF
        setDigitalChannel(curtime,'RF TTL',1);   
        % Iterate for each sweep
        for kk=1:n_sweeps_mix
            % Trigger the DDS
            DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
            % Increment the number of DDS sweeps
            seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;   
            if mod(kk,2) % Odd sweeps go low to high
                f1 = f_low;
                f2 = f_high;
            else         % Even sweeps go high to low
                f1 = f_high;
                f2 = f_low;
            end
            sweep=[DDS_ID f1 f2 dT];    % Sweep data;
            seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;
            curtime = calctime(curtime,dT+.5);            
        end
         setDigitalChannel(curtime,'RF TTL',0);    
        setAnalogChannel(curtime, 'RF Gain', -10);
    end    
    
    curtime = calctime(curtime,15);
end


%% Turn on feshbach field

% if seqdata.flags.xdtB_feshbach_fine2   
%     tr = getVar('xdtB_feshbach_fine2_ramptime');
%     fesh = getVar('xdtB_feshbach_fine2_field');
% 
%     % Define the ramp structure
%     ramp=struct;
%     ramp.shim_ramptime      = tr;
%     ramp.shim_ramp_delay    = 0;
%     ramp.xshim_final        = seqdata.params.shim_zero(1); 
%     ramp.yshim_final        = seqdata.params.shim_zero(2);
%     ramp.zshim_final        = seqdata.params.shim_zero(3);
%     ramp.fesh_ramptime      = tr;
%     ramp.fesh_ramp_delay    = 0;
%     ramp.fesh_final         = fesh; %22.6
%     ramp.settling_time      = 100;    
% 
%     % Ramp FB with QP
% curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
% end
% 


%% Optical Evaporation

if seqdata.flags.xdtB_evap    
                logNewSection('xdtB evap',curtime); 

     % Get Variables
    evap_time   = getVar('xdtB_evap_time');
    evap_tau    = getVar('xdtB_evap_time')/getVar('xdtB_evap_tau_fraction');
    p_end       = getVar('xdtB_evap_power');

    % Display Settings
    logText(' Performing exponential evaporation');
    logText(['     Evap Time (ms) : ' num2str(evap_time)]);
    logText(['     tau       (ms) : ' num2str(evap_tau)]);
    logText(['     XDT1 end   (W) : ' num2str(p_end)]);
    logText(['     XDT2 end   (W) : ' num2str(p_end)]);

    % Ramp Function
    evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    
    evap_time_evaluate = evap_time;       

   P10 = getChannelValue(seqdata,'dipoleTrap1',1,0);

    
    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    
    
    if seqdata.flags.xdtB_evap_levitate_compensate
        Pg = 0.055;
        V_levitate =[.1475]; 0.151;             
        Pprime = P10;
        V15_0 = getChannelValue(seqdata,'Coil 15',1,1);       
       P2_Coil_15 = @(P) max(V15_0, min(V_levitate,interp1([Pg Pprime],[V_levitate V15_0],P,'linear','extrap')));
        AnalogFunc(calctime(curtime,0),'Coil 15',...
            @(t,tt,tau,y1,y2) P2_Coil_15(evap_exp_ramp(t,tt,tau,y2,y1)),...
            evap_time_evaluate,evap_time,evap_tau,P10,p_end,1); 
    end       
    
    % Advance time
    curtime = calctime(curtime,evap_time_evaluate);   
end

%% Ramp Dipole After Evap
% Compress XDT after Stage 2 optical evaporation

if seqdata.flags.xdtB_ramp_power_end 
    logNewSection('Ramping XDT Power Back Up',curtime); 

    scale = getVar('xdtB_evap_end_ramp_scale');
    Pr = scale*getVar('xdtB_evap_end_ramp_power');
    Pr2 = scale*getVar('xdtB_evap_end_ramp_power2');
    tr = getVar('xdtB_evap_end_ramp_time');   
    
    % Ramp ODTs
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr2);
    curtime = calctime(curtime,tr);
  
    % Hold after ramping
    th = getVar('xdtB_evap_end_ramp_hold');
    curtime = calctime(curtime,th);
end


%% Re-create a spin mixture after high-field evaporation
if seqdata.flags.xdtB_rf_mix_post_evap
    
    logNewSection('High Field K 9-7 Mixing after XDTB evap.',curtime);  
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=-9/2;mF2=-7/2;   
    rf_list =  [0] +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);        
    
    sweep_pars = struct;
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'xdtB_rf_mix_freq','MHz');
    
    defVar('xdtB_rf_mix_post_evap_power',[-7.8],'V');
    defVar('xdtB_rf_mix_post_evap_sweep_num',21,'sweeps');

    % Define the RF sweep parameters
    sweep_pars.power =  getVar('xdtB_rf_mix_post_evap_power');
    delta_freq = 0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = .5;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  

    logText([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    logText([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    logText([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    logText([' RF Power        (V) : ' num2str(sweep_pars.power)]);
    
    n_sweeps_mix=getVar('xdtB_rf_mix_post_evap_sweep_num');
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
         curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
         curtime = calctime(curtime,2);
    end        
   
    
end


%% RF Spin Flip HF

if seqdata.flags.xdtB_post_RF_97
    logNewSection('RF transfer -9/2 to -7/2',curtime);
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=-9/2;mF2=-7/2;   
    rf_list =  [0] +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_freq_HF','MHz');

    % Define the RF sweep parameters
    sweep_pars.power =  [0];
    delta_freq = 0.5;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = 50;5;20;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

    logText([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    logText([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    logText([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    logText([' RF Power        (V) : ' num2str(sweep_pars.power)]);

    % Do the RF Sweep
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse 

end
%% RF Sweep at HF
if seqdata.flags.xdtB_post_RF_sweep
    
    logNewSection('RF transfer -9/2 (-7/2) to higher spin states',curtime);
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=-3/2;mF2=-1/2;   
    rf_list =  getVar('xdtB_post_RF_sweep_freq_shift') +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
    sweep_pars.freq = rf_list;
    
    % Define the RF sweep parameters
    sweep_pars.power =  getVar('xdtB_post_RF_sweep_power');
    sweep_pars.delta_freq = getVar('xdtB_post_RF_sweep_delta_freq');
    sweep_pars.pulse_length = getVar('xdtB_post_RF_sweep_time');
    
    % fake RF sweep?
    sweep_pars.fake_pulse = 0;
    
    logText([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    logText([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    logText([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    logText([' RF Power        (V) : ' num2str(sweep_pars.power)]);
    
        % Do the RF Sweep
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse 

% sweep back
doReverse = 0;
if doReverse
    curtime = calctime(curtime,5);
    sweep_pars.delta_freq = -1*getVar('xdtB_post_RF_sweep_delta_freq');
    curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse 
end
end


%% Ramp Power After Low field
% One application is to measure the trap bottom at low field
if seqdata.flags.xdtB_ramp_power_end2
    logNewSection('Ramping XDT Power Back Up',curtime); 

    Pr1 = getVar('xdtB_evap_end2_ramp_power');
    Pr2 = getVar('xdtB_evap_end2_ramp_power2');
    tr = getVar('xdtB_evap_end2_ramp_time');   
    
    % Ramp ODTs
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr1);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr2);
    curtime = calctime(curtime,tr);
 
end



%% Unhop the feshbach resonance

if seqdata.flags.xdtB_feshbach_unhop
    % NEEDS TO BE WRITTEN FROM OLD CODE
end

%% Levitation Adjustment

if seqdata.flags.xdtB_levitate_fine2
        logNewSection('levitate fine 2',curtime); 

    HF_QP = getVar('xdtB_levitate_fine2_current'); % this is now current in A
    tr = getVar('xdtB_levitate_fine2_ramptime');       

    % Ramp Coil 15 (now uses current)
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,HF_QP,2); 
    
end

%% Secondary Feshbach Ramp after evaporation

if seqdata.flags.xdtB_feshbach_fine2   
            logNewSection('feshbach fine 2',curtime); 
            
            ScopeTriggerPulse(curtime,'xdtb_feshbach_fine2');

    tr = getVar('xdtB_feshbach_fine2_ramptime');
    fesh = getVar('xdtB_feshbach_fine2_field');

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
    ramp.settling_time      = 0;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
curtime = calctime(curtime,getVar('xdtB_feshbach_fine2_holdtime'));
end


%% Re-create a spin mixture after high-field evaporation
if seqdata.flags.xdtB_rf_mix2
    
    logNewSection('High Field K Mixing after RF sweep',curtime);  
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=3/2;mF2=1/2;   
%     rf_list =  [0] +...
%         abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
%     defVar('xdtB_rf_mix2_freq_shift',rf_list,'MHz');

    defVar('xdtB_rf_mix2_freq_shift',[0],'MHz');0;
    
    sweep_pars = struct;
    sweep_pars.freq = getVar('xdtB_rf_mix2_freq_shift')+...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
    
    
    defVar('xdtB_rf_mix2_power',[-9.2],'V');-9.2;
    defVar('xdtB_rf_mix2_sweep_num',[15],'sweeps');15;

    % Define the RF sweep parameters
    sweep_pars.power =  getVar('xdtB_rf_mix2_power');
    delta_freq = 0.05;0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = [0.65];.65;%2 ms for full transfer, 0.65 ms for 50/50
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  

    logText([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    logText([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    logText([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    logText([' RF Power        (V) : ' num2str(sweep_pars.power)]);
    
    n_sweeps_mix=getVar('xdtB_rf_mix2_sweep_num');
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
         curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
%          curtime = calctime(curtime,2);
    end     
    
%     defVar('xdtb_spin_mix_hold',[0],'ms');
%     curtime = calctime(curtime,getVar('xdtb_spin_mix_hold'));
    
end

%% Pulse on lattices
% CJF : This is poorly named code and confused me for a while.
% Please fix this.  Why would we call this a loading time?  
% All these variable name need to refer to the
% fact that this is a pulse measurement. 

if seqdata.flags.xdtB_pulse_lattice
    
    % Ramp parameters
    tL = getVar('xdtb_lattice_load_time');

    % Define individual lattices separately just in case
    Ux = getVar('xdtb_lattice_depth');
    Uy = getVar('xdtb_lattice_depth');
    Uz = getVar('xdtb_lattice_depth');
    
    tH = getVar('xdtb_lattice_hold_pulse_time');
    teq = getVar('xdtb_lattice_pulse_equil_time');
    
    % Set lattice feedback offset (double PD configuration)
setAnalogChannel(calctime(curtime,-60),'Lattice Feedback Offset', -9.8,1);
% Set PID request to below zero to rail PID
setAnalogChannel(calctime(curtime,-60),'xLattice',-9.85,1);
setAnalogChannel(calctime(curtime,-60),'yLattice',-9.85,1);
setAnalogChannel(calctime(curtime,-60),'zLattice',-9.85,1);
    
    % Enable AOMs on the lattice beams
    setDigitalChannel(calctime(curtime,-50),'yLatticeOFF',0); % 0 : All on, 1 : All off


    % Bring the PID levels to the "zero" value
    AnalogFuncTo(calctime(curtime,-40),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,seqdata.params.lattice_zero(1));
    AnalogFuncTo(calctime(curtime,-40),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,seqdata.params.lattice_zero(2));
    AnalogFuncTo(calctime(curtime,-40),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        20,20,seqdata.params.lattice_zero(3));

    % turn on the lattices
    ScopeTriggerPulse(curtime,'xdtb_pulse_lattice');
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,Ux); 
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,Uy);
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,Uz); 

    % pulse for some time
curtime = calctime(curtime,tH);


    % Ramp to low
    AnalogFuncTo(calctime(curtime,0),'xLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(1));
    AnalogFuncTo(calctime(curtime,0),'yLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(2));
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tL,tL,seqdata.params.lattice_zero(3));

    % Disable AOMs on the lattice beams
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1); % 0 : All on, 1 : All off

    % let atoms equilibriate in XDT
curtime = calctime(curtime,teq);
 
    
    
end

%% uWave Spectroscopy to Check field 
 if seqdata.flags.xdtb_rf_spec
     logNewSection('RF Spec',curtime);
     
    Bfb = getChannelValue(seqdata,'FB Current',1);    
    Iz_shim = getChannelValue(seqdata,'Z Shim',1);    
    Bz_shim = (Iz_shim-seqdata.params.shim_zero(3))*2.35;
    Boff = 0.1238;

    
    Bguess = Bfb + Boff + Bz_shim;
    
    % Transition guess 
    h = 6.6260755e-34;
    Fi = 9/2; Ff = 9/2;
    mFi = -9/2; mFf = -7/2;
    rf0 = 1e-6*abs(BreitRabiK(Bguess,Fi,mFi) - BreitRabiK(Bguess,Ff,mFf))/h;

    rf_shift_list =  1e-3*[20];   
    
    rf_list = rf_shift_list + rf0;
    
    defVar('xdtb_rf_freq',rf_list,'MHz');
    defVar('xdtb_rf_power',-2,'arb');
    defVar('xdtb_rf_delta',2.5,'kHz');
    defVar('xdtb_rf_time',10,'ms');
    
    addOutputParam('xdtb_rf_freq_shift',...
        1e3*(getVar('xdtb_rf_freq')-rf0),'kHz');

    sweep = struct;
    sweep.freq = getVar('xdtb_rf_freq');
    sweep.power = getVar('xdtb_rf_power');
    sweep.delta_freq = 1e-3*getVar('xdtb_rf_delta');
    sweep.pulse_length = getVar('xdtb_rf_time');
    
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
 

%% Turn off feshbach field and possibly leviation field

if seqdata.flags.xdtB_feshbach_off   
        logNewSection('Turning off the feshbach',curtime); 

    tr = getVar('xdtB_feshbach_off_ramptime');
    fesh = getVar('xdtB_feshbach_off_field');        

    % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime      = tr;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3);
    ramp.fesh_ramptime      = tr;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh;
    ramp.settling_time      = 0; 
    
     % check ramp_bias_fields to see what struct ramp may contain 
    
    if ~seqdata.flags.xdtB_levitate_off 
        curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    else
        ramp_bias_fields(calctime(curtime,0), ramp);
    end
    
end 

if seqdata.flags.xdtB_levitate_off  
    trQP = getVar('xdtB_levitate_off_ramptime');

    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),trQP,trQP,0,2);
      
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
             5,5,0); 
    % Go back to "normal" configuration
    curtime = calctime(curtime,10);
    % Turn off reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',0);
    curtime = calctime(curtime,10);
    % Turn on 15/16 switch
    curtime = AnalogFuncTo(calctime(curtime,0),'15/16 GS',...
         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
             10,10,9,1);              
    curtime = calctime(curtime,10); 
end

if seqdata.flags.xdtB_feshbach_off  
    curtime = calctime(curtime,50);
    curtime = calctime(curtime,getVar('xdtB_feshbach_off_holdtime'));
end

%% Ramp Feshbach and levitation to HF imaging values

if seqdata.flags.xdtB_HF_img_ramp
    
    % get the field - sets HF imaging parameters based on current field
    check_HF_Image();
    
    if isfield(seqdata.flags, 'HF_Imaging') && seqdata.flags.HF_Imaging
        
         % Set final feshbach value
        if seqdata.flags.HF_absorption_image.Attractive
            fesh = 207;
        else
            fesh = 195;
        end
    end
    
    defVar('xdtB_HF_img_levitate_current',0.15','A');
    defVar('xdtB_HF_img_feshbach_field',fesh,'G');
    defVar('xdtB_HF_img_ramptime',50,'ms');
    defVar('xdtB_HF_img_holdtime',75,'ms');

    HF_QP = getVar('xdtB_HF_img_levitate_current'); % this is now current in A
    tr = getVar('xdtB_HF_img_ramptime');  

    % Ramp Coil 15 (now uses current)
    AnalogFuncTo(calctime(curtime,0),'Coil 15 Small',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,HF_QP,2); 
    
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
    ramp.settling_time      = 0;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
curtime = calctime(curtime,getVar('xdtB_HF_img_holdtime'));
    
end


%% Piezo kick
if seqdata.flags.xdtB_piezo_vert_kick
    logNewSection('Kicking the dipole trap',curtime);
    
    tr = getVar('xdtB_piezo_vert_kick_rampup_time');
    V = getVar('xdtB_piezo_vert_kick_disp');
    t_off = getVar('xdtB_piezo_vert_kick_rampoff_time');
    th = getVarOrdered('xdtB_piezo_vert_kick_holdtime');

    % Piezo Mirror to a Displaced Position
    curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V);
    
    % Piezo Mirror to Original displacement
    curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),t_off,t_off,5);
    
    % Wait for oscillations
    curtime = calctime(curtime,th);  
end

%% XDT Piezo Ramp
% 2024/02/19 : CJF rewrote this code to make more sense to me, the other
% versions seemed needlessly complicated.

if seqdata.flags.xdtB_vert_piezo_ramp_ODT2 || seqdata.flags.xdtB_vert_piezo_ramp_ODT1
    logNewSection('Displacing ODT Piezos',curtime);
    DigitalPulse(calctime(curtime,-100),'QPD Monitor Trigger',5,1);

    tr = getVar('xdtB_vert_piezo_ramp_time');           % Ramp Time
    
    v10 = getChannelValue(seqdata,'XDT1 V Piezo',1);    % Starting ODT1
    v20 = getChannelValue(seqdata,'XDT2 V Piezo',1);    % Starting ODT2
    
    v1 = getVar('xdtB_vert_piezo_ramp_value_1');        % Set ODT1
    v2 = getVar('xdtB_vert_piezo_ramp_value_2');        % Set ODT2
    
    % Do you actually ramp?
    doRamp_ODT1 = seqdata.flags.xdtB_vert_piezo_ramp_ODT1;
    doRamp_ODT2 = seqdata.flags.xdtB_vert_piezo_ramp_ODT2;    
    doRampBack = 0;
    
    % Ramp ODT1 Vertical Piezo
    if doRamp_ODT1
        
        %  Conversion functions for ODT1
        V_C = 5;
        a1 = 0.175/5;
        b1 = 0;
        ODT1_CTRL_2_HV = @(V_CTRL) a1*(V_CTRL-V_C)+b1*(V_CTRL-V_C).^2+V_C;
        ODT1_CTRL_2_V  = @(V_CTRL) V_CTRL;
        
        
        v10 = getChannelValue(seqdata,'XDT1 V Piezo',1);   
        AnalogFunc(calctime(curtime,0),'XDT1 V Piezo',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,v10,v1);
        AnalogFunc(calctime(curtime,0),'ODT1 Piezo HV',...
            @(t,tt,y1,y2) ODT1_CTRL_2_HV(ramp_minjerk(t,tt,y1,y2)),tr,tr,v10,v1);
    
    end
    
    % Ramp ODT2 Vertical Piezo
    if doRamp_ODT2
        
        % % Conversion functions for ODT2
        V_C = 5;
        a2 = -1.45/5;
        b2 = .015;
        ODT2_CTRL_2_HV = @(V_CTRL) a2*(V_CTRL-V_C)+b2*(V_CTRL-V_C).^2+V_C;
        
        v20 = getChannelValue(seqdata,'XDT2 V Piezo',1);    
        AnalogFunc(calctime(curtime,0),'XDT2 V Piezo',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,v20,v2);  
        AnalogFunc(calctime(curtime,0),'ODT2 Piezo HV',...
            @(t,tt,y1,y2) ODT2_CTRL_2_HV(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,v20,v2);
    end
    
    % Wait for Piezo Ramps
    if (doRamp_ODT1 || doRamp_ODT2);curtime = calctime(curtime,tr);end
    
%     Wait for a bit (optional, sometimes this is useful)
    curtime = calctime(curtime,250);

    % Additional ramps to return (useful for round trip measurements)
    if doRampBack
       if doRamp_ODT1
            AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,v10);
       end       
        if doRamp_ODT2
            AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
                @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,v20);
        end        
        % Wait for ramps if they happened
        if (doRamp_ODT1 || doRamp_ODT2);curtime = calctime(curtime,tr);end        
    end
    
    % Wait for a bit (optional, sometimes this is useful)
%     curtime = calctime(curtime,50);]
end


%% Turn off one of the ODT beams
% After optical evaporation, turn off one of the trap so you can see the
% position of the other ODT beam
if seqdata.flags.xdtB_one_beam_ODT1 || seqdata.flags.xdtB_one_beam_ODT2
    logNewSection('Turning off one of the dipole trap beams',curtime);
    tr = 100;    
    
    P1 = getChannelValue(seqdata,'dipoleTrap1',1);
    P2 = getChannelValue(seqdata,'dipoleTrap2',1);
    
    odt1_on = seqdata.flags.xdtB_one_beam_ODT1;
    odt2_on = seqdata.flags.xdtB_one_beam_ODT2;
    doWait = 0;
    
    % To mitigate gravitational sag, turn one ODT off but then increase the
    % power in the other beam
    
    if odt2_on 
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,0);
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,2*P2);
        curtime = calctime(curtime,tr);
    end
    
    if odt1_on    
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,2*P1);
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,0);
        curtime = calctime(curtime,tr);
    end    
    
    % Optional wait time
    if doWait
         tW=defVar('xdtB_hold_time',[100]);
         curtime = calctime(curtime,tW);
    end
end


 %% Piezo hold ODT1
% if seqdata.flags.xdtB_odt1_piezo_vert_disp
%     logNewSection('Displacing ODT1',curtime);
%     
%     tr = getVar('xdtB_odt1_piezo_vert_disp_rampup_time');
%     V = getVar('xdtB_odt1_piezo_vert_disp_amplitude');
%     
%     DigitalPulse(calctime(curtime,-200),'QPD Monitor Trigger',5,1);
% 
% %     % Piezo Mirror to a Displaced Position
%     curtime = AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V);
%     
%     doRampBack = 0;
%     if doRampBack
%         
%     end
%     
% % 
% %         tr = 100;
% %     
% %         % Piezo Mirror to a Displaced Position
% %     V1 = 1;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V1);
% %     
% %     curtime = calctime(curtime,50);
% %     
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,5);
% %     
% %     curtime = calctime(curtime,200);
% %     
% %     
% %     
% %     % Piezo Mirror to a Displaced Position
% %     V2 = 9;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V2);
% %     
% %     curtime = calctime(curtime,50);
% %     
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT1 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,5);
% end

%% Piezo hold ODT2
% if seqdata.flags.xdtB_odt2_piezo_vert_disp
%     logNewSection('Displacing ODT2',curtime);
%     
%     tr = getVar('xdtB_odt2_piezo_vert_disp_rampup_time');
%     V = getVar('xdtB_odt2_piezo_vert_disp_amplitude');
%     
%     DigitalPulse(calctime(curtime,-100),'QPD Monitor Trigger',5,1);
% 
% %     Piezo Mirror to a Displaced Position
%     curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
%         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V);
%     
% %         tr = 100;
%     
% %         % Piezo Mirror to a Displaced Position
% %     V1 = 1;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V1);
% %     
% %     curtime = calctime(curtime,50);
% %     
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,5);
% %     
% %     curtime = calctime(curtime,200);
% %     
% %     
% %     
% %     % Piezo Mirror to a Displaced Position
% %     V2 = 9;
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V2);
% %     
% %     curtime = calctime(curtime,50);
% %     
% %     curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
% %         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,5);
%      
% end

%% Pulse Raman/Bragg beams

%%%%%%%%% Raman Spectroscopy settings %%%%%%%%%%
seqdata.flags.xdtB_raman_spec                   = 0;
% first pulse settings
defVar('xdtB_Raman_time',[1],'ms');0.074; % 1 ms for sweep, 0.09 ms for pi pulse at -21.72 GHz cmdet 86 us pi/2
defVar('xdtB_Raman_AOM2_power',0.5,'V');0.5;1.6;
seqdata.flags.Raman_Source1                     = 1; % 0 default, 1 alternate

% default source settings
defVar('xdtB_Raman_DP_freq_shift',[-64],'kHz');-92.5;-72.5;60;61;% 100 Er: 57 kHz 9n-->7n+1 -25 n--> n, 7n-->9n+1 -73 kHz 
defVar('xdtB_Raman_DP_power',2.3,'V');2.3;
defVar('xdtB_Raman_sweep_range',20,'kHz');
seqdata.flags.Raman_type                        = 1; % 1 is pulse, 0 sweep

% alternate source settings
defVar('xdtB_Raman_DP_alt_freq_shift',[17],'kHz');
defVar('xdtB_Raman_DP_power_alt',0.6,'V');0.6;2.3;
defVar('xdtB_Raman_sweep_range_alt',[5],'kHz');
seqdata.flags.Raman_type_alt                    = 1; % 1 is pulse, 0 sweep

% defVar('xdtB_Raman_common_mode_det',[-21.6],'GHz');
if seqdata.flags.xdtB_raman_spec
    
    Raman_opts.mF1                  = -9/2;
    Raman_opts.mF2                  = -7/2;
    Raman_opts.mF1_alt              = -9/2;
    Raman_opts.mF2_alt              = -9/2;
    Raman_opts.dF                   = getVar('xdtB_Raman_DP_freq_shift');
    Raman_opts.dF2                  = getVar('xdtB_Raman_DP_alt_freq_shift');
    Raman_opts.Raman_AOM2_power     = getVar('xdtB_Raman_AOM2_power');
    Raman_opts.Raman_AOM3_power     = getVar('xdtB_Raman_DP_power');
    Raman_opts.Raman_AOM3_power_alt = getVar('xdtB_Raman_DP_power_alt');
    Raman_opts.sweep_range          = getVar('xdtB_Raman_sweep_range');
    Raman_opts.sweep_range_alt      = getVar('xdtB_Raman_sweep_range_alt');
    Raman_opts.time                 = getVar('xdtB_Raman_time');

    Raman_opts.doProgram            = 1;
    
    % shutter timings if you're doing spin echo stuff
    Raman_opts.doReversal           = 0;
    Raman_opts.isForward            = 1; % this changes shutter timing in a complicated way... should improve
    
    Raman_opts.Source1              = 1; % 0 default, 1 alternate; % 0 is default
%     Raman_opts.Source2              = seqdata.flags.Raman_Source2;
%     Raman_opts.Source3              = seqdata.flags.Raman_Source3;
   
    Raman_opts.post_hold            = 0;
    Raman_opts.Raman_type           = seqdata.flags.Raman_type; % 1 is pulse, 0 sweep
    Raman_opts.Raman_type_alt       = seqdata.flags.Raman_type_alt;
    
    ScopeTriggerPulse(curtime,'Raman_spec'); 
    
    curtime = do_Raman_spectroscopy(curtime,Raman_opts);
%     curtime = calctime(curtime,getVar('lattice_FB_post_Raman_holdtime'));
end
%% The End

timeout = curtime;
end

