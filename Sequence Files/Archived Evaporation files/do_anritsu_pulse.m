%------
%Author: Dave
%Created: May 2012
%Summary: Run through a list of evaporation frequencies. Added to Rb
%hyperfine splitting
%------
function timeout = do_anritsu_pulse(timein, fake_sweep, hold_time)


curtime = timein;
global seqdata;

%Channel 19 is the RF switch
%Channel 13 is RF enable, but we're not really sure what that does


%Make sure that RF/uWave switch is set to allow uwaves through through
setDigitalChannel(calctime(curtime,0),17,1);
%Make sure RF is off
setDigitalChannel(calctime(curtime,0),19,0);

Rb_splitting = 6.83468E9;


% if (-length(sweep_times)+length(freqs))~=1
%     error('Frequency sweep not setup properly.');
% end


if fake_sweep
        
        curtime = calctime(curtime,pulse_time+50);

else

    %turn uWave switch on:
    %setDigitalChannel(calctime(curtime,50),14,1);
    %setAnalogChannel(calctime(curtime,50),1,0,1);
       
    %send command to DDS 
    %curtime = DDS_sweep(calctime(curtime,0),2,0+Rb_splitting,0+Rb_splitting,50);
    
    %send trigger to anritsu
    curtime = DigitalPulse(calctime(curtime,0),11,hold_time+50,1);
        
    %turn uWave switch off:
    %curtime = setDigitalChannel(calctime(curtime,pulse_time),14,0);
    %setAnalogChannel(calctime(curtime,0),1,0,1);


        
end

%Make sure that RF/uWave switch is set to allow RF through through
setDigitalChannel(calctime(curtime,10),17,0);

curtime = calctime(curtime,0);
    
timeout = curtime;

end