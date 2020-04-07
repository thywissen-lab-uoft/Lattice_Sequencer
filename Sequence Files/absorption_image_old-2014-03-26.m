    %------
%Author: DJ
%Created: Sep 2009
%Summary: This function calls an absorption imaging sequence
%------


%%Have recalled this file to the version from Monday March 17th.  Can reset
%%back to the new version by copying from absorption_image_Stefan2014.m

function timeout=absorption_image(timein, image_loc)

    global seqdata;

    if ( nargin == 2 )
        seqdata.flags.image_loc = image_loc;
    end

curtime = timein;
seqdata.times. tof_start = curtime;

    seqdata.flags. iXon = 0; % use iXon camera to take an absorption image (only vertical)
    seqdata.flags. do_F1_pulse = 0; % repump Rb F=1 before/during imaging
    seqdata.flags. QP_imaging = 1; %1= image out of QP, 0=image K out of XDT , 2 = image out of deep lattice with FB already off, 3 = make sure shim are off for D1 molasses

    %Check if FB is on
    if getChannelValue(seqdata,'fast FB Switch',0)
        %FB on, need to handover to shim
        quant_handover_time = 15;
        fesh_ramptime = quant_handover_time; %15 % turning the FB field off (and shim on), e.g. after SG pulse;
        fesh_ramp_delay = -15; %-15 % delay before turning the FB field off (anmd shim on), e.g. after SG pulse; rel. to TOF start
        if seqdata.flags. lattice_stern_gerlach == 1
            fesh_ramptime = 3; %3 for 10ms TOF, 5 for 15ms TOF
            fesh_ramp_delay = 1; %1 for 10ms TOF, 3 for 15ms TOF
        end
    else
        %FB already off, just ramp up shim
        quant_handover_time = 3;
        fesh_ramptime = 0;
        fesh_ramp_delay = 0;
    end
        
        ramp_shims_off = 0; %Ramp the non-imaging shims down to zero rather than snapping off (only works with QP_imaging=0)
    
    
    image_atomtype = 0;  % 0 = Rb, 1 = K, 2 = Rb+K

    img_direction = 1; % 1 = x direction (Sci) / MOT, 2 = y direction (Sci), 3 = vertical direction, 4 = x direction (has been altered ... use 1), 5 = fluorescence

    use_K_repump = 0;
    use_K_OP = 0;
        K_OP_time = 0.9;
       
    
    %     % %list
%     tof_list =[ 5:2:15];
% 
%     %Create linear list
%     %index=seqdata.cycle;
% 
%     %Create Randomized list
%     index=seqdata.randcyclelist(seqdatacycle);
%     tof = tof_list(index);

    tof = 10;
    yShim_min_ramptime = 0;
    
    pulse_length = 0.15;
    
    %Set AM Scales (should this also set TTL and shutter?)
    if image_atomtype == 0
        k_probe_scale = 0;
        rb_probe_scale = 1;
    elseif image_atomtype == 1
        k_probe_scale = 1;
        rb_probe_scale = 0;
    elseif image_atomtype == 2
        k_probe_scale = 1;
        rb_probe_scale = 1;
    end


    %digital trigger after tof
%     DigitalPulse(calctime(curtime,tof),'ScopeTrigger',1,1);

    %take an image in the magnetic trap
    in_trap_img = 0;
    %Take an image after short time of flight
    short_tof=0; 
    %Take an in-situ image of the cloud after D1 cooling (need to leave a
    %wait time after the molasses >3ms)
    in_situ_D1 = 0;
  
    if in_trap_img
        tof = -2;
    end
    
    if in_situ_D1
        tof = -0.2;
        %no TOF so can't do repump or OP
        use_K_repump = 0; 
        use_K_OP = 0;
    end

    addOutputParam('tof',tof); 
    

%% In Trap image

    if in_trap_img

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)
            k_detuning = 53; %54.5
            k_probe_pwr = k_probe_scale*0.4; %0.15
        end

        %Rb
        if (seqdata.atomtype==3  || seqdata.atomtype==4)
            rb_detuning = 6590-239.5; %238 %233 %230 %resonance @ 6590-227 %223 %239 %259 %230
            rb_probe_pwr = rb_probe_scale*0.7; %0.075 for science cell, 0.7 for objective

            if img_direction == 1
                %Image along long direction (MOT)
                rb_detuning = 6590-246; %238.5 (from plugged QP)  before up %234 %feshbach 246 right after load %238 April 13 %240 dylan opt %236 10ms after long evap %241 10ms %238 for short tof %243 for long tof %resonance @ 6590-227
                rb_probe_pwr = rb_probe_scale*0.12; %0.15 %0.2
            elseif img_direction == 2
                %Image along y direction
                rb_detuning = 6590-243; %237
                rb_probe_pwr = rb_probe_scale*0.10; 
            elseif img_direction == 3
                %Image along z direction
                rb_detuning = 6590-250; %234 for a good QP signal  247 for a good dipole signal
                rb_probe_pwr = rb_probe_scale*0.9;
            elseif img_direction == 4
                %Image along x direction
                rb_detuning = 6590-234; %234 good for ODT, %220 good for QP
                rb_probe_pwr = rb_probe_scale*0.15; %0.15 %0.15
            end
        end


    elseif seqdata.flags.image_loc == 0 %MOT Cell

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)

            k_detuning = 43; %45
            if short_tof
                %detuning = probe_list(ceil(seqdata.cycle/2));
                k_detuning = 54.5;
            end   

            k_probe_pwr = k_probe_scale*0.4; %0.07 %0.3 June 22
        end

        %Rb
        if (seqdata.atomtype==3  || seqdata.atomtype==4)

            rb_detuning = 6590-236; %resonance @ 6590-220 %236 for resonance
            rb_probe_pwr = rb_probe_scale*0.4; %0.07   %0.4  June 22            
        end



    elseif seqdata.flags.image_loc == 1 %Science Cell

        %K
        if (seqdata.atomtype==1  || seqdata.atomtype==4)


            %addOutputParam('k_detuning', k_detuning); 

            if img_direction == 1
                %Image along the long direction
                k_detuning = 42;  %QP=42, XDT=42  40   41
                k_probe_pwr = k_probe_scale*0.17;   %0.2  0.22 
                
                if seqdata.flags. QP_imaging == 3
                    %Doing D1 cooling, so use smaller quantizing field
                    k_detuning = 44;  %QP=42, XDT=42  40   41
                    k_probe_pwr = k_probe_scale*0.17;   %0.2  0.22
                    
                    if in_situ_D1
                        %Different detuning for in_situ image
                        k_detuning = 38.5;  %QP=42, XDT=42  40   41
                        k_probe_pwr = k_probe_scale*0.17;   %0.2  0.22
                    end
                end
            elseif img_direction == 2
                %Image along the y direction
                k_detuning = 40;
                k_probe_pwr = k_probe_scale*0.65; %0.22
            elseif img_direction == 3
                %Image along the z direction
                k_detuning = 41;
                k_probe_pwr = k_probe_scale*0.7;
            elseif img_direction == 4
                %Image along the x direction
                k_detuning = 40;
                k_probe_pwr = k_probe_scale*0.2;   %0.2  0.8 April 9
            elseif img_direction == 5 %dummy - fluorescence imaging
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
            if img_direction == 1
                %Image along long direction (MOT) (currently also: X)
                rb_detuning = 6590-239; %243 QP
                    %Bipolar supply (y) - 242.5, Shimmer - 241
                    %May 31 241 QP, 242 XDT
                rb_probe_pwr = rb_probe_scale*0.08; %0.15 %0.2 0.12 May 27th
            elseif img_direction == 2
                %Image along y direction
                rb_detuning = 6590-238.5; %237
                rb_probe_pwr = rb_probe_scale*0.15; 
            elseif img_direction == 3
                %Image along z direction
                rb_detuning = 6590-255; %250  255
                rb_probe_pwr = rb_probe_scale*0.02;
            elseif img_direction == 4
                %Image along x direction
                rb_detuning = 6590-236;
                rb_probe_pwr = rb_probe_scale*0.20; %0.15 %0.15
            elseif img_direction == 5 %dummy - fluorescence imaging
                %Image along x direction
                rb_detuning = 6590-236;
                rb_probe_pwr = rb_probe_scale*0.20; %0.15 %0.15
            end

        end

    else
        error('Invalid absorption imaging settings');
    end

   

%% ABSORPTION IMAGING

%% Pre-Absorption Shutter Preperation
    %Open Probe Shutter
    %K
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
        setDigitalChannel(calctime(curtime,-10),'K Probe/OP shutter',1); %-10
        if use_K_repump
            %Open Repump Shutter
            setDigitalChannel(calctime(curtime,-10),3,1);  
            %turn repump back up
            setAnalogChannel(calctime(curtime,-10),25,0.7);
            %repump TTL
            setDigitalChannel(calctime(curtime,-10),7,1); 
        end
    end
    %Rb
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        setDigitalChannel(calctime(curtime,-10),'Rb Probe/OP shutter',1); %-10
        %Rb F1->F2 pulse
            if ( seqdata.flags.do_F1_pulse == 1 )
                setDigitalChannel(calctime(curtime,-10),'Rb Repump Shutter',1); %-10
            end
        
    end

%% Pulse QP to do SG imaging (uses up 1st 2.5ms of ToF)

if seqdata.flags. lattice_stern_gerlach == 2
%     %Pre-ramp shims
%     SG_shim_vals=[0,0,2];
%     AnalogFuncTo(calctime(seqdata.times.tof_start,-10),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),10,10,SG_shim_vals(1),3);
%     AnalogFuncTo(calctime(seqdata.times.tof_start,-10),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),10,10,SG_shim_vals(2),4);
%     AnalogFuncTo(calctime(seqdata.times.tof_start,-10),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),10,10,SG_shim_vals(3),3);
    
    
    % Pulse parameters (ramp delays and SG_wait_TOF with respect to tof_start)
    SG_shim_val = [2.5,0,0]; %[x,y,z] [0,0,2.5] March 16th, 2014
    SG_fesh_val = 0;
    SG_shim_ramptime = 5; %1
    SG_shim_rampdelay = -7; %0
    SG_fesh_ramptime = -1; 
    SG_fesh_rampdelay = -10;
    SG_QP_val = 8*1.78;
    SG_QP_pulsetime = 2;
    SG_QP_FF_rampdelay = -10;
    SG_QP_FF_ramptime = 5;
    SG_QP_FF = 23*(SG_QP_val/30);
    SG_wait_TOF = 0; %1

    % ramp shims to flatten out gradient and set gradient direction
    if (SG_shim_ramptime >= 0)
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(1),3);
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(2),4);
        AnalogFuncTo(calctime(seqdata.times.tof_start,SG_shim_rampdelay),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_shim_ramptime,SG_shim_ramptime,SG_shim_val(3),3);
    end
    
    if (SG_fesh_ramptime >= 0)
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
            % switch off and set potentially negative channel value
            setDigitalChannel(calctime(seqdata.times.tof_start,SG_fesh_rampdelay+SG_fesh_ramptime),'fast FB switch',0);
            setAnalogChannel(calctime(seqdata.times.tof_start,SG_fesh_rampdelay+SG_fesh_ramptime),37,SQ_fesh_val);
        end
    end
    
    % Ramp up transport supply voltage
    AnalogFuncTo(calctime(seqdata.times.tof_start,SG_QP_FF_rampdelay),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),SG_QP_FF_ramptime,SG_QP_FF_ramptime,SG_QP_FF);
    
    % Step up QP set value
    setAnalogChannel(calctime(seqdata.times.tof_start,SG_QP_FF_rampdelay),1,SG_QP_val);
    
    % pulse QP
    DigitalPulse(calctime(seqdata.times.tof_start,SG_wait_TOF), 21, SG_QP_pulsetime, 0); % fast QP
    DigitalPulse(calctime(seqdata.times.tof_start,SG_wait_TOF), 22, SG_QP_pulsetime, 1); % 15/16 switch

    % set QP set value and supply voltage to zero (again)
    setAnalogChannel(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime),1,0,1);
    AnalogFuncTo(calctime(seqdata.times.tof_start,SG_wait_TOF+SG_QP_pulsetime),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),5,5,0);

    % Record QP value for later "shutoff"
    seqdata.params. QP_val = SG_QP_val;
        
    % delay for quantization field handover (for imaging)
    quant_shim_delay = SG_shim_ramptime+SG_QP_pulsetime;  
    
else
    %No QP Pulse
    quant_shim_delay=0;
end
    
%% Turn on quantizing field
    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
    
    %Make sure that bipolar shim relay is open
    setDigitalChannel(calctime(curtime,-10),'Bipolar Shim Relay',1);

    if img_direction == 1
        %Imaging along the y direction, in the Science chamber or the MOT

        %turn the Y (quantizing) shim on after magnetic trapping
        if ~in_trap_img
            if seqdata.flags.image_loc == 0; %MOT cell
                setAnalogChannel(calctime(curtime,0),'Y Shim',3.5,2); %3.5
            elseif seqdata.flags.image_loc == 1; %Science cell
                    if ( seqdata.flags.QP_imaging == 1 );
                        %setAnalogChannel(calctime(curtime,0),'Y Shim',3.5/1.75,2);%3.5 (div by 2 because of Helmholtz) BIPOLAR SHIM SUPPLY CHANGE
                        setAnalogChannel(calctime(curtime,min(0,tof-yShim_min_ramptime)),'Y Shim',2.45,4);%3.5 (div by 2 because of Helmholtz) BIPOLAR SHIM SUPPLY CHANGE
                        %setAnalogChannel(calctime(curtime,tof-3),'Y Shim',2.45,4);
                        %setAnalogChannel(calctime(curtime,min(0,tof-yShim_min_ramptime)),'Y Shim',3.5/1.75,2);
                        SetDigitalChannel(calctime(curtime,0),'fast FB Switch',0); %fast switch
                        setAnalogChannel(calctime(curtime,0),'FB current',-0.1,1);%0

                    elseif ( seqdata.flags.QP_imaging == 0 );

                        
                        %Read in current shim value
                        y_shim_init = seqdata.params. yshim_val;
                        AnalogFunc(calctime(curtime,fesh_ramp_delay+quant_shim_delay),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),quant_handover_time,quant_handover_time,2,y_shim_init,4);

                        %Read in the current setting of the Feshbach coil
                        feshbach_current = seqdata.params. feshbach_val;

                        %Ramp off Feshbach
                        ramp_fesh_slowly = 1;
                        if ramp_fesh_slowly == 0;
                        %set Feshbach field to 0
                            SetDigitalChannel(calctime(curtime,max([0,fesh_ramp_delay])),'fast FB Switch',0); %fast switch
                            setAnalogChannel(calctime(curtime,max([0,fesh_ramp_delay])),'FB current',-0.1,1);%0
                        elseif ramp_fesh_slowly == 1;
                            %fesh_ramptime = 15;
                            SetDigitalChannel(calctime(curtime,fesh_ramp_delay+fesh_ramptime),'fast FB Switch',0); %fast switch
                            AnalogFunc(calctime(curtime,fesh_ramp_delay),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_ramptime,fesh_ramptime,0,feshbach_current);
                            setAnalogChannel(calctime(curtime,fesh_ramp_delay+fesh_ramptime),'FB current',-0.1,1);
                        end

                    elseif seqdata.flags.QP_imaging ==2;
                        AnalogFunc(calctime(curtime,-8),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),8,8,2,0,4);
                        %AnalogFunc(calctime(curtime,-fesh_ramptime+0),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1*fesh_ramptime,1*fesh_ramptime,2,0);                   
                    
                    elseif seqdata.flags.QP_imaging ==3;

                        if in_situ_D1 == 1
                            %Don't do OP or repumping for in_situ image, so
                            %can ramp the shim on faster
                            AnalogFunc(calctime(curtime,tof-3),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),2,2,1,0,4);
                        else
                            %Shim is turned on in imaging_molassses now to
                            %time it with the trap shutoff
                            
                            %Turning on the shim 2-3ms before TOF is okay,
                            %leave 4ms for adequate optical pumping time
                            %ramp only to 1G rather than 2G to ensure good OP
                            
                            %AnalogFunc(calctime(curtime,tof-4),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),2,2,1,shim_init,4);

                            %%%AnalogFunc(calctime(curtime,-fesh_ramptime+0),19,@
                            %%%(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1*fesh_ramptime,1*fesh_ramptime,2,0);
                        end
                        
                        %Need to ramp off Feshbach
%                         AnalogFunc(calctime(curtime,-fesh_ramptime-0),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_ramptime,fesh_ramptime,0,21.5);
%                         setAnalogChannel(calctime(curtime,0),'FB
%                         current',-0.1,1);
                        

                    end
            end

            %turn off other shims
            
            if ramp_shims_off
                shim_ramptime = 2;
                shim_ramp_delay = 0;
                if seqdata.flags. lattice_stern_gerlach == 1
                    shim_ramp_delay = 1;
                elseif seqdata.flags. lattice_stern_gerlach == 2
                    shim_ramp_delay = SG_shim_ramptime+SG_QP_pulsetime;
                end
                
                x_shim_init = seqdata.params. shim_val(1);
                z_shim_init = seqdata.params. shim_val(3);
                
                AnalogFunc(calctime(curtime,shim_ramp_delay),'X Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramptime,shim_ramptime,0,x_shim_init,3);
                AnalogFunc(calctime(curtime,shim_ramp_delay),'Z Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramptime,shim_ramptime,0,z_shim_init,3);
            else            
                %X (left/right) shim
                setAnalogChannel(calctime(curtime,0),'X Shim',0,3); %1.5
                %Z (top/bottom) shim 
                setAnalogChannel(calctime(curtime,0),'Z Shim',0,3); %1.05
            end

        end

        % Turn Y shim off 100ms later
        setAnalogChannel(calctime(curtime,100),'Y Shim',0.00,4);

    elseif img_direction == 2
        %Imaging along the y-lattice direction in the Science chamber

        %turn the X (quantizing) shim on after magnetic trapping
        if ~in_trap_img
            if seqdata.flags.image_loc == 0; %MOT cell
                %error('Can''t use x imaging direction in the MOT!')
            elseif seqdata.flags.image_loc == 1; %Science cell
                %Optimize field to match the probe detuning to direction 1
                %setAnalogChannel(calctime(curtime,0),'X Shim',3.0); %3.5
                %Turn on bipolar x shim to match
                %setAnalogChannel(calctime(curtime,0),47,3.0);

                if seqdata.flags.QP_imaging ==1;
                        setAnalogChannel(calctime(curtime,0),'X Shim',2,3); %3.5 (div by 2 because of Helmholtz)
                        SetDigitalChannel(calctime(curtime,0),'fast FB Switch',0); %fast switch
                        setAnalogChannel(calctime(curtime,0),'FB current',-0.1,1);%0
                    elseif seqdata.flags.QP_imaging ==0;

                        AnalogFunc(calctime(curtime,-fesh_ramptime),'X Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1*fesh_ramptime,1*fesh_ramptime,3,0);
                        %AnalogFunc(calctime(curtime,-fesh_ramptime),47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1*fesh_ramptime,1*fesh_ramptime,3,0);

                        ramp_fesh_slowly = 1;
                        if ramp_fesh_slowly == 0;
                        %set Feshbach field to 0
                        SetDigitalChannel(calctime(curtime,0),'fast FB Switch',0); %fast switch
                        setAnalogChannel(calctime(curtime,0),'FB current',-0.1,1);%0
                        elseif ramp_fesh_slowly == 1;
                        %fesh_ramptime = 15;
                        SetDigitalChannel(calctime(curtime,0),'fast FB Switch',0); %fast switch
                        AnalogFunc(calctime(curtime,-fesh_ramptime),'FB current',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_ramptime,fesh_ramptime,0,21.0);
                        %AnalogFunc(calctime(curtime,-fesh_ramptime-6),19,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),fesh_ramptime+6,fesh_ramptime+6,1.75,0);
                        end
                end

            end

            %turn off other shims
            %Y (left/right) shim
            setAnalogChannel(calctime(curtime,0),19,0,4); %1.5
            %Z (top/bottom) shim
            setAnalogChannel(calctime(curtime,0),28,0,3); %1.05
           

        end

        % Turn X shim off 100ms later
        
        setAnalogChannel(calctime(curtime,100),'X Shim',0,3); %Bipolar X Shim


    elseif img_direction == 3
        %Imaging along the z-lattice direction in the Science chamber

        %turn the Z (quantizing) shim on after magnetic trapping
        if ~in_trap_img
            if seqdata.flags.image_loc == 0; %MOT cell
                setAnalogChannel(calctime(curtime,0),'Z Shim',3.5,2); %3.5
            elseif seqdata.flags.image_loc == 1; %Science cell
                setAnalogChannel(calctime(curtime,0),'Z Shim',3.5,3); %3.5 (div by 2 because of Helmholtz)
            end

            %turn off other shims
            %X (left/right) shim
            setAnalogChannel(calctime(curtime,0),'X Shim',0,3); %1.5
            %Y (top/bottom) shim 
            setAnalogChannel(calctime(curtime,0),'Y Shim',0,4); %1.5 

        end

        % Turn Z shim off 100ms later
        setAnalogChannel(calctime(curtime,100),'Z Shim',0.00,3);

    elseif img_direction == 4
           %Imaging along the x-lattice direction, in the Science chamber

        %turn the Y shim on after magnetic trapping
        if ~in_trap_img
            if seqdata.flags.image_loc == 0; %MOT cell
                setAnalogChannel(calctime(curtime,0),'Y Shim',3.5,2); %3.5
            elseif seqdata.flags.image_loc == 1; %Science cell
                setAnalogChannel(calctime(curtime,0),'Y Shim',3.5/1.75,4);%3.5 (div by 2 because of Helmholtz)
            end

            %turn off other shims
            %X (left/right) shim
            setAnalogChannel(calctime(curtime,0),'X Shim',0,3); %1.5
            %Z (top/bottom) shim 
            setAnalogChannel(calctime(curtime,0),'Z Shim',0,3); %1.05

        end

        % Turn Y shim off 100ms later
        setAnalogChannel(calctime(curtime,100),'Y Shim',0.00,4);

    end

    

%% Prepare detuning, repump, and probe


    %K
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
        k_detuning_shift_time = 0.5;%4

        %set probe detuning
        setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Probe/OP FM',190); %195
        %SET trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,tof-k_detuning_shift_time),'K Trap FM',k_detuning); %54.5
    end


    %Rb (need some time to set Rb detuning with offset lock)
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        %detuning_shift_time = min(tof,4.0); %4.0
        rb_detuning_shift_time = 4;%4

        if seqdata.flags.image_loc==1
            rb_detuning_shift_time = 1000;%100 %7
        end

    %     %offset FF
          setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FF',+1.2,1); %1.05 %1.15
          setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time+2200),'Rb Beat Note FF',0.0,1);
    % 
    %     %set detuning
          setAnalogChannel(calctime(curtime,tof-rb_detuning_shift_time),'Rb Beat Note FM',rb_detuning);%27 %26 in trap %time is 1.9 %29.6 MHz is resonance (no Q field), 33.4MHz is resonance (with 4G field), 32.4 MHz (with 3G field), found had to change to 27MHz (Aug10)
    end


    %Prepare Probe (analog on, but keep light off with TTL)   

    %K
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
        %analog
        if use_K_OP
            %Analog
            setAnalogChannel(calctime(curtime,-0.3+tof),'K Probe/OP AM',k_probe_pwr*1,1); %0.37 0.26
            %TTL
            setDigitalChannel(calctime(curtime,-0.3+tof),'K Probe/OP TTL',1);
        else
            %Analog
            setAnalogChannel(calctime(curtime,-1+tof),'K Probe/OP AM',k_probe_pwr,1); %1
            %TTL
            setDigitalChannel(calctime(curtime,-1+tof),'K Probe/OP TTL',1);
        end

    end

    %Rb
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        %analog
        setAnalogChannel(calctime(curtime,-5+tof),'Rb Probe/OP AM',rb_probe_pwr,1); %.1
        %TTL
        setDigitalChannel(calctime(curtime,-5+tof),'Rb Probe/OP TTL',1);
    end
   
    
%% Take 1st probe picture

    if ( seqdata.flags.iXon )
        % Clean out trigger for iXON 100ms before image is taken (flush chip)
        DigitalPulse(calctime(curtime,-100),'iXon Trigger',pulse_length,1);
    end



    %%%%do Rb repump pulse to transfer from F=1 to F=2

%     seqdata.flags.do_F1_pulse = 0;
% 
%     if seqdata.flags.do_F1_pulse == 1
% 
%         F1_pulselength = 12;
% 
%         %open repump shutter
%         setDigitalChannel(calctime(curtime,0),5,1);
%         %prepare repump AOM
%         setAnalogChannel(calctime(curtime,0),2,0.7);
%         %TTL (none)
% 
%         %open repump shutter
%         setDigitalChannel(calctime(curtime,F1_pulselength ),5,0);
%         %prepare repump AOM
%         setAnalogChannel(calctime(curtime,F1_pulselength ),2,0.0);
%         %TTL (none)
% 
%     elseif seqdata.flags.do_F1_pulse ==0
% 
%     end

%%%%%

%digital trigger
%     DigitalPulse(calctime(curtime,tof),12,0.1,1);

%Trigger
curtime = calctime(curtime,tof);
 if img_direction ==5

 else
     do_abs_pulse(curtime,pulse_length);
 end
% %K repump on too
% DigitalPulse(curtime,7,pulse_length,0);


%% Take 2nd probe picture after 1st readout

%100us Camera trigger
curtime = calctime(curtime,200);%100, 200



% if seqdata.flags.do_F1_pulse == 1
% 
%     
%     %open repump shutter
%     setDigitalChannel(calctime(curtime,0),5,1);
%     %prepare repump AOM
%     setAnalogChannel(calctime(curtime,0),2,0.7);
%     %TTL (none)
% 
%     %open repump shutter
%     setDigitalChannel(calctime(curtime,100 ),5,0);
%     %prepare repump AOM
%     setAnalogChannel(calctime(curtime,100 ),2,0.0);
%     %TTL (none)
% 
% elseif seqdata.flags.do_F1_pulse ==0
%     
% end
%DigitalPulse(curtime,1,pulse_length,1);
 %AM
       
 if use_K_OP
     %set probe detuning
         setAnalogChannel(calctime(curtime,-9),'K Probe/OP FM',190); %202.5
 end
 
do_abs_pulse(curtime,pulse_length);

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
function do_abs_pulse(curtime,pulse_length)

    %Camera triggers
%     DigitalPulse(curtime,12,pulse_length,1);
    if ( seqdata.flags.iXon )
        DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
    else
        DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
    end

    %Probe pulse with TTL

    %K
    if (seqdata.atomtype==1  || seqdata.atomtype==4)
        DigitalPulse(curtime,'K Probe/OP TTL',pulse_length,0);
        if use_K_repump
            %Repump pulse
            DigitalPulse(calctime(curtime,-0.9 - K_OP_time),7,K_OP_time+0.05,0); %0.3 (needs to be on until OP finishes)
        end
        
        if use_K_OP
         %set probe detuning
         setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',200.5); %202.5 for 2G shim
        %SET trap AOM detuning to change probe
        setAnalogChannel(calctime(curtime,-10),'K Trap FM',32.5); %40 for 2G shim
        %Set AM for Optical Pumping
        setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',2*k_probe_pwr,1);%0.65
        %TTL
        DigitalPulse(calctime(curtime,-0.9 - K_OP_time),'K Probe/OP TTL',K_OP_time,0); %0.3
        
        
        %Set AM back for imaging
        setAnalogChannel(calctime(curtime,-k_detuning_shift_time),'K Probe/OP AM',k_probe_pwr,1);%0.65
        
        end
        
%         %do it again 100ms later
%         if use_K_repump
%             %Repump pulse
%             DigitalPulse(calctime(curtime,-1.0+100),7,0.3,0);
%         end
%         
%         if use_K_OP
%         %set probe detuning
%         setAnalogChannel(calctime(curtime,-10+100),'K Probe/OP FM',202.5); %202.5
%         %SET trap AOM detuning to change probe
%         setAnalogChannel(calctime(curtime,-10+100),'K Trap FM',22); %54.5
%         %AM
%         setAnalogChannel(calctime(curtime,-2+100),'K Probe/OP AM',0.7,1);
%         %setAnalogChannel(calctime(curtime,90),'K Probe/OP AM',0.7,1);
%         %TTL
%         DigitalPulse(calctime(curtime,-1+100),9,0.3,0);
%         end
    end
    %Rb
    if (seqdata.atomtype==3  || seqdata.atomtype==4)
        DigitalPulse(curtime,'Rb Probe/OP TTL',pulse_length,0);
        %Rb F1->F2 pulse
        if seqdata.flags.do_F1_pulse == 1
            % pulse repump with AOM AM
            setAnalogChannel(curtime,'Rb Repump AM',0.1);
            setAnalogChannel(calctime(curtime,0.5*pulse_length),'Rb Repump AM',0);
        end

    end

        
end

end
