function timeout = magnetic_trap_cf(curtime)
global seqdata

% "Useful" constants
kHz = 1E3;
MHz = 1E6;
GHz = 1E9;


% DDS ID for RF evaporation
DDS_ID=1;

% Trigger pulse duration in ms
dTP=0.1; 

I_QP =    33;
I_kitt =    4.0200;
V_QP =   24.8050;
I_fesh =     0;  

% Voltage funcs
func_k = 2;
func_16 = 2;
func_x = 3;
func_y = 4;
func_z = 3;

% Read the currents from the various channels
I_K = getChannelValue(seqdata,'kitten',1);    
I_QP = getChannelValue(seqdata,'Coil 16',1);    
I_x = getChannelValue(seqdata,'X Shim',1);
I_y = getChannelValue(seqdata,'Y Shim',1);
I_z = getChannelValue(seqdata,'Z Shim',1);

% Read in the shim values for the plug (sets the position of RF1B).  You
% want to specify these to be right below the sapphire window since the ODT
% will load very close to the position specified by the shim values
x_shim_val = seqdata.params.plug_shims(1); 
y_shim_val = seqdata.params.plug_shims(2);
z_shim_val = seqdata.params.plug_shims(3); 

    % For Rubidium we evaporate on 2-->1
    % |2,2>-->|2,1>=h*f ==> E_atom = 2*h*f
    % Accounting for the factor of two : 1 MHz evaporates 96 uK atoms

%% Ramp shims for magnetic trap
if seqdata.flags.mt_ramp_to_plugs_shims
    t_ramp = 100;
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),t_ramp,t_ramp,y_shim_val,func_y); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),t_ramp,t_ramp,x_shim_val,func_x);
    AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),t_ramp,t_ramp,z_shim_val,func_z); 
    curtime = calctime(curtime,t_ramp);
end

%% Prepare Switches for evaporation

% The the RF/uWave switch to RF
setDigitalChannel(curtime,'RF/uWave Transfer',0);

%% RF Evaporation 1

defVar('RF1A_freq_0',40,'MHz');
defVar('RF1A_freq_1',30,'MHz');
defVar('RF1A_freq_2',20,'MHz');
defVar('RF1A_freq_3',16,'MHz');

defVar('RF1A_gain_0',-2.05,'arb');
defVar('RF1A_gain_1',-2.05,'arb');
defVar('RF1A_gain_2',-2.05,'arb');
defVar('RF1A_gain_3',-2.05,'arb');

defVar('RF1A_time_1',14000,'ms');
defVar('RF1A_time_2',8000,'ms');
defVar('RF1A_time_3',4000,'ms');

if seqdata.flags.mt_rf_1
    dispLineStr('RF1A',curtime);

    % Frequency end points    
    freqs_1 = [...
          getVar('RF1A_freq_0') ... 
          getVar('RF1A_freq_1') ...
          getVar('RF1A_freq_2') ...
          getVar('RF1A_freq_3')]*MHz;

    % Gain between end points
    gains_1 = [
          getVar('RF1A_gain_1') ...
          getVar('RF1A_gain_2') ...
          getVar('RF1A_gain_3')];

    % Time between frequency points points
    times_1 = [...
          getVar('RF1A_time_1') ... 
          getVar('RF1A_time_2') ...
          getVar('RF1A_time_3')].*getVar('RF1A_time_scale');

    % Whether to enable the RF
    enable_1 = [1 1 1];
    
    disp(['     Times        (ms) : ' mat2str(times_1) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1*1E-6) ]);
    disp(['     Gains         (V) : ' mat2str(gains_1) ]);

    % Wait a moment before starting
    curtime = calctime(curtime,100);   

    % Iterate over each sweep
    for kk=1:length(times_1)      
        setDigitalChannel(curtime,'RF TTL',enable_1(kk));   % set RF on/off        
        DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);    % Trigger DDS        
        seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;        % Increment the number of DDS sweeps
        dT=times_1(kk);                                     % Duration of this sweep in ms
        f1=freqs_1(kk);                                     % Starting Frequency in Hz
        f2=freqs_1(kk+1);                                   % Ending Frequency in Hz  
        sweep=[DDS_ID f1 f2 dT];                            % Sweep data;
        seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;    % Add this sweep to the queue
        setAnalogChannel(curtime,'RF Gain',gains_1(kk));    % Set the RF Gain          
        curtime = calctime(curtime,dT);                     % Advance time
    end
end

    
%% Ramp down QP and/or transfer to the window
% Decompress the QP trap and transpor the atoms closer to the window.

dispLineStr('Decompressing and transporting.',curtime);

if seqdata.mt_move_and_decompress
    t_ramp = 100;
    t_ramp2= 100;
    t_relay = 50;
    I_16_2=26.4;

    % Ramp down the kitten
    AnalogFuncTo(calctime(curtime,0),'kitten', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),t_ramp,t_ramp,0,func_k);
    AnalogFuncTo(calctime(curtime,0),'Coil 16', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),t_ramp,t_ramp,I_16_2,func_16);
    curtime = calctime(curtime,t_ramp);

    % Make sure kitten is off by ramping to negative currents
    AnalogFuncTo(calctime(curtime,0),'kitten', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),t_ramp2,t_ramp2,-2,func_k);
    curtime = calctime(curtime,t_ramp);

    % Turn off kitten physically (can this introduce noise?)
    setDigitalChannel(calctime(curtime,0),'Kitten Relay',0);
    curtime = calctime(curtime,t_relay);    % Wait for relay to settle 
end


%% Turn on Plug Beam
% The plug is only helpful in the second stage of evaporation where the MT
% center is put ontop of the plug.  However, it may cause heating if turned
% on diabatically.  Here we ramp the plug power by ramping the TA current

if  seqdata.flags.mt_use_plug  
    dispLineStr('Turning on the plug',curtime);
    t_plug_ramp = 500;
    plug_current_low = 500;
    plug_current_high = 2500;
    T0 = -1000;

    % Ramp down TA current (while shutter is still closed)
    AnalogFuncTo(calctime(curtime,T0),'Plug', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),t_plug_ramp,t_plug_ramp,plug_current_low);
    curtime = calctime(curtime,t_plug_ramp);

    % Open the plug shutter
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',1); %0: CLOSED; 1: OPEN
    curtime = calctime(curtime,10);     % wait for shutter to open

    % Ramp up the TA Current (while shutter is open)
    AnalogFuncTo(calctime(curtime,T0),'Plug', ...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),t_plug_ramp,t_plug_ramp,plug_current_high);
end

%% Evaporation Stage 1b

if ( seqdata.flags.RF_evap_stages(3) == 1 )    
    dispLineStr('RF1B begins.',curtime);  
    
    % Define RF1B parameters (frequency, gain, timescale, gradient, etc)
    sweep_times_1b = [6000 3000 2]*getVar('RF1B_time_scale');     
    evap_end_gradient_factor_list = [1];.9; %0.75
    evap_end_gradient_factor = getScanParameter(evap_end_gradient_factor_list,...
        seqdata.scancycle,seqdata.randcyclelist,'evap_end_gradient_factor');    
    currs_1b = [1 1 evap_end_gradient_factor evap_end_gradient_factor]*I_QP;
    freqs_1b = [freqs_1(end)/MHz*1.1 7  getVar('RF1B_finalfreq') 2]*MHz;  
    rf_1b_gain_list = [-2];
    rf_1b_gain = getScanParameter(rf_1b_gain_list,...
        seqdata.scancycle,seqdata.randcyclelist,'RF1B_gain','V');    
    gains = ones(1,length(freqs_1b))*rf_1b_gain;
    
    defVar('RF1B_freq_0',getVar('RF1A_freq_3')*1.1,'MHz');
    defVar('RF1B_freq_1',7,'MHz');7;
     defVar('RF1B_freq_2',[1],'MHz');1;
    defVar('RF1B_freq_3',2,'MHz');2;
    defVar('RF1B_time_1',[6000],'ms');6000;2500;
    defVar('RF1B_time_2',[3000],'ms');3000;2000;
    defVar('RF1B_time_3',2,'ms');2;
    defVar('RF1B_gain_0',-2,'arb');-2;0;
    defVar('RF1B_gain_1',-2,'arb');-2;0;
    defVar('RF1B_gain_2',-2,'arb');-2;0;
    defVar('RF1B_gain_3',-2,'arb');-2;0;
    defVar('RF1B_current_0',I_QP,'A');
    defVar('RF1B_current_1',I_QP,'A');
    defVar('RF1B_current_2',I_QP,'A');
    defVar('RF1B_current_3',I_QP,'A');
    

    freqs_1b = [...
          getVar('RF1B_freq_0') ... 
          getVar('RF1B_freq_1') ...
          getVar('RF1B_freq_2') ...
          getVar('RF1B_freq_3')]*MHz;

    gains = [...
          getVar('RF1B_gain_0') ... 
          getVar('RF1B_gain_1') ...
          getVar('RF1B_gain_2') ...
          getVar('RF1B_gain_3')];

    sweep_times_1b = [...
          getVar('RF1B_time_1') ... 
          getVar('RF1B_time_2') ...
          getVar('RF1B_time_3')].*getVar('RF1B_time_scale');
      
    currs_1b = [...
          getVar('RF1B_current_0') ... 
          getVar('RF1B_current_1') ...
          getVar('RF1B_current_2') ...
          getVar('RF1B_current_3')];
% 
    
    % Create RF1B structure object
    RF1Bopts=struct;
    RF1Bopts.Freqs = freqs_1b;
    RF1Bopts.SweepTimes = sweep_times_1b;
    RF1Bopts.Gains = gains;
    RF1Bopts.RFEnable = ones(1,length(sweep_times_1b));
    RF1Bopts.QPCurrents = currs_1b;
    
    disp(['     Times        (ms) : ' mat2str(sweep_times_1b) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1b*1E-6) ]);
    disp(['     Currents      (A) : ' mat2str(currs_1b) ]);
    disp(['     Gains         (V) : ' mat2str(gains) ]);

    % Perform RF1B
    [curtime, I_QP, V_QP, I_shim] = MT_rfevaporation(curtime, RF1Bopts, I_QP, V_QP);
    
    % Turn off the RF
    setDigitalChannel(curtime,'RF TTL',0);% rf TTL
    dispLineStr('RF1B ends.',curtime);        
end

%% Kill Rb after evap
if seqdata.flags.mt_kill_Rb_after_evap
    dispLineStr('Kill Rb after rf evap',curtime);        
    kill_pulse_time = 5; %5

    % Prepare probe beam
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %0=closed, 1=open
    setAnalogChannel(calctime(curtime,-10),'Rb Probe/OP AM',0.7); 
    setAnalogChannel(calctime(curtime,-10),'Rb Beat Note FM',6590-237);

    % Make sure that Rb probe is off
    setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP TTL',1);

    % Pulse the probe TTL
    curtime = DigitalPulse(calctime(curtime,0),'Rb Probe/OP TTL',...
        kill_pulse_time,0);

    % Close the probe shutter
    curtime = setDigitalChannel(calctime(curtime,0),'Rb Probe/OP shutter',0); %0=closed, 1=open
    curtime=calctime(curtime,5);
end   

%% Kill K after evap

if seqdata.flags.mt_kill_K_after_evap
    dispLineStr('Kill K after rf evap',curtime);    
    K_blow_away_time = -15; %1350    

    %open K probe shutter
    setDigitalChannel(calctime(curtime,K_blow_away_time-10),'K Probe/OP shutter',1);
    setAnalogChannel(calctime(curtime,K_blow_away_time-10),'K Probe/OP AM',0.7);
    setDigitalChannel(calctime(curtime,K_blow_away_time-10),'K Probe/OP TTL',1);
    setAnalogChannel(calctime(curtime,K_blow_away_time-10),'K Trap FM',0);

    %pulse beam with TTL
    DigitalPulse(calctime(curtime,K_blow_away_time),'K Probe/OP TTL',15,0);

    %close K probe shutter
    setDigitalChannel(calctime(curtime,K_blow_away_time+15),'K Probe/OP shutter',0);
    %%0=closed, 1=open        
end

%% Ramp down Gradient
% Ramp down the gradient at the end of RF evaporation.  This is useful for
% the following reasons
%
% - Checking for density dependent loss rates (since density propto
% gradient)
% - Checking for adiabaticity of gradient ramps

if seqdata.flags.mt_ramp_down_end 
    tr1 = getVar('mt_ramp_grad_time');
    i1 = getVar('mt_ramp_grad_value');
    
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    dI_QP = i1 - I_QP;    
    
    % Calculate the change in shim currents    
    Cx = -0.0507; % "XSHIM (induces motion along Y lattice dir)    
    defVar('Cy',0.0037);0.0037;
    Cy = getVar('Cy');
    defVar('Cz',0.015);0.014;
    Cz = getVar('Cz');
    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   
    
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,i1);  
    % Ramp the XYZ shims
    AnalogFunc(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(1),I_s(1)+dIx,3); 
    AnalogFunc(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(2),I_s(2)+dIy,4); 
    AnalogFunc(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
        tr1,tr1,I_s(3),I_s(3)+dIz,3);  
    curtime = calctime(curtime,tr1);    
       
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    I_shim = I_s;
end

%% MT Lifetime
if seqdata.flags.mt_lifetime 
%     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON

    th = getVar('mt_hold_time');
    curtime = calctime(curtime,th);
end

end

