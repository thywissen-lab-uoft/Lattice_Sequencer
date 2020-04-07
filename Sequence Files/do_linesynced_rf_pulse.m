%------
%Function call: timeout = do_linesynced_rf_pulse(timein, fake_sweep, freq, pulse_window, hold_time, pulse_pwr)
%Author: Stefan
%Created: April 2014
%Summary: Arms a 60Hz synchronization box that triggers a signal generator.
%         The actual pulse length is set by the signal generator.
%         'pulse_window' should be at least this pulse length plus 17ms. This 
%         function does actually not switch any fast rf switch directly. It just 
%         provides the right setting of transfer switches, frequency and
%         gain.
%         Built from do_rf_pulse

%------
function timeout = do_linesynced_rf_pulse(timein, fake_sweep, freq, pulse_window, hold_time, pulse_pwr)


curtime = timein;
global seqdata;

transfer_switch_delay = -50;

if (val ~= 0)
    if lasttime >= calctime(curtime,transfer_switch_delay);
        buildWarning('do_rf_pulse','Not enough time to switch transfer switch!',1)
    else
        setDigitalChannel(calctime(curtime,transfer_switch_delay),17,0);
    end
end
%Make sure RF is off
setDigitalChannel(calctime(curtime,0),19,0);


% if (-length(sweep_times)+length(freqs))~=1
%     error('Frequency sweep not setup properly.');
% end


if fake_sweep
        
        curtime = calctime(curtime,pulse_window);

else
    
    buildWarning('do_linesynced_rf_pulse',sprintf('pulse_window = %g. Make sure pulse generator is connected to right switch!',pulse_window),0)
    
    %arm 60Hz synchronization box (falling flank on channel d47 '60Hz
    %sync') 
    DigitalPulse(calctime(curtime,-1),'60Hz sync',1,1);
       
    %send command to DDS
    if ( freq > 0 );
        DDS_sweep(calctime(curtime,-50),1,freq,freq,50);
    end
    
    %set RF gain
    setAnalogChannel(calctime(curtime,-50), 39, pulse_pwr ,1); %7
    curtime = calctime(curtime,pulse_window);        
    setAnalogChannel(calctime(curtime,pulse_window), 39, 0 ,1);
        
end

%Make sure that RF/uWave switch is set to allow RF through through
setDigitalChannel(calctime(curtime,0),17,0);

curtime = calctime(curtime,hold_time);
    
timeout = curtime;

end