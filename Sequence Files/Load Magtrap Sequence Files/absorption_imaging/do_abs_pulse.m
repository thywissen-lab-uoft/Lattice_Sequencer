% Absorption pulse function -- triggers cameras and pulses probe/repump
% RHYS - It would be reasonable to call this as a method of an absorption image class.
function do_abs_pulse(curtime,params,power,flags)

pulse_length = params.timings.pulse_length;

%This is where the cameras are triggered.
ScopeTriggerPulse(curtime,'Camera triggers',pulse_length);

%Trigger the iXon versus the PixelFlys.
if (flags.iXon)
  DigitalPulse(curtime,'iXon Trigger',pulse_length,1);
else
  DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
end
%Rb - Triggers the probe pulses for the actual image.
if strcmp(flags.image_atomtype, 'Rb')
  %Pulse the Rb probe with tthe TTL.
  DigitalPulse(curtime,'Rb Probe/OP TTL',pulse_length,0);
  % Rb F1->F2 pulse
  % RHYS - Should this not happen earlier?
  if flags.do_F1_pulse == 1
    % Pulse repump with AOM AM
    setDigitalChannel(calctime(curtime,-5),'Rb Sci Repump',1);
    setAnalogChannel(calctime(curtime,-0.1),'Rb Repump AM',0.3);
    % All switching of the RP pulse is currently done with the shutter/AM.
    % Need TTL off for this AOM to get better timing.
    setAnalogChannel(calctime(curtime,pulse_length),'Rb Repump AM',0);
    setDigitalChannel(calctime(curtime,pulse_length),'Rb Sci Repump',0);
  end
  %K - Triggers the probe pulses for the actual image.
elseif strcmp(flags.image_atomtype, 'K')
  if ~(flags.High_Field_Imaging)
    DigitalPulse(calctime(curtime,0),'K Probe/OP TTL',pulse_length,1);
    % Set AM for Optical Pumping % RHYS - Why not earlier now that TTL is back?
         setAnalogChannel(calctime(curtime,0),'K Probe/OP AM',power);
    
    setAnalogChannel(calctime(curtime,pulse_length),'K Probe/OP AM',0,1);
  elseif flags.High_Field_Imaging
    extra_wait_time = params.timings.wait_time;
    
    % Pulse the imaging beam
    DigitalPulse(calctime(curtime,extra_wait_time),'K High Field Probe',pulse_length,0);
    
    if flags.Two_Imaging_Pulses
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
    
  end
  %Repump on during the image pulse
  if flags.K_repump_during_image
    DigitalPulse(curtime,'K Repump TTL',pulse_length,0);
  end
end
end