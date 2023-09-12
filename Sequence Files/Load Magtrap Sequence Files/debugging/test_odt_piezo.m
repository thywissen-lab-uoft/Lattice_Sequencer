function timeout = test_odt_piezo(timein)

curtime = timein;
curtime=calctime(curtime,1000);

% Turn on XDTs
setDigitalChannel(calctime(curtime,0),'XDT TTL',0); % 0: on, 1: off

% Turn on XDT powers
setAnalogChannel(calctime(curtime,0),'dipoleTrap1',.2);
setAnalogChannel(calctime(curtime,0),'dipoleTrap2',.2);

% Wait a bit
curtime = calctime(curtime,100);

curtime = lattice_conductivity_new(curtime);

% Turn off XDT powers
setAnalogChannel(calctime(curtime,-5),'dipoleTrap1',-1);
setAnalogChannel(calctime(curtime,-5),'dipoleTrap2',-1);


% Turn off XDTs
setDigitalChannel(calctime(curtime,0),'XDT TTL',1); % 0: on, 1: off


timeout = curtime;
    
end

