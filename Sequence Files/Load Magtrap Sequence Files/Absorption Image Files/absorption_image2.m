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

% Disable the optical pumping during HF imaging
if seqdata.flags.absorption_image.High_Field_Imaging==1
  seqdata.flags.absorption_image.use_K_OP = 0;
end

% If 40K is definitely in a negative mF state, flip the quantizing shim
if ((seqdata.flags.init_K_RF_sweep == 1) && ...
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
% disp(str)
% disp(flags)

% Grab the relevant parameters
% detuning = params.detunings.(flags.image_atomtype).(flags.img_direction) ...
%   .(flags.negative_imaging_shim).(flags.condition);
% power = params.powers.(flags.image_atomtype).(flags.img_direction);

% Rb Settings
Rb_detuning = params.detunings.Rb.(flags.img_direction) ...
  .(flags.negative_imaging_shim).(flags.condition);
Rb_power = params.powers.Rb.(flags.img_direction);
rb_detuning_shift_time = params.timings.rb_detuning_shift_time.(flags.img_direction);

% K Settings
K_detuning = params.detunings.K.(flags.img_direction) ...
  .(flags.negative_imaging_shim).(flags.condition);
K_power = params.powers.K.(flags.img_direction);
k_OP_detuning = params.k_OP_detuning.(flags.negative_imaging_shim);
k_repump_shift = params.k_repump_shift.(flags.negative_imaging_shim);

% Quantization axis settings
quant_timings = params.quant_timings.(flags.condition); %This one is a structure.
quant_shim_val = params.quant_shim_val.(flags.img_direction).(flags.negative_imaging_shim);


%% Pulse QP to do SG imaging (uses first several ms of ToF depending on the parameters chosen)
%Do a special set of magnetic field maninpulations if doing
%Stern-Gerlach imaging. Basically pulse the QP field in the presence of a
%vertical bias.
if strcmp(flags.condition, 'SG')
    disp(' Pulsing Stern-Gerlach field.');
  do_stern_gerlach(seqdata,flags,params.SG)
end

%% Turn on quantizing field for imaging 

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
    setAnalogChannel(calctime(curtime,params.timings.tof - ...
        params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP FM',190.0); %202.5 for 2G shim
    %SET trap AOM detuning to change probe
    setAnalogChannel(calctime(curtime,params.timings.tof - ...
        params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Trap FM',k_OP_detuning); %40 for 2G shim
    %Set AM for Optical Pumping
    setAnalogChannel(calctime(curtime,params.timings.tof - ...
        params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP AM',K_power);%0.65
    %TTL
    DigitalPulse(calctime(curtime,params.timings.tof - ...
        params.timings.k_detuning_shift_time - params.timings.K_OP_time),'K Probe/OP TTL',params.timings.K_OP_time,1); %0.3
    
    
    %Turn off AM
     setAnalogChannel(calctime(curtime,params.timings.tof - ...
         params.timings.k_detuning_shift_time),'K Probe/OP AM',0,1);   
  end
end


%% Prepare detuning, repump, and probe for the actual image
if(~flags.High_Field_Imaging)
    
  % Set K probe Detuning for pump and probe
  setAnalogChannel(calctime(curtime,...
        params.timings.tof-params.timings.k_detuning_shift_time),'K Probe/OP FM',180);
  setAnalogChannel(calctime(curtime,...
        params.timings.tof-params.timings.k_detuning_shift_time),'K Trap FM',K_detuning);  
  
  % Set Rb probe detuning via offset lock
  AnalogFuncTo(calctime(curtime,...
      params.timings.tof - rb_detuning_shift_time),'Rb Beat Note FM',...
      @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
      rb_detuning_shift_time,rb_detuning_shift_time, Rb_detuning);
  
  % Set Rb probe back to "original" value much later
  AnalogFuncTo(calctime(curtime,...
      params.timings.tof + 500),'Rb Beat Note FM',...
      @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),...
      1000,1000, 6590+32);

  % Set K probe/OP power 
  setAnalogChannel(calctime(curtime,-1+params.timings.tof),...
      'K Probe/OP AM',K_power); 

  % Set Rb probe/OP power
  setAnalogChannel(calctime(curtime,-5+params.timings.tof),...
      'Rb Probe/OP AM',Rb_power);  
  
else
  if strcmp(flags.image_atomtype, 'K')
    %K High Field Imaging
    % Set the detunings for the High Field imaging
      
    % Set Trap FM detuning for FB field
    setAnalogChannel(calctime(curtime,params.timings.tof-params.timings.k_detuning_shift_time),...
            'K Trap FM',K_detuning+(seqdata.params.HF_probe_fb-190)*0.675*2);

    HF_prob_freq9 =  params.detunings.K.X.negative9.HF.normal;
    HF_prob_freq7 =  params.detunings.K.X.negative7.HF.normal;

    % Frequency of rigol is based on the relative shift
    freq1 = (120+HF_prob_freq7)*1E6;
    freq2 = (120+HF_prob_freq9)*1E6;

    % Power in -7 beam
    pow1_list = [0.8];[0.8];
    pow1 = getScanParameter(pow1_list,seqdata.scancycle,seqdata.randcyclelist,...
        'HF_prob_pwr1','V');

    % Power in -9 beam
    pow2_list = [1];        
    pow2 = getScanParameter(pow2_list,seqdata.scancycle,seqdata.randcyclelist,...
        'HF_prob_pwr2','V');

    % Rigol Channel 1 (-7 HF high field imaging)
    ch1=struct;
    ch1.STATE='ON';
    ch1.AMPLITUDE=pow1;
    ch1.FREQUENCY=freq1;

    % Rigol Channel 2 (-9 HF high field imaging)
    ch2=struct;
    ch2.STATE='ON';
    ch2.AMPLITUDE=pow2;
    ch2.FREQUENCY=freq2;   

    % Rigol address # 
    addr=6;     
    programRigol(addr,ch1,ch2);     
  end 
  
end

%% Pre-Absorption Shutter Preperation

%K - Open shutter for probe. 
%RHYS - This is ok, just get rid of blue_image/D1_image and simplify.
if ~(flags.High_Field_Imaging)
    
  % Open K shutter
  if strcmp(flags.image_atomtype, 'K') || strcmp(flags.image_atomtype, 'KRb')
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
  
  % Open Rb shutter
  if strcmp(flags.image_atomtype, 'Rb') || strcmp(flags.image_atomtype, 'KRb')
    setDigitalChannel(calctime(curtime,-5+params.timings.tof),'Rb Probe/OP shutter',1); %-10
  end
  
  
elseif flags.High_Field_Imaging
  %open shutter
  setDigitalChannel(calctime(curtime,-5 + params.timings.tof),'High Field Shutter',1);
  %Close shutter much later
  setDigitalChannel(calctime(curtime,500),'High Field Shutter',0);
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
tof_krb_diff=seqdata.params.tof_krb_diff;
do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff);

% Wait 200 ms for all traces of atoms to be gone 
% RHYS - could be shorter
curtime = calctime(curtime,200); 

% Take the second absorption image
do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff);

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
function do_abs_pulse2(curtime,params,flags,K_power,tof_krb_diff)
global seqdata
pulse_length = params.timings.pulse_length;

%This is where the cameras are triggered.
ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);

%Trigger the iXon versus the PixelFlys.
if (flags.iXon)
  DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
else
  DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
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
        if ~(flags.High_Field_Imaging)
            DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,1);
            
            
             % Open and close shutter
             setDigitalChannel(calctime(curtime, -5),'K Probe/OP shutter',1);
             setDigitalChannel(calctime(curtime, pulse_length+.5),'K Probe/OP shutter',0);
            
            % Turn AM on and off if need
               setAnalogChannel(calctime(curtime,-.5),'K Probe/OP AM',K_power);
              setAnalogChannel(calctime(curtime,pulse_length+.5),'K Probe/OP AM',0,1);
        elseif flags.High_Field_Imaging
            extra_wait_time = params.timings.wait_time;
            % Pulse the imaging beam
            DigitalPulse(calctime(curtime,extra_wait_time),'K High Field Probe',pulse_length,0);
            if flags.Two_Imaging_Pulses==1 && flags.Spin_Flip_79_in_Tof == 0
                % Pulse the imaging beam again
                DigitalPulse(calctime(curtime,params.timings.time_diff_two_absorp_pulses+pulse_length+extra_wait_time),...
                    'K High Field Probe',pulse_length,0);
                if flags.Image_Both97
                    % Switch RF source if imaging both
                    buffer_time = 0.01;
                    DigitalPulse(calctime(curtime,...
                        params.timings.time_diff_two_absorp_pulses+pulse_length+extra_wait_time-buffer_time),...
                    'HF freq source',pulse_length+buffer_time+buffer_time,0);               
   
                end
            end
            if flags.Two_Imaging_Pulses==1 && flags.Spin_Flip_79_in_Tof == 1
                % Pulse the imaging beam again
                DigitalPulse(calctime(curtime,params.timings.time_diff_two_absorp_pulses...
                    +pulse_length+extra_wait_time),...
                    'K High Field Probe',pulse_length,0);
                if flags.Image_Both97
                    %%%%%%%%%%%%%%%%%%%%%%%%%%rf pulse
%                     mF1=-9/2;
%                     mF2=-7/2;    
% 
%                     disp(' Rabi Oscillations Manual');
%                     clear('rabi');
%                     rabi=struct;          
% 
%                     Boff = 0.11;
%                     B = seqdata.params.HF_probe_fb+ Boff;
%                     rf_list =[0]+...
%                         (BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6;
%                     rabi.freq = getScanParameter(rf_list,seqdata.scancycle,...
%                         seqdata.randcyclelist,'rf_rabi_freq_HF','MHz');[0.0151];
%                     power_list =  [8];
%                     rabi.power = getScanParameter(power_list,...
%                         seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_power_HF','V');            
%             %             rf_pulse_length_list = [0.5]/15;
%                     rabi.wait_time = [0.01];
% 
%                     if (rabi.freq < 10)
%                          error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
%                     end
% 
%                     rf_pulse_length_list = [0.01:0.01:0.1]; 
% 
%                     rabi.pulse_length = getScanParameter(rf_pulse_length_list,...
%                         seqdata.scancycle,seqdata.randcyclelist,'rf_rabi_time_HF','ms');  % also is sweep length  0.5               
% 
%                     % Define the frequency
%                     dTP=0.1;
%                     DDS_ID=1; 
%                     sweep=[DDS_ID 1E6*rabi.freq 1E6*rabi.freq rabi.pulse_length+2];
% 
% 
%                     % Preset RF Power
%                     setAnalogChannel(calctime(curtime,...
%                         rabi.wait_time + pulse_length + extra_wait_time-5),'RF Gain',rabi.power);         
%                     setDigitalChannel(calctime(curtime,rabi.wait_time + pulse_length + extra_wait_time-5),'RF/uWave Transfer',0);             
% 
%                     % Enable the ACync
%                     do_ACync_rf = 0;
%                     if do_ACync_rf
%                         ACync_start_time = calctime(curtime,1);
%                         ACync_end_time = calctime(curtime,1+rabi.pulse_length+35);
%                         curtime=setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
%                         setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);                
%                     end         
% 
%                     % Apply the RF
%                     if rabi.pulse_length>0                
%                         % Trigger the DDS 1 ms ahead of time
%                         DigitalPulse(calctime(curtime, ...
%                             rabi.wait_time + pulse_length + extra_wait_time - 1),'DDS ADWIN Trigger',dTP,1);  
%                         seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
%                         seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;     
% 
%                         % Turn on RF
%                         setDigitalChannel(calctime(...
%                             curtime, rabi.wait_time + pulse_length + extra_wait_time),'RF TTL',1);      
% 
%                         % Advance by pulse time
% %                         curtime=calctime(curtime,rabi.pulse_length);
% 
%                         % Turn off RF
%                         setDigitalChannel(calctime(...
%                             curtime,rabi.wait_time + ...
%                             extra_wait_time + pulse_length + rabi.pulse_length),'RF TTL',0);      
%                     end
% 
%                     % Lower the power
%                     setAnalogChannel(calctime(curtime,...
%                         rabi.wait_time + pulse_length + extra_wait_time + rabi.pulse_length + 1),'RF Gain',-10); 
%                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%rf pulse
                    

                    mF1=-9/2;   % Lower energy spin state
                    mF2=-7/2;   % Higher energy spin state

                    % Get the center frequency
                    Boff = 0.11;
                    B = seqdata.params.HF_probe_fb+ Boff;
                    rf_list =  [61]*1e-3 +...  %37.5 42.5   12.5 17.5 22.5 0:5:25 30 40:5:60 70
                        abs((BreitRabiK(B,9/2,mF2) - BreitRabiK(B,9/2,mF1))/6.6260755e-34/1E6);            
                    rf_freq_HF = getScanParameter(rf_list,seqdata.scancycle,...
                        seqdata.randcyclelist,'rf_freq_HF','MHz');
                    
                    rf_wait_time = 0.1;

                    if (rf_freq_HF < 1)
                         error('Incorrect RF frequency calculation!! MATLAB IS STUPID! >:(')
                    end

                    % Define the sweep parameters
                    delta_freq= 0.1; %0.02            
                    addOutputParam('rf_delta_freq_HF',delta_freq,'MHz');

                    % RF Pulse 
                    rf_pulse_length_list = 0.8;%1
                    rf_pulse_length = getScanParameter(rf_pulse_length_list,seqdata.scancycle,...
                        seqdata.randcyclelist,'rf_pulse_length');

%                     freq_list=rf_freq_HF+[...
%                         -0.5*delta_freq ...
%                         -0.5*delta_freq ...
%                         0.5*delta_freq ...
%                         0.5*delta_freq];    
                    freq_list=rf_freq_HF+[...
                        -0.5*delta_freq ...
                        0.5*delta_freq ...
                        ];       
                    pulse_list=[rf_pulse_length];

                    % Max rabi frequency in volts (uncalibrated for now)
                    off_voltage=-10;
                    peak_voltage=2.5;

                    % Display the sweep settings
                    disp([' Freq Center    (MHz) : [' num2str(rf_freq_HF) ']']);
                    disp([' Freq List    (MHz) : [' num2str(freq_list) ']']);
                    disp([' Time List     (ms) : [' num2str(pulse_list) ']']);
                    disp([' RF Gain Range  (V) : [' num2str(off_voltage) ' ' num2str(peak_voltage) ']']);


                    % Set RF gain to zero a little bit before
                    setAnalogChannel(calctime(curtime,-40),'RF Gain',off_voltage);   

                    % Turn on RF
                    setDigitalChannel(calctime(curtime,...
                        rf_wait_time + pulse_length + extra_wait_time),'RF TTL',1);   

                    % Set to RF
%                     setDigitalChannel(curtime,'RF/uWave Transfer',0);   

                    do_ACync_rf = 0;
                    if do_ACync_rf
                        ACync_start_time = calctime(curtime,-30);
                        ACync_end_time = calctime(curtime,sum(pulse_list)+30);
                        setDigitalChannel(calctime(ACync_start_time,0),'ACync Master',1);
                        setDigitalChannel(calctime(ACync_end_time,0),'ACync Master',0);
                    end

                    % Trigger pulse duration
                    dTP=0.1;
                    DDS_ID=1;

                    % Initialize "Sweep", ramp up power        
                    sweep=[DDS_ID 1E6*freq_list(1) 1E6*freq_list(2) pulse_list(1)];
                    DigitalPulse(calctime(curtime,...
                        rf_wait_time + pulse_length + extra_wait_time),'DDS ADWIN Trigger',dTP,1);               
                    seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
                    seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
%                     curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
%                         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%                         pulse_list(1),pulse_list(1),peak_voltage); 
                    setAnalogChannel(calctime(curtime,...
                        rf_wait_time + pulse_length + extra_wait_time -1),'RF Gain',peak_voltage)

%                     % Primary Sweep, constant power            
%                     sweep=[DDS_ID 1E6*freq_list(2) 1E6*freq_list(3) pulse_list(2)];
%                     DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);  
%                     seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
%                     seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
%                     curtime=calctime(curtime,pulse_list(2));
% 
%                     % Final "Sweep", ramp down power
%                     sweep=[DDS_ID 1E6*freq_list(3) 1E6*freq_list(4) pulse_list(3)];
%                     DigitalPulse(curtime,'DDS ADWIN Trigger',dTP,1);               
%                     seqdata.numDDSsweeps=seqdata.numDDSsweeps+1;               
%                     seqdata.DDSsweeps(seqdata.numDDSsweeps,:)=sweep;               
%                     curtime=AnalogFuncTo(calctime(curtime,0),'RF Gain',...
%                         @(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),...
%                         pulse_list(1),pulse_list(1),off_voltage); 

                    setAnalogChannel(calctime(curtime,...
                        rf_wait_time + pulse_length + extra_wait_time ...
                        + rf_pulse_length +1),'RF Gain',off_voltage)

                    % Turn off RF
                    setDigitalChannel(calctime(curtime,...
                      rf_wait_time + pulse_length + extra_wait_time + rf_pulse_length),'RF TTL',0);               



                      % Switch RF source if imaging both
%                     buffer_time = 0.01;
%                     DigitalPulse(calctime(curtime,...
%                         params.timings.time_diff_two_absorp_pulses+pulse_length+extra_wait_time-buffer_time),...
%                     'HF freq source',pulse_length+buffer_time+buffer_time,0);               
   
                end
            end
    
        end
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