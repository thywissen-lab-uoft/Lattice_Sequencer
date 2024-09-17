function [curtime, I_QP, I_kitt, V_QP, I_fesh, I_shim] = magnetic_trap(curtime)
global seqdata

% "Useful" constants
kHz = 1E3;
MHz = 1E6;
GHz = 1E9;


%% Ramp up QP
if seqdata.flags.mt_compress_after_transport
    dispLineStr('Compression stage after transport to science cell.',curtime);
    % Compression stage after the transport to the science cell
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_trans(curtime, ...
        seqdata.flags.mt_compress_after_transport);
else    
    I_QP =    33;
    I_kitt =    4.0200;
    V_QP =   getVar('RF1a_FF_V');24.8050;
    I_fesh =     0;
    % Get the plug shim values
    I0=seqdata.params.plug_shims;
    Ix=I0(1);Iy=I0(2);Iz=I0(3);
    % Record the starting shim values
    I_shim = [Ix Iy Iz];
end

%% Ramp shims for magnetic trap

if seqdata.flags.mt_ramp_to_plugs_shims
    %Shim Values to Turn On To: 
    % (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
    x_shim_val = seqdata.params.plug_shims(1); %0*1.6
    y_shim_val = seqdata.params.plug_shims(2); %0*0.5
    z_shim_val = seqdata.params.plug_shims(3); %0*0.8

    % Ramp shims to plug values
    AnalogFuncTo(calctime(curtime,0),'Y Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,y_shim_val,4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,x_shim_val,3);
    curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,z_shim_val,3); 
end

%% RF1A
if ( seqdata.flags.RF_evap_stages(1) == 1 )

    % For Rubidium we evaporate on 2-->1
    % |2,2>-->|2,1>=h*f ==> E_atom = 2*h*f
    % Accounting for the factor of two : 1 MHz evaporates 96 uK atoms
    dispLineStr('RF1A',curtime);

    fake_sweep = 0;             % do a fake RF sweep
    hold_time = 100;            % hold time after sweeps
    pre_hold_time =  100;       % Hold time before sweeps
    start_freq = 42;            % Beginning RF1A frequnecy 42 MHz 
    

    defVar('RF1A_freq_0',[42],'MHz');42;36;
    defVar('RF1A_freq_1',28,'MHz');28;28;
    defVar('RF1A_freq_2',20,'MHz');20;20;
    defVar('RF1A_freq_3',getVar('RF1A_finalfreq'),'MHz');
    
    defVar('RF1A_time_1',[6000],'ms');6000;
    defVar('RF1A_time_2',5500,'ms');5500;
    defVar('RF1A_time_3',2000,'ms');2000;
    
    defVar('RF1A_gain_0',-2.05,'arb');
    defVar('RF1A_gain_1',-2.05,'arb');
    defVar('RF1A_gain_2',-2.05,'arb');
    defVar('RF1A_gain_3',-2.05,'arb');

    % Frequency points
    freqs_1 = [start_freq 28 20 getVar('RF1A_finalfreq')]*MHz;
        
    % Gains during each sweep
    RF_gain_1 = 0.5*[-4.1 -4.1 -4.1 -4.1]; 
    
    % Duration of each sweep interval
    sweep_times_1 =[14000 8000 4000].*getVar('RF1A_time_scale');    
    
    freqs_1 = [...
          getVar('RF1A_freq_0') ... 
          getVar('RF1A_freq_1') ...
          getVar('RF1A_freq_2') ...
          getVar('RF1A_freq_3')]*MHz;

    RF_gain_1 = [...
          getVar('RF1A_gain_0') ... 
          getVar('RF1A_gain_1') ...
          getVar('RF1A_gain_2') ...
          getVar('RF1A_gain_3')];

    sweep_times_1 = [...
          getVar('RF1A_time_1') ... 
          getVar('RF1A_time_2') ...
          getVar('RF1A_time_3')].*getVar('RF1A_time_scale');

    
    disp(['     Times        (ms) : ' mat2str(sweep_times_1) ]);
    disp(['     Frequencies (MHz) : ' mat2str(freqs_1*1E-6) ]);
    disp(['     Gains         (V) : ' mat2str(RF_gain_1) ]);

    % Hold before beginning evaporation
    curtime = calctime(curtime,pre_hold_time);

    % Do the RF evaporation
    curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) == 0));
    
    %Including this I_shim definition or else we can't perform only RF1A
    % Get the plug shim values
    I0=seqdata.params.plug_shims;
    Ix=I0(1);Iy=I0(2);Iz=I0(3);
    % Record the starting shim values
    I_shim = [Ix Iy Iz];
    %%%%
    
    t1a_hold = getVar('RF1A_hold_time');
    curtime = calctime(curtime,t1a_hold);
end
    
%% RF1A Alternate : Fast RF for transport benchmark
% This does a fast evaporation to benchmark the transport
% CF : I don't konw what this is for?

if ( seqdata.flags.RF_evap_stages(1) == 2 )
    dispLineStr('Fast RF1A for transport benchmark',curtime);

    fake_sweep = 1;
    hold_time = 100;
    %Jan 2019
    start_freq = 42;%42
    %this worked well with 0.6 kitten
    freqs_1 = [start_freq 10]*MHz; %7.5
    RF_gain_1 = [9]*(5)/9*0.75;%[9]*(5)/9*0.75; %9 9 9
    sweep_times_1 = [15000]; 

    curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) ~= 0));
end

%% Ramp down QP and/or transfer to the window
% Decompress the QP trap and transpor the atoms closer to the window.

%This is only for testing the constituent spins of Rb after the RF1A stage.
%When ramp_wo_transfer flag is on, we do a gradient ramp without
%tansfering the atoms to near the window
ramp_wo_transfer = 0; 
ramp_after_transfer = 0;
if ramp_wo_transfer
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_wo_transfer(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
else
    dispLineStr('Decompressing and tranpsorting.',curtime);
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_before_transfer(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end

MT_wait_list = [0];
MT_wait = getScanParameter(MT_wait_list, seqdata.scancycle,...
        seqdata.randcyclelist, 'MT_wait_afterRF1a','ms');

curtime = calctime(curtime,MT_wait);

if ramp_after_transfer
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_transfer_test(curtime,...
        seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end

%% Turn on Plug Beam
% Turn on the plug beam.  We currently only have a shutter on the plug beam

if  seqdata.flags.mt_use_plug == 1       
    dispLineStr('Turning on the plug',curtime);
    plug_offset = -500; % -200
    ScopeTriggerPulse(calctime(curtime,plug_offset),'Plug');
    setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',1); %0: CLOSED; 1: OPEN
end

ramp_after_plug=0;
if ramp_after_plug
    [curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_transfer_test(curtime, seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
end


%% Evaporation Stage 1b

if ( seqdata.flags.RF_evap_stages(3) == 1 )    
    dispLineStr('RF1B begins.',curtime);    

    freqs_1b = [...
          getVar('RF1B_freq_0') ... 
          getVar('RF1B_freq_1') ...
          getVar('RF1B_freq_2') ...
          getVar('RF1B_freq_3') ...
          getVar('RF1B_freq_4') ...
          getVar('RF1B_freq_5')]*MHz;

    gains = [...
          getVar('RF1B_gain_0') ... 
          getVar('RF1B_gain_1') ...
          getVar('RF1B_gain_2') ...
          getVar('RF1B_gain_3') ...
          getVar('RF1B_gain_4') ...
          getVar('RF1B_gain_5')];

    sweep_times_1b = [...
          getVar('RF1B_time_1') ... 
          getVar('RF1B_time_2') ...
          getVar('RF1B_time_3') ...
          getVar('RF1B_time_4') ...
          getVar('RF1B_time_5')].*getVar('RF1B_time_scale');
      
    currs_1b = [...
          getVar('RF1B_current_0') ... 
          getVar('RF1B_current_1') ...
          getVar('RF1B_current_2') ...
          getVar('RF1B_current_3') ...
          getVar('RF1B_current_4') ...
          getVar('RF1B_current_5')];
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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     ramp_after_1B = 0;
%     if ramp_after_1B
%         % This is useful if you want to check the plug_shim_slopes
%         % (lowering the field gradient should keep the MT field zero
%         % constant if the plug shim slopes are appropriate)
%         dispLineStr('Ramp QP after RF1B',curtime);       
% 
%         [curtime, I_QP, I_kitt, V_QP, I_fesh] = ...
%             ramp_QP_after_transfer_test(curtime, ...
%             seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);
%     end

    
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

%% Ramp Down Plug Power a little bit
if seqdata.flags.mt_plug_ramp_end
    plug_ramp_time = 200;    
    plug_ramp_power_list = [1500];
    plug_ramp_power=getScanParameter(plug_ramp_power_list,...
        seqdata.scancycle,seqdata.randcyclelist,'plug_ramp_power','mA');    
    curtime = AnalogFuncTo(calctime(curtime,0),'Plug',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        plug_ramp_time,plug_ramp_time,plug_ramp_power,3);     
    % Ramp back to full a while later
    AnalogFuncTo(calctime(curtime,2000),'Plug',...
        @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
        plug_ramp_time,plug_ramp_time,2500,3);     
    curtime = calctime(curtime,500);
end

%% Ramp down Gradient
% Ramp down the gradient at the end of RF evaporation.  This is useful for
% the following reasons
%
% - Checking for density dependent loss rates (since density propto
% gradient)
% - Checking for adiabaticity of gradient ramps

if seqdata.flags.mt_ramp_down_end 
    dispLineStr('Ramp down gradient',curtime);    

    tr1 = getVar('mt_ramp_grad_time');
    i1 = getVar('mt_ramp_grad_value');
    
    I_QP = getChannelValue(seqdata,'Coil 16',1);    
    I_s = [0 0 0];
    I_s(1) = getChannelValue(seqdata,'X Shim',1);
    I_s(2) = getChannelValue(seqdata,'Y Shim',1);
    I_s(3) = getChannelValue(seqdata,'Z Shim',1);
    dI_QP = i1 - I_QP;    

    Cx = getVar('mt_shim_slope_x');
    Cy = getVar('mt_shim_slope_y');
    Cz = getVar('mt_shim_slope_z');

    dIx=dI_QP*Cx;
    dIy=dI_QP*Cy;
    dIz=dI_QP*Cz;   
    
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,i1);  
    
    V_QP = i1 * 23/30;        
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,V_QP);  
    
% %     % Ramp the XYZ shims
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
    
%     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON
    curtime = calctime(curtime,30);
    
    
    seqdata.flags.mt_xdt_load2=0;
    seqdata.flags.mt_xdt_load2_qp_off=0;

    if seqdata.flags.mt_xdt_load2

        p1 = getVar('xdt1_load_power');  
        p2 = getVar('xdt2_load_power'); 
        t_xdt = getVar('xdt_load_time');
        defVar('xdt_load_wait_time',200,'ms');
        t_xdt_hold = getVar('xdt_load_wait_time');    

        % Turn on XDT AOMs
        setDigitalChannel(calctime(curtime,-1),'XDT TTL',0);  
        % Ramp ODT1
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap1',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            t_xdt,t_xdt,p1);     
        % Ramp ODT2
        AnalogFuncTo(calctime(curtime,0),'dipoleTrap2',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
            t_xdt,t_xdt,p2);    
        curtime = calctime(curtime,t_xdt);    
        curtime=calctime(curtime,t_xdt_hold);  
        
        if seqdata.flags.mt_xdt_load2_qp_off

                i2 = 0;
                I_s = [0 0 0];
                I_s(1) = getChannelValue(seqdata,'X Shim',1);
                I_s(2) = getChannelValue(seqdata,'Y Shim',1);
                I_s(3) = getChannelValue(seqdata,'Z Shim',1);
                dI_QP = i2 - i1;    

                Cx = getVar('mt_shim_slope_x');
                Cy = getVar('mt_shim_slope_y');
                Cz = getVar('mt_shim_slope_z');

                dIx=dI_QP*Cx;
                dIy=dI_QP*Cy;
                dIz=dI_QP*Cz;   

                % Ramp the QP Current
                AnalogFuncTo(calctime(curtime,0),'Coil 16',...
                    @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
                    tr1,tr1,i2);  

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

            %     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON
                curtime = calctime(curtime,30);


                 curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
                     @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
                     1,1,0); 
        end
    end



end

%% Load 2


%% Ramp  Gradient
% Ramp down the gradient at the end of RF evaporation.  This is useful to
% measure the geometric trap center of the coils

if seqdata.flags.mt_ramp_end 
    dispLineStr('Ramp down gradient',curtime);    

    tr1 = 100;
    defVar('mt_qp_current_ramp',[26],'A');
    i1 = getVar('mt_qp_current_ramp'); 
        
    % Ramp the QP Current
    AnalogFuncTo(calctime(curtime,0),'Coil 16',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,i1);     
    
    V_QP = i1 * 23/30;        
    AnalogFuncTo(calctime(curtime,0),'Transport FF',...
        @(t,tt,y1,y2) ramp_minjerk(t,tt,y1,y2),...
        tr1,tr1,V_QP);  
    curtime = calctime(curtime,tr1);           
    I_QP = getChannelValue(seqdata,'Coil 16',1);   
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON

    curtime = calctime(curtime,50);    
end


%% MT Lifetime
if seqdata.flags.mt_lifetime == 1    
%     setDigitalChannel(calctime(curtime,0),'Plug Shutter',0);% 0:OFF; 1: ON

    th = getVar('mt_hold_time');
    curtime = calctime(curtime,th);
end


%% Post QP Evap Tasks

if ( seqdata.flags.mt_use_plug == 1)       
    hold_time_list = [0];
    hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_QPcoils');
    curtime = calctime(curtime,hold_time);   
    plug_offset = -2.5;%-2.5 for experiment, -10 to align for in trap image

    % Turn off the plug here if you are doing RF1B TOF.
    if (seqdata.flags.xdt ~= 1)
        % Dipole transfer has its own code for turning off the plug after
        % loading the XDTs
        dispLineStr('Closing plug shutter',calctime(curtime,plug_offset));
        setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',0);% 0:OFF; 1: ON
        ScopeTriggerPulse(calctime(curtime,0),'plug test');
    end        
end

end

