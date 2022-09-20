function timeout = AnalogFuncTo(timein,channel,fhandle,tt,varargin)
%------
%Function call: timeout = AnalogFuncTo(timein,channel,fhandle,tt,varargin)
%Author: Stefan Trotzky
%Created: 2014
%Summary: exectutes a function on the analog channel defined by fhandle for time tt
%   fhandle is the handle to a function that takes as its first argument a
%   time array. The rest of the parameters are passed in form varargin
%   In contrast to AnalogFunc, this funcion creates ramps that start at the
%   last set value for the respective channel (makes use of getChannelValue.m
%   and seqdata.params.analogch)
%------

global seqdata;

if ( ischar(channel) ) % channel name lookup
    channel = name_lookup(channel,1);
end

%check this is a valid channel
if (channel<0 || channel>length(seqdata.analogchannels))
    error('Invalid analog channel');
end

% Check if more arguments than needed for calling fhandle are handed over.
% AnalogFuncTo assumes a function definition like fun(t,tt,y0,...), where
% the 3rd argument y0 is the start value (at t=0) of the function and is
% not given as an argument. It will be taken from seqdata.params.analogch
% instead.
% Use next argument as voltagefunctionindex if present (in case it is an integer).
nfunarg = nargin(fhandle);
if channel~=0 
    [curvalue, curvoltagefuncindex, curvoltage, lasttime] = getChannelValue(seqdata,channel,1,0);
    
    % checking whether channel is attempted to be ramped before last value
    % on channel was set in the "past".
    quiet = 0;
    if (lasttime > timein) && (~quiet)
        chName = seqdata.analogchannels(channel).name;
        error(['Attempting to use AnalogFuncTo to start a ramp before the last \n' ...
            'change done on analog channel %g %s (time = %g).\n' ...
            'Set flag ''quiet'' in order to suppress this error.'],channel,chName,timein);
    elseif (lasttime > timein) && (quiet)
        buildWarning(sprintf('AnalogFuncTo::Warning -- Channel %g set earlier than last change at time %g!',channel,timein));
    end
    
    % check user input
    if ( length(varargin) > (nfunarg-2) )
        if ( isnumeric(varargin{nfunarg-1}) && ~isempty(varargin{nfunarg-1}) )
            if round(varargin{nfunarg-1}) ~= varargin{nfunarg-1}
                error('Voltage function index needs to be integer.')
            else
                voltagefuncindex = varargin{nfunarg-1};
            end
        else
            voltagefuncindex = seqdata.analogchannels(channel).defaultvoltagefunc;
        end
    else
        voltagefuncindex = seqdata.analogchannels(channel).defaultvoltagefunc;
    end
else
    error('AnalogFuncTo does not support transport ramps (channel zero)!')
end

if (voltagefuncindex ~= curvoltagefuncindex) 
    if voltagefuncindex ~= 1 
        % if voltagefunction indeces do not match: need to numerically
        % invert voltage functions ...
        [curvalue, check] = invertVoltagefunc(seqdata,channel,curvoltage,voltagefuncindex,1);
        if abs(check-curvoltage) > 1e-3
            error(sprintf('Inversion of voltage function unsuccessfull!! channel: %g, index: %g, voltage: %g .',...
                channel,voltagefuncindex,curvoltage));
        end
    else
        % use real adwin voltage
        curvalue = curvoltage;
    end
else
     % use voltage function (no additional assignments needed)
end


if (tt == 0) % deal with zero-time ramps: set channel to ramp end value.
    if (channel == 0)
        % do nothing (arriving here when trying to build transport ramps
        % with zero time)
    else
        t=1:10;
        fakeramp = fhandle(t,10,curvalue,varargin{2:(nfunarg-2)}); % calculate a fake ramp in order to see where it is ramping to
        seqdata.params.analogch(channel,2:4)=[fakeramp(end) voltagefuncindex timein];
        funcarray = [timein, channel, seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(fakeramp(end))];
        if (sum(funcarray(:,3)>seqdata.analogchannels(channel).maxvoltage) || sum(funcarray(:,3)<seqdata.analogchannels(channel).minvoltage))
            error('Voltage out of range')
        end
        seqdata.analogadwinlist = [seqdata.analogadwinlist; funcarray];
        seqdata.params.analogch(channel,1)=funcarray(end,3);
    end
    timeout = timein;
else
    %convert time into the number of update cycles
    endtime = calctime(0,tt);

    if (channel==43 || channel==44 || channel==45 || channel==47  || channel==52 || channel==28 || channel==6 || channel== 39) %lattices and Raman VVA
        % ramp lattice channels with smaller steps to avoid heating (put 30kHz
        % filter on AM input of ALPS)
        if endtime <= 1000;
            t = 0:1:endtime; % every 5us
        elseif (endtime > 1000 && endtime <= 50000)
            t = 0:4:endtime; % every 20us
        else
            t = 0:6:endtime; % every 30us = 6*5us
        end
    else
        %update every 10us
        t = 0:10:endtime;
    end

    timeout = t(end)+timein;

    %create the function array
    funcarray = zeros(length(t),3);

    funcarray(:,1) = t+timein;
    funcarray(:,2) = ones(1,length(t))*channel;
    % call fhandle(t,tt,y0,various) 
    funcarray(:,3) = fhandle(t*seqdata.deltat/seqdata.timeunit,varargin{1},curvalue,varargin{2:(nfunarg-2)});

    seqdata.params.analogch(channel,2:4)=[funcarray(end,3) voltagefuncindex timeout];
    funcarray(:,3) = seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(funcarray(:,3));

    %make sure the voltages are within the min/max ranges
    if (sum(funcarray(:,3)>seqdata.analogchannels(channel).maxvoltage) || sum(funcarray(:,3)<seqdata.analogchannels(channel).minvoltage))
        error('Voltage out of range')
    end
    seqdata.params.analogch(channel,1)=funcarray(end,3);

    seqdata.analogadwinlist = [seqdata.analogadwinlist; funcarray];

end

seqdata.ramptimes = [seqdata.ramptimes; channel timein timeout];

end