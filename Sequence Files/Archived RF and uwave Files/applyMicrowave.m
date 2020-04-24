function [timeout, varargout] = applyMicrowave(timein, frequency, power, duration, varargin)
% timeout = applyRF(timein, frequency, power, duration, options)
% [timeout, frequency] = applyRF(timein, frequency, power, duration, options)
% [timeout, frequency, postwaittime] = applyRF(timein, frequency, power, duration, options)
% 
% This function applies RF from the evaporation DDS to do either a sweep or
% a pulse. It descends from rf_uwave_spectroscopy.m (types 3 and 4) and
% makes use of do_rf_sweep.m, do_rf_pulse.m and do_linesynced_rf_pulse.m.
% Optional output arguments are frequency=[f1,f2,f3,f4] for a sequence of
% sweeps and the postwaittime, which is set to a minimal value of 1ms for
% pulses (probably an unnecessary relic). All frequencies are given in MHz!
% Can do n-segment sweeps when specifying n+1 frequencies ([start1, end1,
% ... endn]) and n powers and n durations. Time is advanced in
% do_rf_sweep.m, etc.
% The output time timeout advances only by the time over which uwave is
% applied plus some postwaittime, that is either set in the options or may
% be calculated and applied by the function (currently zero).
%
% Valid options (and default values) are:
%
% Type ('pulse') whether to do a (SYNChronized) PULSE or AMPULSE or SWEEP
% Device (27) the device adress (should be a number for GPIB, a string for VISA)
% DeviceType ('GPIB') the type of the device (VISA or GPIB)
% Disable (0) whether to disable Microwave; set to 1 for a dummy pulse
% Atom ('K') which atom the uwave is targeting (basically sets frequency ranges, etc.)
% FrequencyRange ([]) frequency range of a sweep (will sweep centered around frequency).
% FMDeviation ([]) frequency modulation deviation (will be calculated from frequencies if empty)
% FMPresetTime (10) how much earlier to ramp frequency to the start value of a sweep (used to be 100)
% FMPostsetTime (10) how long to take to ramp frequency back to initial value after the sweep (used to be 100)
% PCSweep (1) whether to do phase continuous sweeps when doing sweeps (available with SRS generators)
% AMPresetTime (100) how much earlier to ramp amplitude to the start value of an AM pulse
% AMRampOnTime (0) time to ramp on the power with AM (min-jerk; may do fancier pulses)
% AMRampOffTime (0) time to ramp off the power with AM (min-jerk; may do fancier pulses)
% AMRampOffset (0) offset of AM ramp (in percent of (linear) power)
% DelayTime (0)
% PostWaitTime (0) some time to add to the end
% ScopeTrigger ('') scope trigger name (empty string for no trigger)
%
% Started: 2015-02-12; Stefan Trotzky
% Last changes: 2015-02-19

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;
curtime = timein;
MHz = 1E6; % a calibration factor

% the number of necessary input arguments (including timein)
narginfix = 4;

% Define valid options for this function and their default values here. 
opt = struct('Type', 'pulse', ... whether to do a (SYNChronized) PULSE or AMPULSE or SWEEP
             'Device', 27, ... the device adress (should be a number for GPIB, a string for VISA)
             'DeviceType', 'GPIB', ... the type of the device (VISA or GPIB)
             'Disable', 0, ... whether to disable Microwave; set to 1 for a dummy pulse
             'Atom', 'K', ... which atom the uwave is targeting (basically sets frequency ranges, etc.)
             'FrequencyRange', [], ... frequency range of a sweep (will sweep centered around frequency).
             'FMDeviation', [], ... frequency modulation deviation (will be calculated from frequencies if empty)
             'FMPresetTime', 10, ... how much earlier to ramp frequency to the start value of a sweep (used to be 100)
             'FMPostsetTime', 10, ... how long to take to ramp frequency back to initial value after the sweep (used to be 100)
             'PCSweep', 1, ... whether to do phase continuous sweeps when doing sweeps (available with SRS generators)
             'AMPresetTime', 100, ... how much earlier to ramp to the start value of an AM pulse
             'AMRampOnTime', 0, ... time to ramp on the power with AM (min-jerk; may do fancier pulses)
             'AMRampOffTime', 0, ... time to ramp off the power with AM (min-jerk; may do fancier pulses)
             'AMRampOffset', 0, ... offset of AM ramp (in percent of (linear) power)
             'DelayTime', 0, ...
             'PostWaitTime', 0, ... some time to add to the end
             'ScopeTrigger', '' ... scope trigger name (empty for no trigger)
             );
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input are timein, frequency, power and duration!')
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

% Sanity checks
if (isempty(frequency))||(~isnumeric(frequency))
    error('Need to specify a valid frequency!');
end

if (isempty(power))||(~isnumeric(power))
    error('Need to specify a valid power!');
end

if (isempty(duration))||(~isnumeric(duration))
    error('Need to specify a valid duration!');
end


%% Action do a RF pulse or sweep

% Add a scope trigger at the beginning of this sweep or pulse
if ~isempty(opt.ScopeTrigger)
    ScopeTriggerPulse(calctime(curtime,opt.DelayTime),opt.ScopeTrigger);
end

switch lower(opt.Type)
    
    case {'sweep'} % Microwave sweep
        
        % Process frequency input
        if (length(frequency) == 1)
            if isempty(opt.FrequencyRange)
                error('Need to either input frequency as [start,end] or to specify option FrequencyRange for sweeps about frequency!');
            end
            frequency = [frequency-opt.FrequencyRange/2 frequency+opt.FrequencyRange/2];
        else
            if (length(duration)~=length(frequency)-1)
                error('For a multi-segment sweep, need to specify duration for each segment!');
            end
        end
        
        % full range of sweep
        opt.FrequencyRange = [min(frequency) max(frequency)];
        
        % for FM sweeps with SRS synthesizers, this is the set center frequency
        frequencyCenter = mean(opt.FrequencyRange); 
        
        % calculate a modulation deviation if not specified explicitly;
        % using ±FMDeviation for sweeps; if the frequency range is not
        % fully covered by FMDeviation, throw an error!
        if isempty(opt.FMDeviation)
            opt.FMDeviation = (opt.FrequencyRange(2)-opt.FrequencyRange(1))/1.9; %1.9 bc using the full mod_dev gives issues
        else
            if (opt.FMDeviation < (opt.FrequencyRange(2)-opt.FrequencyRange(1))/2);
                buildWarning(mename,'::Modulation deviation too small!',1);
            end
        end
        
        if strcmpi(opt.DeviceType,'gpib'); % Handle GPIB devices (default)
            
            if (opt.Device == 27)||(opt.Device == 28) % either of the two SRS generators
                
                % Unfortunately, cannot program AM and FM at the same time;
                % may work around this one day with a (good!) VVA.
                if (length(power) > 1);
                    buildWarning(mename,'SRS generators do not take multiple powers; using first in list.');
                    power = power(1);
                end
                                
                if strcmpi(opt.Atom,'k') % (default)
                    % direct frequency control; keep frequency values as are 
                elseif strcmpi(opt.Atom,'rb')
                    % using the sextupler to bump frequency up to >6GHz;
                    % divide frequency values by 6.
                    opt.FrequencyRange = opt.FrequencyRange/6;
                    frequencyCenter = frequencyCenter/6;
                    frequency = frequency/6;
                    opt.FMDeviation = opt.FMDeviation/6;
                end
                
                % control voltages for the sweep.
                sweep = (frequency-frequencyCenter)/opt.FMDeviation; 
                
                % externally controlled frequency modulation (see SRS manual on GPIB commands);
                % multiple programming of the same GPIB device is handled in addGPIBcommand.m
                if (opt.PCSweep) % phase continuous sweeps (default)
                    addGPIBCommand(opt.Device,sprintf(['FREQ %fMHz; TYPE 3; SDEV %gMHz; SFNC 5; ' ... 
                        'AMPR %gdBm; MODL 1; DISP 2; ENBR %g;'],...
                        frequencyCenter,opt.FMDeviation,power,1));
                else % simple frequency modulation
                    addGPIBCommand(opt.Device,sprintf(['FREQ %fMHz; TYPE 1; FDEV %gMHz; MFNC 5; ' ... 
                        'AMPR %gdBm; MODL 1; DISP 2; ENBR %g;'],...
                        frequencyCenter,opt.FMDeviation,power,1));
                end                    
                
                % set value for ZASWA switch selecting SRS generators
                if (opt.Device == 27); %SRS A (default)
                    SRS_select = 0;
                elseif (opt.Device == 28); %SRS B
                    SRS_select = 1;
                end                
                % select uWave source with SRS selection ZASWA switch
                setDigitalChannel(calctime(curtime,opt.DelayTime-5),'K uWave Source',SRS_select);

                % whether to use the sextupler
                if strcmpi(opt.Atom,'k') % (default)
                    atomtype = 1; % for do_uwave_pulse.m
                elseif strcmpi(opt.Atom,'rb')
                    atomtype = 0; % for do_uwave_pulse.m
                    % making sure that sextupled SRS is used and not the (fix frequency) Anritsu synthesizer from the chip lab
                    % WARNING: at the time of coding, we do not have the
                    % sextupler connected to an SRS generator. At the
                    % moment, this needs to be done by physically adding
                    % the sextupler in the respective uwave line. In the
                    % future, another pair of ZASWA (or similar) switches
                    % should be added and adressed at this point in the
                    % code.
                    if (getChannelValue(seqdata,'Rb Source Transfer',0) == 0)
                        % WARNING: large negative time offset (50ms)
                        setDigitalChannel(calctime(curtime,opt.DelayTime-50),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler
                    end  
                end
                                
                % Ramp FM control channel from 0 to start value before sweep
                AnalogFuncTo(calctime(curtime,-opt.FMPresetTime),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.FMPresetTime/2,opt.FMPresetTime/2,sweep(1));
                % Open fast switch for full duration of sweep
                do_uwave_pulse(calctime(curtime,opt.DelayTime), opt.Disable, 0*MHz, sum(duration),2,atomtype);                
                % Cary out sweep for each segment (linear ramps on FM control channel)
                for j = 1:(length(sweep)-1)
curtime =           AnalogFunc(calctime(curtime,opt.DelayTime),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),duration(j),duration(j),sweep(j),sweep(j+1));
                end
                % Ramp FM control channel from end value back to 0 after sweep 
                AnalogFuncTo(calctime(curtime,opt.FMPostsetTime/2),46,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.FMPostsetTime/2,opt.FMPostsetTime/2,0);
                                
            else
                % other GPIB devices here!
            end
            
        elseif strcmpi(opt.DeviceType,'visa'); % Handle VISA devices
           
            % GPIB devices that offer USB/Ethernet communication may be
            % moved here at some point for faster programming. 
            error('No VISA Devices included, yet!')
            
        else
            
            error('No devices other than GPIB or VISA included, yet!')
            
        end
        
    case {'pulse', 'sync pulse', 'am pulse', 'sync am pulse'}
        
        if strcmpi(opt.DeviceType,'gpib'); % Handle GPIB devices (default)
            
            if (opt.Device == 27)||(opt.Device == 28) % either of the two SRS generators
                
                if strcmpi(opt.Atom,'k') % (default)
                    % direct frequency control; keep frequency values as are 
                    atomtype = 1;
                elseif strcmpi(opt.Atom,'rb')
                    % using the sextupler to bump frequency up to >6GHz;
                    % divide frequency values by 6.
                    frequency = frequency/6;
                    atomtype = 0;
                end
                
                % set value for ZASWA switch selecting SRS generators
                if (opt.Device == 27); %SRS A (default)
                    SRS_select = 0;
                elseif (opt.Device == 28); %SRS B
                    SRS_select = 1;
                end                
                % select uWave source with SRS selection ZASWA switch
                setDigitalChannel(calctime(curtime,opt.DelayTime-5),'K uWave Source',SRS_select);
                
                % device programming (see SRS manual on GPIB commands);
                % multiple programming of the same GPIB device is handled in addGPIBcommand.m
                if strcmpi(opt.Type,'am pulse')||strcmpi(opt.Type,'sync am pulse')
                    
                    % check whether AM ramps fits into duration of uwave
                    % pulse (different logic than in rf_uwave_spectrscopy.m!) 
                    if (opt.AMRampOnTime+opt.AMRampOffTime) > duration
                        buildWarning(mename,'AMRampOnTime+AMRampOffTime needs to be smaller than pulse duration!',1);
                    end
                    
                    % amplitude-modulated pulse; power needs to be programmed in linear units; 
                    % calculating from input value in dBm (see formula below, 50Ohm); modulation dev 
                    % set to 100%, meaning that -1V on the SRS external input gives full suppression
                    addGPIBCommand(opt.Device,sprintf(['FREQ %fMHz; AMPR %gRMS; MODL 1; ' ...
                        'TYPE 0; MFNC 5; ADEP 100; DISP 2; ENBR %g; AMPR?'], ...
                        frequency(1),0.2236*sqrt(10^(power(1)/10)),1));
                    
                    % convert percentage into control voltage
                    AM_offset = opt.AMRampOffset/100 - 1; 
                    
                    % turn uwave down initially (before switch is opened)
                    AnalogFuncTo(calctime(curtime,opt.DelayTime-opt.AMPresetTime),46,@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),opt.AMPresetTime/2,opt.AMPresetTime/2,AM_offset);
                    % ramp uwave on to 100% of input power with min jerk at
                    % beginning of pulse (Modulation input via channel 46)
                    AnalogFuncTo(calctime(curtime,opt.DelayTime),46,@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),opt.AMRampOnTime,opt.AMRampOnTime,0);
                    %Ramp off with min jerk at end of pulse
                    AnalogFuncTo(calctime(curtime,opt.DelayTime+duration(1)-opt.AMRampOffTime),46,@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),opt.AMRampOffTime,opt.AMRampOffTime,AM_offset);
                    % Not ramping the voltage back to 0 here, since the  channel will either be used 
                    % for the same thing again or not at all.
                    
                    % Note on line-synced AM pulses (holds for line synced
                    % sweeps as well): These need to be set up physically
                    % using Alan's "ACync" device (not finished at the time
                    % of coding). This device synchronizes (delays)
                    % channels that are piped through it to the 60Hz power
                    % line cycle. Synchronization starts when a digital
                    % master input signal is set HI and stops when it is set LO.
                    % The timing of AM and FM control signals by the Adwin
                    % is not needed to be adapted. It only needs to be
                    % assured that AM and FM ramps fall into the time
                    % window in which the master is HI (reduced by 17ms at
                    % the end). This new option will make do_linesync_uwave_pulse
                    % obsolete (remove from this function onvce things are
                    % working).
                    
                elseif strcmpi(opt.Type,'pulse')||strcmpi(opt.Type,'sync pulse')
                    
                    % regular pulse; simply setting frequency and power
                    addGPIBCommand(opt.Device,sprintf(['FREQ %fMHz; AMPR %gdBm; MODL 0; ' ...
                        'DISP 2; ENBR %g; FREQ?'],frequency(1),power(1),1));
                    
                end
                                
                if strcmpi(opt.Type(1:4),'sync') % do a line-synchronized pulse (see note above)

                    % ACync-controlled line-synced pulse. Untested! (2015-04-01)
                    % The transfer switch delay is currently -50ms, which should be enough to
                    % work with the max. synchronization delay of 16.7ms.
                    % Pulsing the ACync master 50us earlier, and for duration + 17ms.
                    DigitalPulse(calctime(curtime,opt.DelayTime-0.05),56,duration(1)+17,1);
                   
                end
                    % do the actual pulse (will happened delayed to AC line
                    % zero crossing if a synchronized pulse is requested
                    % and if the corresponding signals are piped through
                    % ACync.
curtime =           do_uwave_pulse(calctime(curtime,opt.DelayTime), opt.Disable, 0*MHz,duration(1),0,atomtype);                                                    
                
            else
                % other GPIB devices here
            end

        elseif strcmpi(opt.DeviceType,'visa'); % Handle VISA devices
           
            % GPIB devices that offer USB/Ethernet communication may be
            % moved here at some point for faster programming. 
            error('No VISA Devices included, yet!')
            
        else
            
            error('No devices other than GPIB or VISA included, yet!')
            
        end
        
    otherwise
        
        error('Unknown Type!')
end

% Add some time at the end (this is at least 1ms for pulses, for a reason that is not directly clear)
curtime = calctime(curtime,opt.PostWaitTime);

out = {frequency, opt.PostWaitTime};
        
    
%% assigning outputs (edit with care!)

timeout = curtime;

if ( nargout <= 1 )
    % only timeout has been requested (or not) -- doing nothing
elseif ( nargout > 1 )
    % check that there no more than the available output arguments are
    % requested
    if ((nargout-1) > length(out))
        error('Invalid number of output arguments!')
    else
        for j = 1:(nargout-1)
            varargout{j} = out{j};
        end
    end
end
    
end