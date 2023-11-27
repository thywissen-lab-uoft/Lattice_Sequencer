function [curtime] = plane_selection(timein,override)

 
 if nargin == 0
     timein = 10;
 end
 

opts = struct;

 

global seqdata
 curtime = timein;
%% Flags

% Establish field gradeint with QP, FB, and shim fields for plane selection
opts.ramp_fields = 1; 


opts.dotilt     = 1; %tilt for stripe pattern


% Do you want to fake the plane selection sweep?
%0=No, 1=Yes, no plane selection but remove all atoms.
opts.fake_the_plane_selection_sweep = 0; 

% Pulse the vertical D2 kill beam to kill untransfered F=9/2
opts.planeselect_doVertKill = 1;

% Transfer back to -9/2 via uwave transfer
opts.planeselect_doMicrowaveBack = 0;   

% Pulse repump to remove leftover F=7/2
opts.planeselect_doFinalRepumpPulse = 0;

%Repeat plane selection
opts.planeselect_again = 0;

% Choose the Selection Mode
opts.SelectMode = 'SweepFreqHS1';          % Sweep SRS HS1 frequency
opts.SelectModeBack = 'SweepFreqHS1';       %Sweep SRS HS1 frequency backwards
% opts.SelectMode = 'SweepField';       % Not programmed yet 
% opts.SelectMode = 'SweepFieldLegacy'; % old way

% Enanble/Disable the ACSynce
opts.use_ACSync = 1;

opts.doProgram = 1;


if nargin == 2
    fnames = fieldnames(override);
    for kk=1:length(fnames)
        opts.(fnames{kk}) = override.(fnames{kk});
    end
end    


%% Prepare Switches for uWave Radiation

disp('Changing swithces so that uwave are on');

% Make sure RF, Rb uWave, K uWave are all off for safety
setDigitalChannel(calctime(curtime,0),'RF TTL',0);
setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);

% Switch antenna to uWaves (0: RF, 1: uWave)
setDigitalChannel(calctime(curtime,10),'RF/uWave Transfer',1); 

% Switch uWave source to the K sources (0: K, 1: Rb);
setDigitalChannel(calctime(curtime,20),'K/Rb uWave Transfer',0);

% RF Switch for K SRS depreciated? (1:B, 0:A)
% Warning : may need to check the RF diagram for this to be correct
setDigitalChannel(calctime(curtime,25),'K uWave Source',1); 

% For SRS GPIB 30
setDigitalChannel(calctime(curtime,25),'SRS Source',1);  
        
% For SRS GPIB 29
% setDigitalChannel(calctime(curtime,25),'SRS Source post spec',1);
% setDigitalChannel(calctime(curtime,25),'SRS Source',0);

% Wait for switches to finish
curtime = calctime(curtime,30);

ScopeTriggerPulse(curtime,'Plane Select');

%% Magnetic Field Ramps 2
ramp_field_CF=0;
doTriggerLabJack=0;
if ramp_field_CF
    
    % FF Settings
    defVar('qgm_pselect_FF',25,'V');
    defVar('qgm_pselect_FF_ramp_time',20,'ms');

    % Timings
    defVar('qgm_pselect_ramp_time',25,'ms')
    defVar('qgm_pselect_settle_time',50,'ms');
    
    defVar('qgm_pselect_QP',24.92,'A');func_qp = 2;     % QP Settings
    defVar('qgm_pselect_FB',128-0.45,'G');func_fb = 2;   % FB Settings
    
    % Shim Setting
    func_x = 3; func_y = 4; func_z = 3;
    dIx0 = - 2.8050;
    dIy0 = - 0.1510;
    dIz0 = -1;         
    
    Ix = dIx0 + seqdata.params.shim_zero(1);
    Iy = dIy0 + seqdata.params.shim_zero(2);
    Iz = dIz0 + seqdata.params.shim_zero(3);
    
    Vff = getVar('qgm_pselect_FF');
    Tff = getVar('qgm_pselect_FF_ramp_time');
    IQP = getVar('qgm_pselect_QP');
    BFB = getVar('qgm_pselect_FB');
    Tr  = getVar('qgm_pselect_ramp_time');
    Ts  = getVar('qgm_pselect_settle_time');

    % Useful for looking at field stability
    if doTriggerLabJack
        DigitalPulse(calctime(curtime,-100),...
            'LabJack Trigger Transport',10,1);      
        DigitalPulse(calctime(curtime,100),...
            'LabJack Trigger Transport',10,1);
    end    
    
    dispLineStr('Ramping Fields CF', curtime);
    val_FF = getChannelValue(seqdata,'Transport FF',1);
    val_16 = getChannelValue(seqdata,'Coil 16',1);
    val_FB = getChannelValue(seqdata,'FB Current',1);
    val_X = getChannelValue(seqdata,'X Shim',1);
    val_Y = getChannelValue(seqdata,'Y Shim',1);
    val_Z = getChannelValue(seqdata,'Z Shim',1);

    % Ramp up QP Feedforward
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tff, Tff, Vff);    
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, IQP,func_qp);
    AnalogFuncTo(calctime(curtime,0),'FB Current',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, BFB,func_fb);  
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Ix,func_x);  
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Iy,func_y);  
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, Iz,func_z);  
    curtime = calctime(curtime,Tr);
    curtime = calctime(curtime,Ts);
end

%% Magnetic Field Ramps
opts.ramp_fields=1;
if opts.ramp_fields
    DigitalPulse(calctime(curtime,-100),...
        'LabJack Trigger Transport',10,1);      
    DigitalPulse(calctime(curtime,100),...
        'LabJack Trigger Transport',10,1);
    
    % Ramp the SHIMs, QP, and FB to the appropriate level  
    dispLineStr('Ramping Fields', curtime);
    clear('ramp');           

    % Fesbhach Field (in gauss)
    B0 = 128;    %old value 128G, 0.6G shift
    fb_shift_list = [0.45];% OLD FOR 25 A

    fb_shift_list = [0.45+0.63];[0.45];
    
    fb_shift_list = [0.45+0.63];[0.45];
        
fb_shift_list =[0.45+0.63]+2.35*1.256;
    
    fb_shift = getScanParameter(fb_shift_list,seqdata.scancycle,...
        seqdata.randcyclelist,'qgm_plane_FB_shift','G');    
    Bfb = B0 - fb_shift;
    
    
    defVar('IQP_PS_shift', [14], 'A');
    IQP_PS_shift = getVar('IQP_PS_shift');
    
    defVar('QP_FF_override', 28, 'V');18;
    
    % QP Field (in Amps)
    IQP = 14*1.78 + IQP_PS_shift; % 210 G/cm (not sure if calibrated)
    
    % Shim Fields (in Amps) OLD FOR 25 AMP
%     xshimdlist  = -2.8050;
%     yshimdlist  = -0.1510;
%     zshimdlist  = -1;         
%     
         
    % Shim Fields (in Amps) NEW FOR 39 AMP QP --> 12mG per plane
    xshimdlist  = -3.55;
    yshimdlist  = -0.1510;
    zshimdlist  = 0;
    
    xshimd = getScanParameter(xshimdlist,seqdata.scancycle,...
        seqdata.randcyclelist,'qgm_plane_dIx','A');
    yshimd = getScanParameter(yshimdlist,seqdata.scancycle,...
        seqdata.randcyclelist,'qgm_plane_dIy','A');    
    zshimd = getScanParameter(zshimdlist,seqdata.scancycle,...
        seqdata.randcyclelist,'qgm_plane_dIz','A');        
    
    % Shim Calibrations (unsure how correct
    % X/Y   : 1.983 G/A (from raman transfers)
    % Z     : 2.35 G/A  (from high field measurements)
    cxy = 1.983;
    cz = 2.35;
    
    if opts.dotilt        
%         xshimtilt = 5;
%         yshimtilt = -2.7;             
%         defVar('qgm_plane_tilt_dIz',[-0.206],'A');
%         zshimtilt=getVar('qgm_plane_tilt_dIz');        
        defVar('qgm_plane_tilt_dIz',[-0.012],'A');
        defVar('qgm_plane_tilt_dIz',[0.025],'A');
        
        defVar('qgm_plane_tilt_dIz',0.011,'A');
        
        if isfield(seqdata.flags,'qgm_stripe_feedback') && ...
            seqdata.flags.qgm_stripe_feedback && ...
            exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')      
            try
               names = dir([seqdata.IxonGUIAnalayisHistoryDirectory filesep '*.mat']);
               names = {names.name};
               names = flip(sort(names)); % Sort by most recent               
               N = 10;               
               % Get the most recent runs
               names = [names(1:N)];               
               tnow = datenum(now);
                t=[];theta=[];L=[];phi=[];v=[];B=[];
               for n = 1:length(names) 
                  data = load(fullfile(seqdata.IxonGUIAnalayisHistoryDirectory,names{n}));
                  data=data.gui_saveData;
                  
                  if isfield(data,'Stripe')
                      t(end+1) = datenum(data.Date);
                      v(end+1) = data.Params.qgm_plane_tilt_dIz;                      
                      theta(end+1,1) = data.Stripe.theta;
                      theta(end,2) = data.Stripe.theta_err;
                      
                      L(end+1,1) = data.Stripe.L;                      
                      L(end,2) = data.Stripe.L_err;
                      
                      phi(end+1,1) = data.Stripe.phi; 
                      phi(end,2) = data.Stripe.phi_err;    
                      
                      B(end+1,1) = data.Stripe.B; 
                      B(end,2) = data.Stripe.B_err;    
                  end
               end               
               dT = (tnow - t)*24*60*60;
              phiset = 0.9 * (2*pi);

               doDebug = 1;
               if doDebug
                  figure(1102); 
                  subplot(221)
                  errorbar(dT,phi(:,1),phi(:,2),'o');
                  xlabel('time ago(s)');
                      ylabel('phase (rad)');

                  ylim(phiset+[-pi pi]);
                  subplot(222)
                  errorbar(dT,L(:,1),L(:,2),'o');
                    xlabel('time ago(s)');
                    ylabel('wavelength (px)');

                  subplot(223)
                  errorbar(dT,theta(:,1),theta(:,2),'o');   
                xlabel('time ago(s)');
                ylabel('angle (deg)');

                  subplot(224)
                  plot(dT,v,'o');  
                    xlabel('time ago(s)');
                    ylabel('current (A)');

               end             
               
               % Modulus math to calculate -pi,pi phase error from phiset
               phi_err = ((phi(:,1)-phiset)/(2*pi)-round((phi(:,1)-phiset)/(2*pi)))*2*pi;               
               isGood = ones(size(phi,1),1);               
               theta_bounds = [88.5 89.5];
               L_bounds = [70 73];               
               minB = 0.45;
               
               for kk=1:size(phi,1)                   
                   % Ignore large phi data
                   if phi(kk,2)>.35;isGood(kk) = 0;end                   
                   % Ignore phi error close to +-pi/2
                   if abs(phi_err(kk))>(.45*pi);isGood(kk) = 0;end                   
                   
                   % Ignore larger theta uncertainty that 0.5 deg
                   if abs(theta(kk,2))>.5;isGood(kk) = 0;end   
                  % Ignore theta outside of boundaries
                   if theta(kk,1)<theta_bounds(1) || ...
                           theta(kk,1)>theta_bounds(2)
                       isGood(kk) = 0;                       
                   end                    
                                      
                   % Ignore L uncertainty than 0.6 px
                   if abs(L(kk,2))>.6;isGood(kk) = 0;end   
                  % Ignore L outside of boundaries
                   if abs(L(kk,1))<L_bounds(1) || ...
                           abs(L(kk,1))>L_bounds(2)
                       isGood(kk) = 0;                       
                   end                     
                   if B(kk,1)<minB; isGood(kk) = 0; end  
               end                     
                t_memory = 1800;
%                 t_memory = inf;                    
               isGood = isGood.*[dT<t_memory]';               
               isGood=logical(isGood);
               
               % Remove fits with suspect noise
                phi(~isGood,:)=[];
                t(~isGood) =[];
                theta(~isGood,:)=[];
                L(~isGood,:) = [];
                phi_err(~isGood) = [] ;
                v(~isGood) = [];
                B(~isGood,:)= [];
                dT(~isGood) = [];
                 
                 if length(dT)>5
                     beta = 0.9;                     
                     err_avg = mean(phi_err)/(2*pi);
                     err_this = phi_err(end)/(2*pi);                     
                     err_eff = err_this*(1-beta)+err_avg*beta;                     
                     dIz_old = v(end);                         
                     kappa = 1e-3/0.14;                     
                     dIz_new = dIz_old - kappa*err_eff;                     
                     defVar('qgm_plane_tilt_dIz',dIz_new,'A');
                     
                     disp(err_avg);
                     disp(err_eff);
                     disp(dIz_new);
                 end
         
                 
                 
% %     
%                
%                               
%                 keyboard
%                 t = readtable(ixon_gui_file);
%                 phiset = 0.9;    
%                 phiread = t.stripe__2pi_;                  
%                 phiread_p = phiread+1;
%                 phiread_n = phiread-1;
%                 phiall =[phiread_n phiread phiread_p];
%                 [val,ind] = min(abs(phiall-phiset));   
%                 disp('hiall');
%                 phiread=phiall(ind);
%                 dIz_old = t.x;
%                 m = 0.14;
%                 dI = 1e-3*(phiset-phiread)/m;                
%                 dIz_new = dIz_old+dI*0.5;
%                 disp(phiset);
%                 disp(phiread);
%                 disp(dIz_old);
%                 disp(dIz_new);                
%                 if abs(phiset-phiread)>0.15 && abs(phiset-phiread)<0.8
%                       defVar('qgm_plane_tilt_dIz',dIz_new,'A');
%                 else
%                       defVar('qgm_plane_tilt_dIz',dIz_old,'A');
%                 end
            end
        end
        
        xshimtilt = 4.4;
        yshimtilt = 0.3;    
        zshimtilt=getVar('qgm_plane_tilt_dIz');        
%         
%         xshimtilt = 5;
%         yshimtilt = -2.7;               
%         defVar('qgm_plane_tilt_dIz',[-0.125],'A');
%         zshimtilt=getVar('qgm_plane_tilt_dIz');
    else
        xshimtilt = 0;
        yshimtilt = 0;
        zshimtilt = 0;
    end  

    % Shim Ramp
    ramp.xshim_final = seqdata.params.shim_zero(1) + xshimd + xshimtilt;
    ramp.yshim_final = seqdata.params.shim_zero(2) + yshimd + yshimtilt;
    ramp.zshim_final = seqdata.params.shim_zero(3) + zshimd + zshimtilt;        
    ramp.shim_ramptime = 100;
    ramp.shim_ramp_delay = -10;
    
    % FB and QP values
    ramp.fesh_final         = Bfb; % in Gauss
    ramp.QP_final           = IQP; % in Amps?   

    % FB Timings
    ramp.fesh_ramptime      = 100;
    ramp.fesh_ramp_delay    = 0;

    % QP timings
    ramp.QP_ramptime        = 100;
    ramp.QP_ramp_delay      = 0;
    ramp.settling_time      = 300; %200   
    ramp.QP_FF_override     = getVar('QP_FF_override');
    
    % Extra Labeling
    addOutputParam('qgm_plane_Bfb',Bfb,'G');
    addOutputParam('qgm_plane_IQP',IQP,'A');

curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
end

%% Apply the uWaves

switch opts.SelectMode
    case 'SweepFreq'
        
    case 'SweepFreqHS1'        
        %% Sweep Frequency 
        % This does an HS1 plane frequency sweep, this is only good for one
        % plane really.
        dispLineStr('HS1 Frequency Sweep',curtime);

        % 2021/06/22 CF
        % Use this when Xshimd=3, zshimd=-1 and you vary yshimd
        % freq_list=interp1([-3 0.27 3],[100 -200 -500],yshimd);
        % use this when yshimd=3, zshim3=-1 an dyou vary xshimd
        % freq_list=interp1([-3 0 3],[-200 -400 -500],xshimd);

        % Define the SRS frequency

        freq_offset_list = [-60];-200;-715;
            

% freq_offset_list = freq_offset_list - 100*(yshimdlist+.1510);

        freq_amp_list = [8]; % 30 kHz is about 2 planes
%           freq_amp_list = [7]; % 12 kHz is about 1 plane   
          
        if opts.dotilt
            freq_amp_list = [8]; % 12 kHz is about 1 plane       
        end

        sweep_time_list = 2*freq_amp_list/10; % CF has no idea when this was calibrated

        defVar('qgm_plane_uwave_frequency_offset',freq_offset_list,'kHz');
        defVar('qgm_plane_uwave_amplitude',freq_amp_list,'kHz');
        defVar('qmg_plane_uwave_time',sweep_time_list,'ms')
        
        freq_offset = getVar('qgm_plane_uwave_frequency_offset');
%         freq_offset = getVarOrdered('qgm_plane_uwave_frequency_offset');
        freq_amp = getVar('qgm_plane_uwave_amplitude');
        sweep_time = getVar('qmg_plane_uwave_time');        
        uWave_delta_freq = freq_amp*1e-3;        
    
        
        defVar('qgm_plane_uwave_power',[15],'dBm');

        
       % Configure the SRS
        uWave_opts=struct;
        uWave_opts.Address      = 30;                       % SRS GPIB Addr
%         uWave_opts.Address=29; % 4/4/2023
        uWave_opts.Frequency    = 1606.75+freq_offset*1E-3; % Frequency [MHz]
        uWave_opts.Power        = getVar('qgm_plane_uwave_power');%15                    % Power [dBm]
        uWave_opts.Enable       = 1;                        % Enable SRS output    
        uWave_opts.EnableSweep  = 1;                    
        uWave_opts.SweepRange   = uWave_delta_freq;         % Sweep Amplitude [MHz]
        
        env_amp     = 1;              % Relative amplitude of the sweep (keep it at 1 for max)
        beta        = asech(0.005);   % Beta defines sharpness of HS1
        
%         addOutputParam('qgm_plane_uwave_power',uWave_opts.Power)
        addOutputParam('qgm_plane_uwave_frequency',uWave_opts.Frequency);            
        addOutputParam('qgm_plane_uwave_HS1_beta',beta);
        addOutputParam('qgm_plane_uwave_HS1_amp',env_amp);
        
        disp(['     Freq         : ' num2str(uWave_opts.Frequency) ' MHz']);    
        disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);    
        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Amp     : ' num2str(uWave_delta_freq*1E3) ' kHz']);


        %%%% The uWave Sweep Code Begins Here %%%%
        
        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

        % Enable ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave        
        if  ~opts.fake_the_plane_selection_sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
        end

        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);

        if  ~opts.fake_the_plane_selection_sweep
            % Sweep the VVA (use voltage func 2 to invert the vva transfer
            % curve (normalized 0 to 10
            AnalogFunc(calctime(curtime,0),'uWave VVA',...
                @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,env_amp,2);
        end

        curtime = calctime(curtime,sweep_time);                     % Wait for sweep
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

%         Reset the ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end

        if opts.doProgram
            programSRS(uWave_opts);                     % Program the SRS        
        end
        curtime = calctime(curtime,30);             % Additional wait

    case 'SweepFieldLegacy'
        %% Sweep Field Legacy (Pre CF)
        disp('Using Z shim to plane select');

        % uwave freq width (gets overwritten)
        ffscan_list = [100]/1000;%frequency sweep width
        ffscan = getScanParameter(ffscan_list,seqdata.scancycle,seqdata.randcyclelist,'ffscan');
        planeselect_sweep_width = ffscan;%500/1000;

        % SRS Settings (get's overwritten)
        spect_pars.freq = 1606.75;   % |9/2,-9/2>
        spect_pars.power = 15;15;%6.5; %-15 %uncalibrated "gain" for rf
        spect_pars.delta_freq = planeselect_sweep_width; %300
        spect_pars.mod_dev = planeselect_sweep_width; %Frequency range of SRS (MHz/V, input range is +/-1V, eg: 1/1000 means +/-500Hz)

        % What does this mean?
        Cycle_About_Freq_Val = 1; %1 if freq_val is centre freq, 0 if it is start freq.
        if(~Cycle_About_Freq_Val)
            spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
        end

        % uWave Timings (get's overwritten)
        planeselect_pulse_length = planeselect_sweep_width * 1000 / 10 * 2; %2ms per 10kHz        
        spect_pars.pulse_length = planeselect_pulse_length; % also is sweep length (max is Keithley time - 20ms)       1*16.7
        spect_pars.uwave_delay = 0; %wait time before starting pulse
        spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)

        %Options for spect_type = 1
        spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk  
        spect_pars.AM_ramp_time = 2;9;  

        %SRS in pulsed mode with amplitude modulation
        spect_type = 2;

        %Take frequency range in MHz, convert to shim range in Amps
        %  (-5.714 MHz/A on Jan 29th 2015)
        if (seqdata.flags.K_RF_sweep==1 || seqdata.flags.xdt_K_p2n_rf_sweep_freq==1)
            %In -ve mF state, frequency increases with field
            dBz = spect_pars.delta_freq / (5.714);
        else 
            %In +ve mF state, frequency decreases with field
            dBz = spect_pars.delta_freq / (-5.714);
        end

        field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
        field_shift_settle = 60; % settling time after initial and final field shifts

        if (Cycle_About_Freq_Val)
            %Shift field down and up by half of the desired width
            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
        else %Start at current field and ramp up
            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz;
        end

        % synchronizing this plane-selection sweep
        if opts.use_ACSync
              dispLineStr('enabling acync',curtime);

    %                 % Enable ACync right after ramping up to start field
    %                 ACync_start_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time);
    %                 % Disable ACync right before ramping back to initial field value
    %                 ACync_end_time = calctime(curtime,spect_pars.uwave_delay + field_shift_time + ...
    %                     2*field_shift_settle + spect_pars.pulse_length);

            % Enable ACync right after ramping up to start field
            ACync_start_time = calctime(curtime,spect_pars.uwave_delay - field_shift_settle);
            % Disable ACync right before ramping back to initial field value
            ACync_end_time = calctime(curtime,spect_pars.uwave_delay + ...
                field_shift_settle + spect_pars.pulse_length);
            setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
            setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
        end

        %Ramp shim to start value before generator turns on
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_start;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim during uwave pulse to transfer atoms
        ramp.shim_ramptime = spect_pars.pulse_length;
        ramp.shim_ramp_delay = spect_pars.uwave_delay;
        ramp.zshim_final = z_shim_sweep_final;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Ramp shim back to initial value after pulse is complete
        clear('ramp');
        ramp.shim_ramptime = field_shift_time;
        ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
        ramp.zshim_final = z_shim_sweep_center;

        ramp_bias_fields(calctime(curtime,0), ramp);

        %Extra Parameters for the plane selecting pulse
        spect_pars.fake_pulse = opts.fake_the_plane_selection_sweep;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
        spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value

            %Do plane selection pulse
    curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
    curtime = calctime(curtime,field_shift_settle+field_shift_time);
    % curtime = calctime(curtime,field_shift_time+5); %April 13th 2015, Reduce the post transfer settle time... since we will ramp the shim again anyway

end
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vertical Kill Beam Application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Apply a vertical *upwards* D2 beam resonant with the 9/2 manifold to 
% remove any atoms not transfered to the F=7/2 manifold.

if opts.planeselect_doVertKill==1
    dispLineStr('Applying vertical D2 Kill Pulse',curtime);

    %Resonant light pulse to remove any untransferred atoms from
    %F=9/2
    kill_time_list = [5];2;
    kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'kill_time','ms'); %10 
    kill_detuning_list = [42];[42.7];%42.7
    kill_detuning = getScanParameter(kill_detuning_list,...
        seqdata.scancycle,seqdata.randcyclelist,'kill_det');        

    %Kill SP AOM 
    mod_freq =  (120)*1E6;
    mod_amp_list = [0.02]; 0.1;
    mod_amp = getScanParameter(mod_amp_list,...
        seqdata.scancycle,seqdata.randcyclelist,'k_kill_power','V');
    mod_offset =0;
    str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
    addVISACommand(8, str);  %Device 8 is the new kill beam Rigol changed on July 10, 2021

    % Display update about
    disp(' D2 Kill pulse');
    disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
    disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
    disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
    disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 

    % Offset time of pulse (why?)
    pulse_offset_time = -5;       

    if kill_time>0
        % Set trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,pulse_offset_time-50),...
            'K Trap FM',kill_detuning); %54.5

        % Turn off kill SP (0= off, 1=on)(we keep it on for thermal stability)
        setDigitalChannel(calctime(curtime,pulse_offset_time-20),...
            'Kill TTL',0);

        % Open K Kill shutter (0=closed, 1=open)
        setDigitalChannel(calctime(curtime,pulse_offset_time-5),...
            'Downwards D2 Shutter',1);     

        % Pulse K Kill AOM
        DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',...
            kill_time,1);

        % Close K Kill shutter
        setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+2),...
            'Downwards D2 Shutter',0);

        % Turn on kill SP (thermal stability)
        setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+5),...
            'Kill TTL',1);

        % Advance Time
        curtime=calctime(curtime,pulse_offset_time+kill_time+5);
    end
end


%% UWave Transfer Back to 9/2,-9/2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uWave Transfer back to |9/2,-9/2>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if opts.planeselect_doMicrowaveBack
    
    switch opts.SelectModeBack
        case 'SweepFreqHS1'        
            %Sweep the frequency
            disp('sweeping frequency HS1');
            
            % For SRS GPIB 29
            setDigitalChannel(calctime(curtime,0),'SRS Source post spec',1);
            setDigitalChannel(calctime(curtime,0),'SRS Source',0);
            
            % Wait for switches to finish
            curtime = calctime(curtime,30);
            
            % 2021/06/22 CF
            % Use this when Xshimd=3, zshimd=-1 and you vary yshimd
            % freq_list=interp1([-3 0.27 3],[100 -200 -500],yshimd);
            % use this when yshimd=3, zshim3=-1 an dyou vary xshimd
            % freq_list=interp1([-3 0 3],[-200 -400 -500],xshimd);

            % Define the SRS frequency
            if opts.dotilt
                freq_list = 1050 + [1220];
            else
                freq_list = 1050 + [520];
            end

            freq_offset = getScanParameter(freq_list,seqdata.scancycle,...
                seqdata.randcyclelist,'uwave_freq_offset_back','kHz from 1606.75 MHz');

            disp(['     Freq Offset  : ' num2str(freq_offset) ' kHz']);

            % SRS settings (may be overwritten later)
            uWave_opts=struct;
            uWave_opts.Address=29;                        % K uWave ("SRS B");
            uWave_opts.Frequency=1606.75+freq_offset*1E-3;% Frequency in MHz
            uWave_opts.Power= 15;%15                      % Power in dBm
            uWave_opts.Enable=1;                          % Enable SRS output    

            addOutputParam('uwave_pwr_back',uWave_opts.Power)
            addOutputParam('uwave_frequency_back',uWave_opts.Frequency);    

            disp('HS1 Sweep Pulse Backwards');

            % Calculate the beta parameter
            beta=asech(0.005);   
            addOutputParam('uwave_HS1_beta_back',beta);

            % Relative envelope size (less than or equal to 1)
            env_amp=1;
            addOutputParam('uwave_HS1_amp_back',env_amp);

            % Determine the range of the sweep
            uWave_delta_freq_list= [120]/1000; [7]/1000;
            uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
                seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq_back','kHz');

            % the sweep time is based on old calibration for rabi frequency
            uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
            sweep_time = getScanParameter(uwave_sweep_time_list,...
                seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time_back');     

            disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
            disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

            % Enable uwave frequency sweep
            uWave_opts.EnableSweep=1;                    
            uWave_opts.SweepRange=uWave_delta_freq;   

            setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
            setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

            % Enable ACync
            if opts.use_ACSync
                setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
            end

            % Turn on the uWave        
            if  ~opts.fake_the_plane_selection_sweep
                disp('disabling ');
                setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
            end

            % Ramp the SRS modulation using a TANH
            % At +-1V input for +- full deviation
            % The last argument means which votlage fucntion to use
            AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
                @(t,T,beta) -tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,1);

            if  ~opts.fake_the_plane_selection_sweep
                % Sweep the VVA (use voltage func 2 to invert the vva transfer
                % curve (normalized 0 to 10
                AnalogFunc(calctime(curtime,0),'uWave VVA',...
                    @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                    sweep_time,sweep_time,beta,env_amp,2);
            end

            curtime = calctime(curtime,sweep_time);                     % Wait for sweep
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
            setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
            setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

            % Reset the ACync
            if opts.use_ACSync
                setDigitalChannel(calctime(curtime,30),'ACync Master',0);
            end

            programSRS(uWave_opts);                     % Program the SRS        
            curtime = calctime(curtime,30);             % Additional wait  

        case 'SweepFieldLegacy'
            % Transfer the |7,-7> back to |9,-9>.  This sweep can be broad
            % because everything else is dead (nominally). This step is
            % also somewhat uncessary because the Raman beams during
            % imaging Rabi oscillates between the two

            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
            curtime = calctime(curtime,65);

            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;

            %Take frequency range in MHz, convert to shim range in Amps
            %(-5.714 MHz/A on Jan 29th 2015)

            final_transfer_range = 2; %MHz
            back_transfer_range = 1;
            if (seqdata.flags. K_RF_sweep==1 || seqdata.flags. xdt_K_p2n_rf_sweep_freq==1)

                %In -ve mF state, frequency increases with field
                dBz = back_transfer_range*final_transfer_range / (5.714);
            else 
                %In +ve mF state, frequency decreases with field
                dBz = back_transfer_range*final_transfer_range / (-5.714);
            end

            spect_pars.pulse_length = 100*final_transfer_range; %Seems to give good LZ transfer for power = -12dBm peak

            final_sweep_time = back_transfer_range*spect_pars.pulse_length;
            field_shift_time = 10; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = spect_pars.AM_ramp_time + 10; % settling time after initial and final field shifts

            z_shim_sweep_center = getChannelValue(seqdata,'Z Shim',1,0);
            z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
            z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = final_sweep_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            ramp_bias_fields(calctime(curtime,0), ramp);

            %Ramp shim back to initial value after pulse is complete
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            ramp_bias_fields(calctime(curtime,0), ramp);

        curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
        curtime = calctime(curtime,field_shift_settle+field_shift_time); 

            followup_repump_pulse = 1;1;%remove mF = -7/2 atoms
            if (followup_repump_pulse)
                %Ensure atoms are all returned to F=9/2 with repump light
                % (do this during the shim field wait time above)
                % (would be great to use FM to get the repump to resonance in the 40G field)

                %Pulse on repump beam to try to remove any atoms left in F=7/2
                repump_pulse_time = 5;
                repump_pulse_power = 0.7;

                %Open Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),3,1);
                %turn repump back up
                setAnalogChannel(calctime(curtime,-field_shift_settle-10),25,repump_pulse_power);
                %repump TTL
                setDigitalChannel(calctime(curtime,-field_shift_settle-10),7,1);

                %Repump pulse
                DigitalPulse(calctime(curtime,-field_shift_settle),7,repump_pulse_time,0);

                %Close Repump Shutter
                setDigitalChannel(calctime(curtime,-field_shift_settle+repump_pulse_time+5),3,0);
            end
    end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Repump to kill F=7/2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if opts.planeselect_doFinalRepumpPulse
    %Pulse on repump beam to try to remove any atoms left in F=7/2
    repump_pulse_time = 5;
    repump_pulse_power = 0.7;

    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),3,1);
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),25,repump_pulse_power);
    %repump TTL
    setDigitalChannel(calctime(curtime,-10),7,1);

    %Repump pulse
    DigitalPulse(calctime(curtime,0),7,repump_pulse_time,0);

    %Close Repump Shutter
    setDigitalChannel(calctime(curtime,repump_pulse_time+5),3,0);
end 

%% Plane select a second time
if opts.planeselect_again

    
    % For SRS GPIB 30
    setDigitalChannel(calctime(curtime,0),'SRS Source',1); 
    setDigitalChannel(calctime(curtime,0),'SRS Source post spec',0);
    % Wait for switches to finish
    curtime = calctime(curtime,30);
    
    disp('HS1 Sweep Pulse');

        % Calculate the beta parameter
        beta=asech(0.005);   
        addOutputParam('uwave_HS1_beta_2',beta);

        % Relative envelope size (less than or equal to 1)
        env_amp=1;
        addOutputParam('uwave_HS1_amp_2',env_amp);

        % Determine the range of the sweep
        uWave_delta_freq_list= [20]/1000; [7]/1000;
        uWave_delta_freq=getScanParameter(uWave_delta_freq_list,...
            seqdata.scancycle,seqdata.randcyclelist,'plane_delta_freq_2','kHz');

        % the sweep time is based on old calibration for rabi frequency
        uwave_sweep_time_list =[uWave_delta_freq]*1000/10*2; 
        sweep_time = getScanParameter(uwave_sweep_time_list,...
            seqdata.scancycle,seqdata.randcyclelist,'uwave_sweep_time_2');     

        disp(['     Pulse Time   : ' num2str(sweep_time) ' ms']);
        disp(['     Freq Delta   : ' num2str(uWave_delta_freq*1E3) ' kHz']);

        % Enable uwave frequency sweep
        uWave_opts.EnableSweep=1;                    
        uWave_opts.SweepRange=uWave_delta_freq;   

        setAnalogChannel(calctime(curtime,-20),'uWave VVA',0);      % Set uWave to low
        setAnalogChannel(calctime(curtime,-10),'uWave FM/AM',-1);   % Set initial modulation

        % Enable ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
        end

        % Turn on the uWave        
        if  ~opts.fake_the_plane_selection_sweep
            disp('disabling ');
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  
        end

        % Ramp the SRS modulation using a TANH
        % At +-1V input for +- full deviation
        % The last argument means which votlage fucntion to use
        AnalogFunc(calctime(curtime,0),'uWave FM/AM',...
            @(t,T,beta) tanh(2*beta*(t-0.5*sweep_time)/sweep_time),...
            sweep_time,sweep_time,beta,1);

 
        if  ~opts.fake_the_plane_selection_sweep
            % Sweep the VVA (use voltage func 2 to invert the vva transfer
            % curve (normalized 0 to 10
            AnalogFunc(calctime(curtime,0),'uWave VVA',...
                @(t,T,beta,A) A*sech(2*beta*(t-0.5*sweep_time)/sweep_time),...
                sweep_time,sweep_time,beta,env_amp,2);
        end

        curtime = calctime(curtime,sweep_time);                     % Wait for sweep
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);     % Turn off the uWave
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0);        % Turn off VVA        
        setAnalogChannel(calctime(curtime,10),'uWave FM/AM',-1);    % Reset the uWave deviation after a while

        % Reset the ACync
        if opts.use_ACSync
            setDigitalChannel(calctime(curtime,30),'ACync Master',0);
        end
        curtime = calctime(curtime,30);             % Additional wait
        
        if opts.planeselect_doVertKill==1

                    %Resonant light pulse to remove any untransferred atoms from
            %F=9/2
            kill_time_list = kill_time;2;
            kill_time = getScanParameter(kill_time_list,seqdata.scancycle,...
                seqdata.randcyclelist,'kill_time_2','ms'); %10 
            kill_detuning_list = kill_detuning;[42.7];%42.7
            kill_detuning = getScanParameter(kill_detuning_list,...
                seqdata.scancycle,seqdata.randcyclelist,'kill_det_2');        
               
            %Kill SP AOM 
            mod_freq =  (120)*1E6;
            mod_amp = mod_amp;0.05;0.1; % use same power for both pulses 
            
            % Display update about
            disp(' D2 Kill pulse');
            disp(['     Kill Time       (ms) : ' num2str(kill_time)]); 
            disp(['     Kill Frequency (MHz) : ' num2str(mod_freq*1E-6)]); 
            disp(['     Kill Amp         (V) : ' num2str(mod_amp)]); 
            disp(['     Kill Detuning  (MHz) : ' num2str(kill_detuning)]); 

            % Offset time of pulse (why?)
            pulse_offset_time = -5;       

            if kill_time>0
                % Set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,pulse_offset_time-50),...
                    'K Trap FM',kill_detuning); %54.5

                % Turn off kill SP (0= off, 1=on)(we keep it on for thermal stability)
                setDigitalChannel(calctime(curtime,pulse_offset_time-20),...
                    'Kill TTL',0);

                % Open K Kill shutter (0=closed, 1=open)
                setDigitalChannel(calctime(curtime,pulse_offset_time-5),...
                    'Downwards D2 Shutter',1);     

                % Pulse K Kill AOM
                DigitalPulse(calctime(curtime,pulse_offset_time),'Kill TTL',...
                    kill_time,1);

                % Close K Kill shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+2),...
                    'Downwards D2 Shutter',0);

                % Turn on kill SP (thermal stability)
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time+5),...
                    'Kill TTL',1);

                % Advance Time
                curtime=calctime(curtime,pulse_offset_time+kill_time+5);
            end
            
        end
    
end

%%
if ramp_field_CF
    % Ramp up QP Feedforward
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_16,func_qp);
    AnalogFuncTo(calctime(curtime,0),'FB Current',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_FB,func_fb);  
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_X,func_x);  
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_Y,func_y);  
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tr, Tr, val_Z,func_z);  
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        Tff+20, Tff+20, val_FF); 
    curtime = calctime(curtime,Tr);
    curtime = calctime(curtime,Ts);
     
end
     
end

