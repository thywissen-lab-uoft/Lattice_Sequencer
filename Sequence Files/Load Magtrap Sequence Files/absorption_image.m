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
function timeout=absorption_image(timein, image_loc)

    global seqdata;

    if ( nargin == 2 )
        seqdata.flags.image_loc = image_loc;
    end

curtime = timein;
seqdata.times.tof_start = curtime;

    ScopeTriggerPulse(curtime,'Start TOF',0.2);
    %RHYS - As usual, a number of flags are here. Move to structure in
    %main.
    quant_handover_time = 3; % time to ramp shims for imaging ... this may be changed below depending on the selected option
    perp_quant_field = 0; %set to nonzero integer (1) to use a quantization field perpendicular to img_direction
    
    use_K_OP = 1; %Usually useful. Must enable repump as well.
    use_K_repump = 1; % 1:turn on K repump beam for imaging F=7/2
    use_K_repump_at_low_field = 0;
    K_repump_during_image = 0; %Not sure this is useful. 
    negative_imaging_shim = 0; %0 = positive states 1 = negative states %Automatically set by K_RF_Sweep flag
    
    if seqdata.flags.High_Field_Imaging==0 %disable the optical pumping during HF imaging
        use_K_OP = 0;
    end
       
    tof = seqdata.params.tof;   
    pulse_length = 0.3;%0.15;
    K_OP_time = 0.3;  
    k_detuning_shift_time = 0.5;
    rb_detuning_shift_time = 4;%4
    if seqdata.flags.image_loc==1
        rb_detuning_shift_time = 50;%100 %7
    end
    
    %Set AM Scales
    if seqdata.flags.image_atomtype == 0
        k_probe_scale = 0;
        rb_probe_scale = 1;
    elseif seqdata.flags.image_atomtype == 1
        k_probe_scale = 1;
        rb_probe_scale = 0;
    elseif seqdata.flags.image_atomtype == 2
        k_probe_scale = 1;
        rb_probe_scale = 1;
    end

    %take an image in the magnetic trap
    in_trap_img = seqdata.flags.In_Trap_imaging;
    %Take an image after short time of flight
    short_tof = 0; 
    %Take an in-situ image of the cloud after D1 cooling (need to leave a
    %wait time after the molasses >3ms)
    in_situ_D1 = 0;
%         if seqdata.flags. image_type == 8
%             in_situ_D1 = 1;
%         end
    %Image with 405nm Beam
    blue_image = 0;
    %Image with D1 beam
    D1_image = 0;
    
    addOutputParam('tof',tof); 
  
%% Special Flags
    %RHYS - Some parameters are changed based on special flags being set.
    %Perhaps somewhat confusing to overwrite previously set parameters
    %locally here (e.g. tof set to -2 for in_trap_image even if set to
    %something else previously).
    if in_trap_img %%1: take an image in the magnetic trap
        tof = -2;
    end
    
    if in_situ_D1
        tof = -2;
        %no TOF so can't do repump or OP
%         use_K_repump = 0; 
%         use_K_OP = 0;
        %Do minimal OP to keep from heating
        K_OP_time = 0.5;
        %Can at least repump during image
        K_repump_during_image = 0;
    end
    
    if seqdata.flags.rb_vert_insitu_image
        use_K_repump = 0;
        use_K_OP = 0;
    end
    
    if ((seqdata.flags.K_RF_sweep == 1 || seqdata.flags.init_K_RF_sweep == 1) && seqdata.flags. image_atomtype == 1)
        %40K is in a negative mF state, so flip the quantizing shim
        negative_imaging_shim = 1; %%% 1: image mF = -9/2 atoms
    end  

%% Values for the detunings for all the possible imaging configurations.
    %RHYS - The long set of detunings/probe powers that follow here based
    %on nested if statements is a complete mess. Recommend making this a
    %list in an external text file and just loading the relevant numbers in
    %based on conditions in one line of code.
    if in_trap_img %%1 : take an image in the magnetic trap

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)
            k_detuning = 44; %54.5
            k_probe_pwr = k_probe_scale*0.07; %0.15
        end

        %Rb
        if (seqdata.atomtype==3  || seqdata.atomtype==4)
            rb_detuning = 6590-239.5;   %239.5; %238 %233 %230 %resonance @ 6590-227 %223 %239 %259 %230          
            RB_FF = 1.2; %Added on May 5, 2015 by Rhys for in_trap imaging to work. Is this necessary?
            if seqdata.flags.img_direction == 1
                %Image along long direction (MOT)
                rb_detuning = 6590-246; %238.5 (from plugged QP)  before up %234 %feshbach 246 right after load %238 April 13 %240 dylan opt %236 10ms after long evap %241 10ms %238 for short tof %243 for long tof %resonance @ 6590-227
                rb_probe_pwr = 0.5*rb_probe_scale; %0.04 %0.2
            elseif seqdata.flags.img_direction == 2
                %Image along y direction
                rb_detuning = 6590-243; %237
                rb_probe_pwr = 0.25*rb_probe_scale; 
            elseif seqdata.flags.img_direction == 3
                %Image along z direction
                rb_detuning = 6590-250; %234 for a good QP signal  247 for a good dipole signal
                rb_probe_pwr = 0.9*rb_probe_scale;
            elseif seqdata.flags.img_direction == 4
                %Image along x direction
                rb_detuning = 6590-234; %234 good for ODT, %220 good for QP
                rb_probe_pwr = 0.15*rb_probe_scale; %0.15 %0.15
            end
        end


    elseif seqdata.flags.image_loc == 0 %MOT Cell  %in_trap_img = 0: do not take an image in the magnetic trap

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)

            k_detuning_list = [41]; %45
            if short_tof
                %detuning = probe_list(ceil(seqdata.cycle/2));
                k_detuning = 54.5;
            end   
            k_detuning=getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_mot_det');
            k_probe_pwr = k_probe_scale*0.8; %0.08 %0.3 June 22
        end

        %Rb
        if (seqdata.atomtype==3  || seqdata.atomtype==4)

            rb_detuning = 6590-240; %resonance @ 6590-220 %236 for resonance
            rb_probe_pwr = 0.25*rb_probe_scale; %0.07   %0.4  June 22            
        end



    elseif seqdata.flags.image_loc == 1 %Science Cell

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)

            if seqdata.flags.img_direction == 1
                %Image along the x direction
                k_detuning_list = [42];[42];%42;  %41.5 good for K after XDT evap (12/08/14) %QP=40.5, XDT=42  40   41
                k_detuning=getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'kdet');
                k_prob_power_list = [0.09];0.3;
                k_prob_power_parameter = getScanParameter(k_prob_power_list,seqdata.scancycle,seqdata.randcyclelist,'kpwr');
                k_probe_pwr = k_probe_scale * k_prob_power_parameter; %0.15 on 21/05/15 %0.2  0.22 
                
                if (seqdata.flags.QP_imaging)
                    %Detune slightly for QP imaging (due to eddy currents)
                    k_detuning = 42;40;
                end
                
                if seqdata.flags. do_stern_gerlach
                    %Need to detune a bit for good images after SG pulse
                    k_detuning = 45;45;40;
                end
                
                if in_situ_D1
                    %Different detuning for in_situ image
                    lattice_depth = 400;
                    n_lattices = 1;
                    k_detuning = (42-n_lattices*5*(lattice_depth/400));  %QP=42, XDT=42  40   41
                    k_probe_pwr = 2*k_probe_scale*0.17;  %0.17 %0.2  0.22
                end
                
                if use_K_repump_at_low_field %usually set to 0;
                    %Smaller shift because of lower shim field
                    k_detuning = 46.5;
                end
                
                if negative_imaging_shim
                    %Smaller frequency because -ve mF states are less
                    %separate in a field
                    detuning_list = [51];
                    %52.2 for negative imaging = 1 and quantizationfield= [0 -1 0]
                    %50 for negative imaging = 1 and quantizationfield= [0 -0.5 0]
                    k_detuning = getScanParameter(detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k2_probe_detuning');
%                     k_detuning = 52;%51;% 2016-10-21
                    k_probe_pwr = k_probe_scale*k_prob_power_parameter; 0.25; %changed on 08/03/2016 from previous value of 0.15 to reduce noise                    
                            
                    if seqdata.flags.do_stern_gerlach
                        %Need a different detuning to image |9/2,-9/2> after SG?
                        %Strong eddy currents may still be present for ToF
                        %< 12ms.
                        k_detuning_list =[50];[55];%54.5
                    %54.5 for negative imaging = 1 and quantizationfield= [0 -1 0]
                    %46 for negative imaging = 1 and quantizationfield= [0 -0.5 0]
                        k_detuning = getScanParameter(k_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'SG_k_det');
                        k_prob_power_parameter = 0.09;
                        k_probe_pwr = k_probe_scale * k_prob_power_parameter;
                    end
                end
                
            elseif seqdata.flags.img_direction == 2
                %Image along the y direction
                k_detuning = 42;   %51 if the half-waveplate is left at 5deg (making sigma-minus light?)
                k_probe_pwr = k_probe_scale*0.05; %0.40 
                
                if in_situ_D1
                    %Different detuning for in_situ image
                    k_detuning = 52;  %QP=42, XDT=42  40   41 %07/07/14 - 40 Lattice, 54 1 Lattice Beam. 
                    k_probe_pwr = k_probe_scale*0.1;   %0.2  0.22
                end
                
                if negative_imaging_shim
                    %Smaller frequency because -ve mF states are less
                    %seperated in a field
                    k_detuning = 52;
                    k_probe_pwr = k_probe_scale*0.1;
                end
                
            elseif seqdata.flags.img_direction == 3
                %Image along the z direction
                k_detuning = 41;
                k_probe_pwr = k_probe_scale*0.7;
            elseif seqdata.flags.img_direction == 4
                %Image along the x direction
                k_detuning = 40;
                k_probe_pwr = k_probe_scale*0.2;   %0.2  0.8 April 9
            elseif seqdata.flags.img_direction == 5 %dummy - fluorescence imaging
                %Image along the x direction
                k_detuning = 40;
                k_probe_pwr = k_probe_scale*0.2;   %0.2  0.8 April 9
            end
            if short_tof
                %detuning = probe_list(ceil(seqdata.cycle/2));
                k_detuning = 54.5;
            end        

        end

        %Rb   
        if (seqdata.atomtype==3  || seqdata.atomtype==4)
            if seqdata.flags.img_direction == 1
                %Image along long direction (MOT) (currently also: X)
%                 rb_detuning_set(1) = 6590-237.5;  %When Rb Probe AOM is set to -ve order, shift up to F=2->F'=3 transition
%                 rb_detuning_set(2) = 6590+21;    %When Rb Probe AOM is set to +ve order, already close to F=2->F'=3 transition
%                 
%                 RB_FF_set(1) = 1.2;
%                 RB_FF_set(2) = 0;
%                 
%                 rb_detuning = rb_detuning_set(seqdata.flags.Rb_Probe_Order);
%                 RB_FF = RB_FF_set(seqdata.flags.Rb_Probe_Order);

                rb_detuning = 6590-238;244;238; 6590-240.5; %238.5
                RB_FF = 1.2; %%%%%%%%%%%%%Rb probe detuning here 2017dec
                
                if (seqdata.flags.QP_imaging)
                    %Detune slightly for QP imaging (due to eddy current)
                    rb_detuning = 6590-245+6.5;245;
                end
                
                if in_situ_D1
                    %Different detuning for in_situ image
                    rb_detuning = 6590-236.5;  %QP=42, XDT=42  40   41
                end
                
                if seqdata.flags.do_stern_gerlach
                   %Need a different detuning to image |9/2,-9/2> after SG?
                   %Strong eddy currents may still be present for ToF
                   %< 12ms.
                   rb_detuning =6590-241.8;
                   addOutputParam('SG_rb_det',6590-rb_detuning);
                end
                
                
                addOutputParam('rb_detuning',6590-rb_detuning);
                
                if negative_imaging_shim % if init_K_RF_sweep==1, negative_imaging_shim == 1
                    %imaging on the |2,-2> -> |3,-3> transition, adjust the
                    %probe detuning
                    rb_detuning = 6590-232;232;
                end
                
                rb_probe_pwr = 0.30*rb_probe_scale; %%%%%%%%%%%%%%%%%%%%%%%%%%probe power for Rb abs regular image
            elseif seqdata.flags.img_direction == 2
                %Image along y direction
                rb_detuning = 6590-230.7; %237
                RB_FF = 1.2;
                rb_probe_pwr = 0.25*rb_probe_scale;               
            elseif seqdata.flags.img_direction == 3
                %Image along z direction (don't use shim, so set detuning
                %to free space resonance)
                rb_detuning = 6590-233; %250  255
                RB_FF = 1.2;
                rb_probe_pwr = 0.7*rb_probe_scale;
            elseif seqdata.flags.img_direction == 4
                %Image along x direction
                rb_detuning = 6590-236;
                RB_FF = 1.2;
                rb_probe_pwr = 0.20*rb_probe_scale; %0.15 %0.15
            elseif seqdata.flags.img_direction == 5 %dummy - fluorescence imaging
                %Image along x direction
                rb_detuning = 6590-236;
                RB_FF = 1.2;
                rb_probe_pwr = 0.20*rb_probe_scale; %0.15 %0.15
            end

        end
    end
        
    if blue_image
        %Detuning and power are manually set for now
        
        %Keep D2 beams from turning on
        rb_probe_pwr = 0;
        k_probe_pwr = 0;
    elseif D1_image
        %Keep D2 beams from turning on
        rb_probe_pwr = 0;
        k_probe_pwr = 0;
        
        D1_detuning = 205;
        D1_power = 10;
    else
        
    end
    
    if ( seqdata.flags.iXon )
        rb_probe_pwr = 0.7;
        pulse_length = 0.6;
        k_probe_pwr = 0.7;
    else
    end
         
addOutputParam('rb_probe_pwr',rb_probe_pwr);   
%% ABSORPTION IMAGING
  
%% Pulse QP to do SG imaging (uses up 1st 2ms of ToF)
%RHYS - Do a special set of magnetic field maninpulations if doing
%Stern-Gerlach imaging. Basically pulse the QP field in the presence of a
%vertical bias. Could be its own method or module.
if (seqdata.flags.do_stern_gerlach)

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
    if (SG_fesh_ramptime >= 0 && ~seqdata.flags.High_Field_Imaging)         
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
    if (seqdata.flags.image_loc == 1) && (~in_trap_img) && (~in_situ_D1) && (seqdata.flags. do_imaging_molasses==2 || seqdata.flags. do_imaging_molasses==0 || (seqdata.flags. do_imaging_molasses==1 && seqdata.flags.do_stern_gerlach))% for an absorption image in science cell     
        
        if (seqdata.flags.QP_imaging == 0) % image out of optical trap
            if (seqdata.flags.do_stern_gerlach)
                % delay for quantization field handover (for imaging)
                quant_handover_delay = SG_wait_TOF+SG_QP_pulsetime;
                quant_handover_time = 1; %Give 1ms for quantizing shims to turn on.
                quant_handover_fesh_ramptime = 1;  
                quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
                % quant_handover_delay =
                % max([SG_shim_ramptime+SG_shim_rampdelay,SG_fesh_ramptime+SG_fesh_rampdelay,0])+SG_wait_TOF+SG_QP_pulsetime;             
            elseif (seqdata.flags. do_imaging_molasses || seqdata.flags. lattice_img_molasses)
                %Leave shims off until after TOF has begun
                quant_handover_time = 2;
                quant_handover_delay = 2;
            else
                % no traps need to be switched
                quant_handover_fesh_ramptime = 15;  %0
                quant_handover_fesh_rampdelay = 0;  %Offset from when the shim ramp begins
                quant_handover_time = 15; %RHYSCHANGE Oct 17, 2018 from 30
                quant_handover_delay = -15; %RHYSCHANGE Oct 17, 2018 from -30
            end
            
        elseif (seqdata.flags.QP_imaging == 1) % imaging out of magnetic trap
            % fast handover to quantization field
            quant_handover_delay = min(0,tof-2); % minimum ramp time for shims: ~2ms
            quant_handover_time = 0;
            quant_handover_fesh_ramptime = 0;
            quant_handover_fesh_rampdelay = 0;
        end
        
        % switch off FB field after SG pulse (either there is no time for a ramp or it is already off anyways)
%         if (seqdata.flags.do_stern_gerlach)
%             quant_handover_fesh_ramptime = 0;
%             quant_handover_fesh_rampdelay = 0;
        if (seqdata.flags. do_imaging_molasses || seqdata.flags. lattice_img_molasses)
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
        quant_direction = mod(seqdata.flags.img_direction + perp_quant_field - 1, 3) + 1;
     
        % select shim values for respective imaging direction
        if (quant_direction == 1)
            
            if use_K_repump_at_low_field
                quant_shim_val = [0,0.5,0]; % quantization along y Shim (small value to see all mF states)
            else
                quant_shim_val = [0,2.45,0]; % quantization along y Shim (x lattice) %2.45
            end
            
            if negative_imaging_shim
                quant_shim_val = [0,-1,0];
%                 quant_shim_val = [0,-0.5,0];
            end
             
        elseif (quant_direction == 2)
            quant_shim_val = [2.45,0,0]; % quantization along x Shim (y lattice)
            if negative_imaging_shim
                quant_shim_val = [-1,0,0];
            end
        elseif (quant_direction == 3)
            quant_shim_val = [0,0,0]; % quantization along z Shim (z lattice) (no waveplates, so leave shim off)
        end
        
        if (seqdata.flags.img_direction == 4)
            quant_shim_val = [0,2,0]; % relic from older days ... needed?
        end
        
        if blue_image || D1_image
            %Not sure about the Zeeman shift for 405nm, try no shims for
            %now
            quant_shim_val = [0,0,0];
        end

        if (~seqdata.flags.High_Field_Imaging) 
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
    
    elseif (seqdata.flags.image_loc == 0) && (~in_trap_img) % MOT cell image
        
        setAnalogChannel(calctime(curtime,0),'Y Shim',3.5,2); %3.5
        % Turn Y shim off 100ms later
        setAnalogChannel(calctime(curtime,100),'Y Shim',0.00,4);
        
    elseif (in_situ_D1 || seqdata.flags. do_imaging_molasses==1 || seqdata.flags. do_imaging_molasses==3 )

        if seqdata.flags. in_trap_OP==1 && seqdata.flags. plane_selection_after_D1==0
            %Shim is already ramped up, don't try to ramp again since it
            %may give a timing error
            
            %If plane selection sequence has been run, then all sorts of
            %fields are on that will need to be shut off as below
            
        else
        
            %There is a 15ms wait time after D1 finishes before the trap shuts
            %off, so ramp up the shim during this time

            quant_handover_start = calctime(curtime,-15);
            quant_handover_time = 10;
            if (seqdata.flags.img_direction == 1)   
                quant_shim_val = [0,2.45,0]; % quantization along y Shim (x lattice) %2.45
            elseif (seqdata.flags.img_direction == 2)
                quant_shim_val = [2.45,0,0]; % quantization along x Shim (y lattice)
            elseif (seqdata.flags.img_direction == 3)
                quant_shim_val = [0,0,2]; % quantization along z Shim (z lattice)
            end
            
            if negative_imaging_shim
                if (seqdata.flags.img_direction == 1)
                    quant_shim_val = [0,-1,0];
                elseif (seqdata.flags.img_direction == 2) 
                    quant_shim_val = [-1,0,0];
                end
            end

            quant_handover_fesh_ramptime = 10;

            AnalogFuncTo(calctime(quant_handover_start,-15),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_fesh_ramptime,quant_handover_fesh_ramptime,0);

            % ramp shims to quantization field values 
            AnalogFuncTo(calctime(quant_handover_start,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(1),3);
            AnalogFuncTo(calctime(quant_handover_start,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(2),4);
            AnalogFuncTo(calctime(quant_handover_start,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(3),3);

            % eventually set all shims to zero (50ms after image was taken)
            %set FB channel to 0 as well to keep from getting errors in
            %AnalogFuncTo
            setAnalogChannel(calctime(curtime,tof+50),'X Shim',0,3);
            setAnalogChannel(calctime(curtime,tof+50),'Y Shim',0,4);
            setAnalogChannel(calctime(curtime,tof+50),'Z Shim',0,3);
            setAnalogChannel(calctime(curtime,tof+50),'FB current',0,1);

        end
                    
    elseif in_trap_img
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
if (~seqdata.flags.High_Field_Imaging)
    if use_K_repump
        %Repump pulse: off slightly after optical pumping pulse
        DigitalPulse(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Repump TTL',K_OP_time+0.2,0);
    end
 
    if use_K_OP
        ramp_OP_detuning = 0;
        if seqdata.flags. do_imaging_molasses ~= 0
            %Doing Molasses and need a lot of OP.  Imaging shim is set
            %to 1G and so we need to detune the OP accordingly
            if negative_imaging_shim
                k_OP_detuning = 27; %40
                addOutputParam('OP_Detuning', k_OP_detuning)
            else
                k_OP_detuning = 1;
            end
        else
            %No Molasses, 2.45G shim
            if negative_imaging_shim
                k_OP_detuning = 25;
                k_OP_detuning_B = 33;
                addOutputParam('OP_Detuning', k_OP_detuning)
                ramp_OP_detuning = 1; 
            else
                k_OP_detuning = 24;
            end
        end

        %set probe detuning
        setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Probe/OP FM',190.0); %202.5 for 2G shim
        %SET trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Trap FM',k_OP_detuning); %40 for 2G shim
        %Set AM for Optical Pumping
        setAnalogChannel(calctime(curtime,tof - k_detuning_shift_time - K_OP_time),'K Probe/OP AM',k_probe_pwr);%0.65
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
    addOutputParam('kdet',k_detuning);
    addOutputParam('rbdet',6590-rb_detuning);

if(~seqdata.flags.High_Field_Imaging)
    %K - Set frequency for imaging just before actual image. 
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
        %set probe detuning
        setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Probe/OP FM',180); %195
        %SET trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',k_detuning-20.5);%54.5
    end

    %Rb - Set frequency for imaging just before actual image. Need more
    %time to set Rb detuning with offset lock.
    if (seqdata.atomtype==3  || seqdata.atomtype==4)            
        %offset FF
        if exist('Rb_FF','var')
            setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FF',RB_FF,1); %1.05 %1.15
        else
            setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FF',1.2,1); %1.05 %1.15
        end
          setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time+2200),'Rb Beat Note FF',0.0,1);
          setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FM',rb_detuning);%27 %26 in trap %time is 1.9 %29.6 MHz is resonance (no Q field), 33.4MHz is resonance (with 4G field), 32.4 MHz (with 3G field), found had to change to 27MHz (Aug10)
    end
  
    %RHYS - Blue image and D1 image are never going to be taken again.
    %Delete all references to these.
    %K - Set power, make sure probe is TTL'd off before image.  
    if ~(blue_image || D1_image)
        if (seqdata.atomtype==1  || seqdata.atomtype==4)
%             setAnalogChannel(calctime(curtime,-1+tof),'K Probe/OP AM',k_probe_pwr); %1        
        end
    elseif blue_image
        %image with 405nm
        %keep beam off with TTL
        setDigitalChannel(calctime(curtime,-10),38,0);
    elseif D1_image
        %image with D1 light
        %keep beam off with TTL
        setDigitalChannel(calctime(curtime,-10),35,0);
        
        %Detuning
        setAnalogChannel(calctime(curtime,-10),48,D1_detuning);
        %Power
        setAnalogChannel(calctime(curtime,-10),47,D1_power,1);
    end

    %Rb - Set power, make sure probe is TTL'd off before image. 
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        %analog
        setAnalogChannel(calctime(curtime,-5+tof),'Rb Probe/OP AM',rb_probe_pwr); %.1
    end
    
    %K High Field Imaging  
else
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
    %set trap detuning
    setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',k_detuning-20.5);%54.5 

    
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
    if ~(blue_image || D1_image || seqdata.flags.High_Field_Imaging)
        if (seqdata.atomtype==1  || seqdata.atomtype==4)
            %RHYSCHANGE - Try to change timing from -10 to something more reasonable.
            setDigitalChannel(calctime(curtime, -5+tof),'K Probe/OP shutter',1); %-10
            if use_K_repump || K_repump_during_image
                %Open science cell K repump shutter
                setDigitalChannel(calctime(curtime,-5+tof),'K Sci Repump',1);
                %turn repump back up
                setAnalogChannel(calctime(curtime,-5+tof),25,0.8);
                %repump TTL
                setDigitalChannel(calctime(curtime,-5+tof),7,1);
                %Frequency shift the repump
                if negative_imaging_shim
                    k_repump_shift = 21;
                    setAnalogChannel(calctime(curtime,-5+tof),'K Repump FM',k_repump_shift,2);
                else
                    k_repump_shift = 28;%28
                    setAnalogChannel(calctime(curtime,-5+tof),'K Repump FM',k_repump_shift,2);
                end
            end
        end
    elseif blue_image
        %Open blue shutter
        setDigitalChannel(calctime(curtime,-4 + tof),23,1);
        
        %Close blue shutter
        setDigitalChannel(calctime(curtime,300 + tof),23,0);
        
        %Open Repump Shutter
        setDigitalChannel(calctime(curtime,-10 + tof),3,1);
        %turn repump back up
        setAnalogChannel(calctime(curtime,-10 + tof),25,0.7);
        %repump TTL
        setDigitalChannel(calctime(curtime,-10 + tof),7,1);

    elseif D1_image
        %Open Shutter
        setDigitalChannel(calctime(curtime,-4 + tof),'D1 Shutter',1);
        
        %Close shutter much later
        setDigitalChannel(calctime(curtime,500),'D1 Shutter',0);
        
    elseif seqdata.flags.High_Field_Imaging
        %open shutter
        setDigitalChannel(calctime(curtime,-5 + tof),'High Field Shutter',1);
        %Close shutter much later
        setDigitalChannel(calctime(curtime,500),'High Field Shutter',0);
    end
    
    %Rb (Open the shutters just before the imaging pulse)
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        setDigitalChannel(calctime(curtime,-5+tof),'Rb Probe/OP shutter',1); %-10
        %Rb F1->F2 pulse
            if ( seqdata.flags.do_F1_pulse == 1 )
                
            end        
    end    
%% Take 1st probe picture

    if ( seqdata.flags.iXon )
        % Clean out trigger for iXON 100ms before image is taken (flush chip)
        DigitalPulse(calctime(curtime,-100),'iXon Trigger',pulse_length,1);
    end

    % 1st imaging pulse
curtime = calctime(curtime,tof);

    %RHYS - img_direction == 5???
    if seqdata.flags.img_direction ==5
    else
         do_abs_pulse(curtime,pulse_length,k_probe_pwr);
    end

%% Take 2nd probe picture after 1st readout

    %100us Camera trigger
    curtime = calctime(curtime,200);%100, 200

%     if use_K_OP % why is this one down here and not also up there?
%         %set probe detuning
%         setAnalogChannel(calctime(curtime,-9),'K Probe/OP FM',190); %202.5
%     end
 
     do_abs_pulse(curtime,pulse_length,k_probe_pwr);

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
function do_abs_pulse(curtime,pulse_length,k_probe_pwr)
    
    %This is where the cameras are triggered.
    ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);
    if ( seqdata.flags.iXon )
        DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
    else
        DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
    end

    %Rb - Triggers the probe pulses for the actual image.
    if (seqdata.flags.image_atomtype==0  || seqdata.flags.image_atomtype==2)
        DigitalPulse(curtime,'Rb Probe/OP TTL',pulse_length,0);
        %Rb F1->F2 pulse
        if seqdata.flags.do_F1_pulse == 1
            
            % pulse repump with AOM AM
            setDigitalChannel(calctime(curtime,-5),'Rb Sci Repump',1);%-4
            setAnalogChannel(calctime(curtime,-0.1),'Rb Repump AM',0.3);%0.02 % note: not much repump is needed to see F=1! 
            %All switching of the RP pulse is currently done with the shutter. Need TTL off for this AOM to get better timing.
            setAnalogChannel(calctime(curtime,pulse_length),'Rb Repump AM',0);
            setDigitalChannel(calctime(curtime,pulse_length),'Rb Sci Repump',0);
        end

    end
    
    %K - Triggers the probe pulses for the actual image.
    if (seqdata.flags.image_atomtype==1  || seqdata.flags.image_atomtype==2)
        
        if ~(blue_image || D1_image ||seqdata.flags.High_Field_Imaging)
            DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,1);
            %Set AM for Optical Pumping
            setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',k_probe_pwr);%0.65
            setAnalogChannel(calctime(curtime,pulse_length),'K Probe/OP AM',0,1);%0.65

        elseif blue_image
            DigitalPulse(curtime,'405nm TTL',pulse_length,1);
            DigitalPulse(curtime,7,pulse_length,0);
        elseif D1_image
            DigitalPulse(calctime(curtime,0),35,pulse_length,1);
        elseif seqdata.flags.High_Field_Imaging
            DigitalPulse(calctime(curtime,0),'K High Field Probe',pulse_length,0);
        end
        
        if K_repump_during_image
            %Repump on during the image pulse
            DigitalPulse(curtime,7,pulse_length,0);
        end
        
%RHYS - Remove the comments below.        
        
        %Is it strange that this is here? Could just happen before first
        %image. Everything here is happening back in time. 
%         if use_K_repump
%             %Repump pulse
%             DigitalPulse(calctime(curtime,-0.9 - K_OP_time),7,K_OP_time+1,0); %0.3 (needs to be on until OP finishes)
%         end
% 
%         %Same for this? 
%         if use_K_OP
%             ramp_OP_detuning = 0;
%             if seqdata.flags. do_imaging_molasses ~= 0
%                 %Doing Molasses and need a lot of OP.  Imaging shim is set
%                 %to 1G and so we need to detune the OP accordingly
%                 if negative_imaging_shim
%                     k_OP_detuning = 48; %40
%                     addOutputParam('OP_Detuning', k_OP_detuning)
%                 else
%                     k_OP_detuning = 28;
%                 end
%             else
%                 %No Molasses, 2.45G shim
%                 if negative_imaging_shim
%                     k_OP_detuning = 46;
%                     k_OP_detuning_B = 54;
%                     addOutputParam('OP_Detuning', k_OP_detuning)
%                     ramp_OP_detuning = 1; 
%                 else
%                     k_OP_detuning = 45;
%                 end
%             end
%                         
%             %set probe detuning
%             setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',200.5); %202.5 for 2G shim
%             %SET trap AOM detuning to change probe
%             setAnalogChannel(calctime(curtime,-10),'K Trap FM',k_OP_detuning); %40 for 2G shim
%             %Set AM for Optical Pumping
%             setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',2*k_probe_pwr,1);%0.65
%             %TTL
%             DigitalPulse(calctime(curtime,-0.9 - K_OP_time),'K Probe/OP TTL',K_OP_time,0); %0.3
%             if ramp_OP_detuning
%                 AnalogFuncTo(calctime(curtime,-0.9 - K_OP_time),'K Trap FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),K_OP_time,K_OP_time,k_OP_detuning_B);
%             end
% 
% 
%             %Set AM back for imaging
%             setAnalogChannel(calctime(curtime,-k_detuning_shift_time),'K Probe/OP AM',k_probe_pwr,1);%0.65
%         
%         end
%         
    end
end

end
