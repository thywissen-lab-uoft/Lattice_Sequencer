%------
%Author: Stefan ( Ctrl-C/Ctrl-V )
%Created: May 2013
%Summary: Reset channels to default values, defined in initialize_channels.
%         Should be called at end of cycle, before loading the MOT. Checks
%         for each channel, whether seqdata.analogchannels/digchannels(j)
%         has a resetvalue specified and resets to this value, if yes.
%         Could be added: check whether resetvalue is a cell array with
%         more instructions on how to go to the resetvalue (i.e. ramps,
%         etc.)
%------

function timeout = Reset_Channels(timein)
global seqdata;

    curtime = timein;
    
    % going through analog channles and reset to resetvalue if one is
    % specified
    for j = 1:length(seqdata.analogchannels);
        if isfield(seqdata.analogchannels(j),'resetvalue');
            if seqdata.analogchannels(j).resetvalue(1) ~= 1i; % using complex i to indicate no change
%                 disp(sprintf('Resetting a%g',j))
                if length(seqdata.analogchannels(j).resetvalue) == 1
                    % default: use default voltage function
                    setAnalogChannel(curtime,j,seqdata.analogchannels(j).resetvalue(1));
                elseif length(seqdata.analogchannels(j).resetvalue) == 2
                    % if given: use voltagefunction index specified in second
                    % element of resetvalue
                    setAnalogChannel(curtime,j,seqdata.analogchannels(j).resetvalue(1),seqdata.analogchannels(j).resetvalue(2));
                end
            end
        end
    end
    
    % going through digital channels and reset to resetvalue if one is
    % specified
    for j = 1:length(seqdata.digchannels);
        if isfield(seqdata.digchannels(j),'resetvalue');
            if (seqdata.digchannels(j).resetvalue ~= 1i); % using complex i to indicate no change
%                 disp(sprintf('Resetting d%g',j))
                setDigitalChannel(curtime,j,seqdata.digchannels(j).resetvalue(1));
            end
        end
    end
   
    timeout = curtime;
    
end