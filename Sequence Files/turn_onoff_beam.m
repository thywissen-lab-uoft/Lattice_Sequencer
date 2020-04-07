%------
%Author: DM
%Created: Jan 2012
%Summary: This function turns on/off light (repump, trap, probe or OP) where
%there is a TTL, analog and shutter
%------

function timeout=turn_onoff_beam(timein, beam_ID, analogvolt, atomtype, turnon, shutteronly)


curtime = timein;

%Note that this is a general function that shouldn't be called
%itself...should only be called from "turn_on_beam" or "turn_off_beam"

%turnon == 1 turn the beam on
%turnon == 0 turn off the beam

% if beam_ID==4 || beam_ID==3
%     error('These channels are not setup yet!!!')
% end

shutterdelay = 0; % value for shutter delay as of 2014-03-26 used if no individual value is set

if beam_ID == 1 %trap
    if atomtype==1 || atomtype == 2 %K
        analogid = 26;
        ttlid = 6;
        shutterid = 2;
        shutterdelay = -1.2; %-1.2
    else %Rb
        analogid = 4;
        ttlid = 8;
        shutterid = 4;
        shutterdelay = -2.0; %-2.2
    end
elseif beam_ID == 2 %repump
    if atomtype==1 || atomtype == 2 %K
        analogid = 25;
        ttlid = 7;
        shutterid = 3;
    else %Rb
        analogid = 2;
        ttlid = -1; %no ttl
        shutterid = 5;
    end
elseif beam_ID == 3 %OP
    if atomtype==1 || atomtype == 2 %K
        analogid = 29;
        ttlid = 9;
        shutterid = 30;
    else %Rb
        analogid = 36;
        ttlid = 24;
        shutterid = 25;
    end
elseif beam_ID == 4 %probe
    if atomtype==1 || atomtype == 2 %K
        analogid = 29;
        ttlid = 9;
        shutterid = 30;
    else %Rb
        analogid = 36;
        ttlid = 24;
        shutterid = 25;
    end
elseif beam_ID == 5 %plug
    analogid = 33;
    ttlid = -1; %no ttl
    shutterid = 10;
else
    error('Beam ID not defined')
end


%Analog
if ~turnon
    %turn beam off
    if ~shutteronly
        setAnalogChannel(curtime,analogid,0,1);
        %TTL
        if ttlid > 0
            setDigitalChannel(curtime,ttlid,1);
        end
    end
else %turn_on
    setAnalogChannel(curtime,analogid,analogvolt);
    %TTL
    if ttlid > 0
        setDigitalChannel(curtime,ttlid,0);
    end
end


%Shutter
%  if shutterid == 1
%  setDigitalChannel(calctime(curtime,-1.7),shutterid,turnon);
%  elseif shutterid == 2
%  setDigitalChannel(calctime(curtime,-1.7),shutterid,turnon);    
%  elseif shutterid == 3
%  setDigitalChannel(calctime(curtime,0),shutterid,turnon);    
%  elseif shutterid == 4
%  setDigitalChannel(calctime(curtime,0),shutterid,turnon);        
%  else
%  end

setDigitalChannel(calctime(curtime,shutterdelay),shutterid,turnon);

timeout = curtime;

end
