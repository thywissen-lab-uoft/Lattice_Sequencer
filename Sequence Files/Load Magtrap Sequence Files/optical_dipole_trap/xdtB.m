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

    % Ramp up transport supply voltage
    QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
    tFF = 100;
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        tFF,tFF,QP_FFValue);
    curtime = calctime(curtime,tFF);

    % Ramp Coil 15
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,HF_QP,1); 
end
%% Turn on feshbach field

if seqdata.flags.xdtB_feshbach   
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
end

%% Hop the feshbach resonance

if seqdata.flags.xdtB_feshbach_hop
    % NEEDS TO BE WRITTEN AGAIN
end

%% RF Mix at high field
if seqdata.flags.xdtB_rf_mix_feshbach
    % NEEDS TO BE WRITTEN 
end

%% Optical Evaporation

if seqdata.flags.xdtB_evap    
     % Get Variables
    evap_time   = getVar('xdtB_evap_time');
    evap_tau    = getVar('xdtB_evap_time')/getVar('xdtB_evap_tau_fraction');
    p_end       = getVar('xdtB_evap_power');

    % Display Settings
    disp(' Performing exponential evaporation');
    disp(['     Evap Time (ms) : ' num2str(evap_time)]);
    disp(['     tau       (ms) : ' num2str(evap_tau)]);
    disp(['     XDT1 end   (W) : ' num2str(p_end)]);
    disp(['     XDT2 end   (W) : ' num2str(p_end)]);

    % Ramp Function
    evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    
    evap_time_evaluate = evap_time;       

    % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_evaluate,evap_time,evap_tau,p_end);
    
    % Advance time
    curtime = calctime(curtime,evap_time_evaluate);   
end

%% Ramp Dipole After Evap
% Compress XDT after Stage 2 optical evaporation

if seqdata.flags.xdtB_ramp_power_end 
    dispLineStr('Ramping XDT Power Back Up',curtime); 

    Pr = getVar('xdtB_evap_end_ramp_power');
    tr = getVar('xdtB_evap_end_ramp_time');   
    
    % Ramp ODTs
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tr,tr,Pr);
    curtime = calctime(curtime,tr);
  
    % Hold after ramping
    th = getVar('xdt_evap_end_ramp_hold');
    curtime = calctime(curtime,th);
end

%% Turn on feshbach field

if seqdata.flags.xdtB_feshbach_fine2   
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
    ramp.settling_time      = 100;    

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
end

%% Unhop the feshbach resonance

if seqdata.flags.xdtB_feshbach_unhop
    % NEEDS TO BE WRITTEN FROM OLD CODE
end
%% Turn off feshbach field

if seqdata.flags.xdtB_feshbach_off   
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
    curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 
end

%% Turn off levitation field
if seqdata.flags.xdtB_levitate_off  
    tr = getVar('xdtB_levitate_off_ramptime');
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,0,1);               

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
        curtime = calctime(curtime,50);
end

%% Piezo kick
if seqdata.flags.xdtB_piezo_vert_kick
    dispLineStr('Kicking the dipole trap',curtime);
    
    tr = getVar('xdtB_piezo_vert_kick_rampup_time');
    V = getVar('xdtB_piezo_vert_kick_amplitude');
    t_off = getVar('xdtB_piezo_vert_kick_rampoff_time');
    th = getVar('xdtB_piezo_vert_kick_holdtime');

    % Piezo Mirror to a Displaced Position
    curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),tr,tr,V);
    
    % Piezo Mirror to Original displacement
    curtime = AnalogFuncTo(calctime(curtime,0),'XDT2 V Piezo',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),t_off,t_off,0);
    
    % Wait for oscillations
    curtime = calctime(curtime,th);  
end

%% Single Beam Check
% After optical evaporation, turn off one of the trap so you can see the
% position of the other ODT beam
if seqdata.flags.xdtB_one_beam
    dispLineStr('Turning off one of the dipole trap beams',curtime);
    tr = 10;    
    
    P1 = getChannelValue(seqdata,'dipoleTrap1',1);
    P2 = getChannelValue(seqdata,'dipoleTrap2',1);
    
    odt1_on = 0;
    odt2_on = 1;
    
    % To mitigate gravitational sag, turn one ODT off but then increase the
    % power in the other beam
    
    if odt2_on
        % Comment out which beam you want to stay on    
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,0);
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,2*P2);
        curtime = calctime(curtime,tr);
    end
    
    if odt1_on
        % Comment out which beam you want to stay on    
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,2*P1);
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr,0);
        curtime = calctime(curtime,tr);
    end

    
    curtime = calctime(curtime,20);
end


%% The End

timeout = curtime;
end

