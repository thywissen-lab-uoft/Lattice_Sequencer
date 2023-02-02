function curtime = MOT_fluorescence_image(curtime)
global seqdata

 %%%%%%%%%%%% Turn off beams and gradients %%%%%%%%%%%%%%

    % Turn off the field gradient
    setAnalogChannel(calctime(curtime,0),'MOT Coil',0,1);    

    % Turn off the D2 beams, if they arent off already
    setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
    setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
    setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);   

    % Turn off the D1 beams. The GM stage automattically does this

    %%%%%%%%%%%% Perform the time of flight %%%%%%%%%%%%


    % Increment the time (ie. perform the time of flight
    curtime = calctime(curtime,getVar('tof'));

    %%%%%%%%%%%%%% Perform fluoresence imaging %%%%%%%%%%%%
    %turn back on D2 for imaging (or make it on resonance)  

    % Set potassium detunings to resonances (0.5 ms prior to allow for switching)
    setAnalogChannel(calctime(curtime,0),'K Trap FM',0);
    setAnalogChannel(calctime(curtime,0),'K Repump FM',0,2);

    % Set potassium power to standard value
    setAnalogChannel(calctime(curtime,-1),'K Repump AM',0.45);          
    setAnalogChannel(calctime(curtime,-1),'K Trap AM',0.8);            

    % Set Rubidium detunings to resonance (0.5 ms prior to allow for switching)
    setAnalogChannel(calctime(curtime,-1),'Rb Beat Note FM',6590)

    % Set rubdium power to standard value
    setAnalogChannel(calctime(curtime,-1),'Rb Trap AM', 0.7);            
    setAnalogChannel(calctime(curtime,-1),'Rb Repump AM',0.9);          

    switch seqdata.flags.image_atomtype
        case 1
            setDigitalChannel(calctime(curtime,0),'K Trap TTL',0); 
            setDigitalChannel(calctime(curtime,0),'K Repump TTL',0); 
            setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',1);  
        case 0
            setDigitalChannel(calctime(curtime,0),'K Trap TTL',1); 
            setDigitalChannel(calctime(curtime,0),'K Repump TTL',1); 
            setDigitalChannel(calctime(curtime,0),'Rb Trap TTL',0);  
    end 

    % Camera Trigger (1) : Light+Atoms
    setDigitalChannel(calctime(curtime,0),15,1);
    setDigitalChannel(calctime(curtime,10),15,0);

    % Wait for second image trigger
    curtime = calctime(curtime,3000);

    % Camera Trigger (2) : Light only
    setDigitalChannel(calctime(curtime,0),15,1);
    setDigitalChannel(calctime(curtime,10),15,0);
end

