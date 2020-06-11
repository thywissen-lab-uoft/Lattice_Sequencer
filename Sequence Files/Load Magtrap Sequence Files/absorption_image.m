%------
%Function call: timeout = absorption_image(timein, image_loc)
%Author: DJ
%Created: Sep 2009
%Summary: This function calls an absorption imaging sequence for a certain
%   image locatin (image_loc = 0 for MOT cell; 1 for science cell). Time of
%   flight is currently defined via seqdata.params.tof.
%------

%Note: curtime is only updated to tof in this code just before the first
%absorption image. Thus, all times before this are referenced to the
%presumed drop time.
function timeout = absorption_image(timein, image_loc)
    
    global seqdata; %Not sure why it is necessary to declare seqdata global at the top of each structure, but should probably stop.
curtime = timein; %Declare the current time reference
    ScopeTriggerPulse(curtime,'Start TOF',0.2); %Trigger the scope right at the start of the TOF
        
    %Populate the relevant structures
    seqdata.times.tof_start = curtime; %Times structure eh... useful? Forms a list of useful time references.
    seqdata.flags.absorption_image = Load_Absorption_Image_Flags();
    seqdata.params.absorption_image = Load_Absorption_Image_Parameters();
    
    %% Override default values for parameters
    
    %RHYS - Some parameters are changed based on special flags being set.
    %Perhaps somewhat confusing to overwrite previously set parameters
    %locally here (e.g. tof set to -2 for in_trap_image even if set to
    %something else previously).
    if seqdata.flags.absorption_image.image_loc==1
        seqdata.params.absorption_image.rb_detuning_shift_time = 50;
    end
    
    if (nargin == 2)
        seqdata.flags.absorption_image.image_loc = image_loc;
    end
    
    if seqdata.flags.absorption_image.High_Field_Imaging==1 %disable the optical pumping during HF imaging
        seqdata.flags.absorption_image.use_K_OP = 0;
    end
    
    if seqdata.flags.absorption_image.In_Trap_imaging %%1: take an image in the magnetic trap
        seqdata.params.absorption_image.tof = -2;
    end
    
    if seqdata.flags.absorption_image.rb_vert_insitu_image
        seqdata.flags.absorption_image.use_K_repump = 0;
        seqdata.flags.absorption_image.use_K_OP = 0;
    end
    
    if ((seqdata.flags.K_RF_sweep == 1 || seqdata.flags.init_K_RF_sweep == 1) && ...
            strcmp(seqdata.flags.absorption_image.image_atomtype,'K'))
        %40K is in a negative mF state, so flip the quantizing shim
        seqdata.flags.absorption_image.negative_imaging_shim = 'negative'; %%% 1: image mF = -9/2 atoms
    end
    
    %% Shorthand for certain parameters and flags
    
    %Shorthand for convenience
    flags = seqdata.flags.absorption_image;
    params = seqdata.params.absorption_image;
    
    %Rhys collect most of the non-nested parameters here for now.
    tof = seqdata.params.tof;
    addOutputParam('tof',tof);
    
    %Get the relevant probe beam power and detuning
    detuning = params.detunings.(flags.image_atomtype).(flags.img_direction) ... 
        .(flags.negative_imaging_shim).(flags.condition);
    
    power = params.powers.(flags.image_atomtype).(flags.img_direction);
    

    %% ABSORPTION IMAGING
    
    %% Pulse QP to do SG imaging (uses up 1st 2ms of ToF)
    %RHYS - Do a special set of magnetic field maninpulations if doing
    %Stern-Gerlach imaging. Basically pulse the QP field in the presence of a
    %vertical bias. Could be its own method or module.
    if (seqdata.flags.absorption_image.do_stern_gerlach)
        
        % Pulse parameters (ramp delays and SG_wait_TOF with respect to tof_start)
        SG_shim_val = [-0.45,+0.1,2]; %[x,y,z] [0,0,2.5] March 16th, 2014 %-0.6 %2
        SG_fesh_val = 0;
        SG_shim_ramptime = 1; %1
        SG_shim_rampdelay = 0; %0 with respect to pulse start
        SG_fesh_ramptime = 1;
        SG_fesh_rampdelay = 0; % with respect to pulse start
        SG_QP_val = 6*1.78;6*1.78;%6*1.78;
        %SG_QP_val = 8*1.78; % 'stretched' pair
        SG_QP_pulsetime = 5;6; %2
        SG_QP_ramptime = 2;1;
        SG_QP_FF = 23*(SG_QP_val/30); % voltage FF on delta supply
        SG_wait_TOF = 1; %4.5 must be longer than FF_rampdelay + FF_ramptime and shim_ramptime + shim_rampdelay
        %SG_wait_TOF = 0; % 'stretched' pair
        
        %     if (seqdata.flags. do_imaging_molasses)
        %        %Need to keep coils off until D1 is finished (15ms before TOF
        %        %starts)
        %        SG_shim_ramptime = 10; %1
        %        SG_shim_rampdelay = -10; %0 with respect to pulse start
        %        SG_fesh_ramptime = 15;
        %        SG_fesh_rampdelay = -10; % with respect to pulse start
        %        SG_wait_TOF = 5.5; %4.5 %0 wait time before doing SG pulse
        %     else
        %     end
        
        % ramp shims to flatten out gradient and set gradient direction
        if (SG_shim_ramptime >= 0)
            AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(1),3);
            AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(2),4);
            AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(3),3);
            
            seqdata.params. shim_val(1) = SG_shim_val(1);
            seqdata.params. shim_val(2) = SG_shim_val(2);
            seqdata.params. shim_val(3) = SG_shim_val(3);
        end
        
        % Turn down the FB field (unless doing imaging at high field).
        if (SG_fesh_ramptime >= 0 && ~seqdata.flags.absorption_image.High_Field_Imaging)
            if SG_fesh_val > 0
                % switch on and ramp to value
                setDigitalChannel(calctime(seqdata.times.tof_start,SG_fesh_rampdelay),'fast FB switch',1);
                if (getChannelValue(seqdata,37,1,1) > 0) % ramp from previous set value
                    AnalogFuncTo(calctime(seqdata.times.tof_start,SG_fesh_rampdelay),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_fesh_ramptime,SG_fesh_ramptime,SG_fesh_val);
                else % force ramp to start from zero
                    AnalogFunc(calctime(seqdata.times.tof_start,SG_fesh_rampdelay),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_fesh_ramptime,SG_fesh_ramptime,0,SG_fesh_val);
                end
            else
                if (getChannelValue(seqdata,37,1,1) > 0) % ramp to zero
                    AnalogFuncTo(calctime(seqdata.times.tof_start,SG_fesh_rampdelay),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_fesh_ramptime,SG_fesh_ramptime,0);
                end
            end
        end
        
        % Ramp up transport supply voltage
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_wait_TOF),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_QP_ramptime,SG_QP_ramptime,SG_QP_FF);
        
        % Ramp up QP
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_wait_TOF),'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_QP_ramptime,SG_QP_ramptime,SG_QP_val);
        
        %     % Step up QP set value
        %     setAnalogChannel(calctime(seqdata.times.tof_start,SG_QP_FF_rampdelay),1,SG_QP_val);
        
        % pulse QP
        DigitalPulse(calctime(seqdata.times.tof_start,SG_wait_TOF), 21, SG_QP_pulsetime, 0); % fast QP
        DigitalPulse(calctime(seqdata.times.tof_start,SG_wait_TOF), 22, SG_QP_pulsetime, 1); % 15/16 switch
        
        % Ramp down transport supply voltage
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime-SG_QP_ramptime),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_QP_ramptime,SG_QP_ramptime,-0.2,1);
        
        % Ramp down QP
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime-SG_QP_ramptime),'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_QP_ramptime,SG_QP_ramptime,0,1);
        
        
        %     % set QP set value and supply voltage to zero (again)
        %     setAnalogChannel(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime),1,0,1);
        %     setAnalogChannel(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime),18,-0.2,1);
        
        % Record QP value for later "shutoff"
        seqdata.params. QP_val = SG_QP_val;
        
    else
        %No SG Pulse
    end
    
    %% Turn on quantizing field for imaging (ST 2014-03-18: made some changes here using AnalogFuncTo)
    %     %Make sure that bipolar shim relay is open
    %     setDigitalChannel(calctime(curtime,-10),'Bipolar Shim Relay',1);
    %RHYS - The set of conditions that determine how to handle field quantization
    %is confusing. Can this be simplified?
    if (seqdata.flags.absorption_image.image_loc == 1) && (~seqdata.flags.absorption_image.In_Trap_imaging) && (seqdata.flags. do_imaging_molasses==2 || seqdata.flags. do_imaging_molasses==0 || (seqdata.flags. do_imaging_molasses==1 && seqdata.flags.absorption_image.do_stern_gerlach))% for an absorption image in science cell
        
        if (seqdata.flags.absorption_image.QP_imaging == 0) % image out of optical trap
            if (seqdata.flags.absorption_image.do_stern_gerlach)
                % delay for quantization field handover (for imaging)
                quant_handover_delay = SG_wait_TOF+SG_QP_pulsetime;
                quant_handover_time = 1; %Give 1ms for quantizing shims to turn on.
                quant_handover_fesh_ramptime = 1;
                quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
            else
                % no traps need to be switched
                quant_handover_fesh_ramptime = 15;  %0
                quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
                quant_handover_time = 15; %RHYSCHANGE Oct 17, 2018 from 30
                quant_handover_delay = -15; %RHYSCHANGE Oct 17, 2018 from -30
            end
            
        elseif (seqdata.flags.absorption_image.QP_imaging == 1) % imaging out of magnetic trap
            % fast handover to quantization field
            quant_handover_delay = min(0,tof-2); % minimum ramp time for shims: ~2ms
            quant_handover_time = 0;
            quant_handover_fesh_ramptime = 0;
            quant_handover_fesh_rampdelay = 0;
        end
        
        if (quant_handover_delay + quant_handover_time > tof)
            buildWarning('absorption_image','Quantization shims are still ramping on during imaging pulse!',1)
        end
        
        if (quant_handover_fesh_ramptime + quant_handover_fesh_rampdelay + quant_handover_delay > tof)
            buildWarning('absorption_image','Quantization ''FB'' field is still ramping on during imaging pulse!')
        end
        
        % to use a perpendicular quantization field
        quant_direction = mod(seqdata.flags.absorption_image.img_direction + seqdata.flags.absorption_image.perp_quant_field - 1, 3) + 1;
        
        % select shim values for respective imaging direction
        if (quant_direction == 1)
            
            quant_shim_val = [0,2.45,0]; % quantization along y Shim (x lattice) %2.45
            
            if seqdata.flags.absorption_image.negative_imaging_shim
                quant_shim_val = [0,-1,0];
                %                 quant_shim_val = [0,-0.5,0];
            end
            
        elseif (quant_direction == 2)
            quant_shim_val = [2.45,0,0]; % quantization along x Shim (y lattice)
            if seqdata.flags.absorption_image.negative_imaging_shim
                quant_shim_val = [-1,0,0];
            end
        elseif (quant_direction == 3)
            quant_shim_val = [0,0,0]; % quantization along z Shim (z lattice) (no waveplates, so leave shim off)
        end
        
        if (seqdata.flags.absorption_image.img_direction == 4)
            quant_shim_val = [0,2,0]; % relic from older days ... needed?
        end
        
        
        if (~seqdata.flags.absorption_image.High_Field_Imaging)
            % start handover to quantization field for imaging
            quant_handover_start = calctime(seqdata.times.tof_start,quant_handover_delay);
            addOutputParam('qqfield1',quant_shim_val(1));
            addOutputParam('qqfield2',quant_shim_val(2));
            addOutputParam('qqfield3',quant_shim_val(3));
            % ramp shims to quantization field values
            AnalogFuncTo(calctime(quant_handover_start,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(1),3);
            AnalogFuncTo(calctime(quant_handover_start,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(2),4);
            AnalogFuncTo(calctime(quant_handover_start,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(3),3);
            
            
            % switch off FB coil if necessary
            if (getChannelValue(seqdata,'FB current',1,0) > 0) && (quant_handover_fesh_ramptime <= 0)
                % hard shut off of FB field
                setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
                setDigitalChannel(calctime(quant_handover_start,0),'fast FB Switch',0); %fast switch
            elseif (getChannelValue(seqdata,'FB current',1,0) > 0) && (quant_handover_fesh_ramptime > 0)
                % ramp FB field
                AnalogFuncTo(calctime(quant_handover_start,quant_handover_fesh_rampdelay),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_fesh_ramptime,quant_handover_fesh_ramptime,0);
                setDigitalChannel(calctime(quant_handover_start,quant_handover_time),'fast FB Switch',0); %fast switch
            else
                % FB field already off ... just to be sure
                setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
                setDigitalChannel(calctime(quant_handover_start,quant_handover_time),'fast FB Switch',0);
            end
            
        end
        
        % eventually set all shims to zero (50ms after image was taken)
        %set FB channel to 0 as well to keep from getting errors in
        %AnalogFuncTo
        setAnalogChannel(calctime(curtime,tof+50),'X Shim',0,3);
        setAnalogChannel(calctime(curtime,tof+50),'Y Shim',0,4);
        setAnalogChannel(calctime(curtime,tof+50),'Z Shim',0,3);
        clear('ramp');
        ramp.fesh_ramptime = 100;%50 %THIS LONG?
        ramp.fesh_ramp_delay = -0;
        ramp.fesh_final = 0;
        ramp.settling_time = 10;
        ramp_bias_fields(calctime(curtime,tof+50), ramp);
        
    elseif (seqdata.flags.absorption_image.image_loc == 0) && (~seqdata.flags.absorption_image.In_Trap_imaging) % MOT cell image
        
        setAnalogChannel(calctime(curtime,0),'Y Shim',3.5,2); %3.5
        % Turn Y shim off 100ms later
        setAnalogChannel(calctime(curtime,100),'Y Shim',0.00,4);
        
    elseif seqdata.flags.absorption_image.In_Trap_imaging
        %No Quantizing Shim
        
        
        % eventually set all shims to zero (50ms after image was taken)
        %set FB channel to 0 as well to keep from getting errors in
        %AnalogFuncTo
        setAnalogChannel(calctime(curtime,tof+50),'X Shim',0,3);
        setAnalogChannel(calctime(curtime,tof+50),'Y Shim',0,4);
        setAnalogChannel(calctime(curtime,tof+50),'Z Shim',0,3);
        setAnalogChannel(calctime(curtime,tof+50),'FB current',0,1);
    end
    
    
    %% Prepare detunings for optional optical pumping and repump pulses, which occur before the first image.
    
    %Before the actual imaging pulse, perform repump and/or optical
    %pumping.
    %RHYS - This section of the code is reasonable, except for again the
    %nexted if statements and local parameters. Add to external file for
    %read in.
    if (~seqdata.flags.absorption_image.High_Field_Imaging)
        if seqdata.flags.absorption_image.use_K_repump
            %Repump pulse: off slightly after optical pumping pulse
            DigitalPulse(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Repump TTL',K_OP_time+0.2,0);
        end
        
        if seqdata.flags.absorption_image.use_K_OP
            ramp_OP_detuning = 0;
            %2.45G shim
            if seqdata.flags.absorption_image.negative_imaging_shim
                k_OP_detuning = 25;
                k_OP_detuning_B = 33;
                addOutputParam('OP_Detuning', k_OP_detuning)
                ramp_OP_detuning = 1;
            else
                k_OP_detuning = 24;
            end
            
            %set probe detuning
            setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Probe/OP FM',190.0); %202.5 for 2G shim
            %SET trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Trap FM',k_OP_detuning); %40 for 2G shim
            %Set AM for Optical Pumping
            setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Probe/OP AM',power);%0.65
            %TTL
            DigitalPulse(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Probe/OP TTL',K_OP_time,1); %0.3
            %Turn off AM
            setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time),'K Probe/OP AM',0,1);%0.65
            if ramp_OP_detuning
                AnalogFuncTo(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),K_OP_time,K_OP_time,k_OP_detuning_B);
            end
            
        end
    end
    
    
    %% Prepare detuning, repump, and probe for the actual image
    addOutputParam('kdet',detuning);
    addOutputParam('rbdet',6590-detuning);
    
    if(~seqdata.flags.absorption_image.High_Field_Imaging)
        %K - Set frequency for imaging just before actual image.
        if strcmp(seqdata.flags.absorption_image.image_atomtype,'K')
            %set probe detuning
            setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Probe/OP FM',180); %195
            %SET trap AOM detuning to change probe
            setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',detuning-20.5);%54.5
        end
        
        %Rb - Set frequency for imaging just before actual image. Need more
        %time to set Rb detuning with offset lock.
        if strcmp(seqdata.flags.absorption_image.image_atomtype,'Rb')
            %offset FF
            if exist('Rb_FF','var')
                setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FF',RB_FF,1); %1.05 %1.15
            else
                setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FF',1.2,1); %1.05 %1.15
            end
            setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time+2200),'Rb Beat Note FF',0.0,1);
            setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FM',detuning);%27 %26 in trap %time is 1.9 %29.6 MHz is resonance (no Q field), 33.4MHz is resonance (with 4G field), 32.4 MHz (with 3G field), found had to change to 27MHz (Aug10)
        end
        
        %RHYS - Why is the TTL commented?
        %K - Set power, make sure probe is TTL'd off before image.
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'K')
            %             setAnalogChannel(calctime(curtime,-1+tof),'K Probe/OP AM',k_probe_pwr); %1
        end

        
        %Rb - Set power, make sure probe is TTL'd off before image.
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'Rb')
            %analog
            setAnalogChannel(calctime(curtime,-5+tof),'Rb Probe/OP AM',power); %.1
        end
        
        %K High Field Imaging
    else
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'K')
            %set trap detuning
            setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',detuning-20.5);%54.5
            
            
            HF_prob_freq_list = [3.6];%3.75
            HF_prob_freq = getScanParameter(HF_prob_freq_list,seqdata.scancycle,seqdata.randcyclelist,'HF_prob_freq')+ 1.4*(seqdata.HF_FeshValue_final-205)/2; %3.75 for 205G;
            mod_freq =  (120+HF_prob_freq)*1E6;
            mod_amp = 1.5;
            mod_offset =0;
            str111=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
            str2=[str111];
            addVISACommand(3, str2);
        end
        
        
    end
    
    
    
    
    %% Pre-Absorption Shutter Preperation
    
    %K - Open shutter for probe. This seems to happen a long long time
    %before the image.
    %RHYS - This is ok, just get rid of blue_image/D1_image and simplify.
    if ~(seqdata.flags.absorption_image.High_Field_Imaging)
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'K')
            %RHYSCHANGE - Try to change timing from -10 to something more reasonable.
            setDigitalChannel(calctime(curtime, -5+tof),'K Probe/OP shutter',1); %-10
            if seqdata.flags.absorption_image.use_K_repump || seqdata.flags.absorption_image.K_repump_during_image
                %Open science cell K repump shutter
                setDigitalChannel(calctime(curtime,-5+tof),'K Sci Repump',1);
                %turn repump back up
                setAnalogChannel(calctime(curtime,-5+tof),25,0.8);
                %repump TTL
                setDigitalChannel(calctime(curtime,-5+tof),7,1);
                %Frequency shift the repump
                if seqdata.flags.absorption_image.negative_imaging_shim
                    k_repump_shift = 21;
                    setAnalogChannel(calctime(curtime,-5+tof),'K Repump FM',k_repump_shift,2);
                else
                    k_repump_shift = 28;%28
                    setAnalogChannel(calctime(curtime,-5+tof),'K Repump FM',k_repump_shift,2);
                end
            end
        end
       
    elseif seqdata.flags.absorption_image.High_Field_Imaging
        %open shutter
        setDigitalChannel(calctime(curtime,-5 + tof),'High Field Shutter',1);
        %Close shutter much later
        setDigitalChannel(calctime(curtime,500),'High Field Shutter',0);
    end
    
    %Rb (Open the shutters just before the imaging pulse)
    if strcmp(seqdata.flags.absorption_image.image_atomtype, 'Rb')
        setDigitalChannel(calctime(curtime,-5+tof),'Rb Probe/OP shutter',1); %-10
        %Rb F1->F2 pulse
        if ( seqdata.flags.absorption_image.do_F1_pulse == 1 )
            
        end
    end
    %% Take 1st probe picture
    
    if ( seqdata.flags.absorption_image.iXon )
        % Clean out trigger for iXON 100ms before image is taken (flush chip)
        DigitalPulse(calctime(curtime,-100),'iXon Trigger',pulse_length,1);
    end
    
    % 1st imaging pulse
    curtime = calctime(curtime,tof);
    
    %RHYS - absorption_image.img_direction == 5???
    if seqdata.flags.absorption_image.img_direction ==5
    else
        do_abs_pulse(curtime,pulse_length,power);
    end
    
    %% Take 2nd probe picture after 1st readout
    
    %100us Camera trigger
    curtime = calctime(curtime,200);%100, 200
    
    %     if seqdata.flags.absorption_image.use_K_OP % why is this one down here and not also up there?
    %         %set probe detuning
    %         setAnalogChannel(calctime(curtime,-9),'K Probe/OP FM',190); %202.5
    %     end
    
    do_abs_pulse(curtime,pulse_length,power);
    
    %% Background Image
    
    %100us Camera trigger
    % DigitalPulse(calctime(curtime,2000),1,.2,1);
    
    %% Turn Probe and Repump off
    
    curtime = calctime(curtime,100);
    
    % %turn_off function knows about atomtype
    %Probe
    turn_off_beam(curtime,4);
    %Repump
    turn_off_beam(curtime,2);
    
    timeout=curtime;
    
    
    %% Absorption pulse function -- triggers cameras and pulses probe/repump
    %RHYS - Not bad, again, remove extraneous conditions, maybe call as a
    %method of an absorption image class.
    function do_abs_pulse(curtime,pulse_length,power)
        
        %This is where the cameras are triggered.
        ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);
        if ( seqdata.flags.absorption_image.iXon )
            DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
        else
            DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
        end
        
        %Rb - Triggers the probe pulses for the actual image.
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'Rb')
            DigitalPulse(curtime,'Rb Probe/OP TTL',pulse_length,0);
            %Rb F1->F2 pulse
            if seqdata.flags.absorption_image.do_F1_pulse == 1
                
                % pulse repump with AOM AM
                setDigitalChannel(calctime(curtime,-5),'Rb Sci Repump',1);%-4
                setAnalogChannel(calctime(curtime,-0.1),'Rb Repump AM',0.3);%0.02 % note: not much repump is needed to see F=1!
                %All switching of the RP pulse is currently done with the shutter. Need TTL off for this AOM to get better timing.
                setAnalogChannel(calctime(curtime,pulse_length),'Rb Repump AM',0);
                setDigitalChannel(calctime(curtime,pulse_length),'Rb Sci Repump',0);
            end
            
        end
        
        %K - Triggers the probe pulses for the actual image.
        if strcmp(seqdata.flags.absorption_image.image_atomtype, 'K')
            
            if ~(seqdata.flags.absorption_image.High_Field_Imaging)
                DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,1);
                %Set AM for Optical Pumping
                setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',power);%0.65
                setAnalogChannel(calctime(curtime,pulse_length),'K Probe/OP AM',0,1);%0.65

            elseif seqdata.flags.absorption_image.High_Field_Imaging
                DigitalPulse(calctime(curtime,0),'K High Field Probe',pulse_length,0);
            end
            
            if seqdata.flags.absorption_image.K_repump_during_image
                %Repump on during the image pulse
                DigitalPulse(curtime,7,pulse_length,0);
            end
            
        end
    end
    
end
