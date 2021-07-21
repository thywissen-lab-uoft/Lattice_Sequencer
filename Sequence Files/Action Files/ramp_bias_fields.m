function  timeout = ramp_bias_fields(timein, pars)
%------
%Function call:    timeout = ramp_bias_fields(timein, pars)
%Author: Stefan
%Created: Apr 2014
%Summary: Ramping homogeneous fields (shims and FB) to new values,
%   starting at timein. The argument 'pars' is a struct that contains the
%   ramp parameters. If a ramp parrameter remains unspecified (respective
%   field is missing in 'pars'), it will be set to a default value.
%
% Fields contained in pars and their default values:
%   shim_ramptime (50) -- time for linear shim ramp
%   shim_ramp_delay (-10) -- (possibly negative) delay of the shim ramp
%   xshim_final, yshim final, zshim_final -- values to ramp the shims to.
%       If these fields are missing in pars, they will not be set to 
%       default values in this function and the respective shims will not
%       be ramped.
%   fesh_ramptime (50) -- time for linear FB ramp   
%   fesh_ramp_delay (0) -- (possibly negative) delay of the FB ramp
%   fesh_off_delay (50) -- an extra wait time that is applied when ramping
%       the FB field to zero. This is necessary to let the field fully
%       decay / settle.
%   fesh_final -- value to ramp the FB coil to. See final values for shims.
%   FB_fine_control -- whether to use the voltage-divider option on the FB
%       control voltage.
%   settling_time (50 + fesh_off_delay) -- final wait time to let the
%       fields settle.
%
% Time is advanced in this function to the allow for all ramp delays (this
% may be unneccessary) and ramps to happen and to allow for the settling
% time.
%------

%RHYS - In theory, replaced by rampMagneticFields.m. Compare functionality.
global seqdata;
curtime = timein;

    % shim settings for spectroscopy
    p.shim_ramptime = 50;
    p.shim_ramp_delay = -10; % ramp earlier than FB field if FB field is ramped to zero
    p.shim_ramp_tau = p.shim_ramptime;
    p.shim_ramp_type = 'Linear';
    p.shim_ramp_tau = 50;
    
    % FB coil settings for spectroscopy
    p.fesh_ramptime = 50;
    p.fesh_ramp_delay = -0;
    p.fesh_off_delay = 50; % FB current and field decay slowly. Delaying the TTL switch to give them some time.
    p.FB_fine_control = 0; %Only for currents <19.8A
    p.use_fesh_switch = 1;
        
    p.QP_ramp_delay = 0;
    p.QP_ramptime = 50;
    p.QP_ramptotaltime = p.QP_ramptime;
    p.QP_ramp_type = 'Linear';
    p.QP_ramp_tau = 50;
%     p.QP_FF_ramp_delay = 0;
%     p.QP_FF_ramptime = 50;
    %FF ramp time default values are set below
    
    p.settling_time = 50 + p.fesh_off_delay; % wait after ramps for fields to settle
   
    if exist('pars','var') % copy fields in pars into default structure p above
        if isstruct(pars)
            fields = fieldnames(pars);
            for j = 1:length(fields);
                p.(fields{j}) = pars.(fields{j});
            end
        end
    end
    
    %If QP ramp time is defined, match the FF ramp
    p.QP_FF_ramp_delay = p.QP_ramp_delay;
    p.QP_FF_ramptime = p.QP_ramptime; 
    p.QP_FF_ramptotaltime = p.QP_ramptotaltime;
    
    if (p.FB_fine_control)
        buildWarning('ramp_bias_fields','Careful here: verify that FB fine control option is implemented correctly. (Untested)',1)
    end
    

    %Set shim fields    
    if isfield(p,'xshim_final')
        if strcmp(p.shim_ramp_type, 'Linear')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),27,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.shim_ramptime,p.shim_ramptime,p.xshim_final,3);
        elseif strcmp(p.shim_ramp_type, 'Exponential')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),27,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),p.shim_ramptime,p.shim_ramptotaltime,p.xshim_final,p.shim_ramp_tau,3);            
        end
    end
    if isfield(p,'yshim_final')
        if strcmp(p.shim_ramp_type, 'Linear')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),19,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.shim_ramptime,p.shim_ramptime,p.yshim_final,4);
        elseif strcmp(p.shim_ramp_type, 'Exponential')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),19,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),p.shim_ramptime,p.shim_ramptotaltime,p.yshim_final,p.shim_ramp_tau,4);            
        end
    end
    if isfield(p,'zshim_final')
        if strcmp(p.shim_ramp_type, 'Linear')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),28,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.shim_ramptime,p.shim_ramptime,p.zshim_final,3);
        elseif strcmp(p.shim_ramp_type, 'Exponential')
            AnalogFuncTo(calctime(curtime,p.shim_ramp_delay),28,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),p.shim_ramptime,p.shim_ramptotaltime,p.zshim_final,p.shim_ramp_tau,3);            
        end
    end

    %Set Feshbach field
    if isfield(p,'fesh_final')
        
        %Do not bother trying to ramp or opening a switch if going from 0
        %to 0. Opening the switch induces a small current spike due to a
        %discharging capacitor. 
        if ~(getChannelValue(seqdata,37,1,0) == 0 && p.fesh_final == 0)
            %%%% Does this code work?
            setDigitalChannel(calctime(curtime,p.fesh_ramp_delay-50),31,1);
            %%%%
            AnalogFuncTo(calctime(curtime,p.fesh_ramp_delay),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.fesh_ramptime,p.fesh_ramptime,p.fesh_final);
        end
        
        if p.FB_fine_control %Change to fine control (voltage divider)
            setDigitalChannel(calctime(curtime,0),'FB offset select',0);
            setDigitalChannel(calctime(curtime,0),'FB sensitivity select',1);
            setAnalogChannel(calctime(curtime,0.05),37,p.fesh_final,4);
        else
        end
            if (p.fesh_final == 0 && p.use_fesh_switch == 1) %turn off Feshbach coils with fast switch
                setDigitalChannel(calctime(curtime,p.fesh_off_delay),31,0);
                buildWarning('ramp_bias_fields','Known issue with switching off FB field! Check current monitor!');
            else
            end
    end
    
    
    
    %Set Quadrupole field
    if isfield(p,'QP_final')

            p.QP_FF = 23*(p.QP_final/30); % voltage FF on delta supply
            
            if strcmp(p.QP_ramp_type,'Linear')
                % Ramp up transport supply voltage
                AnalogFuncTo(calctime(curtime,p.QP_FF_ramp_delay),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.QP_FF_ramptime,p.QP_FF_ramptime,p.QP_FF);

                if ~(getChannelValue(seqdata,1,1,0) == 0 && p.QP_final == 0)
                    % Ramp up QP coil current, unless it is going from 0 to 0. 
                    setDigitalChannel(calctime(curtime,p.QP_ramp_delay), 21, 0); % fast QP, 1 is off
                    AnalogFuncTo(calctime(curtime,p.QP_ramp_delay),1,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),p.QP_ramptime,p.QP_ramptime,p.QP_final);
                end

                if (p.QP_final == 0)
                    setDigitalChannel(calctime(curtime,p.QP_ramp_delay+p.QP_ramptime), 21, 1); % fast QP, 1 is off
                    setAnalogChannel(calctime(curtime,p.QP_ramp_delay+p.QP_ramptime+5),1,0);%1
                end
            elseif strcmp(p.QP_ramp_type,'Exponential')
                % Ramp up transport supply voltage
                p.QP_FF_ramptotaltime
                p.QP_FF_ramptime
                AnalogFuncTo(calctime(curtime,p.QP_FF_ramp_delay),18,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),p.QP_FF_ramptime,p.QP_FF_ramptotaltime,p.QP_FF,p.QP_ramp_tau);

                if ~(getChannelValue(seqdata,1,1,0) == 0 && p.QP_final == 0)
                    % Ramp up QP coil current, unless it is going from 0 to 0. 
                    setDigitalChannel(calctime(curtime,p.QP_ramp_delay), 21, 0); % fast QP, 1 is off
                    AnalogFuncTo(calctime(curtime,p.QP_ramp_delay),1,@(t,tt,y1,y2,tau)(ramp_exponential(t,tt,y1,y2,tau)),p.QP_ramptime,p.QP_ramptotaltime,p.QP_final,p.QP_ramp_tau);
                end

                if (p.QP_final == 0)
                    setDigitalChannel(calctime(curtime,p.QP_ramp_delay+p.QP_ramptime), 21, 1); % fast QP, 1 is off
                    setAnalogChannel(calctime(curtime,p.QP_ramp_delay+p.QP_ramptime+5),1,0);%1
                end
            end

    end
    
    
    %advance time to allow for ramps and ramp delays to happen (may be
    % fine to remove this, since fields can be changed during lattice loading)
    curtime=calctime(curtime,max([p.shim_ramptime+p.shim_ramp_delay,p.fesh_ramptime+p.fesh_ramp_delay,p.QP_ramptime+p.QP_ramp_delay ]));


timeout = calctime(curtime,p.settling_time);


end