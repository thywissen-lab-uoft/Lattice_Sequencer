function curtime = dipole_high_field_evap(timein)

global seqdata
curtime = timein;

    field_ramp_1 = 1;       % Initial ramp to high field
    expevap2 = 0 ;          % Optical Evaporation
    field_ramp_img = 0;     % High Field Imaging
    spin_flip_9_7 = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Ramp B Field to High Value %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Ramp magnetic field to high field value
    if field_ramp_1
        clear('ramp');                
        
        zShim = 0;
        
        % Fesh Ramp        
        XDT_Evap2_FeshValue_List =[195];
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
        ramp.fesh_ramptime = 100;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = XDT_Evap2_FeshValue;
        ramp.settling_time = 100;      

        % Also going to want to ramp shims (but do that later)  
        disp(' Ramping to high field');
        disp(['     Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
        disp(['     Settling Time (ms) : ' num2str(ramp.settling_time)]);
        disp(['     Fesh Value     (G) : ' num2str(ramp.fesh_final)]);
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   

        fieldReal = XDT_Evap2_FeshValue + 2.35*zShim + 0.1; 

        seqdata.params.HF_probe_fb = XDT_Evap2_FeshValue; 
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Spin Flip 97 %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Optical Evaporation %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if expevap2
        exp_evap2_time = 5000;
        tau2 = exp_evap2_time;
        P1_end = exp_end_pwr2;    
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Prepare for Imaging %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
end

