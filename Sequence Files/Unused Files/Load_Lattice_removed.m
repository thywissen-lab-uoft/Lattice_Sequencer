%% Flags

QP_off_after_load = 0;                  % (607)         keep : Ramp off QP after lattice Load
    load_XY_after_evap = 0;                 % (568)         keep : could be used to evaporate in just z-lattice
    spin_mixture_in_lattice_after_plane_selection = 0; 	% (3290)            keep : maybe use for 2D physics  
    initial_RF_sweep = 0;                               % (3589)            keep (delete?) : Sweep 40K to |9/2,-9/2> before plane selection
    do_raman_optical_pumping = 0;           % ()            unsused 


%% Load X/Y lattices after evaporation.
    %RHYS - If you want to evaporate in just a z-lattice. Test code, this
    %sort of evaporation did not work well.
    
    % CF : Can we delete/move this? This never proved to be useful
    
    if(load_XY_after_evap)
        
%         lat_rampup_depth = 1*[[0.00 0.00 0.00 0.00 0.02 0.02 0.10 0.10 ZLD  ZLD]*100;
%                                 [0.00 0.00 0.00 0.00 0.02 0.02 0.10 0.10 ZLD  ZLD]*100;
%                                 [0.02 0.02 0.10 0.10  ZLD  ZLD  ZLD  ZLD ZLD  ZLD]*100]/atomscale;

        %Load xy.
        lat_rampup_depth = 1*[[0.02 0.02 0.10 0.10 0.4 0.4]*100;
                              [0.02 0.02 0.10 0.10 0.4 0.4]*100;
                              [0.02 0.02 0.10 0.10 0.4 0.4]*100]/atomscale;

        lat_rampup_time = 1*[50,10,50,10,50,10]; 
                      % further lattice rampup segments
            % 1st lattice rampup segment
        AnalogFuncTo(calctime(curtime,0),'xLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(1,1));
        AnalogFuncTo(calctime(curtime,0),'yLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(2,1));
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(1), lat_rampup_time(1), lat_rampup_depth(3,1));
              
        if length(lat_rampup_time) > 1
            for j = 2:length(lat_rampup_time) 
                for k = 1:length(lattices)         
                    if lat_rampup_depth(k,j) ~= lat_rampup_depth(k,j-1) % only do a minjerk ramp if there is a change in depth
                        AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_time(j), lat_rampup_time(j), lat_rampup_depth(k,j));
                    end
                end
curtime = calctime(curtime,lat_rampup_time(j));
            end
        end
    end
    
    
    
   
%% Ramp up/down Gradient
%RHYS - If the lattice is loaded right from the QP, can call this to turn
%the QP trap off, otherwise it will be on until the sequence ends.

% CORA - Can we delete this? Don't see why loading the lattice directly
% from the QP would ever be useful if XDT is working (which we think we
% understand much better now)

if QP_off_after_load
        FB_init = getChannelValue(seqdata,37,1,0);
        clear('ramp');

        ramp.xshim_final = seqdata.params. shim_zero(1);% - 0.144; %-0.144
        ramp.yshim_final = seqdata.params. shim_zero(2);% + 0.34; %0.14
        ramp.zshim_final = seqdata.params. shim_zero(3);
        ramp.shim_ramptime = 50;
        ramp.shim_ramp_delay = -100; % ramp earlier than FB field if FB field is ramped to zero
        addOutputParam('PSelect_xShim',ramp.xshim_final)
        addOutputParam('PSelect_yShim',ramp.yshim_final)

        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -100;
        ramp.fesh_final = 5.2539234;%before 2017-1-6 0.25*22.6; %22.6
        addOutputParam('PSelect_FB',ramp.fesh_final)

        % QP coil settings for spectroscopy
        ramp.QP_ramptime = 50;
        ramp.QP_ramp_delay = -100;
        ramp.QP_final =  0*1.78; %7

        ramp.settling_time = 50; %200

        for i = [7 8 9:17 22:24 20] 
            setAnalogChannel(calctime(curtime,0),i,0,1);
        end
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain

end

%% RF Sweep to |9/2,-9/2>, Sweep 40K to |9/2,-9/2> before plane selection
%RHYS - Usually atoms are already in this state. Could keep this option
%around in case in |9/2,9/2>. Comments elsewhere about generalizing the
%field-ramp/RF/uwave transfer codes apply.

if initial_RF_sweep
    
curtime = AnalogFuncTo(calctime(curtime,0),'zLattice',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), 50, 50, 8*33/atomscale);

    
    %Ramp FB Field
    clear('ramp');
    
    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final =  20.98111; %before 2017-1-6 1*22.6; %22.6
    ramp.settling_time = 100;
    
    % QP coil settings for spectroscopy
    ramp.QP_ramptime = 50;
    ramp.QP_ramp_delay = 0;
    ramp.QP_final =  0*1.78; %7
    
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    
    %Do RF Sweep
    clear('sweep');
    sweep_pars.freq = 6.4; %MHz
    sweep_pars.power = 4.9;
    sweep_pars.delta_freq = -1.00; % end_frequency - start_frequency
    sweep_pars.pulse_length = 40; % also is sweep length
    
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);

    reduce_field = 0;
    if reduce_field
        %Ramp field back down
        clear('ramp');
        
        % FB coil settings for spectroscopy
        ramp.fesh_ramptime = 50;
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 5.2539234;%before 2017-1-6 0.25*22.6; %22.6
        ramp.settling_time = 50;
        
curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    end
   
end  

%% Use Raman/EIT beams to optically pump the atoms.
%RHYS - This should work, but is kind of pointless. Normal D1 optical
%pumping works. Delete?

% CF : What does Raman pump even mean? I think this can be deleted.

if do_raman_optical_pumping
    
     %Define ramp parameters
     xLatDepth = 1100/100; 
     yLatDepth = 1100/100; 
     zLatDepth = 1200/100; 
     
     addOutputParam('xLatDepth',xLatDepth);
     addOutputParam('yLatDepth',yLatDepth);
     addOutputParam('zLatDepth',zLatDepth);
     
     lat_rampup_imaging_depth = [xLatDepth xLatDepth; yLatDepth yLatDepth; zLatDepth zLatDepth]*100/atomscale;  %[100 650 650;100 650 650;100 900 900]
     lat_rampup_imaging_time = [50 10];

    if (length(lat_rampup_imaging_time) ~= size(lat_rampup_imaging_depth,2)) || ...
            (size(lat_rampup_imaging_depth,1)~=length(lattices))
        error('Invalid ramp specification for lattice loading!');
    end
     
    %lattice rampup segments
    for j = 1:length(lat_rampup_imaging_time)
        for k = 1:length(lattices)
            if j==1
                if lat_rampup_imaging_depth(k,j) ~= lat_rampup_depth(k,end) % only do a minjerk ramp if there is a change in depth
                    AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_imaging_time(j), lat_rampup_imaging_time(j), lat_rampup_imaging_depth(k,j));
                end
            else
                if lat_rampup_imaging_depth(k,j) ~= lat_rampup_imaging_depth(k,j-1) % only do a minjerk ramp if there is a change in depth
                    AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_rampup_imaging_time(j), lat_rampup_imaging_time(j), lat_rampup_imaging_depth(k,j));
                end
            end
        end
curtime =   calctime(curtime,lat_rampup_imaging_time(j));
    end
    
    clear('horizontal_plane_select_params')
    F_Pump_List = [0.85];%[0.8:0.2:1.6];%0.8 is optimized for 220 MHz. 1.1 is optimized for 210 MHz.
    horizontal_plane_select_params.F_Pump_Power = getScanParameter(F_Pump_List,seqdata.scancycle,seqdata.randcyclelist,'F_Pump_Power'); %1.4;
    Raman_Power_List = [1.7]; %Do not exceed 2V here. 1.5V is approximately max AOM deflection.
    horizontal_plane_select_params.Raman_Power = getScanParameter(Raman_Power_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_Power'); 
    horizontal_plane_select_params.Fake_Pulse = 0;
    horizontal_plane_select_params.Use_EIT_Beams = 1;
    horizontal_plane_select_params.Selection__Frequency = 1285.8 + 11.025; %11.550
    Raman_List = [0];
    horizontal_plane_select_params.Raman_AOM_Frequency = 110 + getScanParameter(Raman_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_Freq')/1000;
    horizontal_plane_select_params.Rigol_Mode = 'Pulse';
    Range_List = [50];
    horizontal_plane_select_params.Selection_Range = getScanParameter(Range_List,seqdata.scancycle,seqdata.randcyclelist,'Sweep_Range')/1000; %150
    Raman_OP_Time_List = [10];%2000ms for 1 images. [4800]= 2*2000+2*400, 400 is the dead time of EMCCD
    horizontal_plane_select_params.Microwave_Pulse_Length = getScanParameter(Raman_OP_Time_List,seqdata.scancycle,seqdata.randcyclelist,'Raman_OP_Time'); %50
    horizontal_plane_select_params.Fluorescence_Image = 0;
    horizontal_plane_select_params.Num_Frames = 1; % 2 for 2 images
    Modulation_List = [1];
    horizontal_plane_select_params.Modulation_Time = getScanParameter(Modulation_List,seqdata.scancycle,seqdata.randcyclelist,'Modulation_Time');
    horizontal_plane_select_params.Microwave_Or_Raman = 2; 
    horizontal_plane_select_params.Sweep_About_Central_Frequency = 1;
    horizontal_plane_select_params.Resonant_Light_Removal = 0;
    horizontal_plane_select_params.Final_Transfer = 0; 
    horizontal_plane_select_params.SRS_Selection = 0;
    horizontal_plane_select_params.QP_Selection_Gradient = 0;
    %REMOVE SHIM ZERO VALUES HERE - DOUBLE COUNTED.
    horizontal_plane_select_params.X_Shim_Offset = seqdata.params. shim_zero(1);
    horizontal_plane_select_params.Y_Shim_Offset = seqdata.params. shim_zero(2);
    horizontal_plane_select_params.Z_Shim_Offset = 0.05;
    horizontal_plane_select_params.Selection_Angle = 66.5; %-30 for vertical, +60 for horizontal (iXon axes)
    %Kill pulse uses the shim fields for quantization, atom removal may
    %be poor for angles much different from 0deg!!

    %break thermal stabilization by turn off AOM
    setDigitalChannel(calctime(curtime,-10),'D1 OP TTL',0);
        
    ScopeTriggerPulse(curtime,'Raman Beams On');
        
curtime = do_horizontal_plane_selection(curtime, horizontal_plane_select_params);

    %turn on optical pumping beam AOM for thermal stabilization
    setDigitalChannel(calctime(curtime,10),'D1 OP TTL',1);
end
%% Spin mixture after plane selection

%RHYS - Possibly useful but probably not unless making a larger spacing
%z-lattice. Mixture always exists before the lattice these days. But, the
%idea of this is that it enables a mixture to be created after isolating a
%plane, for 2D physics. 
if spin_mixture_in_lattice_after_plane_selection
    %Ramp FB Field
    clear('ramp');
    
    % FB coil settings for spectroscopy
    ramp.fesh_ramptime = 50;
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 20.98111;%before 2017-1-6 1*22.6; %22.6         ~ 20 G
    ramp.settling_time = 100;
    
 curtime = ramp_bias_fields(calctime(curtime,0), ramp);
    %Do RF Sweep
    clear('sweep_pars');
%         sweep_pars.freq = 6.07; %MHz
%         sweep_pars.power = -2;   %-9
%         sweep_pars.delta_freq = +0.05; % end_frequency - start_frequency   0.01
%         sweep_pars.pulse_length = 0.6; % also is sweep length  0.5

    sweep_pars.freq = 6.275; %6.07 MHz
    sweep_pars.power = -1;   %-7.7
    sweep_pars.delta_freq = 0.02; % end_frequency - start_frequency   0.01
    sweep_pars.pulse_length = 0.2; % 20kHz in 0.2ms. also is sweep length  0.5

        
        addOutputParam('RF_Pulse_Length',sweep_pars.pulse_length);
curtime = rf_uwave_spectroscopy(calctime(curtime,0),3,sweep_pars);
% 
        %Multiple sweeps to drive the mixture towards 50/50
curtime = rf_uwave_spectroscopy(calctime(curtime,20),3,sweep_pars);

curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);
% 
curtime = rf_uwave_spectroscopy(calctime(curtime,10),3,sweep_pars);

curtime = calctime(curtime,50);

end

%% uWave single shot spectroscopy

if ( do_singleshot_spectroscopy ) % does an rf pulse or sweep for spectroscopy
        dispLineStr('singleshot_spectroscopy.',curtime);
%     addGPIBCommand(2,sprintf(['FUNC PULS; PULS:PER %g; FUNG:PULS:WIDT %g; VOLT:HIGH 4.5V; VOLT:LOW 0V; BURS:MODE TRIG; BURS:NCYC 1; ' ...
%         'AMPR %gdBm; MODL 1; DISP 2; ENBR
%         %g;'],SRSfreq,SRSmod_dev,SRSpower,rf_on));
curtime = uwave_singleshot_spectroscopy(calctime(curtime,0));
end       
    



%% old lattice_depth_calibration by amplitude modulation using conductivity Rigol?
%RHYS - Another lattice depth calibration code. Might work, not sure if it
%is better than do_lattice_mod.
lattice_depth_calibration = 0;
if lattice_depth_calibration == 1        
        freq_list = [87.5:1:93];freq_list=freq_list*1000;        
        mod_freq = getScanParameter(freq_list,seqdata.scancycle,seqdata.randcyclelist,'lat_mod_freq');
        mod_amp = 0.02;
        mod_time = 1;
        %-------------------------set Rigol DG4162 ---------
        str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,0);
        str112=sprintf(':SOUR1:BURS ON;:SOUR1:BURS:MODE GAT;:SOUR1:BURS:GATE:POL Normal;:SOUR1:BURS:PHAS %f;:OUTP1 ON;',0);
        str2=[str112,str111];
        addVISACommand(2, str2);
        %-------------------------end:set Rigol-------------        
        %ramp the modulation amplitude

        ScopeTriggerPulse(curtime,'band_excitation');
%         setDigitalChannel(curtime,'ScopeTrigger',1);
%         setDigitalChannel(calctime(curtime,10),'ScopeTrigger',0);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',1);
curtime = calctime(curtime,mod_time);
        setDigitalChannel(calctime(curtime,0),'Lattice FM',0);   
end