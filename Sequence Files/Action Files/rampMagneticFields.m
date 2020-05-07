function timeout = rampMagneticFields(timein, varargin)
% timeout = rampMagneticFields(timein, options)
% 
% This function does a ramp of the magnetic fields specified. If a certain
% coil is not to be ramped, set its value to [] (default for all coils).
% Originates from the older ramp_bias_fields.m; some possible bugs were
% fixed (search for NEW).
%
% Available options (and default values):
%
% ShimRampTime (50) time to ramp shims
% ShimRampDelay (-10) delay (with respect to timein) for shim ramps 
% xShimValue ([]) final value for xShim
% yShimValue ([]) final value for yShim
% zShimValue ([]) final value for zShim
% ShimValues ([]) option to give all final values for the shims together (overwrites individual values)
% FeshRampTime (50) time to ramp Feshbach
% FeshRampDelay (0) delay (with respect to timein) for Feshbach ramp 
% FeshTurnoffDelay (50) delay for turnong FB field off
% FeshFineControl (0) whether to use fine-control option on Feshbach (for currents < 19.8A)
% FeshValue ([]) final value for Feshbach
% QPRampTime (50) time to ramp QP
% QPRampDelay (0) delay (with respect to timein) for QP ramp
% QP_FFRampTime (50) time to ramp QP voltage
% QP_FFRampDelay (0) delay (with respect to timein) for QP voltage ramp
% QPValue ([]) final value for QP
% QP_FFValue ([]) final value for QP voltage
% SettlingTime (100) waittime at the end of the ramps
%
% Started: 2015-02-11; Stefan Trotzky
% Last changes: 2015-02-11

%% constants and defaults

%RHYS - Cleaner field sweep code. Check for consistency with
%ramp_bias_fields. 

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;
curtime = timein;

% the number of necessary input arguments (including timein)
narginfix = 1;

% Define valid options for this function and their default values here.
opt = struct('ShimRampTime', 50, ... time to ramp shims
             'ShimRampDelay', -10, ... delay (with respect to timein) for shim ramps 
             'xShimValue', [], ... final value for xShim
             'yShimValue', [], ... final value for yShim
             'zShimValue', [], ... final value for zShim
             'ShimValues', [], ... option to give all final values for the shims together (overwrites individual values)
             'FeshRampTime', 50, ... time to ramp Feshbach
             'FeshRampDelay', 0, ... delay (with respect to timein) for Feshbach ramp 
             'FeshTurnoffDelay', 50, ... delay for turnong FB field off
             'FeshFineControl', 0, ... whether to use fine-control option on Feshbach (for currents < 19.8A)
             'FeshValue', [], ... final value for Feshbach
             'QPRampTime', 50, ... time to ramp QP
             'QPRampDelay', 0, ... delay (with respect to timein) for QP ramp
             'QP_FFRampTime', 50, ... time to ramp QP voltage
             'QP_FFRampDelay', 0, ... delay (with respect to timein) for QP voltage ramp
             'QPValue', [], ... final value for QP
             'QP_FFValue', [], ... final value for QP voltage
             'SettlingTime', 100 ... waittime at the end of the ramps
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

%% Action: ramping the fields and operating FETs
   
    % to be removed once things are tested and fine!
    if (opt.FeshFineControl)
        buildWarning('rampMagneticFields','Careful here: verify that FB fine control option is implemented correctly. (Untested)',1)
    end

    %Process shim value input
    if ~isempty(opt.ShimValues)
        if (length(opt.ShimValues) ~= 3)
            error('When specified together, all three shim values need to be given!')
        else
            opt.xShimValue = opt.ShimValues(1);
            opt.yShimValue = opt.ShimValues(2);
            opt.zShimValue = opt.ShimValues(3);
        end
    else
        opt.ShimValues = [opt.xShimValue opt.yShimValue opt.zShimValue]; % to determine whether any shim is ramped
    end
    
    %Ramp shim fields
    if ~isempty(opt.xShimValue)
        AnalogFuncTo(calctime(curtime,opt.ShimRampDelay),27,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.ShimRampTime,opt.ShimRampTime,opt.xShimValue,3);
    end
    if ~isempty(opt.yShimValue)
        AnalogFuncTo(calctime(curtime,opt.ShimRampDelay),19,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.ShimRampTime,opt.ShimRampTime,opt.yShimValue,4);
    end
    if ~isempty(opt.zShimValue)
        AnalogFuncTo(calctime(curtime,opt.ShimRampDelay),28,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.ShimRampTime,opt.ShimRampTime,opt.zShimValue,3);
    end
    
    if isempty(opt.ShimValues)
        opt.ShimRampDelay = 0; % for calculation of total time
        opt.ShimRampTime = 0;
    end

    %Ramp Feshbach field
    if ~isempty(opt.FeshValue)
        
        %Do not bother trying to ramp or opening a switch if going from 0
        %to 0. Opening the switch induces a small current spike due to a
        %discharging capacitor. 
        if ~(getChannelValue(seqdata,37,1,0) == 0 && opt.FeshValue == 0)
            %%%% Does this code work?
            setDigitalChannel(calctime(curtime,opt.FeshRampDelay-50),31,1); % opens switch 50ms earlier (if it is not already open)
            %%%%
            AnalogFuncTo(calctime(curtime,opt.FeshRampDelay),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.FeshRampTime,opt.FeshRampTime,opt.FeshValue);
        end
        
        %Change to fine control (voltage divider), using voltage function 4
        if (opt.FeshFineControl) % NEW: Fixed timing; happens at the end of the ramp
            setDigitalChannel(calctime(curtime,opt.FeshRampDelay+opt.FeshRampTime),'FB offset select',0); 
            setDigitalChannel(calctime(curtime,opt.FeshRampDelay+opt.FeshRampTime),'FB sensitivity select',1);
            setAnalogChannel(calctime(curtime,opt.FeshRampDelay+opt.FeshRampTime+0.05),37,opt.FeshValue,4);
        else
        end
        
        %turn off Feshbach coils with fast switch if ramped to zero;
        %currently throws a warning -- may not be neded at some point.
        if opt.FeshValue == 0 % NEW: Fixed timing; added FeshRampDelay + FeshRampTime
            setDigitalChannel(calctime(curtime,opt.FeshRampDelay+opt.FeshRampTime+opt.FeshTurnoffDelay),31,0);
            buildWarning('rampMagneticFields','Known issue with switching off FB field! Check current monitor!');
        else
            opt.FeshTurnoffDelay = 0; % for calculation of total time
        end
    else
        opt.FeshRampDelay = 0; % for calculation of total time
        opt.FeshRampTime = 0;
        opt.FeshTurnoffDelay = 0;
    end
    
    
    
    %Set Quadrupole field
    if ~isempty(opt.QPValue)

            opt.QP_FFValue = 23*(opt.QPValue/30); % voltage FF on delta supply
            
            % Ramp up transport supply voltage
            AnalogFuncTo(calctime(curtime,opt.QP_FFRampDelay),18,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.QP_FFRampTime,opt.QP_FFRampTime,opt.QP_FFValue);
            
            % Ramp QP coil current, unless it is going from 0 to 0. 
            if ~(getChannelValue(seqdata,1,1,0) == 0 && opt.QPValue == 0)
                setDigitalChannel(calctime(curtime,opt.QPRampDelay), 21, 0); % fast QP, 1 is off
                AnalogFuncTo(calctime(curtime,opt.QPRampDelay),1,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),opt.QPRampTime,opt.QPRampTime,opt.QPValue);
            end
            
            % Switching off QP fields
            if (opt.QPValue == 0)
                setDigitalChannel(calctime(curtime,opt.QPRampDelay+opt.QPRampTime), 21, 1); % fast QP, 1 is off
                setAnalogChannel(calctime(curtime,opt.QPRampDelay+opt.QPRampTime + 5),1,0); %1 % built in 5ms delay for turning QP control to true zero
            end
    else
        opt.QPRampDelay = 0; % for calculation of total time
        opt.QPRampTime = 0;
    end
    
    % calculate total time for all ramps
    totaltime = max([opt.ShimRampDelay+opt.ShimRampTime, ...
                     opt.FeshRampDelay+opt.FeshRampTime+opt.FeshTurnoffDelay, ...
                     opt.QPRampDelay+opt.QPRampTime, 0]);
    
    % advance by total amount of time
curtime=calctime(curtime,totaltime+opt.SettlingTime);



%% assigning outputs (edit with care!)

timeout = curtime;

    
end