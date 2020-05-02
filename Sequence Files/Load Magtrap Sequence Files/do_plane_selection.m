function timeout = do_plane_selection(timein, varargin)
%This function performs the plane selection sequence, taking inputs
%corresponding to the desired types of kills, sweeps, and associated
%parameters. 


%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;
curtime = timein;

% the number of necessary input arguments (including timein)
narginfix = 1;

% Define valid options for this function and their default values here.
opt = struct('X_Shim_Offset', [], ... offset for the X Shim.
             'Y_Shim_Offset', [], ... offset for the Y Shim.
             'Z_Shim_Offset', [], ... offset for the Z Shim.
             'Ramp_Fields', 1, ... to ramp the fields, or not to ramp them.
             'QP_Selection_Gradient', 7*1.78, ... gradient for plane selection.
             'QP_Kill_Gradient', 0, ... gradient for kill.
             'Feshbach_Level', 2*22.6, ... feshbach level for plane selection.
             'Selection_Range', 10/1000, ... range of sweep for plane selection.
             'Selection__Frequency', 1186.107 - 0.035 - 0.400 - 0.897, ... frequency for plane selection.
             'Initial_Transfer', 1, ... transfer all atoms to 7/2 initially?
             'Initial_Transfer_Frequency_Range', [], ... sweep range for initial transfer.
             'Microwave_Power_For_Selection', -12, ... microwave power for selection.
             'Sweep_About_Central_Frequency', 1, ... set to 1 to have plane selection be centred on input frequency. Else, it is start frequency. 
             'Microwave_Pulse_Length', 16.7 ... length of time for micrwave pulse. Often multiple of a period of 60Hz AC.
         );
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input is timein')
elseif (nargin >= narginfix)
    % an appropriate number of input arguments -- check their validity
end

% checking the optional input arguments
if ( ~isempty(varargin) )
    optnames = {};
    optvalues = {};

    % if first optional arguments are structures, read in their fields first
    while ( isstruct(varargin{1}) )
        addnames = fieldnames(varargin{1});
        for j = 1:length(addnames)
            optnames{end+1} = addnames{j};
            optvalues{end+1} = varargin{1}.(addnames{j});
        end
        varargin = varargin(2:end); % remove first argument from list
        if ( isempty(varargin) ); break; end
    end 

    % check that there is an even number of remaining optional arguments
    if mod(length(varargin),2)
        error('Optional arguments must be given in pairs ...''name'',value,... !');
    else
        for j = 1:(length(varargin)/2)
            % check that the first part of each pair is a string
            if ~ischar(varargin{2*j-1})
                error('Optional arguments must be given in pairs ...''name'',value,... !');
            else
                optnames{end+1} = varargin{2*j-1};
                optvalues{end+1} = varargin{2*j};
            end
        end
    end

    % assigning values to optional arguments to fields of structure 'opt',
    % provided that these fields were initialized above
    for j =1:length(optnames)
        % check that the option is valid; i.e. defined as a field of the
        % structure opt. Make it an error if needed.
        if ~isfield(opt,optnames{j})
            disp([mename '::Unknown option ''' optnames{j} ''' !']);
            % error('Unknown option ''' optnames{j} ''' !'); 
        else
            opt.(optnames{j}) = optvalues{j};
        end
    end

    clear('varargin','optnames','optvalues');
    
end

%%
    
    % Ramp up gradient and Feshbach field
        
        FB_init = getChannelValue(seqdata,37,1,0);
        if opt.Ramp_Fields
            
            newramp = struct('FeshValue',opt.Feshbach_Level,'QPValue',opt.QP_Selection_Gradient,'SettlingTime',200);

curtime = rampMagneticFields(calctime(curtime,0), newramp);

        end

    % Do uWave sweep to transfer plane(s)
        spect_pars.freq = opt.Selection_Frequency;
        addOutputParam('freq_val',df)
        spect_pars.power = opt.Microwave_Power_For_Selection; %-15 %uncalibrated "gain" for rf
        spect_pars.delta_freq = opt.Selection_Range; %300
        spect_pars.mod_dev = opt.Selection_Range; %Frequency range of SRS (MHz/V, input range is +/-1V)
        
        %Quick little addition to start at freq_val instead.
        if(~opt.Sweep_About_Central_Frequency)
            spect_pars.freq = spect_pars.freq + spect_pars.delta_freq / 2;
        end
        
        spect_pars.pulse_length = opt.Microwave_Pulse_Length; % also is sweep length (max is Keithley time - 20ms)       1*16.7
        spect_pars.uwave_delay = 0; %wait time before starting pulse
        spect_pars.uwave_window = 45; % time to wait during 60Hz sync pulse (Keithley time +20ms)
        spect_type = 1; %1: sweeps, 2: pulse, 7: 60Hz sync sweeps
        sweep_field = 1; %0 to sweep with SRS, 1 to sweep with z Shim
                %Options for spect_type = 1
                spect_pars.pulse_type = 1;  %0 - Basic Pulse; 1 - Ramp amplitude with min-jerk
                spect_pars.AM_ramp_time = 2*16.7; %Used for pulse_type = 1      2*16.7
 
        if opt.Initial_Transfer
            
            %Save pulse settings for plane selection
            selection_pulse_length = spect_pars.pulse_length;
            selection_delta_freq = spect_pars.delta_freq;
            
            if (sweep_field == 0)
            %Transfer all atoms to F=7/2 first
            spect_pars.mod_dev = 900/1000; %Mod dev needs to be big enough for a wide initial sweep
            spect_pars.delta_freq = 1800/1000;
            spect_pars.pulse_length = 100;
        
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % first sweep (note: this one moves with the center frequency!)

curtime = calctime(curtime,200); % wait to allow SRS to settle at new frequency

            elseif (sweep_field == 1)
                
                %SRS in pulsed mode with amplitude modulation
                spect_type = 2;
                
                % set to resonance in gradient field
%                 spect_pars.freq = 1186.107 - 35/1000 - 897/1000 - 170/1000; %MHz (1186.107 for 2*22.6 FB)

                %Take frequency range in MHz, convert to shim range in Amps (-5.714 MHz/A on Jan 29th 2015)
                dBz = 1.80 / (-5.714); % sweeping over a large range (equiv to 1800kHz) to transfer the full cloud.
                selection_pulse_length = spect_pars.pulse_length;
                spect_pars.pulse_length = 100;
                spect_pars.SRS_select = 0; %Use SRS A for the global sweep
                
                init_sweep_time = 80;
                field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
                field_shift_settle = 40; % settling time after initial and final field shifts

                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;

                %Ramp shim to start value before generator turns on
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_start;

                ramp_bias_fields(calctime(curtime,0), ramp);

                %Ramp shim during uwave pulse to transfer atoms
                ramp.shim_ramptime = init_sweep_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay;
                ramp.zshim_final = z_shim_sweep_final;

                ramp_bias_fields(calctime(curtime,0), ramp);

                %Ramp shim back to initial value after pulse is complete
                clear('ramp');
                ramp.shim_ramptime = field_shift_time;
                ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
                ramp.zshim_final = z_shim_sweep_center;

                ramp_bias_fields(calctime(curtime,0), ramp);
            
            
            %Do plane selection pulse
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
            
            % wait time (code related -- need to accomodate for AnalogFuncTo
            % calls to the past in rf_uwave_spectroscopy)
curtime = calctime(curtime,100);

            end

            clean_up_pulse = 1;
            if clean_up_pulse
                %Resonant light pulse to remove any untransferred atoms from F=9/2
                kill_probe_pwr = 0.3;
                kill_time = 0.5;
                kill_detuning = -8; %-8 MHz to be resonant with |9/2,9/2> -> |11/2,11/2> transition in 40G field
                
                pulse_offset_time = -100; %Need to step back in time a bit to do the kill pulse
                                          % directly after transfer, not after the subsequent wait times
                
                %set probe detuning
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Probe/OP FM',190); %195
                %set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),'K Trap FM',kill_detuning); %54.5
                
                %open K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time-10),30,1); %0=closed, 1=open
                %turn up analog
                setAnalogChannel(calctime(curtime,pulse_offset_time-10),29,kill_probe_pwr);
                %set TTL off initially
                setDigitalChannel(calctime(curtime,pulse_offset_time-11),9,1);
                
                %pulse beam with TTL
                DigitalPulse(calctime(curtime,pulse_offset_time),9,kill_time,0);
                
                %close K probe shutter
                setDigitalChannel(calctime(curtime,pulse_offset_time+kill_time + 1),30,0);
            end
            
            
            %Reset pulse settings for plane selection
            spect_pars.pulse_length = selection_pulse_length;
            spect_pars.delta_freq = selection_delta_freq;
            
            
        end

ScopeTriggerPulse(curtime,'Plane Select');
        
        
        if (sweep_field == 0) %Sweeping frequency of SRS

            %Plane select atoms by sweeping frequency
            addOutputParam('delta_freq',spect_pars.delta_freq)
            spect_pars.fake_pulse = 0;
            spect_pars.SRS_select = 0; %0: Use SRS A, 1: Use SRS B
                if spect_pars.SRS_select == 1
                    %Programming second generator, may set different power,
                    %mod_dev, etc...
                    spect_pars.power = -35;
                    spect_pars.mod_dev = 100/1000;
                end
            
            
curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars); % second sweep (actual plane selection)
        
        elseif (sweep_field == 1) %Sweeping field with z Shim, SRS frequency is fixed
            
            %SRS in pulsed mode with amplitude modulation
            spect_type = 2;
            
            
            %Take frequency range in MHz, convert to shim range in Amps
            %  (-5.714 MHz/A on Jan 29th 2015)
            dBz = spect_pars.delta_freq / (-5.714);
            addOutputParam('delta_freq',spect_pars.delta_freq)
            addOutputParam('current_range',dBz)
            
            field_shift_time = 20; % time to shift the field to the initial value for the sweep (and from the final value)
            field_shift_settle = 40; % settling time after initial and final field shifts
            
            if (Cycle_About_Freq_Val)
                %Shift field down and up by half of the desired width
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center-1*dBz/2;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz/2;
            else %Start at current field and ramp up
                z_shim_sweep_center = getChannelValue(seqdata,28,1,0);
                z_shim_sweep_start = z_shim_sweep_center;
                z_shim_sweep_final = z_shim_sweep_center+1*dBz;
            end
            
            %Ramp shim to start value before generator turns on
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay-field_shift_settle-field_shift_time; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_start;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim during uwave pulse to transfer atoms
            ramp.shim_ramptime = spect_pars.pulse_length;
            ramp.shim_ramp_delay = spect_pars.uwave_delay;
            ramp.zshim_final = z_shim_sweep_final;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Ramp shim back to initial value after pulse is complete
            clear('ramp');
            ramp.shim_ramptime = field_shift_time;
            ramp.shim_ramp_delay = spect_pars.uwave_delay+spect_pars.pulse_length+field_shift_settle; %offset from the beginning of uwave pulse
            ramp.zshim_final = z_shim_sweep_center;
            
            ramp_bias_fields(calctime(curtime,0), ramp);
            
            %Extra Parameters for the plane selecting pulse
            spect_pars.fake_pulse = 0;  %Whether to actually open the uWave switch (0: do pulse; 1: don't do pulse)
            spect_pars.power_scale = 1; %Diminish the uWave power from the programmed value
            
            %Do plane selection pulse
  curtime = rf_uwave_spectroscopy(calctime(curtime,0),spect_type,spect_pars);     

            %Wait for shim field to return to initial value
curtime = calctime(curtime,field_shift_settle+field_shift_time);
            
        end

        if (eliminate_planes_with_QP)
            % Note: only works ok in a very narrow range of parameters;
            % always kills some atoms in 9/2 as well. Optimal parameters
            % may change with lattice alignment.     
            
            extra_probe_pulse = 0;
            if extra_probe_pulse
                kill_probe_pwr = 0.7;
                kill_time = 5;
                kill_detuning = 40;
                
                
                %set probe detuning
                setAnalogChannel(calctime(curtime,-10),'K Probe/OP FM',190); %195
                %set trap AOM detuning to change probe
                setAnalogChannel(calctime(curtime,-10),'K Trap FM',kill_detuning); %54.5
                
                %open K probe shutter
                setDigitalChannel(calctime(curtime,-5),30,1); %0=closed, 1=open
                %turn up analog
                %
                setAnalogChannel(calctime(curtime,-5),29,kill_probe_pwr);
                %set TTL off initially
                setDigitalChannel(calctime(curtime,-5),9,1);
            end
            
            
            QP_kill_time = 80; % time with lowered lattices and strong gradient

            lat_psel_ramp_depth = [[0 0 20 20];[0 0 20 20];[10 10 20 20]]/atomscale; % lattice depths in Er
            lat_psel_ramp_time = [150 NaN 150 50]; % sum of the last two ramp times is effectively the field settling time
            
            clear('ramp');

        % Field Ramps for Gradient Kill
            % Reduce FB coil so that the transverse gradient is significant
            ramp.fesh_ramptime = 55;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = 0.1; %0.05
            % Ramp X and Y shims to center the QP gradient around the trap axis
            ramp.shim_ramptime = 50;
            ramp.shim_ramp_delay = -0;
            ramp.xshim_final = getChannelValue(seqdata,27,1,0)-0.050; %-0.050 previously.
            ramp.yshim_final = getChannelValue(seqdata,19,1,0)+0.090;
            ramp.zshim_final = getChannelValue(seqdata,28,1,0);
            % QP coil settings for gradient killing
            ramp.QP_ramptime = 50;
            ramp.QP_ramp_delay = -0;
            ramp.QP_final =  4*1.78; %4
            % no settling time (being rough here) -- lattice rampup time plus additional hold time are used instead
            ramp.settling_time = 0;

        %Lattice Ramps for Gradient Kill
            % first field ramp (happens once the horizontal lattice is ramped down)
            ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)), ramp); % check ramp_bias_fields to see what struct ramp may contain
            
            % second field ramp (happens before the horizontal lattice is ramped back up)
            ramp.fesh_final = FB_init;
            ramp.QP_final =  0*1.78;          
            ramp_bias_fields(calctime(curtime,lat_psel_ramp_time(1)+ramp.fesh_ramptime+QP_kill_time), ramp); % check ramp_bias_fields to see what struct ramp may contain
 
            % wait with lowered horizontal lattice until FB field is ramped up again and gradient is removed
            lat_psel_ramp_time(2) = 2*ramp.fesh_ramptime+QP_kill_time;

            if extra_probe_pulse               
                %pulse beam with TTL
                DigitalPulse(calctime(curtime,lat_psel_ramp_time(1)+ramp.fesh_ramptime+QP_kill_time - kill_time),9,kill_time,0);
                
                %close K probe shutter
                setDigitalChannel(calctime(curtime,lat_psel_ramp_time(1)+ramp.fesh_ramptime+QP_kill_time + 5),30,0);
            end
            
            
            if (length(lat_psel_ramp_time) ~= size(lat_psel_ramp_depth,2)) || ...
                    (size(lat_psel_ramp_depth,1)~=length(lattices)) || ...
                    isnan(sum(sum(lat_psel_ramp_depth)))
                error('Invalid ramp specification for lattice loading!');
            end
            
        % execute lattice ramps (advances curtime)
            if length(lat_psel_ramp_time) >= 1
                for j = 1:length(lat_psel_ramp_time)
                    for k = 1:length(lattices)
                        curr_val = getChannelValue(seqdata,lattices{k},1);
                        if lat_psel_ramp_depth(k,j) ~= curr_val % only do a minjerk ramp if there is a change in depth
                            AnalogFuncTo(calctime(curtime,0),lattices{k},@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)), lat_psel_ramp_time(j), lat_psel_ramp_time(j), lat_psel_ramp_depth(k,j));
                        end
                    end
curtime =   calctime(curtime,lat_psel_ramp_time(j));
                end
            end
        else
    
            % Ramp gradient and FB back down
            clear('ramp');

            % FB coil settings for spectroscopy
            ramp.fesh_ramptime = 50;
            ramp.fesh_ramp_delay = -0;
            ramp.fesh_final = FB_init; %18

            % QP coil settings for spectroscopy
            ramp.QP_ramptime = 50;
            ramp.QP_ramp_delay = -0;
            ramp.QP_final =  0; %7

            ramp.settling_time = 200; %200
       
curtime = ramp_bias_fields(calctime(curtime,0), ramp); % check ramp_bias_fields to see what struct ramp may contain
        end

        
        final_repump_pulse = 0;
        if final_repump_pulse
            %Pulse on repump beam to try to remove any atoms left in F=7/2
            repump_pulse_time = 5;
            repump_pulse_power = 0.7;
            
            %Open Repump Shutter
            setDigitalChannel(calctime(curtime,-10),3,1);
            %turn repump back up
            setAnalogChannel(calctime(curtime,-10),25,repump_pulse_power);
            %repump TTL
            setDigitalChannel(calctime(curtime,-10),7,1);
            
            %Repump pulse
            DigitalPulse(calctime(curtime,0),7,repump_pulse_time,0);
            
            %Close Repump Shutter
            setDigitalChannel(calctime(curtime,repump_pulse_time+5),3,0);
        end
        
    %% assigning outputs (edit with care!)
    timeout = curtime;
    
end