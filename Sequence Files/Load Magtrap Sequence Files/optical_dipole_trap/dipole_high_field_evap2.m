function curtime = dipole_high_field_evap2(timein)

global seqdata
curtime = timein;

%% Flags    

seqdata.flags.xdt_evap2_HF_repulsive    = 1;
seqdata.flags.xdt_evap2_HF_attractive   = 0;
seqdata.flags.ramp_back_LF              = 1;
do_75_transfer                          = 0;

% rampfieldreulsive = 0;
% rampfiledattractive = 1;

% if rampfieldattrave
%  crossres = 1;
% cross res =1
% end
% expevap = 1
% ramptolf = 0;

%% HF evap on repulsive side

if (seqdata.flags.xdt_evap2_HF_repulsive == 1 && seqdata.flags.xdt_evap2_HF_attractive == 0)% ramp fields up

    %%%%%%%% Set parameters for QP+FB field ramps %%%%%%
    ramp_time_all_list = [100];
    ramp_time_all = getScanParameter(ramp_time_all_list,seqdata.scancycle,...
    seqdata.randcyclelist,'HF_evap_ramptime','ms');
    % QP parameters
    qp_ramp_time = ramp_time_all;150;
    HF_QP_List = [0.09];0.15;0.117;.14;0.115;
    HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
    seqdata.randcyclelist,'HF_QPReverse','V');  

    % Feshbach ramp parameters
    BzShim = 0;

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
    ramptime = ramp_time_all;150;

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

    %%%%%%%% Set switches for reverse QP coils %%%%%%%%%

    % Ramp C16 and C15 to off values
    pre_ramp_time = 100;
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0);    
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

    %%%%%%%% RAMP QP+FB TO HF CONFIGURATION %%%%%%%
    
    disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
    disp([' FB Ramp Value  (G) : ' num2str(ramp.fesh_final)]);
    disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);
    disp([' QP Ramp Value  (V) :  ' num2str(HF_QP)]);

    % Ramp Coil 15, but don't update curtime
    AnalogFuncTo(calctime(curtime,0),'Coil 15',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 

    % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

    
    %%%%%%%%%%%%%%%% DO THE SECOND EVAP STAGE %%%%%%%%%%%%%%%%%%%%%
    

    pend = 0.06;0.06;
    evap_exp_ramp = @(t,tt,tau,y2,y1) ...
        (y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    

    evap_time_2_list =  [6000];
    evap_time_2 = getScanParameter(evap_time_2_list,seqdata.scancycle,...
        seqdata.randcyclelist,'evap_time_2','ms');

    % Exponetial time factor
    Tau_List = [3.5];%[5];
    exp_tau_frac = getScanParameter(Tau_List,seqdata.scancycle,...
        seqdata.randcyclelist,'Evap_Tau_frac2');
    
    defVar('Vary_HF_Tau_dummy',[25]*1e3,'ms');
    evap_time_total = getVar('Vary_HF_Tau_dummy');
%     evap_time_total = 25*1e3; %this should be changed
    
    exp_tau=evap_time_total/exp_tau_frac;

%     % Ramp down the optical powers
    AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_2,evap_time_2,exp_tau,pend);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
        @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
        evap_time_2,evap_time_2,exp_tau,pend);
    
   
    %% RF transfer 7 to 5 at high field
    
    if do_75_transfer
        
        % Get the Feshbach field
        Bfesh  = getChannelValue(seqdata,'FB Current',1);   
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
            seqdata.randcyclelist,'rf_freq_HF_evap','MHz');

        % Define the RF sweep parameters
        sweep_pars.power =  [0];
        delta_freq = 0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = [5];50;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length_HFevap','ms');  % also is sweep length  0.5               

        disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
        disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);

    % Do the RF Sweep
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
         
    end
    %% Wait time
    %Hold at high field for some additional time after evap and spin flips
    defVar('HF_evap_wait',[0],'ms');
    HF_evap_wait = getVar('HF_evap_wait');
    curtime = calctime(curtime,HF_evap_wait);
    
   %% Ramp back down to low field     
    if seqdata.flags.ramp_back_LF
        
        %%%%%%%%%% RAMP FIELDS TO LOW FIELD CONFIGURATION %%%%%%%%%%%
            
        qp_ramp_down_time = ramp_time_all;150;
        
        % Define the ramp structure
        ramp=struct;

        % Shim Ramp Parameters
        ramptime = ramp_time_all;150;

        ramp.shim_ramptime      = ramptime;
        ramp.shim_ramp_delay    = 0;
        ramp.xshim_final        = seqdata.params.shim_zero(1); 
        ramp.yshim_final        = seqdata.params.shim_zero(2);
        ramp.zshim_final        = seqdata.params.shim_zero(3);

        % FB coil 
        ramp.fesh_ramptime      = ramptime;
        ramp.fesh_ramp_delay    = 0;
        ramp.fesh_final         = 20;
        ramp.settling_time      = 100; 

        
        AnalogFuncTo(calctime(curtime,0),'Coil 15',...
                 @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time,qp_ramp_down_time,0,1);  
             
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
             @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                 5,5,0);        
             
        % Go back to "normal" configuration
        curtime = calctime(curtime,10);
        % Turn off reverse QP switch
        setDigitalChannel(curtime,'Reverse QP Switch',0);
        curtime = calctime(curtime,10);

        % Turn on 15/16 switch
        setDigitalChannel(curtime,'15/16 Switch',1);
        curtime = calctime(curtime,200);
        
    end
                 
end

%% HF evap on attractive side

if (seqdata.flags.xdt_evap2_HF_attractive == 1 && seqdata.flags.xdt_evap2_HF_repulsive == 0)

        %%%%%%%%%%%%%% RAMP FB+QP TO INITIAL 195G%%%%%%%%%%%%%%%%%
       %%%%%%%% Set parameters for FB field ramps %%%%%%

        %%%%%%%% Set parameters for QP+FB field ramps %%%%%%
        ramp_time_all_list = [100];
        ramp_time_all = getScanParameter(ramp_time_all_list,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_evap_ramptime','ms');
        % QP parameters
        qp_ramp_time = ramp_time_all;150;
        HF_QP_List = [0.09];0.15;0.117;.14;0.115;
        HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_QPReverse','V');  

        % Feshbach ramp parameters
        BzShim = 0;

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
        ramptime = ramp_time_all;150;

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

        %%%%%%%% Set switches for reverse QP coils %%%%%%%%%

        % Ramp C16 and C15 to off values
        pre_ramp_time = 100;
        AnalogFuncTo(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0);    
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

        %%%%%%%% RAMP QP+FB TO HF CONFIGURATION %%%%%%%

        disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
        disp([' FB Ramp Value  (G) : ' num2str(ramp.fesh_final)]);
        disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);
        disp([' QP Ramp Value  (V) :  ' num2str(HF_QP)]);

        % Ramp Coil 15, but don't update curtime
        AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 

        % Ramp FB with QP
curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%% CROSS THE RESONANCE%%%%%%%%%%%%%%%%%
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
            seqdata.scancycle,seqdata.randcyclelist,'xdt_hf__a_fesh_2','G');

        % Total Field Value
        Bend = fesh + 0.11 + BzShim;
        addOutputParam('xdt_hf_field_2',Bend,'G');      
        %%%%%%%%%%%%%%%%%% RAMP MAGNETIC FIELD %%%%%%%%%%%%%%%%%%%%%%%
        ramp=struct;

        % Shim Ramp Parameters

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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

        %%%%%%%%%%%%%%%%%%%% RAMP FB TO EVAP VALUES%%%%%%%%%%%%

        % Feshbach ramp parameters
        BzShim = 0;

        % Feshbach Coil Value
        fesh_list = [204];
        fesh = getScanParameter(fesh_list,...
            seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_evap_field','G');

        % Total Field Value
        Btot = fesh + 0.11 +BzShim; 
        addOutputParam('xdt_hf_a_field_3',Btot,'G');    

        % Define the ramp structure
        ramp=struct;

        % Shim Ramp Parameters
        ramptime = ramp_time_all;

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
        disp([' FB Ramp Value  (G) : ' num2str(ramp.fesh_final)]);
        disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);


curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

        %%%%%%%%%%%%%%%% DO THE SECOND EVAP STAGE %%%%%%%%%%%%%%%%%%%%%
%         pend = 0.06;0.06;
        
        defVar('XDT_HF_evap2_end_pwr',[0.06],'W');
        pend = getVar('XDT_HF_evap2_end_pwr');
        
        evap_exp_ramp = @(t,tt,tau,y2,y1) ...
            (y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));    

        evap_time_2_list =  [1000:1000:9000];
        evap_time_2 = getScanParameter(evap_time_2_list,seqdata.scancycle,...
            seqdata.randcyclelist,'evap_time_2','ms');

        % Exponetial time factor
        Tau_List = [3.5];%[5];
        exp_tau_frac = getScanParameter(Tau_List,seqdata.scancycle,...
            seqdata.randcyclelist,'Evap_Tau_frac2');
        
%         defVar('Vary_HF_Tau_dummy',[20 35 40]*1e3,'ms')
%         evap_time_total = getVar('Vary_HF_Tau_dummy');
% %         evap_time_total = 25*1e3; %this should be changed
%         
        
        exp_tau=6*evap_time_2/exp_tau_frac;

        % Ramp down the optical powers
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            evap_time_2,evap_time_2,exp_tau,pend);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            evap_time_2,evap_time_2,exp_tau,pend);



        if seqdata.flags.ramp_back_LF

               %%%%%%%%%%%%%ramp FB+QP back to 210G%%%%%%%
            ramp_time_all_list = [100];
            ramp_time_all = getScanParameter(ramp_time_all_list,seqdata.scancycle,...
            seqdata.randcyclelist,'HF_evap_a_ramptime','ms');

            % QP parameters
            qp_ramp_time = ramp_time_all;
            HF_QP_List = [0.1];
            HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
            seqdata.randcyclelist,'HF_QPReverse2_a','V'); 

            % Feshbach ramp parameters
            BzShim = 0;

            % Feshbach Coil Value
            fesh_list = [210];
            fesh = getScanParameter(fesh_list,...
                seqdata.scancycle,seqdata.randcyclelist,'xdt_hf_a_fesh_4','G');

            % Total Field Value
            Btot = fesh + 0.11 +BzShim; 
            addOutputParam('xdt_hf_a_field_4',Btot,'G');    

            % Define the ramp structure
            ramp=struct;

            % Shim Ramp Parameters
            ramptime = ramp_time_all;

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

            % Ramp up transport supply voltage
            QP_FFValue = 23*(HF_QP/.125/30); % voltage FF on delta supply
curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                100,100,QP_FFValue);
            curtime = calctime(curtime,50);

    % Ramp Coil 15, but don't update curtime
            AnalogFuncTo(calctime(curtime,0),'Coil 15',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 

curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


            %%%%%%%%%%%%%%% CROSS RESONANCE AGAIN%%%%%%%%%%%%%%%%%
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

            %%%%%%%%%%%%%RAMP BACK DOWN TO LOW FIELD 15 G%%%%%%%%%%%%%%%%%
            qp_ramp_down_time = ramp_time_all;

            % Define the ramp structure
            ramp=struct;

            % Shim Ramp Parameters
            ramptime = ramp_time_all;

            ramp.shim_ramptime      = ramptime;
            ramp.shim_ramp_delay    = 0;
            ramp.xshim_final        = seqdata.params.shim_zero(1); 
            ramp.yshim_final        = seqdata.params.shim_zero(2);
            ramp.zshim_final        = seqdata.params.shim_zero(3);

            % FB coil 
            ramp.fesh_ramptime      = ramptime;
            ramp.fesh_ramp_delay    = 0;
            ramp.fesh_final         = 20;
            ramp.settling_time      = 100; 


            AnalogFuncTo(calctime(curtime,0),'Coil 15',...
                     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_down_time,qp_ramp_down_time,0,1);  

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain 

curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
                 @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                     5,5,0);        

            % Go back to "normal" configuration
            curtime = calctime(curtime,10);
            % Turn off reverse QP switch
            setDigitalChannel(curtime,'Reverse QP Switch',0);
            curtime = calctime(curtime,10);

            % Turn on 15/16 switch
            setDigitalChannel(curtime,'15/16 Switch',1);
            curtime = calctime(curtime,200);  

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        end

end


