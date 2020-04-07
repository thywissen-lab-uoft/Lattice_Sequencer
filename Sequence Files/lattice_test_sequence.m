%------
%Author: David McKay
%Created: Nov 2012
%Summary: This is a lattice test sequence to check maximum power
%------

function timeout = lattice_test_sequence(timein)

curtime = timein;

global seqdata;

%pulse the lattice

setDigitalChannel(curtime,11,1);

curtime = calctime(curtime,100);

setAnalogChannel(curtime,40,0,1);


%trigger
DigitalPulse(calctime(curtime,0.0),12,1,1)

for i = 1:1

    %pulse lattice
    DigitalPulse(calctime(curtime,-0.07),11,300,0);

    %take a picture
    curtime = absorption_image(calctime(curtime,0.0),1); 
    
    curtime = calctime(curtime,100);

end

setDigitalChannel(curtime,11,1);

%% End
timeout = curtime;


end

