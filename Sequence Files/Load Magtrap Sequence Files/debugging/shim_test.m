function curtime = shim_test(timein)
curtime = timein;

global seqdata;

%Choose which set of shims to test
test_MOT = 1;
test_science = 0;


%Set the shim values
x_shim_val = 0.2;
y_shim_val = 2.0;
z_shim_val = 0.9;
% 
% x_shim_val = -1.1975;
% y_shim_val = 0.0598;
% z_shim_val = 0.2485;


if test_MOT
%     curtime = calctime(curtime,5000);
    %Don't close relay for Science Cell Shims because of current spikes
    setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1); %1=on, 0=off

    %Turn on MOT Shim Supply Relay
%     setDigitalChannel(calctime(curtime,0),'Shim Relay',1); %1=on, 0=off

    % Set the shim values for the MOT chamber
    setAnalogChannel(calctime(curtime,0),'X MOT Shim',x_shim_val,2); %0.2
    setAnalogChannel(calctime(curtime,0),'Y MOT Shim',y_shim_val,2); %2.0
    setAnalogChannel(calctime(curtime,0),'Z MOT Shim',z_shim_val,2); %0.9

%Wait a certain amount of time
curtime = calctime(curtime,5000);

    % Set the shim values for the MOT chamber
%     setAnalogChannel(calctime(curtime,0),'X MOT Shim',0,1);
%     setAnalogChannel(calctime(curtime,0),'Y MOT Shim',0,1);
%     setAnalogChannel(calctime(curtime,0),'Z MOT Shim',0,1);


end


if test_science

    %Don't close relay for Science Cell Shims because of current spikes
    setDigitalChannel(calctime(curtime,0),'Bipolar Shim Relay',1); %1=on, 0=off
    
     %Turn on MOT Shim Supply Relay
    setDigitalChannel(calctime(curtime,0),'Shim Relay',1); %1=on, 0=off
   
    %Set the shim values for the science chamber
    setAnalogChannel(calctime(curtime,0),'X Shim',x_shim_val,1); %-1.1975 for plug
    setAnalogChannel(calctime(curtime,0),'Y Shim',y_shim_val,1); %0.0598 for plug
    setAnalogChannel(calctime(curtime,0),'Z Shim',z_shim_val,1); %0.2485 for plug
   
%Wait a certain amount of time
curtime = calctime(curtime,2500);

    % Set the shim values to zero
    setAnalogChannel(calctime(curtime,0),'X Shim',0,1);
    setAnalogChannel(calctime(curtime,0),'Y Shim',0,1);
    setAnalogChannel(calctime(curtime,0),'Z Shim',0,1);
   
    
end





end

