%------
%Function call: timeout = do_uwave_pulse(timein, disable_pulse, freq, pulse_time, hold_time, atomtype)
%Author: Dave
%Created: May 2012
%Summary: Sets transfer switches
%------
function timeout = do_uwave_pulse(timein, disable_pulse, freq, pulse_time, hold_time, atomtype)

    %Input argument 'freq' is unused since we no longer use the DDS to
    %reference our microwave frequency for Rb
    Rb_splitting = 6.83468E9; %unused

curtime = timein;
    global seqdata;

    if nargin == 5
        %No atomtype defined, assume Rb by default
        atomtype = 0; %0 = Rb, 1 = K
    else
    end

    transfer_switch_delay = -50; % how much earlier to switch the transfer switches
    
    %Make sure RF is off
    setDigitalChannel(calctime(curtime,0),19,0);

    %Make sure that RF/uWave switch is set to allow uWaves through through
    if ~(getChannelValue(seqdata,'RF/uWave Transfer',0) == 1)
        setDigitalChannel(calctime(curtime,transfer_switch_delay),'RF/uWave Transfer',1); %0: RF, 1: uwave
    end 
%     setDigitalChannel(calctime(curtime,transfer_switch_delay),'RF/uWave Transfer',1);
    %Make sure that K/Rb uWave switch is set to the right atom

    
    if atomtype == 0
        %Rb
        if ~(getChannelValue(seqdata,'K/Rb uWave Transfer',0) == 1)
            setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb uWave Transfer',1); %0: K, 1: Rb 
        end         
%         setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb
%         uWave Transfer',1);
        switch_id = 14;  %Rb switch is channel 14
    elseif atomtype == 1
        %K
        if ~(getChannelValue(seqdata,'K/Rb uWave Transfer',0) == 0)
            setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb uWave Transfer',0); %0: K, 1: Rb 
        end                 
%         setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb
%         uWave Transfer',0);
        switch_id = 39;  %K switch is channel 39
    else
        error('Invalid atom type for do_uwave_pulse.')
    end

    if disable_pulse       
curtime = calctime(curtime,pulse_time);
    else
        %pulse uWave switch:
curtime = DigitalPulse(calctime(curtime,0),switch_id,pulse_time,1);
    end


    %Make sure that RF/uWave switch is set to allow RF through through
%     setDigitalChannel(calctime(curtime,10),'RF/uWave Transfer',0);
    %Make sure that Rb/K uWave switch is set back to Rb at the end
%     setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1);

    curtime = calctime(curtime,hold_time);

    timeout = curtime;
    
%     buildWarning('do_uwave_pulse','Recently changed timing of this function. Make sure, pulses work correctly.',0);

end