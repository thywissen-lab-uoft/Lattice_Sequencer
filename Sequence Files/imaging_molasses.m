%------
%Author: Dylan
%Created: Mar 2013
%Summary:   Turns on optical molasses beams
%------

function [timeout,molasses_offset] = imaging_molasses(varargin)

timein = varargin{1};
if nargin > 1
    img_molasses_time = varargin{2};
else
    img_molasses_time = 1*5000;
end

global seqdata;

    
molasses_trap = 4;  %0 - QP, 1 - XDT, 2 - Lattice with Rb, 3 - Lattice with K (D2), 4 - XDT with K (D1)


% timein is the time at which the molasses beams are turned on
    curtime = timein;
%extra time to run function by itself
    %curtime = calctime(curtime,200);

    
    
    fluorescence_image = 0;
    fluor_delay = 5;
    
    zero_shims = 1;
   
if molasses_trap == 0 %QP
    
        
    %imaging molasses parameters    
    img_molasses_detuning = 30;%30 %45
    img_molasses_time = 10;%10
    
elseif molasses_trap == 1 %XDT
    
    %imaging molasses parameters    
    img_molasses_detuning = 40;%30 %45
    img_molasses_time = 50;%10
    
elseif molasses_trap == 2 %Lattice with Rb
    
    rb_molasses_detuning = 50;  
    rb_molasses_trap_power = 0.3*1;
    rb_molasses_repump_power = 0.25*1;
    img_molasses_time = 1;
    
%     %     %      %list
%     img_molasses_detuning_list=[-100 -50:5:20 50 100];
%     
%     %Create linear list
%     %index=seqdata.cycle;
%     
%     %Create Randomized list
%     index=seqdata.randcyclelist(seqdata.cycle);
%     
%     rb_molasses_detuning = img_molasses_detuning_list(index);
%     addOutputParam('rb_detuning',rb_molasses_detuning);

elseif molasses_trap == 3 %Lattice with K
    
    %imaging molasses parameters    
    img_molasses_detuning = 30;%30 %45
    img_molasses_trap_power = 0.7;
    img_molasses_repump_power = 0.7;
    
    img_molasses_time = 10;%10
    
elseif molasses_trap == 4 %XDT with K (D1)
    
    %%%%% Tune Molasses to Be Extra Bright (only works with single plane)
    extra_brightness = 0;
    %%%%%
    if extra_brightness
        D1_raman_detuning = 100/1000;
        dBz = -0.03;
    else
        D1_raman_detuning = 0/1000;
        dBz = 0;
    end
    
%     raman_detuning_list = [-150:50:150 -250 250]/1000;
%       raman_detuning_list = (0/1000);
%       D1_raman_detuning = getScanParameter(raman_detuning_list,seqdata.scancycle, seqdata.randcyclelist, 'raman_detuning');
    
%     D1_raman_detuning = 0/1000;
    
    %imaging molasses parameters
%           detuning_list = (225:5:255);
%          k_D1_detuning = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'k_D1_detuning');
         k_D1_detuning = 235; %171 for D1, no blue. 
        addOutputParam('k_D1_detuning',k_D1_detuning); 
         
        
        D1_raman_detuning = -0/1000; %Raman detuning from 1285.8MHz (in MHz)
%           raman_detuning_list = repmat([-240:40:200]/1000,1,2);
%           raman_detuning_list = [-100 -75 -50 -25 -15 -5 0 5 15 25 50 75 100]/1000;
%           D1_raman_detuning = getScanParameter(raman_detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'raman_detuning');
        
        raman_set_freq = (1285.79 + D1_raman_detuning); %Divide by ten when using tentupler to generate sidebands
        addOutputParam('raman_detuning',D1_raman_detuning); 
        raman_power = -5;
        addOutputParam('raman_power',raman_power); 
        
        %Program HP Generator to set Raman sideband frequency
%         addGPIBCommand(7,sprintf('FR%fMZ; AP%gDM;',raman_set_freq,-5)); %Keep amplitude fixed at -5dBm for tentupler to work
        %Program SRS B to set Raman sideband frequency
%           addGPIBCommand(28,sprintf('FREQ %fMHz; AMPR %gdBm; MODL 0; DISP 2; ENBR %g; FREQ?',raman_set_freq,raman_power,0));  
        
%         maxpower = 2 + (k_D1_detuning - 220) / 7 * 1.5;
%         if(maxpower>10)
%             maxpower = 10;
%         end
%         minpower = 2 + (k_D1_detuning - 220) / 7 * 0.5;
%          power_list = [4.5 5 5.5 6 6.5 7 8 9];
          k_D1_detuning_trap_power = 10; %5.7 at 250MHz July 20 2015.
%          k_D1_detuning_trap_power = getScanParameter(power_list, seqdata.scancycle, seqdata.randcyclelist, 'k_D1_power');
        addOutputParam('k_D1_power',k_D1_detuning_trap_power); 
        %mol_list = [2.5 2.6 3 5 10 20 50 100 200] - 2.4;
%         img_molasses_time = 5000; %getScanParameter(mol_list,seqdata.scancycle,seqdata.randcyclelist,'mol_time'); %this is the time to wait AFTER ramping up the beam!! 
        lattice_holdtime = 15; %15 %Hold time in trap after molasses (should be at least 5ms)
        if seqdata.flags. do_stern_gerlach == 1
            %Need extra long hold time to allow shims to ramp
            lattice_holdtime = 30;
        end
        
        
        addOutputParam('molasses_time',img_molasses_time); 
        
        addOutputParam('probe_power',2);
        
         
        %Using chopper for vertical beam?
        use_chopper = 0;
        
        %Raman beams?
        Raman_On = 0;
        
        %Using channel D54 (D1 TTL B) for an optical pumping beam?
        D54_OP_beam = 0;
        
    %Ramp on the beam with AOM?
        AM_ramp = 1;    %0 - TTL Pulse at set AM value; 1 - AM Ramp up to set value
        ramp_time = 5;  %Length of power ramp-up (ramps shorter than 0.5ms look nonlinear)
        AM_ramp_down = 0; % 0 - TTL off the D1; 1 - AM Ramp Down from set value with same time as ramp-up

        %Turn on far detuned D2 beam pair for Raman coupling?
        raman_coupling = 0;
        
        %Turn on 405nm Beam During Molasses?
        blue_on = 0;  %1: use Toptica as blue beam, 2: use Daniel's laser as blue beam
%         blue_on_delay = AM_ramp*ramp_time+50;
        blue_on_delay = 0;    
        pulse_blue = 1; %0 - continous 405nm beam; 1 - Adwin-controlled pulsing; 2 - Trigger Rigol to pulse.
        
    %Pulse probe Beam During Molasses?
        pulse_probe = 0;
        Downwards_D2 = 0;
%         probe_on_delay = -2;  %AM_ramp*ramp_time+50
%         time_list = [0.02 0.05 0.08 0.12 0.2 0.4 0.8];
%         K_probe_time = getScanParameter(time_list, seqdata.scancycle, seqdata.randcyclelist, 'k_probe_time');


%         K_probe_time = img_molasses_time-15;  %img_molasses_time-100   0.05
%         addOutputParam('k_probe_time',K_probe_time);
%         probe_on_delay = ramp_time + 10; %-K_probe_time
    
    %Turn on 767nm D2 Repump Beam During Molasses?
        D2_on = 0;
        D2_on_time = 0;
        img_molasses_detuning = 6;%30 %45
        img_molasses_trap_power = 0.5;
        img_molasses_repump_power = 0.3;
               
        %Optically Pump In Trap
        seqdata.flags. in_trap_OP = 0;
else
end

if seqdata.flags.do_imaging_molasses == 3
    %D1 Molasses in Free Space, begins when the trap shuts off
    curtime = calctime(curtime,0);
    molasses_offset = 0;
    lattice_holdtime = 0;
    
    %turn off dipole trap 1
    setAnalogChannel(calctime(curtime,0),40,-0.3,1);
    %turn off dipole trap 2
    setAnalogChannel(calctime(curtime,0),38,-0.3,1);
elseif seqdata.flags.do_imaging_molasses == 2
    %D1 Molasses After QP Trap
    
    molasses_offset = 0;

    %Need to adjust TOF to make sure the image is taken after D1 is
    %finished
    seqdata.params. tof = seqdata.params. tof + seqdata.params. molasses_drop_time + img_molasses_time;   
elseif seqdata.flags.do_imaging_molasses == 1
    %D1 Molasses in optical Trap: trap shuts off after D1 ends, plus any
    %additional hold time
    
    %Need at least 15ms of hold time
    if lattice_holdtime < 15
        lattice_holdtime = 15; 
        error('Lattice holdtime must be at least 15ms for shim ramps')
    else 
    end
    
    total_molasses_time = img_molasses_time + AM_ramp*ramp_time;
    
    molasses_offset = total_molasses_time+lattice_holdtime;
    
    
    
    curtime = calctime(curtime,-molasses_offset);
    
    
end
    
%Trigger at Start of Molasses
ScopeTriggerPulse(calctime(curtime,0),'D1 Molasses Start');

%% Get rid of Rb

get_rid_Rb = 0; 

    if get_rid_Rb

        %blow away any atoms left in F=2
        %open Rb probe shutter
        setDigitalChannel(calctime(curtime,-80),25,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,-80),4,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,-80),24,1);
        %set detuning
        setAnalogChannel(calctime(curtime,-80),34,6590-237);
        
        %pulse beam with TTL
        DigitalPulse(calctime(curtime,-75),24,5,0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,-60),25,0); %0=closed, 1=open

    end

%% Turn off Feshbach Field  

ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);

if molasses_trap == 0 %QP
    %Feshbach is already off!
elseif molasses_trap==1 %XDT
    %Ramp off Feshbach in 15 ms
    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
            SetDigitalChannel(calctime(curtime,0),31,0); %fast switch
            AnalogFunc(calctime(curtime,-15),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),15,15,-2,21.5);
            setAnalogChannel(calctime(curtime,0),37,-0.1,1);
elseif molasses_trap == 2 %Lattice with Rb
    %Feshbach is already off!
    
     ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
     ramptime = 15;
            SetDigitalChannel(calctime(curtime,-20),31,0); %fast switch
            AnalogFunc(calctime(curtime,-ramptime-20),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramptime,ramptime,-2,21.5);

elseif molasses_trap == 3 %Lattice with K
 %Ramp off Feshbach 
    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
    ramptime = 15;
            SetDigitalChannel(calctime(curtime,-5),31,0); %fast switch
            AnalogFunc(calctime(curtime,-ramptime-5),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramptime,ramptime,-2,21.5);
   
elseif molasses_trap == 4 %XDT with K
    
    if seqdata.flags.do_imaging_molasses == 2
        %Dropping from QP, don't need to ramp FB
    else
%         Ramp off Feshbach
        
        feshbach_current = seqdata.params. feshbach_val;
        ramptime = 50;
                SetDigitalChannel(calctime(curtime,-10),31,0); %fast switch
                AnalogFuncTo(calctime(curtime,-ramptime-25),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramptime,ramptime,0);
%                 AnalogFunc(calctime(curtime,-ramptime-5),37,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramptime,ramptime,0,feshbach_current);
    end
end
%% turn on the shims for optical pumping and/or molasses
   
%Shims are already set to field zeroing values in dipole_transfer.m

if zero_shims==1
% SHIM COILS !!!
    shim_ramptime = 10;
    shim_ramp_offset = 5;
    
    %set shim coils to the field cancelling values
    x_Bzero = seqdata.params. shim_zero(1);   %0.115 minimizes field - 1*seqdata.params.shim_zero(1)
    y_Bzero = seqdata.params. shim_zero(2);   %-0.0517 minimizes field - 1*seqdata.params.shim_zero(2)
    z_Bzero = seqdata.params. shim_zero(3);   %-0.1 minimizes field - 1*seqdata.params.shim_zero(3)
    
       
%     %Requested field in Gauss
%     field_val = 2;
%     %Angle for field direction in x-y plane
%     field_theta = 60;
%     
%     %Determine the requested frequency offset from zero-field resonance
%     frequency_shift = field_val *2.4889;
%     
%     %Define the measured shim calibrations (NOT MEASURED YET, ASSUMING 2G/A)
%     Shim_Calibration_Values = [2.4889*2, 0.994*2.4889*2];  %Conversion from Shim Values (Amps) to frequency (MHz) to
%     
%     %Determine how much to turn on the X and Y shims to get this frequency
%     %shift at the requested angle
%     X_Shim_Value = frequency_shift * cosd(field_theta) / Shim_Calibration_Values(1);
%     Y_Shim_Value = frequency_shift * sind(field_theta) / Shim_Calibration_Values(2);
%     
%     X_Shim_Offset = 0;
%     Y_Shim_Offset = 0;
%    
%     
%     img_xshim = x_Bzero + X_Shim_Offset + X_Shim_Value;
%     img_yshim = y_Bzero + Y_Shim_Offset + Y_Shim_Value; %-0.02
    dBx = 0.00;
    dBy = -0.00; %-0.03


    img_xshim = x_Bzero + dBx;
    img_yshim = y_Bzero + dBy;
    
%     shim_list = [-0.03:0.01:0.08];
%     dBz = getScanParameter(shim_list,seqdata.scancycle, seqdata.randcyclelist, 'z_shim');
    
%     dBz_list = [-0.03];%[repmat(0.03,1,12) repmat(0.05,1,12)];
%     dBz = getScanParameter(dBz_list, seqdata.scancycle, seqdata.randcyclelist, 'z_shim');

    dBz = -0.0; %-0.018 seems to improve brightness
    img_zshim = z_Bzero+dBz; %-0.05
    
    addOutputParam('dBx',dBx);
    addOutputParam('dBy',dBy);
    addOutputParam('dBz',dBz);
    
    

    %ramp on shims with min jerk
    AnalogFuncTo(calctime(curtime,-shim_ramptime-shim_ramp_offset),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,img_xshim,3);
    AnalogFuncTo(calctime(curtime,-shim_ramptime-shim_ramp_offset),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,img_yshim,4);
    AnalogFuncTo(calctime(curtime,-shim_ramptime-shim_ramp_offset),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramptime,shim_ramptime,img_zshim,3);
else
end

%% Reset the Magnetic Field Sensor in Bucket
      
    SR_pulse_time = 1;
    n_pulses = 10;
    
    for i=1:n_pulses
        DigitalPulse(calctime(curtime,2*(i-1)),'Field sensor SR',SR_pulse_time,1);
    end 
    
%% turn on trap and repump beams     


if molasses_trap == 2 %Lattice with Rb
    %rb_molasses_detuning = 20;
   %Set Detunings
   setAnalogChannel(calctime(curtime,-50),34,6590+rb_molasses_detuning); %Trap
   %offset FF
        setAnalogChannel(calctime(curtime,-50),'Rb Beat Note FF',-0.03,1);
   %Set Powers
   setAnalogChannel(calctime(curtime,-2),4,rb_molasses_trap_power); %Trap
   setAnalogChannel(calctime(curtime,-2),2,rb_molasses_repump_power); %Repump
   setAnalogChannel(calctime(curtime,img_molasses_time),2,0); %Repump
   
   %TTL and Shutters
   setDigitalChannel(calctime(curtime,-10),8,1); %Trap TTL
   DigitalPulse(calctime(curtime,0),8,img_molasses_time,0);
   setDigitalChannel(calctime(curtime,-5),4,1); %Trap shutter
   setDigitalChannel(calctime(curtime,-5),5,1); %Repump Shutter
   
elseif molasses_trap == 3 %Lattice with K

    %Trap Detuning
    setAnalogChannel(calctime(curtime,-2),5,img_molasses_detuning);
    
    %Trap Power
    setAnalogChannel(calctime(curtime,-2),26,img_molasses_trap_power);
    
    %Trap TTL and Shutter
    setDigitalChannel(calctime(curtime,0),6,0);
    setDigitalChannel(calctime(curtime,-3),2,1);
    
    %Repump Power
    setAnalogChannel(calctime(curtime,-100),25,img_molasses_repump_power);
    
    %Repump TTL and Shutter
    setDigitalChannel(calctime(curtime,0),7,0);
    setDigitalChannel(calctime(curtime,-3),3,1);
    
elseif molasses_trap == 4 %XDT with K
    
    D1_AM_control =1; %0 - TTL Pulse at manual power, 1 - AM Controlled
                 
    %Turn on D1 beams
        if D1_AM_control == 0
 
        %AOM is usually ON to keep warm, so turn off TTL before opening shutter
            setDigitalChannel(calctime(curtime,-5),35,0);
            
        %Turn on beam with TTL Only
            %Set Detuning
            setAnalogChannel(calctime(curtime,-10),48,k_D1_detuning);
            %Shutter  
            setDigitalChannel(calctime(curtime,-4),36,1);
            %TTL
            setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
            setDigitalChannel(calctime(curtime,0),'D1 TTL B',1);
                 
        elseif D1_AM_control == 1
            
        %turn on D1 AOM 3s before it's being used in order for it to
        %warm up
        setAnalogChannel(calctime(curtime,-3000),47,k_D1_detuning_trap_power,1);
            
        %AOM is usually ON to keep warm, so turn off TTL before opening shutter
        setDigitalChannel(calctime(curtime,-5),'D1 TTL',0);
        setDigitalChannel(calctime(curtime,-5),'D1 TTL B',0);
        
        if Downwards_D2 == 1
            
            k_probe_detuning = 0; %Stark shifted resonance at ~0MHz in (650,650,800)ER lattice
            k_probe_pwr = 1*0.61; %0.06 doesn't kill all atoms at 500ms
            probe_on_delay = 0;
            pulse_window = img_molasses_time;
            
            addOutputParam('k_probe_detuning',k_probe_detuning);
            
            %set probe detuning
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Probe/OP FM',190); %202.5 for 2G shim
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Trap FM',k_probe_detuning); %40 for 2G shim
            %Set AM for Optical Pumping
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Probe/OP AM',k_probe_pwr,1);%0.65
            
            %Open probe AOM.
            setDigitalChannel(calctime(curtime,ramp_time),'K Probe/OP TTL',0);                         
            %Open probe shutter
            setDigitalChannel(calctime(curtime,ramp_time-5),'Downwards D2 Shutter',1);
            %Close when done
            setDigitalChannel(calctime(curtime,ramp_time+pulse_window),'Downwards D2 Shutter',0);

            %Turn D2 beam off with Adwin
            setDigitalChannel(calctime(curtime,ramp_time+pulse_window-1),'K Probe/OP TTL',1);

        end

        if pulse_probe ==1
            %This adds a probe pulse to blowaway the atoms in the wings
            %Need to turn up power, set detuning to 44
            
%             detuning_list = [-60:5:-20];
%             k_probe_detuning = getScanParameter(detuning_list, seqdata.scancycle,seqdata.randcyclelist, 'k_probe_detuning');
            
            k_probe_detuning = 70; %Stark shifted resonance at ~0MHz in (650,650,800)ER lattice
            k_probe_pwr = 1*0.61; %0.06 doesn't kill all atoms at 500ms
            
            addOutputParam('k_probe_detuning',k_probe_detuning);
            
            %set probe detuning
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Probe/OP FM',190); %202.5 for 2G shim
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Trap FM',k_probe_detuning); %40 for 2G shim
            %Set AM for Optical Pumping
            setAnalogChannel(calctime(curtime,probe_on_delay-25),'K Probe/OP AM',k_probe_pwr,1);%0.65
            
            %Open Shutter and Turn on Beam
            DigitalPulse(calctime(curtime,probe_on_delay),'K Probe/OP TTL',K_probe_time,0); %0.3
            DigitalPulse(calctime(curtime,probe_on_delay-5),'K Probe/OP Shutter',K_probe_time+3,1);
            
            add_repump = 0;
            if add_repump
                repump_power = 0.3;
                
                %Repump Power
                setAnalogChannel(calctime(curtime,probe_on_delay-25),25,repump_power);

                %Repump TTL and Shutter
                DigitalPulse(calctime(curtime,probe_on_delay),7,K_probe_time,0);
                DigitalPulse(calctime(curtime,probe_on_delay-5),3,K_probe_time+10,1);
            end
            
        end
        
        %Turn on beam with TTL
            %Set Detuning
            setAnalogChannel(calctime(curtime,-6),48,k_D1_detuning);
            %Shutter  
            setDigitalChannel(calctime(curtime,-4),36,1);
            %TTL ON
            setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
            setDigitalChannel(calctime(curtime,0),'D1 TTL B',1);
           
            if (Raman_On)
                Pulse_RamanBeams(calctime(curtime, AM_ramp*ramp_time) ,img_molasses_time - AM_ramp*ramp_time,'MOTLightSource',2);
            end
            
            if AM_ramp == 1
                
                %Ramp on the beam linearly over 0.1ms
                    %Linear ramp function
                    ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
                    %Set Analog to 0 Initially
                    setAnalogChannel(calctime(curtime,-2),47,0);
                    %Ramp Analog over 1ms
                    AnalogFunc(curtime,47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramp_time,ramp_time,k_D1_detuning_trap_power,0,1);
            else
                %The beam is already turned on by the TTL
            end
            
            if blue_on == 1    
                %Open blue shutter, keep beam off with TTL
                setDigitalChannel(calctime(curtime,-10),'405nm TTL',0); %NO LONGER EXISTS ADD NEW TTL IF DESIRED.
                setDigitalChannel(calctime(curtime,-4),'405nm Shutter',1)

                switch pulse_blue
                    case 1 %Adwin-controlled pulses.
                        pulse_length = 15; %Repetition time for the blue/D1 Pulses
                        duty = 0.20; %Fraction of the pulse length that the 405nm beam is on
                        for Counter = 1 : ((floor(img_molasses_time/pulse_length)))
                            setDigitalChannel(calctime(curtime,blue_on_delay + pulse_length * (Counter-1)),'405nm TTL',1);
                            setDigitalChannel(calctime(curtime,blue_on_delay + pulse_length * (Counter-1) + duty*pulse_length),'405nm TTL',0);
                            DigitalPulse(calctime(curtime,blue_on_delay + pulse_length * (Counter - 1)),'D1 TTL',pulse_length*duty,0);
                        end

                    case 2 %Control pulses with Rigol.
                        %Amount of time to do pulses
                        pulse_window = img_molasses_time-50;
 
                        %Hand over digital control of D1 and blue to Rigol generator
                        setDigitalChannel(calctime(curtime,0),'D1 TTL',0);
                        setDigitalChannel(calctime(curtime,0),'D1 TTL B',0);
                        DigitalPulse(calctime(curtime,ramp_time),51,pulse_window,1);

                    otherwise
                    %Blue beam on continuously.
                        %Turn on 405nm Beam to scatter
                        setDigitalChannel(calctime(curtime,blue_on_delay),38,1);

                end

            elseif blue_on == 2
                %using Daniel's laser
                setDigitalChannel(calctime(curtime,blue_on_delay),'404.8nm TTL',1);
            else
                %do nothing
            end
            
            if (use_chopper==1)
                %Turn off D1 TTL B after 10ms to start alternating vertical
                %beam with the camera exposure
                setDigitalChannel(calctime(curtime,ramp_time + 10),'D1 TTL B',0);
            end
            
            alternate_beams = 0; %0 for no pulsing; 1 for Adwin controlled pulses; 2 for Rigol pulses on D51
            if (alternate_beams==1)
                %Want to alternate a scattering beam with the D1 cooling using
                %TTL pulses
                
                              
                %Need to leave probe shutter open for fast pulses
                setDigitalChannel(calctime(curtime,ramp_time-5),'K Probe/OP Shutter',1);
                %Close when done
                setDigitalChannel(calctime(curtime,ramp_time+img_molasses_time),'K Probe/OP Shutter',0);
                
%                 cool_time = 5;
%                 scatt_time = 0.5;
% %                 off_time = 0.05;
%                 cycle_time = 10;

                cycle_time = 10;
                cool_frac = 0.8;
                cool_time = cycle_time*cool_frac;
                scatt_time = cycle_time*(1-cool_frac);
                
                
                addOutputParam('cool_frac',cool_frac);
                
%                 cycle_time = cool_time + scatt_time + 2*off_time;
%                 off_time = (cycle_time - cool_time - scatt_time)/2;

                n_cycles = floor(img_molasses_time/cycle_time)-1;
                
                DigitalPulseTrain(calctime(curtime,ramp_time),'D1 TTL',scatt_time,cool_time,n_cycles,0);
%                 DigitalPulseTrain(calctime(curtime,ramp_time),'K Probe/OP TTL',scatt_time,cool_time,n_cycles,0);
                
%                 for n=0:(n_cycles-1)
%                 DigitalPulse(calctime(curtime,ramp_time + (cool_time) + n*cycle_time),'D1 TTL',scatt_time+2*off_time,0);
%                 DigitalPulse(calctime(curtime,ramp_time + (cool_time+off_time) + n*cycle_time),'K Probe/OP TTL',scatt_time,0);
%                 end
                
            elseif (alternate_beams==2)
                
                %Amount of time to do pulses
                pulse_window = img_molasses_time-50;
                
                %Open probe shutter
                setDigitalChannel(calctime(curtime,ramp_time-5),'K Probe/OP Shutter',1);
                %Close when done
                setDigitalChannel(calctime(curtime,ramp_time+pulse_window),'K Probe/OP Shutter',0);
                
                %Hand over digital control of D1 and D2 to Rigol generator
                setDigitalChannel(calctime(curtime,ramp_time+5.5),'K Probe/OP TTL',0);
                setDigitalChannel(calctime(curtime,ramp_time+5.5),'D1 TTL',0);
                DigitalPulse(calctime(curtime,ramp_time),51,pulse_window,1);
                
                %Turn D2 beam off with Adwin
                setDigitalChannel(calctime(curtime,ramp_time+pulse_window-1),'K Probe/OP TTL',1);
                
            end
            
            modulate_AOM_B = 0;
            addOutputParam('AOM_B_pulsing',modulate_AOM_B);
            if modulate_AOM_B
                %Pulse AOM B with a duty cycle to reduce the amount of
                %cooling light passing through the microscope
                
%                  time_list = [0.01 0.5 1:1:9 9.9];%[0.5 1:9 9.5];
%                  on_time = getScanParameter(time_list, seqdata.scancycle,seqdata.randcyclelist, 'on_time');
                
                cycle_list = (1:2:21);
                cycle_time = getScanParameter(cycle_list, seqdata.scancycle,seqdata.randcyclelist, 'cycle_time');

%                 cycle_time = 1;
                on_time = 0.3 * cycle_time;
                off_time = cycle_time - on_time;
%                 on_time = 1;
%                 off_time = 10 - on_time;
%                 cycle_time = on_time + off_time;
                
                addOutputParam('on_time',on_time);
                addOutputParam('off_time',off_time);
                addOutputParam('on_fraction',on_time/cycle_time);
                
                n_cycles = floor(img_molasses_time/cycle_time)-1;
                
                for n=0:(n_cycles-1)
                DigitalPulse(calctime(curtime,ramp_time + (on_time) + n*cycle_time),'D1 TTL B',off_time,0);
                end
                
                
            end
            
%              setDigitalChannel(calctime(curtime,ramp_time),'D1 TTL B',0);
% %             
%             off_time = 15;
%             cool_time = 0;
%              setDigitalChannel(calctime(curtime,img_molasses_time + ramp_time - off_time - cool_time),'D1 TTL B',0);
%             setDigitalChannel(calctime(curtime,img_molasses_time + ramp_time - cool_time),'D1 TTL B',1);
             
%              addOutputParam('off_time',off_time);
%              addOutputParam('cool_time',cool_time);
            
            if (raman_coupling == 1)
                %open shutter to illuminate with far off resonant D2 beam
                %pair (currently connected to 405nm shutter)

                Pulse_RamanBeams(calctime(curtime,ramp_time),img_molasses_time);
                
            end
            
            
            
            if D2_on
%                  %Trap Detuning
%                 setAnalogChannel(calctime(curtime,-2+D2_on_time),5,img_molasses_detuning);
% 
%                 %Trap Power
%                 setAnalogChannel(calctime(curtime,-2+D2_on_time),26,img_molasses_trap_power);
% 
%                 %Trap TTL and Shutter
%                 setDigitalChannel(calctime(curtime,0+D2_on_time),6,0);
%                 setDigitalChannel(calctime(curtime,-3+D2_on_time),2,1);
% 
                %Repump Power
                setAnalogChannel(calctime(curtime,-10+D2_on_time),25,img_molasses_repump_power);

                %Repump TTL off and Shutter open to start
                setDigitalChannel(calctime(curtime,-15+D2_on_time),7,1);
                setDigitalChannel(calctime(curtime,-10+D2_on_time),3,1);
                
                %TTL ON
                setDigitalChannel(calctime(curtime,0+D2_on_time),7,0);
                
            else
            end
            
            
        end
    
    
end
        

% 
    %Pulse beam and trigger camera
                if fluorescence_image
                     DigitalPulse(calctime(curtime,fluor_delay),'PixelFly Trigger',0.2,1);
                end
%                     DigitalPulse(calctime(curtime,2.5),6,img_molasses_time,0);
%         curtime =  DigitalPulse(calctime(curtime,2.5),7,img_molasses_time,0);
     
%% do imaging for some time  
          
if AM_ramp==1

    %Let AM finish ramping before counting out img_molasses_time
    curtime = calctime(curtime,img_molasses_time+ramp_time);
    
else
    %do molasses for sometime
    curtime = calctime(curtime,img_molasses_time);
end
    
%% turn off trap and repump beams   

if molasses_trap == 2 %Lattice with Rb
   
    %Turn off Trap and Repump Beams
        %Rb repump
        curtime = turn_off_beam(calctime(curtime,2),2,0,3);
        %Rb trap
        curtime = turn_off_beam(calctime(curtime,2),1,0,3);
   
elseif molasses_trap ==3 %Lattice with K
    
    %turn trap off
    %turn_off_beam(calctime(curtime,0),1,1);
    setAnalogChannel(calctime(curtime,0),26,0,1);
    setDigitalChannel(calctime(curtime,0),6,1);
    setDigitalChannel(calctime(curtime,0),2,0);
    %turn repump off
    %turn_off_beam(calctime(curtime,0),2,1);
    setAnalogChannel(calctime(curtime,0),25,0,1);
    setDigitalChannel(calctime(curtime,0),7,1);
    setDigitalChannel(calctime(curtime,0),3,0);
    
elseif molasses_trap == 4 %XDT with K (D1)
            
    if AM_ramp_down == 0
        %Turn off D1
        setDigitalChannel(calctime(curtime,0),36,0); %Shutter
        setDigitalChannel(calctime(curtime,0),'D1 TTL',0); %TTL
        setDigitalChannel(calctime(curtime,0),'D1 TTL B',0); %TTL
    
    %Ramp off D1 light
    elseif AM_ramp_down == 1
                
        %Ramp off the beam linearly over 0.1ms
        %Linear ramp function
        ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%         start_power = 
        %Ramp Analog down over some time, currently same as ramp on time
        curtime = AnalogFunc(curtime,47,@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),ramp_time,ramp_time,0,k_D1_detuning_trap_power,1);
        setDigitalChannel(calctime(curtime,0),36,0); %Shutter
        setDigitalChannel(calctime(curtime,0),'D1 TTL',0); %TTL
        setDigitalChannel(calctime(curtime,0),'D1 TTL B',0); %TTL
    end
            

   
    %After the shutter closes, turn TTL and Analog back on to keep AOM Warm
    setDigitalChannel(calctime(curtime,5),'D1 TTL',1);
    
    if D54_OP_beam
        setDigitalChannel(calctime(curtime,5),'D1 TTL B',0); %TTL
    else
        setDigitalChannel(calctime(curtime,5),'D1 TTL B',1); %TTL
    end
    setAnalogChannel(calctime(curtime,5),47,k_D1_detuning_trap_power,1);
    
    
    if blue_on == 1                
        %Turn off 405nm with TTL then shutter
        setDigitalChannel(calctime(curtime,0),38,0);
        setDigitalChannel(calctime(curtime,2),23,0)
        
        %You should comment out the code to keep AOM warm while using Daniel's laser!
        %Turn TTL back on later to keep AOM warm
        setDigitalChannel(calctime(curtime,50),38,1);
    elseif blue_on == 2
        %using Daniel's laser
        setDigitalChannel(calctime(curtime,0),'404.8nm TTL',0);
    else
    end
    
    if raman_coupling == 1
        %Close Shutters
        setAnalogChannel(calctime(curtime,0),25,0,1);
        setDigitalChannel(calctime(curtime,0),7,1);
        setDigitalChannel(calctime(curtime,0),3,0);
        
        setDigitalChannel(calctime(curtime,0),'405nm Shutter',0);
    end
        
    if D2_on
%         %turn trap off
%         %turn_off_beam(calctime(curtime,0),1,1);
%         setAnalogChannel(calctime(curtime,0),26,0,1);
%         setDigitalChannel(calctime(curtime,0),6,1);
%         setDigitalChannel(calctime(curtime,0),2,0);
        %turn repump off
        %turn_off_beam(calctime(curtime,0),2,1);
        setAnalogChannel(calctime(curtime,0),25,0,1);
        setDigitalChannel(calctime(curtime,0),7,1);
        setDigitalChannel(calctime(curtime,0),3,0);
    else
    end
    
end

%Trigger at End of Molasses
ScopeTriggerPulse(calctime(curtime,0),'D1 Molasses End');


%% In-Trap Optical Pumping After Molasses

if seqdata.flags. in_trap_OP
    
    %Ramp up y shim to quantize, keep x/z shims off
    quant_handover_start = calctime(curtime,lattice_holdtime-10);
    quant_handover_time = 5;
    quant_shim_val = [0,2.45,0];
    
    % ramp shims to quantization field values
    AnalogFuncTo(calctime(quant_handover_start,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(1),3);
    AnalogFuncTo(calctime(quant_handover_start,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(2),4);
    AnalogFuncTo(calctime(quant_handover_start,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_handover_time,quant_handover_time,quant_shim_val(3),3);

    %Turn on OP Light
    
    k_OP_detuning = 40;
    k_probe_pwr = 2*0.17;
    k_op_pwr = 2*0.17;
    K_OP_time = 0.2;
    
    
    %set probe detuning
    setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',200.5); %202.5 for 2G shim
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,-10),'K Trap FM',k_OP_detuning); %40 for 2G shim
    %Set AM for Optical Pumping
    setAnalogChannel(calctime(curtime,-5),'K Probe/OP AM',k_op_pwr,1);%0.65
    %TTL
    DigitalPulse(calctime(curtime,lattice_holdtime - 2 -0.9 - K_OP_time),'K Probe/OP TTL',K_OP_time,0); %0.3
    %Set AM back for imaging
    setAnalogChannel(calctime(curtime,lattice_holdtime - 2 - 0.5),'K Probe/OP AM',k_probe_pwr,1);%0.65
    
    %Turn on Repump
    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-10),3,1);
    %turn repump back up
    setAnalogChannel(calctime(curtime,-10),25,0.7);
    %repump TTL
    setDigitalChannel(calctime(curtime,-10),7,1);
    
    DigitalPulse(calctime(curtime,lattice_holdtime - 2 -0.9 - K_OP_time),7,K_OP_time+0.05,0); %0.3 (needs to be on until OP finishes)
    
    
else
    %Imaging shim is turned on in absorption_image.m
end

%% Turn on a Shim to Image the Atoms (before holding in XDT/Lattice to
%% prevent depolarization and loss)

% if lattice_holdtime>0
%     %Begin ramping shim while atoms are still in the trap
%     ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%     shim_ramp_time = 2;
%     
%     %Ramp shim up for optical pumping
%     AnalogFunc(calctime(curtime,1),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),shim_ramp_time,shim_ramp_time,2.45,0,4);
%     
% else
%     %No hold time, wait 1ms after trap shuts off to begin ramping shim
%     ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%     shim_ramp_time = 2;
%     shim_ramp_delay = 0.5;%0.5
%     
%     
%     AnalogFuncTo(calctime(curtime,shim_ramp_delay),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramp_time,shim_ramp_time,0,3);
%     AnalogFuncTo(calctime(curtime,shim_ramp_delay),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),shim_ramp_time,shim_ramp_time,1,4);
% end

%     ramp_func = @(t,tt,y2,y1)(y1+(y2-y1)*t/tt);
%     AnalogFunc(calctime(curtime,0),'Y Shim',@(t,tt,y2,y1)(ramp_func(t,tt,y2,y1)),1,1,1,0,4);

%% Holdtime in the trap after molasses
    
    %Wait in the lattice for some holdtime before turning off
    curtime = calctime(curtime,lattice_holdtime);
       
    
    
timeout = curtime;
end