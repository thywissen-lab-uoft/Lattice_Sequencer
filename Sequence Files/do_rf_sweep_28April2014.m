%------
%Author: Dave
%Created: May 2012
%Summary: Run through a list of rf sweeps for state transfer
%------
function timeout = do_rf_sweep(timein, fake_sweep, freqs, sweep_times, rf_gains)


curtime = timein;
global seqdata;

%Channel 19 is the RF switch
%Channel 13 is RF enable, but we're not really sure what that does

transfer_switch_delay = -50;

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

if (-length(sweep_times)+length(freqs))~=1
    error('Frequency sweep not setup properly.');
end


if fake_sweep
        
        curtime = calctime(curtime,sum(sweep_times));

else

    setAnalogChannel(calctime(curtime,-20), 39, rf_gains(1),1);
   
    %sweep 1 
    for i = 1:length(sweep_times)
        setAnalogChannel(calctime(curtime,0), 39, rf_gains(i),1);
        %turn RF on:
        setDigitalChannel(calctime(curtime,10),19,1);
curtime = DDS_sweep(calctime(curtime,1),1,freqs(i),freqs(i+1),sweep_times(i));
curtime = setDigitalChannel(calctime(curtime,10),19,0);
    end

    %turn DDS (Rf) off:
    
    setAnalogChannel(curtime, 39, 0, 1);
    
end

timeout = curtime;

end