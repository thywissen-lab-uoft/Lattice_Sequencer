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
    global seqdata;
    curtime = timein; 
    ScopeTriggerPulse(curtime,'Start TOF',0.2);
        
    seqdata.times.tof_start = curtime; %Times structure eh... useful?
    
    %Grab these flags from Load_MagTrap_sequence still for now
    if (nargin == 2)
        seqdata.flags.absorption_image.image_loc = image_loc;
    else
        seqdata.flags.absorption_image.image_loc = seqdata.flags.image_loc; %Location of the image: 0 = MOT, 1 = science chamber
    end
    seqdata.flags.absorption_image.image_atomtype = 'K';%seqdata.flags.image_atomtype; %Atom species being imaged: 0 = Rb, 1 = K, 2 = Both
    %Delete the others? %1 = x direction (Sci) / MOT, 2 = y direction (Sci), %3 = vertical direction, 4 = x direc tion (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
    seqdata.flags.absorption_image.img_direction = 'X';%seqdata.flags.img_direction; %Which lattice direction the atoms are imaged in: 1 = x-cam, 2 = y-cam
    seqdata.flags.absorption_image.condition = 'SG';
    seqdata.flags.absorption_image.negative_imaging_shim = 'positive'; %0 = positive states 1 = negative states %Automatically set by K_RF_Sweep flag

    seqdata.flags.absorption_image.do_stern_gerlach = seqdata.flags.do_stern_gerlach; %Whether to pulse the QP coil to split spins during ToF (takes some time,setting minimum ToF): 0 = No SG, 1 = SG
    seqdata.flags.absorption_image.iXon = seqdata.flags.iXon; %Use iXon camera to take an absorption image (only vertical)
    seqdata.flags.absorption_image.do_F1_pulse = seqdata.flags.do_F1_pulse; %Repump Rb F = 1 to F = 2 before/during imaging
    seqdata.flags.absorption_image.In_Trap_imaging = seqdata.flags.In_Trap_imaging; %Take an image in the magnetic trap %Set to take the image while the atoms are still in the magnetic trap
    seqdata.flags.absorption_image.High_Field_Imaging = seqdata.flags.High_Field_Imaging; %Set to image the atoms at a field near the FB resonance (near 202.1G)
    seqdata.flags.absorption_image.rb_vert_insitu_image = seqdata.flags.rb_vert_insitu_image; %Take an absorption image of the BEC up through the system to centre objective.
    seqdata.flags.absorption_image.QP_imaging = seqdata.flags.QP_imaging; %If imaging out of the QP trap, change field ramps to try to reduce eddys.
    
    %These flags were already isolated in absorption_image.
    seqdata.flags.absorption_image.use_K_OP = 1; %Usually useful. Must enable repump as well.
    seqdata.flags.absorption_image.use_K_repump = 1; % 1:turn on K repump beam for imaging F=7/2
    seqdata.flags.absorption_image.K_repump_during_image = 0; %Not sure this is useful.
    seqdata.flags.absorption_image.perp_quant_field = 0; %set to nonzero integer (1) to use a quantization field perpendicular to img_direction    quant_handover_time = 3; % time to ramp shims for imaging ... this may be changed below depending on the selected option
    if seqdata.flags.absorption_image.High_Field_Imaging==0 %disable the optical pumping during HF imaging
        seqdata.flags.absorption_image.use_K_OP = 0;
    end
    %Take an image after short time of flight
    seqdata.flags.absorption_image.short_tof = 0;
    
    %Rhys collect most of the non-nested parameters here for now.
    tof = seqdata.params.tof;
    pulse_length = 0.3;%0.15;
    K_OP_time = 0.3;
    k_detuning_shift_time = 0.5;
    rb_detuning_shift_time = 4;%4
    RB_FF = 1.2;
    if seqdata.flags.absorption_image.image_loc==1
        rb_detuning_shift_time = 50;%100 %7
    end
    
    %What if, instead of 1000 if statements, we made structures like:
    %detuning.K.X.Positive.SG = 52
    %seqdata.params.absorption_image.detuning = 
    
    %What is the point?
    %Set AM Scales
%     if seqdata.flags.absorption_image.image_atomtype == 0
%         k_probe_scale = 0;
%         rb_probe_scale = 1;
%     elseif seqdata.flags.absorption_image.image_atomtype == 1
%         k_probe_scale = 1;
%         rb_probe_scale = 0;
%     elseif seqdata.flags.absorption_image.image_atomtype == 2
%         k_probe_scale = 1;
%         rb_probe_scale = 1;
%     end
%     
    addOutputParam('tof',tof);
    
    %% Special Flags
    %RHYS - Some parameters are changed based on special flags being set.
    %Perhaps somewhat confusing to overwrite previously set parameters
    %locally here (e.g. tof set to -2 for in_trap_image even if set to
    %something else previously).
    if seqdata.flags.absorption_image.In_Trap_imaging %%1: take an image in the magnetic trap
        tof = -2;
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
    
    %What about this:
    detuning.K.X.positive.normal = 42;
    detuning.K.X.positive.in_trap = 44;
    detuning.K.X.positive.QP_imaging = 42;
    detuning.K.X.positive.SG = 45;
    detuning.K.X.positive.short_tof = 45;
    detuning.K.X.negative.normal = 51;
    detuning.K.X.negative.SG = 50;

    detuning.K.Y.positive.normal = 42;
    detuning.K.Y.negative.normal = 52;

    detuning.K.MOT.positive.normal = 41;
    detuning.K.MOT.positive.short_tof = 54.5;

    detuning.Rb.X.positive.normal = 6590 - 238;
    detuning.Rb.X.positive.in_trap = 6590 - 246;
    detuning.Rb.X.positive.QP_imaging = 6590 - 238.5;
    detuning.Rb.X.positive.SG = 6590 - 241.8;

    detuning.Rb.X.negative = 6590 - 232;

    detuning.Rb.Y.positive.normal = 6590 - 230.7;
    detuning.Rb.Y.positive.in_trap = 6590 - 243;

    detuning.Rb.MOT.positive.normal = 6590 - 240;

    detuning = detuning.(seqdata.flags.absorption_image.image_atomtype) ... 
        .(seqdata.flags.absorption_image.img_direction) ... 
        .(seqdata.flags.absorption_image.negative_imaging_shim) ...
        .(seqdata.flags.absorption_image.condition);
    
    power.K.X = 0.09;
    power.K.Y = 0.05;
    power.K.MOT = 0.8;
    power.Rb.X = 0.3;
    power.Rb.Y = 0.25;
    power.Rb.MOT = 0.25;
    
    power = power.(seqdata.flags.absorption_image.image_atomtype) ... 
        .(seqdata.flags.absorption_image.img_direction);
    
%     %% Values for the detunings for all the possible imaging configurations.
%     %RHYS - The long set of detunings/probe powers that follow here based
%     %on nested if statements is a complete mess. Recommend making this a
%     %list in an external text file and just loading the relevant numbers in
%     %based on conditions in one line of code.
%     if seqdata.flags.absorption_image.In_Trap_imaging %%1 : take an image in the magnetic trap
%         
%         %K
%         if (seqdata.atomtype==1  || seqdata.atomtype==4)
%             k_detuning = 44; %54.5
%             k_probe_pwr = k_probe_scale*0.07; %0.15
%         end
%         
%         %Rb
%         if (seqdata.atomtype==3  || seqdata.atomtype==4)
%             rb_detuning = 6590-239.5;   %239.5; %238 %233 %230 %resonance @ 6590-227 %223 %239 %259 %230
%             RB_FF = 1.2; %Added on May 5, 2015 by Rhys for in_trap imaging to work. Is this necessary?
%             if seqdata.flags.absorption_image.img_direction == 1
%                 %Image along long direction (MOT)
%                 rb_detuning = 6590-246; %238.5 (from plugged QP)  before up %234 %feshbach 246 right after load %238 April 13 %240 dylan opt %236 10ms after long evap %241 10ms %238 for short tof %243 for long tof %resonance @ 6590-227
%                 rb_probe_pwr = 0.5*rb_probe_scale; %0.04 %0.2
%             elseif seqdata.flags.absorption_image.img_direction == 2
%                 %Image along y direction
%                 rb_detuning = 6590-243; %237
%                 rb_probe_pwr = 0.25*rb_probe_scale;
%             end
%         end
%         
%         
%     elseif seqdata.flags.absorption_image.image_loc == 0 %MOT Cell  %seqdata.flags.absorption_image.In_Trap_imaging = 0: do not take an image in the magnetic trap
%         
%         %K
%         if (seqdata.atomtype==1  || seqdata.atomtype==4)
%             
%             k_detuning_list = [41]; %45
%             if seqdata.flags.absorption_image.short_tof
%                 %detuning = probe_list(ceil(seqdata.cycle/2));
%                 k_detuning = 54.5;
%             end
%             k_detuning=getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_mot_det');
%             k_probe_pwr = k_probe_scale*0.8; %0.08 %0.3 June 22
%         end
%         
%         %Rb
%         if (seqdata.atomtype==3  || seqdata.atomtype==4)
%             
%             rb_detuning = 6590-240; %resonance @ 6590-220 %236 for resonance
%             rb_probe_pwr = 0.25*rb_probe_scale; %0.07   %0.4  June 22
%         end
%         
%         
%         
%     elseif seqdata.flags.absorption_image.image_loc == 1 %Science Cell
%         
%         %K
%         if (seqdata.atomtype==1  || seqdata.atomtype==4)
%             
%             if seqdata.flags.absorption_image.img_direction == 1
%                 %Image along the x direction
%                 k_detuning_list = [42];[42];%42;  %41.5 good for K after XDT evap (12/08/14) %QP=40.5, XDT=42  40   41
%                 k_detuning=getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'kdet');
%                 k_prob_power_list = [0.09];0.3;
%                 k_prob_power_parameter = getScanParameter(k_prob_power_list,seqdata.scancycle,seqdata.randcyclelist,'kpwr');
%                 k_probe_pwr = k_probe_scale * k_prob_power_parameter; %0.15 on 21/05/15 %0.2  0.22
%                 
%                 if (seqdata.flags.absorption_image.QP_imaging)
%                     %Detune slightly for QP imaging (due to eddy currents)
%                     k_detuning = 42;40;
%                 end
%                 
%                 if seqdata.flags.absorption_image.do_stern_gerlach
%                     %Need to detune a bit for good images after SG pulse
%                     k_detuning = 45;45;40;
%                 end
%                 
%                 if seqdata.flags.absorption_image.negative_imaging_shim
%                     %Smaller frequency because -ve mF states are less
%                     %separate in a field
%                     detuning_list = [51];
%                     %52.2 for negative imaging = 1 and quantizationfield= [0 -1 0]
%                     %50 for negative imaging = 1 and quantizationfield= [0 -0.5 0]
%                     k_detuning = getScanParameter(detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k2_probe_detuning');
%                     %                     k_detuning = 52;%51;% 2016-10-21
%                     k_probe_pwr = k_probe_scale*k_prob_power_parameter; 0.25; %changed on 08/03/2016 from previous value of 0.15 to reduce noise
%                     
%                     if seqdata.flags.absorption_image.do_stern_gerlach
%                         %Need a different detuning to image |9/2,-9/2> after SG?
%                         %Strong eddy currents may still be present for ToF
%                         %< 12ms.
%                         k_detuning_list =[50];[55];%54.5
%                         %54.5 for negative imaging = 1 and quantizationfield= [0 -1 0]
%                         %46 for negative imaging = 1 and quantizationfield= [0 -0.5 0]
%                         k_detuning = getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'SG_k_det');
%                         k_prob_power_parameter = 0.09;
%                         k_probe_pwr = k_probe_scale * k_prob_power_parameter;
%                     end
%                 end
%                 
%             elseif seqdata.flags.absorption_image.img_direction == 2
%                 %Image along the y direction
%                 k_detuning = 42;   %51 if the half-waveplate is left at 5deg (making sigma-minus light?)
%                 k_probe_pwr = k_probe_scale*0.05; %0.40
%                 
%                 if seqdata.flags.absorption_image.negative_imaging_shim
%                     %Smaller frequency because -ve mF states are less
%                     %seperated in a field
%                     k_detuning = 52;
%                     k_probe_pwr = k_probe_scale*0.1;
%                 end
%             end
%             
%         end
%         
%         %Rb
%         if (seqdata.atomtype==3  || seqdata.atomtype==4)
%             if seqdata.flags.absorption_image.img_direction == 1
%                 %Image along long direction (MOT) (currently also: X)
%                 %                 rb_detuning_set(1) = 6590-237.5;  %When Rb Probe AOM is set to -ve order, shift up to F=2->F'=3 transition
%                 %                 rb_detuning_set(2) = 6590+21;    %When Rb Probe AOM is set to +ve order, already close to F=2->F'=3 transition
%                 %
%                 %                 RB_FF_set(1) = 1.2;
%                 %                 RB_FF_set(2) = 0;
%                 %
%                 %                 rb_detuning = rb_detuning_set(seqdata.flags.Rb_Probe_Order);
%                 %                 RB_FF = RB_FF_set(seqdata.flags.Rb_Probe_Order);
%                 
%                 rb_detuning = 6590-238;244;238; 6590-240.5; %238.5
%                 RB_FF = 1.2; %%%%%%%%%%%%%Rb probe detuning here 2017dec
%                 
%                 if (seqdata.flags.absorption_image.QP_imaging)
%                     %Detune slightly for QP imaging (due to eddy current)
%                     rb_detuning = 6590-245+6.5;245;
%                 end
%                 
%                 
%                 if seqdata.flags.absorption_image.do_stern_gerlach
%                     %Need a different detuning to image |9/2,-9/2> after SG?
%                     %Strong eddy currents may still be present for ToF
%                     %< 12ms.
%                     rb_detuning =6590-241.8;
%                     addOutputParam('SG_rb_det',6590-rb_detuning);
%                 end
%                 
%                 
%                 addOutputParam('rb_detuning',6590-rb_detuning);
%                 
%                 if seqdata.flags.absorption_image.negative_imaging_shim % if init_K_RF_sweep==1, seqdata.flags.absorption_image.negative_imaging_shim == 1
%                     %imaging on the |2,-2> -> |3,-3> transition, adjust the
%                     %probe detuning
%                     rb_detuning = 6590-232;232;
%                 end
%                 
%                 rb_probe_pwr = 0.30*rb_probe_scale; %%%%%%%%%%%%%%%%%%%%%%%%%%probe power for Rb abs regular image
%             elseif seqdata.flags.absorption_image.img_direction == 2
%                 %Image along y direction
%                 rb_detuning = 6590-230.7; %237
%                 RB_FF = 1.2;
%                 rb_probe_pwr = 0.25*rb_probe_scale;
%             end            
%         end
%     end
%     
%     if ( seqdata.flags.absorption_image.iXon )
%         rb_probe_pwr = 0.7;
%         pulse_length = 0.6;
%         k_probe_pwr = 0.7;
%     else
%     end
%     
%     addOutputParam('rb_probe_pwr',rb_probe_pwr);
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
