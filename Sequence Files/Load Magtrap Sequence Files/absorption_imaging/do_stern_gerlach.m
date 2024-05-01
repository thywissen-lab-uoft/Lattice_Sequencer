function do_stern_gerlach(seqdata,flags,params)

%% Ramp up the shims

  %RHYS - Should this be done with one of the 'ramp magnetic fields' type functions?
  % Ramp up the shims to flatten out gradient and set gradient direction
  if (params.SG_shim_ramptime >= 0)
    AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_shim_rampdelay), ...
      'X Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ...
      params.SG_shim_ramptime,params.SG_shim_ramptime,params.SG_shim_val(1),3);
    AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_shim_rampdelay), ...
      'Y Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ...
      params.SG_shim_ramptime,params.SG_shim_ramptime,params.SG_shim_val(2),4);
    AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_shim_rampdelay), ...
      'Z Shim',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), ...
      params.SG_shim_ramptime,params.SG_shim_ramptime,params.SG_shim_val(3),3);
    
    %For some reason, we are keeping track of the current shim values in a
    %separate variable?
    seqdata.params.shim_val(1) = params.SG_shim_val(1);
    seqdata.params.shim_val(2) = params.SG_shim_val(2);
    seqdata.params.shim_val(3) = params.SG_shim_val(3);
  end
  
%% Ramp down the Feshbach field
  % Turn down the FB field (unless doing imaging at high field).
  if (params.SG_fesh_ramptime >= 0)
    % If the desired value is greater than 0, ramp to this value.
    if params.SG_fesh_val > 0
      % switch on and ramp to value
      setDigitalChannel(calctime(seqdata.times.tof_start,params.SG_fesh_rampdelay), ...
        'fast FB switch',1);
      if (getChannelValue(seqdata,'FB current',1,1) > 0) % ramp from previous set value
        AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_fesh_rampdelay),'FB current', ...
          @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_fesh_ramptime,params.SG_fesh_ramptime,params.SG_fesh_val);
      else % Force the ramp to start from zero: this is a good idea for channels that regular have their values set to negative.
        AnalogFunc(calctime(seqdata.times.tof_start,params.SG_fesh_rampdelay),'FB current', ...
          @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_fesh_ramptime,params.SG_fesh_ramptime,0,params.SG_fesh_val);
      end
    % If the desired value is <= 0, ramp down to it if not already <=0 0.
    else
      if (getChannelValue(seqdata,'FB current',1,1) > 0) % ramp to zero
        AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_fesh_rampdelay),'FB current', ...
          @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_fesh_ramptime,params.SG_fesh_ramptime,0);
      end
    end
  end
  
  %% Ramp the gradient up and down.
  
  % Ramp up transport supply voltage
  AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_wait_TOF),'Transport FF',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_QP_ramptime,params.SG_QP_ramptime,params.SG_QP_FF);
  % Ramp up QP
  AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_wait_TOF),'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_QP_ramptime,params.SG_QP_ramptime,params.SG_QP_val);
  % pulse QP
  DigitalPulse(calctime(seqdata.times.tof_start,params.SG_wait_TOF), 'Coil 16 TTL', params.SG_QP_pulsetime, 0); % fast QP
  DigitalPulse(calctime(seqdata.times.tof_start,params.SG_wait_TOF), '15/16 Switch', params.SG_QP_pulsetime, 1); % 15/16 switch
  % Ramp down transport supply voltage
  AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_wait_TOF+params.SG_QP_pulsetime-params.SG_QP_ramptime),'Transport FF',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_QP_ramptime,params.SG_QP_ramptime,-0.2,1);
  % Ramp down QP
  AnalogFuncTo(calctime(seqdata.times.tof_start,params.SG_wait_TOF+params.SG_QP_pulsetime-params.SG_QP_ramptime),'Coil 16',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),params.SG_QP_ramptime,params.SG_QP_ramptime,0,1); 
  % Record QP value for later "shutoff"
  seqdata.params.QP_val = params.SG_QP_val;
  
end