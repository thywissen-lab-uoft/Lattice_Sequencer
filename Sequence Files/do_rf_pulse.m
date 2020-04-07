%------
%Function call: timeout = do_rf_pulse(timein, fake_sweep, freq, pulse_time,
%hold_time, pulse_pwr)
%Author: Dave
%Created: May 2012
%Updated: April 2014 (S.T.)
%Summary: Does a fix-frequency rf pulse with the DDS; fake_sweep = 1 
%   suppresses RF; freq <= 0 does use current DDS freq.
%   timeout = timein + pulse_time + hold_time
%   hold_time is a relic that may be unused at this time.
%------
function timeout = do_rf_pulse(timein, fake_sweep, freq, pulse_time, hold_time, pulse_pwr)


curtime = timein;
global seqdata;

transfer_switch_delay = -50;

% in preparation of removing transfer_switch_delay from adding to (timeout - timein)
% curtime = calctime(curtime,-transfer_switch_delay);

%Set transfer switch (d17) to send RF to antenna; only set switch if it is
%not already in the correct position
[val, lasttime] = getChannelValue(seqdata,17,0);
if (val ~= 0)
    if lasttime >= calctime(curtime,transfer_switch_delay);
        buildWarning('do_rf_pulse','Not enough time to switch transfer switch!',1)
    else
        setDigitalChannel(calctime(curtime,transfer_switch_delay),17,0);
    end
end

if fake_sweep
        
        curtime = calctime(curtime,pulse_time);

else
    
    %set DDS frequency 5ms early (arbitrarily chosen -- should be made as small
    %as can be) %RHYS October 30, 2018 - Going back in time by 5ms causing
    %annoying changes of frequency for previous RF pulse during
    %spectroscopy. Drop this. 
    % set DDS frequency; setting freq to a value <= 0 can be used to leave DDS where it is at the moment
    if ( freq > 0 );
        DDS_sweep(calctime(curtime,0),1,freq,freq,5); %-5ms
    end

    %set RF gain 5ms early (arbitrarily chosen -- should be made as small as can be)
    setAnalogChannel(calctime(curtime,0), 'RF Gain', pulse_pwr ,1); %7 %-5ms
    
    %turn rf switch on:
    %Added 1ms here to give gain and frequency time to adjust. RHYS October
    %30, 2018
curtime = setDigitalChannel(calctime(curtime,1),'RF TTL',1); 
    
    % advance in time by pulse_length
curtime = calctime(curtime,pulse_time);
        
    %turn rf switch off:
    setDigitalChannel(calctime(curtime,0),'RF TTL',0);

    % set RF gain to minimum once done
    setAnalogChannel(calctime(curtime,0), 'RF Gain', -10 ,1);
        
end

%Make sure that RF/uWave switch is set to allow RF through through
% setDigitalChannel(calctime(curtime,0),17,0);

curtime = calctime(curtime,hold_time); %this hold_time is a bit weird. Leaving it for now to avoid conflicts
    
timeout = curtime;

end