function timeout = Prepare_MOT_for_MagTrap(timein)

global seqdata;

curtime = timein;

%% Turn off UV

setDigitalChannel(calctime(curtime,-500),'UV LED',0);

%% cMOT

if seqdata.flags.MOT_CMOT==1
    dispLineStr('CMOT',curtime); 
    cMOT_time = max([getVar('cmot_rb_ramp_time') ...
        getVar('cmot_k_ramp_time')]);

    %%%%%%%%%%%%%%%% Set CMOT Shims %%%%%%%%%%%%%%%%    
%     yshim_comp = 0.84;
%     xshim_comp = 0.25;
%     zshim_comp = 0.00;
    % setAnalogChannel(calctime(curtime,-2),'Y MOT Shim',0.84,2); 
    % setAnalogChannel(calctime(curtime,-2),'X MOT Shim',0.25,2); 
    % setAnalogChannel(calctime(curtime,-2),'Z MOT Shim',0.00,2);

    %%%%%%%%%%%%%%%% CMOT Detuning %%%%%%%%%%%%%%%%    
    f_osc = calcOffsetLockFreq(getVar('cmot_rb_trap_detuning'),'MOT');
    DDS_id = 3; 
    
    switch seqdata.flags.MOT_CMOT_detuning_ramp
        case 1            
            warning('linearly changing cmot detunings CANT DO IT YET');
            
            % K Trap Detuning
            AnalogFuncTo(calctime(curtime,0),'K Trap FM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_k_ramp_time'),getVar('cmot_k_ramp_time'),...
                getVar('cmot_k_trap_detuning'));           
            
            % K Repump Detuning
            AnalogFuncTo(calctime(curtime,0),'K Repump FM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_k_ramp_time'),getVar('cmot_k_ramp_time'),...
                getVar('cmot_k_repump_detuning'),2);    
        case 2
            disp('switching cmot detunings');
            % RbTrap Detuning (cant do Rb repump as of now)
            DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01);   
            
            % K Trap Detuning
            setAnalogChannel(calctime(curtime,0),'K Trap FM',...
                getVar('cmot_k_trap_detuning')); 
            % K Repump Detuning
            setAnalogChannel(calctime(curtime,0),'K Repump FM',...
                getVar('cmot_k_repump_detuning'),2); 
        otherwise
            disp('not changing cmot detunings');
    end
    
    %%%%%%%%%%%%%%%% CMOT Power %%%%%%%%%%%%%%%%    
    switch seqdata.flags.MOT_CMOT_power_ramp
        case 1
            AnalogFuncTo(calctime(curtime,0),'Rb Trap AM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_rb_ramp_time'),getVar('cmot_rb_ramp_time'),...
                getVar('cmot_rb_trap_power'));    
            AnalogFuncTo(calctime(curtime,0),'Rb Repump AM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_rb_ramp_time'),getVar('cmot_rb_ramp_time'),...
                getVar('cmot_rb_repump_power'));               
            AnalogFuncTo(calctime(curtime,0),'K Trap AM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_k_ramp_time'),getVar('cmot_k_ramp_time'),...
                getVar('cmot_k_trap_power'));    
            AnalogFuncTo(calctime(curtime,0),'K Repump AM',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                getVar('cmot_k_ramp_time'),getVar('cmot_k_ramp_time'),...
                getVar('cmot_k_repump_power'));               
        case 2
            setAnalogChannel(calctime(curtime,0),'Rb Trap AM',...
                getVar('cmot_rb_trap_power'));
            setAnalogChannel(calctime(curtime,0),'Rb Repump AM',...
                getVar('cmot_rb_repump_power'));  
            setAnalogChannel(calctime(curtime,0),'K Trap AM',...
                getVar('cmot_k_trap_power')); 
            setAnalogChannel(calctime(curtime,0),'K Repump AM',...
                getVar('cmot_k_repump_power')); 
        otherwise
            disp('not changing cmot power');
            
    end    

    %%%%%%%%%%%%%% Set CMOT Field Gradient %%%%%%%%%%%%%%%%
    switch seqdata.flags.MOT_CMOT_grad_ramp        
        case 1
            AnalogFuncTo(calctime(curtime,0),'MOT Coil',...
                @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
                cMOT_time,cMOT_time,getVar('cmot_grad'));
        case 2
            setAnalogChannel(calctime(curtime,0),'MOT Coil',...
                getVar('cmot_grad'));
        otherwise
            disp('not ramping gradient');
    end          
    
    %%%%%%%%%%%%%% Advance time %%%%%%%%%%%%%%%%
    curtime=calctime(curtime,cMOT_time);   
end
%% Combined Molasses - K D1 GM and Rb D2 Mol
% This code is for running the D1 Grey Molasses for K and the D2 Optical
% Molasses for Rb at the same time from the CMOT phase

if seqdata.flags.MOT_Mol == 1
    dispLineStr('Molasses',curtime);

    %%%%%%%%%%%% Shift the fields %%%%%%%%%%%%
    % Set field gradient and shim values (ideally) to zero

    % Turn off field gradients
    setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);   

    % Set the shims
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0.15,2); %0.15
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',0.15,2); %0.15
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0.00,2); %0.00

    %%%%%%%%%%%% Turn off K D2  %%%%%%%%%%%%
    % Turn off the K D2 light
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);   % (1: OFF)
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); % (1: OFF)

    %%%%%%%%%%%% Rb D2 Molasses Settings %%%%%%%%%%%%

    f_osc = calcOffsetLockFreq(getVar('mol_rb_trap_detuning'),'MOT');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,0),DDS_id,f_osc*1e6,f_osc*1e6,.01);      

    setAnalogChannel(curtime,'Rb Trap AM',getVar('mol_rb_trap_power')); %0.7
    setAnalogChannel(curtime,'Rb Repump AM',getVar('mol_rb_repump_power')); %0.14 

    %%%%%%%%%%%% K D1 GM Settings %%%%%%%%%%%%
    % K D1 GM two photon detuning
    SRS_det_list = [0];%0
    SRS_det = getScanParameter(SRS_det_list,seqdata.scancycle,...
        seqdata.randcyclelist,'GM_SRS_det');

    % K D1 GM two photon sideband power
    SRSpower_list = [4];   %%8
    SRSpower = getScanParameter(SRSpower_list,seqdata.scancycle,...
        seqdata.randcyclelist,'SRSpower');

    % Set the two-photon detuning (SRS)
    SRSAddress = 27; rf_on = 1; SRSfreq = 1285.8+SRS_det;%1285.8
    addGPIBCommand(SRSAddress,...
        sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',...
        SRSfreq,SRSpower,rf_on));

    % K D1 GM double pass (single photon detuning) - shift from 70 MHz
    D1_freq_list = [0];
    D1_freq = getScanParameter(D1_freq_list,seqdata.scancycle,...
        seqdata.randcyclelist,'D1_freq');

    % K D1 GM Double pass - modulation depth
    mod_amp_list = [1.3];
    mod_amp = getScanParameter(mod_amp_list,seqdata.scancycle,...
        seqdata.randcyclelist,'GM_power');

    % Set the single photon detuning (Rigol)
    mod_freq = (70+D1_freq)*1E6;
    mod_offset =0;
    str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
    addVISACommand(3, str);

    % Open the D1 shutter (3 ms pre-trigger for delay)
    setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter',1);

    %%%%%%%%%%%% Total Molasses Time %%%%%%%%%%%%
    % Total Molasses Time
    molasses_time_list = [8];
    molasses_time =getScanParameter(molasses_time_list,seqdata.scancycle,...
        seqdata.randcyclelist,'molasses_time'); 

    %%%%%%%%%%%% advance time during molasses  %%%%%%%%%%%%
    curtime = calctime(curtime,molasses_time);

    % Close the D1 Shutter (3 ms pre-trigger for delay); 
    setDigitalChannel(calctime(curtime,-2.5),'K D1 GM Shutter 2',0); % we have a double shutter on this beam
    setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);     % close this shutter too
end


%% Optical Pumping
% Perform D2 optical pumping.  Could consider implemementing D1 optical
% pumping for K which as a true dark state

if seqdata.flags.MOT_optical_pumping == 1
    %digital trigger
    ScopeTriggerPulse(curtime,'Optical pumping');

    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1);    
    setDigitalChannel(calctime(curtime,-1.8),'Rb Trap Shutter',0); 
    setDigitalChannel(calctime(curtime,-1.8),'K Trap Shutter',0);     
    curtime = optical_pumping(calctime(curtime,0.0));      
end

%% Fluoresnce image
if seqdata.flags.image_type == 1
   curtime = MOT_fluorescence_image(curtime);
end
%% Reset GM Shutters
% CF : Should this be done inside the GM code?

% switich D1 shutters back to original configuration
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter',0);
setDigitalChannel(calctime(curtime,0),'K D1 GM Shutter 2',1);

%% Turn off the repump

% CF : No idea what this does
if ( seqdata.flags.image_type ~= 1 )
%RHYS - These turn on/turn off/turn on-off beam functions are confusing and
%could be rewritten.
curtime = turn_off_beam(calctime(curtime,1),2); %a little delayed w.r.t trap
end

%% The end

timeout = curtime;

end