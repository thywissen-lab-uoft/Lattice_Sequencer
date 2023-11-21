function timeout = main_sequence(timein)
% main_sequence.m

if nargin == 0 
    timein = 0;
else
    curtime = timein;
end

global seqdata

%% Flag Checks

if (seqdata.flags.xdt ~= 0 || seqdata.flags.lattice ~= 0)
    seqdata.flags.QP_imaging = 0;
else
    seqdata.flags.QP_imaging = 1;
end

% Ignore other experimental parts if doing fluoresence imaging. It is
% possilble to "there and back" imaging with transport, but this is very
% rare and can be handled manuualy
if seqdata.flags.image_type == 1
    seqdata.flags.transport                     = 0;
    seqdata.flags.mt                            = 0;
    seqdata.flags.xdt                           = 0;
    seqdata.flags.lattice                       = 0;    
end

% Do not run the demag if you don't make a magnetic trap
if ~seqdata.flags.mt
   seqdata.flags.misc_ramp_fesh_between_cycles = 0;
end

% Do not reset the lattice waveplate if you didn't use it
if ~seqdata.flags.lattice
   seqdata.flags.lattice_reset_waveplate     = 0;
end

% Ignore other experimental parts if doing fluoresence imaging.
if seqdata.flags.image_loc == 0 
    seqdata.flags.mt_use_plug = 0;
    seqdata.flags.mt_compress_after_transport = 0;
    seqdata.flags.RF_evap_stages = [0 0 0];
    seqdata.flags.xdt = 0;
    seqdata.flags.lattice = 0;  
    seqdata.flags.lattice_pulse_for_alignment = 0;
end

%% TOF

seqdata.params.tof = getVar('tof');

%% PA Laser Lock Detuning

if seqdata.flags.misc_lock_PA    
    updatePALock(curtime);    
end

%% Set Objective Piezo Voltages
% Update the objective piezo height

if seqdata.flags.misc_moveObjective
    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',...
        getVarOrdered('objective_piezo'),1);
end
    


%% Gray Molasses
% Why should this be here? Put it in the MOT part of the code?

if seqdata.flags.MOT_programGMDP
    setAnalogChannel(calctime(curtime,0),'D1 FM',getVar('D1_DP_FM'));    
end

%% Initialize Voltage levels
% CF: All of these should be put into some separate reset code
setAnalogChannel(curtime,'15/16 GS',0); 

%Initialize modulation ramp to off.
setAnalogChannel(calctime(curtime,0),'Modulation Ramp',-10,1);

%Initialize the Raman VVA to on.
setAnalogChannel(calctime(curtime,0),'Raman VVA',9.9);

%close all RF and uWave switches
setDigitalChannel(calctime(curtime,0),'RF TTL',0);
setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
setAnalogChannel(calctime(curtime,0),'uWave VVA',10);

%Set both transfer switches back to initial positions
setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);   % 0: RF
setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); % 1: Rb
setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1);  % 0:Anritsu, 1 = Sextupler (unsued?)

%Reset Feschbach coil regulation
setDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);   % Integrator disabled
setDigitalChannel(calctime(curtime,0),'FB offset select',0);    % No offset voltage

%turn off dipole trap beams
setAnalogChannel(calctime(curtime,0),'dipoleTrap1',seqdata.params.ODT_zeros(1));
setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));
setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);

%turn off lattice beams
setAnalogChannel(calctime(curtime,0),'xLattice',-10,1);%-0.1,1);    
setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%-0.1,1);
setAnalogChannel(calctime(curtime,0),'zLattice',-10,1);%-0.1,1);

setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up

%set rotating waveplate back to full dipole power
AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);

%set uWave Generator Selection back to SRS A by default
setDigitalChannel(curtime,'K uWave Source',0);

% Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
CDT_piezo_X = 0;
CDT_piezo_Y = 0;
CDT_piezo_Z = 0;
setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X,1);
setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y,1);
setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z,1);

%Close science cell repump shutter
setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed

%Kill beam AOM on to keep warm.
setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
setDigitalChannel(curtime,'Downwards D2 Shutter',0);

%Pulsed beams on to keep warm.
setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);

%Set Raman AOM TTL to open for AOM to stay warmed up
%Turn off Raman shutter with TTL.
%     setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
setDigitalChannel(calctime(curtime,5),'Raman Shutter',0); %2021/03/30 new shutter

setDigitalChannel(calctime(curtime,0),'Raman TTL 1',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 2',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 2a',1);

setDigitalChannel(calctime(curtime,0),'Raman TTL 3',1);
setDigitalChannel(calctime(curtime,0),'Raman TTL 3a',1);

%Set 'D1' Raman AOMs to open, shutter closed.
setDigitalChannel(calctime(curtime,0),'EIT Probe TTL',1);
setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);

%Set TTL to keep F-pump and mF-pump warm.
setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
setAnalogChannel(calctime(curtime,0),'F Pump',9.99);

%Plug beam
setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
setAnalogChannel(calctime(curtime,0),'Plug',getVar('plugTA_current')); % Current in mA

%High-field imaging
setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);

% Turn on MOT Shim Supply Relay
setDigitalChannel(calctime(curtime,0),'Shim Relay',1);

% Turn off Rigol modulation
addr_mod_xy = 9; % ch1 x mod, ch2 y mod
addr_z = 5; %ch1 z lat, ch2 z mod  
ch_off = struct;
ch_off.STATE = 'OFF';
ch_off.AMPLITUDE = 0;
ch_off.FREQUENCY = 1;

programRigol(addr_mod_xy,ch_off,ch_off);    % Turn off xy mod
programRigol(addr_z,[],ch_off);             % Turn off z mod

%% Load the MOT
curtime = calctime(curtime,1000);

% Rerun load MOT if necessary for controller load
if (seqdata.flags.MOT_load_at_start == 1)
    loadMOTSimple(curtime,1);   
    curtime = calctime(curtime,getVar('MOT_controlled_load_time'));
end   

%% Prepare to Load into the Magnetic Trap
% CF Why are these TTLs switched? Just use the shutter and go back to max
% MOT power?!?

if seqdata.flags.MOT_prepare_for_MT
    dispLineStr('Preparing MOT for MT',curtime);   
    
    % If not a fluoresence image take a picture of the MOT here
    if seqdata.flags.image_type ~= 1    
        DigitalPulse(calctime(curtime,-10),'Mot Camera Trigger',1,1);
    end


    curtime = Prepare_MOT_for_MagTrap(curtime);

    if seqdata.flags.image_type == 0    
        %Open other AOMS to keep them warm. Why ever turn them off for long
        %when we have shutters to do our dirty work?
        setDigitalChannel(calctime(curtime,10),'K Trap TTL',0);
        setAnalogChannel(calctime(curtime,10),'K Trap AM',0.8);

        setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',0);    
        setAnalogChannel(calctime(curtime,10),'Rb Trap AM',0.7);

        setDigitalChannel(calctime(curtime,10),'K Repump TTL',0);
        setAnalogChannel(calctime(curtime,10),'K Repump AM',0.45);

        setAnalogChannel(calctime(curtime,10),'Rb Repump AM',0.9);
        
        % Set Double pass detuning back as well
        % K Trap Detuning
        setAnalogChannel(calctime(curtime,10),'K Trap FM',22);            
        % K Repump Detuning
        setAnalogChannel(calctime(curtime,10),'K Repump FM',0,2);
      setAnalogChannel(calctime(curtime,10),'K Probe/OP FM',180);
    end
end

    
%% Load into Magnetic Trap
% CF : The shims probably should be diabatically switch after loading into
% the magtrap. On the other hand, you don't want to keep atoms in the MOT
% cell for too long due to high vapor pressure

if seqdata.flags.MOT_load_to_MT
    
    yshim2 = 0.25;
    xshim2 = 0.25;
    zshim2 = 0.05;

    %optimize shims for loading into mag trap
    setAnalogChannel(calctime(curtime,0.01),'Y MOT Shim',yshim2,3); %1.25
    setAnalogChannel(calctime(curtime,0.01),'X MOT Shim',xshim2,2); %0.3 
    setAnalogChannel(calctime(curtime,0.01),'Z MOT Shim',zshim2,2); %0.2

    curtime = Load_MagTrap_from_MOT(curtime);

    % CF : This seems bad to me as they will perturb the just loaded MT, I
    % think should this be done adiabatically

    %**Should be set to zero volts to fully turn off the shims (use volt func 1)
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.0,2); %2
else
    
    tramp = 20;    
    tdel = 2000;
    AnalogFuncTo(calctime(curtime,tdel),'X MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(1),2);    
    AnalogFuncTo(calctime(curtime,tdel),'Y MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(2),2);    
    AnalogFuncTo(calctime(curtime,tdel),'Z MOT Shim',...
        @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
        tramp, tramp, seqdata.params.MOT_shim(3),2);       
end

%% Transport 
% Use the CATS to mangetically transport the atoms from the MOT cell to the
% science chamber.

if seqdata.flags.transport
    dispLineStr('Magnetic Transport',curtime);
    % Open kitten relay
    curtime = setDigitalChannel(curtime,'Kitten Relay',1);
    
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
    %Turn Shims to Science cell zero values
    % These can always be set to plug shims because we have separate
    % control of MOT and science chamber shims
    setAnalogChannel(calctime(curtime,1000),'X Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Z Shim',0,3); %3
    setAnalogChannel(calctime(curtime,1000),'Y Shim',0,4); %4

    % Scope trigger
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
    
    tic;
    
    trigger_offset = -200;
    trigger_length = 50;
    
    transport_start_time = calctime(curtime,trigger_offset);
    addOutputParam('transport_start_time',transport_start_time,'ms');
    DigitalPulse(calctime(curtime,trigger_offset-trigger_length),...
        'LabJack Trigger Transport',trigger_length,1);      
    DigitalPulse(calctime(curtime,1000),...
        'LabJack Trigger Transport',trigger_length,1);
    
% curtime = Transport_Cloud(curtime, seqdata.flags.transport_hor_type,...
%         seqdata.flags.transport_ver_type, seqdata.flags.image_loc);
    
    % New Code
    doTransportGS_mode = 0 ;
    doCF = 1;
    if doTransportGS_mode
        curtime = TransportCloud2(curtime);
        [aTraces, ~]=generateTraces(seqdata); 
        [~,ind]=ismember('Coil 15',{aTraces.name});
        a15 = aTraces(ind);
        curlist = linspace(-50,50,1e3);      
        curr2v = aTraces(ind).voltagefunc{5};
        vlist = curr2v(curlist);    
        data_curr = interp1(vlist,curlist,a15.data(:,2));
        ip = length(data_curr)-find(flip(data_curr)>0,1)+1;
        t1 = a15.data(ip,1);t2 = a15.data(ip+1,1);
        i1 = data_curr(ip); i2 = data_curr(ip+1);    
        t0 = interp1([i1 i2],[t1 t2],0);
        t0 = round(t0);
        tout=t0*seqdata.deltat/seqdata.timeunit;
        disp(tout/1e3);    
        defVar('ramp_time_1516',[500],'ms');200;
        tr = getVar('ramp_time_1516');
        AnalogFunc(t0,'15/16 GS',...
            @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
            tr,tr, 0,5.5,1);
    end

    if doCF
        curtime = TransportCloud5(curtime);
    end



%     curtime = transport_round_trip(curtime);
%      
    % CF: This seems like a bad idea to do diabatically.
    setAnalogChannel(calctime(curtime,0),'Coil 12a',0,1);
    setAnalogChannel(calctime(curtime,0),'Coil 12b',0,1);
    setAnalogChannel(calctime(curtime,0),'Coil 13',0,1);
    setAnalogChannel(calctime(curtime,0),'Coil 14',0,1);

    
    t2=toc;
    disp(['Transport cloud calculation took ' num2str(t2) ' seconds']);
    

end

%% MOT Shim back for therml
% Ramp MOT shims back to their steady state value


 

%% Floursence image in MOT Cell
% Perform fluoresence imaging. Comes after transport in case you want to do
% a there and back measurement.

if seqdata.flags.image_type == 1
   curtime = MOT_fluorescence_image(curtime);
end

%% Magnetic Trap

if seqdata.flags.mt
    [curtime, I_QP, I_kitt, V_QP, I_fesh, I_shim] = magnetic_trap(curtime);
end

%% Save Transport and Part of RF

seqdata.flags.transport_save = 1;

if seqdata.flags.transport_save && seqdata.flags.transport
    opts = struct;
    opts.FileName = 'transport.mat';
    opts.StartTime = transport_start_time;
    opts.Duration = 10; % in s
    opts.AnalogChannels = {'Push Coil','MOT Coil',...
        'Coil 3','Coil 4','Coil 5','Coil 6',...
        'Coil 7','Coil 8','Coil 9','Coil 10',...
        'Coil 11','Coil 12a','Coil 12b','Coil 13',...
        'Coil 14','Coil 15','Coil 16','kitten','Transport FF'};
    opts.DigitalChannels = {'MOT TTL','Coil 16 TTL','15/16 Switch','Transport Relay',...
        'Kitten Relay','Reverse QP Switch','LabJack Trigger Transport'};
    opts.FileName = 'magnetic_transport.mat';
    saveTraces(opts)
end    

%% Dipole Trap
%     curtime = xdt_load(curtime);

if ( seqdata.flags.xdt == 1 )
    dispLineStr('Caling dipole_transfer.m',curtime);   
    [curtime, I_QP, V_QP, P_dip, I_shim] = ...
        dipole_transfer(curtime, I_QP, V_QP, I_shim);
    
end

%% Pulse lattice after releasing from trap

if (seqdata.flags.lattice_pulse_for_alignment ~= 0)
    curtime = Pulse_Lattice(curtime,...
        seqdata.flags.lattice_pulse_for_alignment);
end


%% Optical Lattice

if ( seqdata.flags.lattice ~= 0 )
    curtime = Load_Lattice(curtime);
end

%% Pulse Z Lattice after ramping up other lattices to align

if (seqdata.flags.lattice_pulse_z_for_alignment == 1 )
    curtime = Pulse_Lattice(curtime,4);
end

%% Levitation gradient
if seqdata.flags.image_levitate

% QP Value to ramp to
TOF_QP_List =  [0.2];.14;0.115; %set to levitate 
TOF_QP = getScanParameter(TOF_QP_List,seqdata.scancycle,...
seqdata.randcyclelist,'TOF_QPReverse','V');  


% Turn off 15/16 switch
setDigitalChannel(curtime,'15/16 Switch',0); 

curtime = calctime(curtime,10);

% Turn on reverse QP switch
setDigitalChannel(curtime,'Reverse QP Switch',1);
curtime = calctime(curtime,10);

% Ramp up transport supply voltage
QP_FFValue = 23*(TOF_QP/.125/30); % voltage FF on delta supply
curtime = AnalogFuncTo(calctime(curtime,0),'Transport FF',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
    5,5,QP_FFValue);
curtime = calctime(curtime,50);

qp_ramp_time = 5;
curtime = AnalogFuncTo(calctime(curtime,0),'Coil 15',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,TOF_QP,1);

curtime = calctime(curtime,50);

%Ramp back down after image
AnalogFuncTo(calctime(curtime,getVar('tof')+5),'Coil 15',...
         @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),qp_ramp_time,qp_ramp_time,0,1);  

AnalogFuncTo(calctime(curtime,getVar('tof')+5),'Transport FF',...
     @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
         5,5,0);        
             
% Go back to "normal" configuration
%curtime = calctime(curtime,10);
% Turn off reverse QP switch
setDigitalChannel(calctime(curtime,getVar('tof')+15),'Reverse QP Switch',0);
%curtime = calctime(curtime,10);

% Turn on 15/16 switch
setDigitalChannel(calctime(curtime,getVar('tof')+25),'15/16 Switch',1);


end
   

%% Initiate Time of Flight in absorption image

if seqdata.flags.image_type == 0
    dispLineStr('Turning off coils and traps.',curtime);   
    
    % Turn off the MOT (shouldnt it already be off?)
    setAnalogChannel(curtime,'MOT Coil',0,1);
    
    % Turn off all transport Coils (shouldnt it already be off?)
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end   
    
    if ~seqdata.flags.High_Field_Imaging 
        
        if ~seqdata.flags.image_levitate
            % Turn off QP Coils (analog control)    
            setAnalogChannel(calctime(curtime,0),'Coil 15',-1,1);            % C15
            curtime = setAnalogChannel(calctime(curtime,0),'Coil 16',0,1);  % C16
            curtime = setAnalogChannel(curtime,'kitten',-1,1);               % Kitten    
            
          
        end

        % MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
        qp_switch1_delay_time = 0;
        if I_kitt == 0
            %use fast switch
            setDigitalChannel(curtime,'Coil 16 TTL',1); % Turn off Coil 16
            setDigitalChannel(calctime(curtime,500),'Coil 16 TTL',0); % Turn on Coil 16
        else
            %Cannot use Coil 16 fast switch if atoms have not be transferred to
            %imaging direction!
        end
        % Turn off 15/16 switch (10 ms later)
        if ~seqdata.flags.image_stern_gerlach_F && ~seqdata.flags.image_stern_gerlach_mF
            setDigitalChannel(calctime(curtime,qp_switch1_delay_time),'15/16 Switch',0);
            setAnalogChannel(calctime(curtime,qp_switch1_delay_time),'15/16 GS',0);
        end
        
    end
    
%     latt_times = [300];
    
    % Turn off XDT (if they aren't already off)
    if seqdata.flags.xdt        
        % Read XDT Powers right before tof
        P1 = getChannelValue(seqdata,'dipoleTrap1',1);
        P2 = getChannelValue(seqdata,'dipoleTrap2',1);

        addOutputParam('xdt1_final_power',P1,'W');
        addOutputParam('xdt2_final_power',P2,'W');

        % Turn off AOMs 
        setDigitalChannel(calctime(curtime,0),'XDT TTL',1);     %add latt_times+50 for round-trip

        % XDT1 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap1',... 
            seqdata.params.ODT_zeros(1));                       %add latt_times+50 for round-trip
        % XDT2 Power Req. Off
        setAnalogChannel(calctime(curtime,0),'dipoleTrap2',seqdata.params.ODT_zeros(2));    %add latt_times+50 for round-trip
        % I think this channel is unused now
        setDigitalChannel(calctime(curtime,-1),'XDT Direct Control',1);
       
    end          
%         setDigitalChannel(calctime(curtime,0),'XDT TTL',1);     %add latt_times+50 for round-trip

    % Turn off lattices (if they haven't already turned off)
    if seqdata.flags.lattice
        
        % Set Analog Channels to zero lattice depth
        setAnalogChannel(calctime(curtime,0),'xLattice', ...
            seqdata.params.lattice_zero(1));
        setAnalogChannel(calctime(curtime,0),'yLattice', ...
            seqdata.params.lattice_zero(2));
        setAnalogChannel(calctime(curtime,0),'zLattice', ...
            seqdata.params.lattice_zero(3));
        
        %Turn off TTL and disable the integrator
        setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1); 
        setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);        
        
        
        % used for round trip measurements from lattice
%         %  Ramp xLattice to the first value ("0Er")
% %         
%         AnalogFuncTo(calctime(curtime,0),'xLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             latt_times(1), latt_times(1), seqdata.params.lattice_zero(1));
% % 
% %         % Ramp yLattice to the first value ("0Er")
% % 
%         AnalogFuncTo(calctime(curtime,0),'yLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             latt_times(1), latt_times(1), seqdata.params.lattice_zero(2));   
% % 
% %         % Ramp zLattice to the first value ("0Er")
% % 
%         AnalogFuncTo(calctime(curtime,0),'zLattice',...
%             @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), ...
%             latt_times(1), latt_times(1), seqdata.params.lattice_zero(3));   
%             
% %         % Turn off TTL and disable the integrator
%         setDigitalChannel(calctime(curtime,latt_times(1)),'yLatticeOFF',1); 
%         setDigitalChannel(calctime(curtime,latt_times(1)),'Lattice Direct Control',1);  
       
    end 
    
    curtime = calctime(curtime,0);
    
end

%% Absorption Imaging

if seqdata.flags.image_type == 0
    
    ScopeTriggerPulse(calctime(curtime,0),'TOF');
    
    dispLineStr('Absorption Imaging.',curtime);
    curtime = absorption_image2(calctime(curtime,0.0));   
end    
%% Take Background Fluoresence Image

if seqdata.flags.lattice
    
    if (isfield(seqdata.flags,'lattice_fluor') && ...
            isfield(seqdata.flags,'lattice_fluor_bkgd') && ...
            seqdata.flags.lattice_fluor && ...
            seqdata.flags.lattice_fluor_bkgd)
        disp('Running the fluorence imaging code again to take background light');
        
        fluor_opts.doInitialFieldRamp = 0;
        fluor_opts.doInitialFieldRamp2 = 0;
%         curtime = calctime(curtime,500);
        curtime = lattice_FL(curtime, fluor_opts);  
    end
end

%% Post-sequence: rotate diople trap waveplate to default value
if (seqdata.flags.lattice_reset_waveplate == 1)
    %Rotate waveplate to divert all power to dipole traps.
    P_RotWave = 0;
    AnalogFunc(calctime(curtime,0),'latticeWaveplate',...
        @(t,tt,Pmin,Pmax) ...
        (0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),...
        200,200,P_RotWave,0); 
end

%% Demag pulse
if seqdata.flags.misc_ramp_fesh_between_cycles
    if seqdata.flags.High_Field_Imaging
    % This is meant to leave material near the atoms with the same
    % magnetization at the beginning of a new cycle, irrespective whether
    % some strong field was pulsed/snapped off or not during the cycle that
    % just ends. We do not have any positive observation that this helps,
    % but we leave it in just in case (total 1.3s extra).
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
    else 
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
    end
end
    
%% Reset Channels
% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

% Set/Reset Pulses for Remote Field Sensor (after the sensor in the bucket)
curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);

% Reset analog and digital channels (shouldn't this always happen?)
curtime = Reset_Channels(calctime(curtime,0));

%turn on the Raman shutter for frquuency monitoring
% setDigitalChannel(calctime(curtime,0),'Raman Shutter',1);

% keep raman off
setDigitalChannel(calctime(curtime,0),'Raman Shutter',0);

% Set the shim values to zero
setAnalogChannel(calctime(curtime,0),'X Shim',0,1);
setAnalogChannel(calctime(curtime,0),'Y Shim',0,1);
setAnalogChannel(calctime(curtime,0),'Z Shim',0,1);   

setDigitalChannel(calctime(curtime,10),'Bipolar Shim Relay',0);

setAnalogChannel(curtime,'15/16 GS',0); 

%% Load MOT
% Load the MOT
dispLineStr('Load the MOT',curtime);
loadMOTSimple(curtime,0);

% Wait some additional time
if ~seqdata.flags.MOT_load_at_start
    curtime = calctime(curtime,getVar('UV_on_time'));
end

%% Transport Reset

% Reset transport relay (Coil 3 vs Coil 11)
curtime = setDigitalChannel(calctime(curtime,10),'Transport Relay',0);

%% Post-sequence: Pulse the PA laser again for labjack power measurement
if seqdata.flags.misc_calibrate_PA == 1    
   curtime = PA_pulse(curtime,2);     
end
    
%% Scope trigger selection
SelectScopeTrigger(seqdata.scope_trigger);

%% Timeout
timeout = curtime;

% Check if sequence is on for too long
if (((timeout - timein)*(seqdata.deltat/seqdata.timeunit))>120000)
    error('Cycle time greater than 120s! Is this correct?')
end

%% Order Flags and Fields
% For visual purposes.  This sorts the flags by flag_groups while keeping
% the original ordering as defined in the sequence.

flag_groups = {'misc','image','MOT','transport','mt','xdt','lattice'};
flag_names = fieldnames(seqdata.flags);
for kk = 1:length(flag_groups)
    inds = startsWith(flag_names,flag_groups{kk});
    [~,inds] = sort(inds,'ascend');
    flag_names = flag_names(inds);
end
seqdata.flags = orderfields(seqdata.flags,flag_names);

end