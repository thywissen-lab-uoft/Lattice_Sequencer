%------
%Function call: timeout = do_uwave_pulse(timein, disable_pulse, freq, pulse_time, hold_time, atomtype)
%Author: Dave
%Created: May 2012
%Summary: Sets transfer switches
%------
function timeout = do_linesync_uwave_pulse(timein, disable_pulse, freq, pulse_window, hold_time, atomtype)

    %Input argument 'freq' is unused since we no longer use the DDS to
    %reference our microwave frequency for Rb
    
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
    %Make sure that K/Rb uWave switch is set to the right atom
    if atomtype == 0
        %Rb
        if ~(getChannelValue(seqdata,'K/Rb uWave Transfer',0) == 1)
            setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb uWave Transfer',1); %0: K, 1: Rb 
        end         
        atom = 'Rb';
    elseif atomtype == 1
        %K
        if ~(getChannelValue(seqdata,'K/Rb uWave Transfer',0) == 0)
            setDigitalChannel(calctime(curtime,transfer_switch_delay),'K/Rb uWave Transfer',0); %0: K, 1: Rb 
        end
        atom = 'K';
    else
        error('Invalid atom type for do_uwave_pulse.')
    end

    if disable_pulse       
    else
        %Arm 60Hz line synchronization; pulse length set manually on pulse
        %generator!
        buildWarning('do_linesynced_uwave_pulse',sprintf(['pulse_window = %g. Make sure pulse generator is connected to right switch (' atom ,')!'],pulse_window),0)
        DigitalPulse(calctime(curtime,-1),'60Hz sync',1,1); % is armed on falling flank    
    end

curtime = calctime(curtime,pulse_window);

curtime = calctime(curtime,hold_time);

timeout = curtime;
    

end