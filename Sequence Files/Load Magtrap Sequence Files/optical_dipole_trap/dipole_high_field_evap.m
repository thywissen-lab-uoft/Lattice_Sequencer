function curtime = dipole_high_field_evap(timein)

global seqdata
curtime = timein;

    ramp_QP_gradient_cancel = 1; % Ramp up the QP Coils for gradient cancel
    
    field_ramp_1            = 1;       % Initial ramp to high field
    
    mix_7_9                 = 0; % If spin pure make mixture at high field
    spin_flip_9_7           = 0;
    
    expevap2                = 0 ;          % Optical Evaporation
    
    % Ramp field to imaging field
    ramp_field_for_imaging_attractive  = 0;
    field_ramp_img                     = 0;     % High Field Imaging
    ramp_field_for_imaging_repulsive   = 1;
    


%% QP Coil Gradient Cancel
    
       if ramp_QP_gradient_cancel
        % QP Value to ramp to
        HF_QP_List =[0.117];0.115;
        HF_QP = getScanParameter(HF_QP_List,seqdata.scancycle,...
        seqdata.randcyclelist,'HF_QPReverse','V');  
    
        % Ramp C16 and C15 to off values
        pre_ramp_time = 100;
        AnalogFuncTo(calctime(curtime,0),'Coil 16',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,-7);    
        curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),pre_ramp_time,pre_ramp_time,0.062,1); 
              
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
        
        qp_ramp_time = 200;
        curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
            @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,HF_QP,1); 
       end
    

%% Ramp B Field to High Value %%%%%%%%%%%%%%%%%%%%%%%%%%
  
    % Ramp magnetic field to high field value
    if field_ramp_1
        clear('ramp');                
        
        zShim = [0]/2.35;
        
        % Fesh Ramp        
        XDT_Evap2_FeshValue_List = [207];
        XDT_Evap2_FeshValue = getScanParameter(XDT_Evap2_FeshValue_List,...
            seqdata.scancycle,seqdata.randcyclelist,'XDT_Evap2_FeshValue');

        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3) + zShim;
        % FB coil 
        ramp.fesh_ramptime = 150;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = XDT_Evap2_FeshValue;
        ramp.settling_time = 100;      

        % Also going to want to ramp shims (but do that later)  
        disp(' Ramping to high field');
        disp(['     Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
        disp(['     Settling Time (ms) : ' num2str(ramp.settling_time)]);
        disp(['     Fesh Value     (G) : ' num2str(ramp.fesh_final)]);
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        fieldReal = XDT_Evap2_FeshValue + 2.35*zShim + 0.11; 

        seqdata.params.HF_probe_fb = XDT_Evap2_FeshValue; 
    end
    
    
%% Create -9/2, -7/2 Spin Mixture at High Field

    if mix_7_9
            %Do RF Sweep
        clear('sweep');

        zshim = [3]/2.35; %1.28V = 3G
        % Get the field to do the sweep at
        B = XDT_Evap2_FeshValue + 0.11 + +2.35*zshim; 
        
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

%% Spin Flip 97 %%%%%%%%%%%%%%%%%%%%%%%%%%


    if spin_flip_9_7
        B = fieldReal; 
        rf_pulse_length_list = 100;
        delta_freq = 10;        
        
        rf_list =  [0] +...
            (BreitRabiK(B,9/2,-7/2) - BreitRabiK(B,9/2,-9/2))/6.6260755e-34/1E6;
        
        clear('sweep_pars');
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'xdt_hf_rf_freq');
        sweep_pars.delta_freq = delta_freq;
        sweep_pars.power =  0; %in dBm
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,...
            seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  
        
        disp(' DDS Spin Flip');
        disp(['     Frequency    (MHz) : ' num2str(sweep_pars.freq)]);
        disp(['     Delta Freq   (kHz) : ' num2str(sweep_pars.delta_freq)]);
        disp(['     Pulse Time    (ms) : ' num2str(sweep_pars.pulse_length)]);
        disp(['     Power          (V) : ' num2str(sweep_pars.power)]);      

        curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
    end


%% Optical Evaporation %%%%%%%%%%%%%%%%%%%%%%%%%%

    
    if expevap2
        exp_evap2_time = 5000;
        tau2 = exp_evap2_time;
%         P1_end = exp_end_pwr2;    
        P1_end = seqdata.params.exp_end_pwr2;
        P2_end = P1_end*seqdata.params.XDT_area_ratio;    

        % Display evaporation parameters
        disp(' Performing exponential evaporation');
        disp(['     Evap Time (ms) : ' num2str(exp_evap2_time)]);
        disp(['     tau       (ms) : ' num2str(tau2)]);
        disp(['     XDT1 end   (W) : ' num2str(P1_end)]);
        disp(['     XDT2 end   (W) : ' num2str(P2_end)]);

        % Ramp function
        evap_exp_ramp = @(t,tt,tau,y2,y1)(y1+(y2-y1)/(exp(-tt/tau)-1)*(exp(-t/tau)-1));

        % Ramp the powers
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap2_time,exp_evap2_time,tau2,P1_end);
curtime = AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,tau,y2)(evap_exp_ramp(t,tt,tau,y2,y1)),...
            exp_evap2_time,exp_evap2_time,tau2,P2_end);   
    end
    

%% Prepare for Imaging %%%%%%%%%%%%%%%%%%%%%%%%%%

    % We perform imaging a "standard" field of 195 G. Ramp the field to
    % this value to perform time of flight and imaging
    % Feshbach Field Ramp (imaging)
    if field_ramp_img

        % Feshbach Field ramp Field ramp
        HF_FeshValue_Final_List = 206;
        HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_Lattice','G');

        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 100;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3);
        % FB coil 
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Final;
        ramp.settling_time = 50;    
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        seqdata.params.HF_probe_fb = HF_FeshValue_Final;
    end  
    
 %% Ramp field for imaging on attractive side
   if ramp_field_for_imaging_attractive
       
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
   if ramp_field_for_imaging_repulsive
       
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
end

