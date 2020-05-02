%------
%Author: DM
%Created: March 2011
%Summary: This function turns on light (repump, trap, probe or OP) where
%there is a TTL, analog and shutter
%------

function timeout=turn_on_beam(timein, beam_ID, analogvolt, atomtype)


global seqdata;

curtime = timein;


if nargin < 4
    atomtype = seqdata.atomtype;
end

%call for both atoms (unless plug)
if atomtype==4 && beam_ID~=5
    turn_onoff_beam(timein,beam_ID,analogvolt,2,1,-1);
    turn_onoff_beam(timein,beam_ID,analogvolt,3,1,-1);
    timeout = curtime;
    return;
else
    turn_onoff_beam(timein,beam_ID,analogvolt,atomtype,1,-1);
end


timeout = curtime;

end
