%------
%Author: David + Dylan
%Created: March 2011
%Summary: Prepares the cloud for loading into the magnetic trap
%------

%----Input Vars
%blue_mot: flag to turn on blue mot
%image_type: If we want to take a fluor image of the MOT do not shut off
%----------

function timeout = Prepare_MOT_for_MagTrap(timein, image_type,image_loc)

global seqdata;

curtime = timein;

if nargin <3
   image_loc = 1; 
end

%% Take Flouresence image of MOT
%cam trigger
%DigitalPulse(curtime,1,1,1);

%% MOT Feed Forward 
%Increase the voltage on the supplies
%setAnalogChannel(calctime(curtime,10),18,10/6.6); 

%digital trigger
%DigitalPulse(curtime,12,0.1,1);

%% Bright MOT (Take out dark spot)
   
%curtime = DigitalPulse(calctime(curtime,0),15,10,1);


%% Compression

do_compression = 1 && (~(image_type==4));

if do_compression

        
        %Try "normal" CMOT stage
        
%         %ramp up gradient 
%         ramp_up_time = 10;
%         cMOT_gradient = 30;
%         
%         AnalogFunc(calctime(curtime,0.0),8,@(t,a)(a+minimum_jerk(t,ramp_up_time,cMOT_gradient-10)),ramp_up_time,10);
               
        cMOT_time = 100; %100
        Rb_cMOT_detuning = 50; %35
             
        if seqdata.atomtype==1 %K-40
            
                     
            %set shims   
            yshim_comp = 1.5;
            xshim_comp = 0.8; %0.05
            zshim_comp = 0.08;

            %optimize shims for compression (put cloud at the position of the mag
            %trap center)
            %turn on the Y (quantizing) shim 
            setAnalogChannel(calctime(curtime,-2),19,yshim_comp); %1.25
            %turn on the X (left/right) shim
            setAnalogChannel(calctime(curtime,-2),27,xshim_comp); %0.3 
            %turn on the Z (top/bottom) shim 
            setAnalogChannel(calctime(curtime,-2),28,zshim_comp); %0.2
            
            %set gradient
            setAnalogChannel(calctime(curtime,0),8,10);
            
            % % %              %   %%list
            %  cMOT_detuning_list=[765:1:774 765:1:774];
            % % 
            % % %Create linear list
            % %index=seqdata.cycle;
            % % 
            % % %Create Randomized list
            % index=seqdata.randcyclelist(seqdata.cycle);
            % % 
            %  cMOT_detuning = cMOT_detuning_list(index)
            %  addOutputParam('resonance',cMOT_detuning); 
            %             
             cMOT_detuning = 760;  

            %             %digital trigger
            %             DigitalPulse(curtime,12,0.1,1);

            %set detuning
            %detuning
            setAnalogChannel(calctime(curtime,0),34,cMOT_detuning); %765
            %FF
            setAnalogChannel(calctime(curtime,0),35,0.1,1); %0.1
               
            %turn repump down
            setAnalogChannel(curtime,25,0.2); %repump 0.075

            %turn trap down
            %setAnalogChannel(curtime,26,0.3);
                
    
        elseif seqdata.atomtype==3 %Rb
            
%             
             
            %optimized by looking after evap in science cell (April 18,
            %2012)
            yshim_comp = 0.9; %0.9
            xshim_comp = 0.25; %0.1
            zshim_comp = 0.75; %0.2

            %optimize shims for compression (put cloud at the position of the mag
            %trap center)
            %turn on the Y (quantizing) shim 
            setAnalogChannel(calctime(curtime,-2),19,yshim_comp); %1.25
            %turn on the X (left/right) shim
            setAnalogChannel(calctime(curtime,-2),27,xshim_comp); %0.3 
            %turn on the Z (top/bottom) shim 
            setAnalogChannel(calctime(curtime,-2),28,zshim_comp); %0.2
            
            %digital trigger
            %DigitalPulse(calctime(curtime,0),12,0.1,1)

            %set detuning
            %detuning
            setAnalogChannel(calctime(curtime,0),34,6590+Rb_cMOT_detuning); 
            %FF
            setAnalogChannel(calctime(curtime,0),35,-0.1,1); %0.1
            
                     
            %turn repump down
            setAnalogChannel(curtime,2,0.2); %repump 0.075

            %turn trap down
            %setAnalogChannel(curtime,4,0.3);
            
            %setAnalogChannel(calctime(curtime,0),8,5); 
            
        end

       
        
        
        %Let there be 10ms of compression (5ms without bias + 5ms with bias)
        curtime=calctime(curtime,cMOT_time);
        
    
end

%% Turn off the MOT

if image_type~=4 
    %turn the MOT off
    %CATS
    setAnalogChannel(curtime,8,0); 
    %TTL
    setDigitalChannel(curtime,16,0); %1 is fast turn-off, 0 is not
end




%% Molasses 

%To fix: the quadrupole field is not turning off *completely* here

do_molasses = 0 && (~(image_type==4));

molasses_time = 20; %20
molasses_detuning = 50; %50

%digital trigger
%DigitalPulse(curtime,12,0.1,1);

if do_molasses
    
    %turn on the shims for optical pumping and/or molasses

    %set shims and detuning (atom dependent)
    if seqdata.atomtype==1 %K40
                    
        yshim_mol = 0; %0.5
        xshim_mol = 0.4; %0.1
        zshim_mol = 0.05; %0.2

        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %1.05 for molassess
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.25 for molasses
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.15 for molasses  
    
                 
        %turn down Trap power for molasses
        setAnalogChannel(calctime(curtime,0),26,0.7);
        
        %set Repump power (turn down for molasses)
       setAnalogChannel(calctime(curtime,0),25,0.24);
       setAnalogChannel(calctime(curtime,5),25,0.7);
        
        %set molasses detuning
        setAnalogChannel(calctime(curtime,0),34,756); %756
        %offset FF
         setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06
        
    elseif seqdata.atomtype==2
        
        yshim_mol = 0.2; 
        xshim_mol = 0.15;
        zshim_mol = 0.15;

        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %0.2 for molassess
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.05 for molasses
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.08 for molasses  
        
        setAnalogChannel(curtime,5,17.25); %29.5
        
        
        
    elseif seqdata.atomtype==3 %Rb
        
        %optimized by imaging a long molasses
        %optimized by evap April 18, 2012 (both methods were basically the
        %same)
        yshim_mol = 0.1; %0.3
        xshim_mol = 0.1; %0.1
        zshim_mol = 0.05; %0.05

        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,-1),19,yshim_mol); %1.05 for molassess
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,-1),27,xshim_mol); %0.25 for molasses
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,-1),28,zshim_mol); %0.15 for molasses  
        
       
       %set OP detuning 
        setAnalogChannel(calctime(curtime,0),34,6590+molasses_detuning);
        
         %turn trap down
        setAnalogChannel(curtime,4,0.7);

        %turn repump down
        %setAnalogChannel(curtime,2,0.28); %0.3
     
        
    end
             
    
   
  
    %do molasses for 5ms
    curtime = calctime(curtime,molasses_time); %5
    
    
else
    
    %need to do this so that the probe detuning is ok
    
     %set molasses detuning
%     setAnalogChannel(calctime(curtime,0),34,756); %756
%     %offset FF
%      setAnalogChannel(calctime(curtime,0),35,0.06,1); %0.06

end



%% Turn the trap light off
if image_type~=4 
    if do_molasses
        turn_off_beam(calctime(curtime,0),1);
    else
        %this is so that the trap light and the trap turn off simultaneously
        curtime = turn_off_beam(calctime(curtime,0),1);
        
    end
end


%digital trigger
%DigitalPulse(curtime,12,0.1,1);

%lag for trap shutter (1.7ms)
%curtime = calctime(curtime,1.7);


%% Optical Pumping

do_optical_pumping = 1 && (~(image_type==4));

%digital trigger
    DigitalPulse(calctime(curtime,0),12,0.1,1);

if do_optical_pumping == 1;
    curtime = optical_pumping(curtime,image_loc);
      
else
    %optical pumping seemed to make little difference (why?)
    %curtime = calctime(curtime,2.0);
end

%% Turn off the repump
if image_type~=4
    turn_off_beam(calctime(curtime,1.5),2); %a little delayed w.r.t trap
end

timeout = curtime;

end