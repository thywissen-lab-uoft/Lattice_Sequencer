function [timeout,I_QP,V_QP,P_dip,I_shim] =  xdt(timein, I_QP, V_QP,I_shim)
%% xdt.m
% Author : C Fujiwara
%
% This code is a glorify wrapper function to call all tasks in the optical
% dipole trap.  The code is segmented in this way because I think it make
% logical sense and also this prevents the optical dipole trap code from
% getting too long.

I_QP=[];
V_QP=[];
I_shim=[];

%% Initialize
P_dip = [];
curtime = timein;
global seqdata;

%% XDT Load new
if seqdata.flags.mt_2_xdt
    curtime = MT_2_XDT(curtime);  
    
    if seqdata.flags.mt_2_xdt_spin_xfers
       [curtime] = xdt_spin_transfers(curtime); 
    end
    
    if seqdata.flags.mt_2_xdt_spin_xfers2
   [curtime] = xdt_spin_transfers2(curtime); 
    end  

end

%% Load the Dipole Trap from the Magnetic Trap
if seqdata.flags.xdt_load
    [curtime, I_QP, V_QP,I_shim] = xdt_load(curtime, I_QP, V_QP,I_shim);    
end
% curtime = calctime(curtime,500);
%% Pre-evaporation 

if seqdata.flags.xdt_pre_evap
    [curtime, I_QP, V_QP,I_shim] = xdt_pre_evap(curtime, I_QP, V_QP,I_shim);
end


%% Evaporation Stage 1
if seqdata.flags.xdt_evap_stage_1
    [curtime, I_QP, V_QP,I_shim] = xdt_evap_stage_1(curtime, I_QP, V_QP,I_shim);
end

%% Post Evap Stage 1
if seqdata.flags.xdt_post_evap_stage1
   curtime = xdt_post_evap_stage_1(curtime); 
end
 curtime=calctime(curtime,10);
 
%% K uWave spectroscopy
seqdata.flags.xdt_uwave_K_spec = 0;
if seqdata.flags.xdt_uwave_K_spec
    
    doRampFB = 1;
    tr = 100;
    fesh = 124; % 124 G   
    
   logNewSection('XDT uWave K Spectroscopy',curtime);   

    % MHz B=0 Gfield splitting
    f0 = 1285.8; % 1607         
    
    % Frequency away from f0 (B=0 splitting)
    defVar('uWave_freq_shift',50,'MHz'); %50 
    
    uWave_freq = defVar('uWave_freq',getVar('uWave_freq_shift')+f0,'MHz');   
    uwave_delta_freq=defVar('uwave_delta_freq',0.2,'MHz');    
    uwave_time=defVar('uWave_time',5,'ms');
    uwave_power=defVar('uwave_power',5,'dBm');
    
    if doRampFB                
        logNewSection('XDT uWave K Spectroscopy',curtime);  
        % MHz B=0 Gfield splitting
        f0 = 1602.5;1571.5;1788.85; % 124 G 1602.5 MHz, 195 G 1788.85 MHz         
        % Frequency away from f0 (B=0 splitting)
        defVar('uWave_freq_shift',[-.033],'MHz'); %2024/10/03
        uWave_freq = defVar('uWave_freq',getVar('uWave_freq_shift')+f0,'MHz');   
        uwave_delta_freq=defVar('uwave_delta_freq',.05,'MHz'); % 0.2 MHz   
        uwave_time=defVar('uWave_time',[0 .005 .15 .25 .35],'ms');
        uwave_power=defVar('uwave_power',5,'dBm');       
        
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
        ramp.settling_time      = 200;    
    curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
    end
    
    % RF transfer
    seqdata.flags.xdt_K_spinflip_end = 0;
    if seqdata.flags.xdt_K_spinflip_end
        % NOTE THAT THIS FREQUENCY COUPLES TO THE RB FIELD SWEEP    
        logNewSection('RF K Sweep -9/2 --> -7/2',curtime);  

        defVar('xdt_spin_xfer_K_end_freq',[31.0272],'MHz');1.52;
        defVar('xdt_spin_xfer_K_end_freq_amp',1,'MHz');.15;
        defVar('xdt_spin_xfer_K_end_gain',0,'V');0; % if you make this too high you will perturb Rb
        defVar('xdt_spin_xfer_K_end_time',100,'ms');20;

        setDigitalChannel(calctime(curtime,-20),'RF Source',0);   % 0: RF, 1: uwave  
        setDigitalChannel(calctime(curtime,-20),'RF/uWave Transfer',0);   % 0: RF, 1: uwave   
        setDigitalChannel(calctime(curtime,-5),'RF TTL',0);               % RF OFF


        tsw = getVar('xdt_spin_xfer_K_end_time');

        DDS_ID=1;
        f1 = 1e6*(getVar('xdt_spin_xfer_K_end_freq')-getVar('xdt_spin_xfer_K_end_freq_amp'));
        f2 = 1e6*(getVar('xdt_spin_xfer_K_end_freq')+getVar('xdt_spin_xfer_K_end_freq_amp')); %( Don't actually sweep the frequency');
        dT=getVar('xdt_spin_xfer_K_end_time');                    % Duration of this sweep in ms

        % Add a DDS Sweep
        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1; 
        sweep=[DDS_ID f1 f2 dT];    % Sweep data;
        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;       

        % Turn on RF some time after Rb
        pulseRF = 1;
        if pulseRF
            setDigitalChannel(calctime(curtime,0),'RF TTL',1);           % RF ON 
        end
        DigitalPulse(calctime(curtime,0),'DDS ADWIN Trigger',5,1);   % DDS Trigger

        setAnalogChannel(calctime(curtime,-10),'RF Gain',-10,1);       % Gain Set
        G = getVar('xdt_spin_xfer_K_end_gain'); % if you make this too high you will perturb Rb

        % Ramp Up Gain Smoothly
        tR = 2;
        curtime = AnalogFunc(calctime(curtime,0),'RF Gain',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            tR,tR,-10,G,1); 
        curtime = calctime(curtime,tsw-2*tR); 
        curtime = AnalogFunc(calctime(curtime,0),'RF Gain',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            tR,tR,G,-10,1); 

        setDigitalChannel(calctime(curtime,0),'RF TTL',0);           % RF OFF 
        setAnalogChannel(calctime(curtime,0),'RF Gain',-10);         % Gain Set
        
        curtime=calctime(curtime,100);
    end

        
    % Turn off all RF, Rb uWave, K uWave are all off for safety
    setDigitalChannel(calctime(curtime,-20),'RF TTL',0);
    setDigitalChannel(calctime(curtime,-20),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,-20),'K uWave TTL',0);
    
    % Switch antenna to uWaves (0: RF, 1: uWave)
    setDigitalChannel(calctime(curtime,-19),'RF/uWave Transfer',1);     
    % Switch uWave source to the K sources (0: K, 1: Rb);
    setDigitalChannel(calctime(curtime,-19),'K/Rb uWave Transfer',0);    
     % Set initial modulation (in case of frequency sweep)
    setAnalogChannel(calctime(curtime,-20),'uWave FM/AM',-1);    
    % Set VVA to Low
    setAnalogChannel(calctime(curtime,-10),'uWave VVA',0,1);     
    
    % Enable ACync
    use_ACSync = 1;
    if use_ACSync
        setDigitalChannel(calctime(curtime,-5),'ACync Master',1);
    end
    
    % For Rabi pulse

    doSweep=1;
    douWave = 1;

    if doSweep
        % For Sweep
        if douWave
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  % Turn on the uWave  
        end    
        curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',... % VVA ramp up
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),0.5,0.5,0,10,1);      
        curtime = AnalogFunc(calctime(curtime,0),'uWave FM/AM',...% Sweep Freq
            @(t,T) -1+2*t/T,uwave_time,uwave_time);    
        curtime = AnalogFunc(calctime(curtime,0),'uWave VVA',... % VVA ramp down
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),0.5,0.5,10,0,1);     
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);  % Turn off the uWave
        % Reset the uWave deviation after a while
        setAnalogChannel(calctime(curtime,50),'uWave FM/AM',-1);  
        
    else
        uwave_delta_freq=defVar('uwave_delta_freq',0.001,'MHz'); % 0.2 MHz           
        defVar('uWave_freq_shift',[-.033],'MHz'); % 0.2 MHz 
        uWave_freq = defVar('uWave_freq',getVar('uWave_freq_shift')+f0,'MHz');   
        uwave_power=defVar('uwave_power',5,'dBm');   
        setAnalogChannel(calctime(curtime,-2),'uWave VVA',10,1); 
        setAnalogChannel(calctime(curtime,-5),'uWave FM/AM',0); 
        f_rabi=8;
        pulse_time=defVar('uWave_time',[0:.1:5]*0.5/f_rabi,'ms');% do a pi pulse
        if douWave
            setDigitalChannel(calctime(curtime,0),'K uWave TTL',1);  % Turn on the uWave  
        end
        curtime=calctime(curtime,pulse_time);
        setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);  % Turn off the uWave  
        setAnalogChannel(calctime(curtime,0),'uWave VVA',0,1); 
    end
    if use_ACSync
        curtime = setDigitalChannel(calctime(curtime,30),'ACync Master',0);
    end
    
    % uWave transfer
    settings=struct;
    settings.Address       = 30;
    settings.Frequency     = uWave_freq;               % Center Frequency (MHz);
    settings.Power         = uwave_power;              % Power (dBm);
    settings.Enable        = 1;
    settings.EnableSweep   = 1;                        % Whether to sweep the frequency
    settings.SweepRange    = (uwave_delta_freq/2);     % Sweep Amplitude in MHz   
    
    if doSweep
        settings.EnableSweep   = 1;  
    else
        settings.EnableSweep   = 0;  
    end
    programSRS(settings);  
    
    if doRampFB    
        tr = 30;
        ts = 20;
        fesh_final = 20;
        
        % Define the ramp structure
        ramp=struct;
        ramp.shim_ramptime      = tr;
        ramp.shim_ramp_delay    = 0;
        ramp.xshim_final        = seqdata.params.shim_zero(1); 
        ramp.yshim_final        = seqdata.params.shim_zero(2);
        ramp.zshim_final        = seqdata.params.shim_zero(3);
        ramp.fesh_ramptime      = tr;
        ramp.fesh_ramp_delay    = 0;
        ramp.fesh_final         = fesh_final; %22.6
        ramp.settling_time      = ts;    
    curtime= ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain   
    end
end
    
%% The End!
timeout = curtime;
logNewSection('Dipole Transfer complete',curtime);

end