function curtime = dipole_high_field_a(timein)
global seqdata
curtime = timein;
        
% This code performs operations in the dipole trap at high magnetic field.
% It was written around 08-09 of 2021 as we began our investigations into
% high field manipulations of swave interactions.
% It has two primary purposes:
%   (1) General testing of high field manipulations (RF, Raman)
%   (2) Loading the optical lattice on the attractive side of the 97
%   resonsnace (202.1 G)
%
%
% %%%%%%%%LOADING THE LATTICE ON ATTRACTIVE SIDE%%%%%%%%%%%%
%
% To load the optical lattice on the attracive side of the 97 resonance, we
% ramp the Feshbach field to high field (~190 G) and then perform a RF
% sweep to create a 95 mixture.  This is done to avoid loses due to the 75
% resonance at 174 G.  After the 95 mixture is created, we ramp the field
% accross the resonance (around 207 G (why this particular value?)). One
% has to be careful at there is a feshbach resonance at 224 G which suffers
% from inelastic losses.
%
% To do this, the following flags are ("typcailly") used :
%
% ramp_field_1, spin_flip_7_5, ramp_field_2, spin_flip_7_5_again
% (1) Go to high field
% (2) transfer 7 to 5 to avoid feshbach
% (3) ramp to above feshbach
% (4) transfer 5 to 7 to make mixture


%%%%%%HIGH FIELD PA MEASUREMENTS IN THE XDT%%%%%%%%%
%
%%%ATTRACTIVE SIDE%%
%The different procedures for taking PA measurements on the attractive side in the XDT
%are as follows:
%   Procedure 1: Creating the mixture at high field.
%
%   (1) Starting with a spin-polarized gas, ramp the field to 209G
%   (ramp_field_1)
%   (2) Then create a spin mixture at 209G via multiple RF sweeps
%   (mix_at_high_field)
%   (3) Ramp to the desired science field where the PA pulse will occur
%   (ramp_field_3)
%   (4) Perform the PA pulse (doPA_pulse)
%   (5) Ramp the field to 207G for imaging (ramp_field_for_imaging)
%
%   Procedure 2: Creating the mixture at low field
%
%   (1) Starting with a spin-mixed gas of -9/2 and -7/2 atoms, ramp the
%   field to 190 G (ramp_field_1)
%   (2) Perform an RF sweep to transfer -7/2 atoms to -5/2 (spin_flip_7_5)
%   (3) Ramp the field to 207 G (ramp_field_2)
%   (4) Flip the -5/2 atoms back to -7/2 (spin_flip_7_5_again)
%   (5) Ramp to the desired science field where the PA pulse will occur
%   (ramp_field_3)
%   (6) Perform the PA pulse (doPA_pulse)
%   (7) Ramp the field to 207G for imaging (ramp_field_for_imaging)
%
%%%REPULSIVE SIDE%%   
% This is the procedure for performing PA measurements on the repulsive
% side of the resonance:
% 
%   (1) Starting with a spin-mixture of -9/2 and -7/2 atoms, ramp the field
%   to the desired value where the PA pulse will occur (ramp_field_1)
%   (2) Perform the PA pulse (doPA_pulse)
%   (3)Ramp the field to 195 G for imaging (ramp_field_for_imaging)


%% Flags          
time_in_HF_imaging = curtime;

seqdata.flags.xdt_hf_ramp_QP_gradient_cancel = 1;   % Ramp QP coils for levitation  
seqdata.flags.xdt_hf_ramp_field_1            = 0;   % Ramp to HF

seqdata.flags.xdt_hf_mix_7_9                 = 0;   % Mix 79 at HF
seqdata.flags.xdt_hf_79_spec                 = 0;   % 79 Spec

seqdata.flags.xdt_hf_CDT_evap_2_high_field  = 0;   % HF evaporation
seqdata.flags.xdt_hf_crossFBUp              = 1;   % Cross 97 Resonance (w 75 flips)

flip_7_5                                    = 0;   % 7 to 5 to avoid fesbach
ramp_field_2                                = 0;   % Ramp above feshbach (attractive)
flip_7_5_again                              = 0;   % 5 to 7 for science mixture

seqdata.flags.xdt_hf_ramp_field_3           = 0;    % Ramp field 
seqdata.flags.xdt_hf_79_spec2               = 0;    % 79 Spec
seqdata.flags.xdt_hf_PA                     = 0;    % PA pulse

% Ramp field to imaging field
seqdata.flags.xdt_hf_ramp_field_for_imaging_attractive  = 0;
seqdata.flags.xdt_hf_ramp_field_for_imaging_repulsive  = 0;
seqdata.flags.xdt_hf_ramp_QP_gradient_cancel_imaging = 0;

% Ramp Down across reosnance (and also to 20G)
seqdata.flags.xdt_hf_crossFBDown               = 1; 
%% QP Coil Gradient Cancel
% Ramp the QP gradient up to levitate

if seqdata.flags.xdt_hf_ramp_QP_gradient_cancel
    dispLineStr('XDT HF QP Gradient cancel',curtime);

    HF_QP_List =  [0.12];.14;0.115;
    HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'HF_QPReverse','V');  

    % Ramp C16 and C15 to off values
    pre_ramp_time = 100;
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 
    
    %Wait a bit
    curtime = calctime(curtime,50);
    
    % Turn off 15/16 switch
    setDigitalChannel(curtime,'15/16 Switch',0); 
    curtime = calctime(curtime,10);

    % Turn on reverse QP switch
    setDigitalChannel(curtime,'Reverse QP Switch',1);
    curtime = calctime(curtime,10);

    % Ramp up transport supply voltage
    QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
    curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        100,100,QP_FFValue);
    curtime = calctime(curtime,50);

    % Ramp up Coil 15
    qp_ramp_time = 200;
    curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 
end
    
%% Feshbach Field Ramp
% Ramp the feshbach field to the initial high value (and set the z-shim)
if seqdata.flags.xdt_hf_ramp_field_1
    dispLineStr('XDT HF Field Ramp 1',curtime);

    % Shim Field Value
    BzShim = 0;
    addOutputParam('xdt_hf_zshim_1',BzShim,'G')

    % Feshbach Coil Value
    fesh_list = 195;
    fesh = getScanParameter(fesh_list,...
        seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_fesh_1','G');
        
    % Total Field Value
    Btot = fesh + 0.11 +BzShim; 
    addOutputParam('xdt_hf_field_1',Btot,'G');    

    % Define the ramp structure
    ramp=struct;
    
    % Shim Ramp Parameters
    ramptime = 150;
    
    ramp.shim_ramptime      = ramptime;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3) + BzShim/2.35;
    
    % FB coil 
    ramp.fesh_ramptime      = ramptime;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = 100;    

    disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
    disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);


curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

    ScopeTriggerPulse(curtime,'FB_ramp');
    seqdata.params.HF_fb = fesh;  
end  


%% Create -9/2, -7/2 Spin Mixture at High Field

if seqdata.flags.xdt_hf_mix_7_9
    dispLineStr('XDT HF 97 Mix',curtime);
    
        %Do RF Sweep
    clear('sweep');

    zshim = [3]/2.35; %1.28V = 3G
    % Get the field to do the sweep at
    B = HF_FeshValue_Initial + 0.11 + +2.35*zshim; 

    % The shift shift list
    rf_list =  [4]*1e-3 +...
        (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
    %rf_list = 48.3758; %@209G  [6.3371]; 
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_freq_sweep_HF');  

    rf_k_gain_hf_list = [-9.2];

    % RF pulse parameters
    sweep_pars.power = getScanParameter(rf_k_gain_hf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_k_gain_hf');


    delta_freq_list = -0.01;[0.01];%0.006; 0.01
    sweep_pars.delta_freq = getScanParameter(delta_freq_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_range_hf');
    pulse_length_list = 1.25;[0.75];%0.4ms for mixing 2ms for 80% transfer remove further sweeps
    sweep_pars.pulse_length = getScanParameter(pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_k_sweep_time_hf');

    disp(['     Center Freq      (MHz) : ' num2str(sweep_pars.freq)]);
    disp(['     Delta Freq       (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp(['     Power              (V) : ' num2str(sweep_pars.power)]);
    disp(['     Sweep time        (ms) : ' num2str(sweep_pars.pulse_length)]);  


    f1=sweep_pars.freq-sweep_pars.delta_freq/2;
    f2=sweep_pars.freq+sweep_pars.delta_freq/2;

    n_sweeps_mix_hf_list=[11];
    n_sweeps_mix = getScanParameter(n_sweeps_mix_hf_list,...
        seqdata.scancycle,seqdata.randcyclelist,'n_sweeps_mix_hf');  % also is sweep length  0.5               

    T60=16.666; % 60 Hz period

    do_ACync_rf = 1;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-30);
        ACync_end_time = calctime(curtime,(sweep_pars.pulse_length+T60)*n_sweeps_mix+30);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
    % Perform any additional sweeps
    for kk=1:n_sweeps_mix
        disp([' Sweep Number ' num2str(kk) ]);
        rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
        curtime = calctime(curtime,T60);
    end     
curtime = calctime(curtime,50);

end
%% Flip 97
if seqdata.flags.xdt_hf_79_spec
    dispLineStr('RF transfer -9/2 to -7/2',curtime);
    
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
    delta_freq = 0.5; 0.025;0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = 50;5;20;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

    disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);

    % Do the RF Sweep
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

    % Wait a second
    HF5_wait_time_list = [50];
    HF5_wait_time = getScanParameter(HF5_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

% ACYnc usage
do_ACync_rf = 0;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-80);
        ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
end

%% Two Stage High Field Evaporation

% This evaporates at high field from the initial evaporation

if (seqdata.flags.xdt_hf_CDT_evap_2_high_field==1)
    dispLineStr('Optical evaporation at high field',curtime);   
    
    % Second Stage ending evaporation power
    Evap2_End_Power_List = [.1];        
    seqdata.params.exp_end_pwr2 = getScanParameter(Evap2_End_Power_List,...
        seqdata.scancycle,seqdata.randcyclelist,'Evap2_End_Power','W');
    
    % Duration of optical evaporation
    exp_evap2_time_list = [5000];
    exp_evap2_time = getScanParameter(exp_evap2_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Evap2_Time','ms');
    
    % Tau for the optical 
    tau2_list = [exp_evap2_time];
    tau2 = getScanParameter(tau2_list,...
        seqdata.scancycle,seqdata.randcyclelist,'Evap2_tau','ms');       

    P1_end = seqdata.params.exp_end_pwr2;
    P2_end = P1_end*seqdata.params.xdt_p2p1_ratio;    

    % Display evaporation parameters
    disp(' Performing exponential evaporation');
    disp(['     Evap Time (ms) : ' num2str(exp_evap2_time)]);
    disp(['     tau       (ms) : ' num2str(tau2)]);
    disp(['     XDT1 end   (W) : ' num2str(P1_end)]);
    disp(['     XDT2 end   (W) : ' num2str(P2_end)]);

    % Ramp function
    evap_exp_ramp = @(t,tt,tau,y2,y1) ...
        (y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));

    % Ramp the powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        exp_evap2_time,exp_evap2_time,tau2,P1_end);
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        exp_evap2_time,exp_evap2_time,tau2,P2_end);   
    
    % Advance time
    curtime= calctime(curtime,exp_evap2_time);

end
  
%% Ramp Across Resonance with 95 Transfer
% This code ramps the Feshbach field accross the feshbach resonance at
% 202.15 G. To avoid heating, RF pulses are applied at the beginning and
% end of the ramp to transfer -7/2 atoms into the -5/2. The time is
% minimized as we have found the 95 mixture to be lossy.

if seqdata.flags.xdt_hf_crossFBUp
    dispLineStr('XDT HF Resonance Transfer',curtime);
    
    %%%%%%%%%%%%%%%%%% INITIAL MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    Bstart = Bfesh + Bzshim + 0.11;    
    
    %%%%%%%%%%%%%%%%%% FINAL MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    % Shim Field Value
    BzShim = 0;
    addOutputParam('xdt_hf_zshim_2',BzShim,'G')

    % Feshbach Coil Value
    fesh_list = [210];
    fesh = getScanParameter(fesh_list,...
        seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_fesh_2','G');
        
    % Total Field Value
    Bend = fesh + 0.11 + BzShim;
    addOutputParam('xdt_hf_field_2',Bend,'G');      
    %%%%%%%%%%%%%%%%%% RAMP MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    ramp=struct;
    
    % Shim Ramp Parameters
    ramptime = 50;
    settlingtime = 50;    
    
    % Feshbach Coil Value
    ramptime_list = [50];
    ramptime = getScanParameter(ramptime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'resonance_cross_time','ms');
    
    ramp.shim_ramptime      = ramptime;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3) + BzShim/2.35;
    
    % FB coil 
    ramp.fesh_ramptime      = ramptime;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = settlingtime;    

    % Ramp the bias fields
    ramp_bias_fields(calctime(curtime,0), ramp);     
    
    % Display output
    disp([' Bstart         (G) : ' num2str(Bstart)]);
    disp([' Bend           (G) : ' num2str(Bend)]);
    disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
    disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);
    disp(' ');
    %%%%%%%%%%%%%%%%%% RF PULSES %%%%%%%%%%%%%%%%%%%%%%%
    % Magnetic fields at which to transfer
    B1 = 196;B2 = 209;    
    % Approximate times at which the chosen fields will be crossed
    t1 = (B1-Bstart)/(Bend-Bstart)*ramptime;
    t2 = (B2-Bstart)/(Bend-Bstart)*ramptime;    
    
    if B1<Bstart || B2>Bend
        warning(['You have chosen an B field outside of the ' ...
            'ramp range. No atoms will be transfered probably']);
    end
    
    % Spin States
    mF1=-7/2;mF2=-5/2;  

    % Get the RF frequencies in MHz
    f1 = abs((BreitRabiK(B1,9/2,mF2) - BreitRabiK(B1,9/2,mF1))/6.6260755e-34/1E6);       
    f2 = abs((BreitRabiK(B2,9/2,mF2) - BreitRabiK(B2,9/2,mF1))/6.6260755e-34/1E6);   
            
    disp([' B1,B2     (G) : ' num2str(B1) ',' num2str(B2)]);
    disp([' t1,t2    (ms) : ' num2str(t1) ',' num2str(t2)]);
    disp([' f1,f2   (MHz) : ' num2str(f1) ',' num2str(f2)]);   

    % Define each RF pulse    
    pulse1                  = struct;
    pulse1.pulse_length     = ramptime/4;10;
    pulse1.power            = 0;            
    pulse1.freq             = f1;
    f1_delay = -1; % delay by -1ms from desired pulse delay bc rf_uwave_spectroscopy is dumb
    
    pulse2                  = struct;
    pulse2.pulse_length     = ramptime/4;10;
    pulse2.power            = 0;            
    pulse2.freq             = f2;
%     f2_delay = 38;
    f2_delay = ramptime - ramptime/4 -1;     % delay by -1ms from desired pulse delay bc rf_uwave_spectroscopy is dumb

    % Apply each pulse
    rf_uwave_spectroscopy(calctime(curtime,f1_delay),4,pulse1);
    rf_uwave_spectroscopy(calctime(curtime,f2_delay),4,pulse2);
    
    curtime = calctime(curtime,ramptime+settlingtime);  
end
 

%%  RF transfer from -7/2 to -5/2
        
if flip_7_5
    dispLineStr('RF transfer -7/2 to -5/2',curtime);
    
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;
    
    % Calculate RF Frequency for desired transitions
    mF1=-7/2;mF2=-5/2;   
    rf_list =  [0] +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_freq_HF','MHz');

    % Define the RF sweep parameters
    sweep_pars.power =  [0];
    delta_freq = 0.5; 0.025;0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = [5];50;5;20;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length','ms');  % also is sweep length  0.5               

    disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);

    % Do the RF Sweep
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

    % Wait a second
    HF5_wait_time_list = [0];
    HF5_wait_time = getScanParameter(HF5_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

% ACYnc usage
do_ACync_rf = 0;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-80);
        ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end
end
    
%% Field Ramp 2
if ramp_field_2
    dispLineStr('XDT HF Field Ramp 2',curtime);

    % Shim Field Value
    BzShim = 0;
    addOutputParam('xdt_hf_zshim_2',BzShim,'G')

    % Feshbach Coil Value
    fesh_list = [209];
    fesh = getScanParameter(fesh_list,...
        seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_fesh_2','G');
        
    % Total Field Value
    Btot = fesh + 0.11 + BzShim;
    addOutputParam('xdt_hf_field_2',Btot,'G');    

    % Define the ramp structure
    ramp=struct;
    
    % Shim Ramp Parameters
    ramptime = 100;
    
    ramp.shim_ramptime      = ramptime;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3) + BzShim/2.35;
    
    % FB coil 
    ramp.fesh_ramptime      = ramptime;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = 50;    

    disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
    disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);


curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

    ScopeTriggerPulse(curtime,'FB_ramp');

    seqdata.params.HF_fb = fesh;  
end  
 
%% RF 75 Flip again
if flip_7_5_again
    dispLineStr('RF transfer -7/2 to -5/2',curtime);

    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    B = Bfesh + Bzshim + 0.11;

    addOutputParam('ODT_RF_flip_2_BField',B,'G')

    mF1=-7/2;   % Lower energy spin state
    mF2=-5/2;   % Higher energy spin state

    rf_list =  [0] +...
        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
    sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_freq_HF','MHz');
    clear('sweep');

    sweep_pars.power =  [0];
    delta_freq = 0.5; 0.025;0.1;
    sweep_pars.delta_freq = delta_freq;
    rf_pulse_length_list = 5;50;5;20;
    sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
        seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

    disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
    disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
    disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
    disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);



    curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    doItAgain = 1;
    if doItAgain
        curtime = calctime(curtime,10);
        curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    end

    do_ACync_rf = 0;
    if do_ACync_rf
        ACync_start_time = calctime(curtime,-80);
        ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
    end


     curtime = calctime(curtime,0);        
end


%% Ramp Field 3
if seqdata.flags.xdt_hf_ramp_field_3

    clear('ramp');
    HF_FeshValue_List = 207;[200]; %+3G from zshim
    HF_FeshValue = getScanParameter(HF_FeshValue_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_ODT_3','G');           

%         HF_FeshValue = paramGet('PA_FB_field'); %+3G from zshim

    HF_FeshValue_Initial = HF_FeshValue; %For use below in spectroscopy
    seqdata.params.HF_probe_fb = HF_FeshValue; %For imaging

    zshim_list = [0]/2.35;
    zshim = getScanParameter(zshim_list,...
seqdata.scancycle,seqdata.randcyclelist,'HF_shimvalue_ODT_3','V');

    ramptime2 = 50;
      % Define the ramp structure
    ramp=struct;
    ramp.shim_ramptime = ramptime2;
    ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
    ramp.xshim_final = seqdata.params.shim_zero(1); 
    ramp.yshim_final = seqdata.params.shim_zero(2);
    ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
    % FB coil 
    ramp.fesh_ramptime = ramptime2;
    ramp.fesh_ramp_delay = 0;
    ramp.fesh_final = HF_FeshValue;
    ramp.settling_time = 50;    

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

% Hold time at the end
 HF_wait_time_list = [0];
 HF_wait_time = getScanParameter(HF_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time','ms');

addOutputParam('PA_field_close',HF_FeshValue + 2.35*zshim + 0.11,'G');

curtime = calctime(curtime,HF_wait_time);

    xdt_ramp_down = 0;
    if xdt_ramp_down 
        dispLineStr('Ramping XDT Power Back Down',curtime);    

        dip_1 = .06; %1.5
        dip_2 = .06; %1.5
        dip_ramptime = 500; %1000
        dip_rampstart = 0;
        dip_waittime = 10;

        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),...
            'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2);
    curtime = calctime(curtime,dip_rampstart+dip_ramptime+dip_waittime);
    end



end
    

     
    
%% RF Sweep Spectroscopy
    
if seqdata.flags.xdt_hf_79_spec2
    dispLineStr('RF Sweep Spectroscopy',curtime);
    ScopeTriggerPulse(curtime,'rf_spectroscopy');

    mF1=-9/2;   % Lower energy spin state
    mF2=-7/2;   % Higher energy spin state

    % Get the center frequency
    Boff = 0.11;
    B = HF_FeshValue_Initial + Boff + 2.35*zshim; 
%         

     rf_shift_list = [-30 -12.5:2.5:12.5 30];

     rf_shift = getScanParameter(rf_shift_list,seqdata.scancycle,...
                     seqdata.randcyclelist,'rf_freq_HF_shift_XDT','kHz');


    f0 = abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);
    rf_freq_HF = f0+rf_shift*1e-3;
    addOutputParam('rf_freq_HF_XDT',rf_freq_HF,'MHz');       

    if (rf_freq_HF < 1)
         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
    end

    % Define the sweep parameters
    delta_freq_SRS= 0.005; % in MHz            
    addOutputParam('rf_delta_freq_HF_SRS',delta_freq_SRS,'MHz');

    % RF Pulse 
    rf_pulse_length_list = 1; 2; %ms
    rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_pulse_length');

    rf_wait_time = 0.00; 
    extra_wait_time = 0;
    rf_off_voltage =-10;


    disp('HS1 SRS Sweep Pulse');  

    rf_srs_power_list = [12];
    rf_srs_power = getScanParameter(rf_srs_power_list,seqdata.scancycle,...
        seqdata.randcyclelist,'rf_srs_power','dBm');
%                 rf_srs_power = paramGet('rf_srs_power');
    sweep_time = rf_pulse_length;

    rf_srs_opts = struct;
    rf_srs_opts.Address = 28;          
    rf_srs_opts.EnableBNC = 1;                         % Enable SRS output 
    rf_srs_opts.PowerBNC = rf_srs_power;                           
    rf_srs_opts.Frequency = rf_freq_HF;
    % Calculate the beta parameter
    beta=asech(0.005);   
    addOutputParam('rf_HS1_beta',beta);

    disp(['     Freq Center  : ' num2str(rf_freq_HF) ' MHz']);
    disp(['     Freq Delta   : ' num2str(delta_freq_SRS*1E3) ' kHz']);
    disp(['     Pulse Time   : ' num2str(rf_pulse_length) ' ms']);
    disp(['     Beta         : ' num2str(beta)]);

    % Enable uwave frequency sweep
    rf_srs_opts.EnableSweep=1;                    
    rf_srs_opts.SweepRange=abs(delta_freq_SRS);     

    % Set SRS Source post spec
    setDigitalChannel(calctime(curtime,-5),'SRS Source post spec',0);

    % Set SRS Source to the new one
    setDigitalChannel(calctime(curtime,-5),'SRS Source',0);

    % Set SRS Direction to RF
    setDigitalChannel(calctime(curtime,-5),'K uWave Source',0);

    % Set initial modulation
    setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',1);

    rf_rabi_manual = 0;

    if rf_rabi_manual
        setDigitalChannel(calctime(curtime,...
             rf_wait_time + extra_wait_time),'RF Source',1); 
        setAnalogChannel(calctime(curtime,...
             rf_wait_time + extra_wait_time),'RF Gain',rf_off_voltage);
    else    
     % Set RF power to low
    setAnalogChannel(calctime(curtime,-5),'RF Gain',rf_off_voltage);

     % Set RF Source to SRS
    setDigitalChannel(calctime(curtime,-5),'RF Source',1);

    end

    % Turn on the RF
    setDigitalChannel(calctime(curtime,...
        rf_wait_time + extra_wait_time),'RF TTL',1);    

    % Ramp the SRS modulation using a TANH
    % At +-1V input for +- full deviation
    % The last argument means which votlage fucntion to use
    AnalogFunc(calctime(curtime,...
        rf_wait_time + extra_wait_time),'uWave FM/AM',...
        @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
        sweep_time,sweep_time,beta,1);

    % Sweep the linear VVA
    AnalogFunc(calctime(curtime,...
        rf_wait_time  + extra_wait_time),'RF Gain',...
        @(t,T,beta) -10 + ...
        20*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
        sweep_time,sweep_time,beta);

    % Wait for Sweep
                curtime = calctime(curtime,rf_pulse_length);

    % Turn off VVA
    setAnalogChannel(calctime(curtime,...
        rf_wait_time  + extra_wait_time+rf_pulse_length),'RF Gain',rf_off_voltage);


    % Program the SRS
    programSRS_BNC(rf_srs_opts); 
    params.isProgrammedSRS = 1;

     % Extra Wait Time

    HF_hold_time_list = [35]+rf_pulse_length;
    HF_hold_time = getScanParameter(HF_hold_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_hold_time','ms');
% %                 
%                 HF_hold_time =  rf_pulse_length+ paramGet('HF_hold_time');

    curtime=calctime(curtime,HF_hold_time); 

    if HF_hold_time > 1
    % Turn off the uWave
    setDigitalChannel(calctime(curtime,...
        rf_wait_time  + extra_wait_time+rf_pulse_length-HF_hold_time),'RF TTL',0); 
    end

end
 
    
  %% PA Pulse
if seqdata.flags.xdt_hf_PA
   curtime = PA_pulse(curtime); 
end

 %% Ramp field for imaging on attractive side
   if seqdata.flags.xdt_hf_ramp_field_for_imaging_attractive
       
    zshim = [0]/2.35;

    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [207]; [204]; % 206 207 208 209 210 211
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Imaging_ODT','G');
 
 % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3) + zshim;
        % FB coil 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final +2.35*zshim;
   end
   

   %% Ramp field for imaging on repulsive side
   if seqdata.flags.xdt_hf_ramp_field_for_imaging_repulsive
       
    zshim = [0]/2.35;

    % Fesahbach Field ramp
    HF_FeshValue_Final_List = [195]; 
    HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Imaging_ODT','G');
 
 % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3) + zshim;
        % FB coil 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final +2.35*zshim;
        
      
   end
   %% Ramp up the QP gradient for imaging
   if seqdata.flags.xdt_hf_ramp_QP_gradient_cancel_imaging
        % QP Value to ramp to
        HF_QP_List =[0.117];0.115;
        HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_QPReverse_imaging','V');  
    
%         % Ramp C16 and C15 to off values
%         pre_ramp_time = 100;
%         AnalogFuncTo(calctime(curtime,0),'Coil 16',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
%         curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
%             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 
%               
%         curtime = calctime(curtime,50);
%         % Turn off 15/16 switch
%         setDigitalChannel(curtime,'15/16 Switch',0); 
%         curtime = calctime(curtime,10);
% 
%         % Turn on reverse QP switch
%         setDigitalChannel(curtime,'Reverse QP Switch',1);
%         curtime = calctime(curtime,10);
%             
        % Ramp up transport supply voltage
        QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
        curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
            100,100,QP_FFValue);
        curtime = calctime(curtime,50);
        
        qp_ramp_time = 200;
        curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 
   end
   
    
   
  %% Back back acrros resonsnace
if seqdata.flags.xdt_hf_crossFBDown
    dispLineStr('XDT HF Resonance Transfer Down',curtime);

    %%%%%%%%%%%%%%%%%% INITIAL MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    % Get the Feshbach field
    Bfesh   = getChannelValue(seqdata,'FB Current',1);   
    % Get the shim field
    Bzshim = (getChannelValue(seqdata,'Z Shim',1) - ...
        seqdata.params.shim_zero(3))*2.35;
    % Caclulate the total field
    Bstart = Bfesh + Bzshim + 0.11;    

    %%%%%%%%%%%%%%%%%% FINAL MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    % Shim Field Value
    BzShim = 0;
    addOutputParam('xdt_hf_zshim_2',BzShim,'G')

    % Feshbach Coil Value
    fesh_list = [195];
    fesh = getScanParameter(fesh_list,...
        seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_fesh_2','G');

    % Total Field Value
    Bend = fesh + 0.11 + BzShim;
    addOutputParam('xdt_hf_field_2',Bend,'G');      
    %%%%%%%%%%%%%%%%%% RAMP MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
    ramp=struct;

    % Shim Ramp Parameters
    ramptime = 50;
    settlingtime = 20;    

    % Feshbach Coil Value
    ramptime_list = [50];
    ramptime = getScanParameter(ramptime_list,...
        seqdata.scancycle,seqdata.randcyclelist,'resonance_cross_time_down','ms');

    ramp.shim_ramptime      = ramptime;
    ramp.shim_ramp_delay    = 0;
    ramp.xshim_final        = seqdata.params.shim_zero(1); 
    ramp.yshim_final        = seqdata.params.shim_zero(2);
    ramp.zshim_final        = seqdata.params.shim_zero(3) + BzShim/2.35;

    % FB coil 
    ramp.fesh_ramptime      = ramptime;
    ramp.fesh_ramp_delay    = 0;
    ramp.fesh_final         = fesh; %22.6
    ramp.settling_time      = settlingtime;    

    % Ramp the bias fields
    ramp_bias_fields(calctime(curtime,0), ramp);     

    % Display output
    disp([' Bstart         (G) : ' num2str(Bstart)]);
    disp([' Bend           (G) : ' num2str(Bend)]);
    disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
    disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);
    disp(' ');
    %%%%%%%%%%%%%%%%%% RF PULSES %%%%%%%%%%%%%%%%%%%%%%%
    % Magnetic fields at which to transfer
    B1 = 209; B2 = 196;    
    % Approximate times at which the chosen fields will be crossed
    t1 = (B1-Bstart)/(Bend-Bstart)*ramptime;
    t2 = (B2-Bstart)/(Bend-Bstart)*ramptime;    

    if B1>Bstart || B2<Bend
        warning(['You have chosen an B field outside of the ' ...
            'ramp range. No atoms will be transfered probably']);
    end

    % Spin States
    mF1=-7/2;mF2=-5/2;  

    % Get the RF frequencies in MHz
    f1 = abs((BreitRabiK(B1,9/2,mF2) - BreitRabiK(B1,9/2,mF1))/6.6260755e-34/1E6);       
    f2 = abs((BreitRabiK(B2,9/2,mF2) - BreitRabiK(B2,9/2,mF1))/6.6260755e-34/1E6);   

    disp([' B1,B2     (G) : ' num2str(B1) ',' num2str(B2)]);
    disp([' t1,t2    (ms) : ' num2str(t1) ',' num2str(t2)]);
    disp([' f1,f2   (MHz) : ' num2str(f1) ',' num2str(f2)]);   
 
    
    % Define each RF pulse    
    pulse1                  = struct;
    pulse1.pulse_length     = ramptime/4;10;
    pulse1.power            = 0;            
    pulse1.freq             = f1;
    f1_delay = -1; % delay by -1ms from desired pulse delay bc rf_uwave_spectroscopy is dumb
    
    pulse2                  = struct;
    pulse2.pulse_length     = ramptime/4;10;
    pulse2.power            = 0;            
    pulse2.freq             = f2;
    f2_delay = ramptime - ramptime/4 -1;     % delay by -1ms from desired pulse delay bc rf_uwave_spectroscopy is dumb


    % Apply each pulse
    rf_uwave_spectroscopy(calctime(curtime,f1_delay),4,pulse1);
    rf_uwave_spectroscopy(calctime(curtime,f2_delay),4,pulse2);

    curtime = calctime(curtime,ramptime+settlingtime);      
    
    rampToLowField=1;
    if rampToLowField
        fesh_list = 20;
        fesh = getScanParameter(fesh_list,...
            seqdata.scancycle,seqdata.randcyclelist,'fesh_low','G');           

        zshim_list = [0]/2.35;
        zshim = getScanParameter(zshim_list,...
            seqdata.scancycle,seqdata.randcyclelist,'zshim_low','V');
        
        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
        % FB coil 
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = fesh;
        ramp.settling_time = 50;            
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

    end

    xdt_ramp_down = 1;
    if xdt_ramp_down 
        dispLineStr('Ramping XDT Power Back Down',curtime);    

        dip_1 = .06;
        dip_2 = .06;
        dip_ramptime = 500; 
        dip_rampstart = 0;
        dip_waittime = 10;

        AnalogFuncTo(calctime(curtime,dip_rampstart),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_1);
        AnalogFuncTo(calctime(curtime,dip_rampstart),...
            'dipoleTrap2',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), dip_ramptime,dip_ramptime,dip_2);
curtime = calctime(curtime,dip_rampstart+dip_ramptime+dip_waittime);
    end
end
  
   
 %% Ending operation

 HF5_wait_time_list = [35];
 HF5_wait_time = getScanParameter(HF5_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>10000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
end