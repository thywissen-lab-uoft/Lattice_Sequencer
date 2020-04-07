%------
%Author: Dave
%Created: May 2012
%Summary: Run through a list of evaporation frequencies. Added to Rb
%hyperfine splitting
%------
function timeout = do_uwave_evap_stage(timein, fake_sweep, freqs, sweep_times, hold_time)


curtime = timein;
global seqdata;

%Channel 19 is the RF switch
%Channel 13 is RF enable, but we're not really sure what that does


%Make sure that RF/uWave switch is set to allow uwaves through through
setDigitalChannel(calctime(curtime,0),17,1);
%Make sure RF is off
setDigitalChannel(calctime(curtime,0),19,0);

Rb_splitting = 6.83468E9;

%allow time for switch to change
curtime = calctime(curtime, 50);

if (-length(sweep_times)+length(freqs))~=1
    error('Frequency sweep not setup properly.');
end


if fake_sweep
        
        curtime = calctime(curtime,sum(sweep_times));

else

    
   %turn uWave on:
    setDigitalChannel(calctime(curtime,10),14,1);

    %reset DDS
    %DDS_sweep(calctime(curtime,-200),2,7E9,7E9,100);
    
    %sweep 1 
    for i = 1:length(sweep_times)
        curtime = DDS_sweep(calctime(curtime,10),2,freqs(i)+Rb_splitting,freqs(i+1)+Rb_splitting,sweep_times(i));
    end
    
     %reset DDS
    %DDS_sweep(calctime(curtime,100),2,7E9,7E9,100);
    
    
    curtime = setDigitalChannel(calctime(curtime,0),14,0);

        
end

%Make sure that RF/uWave switch is set to allow RF through through
setDigitalChannel(calctime(curtime,0),17,0);

curtime = calctime(curtime,hold_time);
    
timeout = curtime;

end