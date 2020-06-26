function timeout = Pulse_RamanBeams(timein, PulseLength, varargin)
% timeout = iXon_FluorescenceImage(timein, options)
% 
% This function takes a (series) of fluorescence images with the iXon
% camera. It sends timed triggers to the camera. It descends from the older
% lattice_fluor_image.m.
%
% Available options (and default values):
%
% ExposureDelay (55) delay of (first) exposure from timein-ExposureOffsetTime
% ExposureOffsetTime (0) used as: how much earlier than timein the molasses is started
% PreFlushOffsetTime (6000) offset (with respect to beginning first exposure) for flushing the camera; needs to be larger than exposure time!
% BackgroundDelayTime (1000) offset (with respect to end of last exposure) for taking the background image (with or without another flush)
% DoPostFlush (1) whether to do another flush before taking the background image
% ExposureTime (5000) Camera exposure time (per frame)
% NumFrames (1) Number of frames to take
% FrameTime (5100) Time between frames (beginning to beginning) check minimal time with iXon GUI's "info"
% FinalWaitTime (500) Final time to add to timeout
%
% Started: 2015-02-11; Stefan Trotzky
% Last changes: 2015-02-11

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

curtime = timein;
global seqdata;

% the number of necessary input arguments (including timein)
narginfix = 2;

% Define valid options for this function and their default values here. 
opt = struct('ShutterOpeningDelay', 5, ... delay of shutter (in ms)
             'ShutterClosingDelay', 0, ... used as: how much earlier than timein the molasses is started
             'PulsePower',10, ...
             'MOTLightOffset',5, ...     delay with which to open MOT beam shutters and TTL
             'MOTLightSource', 0 ...      which MOT light is used for Raman beams? (1: trap, 2: Chip laser)
             );      
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input is timein!')
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


%% Prepare Raman light

if (opt.MOTLightSource == 1)
    %Trap light is used
    
    %Set Trap power
    setAnalogChannel(calctime(curtime,-opt.ShutterOpeningDelay-opt.MOTLightOffset),'K Trap AM',0.8);
    
    %Open Trap shutter and TTL to provide light to the breakout board
    setDigitalChannel(calctime(curtime,-opt.ShutterOpeningDelay-opt.MOTLightOffset),'K Trap Shutter',1); %Shutter
    setDigitalChannel(calctime(curtime,-opt.ShutterOpeningDelay-opt.MOTLightOffset),'K Trap TTL',0);     %TTL
    
    %Later turn off the trap light
    setDigitalChannel(calctime(curtime,PulseLength+opt.MOTLightOffset),'K Trap Shutter',0); %Shutter
    setDigitalChannel(calctime(curtime,PulseLength+opt.MOTLightOffset),'K Trap TTL',1);     %TTL
    setAnalogChannel(calctime(curtime,PulseLength+opt.MOTLightOffset),'K Trap AM',0.0);
else
    %What kind of Raman light are we using?
end
   

%% Action: pulse Raman beams

%     setDigitalChannel(calctime(curtime,-opt.ShutterOpeningDelay),'405nm Shutter',1); %Shutter
%     setDigitalChannel(calctime(curtime,-opt.ShutterOpeningDelay-1),'405nm TTL',1); %RF OFF on ALPS
    
curtime = DigitalPulse(curtime,'Offset TTL',PulseLength,0);
    
%     setDigitalChannel(calctime(curtime,0),'405nm Shutter',0); %Shutter
    
    
%% assigning outputs (edit with care!)

timeout = curtime;

end