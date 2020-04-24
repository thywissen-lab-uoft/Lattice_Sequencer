%------
%Author: David McKay
%Created: Dec 2010
%Summary: An example of how an evaporation sequence might run. Totally
%contrived and not meant to represent anything real.
%------
function timeout = Evaporation_sequence(timein)

curtime = timein;
global seqdata;

seqdata.numDDSsweeps = 0;

%Load from Magnetic Trap (or something)
%curtime = Load_MagTrap_sequence(timein);

GHz = 1E9;
MHz = 1E6;

%turn DDS (Rf) on:
curtime = setDigitalChannel(calctime(curtime,3000),13,1);
%turn Microwaves on:
curtime = setDigitalChannel(calctime(curtime,0),17,1);

%setup frequency
%curtime = DDS_sweep(calctime(curtime,0),1,1.16*GHz,1.161*GHz,3000);

%sweep 1 
%curtime = DDS_sweep(calctime(curtime,0),1,1.16*GHz,1.161*GHz,3000);
curtime = DDS_sweep(calctime(curtime,0),1,1.290*GHz,1.29001*GHz,3000);
%sweep 2 
%curtime = DDS_sweep(calctime(curtime,0),1,8E6,10E6,3000);


%turn DDS (Rf) off:
curtime = setDigitalChannel(calctime(curtime,0),13,0);
%turn Microwaves off:
curtime = setDigitalChannel(calctime(curtime,0),17,0);

%%Timeout
timeout = curtime;


end