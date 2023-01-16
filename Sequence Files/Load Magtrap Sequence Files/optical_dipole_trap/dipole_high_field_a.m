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
% 


%% Flags          
    time_in_HF_imaging = curtime;
    
    % Ramp up the QP Coils for gradient cancel
    ramp_QP_gradient_cancel = 1;
    
    % Initial Ramp to high magnetic field
    ramp_field_1            = 1;       
    
    % If spin pure make mixture at high field
    mix_7_9                 = 0;  
    
    % Spin Manipulations for attractive with initial mixture
    flip_7_5                = 0;        % 7 to 5 to avoid fesbach
    ramp_field_2            = 0;        % Ramp above feshbach (attractive)
    flip_7_5_again          = 0;        % 5 to 7 for science mixture
        
    % Ramp to science magnetic field
    ramp_field_3            = 0;    
    
    % Perform a PA pulse in the XDT at high field
    doPA_pulse_in_XDT       = 0;

    % Ramp field to imaging field
    ramp_field_for_imaging_attractive  = 0;
    ramp_field_for_imaging_repulsive  = 1;

    %% QP Coil Gradient Cancel
    
       if ramp_QP_gradient_cancel
        % QP Value to ramp to
        HF_QP_List =0.2;
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

        % Make Sure Coil 16 is off
        setDigitalChannel(curtime,'Coil 16 TTL',0)
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
    
%% Feshbach Field Ramp
% Ramp the feshbach field to the initial high value (and set the z-shim)
    if ramp_field_1
        
        zshim = [0]/2.35; %1.28V = 3G
        
        dispLineStr('Ramping High Field in XDT',curtime);
        HF_FeshValue_Initial_List = 190;[206];
        HF_FeshValue_Initial = getScanParameter(HF_FeshValue_Initial_List,...
            seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Initial_ODT','G');

    %   Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime = 150;
        ramp.shim_ramp_delay = 0; % ramp earlier than FB field if needed
        ramp.xshim_final = seqdata.params.shim_zero(1); 
        ramp.yshim_final = seqdata.params.shim_zero(2);
        ramp.zshim_final = seqdata.params.shim_zero(3)+zshim;
        % FB coil 
        ramp.fesh_ramptime = 150;
        ramp.fesh_ramp_delay = 0;
        ramp.fesh_final = HF_FeshValue_Initial; %22.6
        ramp.settling_time = 100;    
        
        disp([' Ramp Time     (ms) : ' num2str(ramp.fesh_ramptime)]);
        disp([' Ramp Value     (G) : ' num2str(ramp.fesh_final)]);
        disp([' Settling Time (ms) : ' num2str(ramp.settling_time)]);

        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
        ScopeTriggerPulse(curtime,'FB_ramp');

        seqdata.params.HF_fb = HF_FeshValue_Initial;    
    end  
    

%% Create -9/2, -7/2 Spin Mixture at High Field

    if mix_7_9
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
    

%%  RF transfer from -7/2 to -5/2
        
    if flip_7_5
        dispLineStr('RF transfer -7/2 to -5/2',curtime);

        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state
        
        zshim = [0]/2.35; %1.28V = 3G
        
        % Get the center frequency
        B = HF_FeshValue_Initial + 0.11 + 2.35*zshim; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');
    
        % Sweep parameters
        sweep_pars.power =  [0];
        delta_freq = 0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 50;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

        disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
        disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);

        
        
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

        % Wait a second
        HF5_wait_time_list = [50];
        HF5_wait_time = getScanParameter(HF5_wait_time_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
     curtime = calctime(curtime,HF5_wait_time);
%          sweep_pars.delta_freq  = -delta_freq; 0.025;0.1;
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

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
seqdata.params.HF_probe_fb = HF_FeshValue_Initial;  

   if ramp_field_2
        dispLineStr('Secondary Field Ramp',curtime);
        % Fesahbach Field ramp
        HF_FeshValue_Final_List = [207];% 206 207 208 209 210 211
        HF_FeshValue_Final = getScanParameter(HF_FeshValue_Final_List,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_FeshValue_Final_ODT','G');

        % Define the ramp structure
        ramp=struct;
        ramp.FeshRampTime = 100;10;100;
        ramp.FeshRampDelay = -0;
        ramp.FeshValue = HF_FeshValue_Final;
        ramp.SettlingTime = 50; 50;    


        disp([' Ramp Time     (ms) : ' num2str(ramp.FeshRampTime)]);
        disp([' Ramp Value     (G) : ' num2str(ramp.FeshValue)]);
        disp([' Settling Time (ms) : ' num2str(ramp.SettlingTime)]);

    % Ramp the magnetic Fields
curtime = rampMagneticFields(calctime(curtime,0), ramp);
    
        seqdata.params.HF_probe_fb = HF_FeshValue_Final;
        HF_FeshValue_Initial = HF_FeshValue_Final;
    end
%  curtime = calctime(curtime,100);


 
 %% RF 75 Flip again
  if flip_7_5_again
        dispLineStr('RF transfer -7/2 to -5/2',curtime);

      
        clear('sweep');
        mF1=-7/2;   % Lower energy spin state
        mF2=-5/2;   % Higher energy spin state

        zshim = [0]/2.35; %1.28V = 3G
        
        % Get the center frequency
        B = HF_FeshValue_Initial +0.11 +2.35*zshim; 
        rf_list =  [0] +...
            abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
        sweep_pars.freq = getScanParameter(rf_list,seqdata.scancycle,...
            seqdata.randcyclelist,'rf_freq_HF','MHz');

        sweep_pars.power =  [0];
        delta_freq = 0.5; 0.025;0.1;
        sweep_pars.delta_freq = delta_freq;
        rf_pulse_length_list = 50;5;20;
        sweep_pars.pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,seqdata.randcyclelist,'rf_pulse_length');  % also is sweep length  0.5               

        disp([' Sweep Time    (ms)  : ' num2str(sweep_pars.pulse_length)]);
        disp([' RF Freq       (MHz) : ' num2str(sweep_pars.freq)]);
        disp([' Delta Freq    (MHz) : ' num2str(sweep_pars.delta_freq)]);
        disp([' RF Power        (V) : ' num2str(sweep_pars.power)]);

        
        
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse

%double pulse sequence
% curtime = calctime(curtime,35);
% curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);%3: sweeps, 4: pulse
curtime = calctime(curtime,50);

    do_ACync_rf = 0;
        if do_ACync_rf
            ACync_start_time = calctime(curtime,-80);
            ACync_end_time = calctime(curtime,2*sweep_pars.pulse_length+50);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end
  end
  
%% Ramp Field 3
    if ramp_field_3

        clear('ramp');
        HF_FeshValue_List =[200]; %+3G from zshim
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
  
     end

  %% PA Pulse
if doPA_pulse_in_XDT
   curtime = PA_pulse(curtime); 
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
   
 %% Ending operation

 HF5_wait_time_list = [35];
 HF5_wait_time = getScanParameter(HF5_wait_time_list,...
    seqdata.scancycle,seqdata.randcyclelist,'HF_wait_time_5','ms');
 curtime = calctime(curtime,HF5_wait_time);

        time_out_HF_imaging = curtime;
        if (((time_out_HF_imaging - time_in_HF_imaging)*(seqdata.deltat/seqdata.timeunit))>3000)
            error('CHECK TIME FESHBACH IS ON! MAY BE TOO LONG')
        end
end