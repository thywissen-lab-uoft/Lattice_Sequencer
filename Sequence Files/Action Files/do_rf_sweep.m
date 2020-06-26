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


%Make sure that RF/uWave switch is set to allow RF through:
setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0);

if (-length(sweep_times)+length(freqs))~=1
    error('Frequency sweep not setup properly.');
end


if fake_sweep
        
        curtime = calctime(curtime,sum(sweep_times));

else
    % setAnalogChannel(calctime(curtime,-20), 'RF Gain', rf_gains(1),1);
    setAnalogChannel(calctime(curtime,-0.1), 'RF Gain', rf_gains(1),1);
   
    %sweep 1 %This code adds 1ms delays before and after RF sweeps. Also,
    %turns off the RF after each sweep.
    for i = 1:length(sweep_times)
        setAnalogChannel(calctime(curtime,0), 'RF Gain', rf_gains(i),1);
        %turn RF on:
        setDigitalChannel(calctime(curtime,0.1),'RF TTL',1);
        curtime = DDS_sweep(calctime(curtime,1),1,freqs(i),freqs(i+1),sweep_times(i));
        curtime = setDigitalChannel(calctime(curtime,1.1),'RF TTL',0);
    end

    %turn DDS (Rf) off:
    
    setAnalogChannel(curtime, 39, 0, 1);
    
end

timeout = curtime;

end