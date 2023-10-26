function curtime = MOT_fluorescence_image(curtime)
global seqdata

 %%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%

    % Turn off the field gradient
    setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);    

    % Turn off the D2 beams, if they arent off already
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1);
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1); 
    

    % Keep shutters open
    setDigitalChannel(calctime(curtime,0),'Rb Trap Shutter',1);
    setDigitalChannel(calctime(curtime,0),'K Trap Shutter',1);
    

    % Turn off the D1 beams. The GM stage automattically does this
    
    
    %%%%%%%%%%%%%% Prepare detunings and powers %%%%%%%%%%%%
    % Set potassium detunings to resonances 
    setAnalogChannel(calctime(curtime,0.5),'K Trap FM',0);
    setAnalogChannel(calctime(curtime,0.5),'K Repump FM',0,2);

    % Set potassium power to standard value
    setAnalogChannel(calctime(curtime,0.5),'K Repump AM',0.45);          
    setAnalogChannel(calctime(curtime,0.5),'K Trap AM',0.8);            

    % Set Rubidium detunings to resonance  
    f_osc = calcOffsetLockFreq(0,'MOT');
    DDS_id = 3;    
    DDS_sweep(calctime(curtime,0.5),DDS_id,f_osc*1e6,f_osc*1e6,.01);       

    % Set rubdium power to standard value
    setAnalogChannel(calctime(curtime,0.5),'Rb Trap AM', 0.7);    

    %%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%
    % Increment the time (ie. perform the time of flight
    curtime = calctime(curtime,getVar('tof'));     
    
    % Rubidium Repump
    setAnalogChannel(calctime(curtime,-.5),'Rb Repump AM',0.9);    
    
    %%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
    switch seqdata.flags.image_atomtype
        case 1
            % 30 dB gain works with 64 us exposure
            
            %turn K light on 
            setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
            setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
            
            
            %turn K light off
            setDigitalChannel(calctime(curtime,5),'K Trap TTL',1); 
            setDigitalChannel(calctime(curtime,5),'K Repump TTL',1);
            
        case 0
            % 10 dB gain works with 64 us exposure

            setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);
%             setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1);

            setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',1);



    end 

    % Camera Trigger (1) : Light+Atoms
    setDigitalChannel(calctime(curtime,0),'MOT Camera Trigger',1);
    setDigitalChannel(calctime(curtime,2),'MOT Camera Trigger',0);
    
    ScopeTriggerPulse(calctime(curtime,0),'MOT Trigger');

    % Wait for second image trigger
    curtime = calctime(curtime,1000);
    
    switch seqdata.flags.image_atomtype
        case 1
            % 30 dB gain works with 64 us exposure
            
            %turn K light on 
            setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
            setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
            
            
            %turn K light off
            setDigitalChannel(calctime(curtime,5),'K Trap TTL',1); 
            setDigitalChannel(calctime(curtime,5),'K Repump TTL',1);
            
        case 0
            % 10 dB gain works with 64 us exposure

            setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);
%             setDigitalChannel(calctime(curtime,-2),'Rb Repump Shutter',1);

            setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',1);
            
    end


    % Camera Trigger (2) : Light only
    setDigitalChannel(calctime(curtime,0),'MOT Camera Trigger',1);
    setDigitalChannel(calctime(curtime,2),'MOT Camera Trigger',0);
end

