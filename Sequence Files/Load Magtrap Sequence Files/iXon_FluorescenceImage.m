function timeout = iXon_FluorescenceImage(timein, varargin)
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
narginfix = 1;

% Define valid options for this function and their default values here. 
opt = struct('ExposureDelay', 55, ... delay of (first) exposure from timein-ExposureOffsetTime
             'ExposureOffsetTime', 0, ... used as: how much earlier than timein the molasses is started
             'PreFlushOffsetTime', 6000, ... offset (with respect to beginning first exposure) for flushing the camera; needs to be larger than exposure time!
             'BackgroundDelayTime', 6000, ... offset (with respect to end of last exposure) for taking the background image (with or without another flush)
             'DoPostFlush', 1, ... whether to do another flush before taking the background image
             'ExposureTime', 4950, ... Camera exposure time (per frame)
             'NumFrames', 1, ... Number of frames to take
             'FrameTime', 5050, ... Time between frames (beginning to beginning); check minimal time with iXon GUI's "info"
             'FinalWaitTime', 500, ... Final time to add to timeout
             'PiezoScan',0, ...         Whether to refocus the objective for subsequent frames
             'PiezoScanStep',0.01 ...  Piezo refocusing shift per exposure
                );      
         disp('hi');
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

%% Action: taking a fluoresccence image

    if opt.PiezoScan
        %Read in current Piezo Voltage
        Vo = getChannelValue(seqdata,'objective Piezo Z',1,0);
        addOutputParam('Piezo_Step',opt.PiezoScanStep);
    end

    %Expose iXon Once to Clear Buffer
    DigitalPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay-opt.PreFlushOffsetTime),...
        'iXon Trigger',1,1);
    
%     % Trigger Pixel Fly (only for fluoresnece with it).
%     DigitalPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay-opt.PreFlushOffsetTime),...
%         'PixelFly Trigger',1,1);
    
    % Set Scope Trigger
    ScopeTriggerPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay ),'Start Fluorescence Capture',0.1);

    % Expose for each frame; advance in time
    % A small problem here: currently, the molasses is on all the time. May
    % need to interrupt during read out and then restart it.
    for j = 1:opt.NumFrames
        if opt.PiezoScan
            %Refocus
            setAnalogChannel(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay+(j-1)*opt.FrameTime-100),'objective Piezo Z',Vo + opt.PiezoScanStep*(j-1),1);
        end
        DigitalPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay+(j-1)*opt.FrameTime),...
            'iXon Trigger',1,1);
            
%         Trigger Pixel Fly (only for fluoresnece with it).
%         DigitalPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay+(j-1)*opt.FrameTime),...
%             'PixelFly Trigger',1,1);
%         
    end

    ScopeTriggerPulse(calctime(curtime,-opt.ExposureOffsetTime+opt.ExposureDelay),'iXon Exposure')

curtime = calctime(curtime,opt.BackgroundDelayTime);
% PROBLEM WITH BACKGROUNDS RIGHT NOW CAUSING INFINITE LOAD LATTICE LOOP
% FIX BEFORE UNCOMMENTING.
%     % "dummy" lattice loading for background image
%     curtime = Load_Lattice(calctime(curtime,0), opt.FrameTime);
%     [curtime,Second_Molasses_Time] = imaging_molasses(curtime, opt.FrameTime - 50);
% 
%     if (opt.DoPostFlush)
%         %Expose iXon Once to Clear Buffer
%         DigitalPulse(calctime(curtime,-Second_Molasses_Time+opt.ExposureDelay-opt.PreFlushOffsetTime),'iXon Trigger',1,1);
%     end  
%     
%     % take background image
%     DigitalPulse(calctime(curtime,-Second_Molasses_Time+opt.ExposureDelay),'iXon Trigger',1,1);

    % add a final wait time (for lattice to ramp down)     
curtime = calctime(curtime,opt.FinalWaitTime);


%% assigning outputs (edit with care!)

timeout = curtime;

end