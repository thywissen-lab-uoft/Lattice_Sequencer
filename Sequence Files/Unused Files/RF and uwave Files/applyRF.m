function [timeout, varargout] = applyRF(timein, frequency, power, duration, varargin)
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
%
% Valid options (and default values) are:
%
% Type ('pulse') whether to do a (SYNChronized) PULSE or SWEEP
% FrequencyRange ([]) frequency range of a sweep (will sweep centered around frequency); output frequency has form [start,end].
% PostWaitTime (0) some time to add to the end
% ScopeTrigger ('') whether to send a scope trigger for this pulse.
%       ScopeTrigger is a string specifying the trigger pulse's name. Set 
%       to empty ('') for no pulse.
%
% Started: 2015-02-12; Stefan Trotzky
% Last changes: 2015-02-12

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;
curtime = timein;
MHz = 1E6; % a calibration factor

% the number of necessary input arguments (including timein)
narginfix = 4;

% Define valid options for this function and their default values here. 
opt = struct('Type', 'pulse', ... whether to do a (SYNChronized) PULSE or SWEEP
             'FrequencyRange', [], ... frequency range of a sweep (will sweep centered around frequency).
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
elseif ( frequency > 180 ); % half way arbitrarily chosen ... resonance frequencies at accessible fields typ. <60MHz
    buildWarning(mename,'Frequency too high!',1);
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
    
    case {'sweep'} % RF sweep with evaporation DDS
        
        %Define RF sweep parameters to use with do_rf_sweep.m
        if (length(frequency) == 1)
            if isempty(opt.FrequencyRange)
                error('Need to either input frequency as [start,end] or to specify option FrequencyRange for sweeps about frequency!');
            end
            frequency = [frequency-opt.FrequencyRange/2 frequency+opt.FrequencyRange/2];
        else
            if (length(power)~=length(frequency)-1)||(length(duration)~=length(frequency)-1)
                error('For a multi-segment sweep, need to specify power and duration for each segment!');
            end
        end
        
curtime = do_rf_sweep(calctime(curtime,0),0,frequency*MHz,duration,power);

    case {'pulse'} % RF pulse with evaporation DDS. 
        
curtime =   do_rf_pulse(calctime(curtime,0),0, frequency(1)*MHz,duration(1),0,power(1));
        opt.PostWaitTime = max(opt.PostWaitTime,1);
        
    case {'sync pulse'} % 60Hz synchronized RF pulse with evaporation DDS (currently using the home-built box). 
        
        % ACync-controlled line-synced pulse. Untested! (2015-04-01)
        % The transfer switch delay is currently -50ms, which should be enough to
        % work with the max. synchronization delay of 16.7ms.
        % Pulsing the ACync master 50us earlier, and for duration + 17ms.
        DigitalPulse(calctime(curtime,-0.05),56,duration(1)+17,1);
curtime =   do_rf_pulse(calctime(curtime,0),0, frequency(1)*MHz,duration(1),0,power(1));
        opt.PostWaitTime = max(opt.PostWaitTime,1);        

    otherwise
        
        error('Unknown type!')
        
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