%Note: curtime is only updated to tof in this code just before the first
%absorption image. Thus, all times before this are referenced to the
%presumed drop time.

function timeout = absorption_image2(timein)

global seqdata; 
curtime = timein; 


ScopeTriggerPulse(curtime,'Start TOF',0.2); %Trigger the scope right at the start of the TOF

%Populate the relevant structures
seqdata.times.tof_start = curtime; %Forms a list of useful time references.

seqdata.flags.absorption_image = Load_Absorption_Image_Flags(); %Load in the flags.
seqdata.params.absorption_image = Load_Absorption_Image_Parameters(); %Load in the parameters.

seqdata.times.tof_end = calctime(curtime,seqdata.params.absorption_image.timings.tof); %Also append the time that the image is actually taken to the time list

%% Override default values for parameters based on conditions
% Set TOF to -2 ms for in trap image (ignore TOF time)
if strcmp(seqdata.flags.absorption_image.condition, 'in_trap')
  seqdata.params.absorption_image.timings.tof = -2;
end

% If 40K is definitely in a negative mF state, flip the quantizing shim
if (...
    seqdata.flags.xdt && ...
    seqdata.flags.xdt_K_p2n_rf_sweep_freq && ...
    (strcmp(seqdata.flags.absorption_image.image_atomtype,'K') || ...
    strcmp(seqdata.flags.absorption_image.image_atomtype,'KRb')))

  seqdata.flags.absorption_image.negative_imaging_shim = 'negative'; 
end

%% Shorthand for certain parameters and flags

%Shorthand for convenience
flags = seqdata.flags.absorption_image;
params = seqdata.params.absorption_image;

% Display the imaging flags (conditions of imaging)
str=['Absorption Imaging : ' flags.image_atomtype ' ' flags.img_direction ...
    ' ' flags.negative_imaging_shim ' ' flags.condition];

% Rb Probe Detuning and Power
Rb_detuning = params.detunings.Rb.(flags.img_direction) ...
    .(flags.negative_imaging_shim).(flags.condition);
Rb_power = params.powers.Rb.(flags.img_direction);

% K Probe Detuning and Power
K_detuning = params.detunings.K.(flags.img_direction) ...
  .(flags.negative_imaging_shim).(flags.condition);
K_power = params.powers.K.(flags.img_direction);

% K Optical Pumping Detuning
k_OP_detuning = params.k_OP_detuning.(flags.negative_imaging_shim);

% K Repump Detuning
k_repump_shift = params.k_repump_shift.(flags.negative_imaging_shim);

% Timings for establishing quantization axis
quant_timings = params.quant_timings.(flags.condition); 

% Shim values for quantization axis
quant_shim_val = params.quant_shim_val.(flags.img_direction).(flags.negative_imaging_shim);


%% Stern Gerlach
% Pulse the QP coils at the beginning of the time of flight to 
% separate F and mF states 

if strcmp(flags.condition, 'SG')
    disp(' Pulsing Stern-Gerlach field.');
    do_stern_gerlach(seqdata,flags,params.SG)
end

%% Turn on quantizing field for imaging 
% Set the quantization axis for imaging.
% For low field imaging, the quantization axis is co-axial with the X or Y
% lattice direction. The direction depends on the which stretched state you
% are trying to image.
%
% The shims are ramped in tandem with the Feshbach coils to keep a well-defined
% mF states (Feshbach defines mF and F during dipole and lattice) 

%This sets parameters for imaging in the science chamber under most circumstances
if (strcmp(flags.img_direction,'X') || strcmp(flags.img_direction,'Y'))
    if (~strcmp(flags.condition,'in_trap'))

        % Some warnings displayed: still relevant?
        if (quant_timings.quant_handover_delay + ...
                quant_timings.quant_handover_time > ...
                params.timings.tof)
          buildWarning('absorption_image',...
              'Quantization shims are still ramping on during imaging pulse!',1)
        end

        if (quant_timings.quant_handover_fesh_ramptime + ...
                quant_timings.quant_handover_fesh_rampdelay + ...
                quant_timings.quant_handover_delay > params.timings.tof)
          buildWarning('absorption_image',...
              'Quantization ''FB'' field is still ramping on during imaging pulse!')
        end

          % Time to beging ramping shims
          quant_handover_start = calctime(seqdata.times.tof_start,...
              quant_timings.quant_handover_delay);

          % Ramp shims to appropriate values
          AnalogFuncTo(calctime(quant_handover_start,0),'X Shim',...
              @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
              quant_timings.quant_handover_time,...
              quant_timings.quant_handover_time,quant_shim_val(1),3);
          AnalogFuncTo(calctime(quant_handover_start,0),'Y Shim',...
              @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
              quant_timings.quant_handover_time,...
              quant_timings.quant_handover_time,quant_shim_val(2),4);
          AnalogFuncTo(calctime(quant_handover_start,0),'Z Shim',...
              @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
              quant_timings.quant_handover_time,...
              quant_timings.quant_handover_time,quant_shim_val(3),3);

          % Turn off FB Field
          if (getChannelValue(seqdata,'FB current',1,0) > 0) && ...
                  (quant_timings.quant_handover_fesh_ramptime <= 0)
            % hard shut off of FB field
            setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
            setDigitalChannel(calctime(quant_handover_start,0),'fast FB Switch',0); %fast switch
          elseif (getChannelValue(seqdata,'FB current',1,0) > 0) ...
                  && (quant_timings.quant_handover_fesh_ramptime > 0)
            % ramp FB field
            AnalogFuncTo(calctime(quant_handover_start,quant_timings.quant_handover_fesh_rampdelay),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_timings.quant_handover_fesh_ramptime,quant_timings.quant_handover_fesh_ramptime,0);
            setDigitalChannel(calctime(quant_handover_start,quant_timings.quant_handover_time),'fast FB Switch',0); %fast switch
          else
            % FB field already off ... just to be sure
            setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
            setDigitalChannel(calctime(quant_handover_start,quant_timings.quant_handover_time),'fast FB Switch',0);
          end
    elseif strcmp(flags.condition,'in_trap')
      % For in-trap imaging, you don't touch the magnetic fields!

    end
  
  % Turn off feshbach sometime after the time of flight
    clear('ramp');
    ramp.fesh_ramptime = 100; 
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 0;
    ramp.settling_time = 10;
    ramp_bias_fields(calctime(curtime,params.timings.tof+50), ramp);
   
    % Turn off the shims sometime after the time of flight
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'X Shim',0,3);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Y Shim',0,4);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Z Shim',0,3);
    
end
%% Prepare detunings for optional optical pumping and repump pulses, which occur before the first image.

%Before the actual imaging pulse, perform repump and/or optical
%pumping.

if flags.use_K_repump
%Repump pulse: off slightly after optical pumping pulse - simulataneous with optical
%pumping
DigitalPulse(calctime(curtime,params.timings.tof - ...
    params.timings.k_detuning_shift_time - params.timings.K_OP_time),...
    'K Repump TTL',params.timings.K_OP_time+0.2,0);
end

if flags.use_K_OP
%set probe detuning
setAnalogChannel(calctime(curtime,params.timings.tof - ...
    params.timings.k_detuning_shift_time - params.timings.K_OP_time),...
    'K Probe/OP FM',190.0); %202.5 for 2G shim
%SET trap AOM detuning to change probe
%     setAnalogChannel(calctime(curtime,params.timings.tof -  ...
%         params.timings.k_detuning_shift_time - params.timings.K_OP_time),...
%         'K Trap FM',k_OP_detuning); %40 for 2G shim
% 2023/11/02 : New addiing a ramp time to allow the injection lock to
% be happy
AnalogFuncTo(calctime(curtime,params.timings.tof - ...
    params.timings.k_detuning_shift_time - params.timings.K_OP_time - 50),...
    'K Trap FM',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),50,50,k_OP_detuning);



%     dispLineStr('oppuping',calctime(curtime,params.timings.tof - ...
%         params.timings.k_detuning_shift_time - params.timings.K_OP_time));
%Set AM for Optical Pumping
setAnalogChannel(calctime(curtime,params.timings.tof - ...
    params.timings.k_detuning_shift_time - params.timings.K_OP_time),...
    'K Probe/OP AM',K_power);%0.65
%TTL
DigitalPulse(calctime(curtime,params.timings.tof - ...
    params.timings.k_detuning_shift_time - params.timings.K_OP_time),...
    'K Probe/OP TTL',params.timings.K_OP_time,1); %0.3   
    %Turn off AM
 setAnalogChannel(calctime(curtime,params.timings.tof - ...
     params.timings.k_detuning_shift_time),'K Probe/OP AM',0,1);   
end



%% Prepare detuning, repump, and probe for the actual image

% The probe beam detuning is set by two double passes

% Set K probe FM
setAnalogChannel(calctime(curtime,...
    params.timings.tof-params.timings.k_detuning_shift_time),...
    'K Probe/OP FM',180);

% Set K Trap FM 
setAnalogChannel(calctime(curtime,...
    params.timings.tof-params.timings.k_detuning_shift_time),...
    'K Trap FM',K_detuning);  

% Set Rb Probe Detuning
f_osc = calcOffsetLockFreq(Rb_detuning,'Probe32');
DDS_id = 3;    
DDS_sweep(curtime,DDS_id,f_osc*1e6,f_osc*1e6,1);    

% Set K probe/OP power 
setAnalogChannel(calctime(curtime,-1+params.timings.tof),...
  'K Probe/OP AM',K_power); 

% Set Rb probe/OP power
setAnalogChannel(calctime(curtime,-5+params.timings.tof),...
  'Rb Probe/OP AM',Rb_power);  
  


%% Pre-Absorption Shutter Preperation

%K - Open shutter for probe. 
%RHYS - This is ok, just get rid of blue_image/D1_image and simplify.


% Open K shutter
if strcmp(flags.image_atomtype, 'K') || strcmp(flags.image_atomtype, 'KRb')

      % Open Probe Shutter in preparation
    setDigitalChannel(calctime(curtime, -5+params.timings.tof),'K Probe/OP shutter',1);
    if (flags.use_K_repump || flags.K_repump_during_image)        

          %k_repump_am_list = [0:.05:.8]; % 
          %k_repump_am = getScanParameter(k_repump_am_list,...
          %seqdata.scancycle,seqdata.randcyclelist,'k_repump_am','V?'); 

          %Open science cell K repump shutter
          setDigitalChannel(calctime(curtime,-5+params.timings.tof),...
              'K Sci Repump',1);             

          %turn repump back up
          setAnalogChannel(calctime(curtime,-5+params.timings.tof),...
              'K Repump AM',.8);.8;
          %repump TTL
          setDigitalChannel(calctime(curtime,-5+params.timings.tof),...
              'K Repump TTL',1);
          %Frequency shift the repump
          if strcmp(flags.negative_imaging_shim,'negative')
              setAnalogChannel(calctime(curtime,-5+params.timings.tof),...
                'K Repump FM',k_repump_shift,2);
          else
              setAnalogChannel(calctime(curtime,-5+params.timings.tof),...
                'K Repump FM',k_repump_shift,2);
          end
    end
end

% Open Rb shutter
if strcmp(flags.image_atomtype, 'Rb') || strcmp(flags.image_atomtype, 'KRb')
    setDigitalChannel(calctime(curtime,-5+params.timings.tof),'Rb Probe/OP shutter',1); %-10
end




%% Take the absorption images

%Trigger the iXon if using this for a vertical absorption image
if (flags.iXon )
  % Clean out trigger for iXON 100ms before image is taken (flush chip)
  DigitalPulse(calctime(curtime,-100),'iXon Trigger',params.timings.pulse_length,1);
end

% Update curtime to the imaging time (add the tof).
curtime = calctime(curtime,params.timings.tof);

plug_check =0;
if plug_check ==1
    pulse_length = params.timings.pulse_length;
    
    setDigitalChannel(calctime(curtime,-5),'Plug Shutter',1);% 0:OFF; 1: ON
    setDigitalChannel(calctime(curtime,pulse_length+.5),'Plug Shutter',0);% 0:OFF; 1: ON
end

tD_list = [-20];-20;
tD=getScanParameter(tD_list,seqdata.scancycle,...
    seqdata.randcyclelist,'pixel_delay','us');

% Take the first absorption image with atoms
tof_krb_diff=getVar('tof_krb_diff');
params.isProgrammedSRS = 0;
params=do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff,tD*1e-3);

% Wait 200 ms for all traces of atoms to be gone 
% RHYS - could be shorter
curtime = calctime(curtime,200); 

% Take the second absorption image without atoms
do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff,tD*1e-3);

%% Dark Image

if flags.TakeDarkImage
    curtime = calctime(curtime,250);
    DigitalPulse(curtime,'PixelFly Trigger',1,1); 
    curtime = calctime(curtime,100);
end

%% Turn Probe and Repump off

curtime = calctime(curtime,100);
%Probe
turn_off_beam(curtime,4);
%Repump
turn_off_beam(curtime,2);

%% Add parameters to output file and timeout of function
addOutputParam('tof',params.timings.tof);
addOutputParam('qqfield1',quant_shim_val(1));
addOutputParam('qqfield2',quant_shim_val(2));
addOutputParam('qqfield3',quant_shim_val(3));
addOutputParam('OP_Detuning', k_OP_detuning)
addOutputParam('kdet',K_detuning);
addOutputParam('rbdet',6590-Rb_detuning);

timeout=curtime;
end

% Absorption pulse function -- triggers cameras and pulses probe/repump
% RHYS - It would be reasonable to call this as a method of an absorption image class.
function params = do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff,tD)
global seqdata
pulse_length = params.timings.pulse_length;

%This is where the cameras are triggered.
ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);

%Trigger the iXon versus the PixelFlys.
if (flags.iXon)
  DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
else

  DigitalPulse(calctime(curtime,tD),'PixelFly Trigger',pulse_length,1);
end


switch flags.image_atomtype
    case 'Rb'
      %Pulse the Rb probe with tthe TTL.
      DigitalPulse(curtime,'Rb Probe/OP TTL',pulse_length,0);      
      if flags.do_F1_pulse == 1
        % Pulse repump with AOM AM
        setDigitalChannel(calctime(curtime,-5),'Rb Sci Repump',1);
        setAnalogChannel(calctime(curtime,-0.1),'Rb Repump AM',0.3);
        % All switching of the RP pulse is currently done with the shutter/AM.
        % Need TTL off for this AOM to get better timing.
        setAnalogChannel(calctime(curtime,pulse_length),'Rb Repump AM',0);
        setDigitalChannel(calctime(curtime,pulse_length),'Rb Sci Repump',0);
      end
    case 'K'
        
        DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,1);


        % Open and close shutter
        setDigitalChannel(calctime(curtime, -5),'K Probe/OP shutter',1);
        setDigitalChannel(calctime(curtime, pulse_length+.5),'K Probe/OP shutter',0);

        % Turn AM on and off if need
        setAnalogChannel(calctime(curtime,-.5),'K Probe/OP AM',K_power);
        setAnalogChannel(calctime(curtime,pulse_length+.5),'K Probe/OP AM',0,1);
        
        %Repump on during the image pulse
        if flags.K_repump_during_image
            DigitalPulse(curtime,'K Repump TTL',pulse_length,0);
        end
    case 'KRb'
        % Something doesn't make 100% sense with teh timings, may need to
        % do reanalysis of timings, but we're talking 10us here, so it's
        % okay qualitatively
        
        % Time to start first exposure
        Tstart1 = params.timings.wait_time;        
        buffer_time = 0.01;
        
        % Time to start second exposure
        % (initial delay, pulse time, time diff between exposures)
        Tstart2=params.timings.wait_time+pulse_length+...
            params.timings.time_diff_two_absorp_pulses-buffer_time+tof_krb_diff;
                        

        % K Probe pulse
         DigitalPulse(calctime(curtime,Tstart1),...
             'K Probe/OP TTL',pulse_length,1);
         
         % Turn AM on and off if needed
         setAnalogChannel(calctime(curtime,Tstart1-.5),'K Probe/OP AM',K_power);
         setAnalogChannel(calctime(curtime,Tstart1+pulse_length+.5),'K Probe/OP AM',0,1);
      
         % Open and close shutter
         setDigitalChannel(calctime(curtime, Tstart1-5),'K Probe/OP shutter',1);
         setDigitalChannel(calctime(curtime, Tstart1+pulse_length+.5),'K Probe/OP shutter',0);

        %Repump on during the image pulse
         if flags.K_repump_during_image
             DigitalPulse(calctime(curtime,Tstart1),...
                'K Repump TTL',pulse_length,0);
         end
        
        % Rb Probe Pulse
        DigitalPulse(calctime(curtime,Tstart2),'Rb Probe/OP TTL',...
            pulse_length+2*buffer_time,0);        
       
        
        % Open and close shutter
            setDigitalChannel(calctime(curtime, Tstart2-5),'Rb Probe/OP shutter',1);
            setDigitalChannel(calctime(curtime, Tstart2+pulse_length+.5),'Rb Probe/OP shutter',0);

        if flags.do_F1_pulse == 1
            % Pulse repump with AOM AM
            setDigitalChannel(calctime(curtime,Tstart2-5),'Rb Sci Repump',1);
            setAnalogChannel(calctime(curtime,Tstart2-0.1),'Rb Repump AM',0.3);
           
            
            % All switching of the RP pulse is currently done with the shutter/AM.
            % Need TTL off for this AOM to get better timing.
            setAnalogChannel(calctime(curtime,Tstart2+pulse_length),'Rb Repump AM',0);
            setDigitalChannel(calctime(curtime,Tstart2+pulse_length),'Rb Sci Repump',0);
        end        
    otherwise
        error('YOU FUCKED UP NO ATOM CHOSEN');        
end
        

end