function timeout = AnalogFunc(timein,channel,fhandle,tt,varargin)

global seqdata;

%exectutes a function on the analog channel defined by strfunc for time tt
%fhandle is the handle to a function that takes as its first argument a
%time array. The rest of the parameters are passed in form varargin

if ~isfield(seqdata,'coil_enable')
    % enables all transport channels -- also the default (can be changed for debugging)
    seqdata.coil_enable = ones(1,23);
end

if ( ischar(channel) ) % ST-2013-03-02 // channel name lookup feature
    channel = name_lookup(channel,1);
end

%check this is a valid channel
if (channel<0 || channel>length(seqdata.analogchannels))
    error('Invalid analog channel');
end

% Check if more arguments than needed for calling fhandle are handed over.
% Use next argument as voltagefunctionindex if present (in case it is an integer).
nfunarg = nargin(fhandle);
if channel~=0 
    if ( length(varargin) > (nfunarg-1) )
        if ( isnumeric(varargin{nfunarg}) && ~isempty(varargin{nfunarg}) )
            if round(varargin{nfunarg}) ~= varargin{nfunarg}
                error('Voltage function index needs to be integer.')
            else
                voltagefuncindex = varargin{nfunarg};
            end
        else
            voltagefuncindex = seqdata.analogchannels(channel).defaultvoltagefunc;
        end
    else
        voltagefuncindex = seqdata.analogchannels(channel).defaultvoltagefunc;
    end
end

if (tt == 0) % deal with zero-time ramps: set channel to ramp end value.
    if (channel == 0)
        % do nothing (arriving here when trying to build transport ramps
        % with zero time)
    else
        fakeramp = fhandle(10,10,varargin{2:(nfunarg-1)}); % calculate a fake ramp in order to see where it is ramping to
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

    if channel==0 %for the transport only update every 10 cycles
        %keep fixed to 0.5ms updates * if we change deltat *
        t = 0:(10*10):endtime;
        %RHYS - really? Update only every 500ms for transport?? That can't be correct,
        %can it? What does it mean "* if we change deltat *"?
    
    elseif (channel==43 || channel==44 || channel==45 || channel==47 || channel==46 || channel==53 || channel==39) %lattices
        % ramp lattice channels with smaller steps to avoid heating (put 30kHz
        % filter on AM input of ALPS)
        if endtime <= 1000;
            t = 0:1:endtime; % every 5us
        elseif (endtime > 1000 && endtime <= 50000)
            t = 0:4:endtime; % every 20us
        else
            t = 0:6:endtime; % every 30us
        end
    
    else
        %update every 50us
        t = 0:10:endtime;
    end


    %create the function array
    funcarray = zeros(length(t),3);

    funcarray(:,1) = t+timein;
    funcarray(:,2) = ones(1,length(t))*channel;
    funcarray(:,3) = fhandle(t*seqdata.deltat/seqdata.timeunit,varargin{1:(nfunarg-1)});
    
    timeout = t(end)+timein;

    if channel==0 %this is the transport channel

        %this is the standard transport
        %funcarray = transport_coil_currents_kitten_troubleshoot(funcarray(:,1),funcarray(:,3));

        %this is the transport with the coil raised
        %RHYS - This function determines the coil currents during the
        %transport sequence.
        funcarray = transport_coil_currents_kitten_troubleshoot_raise_topQP(funcarray(:,1),funcarray(:,3),0,seqdata.coil_enable);

    else
        
        % store set value, voltage function and end-time of ramp in seqdata.params for later use.
        seqdata.params.analogch(channel,2:4)=[funcarray(end,3) voltagefuncindex timeout];
        
        % conversion into adwinvoltage using voltage function
        funcarray(:,3) = seqdata.analogchannels(channel).voltagefunc{voltagefuncindex}(funcarray(:,3));

        %make sure the voltages are within the min/max ranges
        if (sum(funcarray(:,3)>seqdata.analogchannels(channel).maxvoltage) || sum(funcarray(:,3)<seqdata.analogchannels(channel).minvoltage))
            error('Voltage out of range')
        end
        
        % store adwin voltage in seqdata.params for later use.
        seqdata.params.analogch(channel,1)=funcarray(end,3);
    end
    
    seqdata.analogadwinlist = [seqdata.analogadwinlist; funcarray];
end    

seqdata.ramptimes = [seqdata.ramptimes; channel timein timeout];

end