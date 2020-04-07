%------
%Author: DM
%Created: March 2011
%Summary: This function turns off light (repump, trap, probe or OP) where
%there is a TTL, analog and shutter
%------

function timeout=turn_off_beam(timein, beam_ID, shutteronly, atomtype)

global seqdata;

curtime = timein;


if nargin < 4
    atomtype = seqdata.atomtype;
end

if nargin<3
    shutteronly = 0;
    atomtype = seqdata.atomtype;
end

%call for both atoms (unless plug)
if atomtype==4 && beam_ID~=5
    turn_onoff_beam(timein,beam_ID,0,2,0,shutteronly);
    turn_onoff_beam(timein,beam_ID,0,3,0,shutteronly);
    timeout = curtime;
    return;
else
    turn_onoff_beam(timein,beam_ID,0,atomtype,0,shutteronly);
end


timeout = curtime;

end
