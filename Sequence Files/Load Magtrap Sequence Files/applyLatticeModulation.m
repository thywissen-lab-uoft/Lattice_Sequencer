function [timeout, varargout] = applyLatticeModulation(timein, frequency, amplitude, offset, duration, varargin)
% timeout = applyLatticeModulation(timein, frequency, amplitude, duration, options)
% [timeout, frequency] = applyLatticeModulation(timein, frequency, amplitude, duration, options)
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
% Type ('AM') whether modulation is FM or AM (may be used to choose
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
atomscale = 0.4;

% the number of necessary input arguments (including timein)
narginfix = 4;

% Define valid options for this function and their default values here. 
opt = struct('Type', 'AM', ... whether modulation is FM or AM (may be used to choose modulation device/input. Currently chosen by hand)
             'Lattice', 'ylattice', ...
             'RampLatticeDelta', 0, ...
             'ScopeTrigger', '');
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input are timein, frequency, amplitude and duration!')
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

if (isempty(amplitude))||(~isnumeric(amplitude))
    error('Need to specify a valid power!');
end

if (isempty(duration))||(~isnumeric(duration))
    error('Need to specify a valid duration!');
end


%% Action do a RF pulse or sweep

% % Program Rigol generator
str = sprintf('SOUR2:APPL:SIN;SOUR2:FREQ %g;SOUR2:VOLT %g;SOUR2:VOLT:OFFS %g;',frequency, amplitude, offset);
addVISACommand(5, str); %Device 3 is newest 25MHZ Rigol.

% Add a scope trigger at beginning of modulation
if ~isempty(opt.ScopeTrigger)
    ScopeTriggerPulse(calctime(curtime,0),'Lattice_Mod');
end

% ramp lattice during modulation
this_lattice = 'ylattice';
if (opt.RampLatticeDelta ~= 0)
    Vini = getChannelValue(seqdata,opt.Lattice,1)*atomscale;
    Vfin = (Vini + opt.RampLatticeDelta)/atomscale;
    AnalogFuncTo(calctime(curtime,0),opt.Lattice,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)), duration, duration, Vfin);    
end

% Start modulation (gated)
% setDigitalChannel(calctime(curtime,0),51,1); 
setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1)
% stoip modulation (gated)
% curtime = setDigitalChannel(calctime(curtime,duration),51,0);
curtime = setDigitalChannel(calctime(curtime,duration),'Lattice Direct Control',0)


% Add some time at the end (this is at least 1ms for pulses, for a reason that is not directly clear)

out = {frequency};
    
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