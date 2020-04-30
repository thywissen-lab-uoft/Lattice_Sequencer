%------
%Author: Stefan Trotzky
%Created: November 2013
%Summary: A sequence for pulsed AOM/fiber alignment
%------
function timeout = pulsedAlignment(timein)

    curtime = timein;
    
    global seqdata;
    
    initialize_channels()
    
    pwrFractionLattice = 0.0;
    
    pulse_length = 20;
    
    curtime = calctime(curtime,0);
    
    setAnalogChannel(curtime,'latticeWaveplate',pwrFractionLattice,3);
    %DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
    
    curtime = calctime(curtime,100);    
    
    ramptime = [0.1 100 50 50 50];
    Pdip1 = 0.1*[1 1 0 1 0];
    
    y1 = [0 Pdip1(1:end-1)]
    y2 = Pdip1
    
    DigitalPulse(curtime,12,pulse_length,1)
    
    for j = 1:length(ramptime)
        AnalogFunc(curtime,'dipoleTrap2',@(t,tt,y2,y1)(ramp_lin(t,tt,y2,y1)),ramptime(j),ramptime(j),y1(j),y2(j),1);
        curtime = calctime(curtime,ramptime(j));        
    end

    
    
   % DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
 
    curtime = calctime(curtime,pulse_length);
%     curtime = calctime(curtime,10);    
    
    curtime = calctime(curtime,10);
    
    
    curtime = calctime(curtime,100);
    
%     DigitalPulse(curtime,'PixelFly Trigger',pulse_length,1);
        
    timeout = curtime;

end