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
function timeout = absorption_image(timein)

%% Loading in parameters times and flags

global seqdata; %Not sure why it is necessary to declare seqdata global at the top of each structure, but should probably stop.
curtime = timein; %Declare the current time reference
ScopeTriggerPulse(curtime,'Start TOF',0.2); %Trigger the scope right at the start of the TOF

%Populate the relevant structures
seqdata.times.tof_start = curtime; %Forms a list of useful time references.
seqdata.flags.absorption_image = Load_Absorption_Image_Flags(); %Load in the flags.
seqdata.params.absorption_image = Load_Absorption_Image_Parameters(); %Load in the parameters.
seqdata.times.tof_end = calctime(curtime,seqdata.params.absorption_image.timings.tof); %Also append the time that the image is actually taken to the time list

%% Override default values for parameters based on conditions
%RHYS - Perhaps these should trigger warning messages that can be overridden rather than a
%change in the flags/parameters set? Not sure what is best.

%Set tof negative if taking an in trap image
if strcmp(seqdata.flags.absorption_image.condition, 'in_trap')
  seqdata.params.absorption_image.timings.tof = -2;
end

%Disable the optical pumping during HF imaging
if seqdata.flags.absorption_image.High_Field_Imaging==1
  seqdata.flags.absorption_image.use_K_OP = 0;
end

%If 40K is definitely in a negative mF state, flip the quantizing shim
if ((seqdata.flags.K_RF_sweep == 1 || seqdata.flags.init_K_RF_sweep == 1) && ...
    strcmp(seqdata.flags.absorption_image.image_atomtype,'K'))
  seqdata.flags.absorption_image.negative_imaging_shim = 'negative'; 
end

%% Shorthand for certain parameters and flags

%Shorthand for convenience
flags = seqdata.flags.absorption_image;
params = seqdata.params.absorption_image;

str=['Absorption Imaging : ' flags.image_atomtype ' ' flags.img_direction ...
    ' ' flags.negative_imaging_shim ' ' flags.condition];
disp(str)


%Get the relevantprobe beam power and detuning... should these be appended back to
%structure?
detuning = params.detunings.(flags.image_atomtype).(flags.img_direction) ...
  .(flags.negative_imaging_shim).(flags.condition);

power = params.powers.(flags.image_atomtype).(flags.img_direction);

rb_detuning_shift_time = params.timings.rb_detuning_shift_time.(flags.img_direction);

k_OP_detuning = params.k_OP_detuning.(flags.negative_imaging_shim);

k_repump_shift = params.k_repump_shift.(flags.negative_imaging_shim);

quant_timings = params.quant_timings.(flags.condition); %This one is a structure.

quant_shim_val = params.quant_shim_val.(flags.img_direction).(flags.negative_imaging_shim);

%% Pulse QP to do SG imaging (uses first several ms of ToF depending on the parameters chosen)
%Do a special set of magnetic field maninpulations if doing
%Stern-Gerlach imaging. Basically pulse the QP field in the presence of a
%vertical bias.
if strcmp(flags.condition, 'SG')
  do_stern_gerlach(seqdata,flags,params.SG)
end

%% Turn on quantizing field for imaging 

%RHYS - Could farm out field ramps to 'Action' files.
%This sets parameters for imaging in the science chamber under most circumstances
if (strcmp(flags.img_direction,'X') || strcmp(flags.img_direction,'Y'))
  if (~strcmp(flags.condition,'in_trap'))
    % Some warnings displayed: still relevant?
    if (quant_timings.quant_handover_delay + quant_timings.quant_handover_time > params.timings.tof)
      buildWarning('absorption_image','Quantization shims are still ramping on during imaging pulse!',1)
    end
    if (quant_timings.quant_handover_fesh_ramptime + quant_timings.quant_handover_fesh_rampdelay + quant_timings.quant_handover_delay > params.timings.tof)
      buildWarning('absorption_image','Quantization ''FB'' field is still ramping on during imaging pulse!')
    end

    % Actually execute the field ramps based on the parameters set prior.
    if (~flags.High_Field_Imaging)
      % start handover to quantization field for imaging
      quant_handover_start = calctime(seqdata.times.tof_start,quant_timings.quant_handover_delay);

      % ramp shims to quantization field values
      AnalogFuncTo(calctime(quant_handover_start,0),'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_timings.quant_handover_time,quant_timings.quant_handover_time,quant_shim_val(1),3);
      AnalogFuncTo(calctime(quant_handover_start,0),'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_timings.quant_handover_time,quant_timings.quant_handover_time,quant_shim_val(2),4);
      AnalogFuncTo(calctime(quant_handover_start,0),'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_timings.quant_handover_time,quant_timings.quant_handover_time,quant_shim_val(3),3);

      % Switch off FB coil if necessary
      if (getChannelValue(seqdata,'FB current',1,0) > 0) && (quant_timings.quant_handover_fesh_ramptime <= 0)
        % hard shut off of FB field
        setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
        setDigitalChannel(calctime(quant_handover_start,0),'fast FB Switch',0); %fast switch
      elseif (getChannelValue(seqdata,'FB current',1,0) > 0) && (quant_timings.quant_handover_fesh_ramptime > 0)
        % ramp FB field
        AnalogFuncTo(calctime(quant_handover_start,quant_timings.quant_handover_fesh_rampdelay),'FB current',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),quant_timings.quant_handover_fesh_ramptime,quant_timings.quant_handover_fesh_ramptime,0);
        setDigitalChannel(calctime(quant_handover_start,quant_timings.quant_handover_time),'fast FB Switch',0); %fast switch
      else
        % FB field already off ... just to be sure
        setAnalogChannel(calctime(quant_handover_start,0),'FB current',-0.5,1);%0
        setDigitalChannel(calctime(quant_handover_start,quant_timings.quant_handover_time),'fast FB Switch',0);
      end

    end

    % eventually set all shims to zero (50ms after image was taken)
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'X Shim',0.0,3);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Y Shim',0.0,4);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Z Shim',0.0,3);

    %Rhys - Why is this required?
    % set FB channel to 0 as well to keep from getting errors in AnalogFuncTo: 
    clear('ramp');
    ramp.fesh_ramptime = 100; 
    ramp.fesh_ramp_delay = -0;
    ramp.fesh_final = 0;
    ramp.settling_time = 10;
    ramp_bias_fields(calctime(curtime,params.timings.tof+50), ramp);
    
    %If imaging in the magnetic trap, do not turn on the quantizing shim.
  elseif strcmp(flags.condition,'in_trap')
    % eventually set all shims to zero (50ms after image was taken)
    % set FB channel to 0 as well to keep from getting errors in AnalogFuncTo
    % %RHYS - These things are going to happen regardless! Remove if statement?
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'X Shim',0,3);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Y Shim',0,4);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Z Shim',0,3);
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'FB current',0,1);
  end
  %If imaging in the MOT, handle the quantizing shims differently.
  elseif (strcmp(flags.img_direction,'MOT'))
    if ~strcmp(flags.condition,'in_trap')
      setAnalogChannel(calctime(curtime,0),'Y Shim',3.5,2); %3.5
    end
    % Turn Y shim off later
    setAnalogChannel(calctime(curtime,params.timings.tof+50),'Y Shim',0.0,2);
end

%% Prepare detunings for optional optical pumping and repump pulses, which occur before the first image.

%Before the actual imaging pulse, perform repump and/or optical
%pumping.
if (~flags.High_Field_Imaging)
  if flags.use_K_repump
    %Repump pulse: off slightly after optical pumping pulse - simulataneous with optical
    %pumping
    DigitalPulse(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Repump TTL',params.timings.K_OP_time+0.2,0);
  end
  
  if flags.use_K_OP
    %set probe detuning
    setAnalogChannel(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP FM',190.0); %202.5 for 2G shim
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Trap FM',k_OP_detuning); %40 for 2G shim
    %Set AM for Optical Pumping
    setAnalogChannel(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP AM',power);%0.65
    %TTL
    DigitalPulse(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP TTL',params.timings.K_OP_time,1); %0.3
    %Turn off AM
    setAnalogChannel(calctime(curtime,params.timings.tof - params.timings.k_detuning_shift_time),'K Probe/OP AM',0,1);   
  end
end


%% Prepare detuning, repump, and probe for the actual image
if(~flags.High_Field_Imaging)
  %K - Set frequency for imaging just before actual image.
  if strcmp(flags.image_atomtype,'K')
    %set probe detuning
    setAnalogChannel(calctime(curtime,params.timings.tof-params.timings.k_detuning_shift_time),'K Probe/OP FM',180);
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,params.timings.tof-params.timings.k_detuning_shift_time),'K Trap FM',detuning);
  end
  
  %Rb - Set frequency for imaging just before actual image. Need more
  %time to set Rb detuning with offset lock.
  if strcmp(flags.image_atomtype,'Rb')
    %offset FF
%     setAnalogChannel(calctime(curtime,params.timings.tof - rb_detuning_shift_time),'Rb Beat Note FF',params.others.RB_FF,1);
%     setAnalogChannel(calctime(curtime,params.timings.tof - rb_detuning_shift_time+2200),'Rb Beat Note FF',10,1);
%     setAnalogChannel(calctime(curtime,params.timings.tof - rb_detuning_shift_time),'Rb Beat Note FM',detuning);
    AnalogFuncTo(calctime(curtime,params.timings.tof - rb_detuning_shift_time),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),rb_detuning_shift_time-200,rb_detuning_shift_time-200, detuning);
    AnalogFuncTo(calctime(curtime,params.timings.tof + 500),'Rb Beat Note FM',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),1000,1000, 6590+32);
  end

  %K - Set power, make sure probe is TTL'd off before image.
  if strcmp(flags.image_atomtype, 'K')
    setAnalogChannel(calctime(curtime,-1+params.timings.tof),'K Probe/OP AM',power); 
  end
  
  %Rb - Set power, make sure probe is TTL'd off before image.
  if strcmp(flags.image_atomtype, 'Rb')
    setAnalogChannel(calctime(curtime,-5+params.timings.tof),'Rb Probe/OP AM',power);
  end
  
  %K High Field Imaging
else
  %RHYS - This could be its own little thing.
  if strcmp(flags.image_atomtype, 'K')
    %set trap detuning
    setAnalogChannel(calctime(curtime,params.timings.tof-params.timings.k_detuning_shift_time),'K Trap FM',detuning);
    
    HF_prob_freq_list = [3.6];%3.75
    HF_prob_freq = getScanParameter(HF_prob_freq_list,seqdata.scancycle,seqdata.randcyclelist,'HF_prob_freq')+ 1.4*(seqdata.HF_FeshValue_final-205)/2; %3.75 for 205G;
    mod_freq =  (120+HF_prob_freq)*1E6;
    mod_amp = 1.5;
    mod_offset =0;
    str=sprintf(':SOUR1:APPL:SIN %f,%f,%f;',mod_freq,mod_amp,mod_offset);
    addVISACommand(3, str);
  end
  
  
end

%% Pre-Absorption Shutter Preperation

%K - Open shutter for probe. 
%RHYS - This is ok, just get rid of blue_image/D1_image and simplify.
if ~(flags.High_Field_Imaging)
  if strcmp(flags.image_atomtype, 'K')
    setDigitalChannel(calctime(curtime, -5+params.timings.tof),'K Probe/OP shutter',1);
    if (flags.use_K_repump || flags.K_repump_during_image)
      %Open science cell K repump shutter
      setDigitalChannel(calctime(curtime,-5+params.timings.tof),'K Sci Repump',1);
      %turn repump back up
      setAnalogChannel(calctime(curtime,-5+params.timings.tof),25,0.8);
      %repump TTL
      setDigitalChannel(calctime(curtime,-5+params.timings.tof),7,1);
      %Frequency shift the repump
      if strcmp(flags.negative_imaging_shim,'negative')
        setAnalogChannel(calctime(curtime,-5+params.timings.tof),'K Repump FM',k_repump_shift,2);
      else
        setAnalogChannel(calctime(curtime,-5+params.timings.tof),'K Repump FM',k_repump_shift,2);
      end
    end
  end
elseif flags.High_Field_Imaging
  %open shutter
  setDigitalChannel(calctime(curtime,-5 + params.timings.tof),'High Field Shutter',1);
  %Close shutter much later
  setDigitalChannel(calctime(curtime,500),'High Field Shutter',0);
end

%Rb (Open the shutters just before the imaging pulse)
if strcmp(flags.image_atomtype, 'Rb')
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

% Take the first absorption image.
do_abs_pulse(curtime,params.timings.pulse_length,power,flags);

% Wait 200 ms for all traces of atoms to be gone 
% RHYS - could be shorter
curtime = calctime(curtime,200); 

% Take the second absorption image
do_abs_pulse(curtime,params.timings.pulse_length,power,flags);

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
addOutputParam('kdet',detuning);
addOutputParam('rbdet',6590-detuning);

timeout=curtime;



end
