%------
%Author: Dave
%Created: May 2012
%Summary: Run through a list of evaporation frequencies
%------
function timeout = do_evap_stage(timein, fake_sweep, freqs, sweep_times, rf_gains, hold_time, last_rf_stage)


curtime = timein;
global seqdata;

%Channel 19 is the RF switch
%Channel 13 is RF enable, but we're not really sure what that does
%RHYS - If referring to digital channel 13, seems to be associated with
%triggering an old Rb uwave DDS to sweep, which is now used for the 4-pass.
%So, possibly unused. 


%Make sure that RF/uWave switch is set to allow RF through:
setDigitalChannel(calctime(curtime,0),17,0);

if (-length(sweep_times)+length(freqs))~=1
    error('Frequency sweep not setup properly.');
end


if fake_sweep
        
        curtime = calctime(curtime,sum(sweep_times));

else

    
%     if (freqs(1)>1E6 && min(sweep_times)>100)
%         DDS_sweep(calctime(curtime,-200),1,min([freqs(1)*1.5 80*1E6]),min([freqs(1)*1.5 80*1E6]),100);
%     end
    %turn RF on:
    setDigitalChannel(calctime(curtime,0),19,1);

    %sweep 1 
    for i = 1:length(sweep_times)
%         setAnalogChannel(calctime(curtime,0), 39, rf_gains(i),1);
            setAnalogChannel(calctime(curtime,0), 39, rf_gains(i));

        %RHYS - The '1' here means DDSID = 1, which indicates the RF evap
        %DDS in DDS_sweep. This uses digital channel 18 as its trigger for
        %the sweep.
        curtime = DDS_sweep(calctime(curtime,10),1,freqs(i),freqs(i+1),sweep_times(i));
    end

    %turn DDS (Rf) off:
    %RHYS - this is a little janky. Turns off the RF completely only if we
    %are at the last stage of rf, which of course depends on the sequence
    %called.
    if last_rf_stage
        setAnalogChannel(curtime, 39, -10);% rf gain
%         setAnalogChannel(curtime, 39, -10, 1);% rf gain

    end
    curtime = setDigitalChannel(calctime(curtime,0),19,0);% rf TTL

end

curtime = calctime(curtime,hold_time);
    
timeout = curtime;

end