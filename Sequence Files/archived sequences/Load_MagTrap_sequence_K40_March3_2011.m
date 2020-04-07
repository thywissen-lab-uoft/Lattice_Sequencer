%------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
function timeout = Load_MagTrap_sequence(timein)

curtime = timein;
global seqdata;

seqdata.numDDSsweeps = 0;

initialize_channels()

%% Make sure Coil 16 fast switch is open

    setAnalogChannel(calctime(curtime,0),31,6);

%% Switches

%It's preferable to add a switch here than comment out code!
image_type = 0; %0: absorption image, 1: recapture
image_loc = 1; %0: MOT cell, 1: science chamber
hor_transport_type = 1; %0: min jerk curves, 1: slow down in middle section curves, 2: none
ver_transport_type = 0; %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear

pre_recapture = 0; %do a recapture before imaging

mag_trap_MOT = 0; %special flag that takes a recapture image of the MOT
mag_trap_filter = 0; %0: no magnetic filtering, 1: magnetic filtering
pre_transport_mag_trap_filter = 0; %0: no magnetic filtering, 1: magnetic filtering, 2: double magnetic filtering
cube_mag_trap_filter = 0;
atom_dunk = 0;
Recap_before_atom_dunk = 0;
microwave_sweep = 1;

 
if atom_dunk 
    Recap_before_atom_dunk = 0;
end
    
if mag_trap_MOT
    hor_transport_type = 2;
    ver_transport_type = 2;
    image_type = 0;
    image_loc = 0;
    microwave_sweep = 0;

end

%% Take Flouresence image of MOT
%cam trigger
%DigitalPulse(curtime,1,1,1);

%% MOT Feed Forward 
%Increase the voltage on the supplies
    setAnalogChannel(calctime(curtime,10),18,10/6.6); 

%% Open Repump and OP shutter, Turn on transport to threshold values

%Open Repump Shutter
%setDigitalChannel(calctime(curtime,1000),3,1);

%Open OP Shutter
curtime=setDigitalChannel(calctime(curtime,1500),5,1);
%Open Probe Shutter
%curtime = setDigitalChannel(curtime,4,1);

%manually turn on the transport to threshold values
 %curtime = setAnalogChannel(calctime(curtime,10),7,0,2);
 %curtime = setAnalogChannel(calctime(curtime,10),9,0,2);
 %curtime = setAnalogChannel(calctime(curtime,10),10,0,2);
 %curtime = setAnalogChannel(calctime(curtime,10),11,0,2);
 %curtime = setAnalogChannel(calctime(curtime,10),12,0,2);
 %curtime = setAnalogChannel(calctime(curtime,10),13,0,2);
 
 %% Bright MOT (Take out dark spot)
 
   
%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

 
%% Compression


time_between_darkSPOT_and_cMOT = 0; %25

cMOT_time = 10; %10

%Jump Trap detuning closer to resonance to 7.2MHz
curtime = setAnalogChannel(calctime(curtime,time_between_darkSPOT_and_cMOT),5,20);%7.2MHz %this was at 3.2MHz!! %18

%turn repump and trap down
setAnalogChannel(curtime,25,0.075); %repump 0.075

%Ramp MOT Coil current to 33.5G/cm
%curtime = AnalogFunc(curtime,8,@(t,a)(0*20/a*t+13.5),10,10);%20/a*t+13.5
%AnalogFunc(calctime(curtime,0.0),8,@(t,a)(a+minimum_jerk(t,10,15-15)),10,15);

%Let there be 10ms of compression (5ms without bias + 5ms with bias)
curtime=calctime(curtime,cMOT_time);

%% Turn off the MOT

%turn the MOT off
% CATS
setAnalogChannel(curtime,8,0);
%TTL
setDigitalChannel(curtime,16,0); %1 is fast turn-off, 0 is not


%% Molasses (Maybe?)

%turn on the shims for optical pumping and/or molasses

%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,-1),19,1.2); %1.0 for molassess
%turn on the X (left/right) shim 
setAnalogChannel(calctime(curtime,-1),27,0.2); %0.30 for molasses
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,-1),28,0.5); %0.10 for molasses  

do_molasses = 1;

if do_molasses
    
    %change detuning
    setAnalogChannel(curtime,5,17.5);

    %turn repump down
    setAnalogChannel(curtime,25,0.15);
    
end

%turn the trap light off
%analog
%setAnalogChannel(curtime,3,0.0);
%TTL
if do_molasses
    curtime = setDigitalChannel(calctime(curtime,5),6,1); 
else
    setDigitalChannel(curtime,6,1);
end
%shutter
setDigitalChannel(curtime,2,0);

%turn repump back up
setAnalogChannel(curtime,25,0.55);

%% OPTICAL PUMPING

curtime = optical_pumping(curtime);

%curtime = calctime(curtime,2);


%% Load into Magnetic Trap


%optimize shims for loading into mag trap
%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,2),19,1.25); %1.25
%turn on the X (left/right) shim
setAnalogChannel(calctime(curtime,2),27,0.3); %0.3 
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,2),28,0.2); %0.2


curtime = Load_MagTrap_from_MOT(curtime);


%turn off shims
%turn on the Y (quantizing) shim 
setAnalogChannel(calctime(curtime,0),19,0.0); 
%turn on the X (left/right) shim
setAnalogChannel(calctime(curtime,0),27,0.0); 
%turn on the Z (top/bottom) shim 
setAnalogChannel(calctime(curtime,0),28,0.0); 

  
%% Pre-transport Mag Trap Filter
if pre_transport_mag_trap_filter == 1

    curtime = MagTrap_filter(curtime);
    %curtime = calctime(curtime,1700);

elseif  pre_transport_mag_trap_filter == 2
    
    curtime = MagTrap_filter(curtime);
    curtime = MagTrap_filter(curtime);
end



%% Transport 

if hor_transport_type == 0

    %---------------
    %In this transport scheme one defines a transport distance and time and
    %the acceleration and deceleration are the minimum jerk curves given
    %the constraints of this distance and time
    %--------------
    
    %Horizontal transport parameters
    hor_transport_distance = 10; %50
    hor_transport_time = 100; %800
    hor_wait_time = 10.0; %10

    %Cube wait time
    cube_wait_time = 200; %300

    %Vertical transport parameters
    ver_transport_distance = 0; 
    ver_transport_time = 10; %650
    ver_wait_time = 0; %100


    %for checking the number of atoms mag trapped out of MOT
    if mag_trap_MOT
        hor_transport_distance = 0; 
        hor_transport_time = 500; 
        hor_wait_time = 10.0; 
        ver_transport_distance = 0;
    end
        

    if hor_transport_distance<360;
        
        ver_transport_distance = 0; 
        ver_transport_time = 0; 
        ver_wait_time = 0;
        cube_wait_time = 0;
    
    end
    
    if hor_transport_distance==360 && ver_transport_distance>0;
        
        hor_wait_time = 0;
        
    end
    
    if hor_transport_distance>360;
        
        error('Horizontal distance too far')
        
    end
    
    if ver_transport_distance>174;
        
        error('Vertical distance too far')
        
    end
    
    %option to ramp down to vertical currents slowly in the cube
    ramp_in_cube = 0;

    if ~ramp_in_cube
    
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)),hor_transport_time,hor_transport_time,hor_transport_distance);
          if ver_transport_distance~=0
              curtime = AnalogFunc(calctime(curtime,cube_wait_time),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360),ver_transport_time,ver_transport_time,ver_transport_distance);
              
              %for long wait times (due to ADWIN issue)...
              curtime = long_wait(curtime,ver_wait_time,8,0);
                            
              %if we are imaging in the MOT cell we need to go back
              if image_loc == 0 
                curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance);
              end
          end
          
          if image_loc == 0
            curtime = AnalogFunc(calctime(curtime,hor_wait_time),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+hor_transport_distance),hor_transport_time,hor_transport_time,hor_transport_distance);
          end
          
    else
        
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)),hor_transport_time,hor_transport_time,hor_transport_distance);
          if ver_transport_distance~=0
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360),cube_wait_time,cube_wait_time,0.1);
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+0.1),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
              
              %for long wait times (due to ADWIN issue)...
              curtime = long_wait(curtime,ver_wait_time,8,0);
              
                        
              if image_loc==0
                  curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
                  curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+0.1),cube_wait_time,cube_wait_time,0.1);
              end
          end
          if image_loc==0
            curtime = AnalogFunc(calctime(curtime,hor_wait_time),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+hor_transport_distance),hor_transport_time,hor_transport_time,hor_transport_distance);
          end
    end
    
    
elseif hor_transport_type  == 1
    
    %---------------
    %In this transport scheme there are several different velocity "zones"
    %so that the atoms slow down before they enter the final cube as gently
    %as possible to reduce heating
    %--------------
    
    %Horizontal transport parameters
        %Distance to the second zone and time to get there
        D1 = 300; %300
        T1 = 1800; %1600
        %Distance to the third zone and time to get there
        Dm = 45; %45
        Tm =1000; %1000
        %Distance to the fourth zone and time to get there
        D2 = 15; %15
        T2 = 600; %600

        %Cube wait time
        cube_wait_time = 200; %300
        
        % %list
%  ver_transport_time_list=[400:200:1200 400:200:1200 400:200:1200];
% % 
% % %Create linear list
% index=seqdata.cycle;
% % 
% % %Create Randomized list
% % %index=seqdata.randcyclelist(seqdata.cycle);
% % 
%  ver_transport_time = ver_transport_time_list(index)
%  addOutputParam('resonance',ver_transport_time);

          
        %Type 0 Vertical transport parameters
        ver_transport_distance = 174; 
        ver_transport_time = 800.02; %650 %700
        ver_SC_rampdown_time = 300;
        ver_wait_time = 10; %100  
        
        %Type 1 Vertical transport parameters
        %Distance to the second zone and time to get there
        D1Vert = 80; 
        T1Vert = 150; 
        %Distance to the third zone and time to get there
        DmVert = 29; 
        TmVert = 50;
        %Distance to the fourth zone and time to get there
        D2Vert = 65; 
        T2Vert = 100; 

            
    blast_light = 0;
    
    cube_shim = 0;
    
  
    
    y_cube_shim_time = 0.1;
    %y_cube_shim_value = 7; % is 7.5 max
    x_cube_shim_time = cube_wait_time;
    x_cube_shim_value = 0;
    cube_shim_pulse_length = 20;
    
     
    
      curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,dm,tm,d2,t2)(for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)),T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);
      if ver_transport_distance~=0 || D1Vert + DmVert + D2Vert~=0
          
                              
          
          if cube_shim
             AnalogFunc(calctime(curtime,0),29,@(t,tt,dt)(minimum_jerk(t,tt,dt)),y_cube_shim_time,y_cube_shim_time,y_cube_shim_value);
             AnalogFunc(calctime(curtime,0),30,@(t,tt,dt)(minimum_jerk(t,tt,dt)),x_cube_shim_time,x_cube_shim_time,x_cube_shim_value);
             setAnalogChannel(calctime(curtime,cube_shim_pulse_length),29,0);
             setAnalogChannel(calctime(curtime,cube_shim_pulse_length),30,0);
          
          end
          
          if cube_mag_trap_filter
              setAnalogChannel(curtime,8,0);
              cube_MagTrap_filter(curtime,22,1);
              curtime = cube_MagTrap_filter(curtime,23,-1);
          end
          
           
          if ver_transport_type==0
         
          %travel 0.1mm above cube              
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360),cube_wait_time,cube_wait_time,0.1);
         
          %travel to 533.9mm, 0.1mm below middle of SC.
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+0.1),ver_transport_time,ver_transport_time,ver_transport_distance-0.2);
          
          %travel final 0.1mm into SC.
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+533.9),ver_SC_rampdown_time,ver_SC_rampdown_time,0.1);
        
          
          %for connect_spline_to_fit = 1 only!
          %curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+533.9),100,100,0.1);
         
          
          elseif ver_transport_type==1
          
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360),cube_wait_time,cube_wait_time,0.1);   
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,dm,tm,d2,t2)(for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)+360+0.1),T1Vert+TmVert+T2Vert,D1Vert-0.1,T1Vert,DmVert,TmVert,D2Vert,T2Vert);
     
          elseif ver_transport_type==3
          
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(dt/tt.*t+360),ver_transport_time,ver_transport_time,ver_transport_distance);
                      
          else
             
              %no vertical transport
              
          end
          
          %turn cube shims off after atoms are in the science chamber
          if image_loc==1
             setAnalogChannel(calctime(curtime,0),29,0);
             setAnalogChannel(calctime(curtime,0),30,0);
          end
          
            if blast_light
                %blast with light
                setAnalogChannel(curtime,26,0.1); %turn trap AOM intensity to full

                %TTL
                setDigitalChannel(curtime,6,0);
                %Shutters
                setDigitalChannel(calctime(curtime,-10),2,1);
                setAnalogChannel(calctime(curtime,-10),5,15.0); 

                %turn off

                %TTL
                curtime = setDigitalChannel(calctime(curtime,5),6,1);
                %Shutters
                setDigitalChannel(calctime(curtime,10),2,0);

            end
          
              
           %if we are imaging in the MOT cell we need to go back
           if image_loc==0
              
              if ver_transport_type==0
               
              curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+0.1),cube_wait_time,cube_wait_time,0.1);
                                      
              elseif ver_transport_type==1
                  
              %need to turn off last horizontal channel (#17) and first
              %vertical (ch# 22) or else they spike to some value when
              %atoms return...don't understand why yet.
              setAnalogChannel(curtime, 17,0);
              setAnalogChannel(curtime, 22,0);
              
              curtime = AnalogFunc(curtime,0,@(t,d1,t1,dm,tm,d2,t2)(back_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)+360+0.1),T1Vert+TmVert+T2Vert,D1Vert-0.1,T1Vert,DmVert,TmVert,D2Vert,T2Vert);
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+0.1),cube_wait_time,cube_wait_time,0.1);    
              
              elseif ver_transport_type==3
                  
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-dt/tt.*t+360+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance);
            
              else
               %no vertical transport
              end
              
              
             if cube_shim
             AnalogFunc(calctime(curtime,-cube_wait_time),29,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+y_cube_shim_value),y_cube_shim_time,y_cube_shim_time,y_cube_shim_value);
             AnalogFunc(calctime(curtime,-cube_wait_time),30,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+x_cube_shim_value),x_cube_shim_time,x_cube_shim_time,x_cube_shim_value);
             end
           
           end
      end
      if image_loc==0
        curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,dm,tm,d2,t2)(back_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)),T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);
      end

elseif hor_transport_type == 2
    %No transport
else
    error('Undefined transport type');
end

%% Recapture MOT after transport and before Magnetic trapping/Atom Dunk

if Recap_before_atom_dunk 

%turn off QT trap
    %Science chamber Quadrupole trap
   curtime = setAnalogChannel(curtime,1,0,1);%MOT channel = 8, QT channel = 21 (b), 1 (t)
   curtime = setAnalogChannel(curtime,3,0,1);%kitten
   
   %MOT
   setAnalogChannel(curtime,8,0);
   
   %MOT/QCoil TTL
   curtime = setDigitalChannel(curtime,16,1);    

%Do a recapture MOT after 1ms tof
    %parameters
     image_loc = 1;
     first_recap_detuning = 20.2;  
     first_recap_trap_power = 0.7;
     first_recap_repump_power = 0.55;
     first_recap_load_time = 25; %20

     %call load_MOT
    curtime = Load_MOT(calctime(curtime,1),first_recap_detuning,image_loc);
    
    %control recap_trap_power
    curtime = setAnalogChannel(curtime,26,first_recap_trap_power);
    %control recap_repump_power
    curtime = setAnalogChannel(curtime,25,first_recap_repump_power);
         
%Turn off recap MOT after recap_load_time
    %Wait recap_load time
    curtime = calctime(curtime,first_recap_load_time);    

    %turn the trap light off
        %analog
        setAnalogChannel(curtime,26,0.0);
        %TTL
        setDigitalChannel(curtime,6,1);
        %shutter
        setDigitalChannel(curtime,2,0);

        %turn the repump light off
        %analog
        setAnalogChannel(curtime,25,0);
        %TTL
        setDigitalChannel(curtime,7,1);
        %shutter
        curtime = setDigitalChannel(curtime,3,0);

%OP (can't do it cause we have no OP light in SC)
    
%Load back into QT
    %Wait 1ms tof
    curtime = calctime(curtime,1);    

    %turn on QT to 174mm value
    QT_wait_time_after_load = 50;
    
    curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+174),QT_wait_time_after_load,QT_wait_time_after_load,0.001);
 
else
    
end

%% Magnetic Filtering and Atom Dunk

if mag_trap_filter

    curtime = MagTrap_filter(curtime);

end


%atom_dunk_distance = 174;
atom_dunk_blast_light = 0;
atom_dunk_method = 0;
atom_dunk_wait_time = 100;

if atom_dunk
    
    if ver_transport_distance ~= 174
        error('Can only dunk if we go all the way to the end of the vertical');
    end
    
    if atom_dunk_distance < 0 ||  atom_dunk_distance > 174
        error('Invalid Atom Dunk Distance');
    end
    
    %down
    if atom_dunk_method == 0
        curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+174),ver_transport_time,ver_transport_time,atom_dunk_distance-0.1);
    else
        curtime = AnalogFunc(curtime,0,@(t)(360+174-t/500*100),500);
        curtime = AnalogFunc(curtime,0,@(t)(360+174-100-t/150*50),150);
%         curtime = AnalogFunc(curtime,0,@(t)(360+174-35-t/200*20),200);
    end
    
    if atom_dunk_blast_light
        %blast with light
        setAnalogChannel(curtime,26,0.02); %turn trap AOM intensity to full

        %TTL
        setDigitalChannel(curtime,6,0);
        %Shutters
        setDigitalChannel(calctime(curtime,-10),2,1);
        setAnalogChannel(calctime(curtime,-10),5,15.0); 

        %turn off
        
        %TTL
        curtime = setDigitalChannel(calctime(curtime,5),6,1);
        %Shutters
        setDigitalChannel(calctime(curtime,10),2,0);
        
    end
    
    %back up
    if atom_dunk_method == 0
        curtime = AnalogFunc(calctime(curtime,atom_dunk_wait_time),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+(174-atom_dunk_distance)+0.1),ver_transport_time,ver_transport_time,atom_dunk_distance-0.1);
    else
        curtime = AnalogFunc(curtime,0,@(t)(360+174-150+t/150*50),150);
        curtime = AnalogFunc(curtime,0,@(t)(360+174-100+t/500*100),500);
        %         curtime = AnalogFunc(curtime,0,@(t)(360+174-25+t/200*25),200);
    end
end

%% Turn off Vertical Coils 12A-14

setAnalogChannel(calctime(curtime,0),22,0,1);
setAnalogChannel(calctime(curtime,0),23,0,1);
setAnalogChannel(calctime(curtime,0),24,0,1);
setAnalogChannel(calctime(curtime,0),20,0,1);
%% Ramp up QP gradient for evaporation
%***********************comment below for MOT pic*******************

% % %list
% QP_value_list=[-5:5:20 -5:5:20 -5:5:20 -5:5:20 ];
% % 
% % %Create linear list
% index=seqdata.cycle;
% % 
% % %Create Randomized list
% % %index=seqdata.randcyclelist(seqdata.cycle);
% % 
% QP_value = QP_value_list(index)
%  addOutputParam('resonance',QP_value);
 
   
QP_ramp_time = 500;
QP_value = 10;

%ramp up feed forward depending on gradient
    setAnalogChannel(calctime(curtime,10),18,0.18 + 1/6.6 + (QP_value*10+100)*.00498); 

%ramp coil 15
AnalogFunc(curtime,21,@(t,tt,dt)(minimum_jerk(t,tt,dt)+10.9),QP_ramp_time,QP_ramp_time,QP_value);

%ramp coil 16
curtime = AnalogFunc(curtime,1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+10.9),QP_ramp_time,QP_ramp_time,QP_value);

%% Ramp on Plug

plugpwr = 350E-3;
% 
%ramp coil 15
% AnalogFunc(curtime,21,@(t,tt)(10.9-8*t/tt),1000,1000);
% 
% %ramp coil 16
% AnalogFunc(curtime,1,@(t,tt)(10.9-8*t/tt),1000,1000);
% 
curtime = setDigitalChannel(curtime,10,1);
curtime = AnalogFunc(calctime(curtime,1),33,@(t,tt,pwr)(pwr*t/tt),100,100,plugpwr*4);
%  

%% Rf Sweep

% Rf_sweep = 0;
% 
% if Rf_sweep 
%    
%     DigitalPulse(curtime,20,10,1);
%     curtime=DigitalPulse(curtime,19,4000,1);
%         
% else
%    
%     curtime=calctime(curtime,4000);
%     
% end

%% Microwave sweep

microwave_sweep = 1;

if microwave_sweep

    %pulse microwaves
    pulse_microwaves = 1;

    MHz = 1E6;
    GHz = 1E9;

    % %list
    % hold_time_list=[1:2000:12001 1:2000:12001 1:2000:12001];
    % % 
    % % %Create linear list
    % index=seqdata.cycle;
    % % 
    % % %Create Randomized list
    % % %index=seqdata.randcyclelist(seqdata.cycle);
    % % 
    % hold_time = hold_time_list(index)
    %  addOutputParam('resonance',hold_time);


    hold_time = 20; 

    %sweep parameters
    start_sweep_freq = 1.16*GHz;
    end_sweep_freq = 1.175*GHz;
    sweep_time = 10000;

    % therm_time = 1000;
    % therm_offset = 1*MHz;

    %turn DDS (Rf) on:
    curtime = setDigitalChannel(calctime(curtime,0),13,pulse_microwaves);
    %turn Microwaves on:
    curtime = setDigitalChannel(calctime(curtime,0),17,pulse_microwaves);


    %sweep 1 
    curtime = DDS_sweep(calctime(curtime,0),1,start_sweep_freq,end_sweep_freq,sweep_time);

    % %turn DDS (Rf) off:
    % curtime = setDigitalChannel(calctime(curtime,0),13,0);
    % %turn Microwaves off:
    % curtime = setDigitalChannel(calctime(curtime,0),17,0);
    % 
    % %turn DDS (Rf) on:
    % curtime =
    % setDigitalChannel(calctime(curtime,therm_time),13,pulse_microwaves);
    % %turn Microwaves on:
    % curtime = setDigitalChannel(calctime(curtime,0),17,pulse_microwaves);
    % 
    % %sweep 2 
    % curtime = DDS_sweep(calctime(curtime,0),1,start_sweep_freq+therm_offset,end_sweep_freq+therm_offset,1);


    %turn DDS (Rf) off:
    curtime = setDigitalChannel(calctime(curtime,0),13,0);
    %turn Microwaves off:
    curtime = setDigitalChannel(calctime(curtime,0),17,0);



    curtime = calctime(curtime,hold_time);
else
    curtime = calctime(curtime,10000);    
end

%************************comment above for MOT pic ***********************

%turn plug off
setAnalogChannel(calctime(curtime,5),33,0);
setDigitalChannel(calctime(curtime,5),10,0);


%to do plug stark shift
% plugpwr = 300E-3;
% 
% curtime = setDigitalChannel(curtime,10,1);
% curtime = AnalogFunc(calctime(curtime,2),33,@(t,tt,pwr)(pwr*t/tt),5,5,plugpwr*4);
% 
% curtime = calctime(curtime,2);
% 
% setAnalogChannel(calctime(curtime,5),33,0);
% setDigitalChannel(calctime(curtime,5),10,0);


%% Atoms are now just waiting in the magnetic trap.  

%ramp down coils

% %ramp coil 15
% AnalogFunc(curtime,21,@(t,tt,dt)(minimum_jerk(t,tt,dt)+10.2114+QP_value),QP_ramp_time,QP_ramp_time,-QP_value);
% 
% %ramp coil 16
% curtime = AnalogFunc(curtime,1,@(t,tt,dt)(minimum_jerk(t,tt,dt)+10.14575+QP_value),QP_ramp_time,QP_ramp_time,-QP_value);

%turn ON coil 14 a little to close switch in order to prevent an induced
%current from the fast QP switch-off
   setAnalogChannel(calctime(curtime,0),20,0.15,1);
   setAnalogChannel(calctime(curtime,1.5),20,0.0,1);

   
%turn the Magnetic Trap off
   
   %set all transport coils to zero
   for i = [7:17 22:24] 
    setAnalogChannel(calctime(curtime,0),i,0,1);
   end

   
   %digital trigger
          DigitalPulse(calctime(curtime,0),12,10,1);
   
   %Science chamber Quadrupole trap
   setAnalogChannel(calctime(curtime,0),21,0,1)
   curtime = setAnalogChannel(calctime(curtime,0),1,0,1);%MOT channel = 8, QT channel = 21 (b), 1 (t)
   
   curtime = setAnalogChannel(curtime,3,0,1);%kitten
   
   %MOT
   setAnalogChannel(curtime,8,0);
   
   %MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
   setAnalogChannel(calctime(curtime,0),31,0);
   curtime = setDigitalChannel(curtime,16,1);    
   
   %Turn on coil 16 switch so that current can flow through 16 in order to
   %do a recapture
   setAnalogChannel(calctime(curtime,8),31,6);

if pre_recapture
    
    prerecap_opt_pump = 0;
    prerecap_mag_trap = 0;
    prerecap_atom_dunk = 0;
    
   %wait 500 us and turn the MOT back on to 7.2MHz detuning
    curtime = Load_MOT(calctime(curtime,1),20.2,1);
        
    curtime = calctime(curtime,50); %50
    
    %turn down the repump at the end (CMOT?)
    setAnalogChannel(calctime(curtime,-10),25,0.2);
    
    %turn the mag trap off
    curtime = setDigitalChannel(curtime,16,1);
    
       
    %turn the trap light off
    %analog
    setAnalogChannel(curtime,3,0.0);
    %TTL
    setDigitalChannel(curtime,6,1);
    %shutter
    setDigitalChannel(curtime,2,0);

    %turn the repump light off
    %analog
    setAnalogChannel(curtime,1,0);
    %TTL
    setDigitalChannel(curtime,7,1);
    %shutter
    curtime = setDigitalChannel(curtime,3,0);
    
    
    
      
    if prerecap_opt_pump
        
        %turn the Y (quantizing) shim on after magnetic trapping
        setAnalogChannel(calctime(curtime,0),19,3.5); %had this at 3.5, timing at 1 for abs from MOT
        
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,0),27,0.0); 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,0),28,0.0);
        
        %set optical pumping detuning
        setAnalogChannel(calctime(curtime,-2),5,26); 
            
        %Open OP Shutter
        setDigitalChannel(calctime(curtime,-10),5,1);
        
        %Open Repump Shutter
        setDigitalChannel(calctime(curtime,-5),5,1);

        %Prepare OP light
        %analog
        setAnalogChannel(calctime(curtime,-10),2,0.12); %0.08
        %TTL
        setDigitalChannel(calctime(curtime,-10),9,1);
        
        %Turn on Repump light
        %shutter
        setDigitalChannel(calctime(curtime,-10),3,1);
        

        %300us OP pulse after 1.5ms for Shim coil to turn on
        %TTL
        DigitalPulse(calctime(curtime,0.8),9,0.3,0); %1.5
        %Repump Pulse
        DigitalPulse(calctime(curtime,0.8),7,0.3,0);

        %turn the OP light off
        %analog
        setAnalogChannel(calctime(curtime,5),2,0);
        %TTL
        setDigitalChannel(calctime(curtime,5),9,1);
        %shutter
        setDigitalChannel(calctime(curtime,5),5,0);
        
        %turn the Y (quantizing) shim off after absorption imaging
        curtime = setAnalogChannel(calctime(curtime,1.2),19,0.00); %1.9
        
    end
    
    if prerecap_mag_trap
        
        %optimize loading back into the trap
        
        %turn on the Y (quantizing) shim 
        setAnalogChannel(calctime(curtime,0),19,0.5); 
        %turn on the X (left/right) shim 
        setAnalogChannel(calctime(curtime,0),27,0.75); 
        %turn on the Z (top/bottom) shim 
        setAnalogChannel(calctime(curtime,0),28,0.0);
        
        curtime = calctime(curtime,0.5);
        
        %turn off the kitten and channel 15
        setAnalogChannel(curtime,21,1,1);
        setAnalogChannel(curtime,3,0,1);
        
        %turn ttl back on
        curtime = setDigitalChannel(curtime,16,0); 
        
        prerecap_ramptime1 = 3;
        prerecap_initialcurrent = 12.4;
        prerecap_holdtime1 = 100;
        
        %ramp up channel 16
        AnalogFunc(calctime(curtime,0.0),1,@(t,a)(a+minimum_jerk(t,prerecap_ramptime1,prerecap_initialcurrent)),prerecap_ramptime1,0);
        setAnalogChannel(calctime(curtime,0.0+prerecap_ramptime1),1,prerecap_initialcurrent);
    
        %hold
        curtime = calctime(curtime,prerecap_holdtime1);
        
        if prerecap_atom_dunk
            
            %down
            curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+174),ver_transport_time,ver_transport_time,174-0.1);
            
            %back up
            curtime = AnalogFunc(calctime(curtime,100),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+0.1),ver_transport_time,ver_transport_time,174-0.1);

        end
        
        %turn off
        setDigitalChannel(curtime,16,1); 
        setAnalogChannel(curtime,1,0,1);
            
        
    end
        
end

% curtime = setAnalogChannel(calctime(curtime,0),33,0);
% setDigitalChannel(calctime(curtime,0),10,0);


if image_type == 0 % Absorption Image
    
   
    %% Pre-Absorption Shutter Preperation
    %Open Probe Shutter
    setDigitalChannel(calctime(curtime,-5),4,1);
    %Open Repump Shutter
    setDigitalChannel(calctime(curtime,-5),5,1);  
    
    
    %% Turn on quantizing field

    
    %turn the Y (quantizing) shim on after magnetic trapping
    if image_loc == 0;
    setAnalogChannel(calctime(curtime,0),19,3.5); %had this at 3.5, timing at 1 for abs from MOT
    elseif image_loc == 1;
    setAnalogChannel(calctime(curtime,0),19,5);
    end
    
    
    %% Absorption 

          
    %call absorption function
    curtime = absorption_image(calctime(curtime,0.0)); %had this at 3
    
    %curtime = fluor_image(calctime(curtime,0.0)); %had this at 3
    
    

    %% Turn off quantizing field

    %turn the Y (quantizing) shim off after absorption imaging
    curtime = setAnalogChannel(calctime(curtime,0),19,0.00);
    
    %% Post-absorption shutter preperation

    %Close Probe Shutter
    curtime = setDigitalChannel(curtime,4,0);
    %Close Repump Shutter
    curtime = setDigitalChannel(curtime,5,0);

elseif image_type == 1 %Recapture

    %Exposure Time should be 500us
    
%     tof_list=[1:5:31];
% 
% %Create linear list
% index=seqdata.cycle;
% 
% %Create Randomized list
% %index=seqdata.randcyclelist(seqdata.cycle);
% 
% tof = tof_list(index)
% addOutputParam('resonance',tof);
%     
    if image_loc == 0
        recap_detuning = 7.2; %7.2 for MOT
        recap_trap_power = 0.12;
        recap_repump_power = 0.55;
        recap_load_time = 100;
    elseif image_loc == 1
        recap_detuning = 15;  
        recap_trap_power = 0.7;
        recap_repump_power = 0.55;
        recap_load_time = 0.0;
    else 
        error('invalid recapture location')
    end
    
    tof = -9.5;
      
    %Create Output data
    %addOutputParam('Time Of Flight',tof);

    %wait 500 us and turn the MOT back on to 7.2MHz detuning
    %curtime = Load_MOT(calctime(curtime,tof),recap_detuning,image_loc);
    
    %TTL
    curtime = setDigitalChannel(calctime(curtime,recap_load_time),6,0);%TTL signal 0 = light, 1 = no light
    setDigitalChannel(curtime,7,0);
    %Shutters
    setDigitalChannel(calctime(curtime,-2),2,1);
    setDigitalChannel(calctime(curtime,-2),3,1);

    %set frequency
    setAnalogChannel(calctime(curtime,-5),5,recap_detuning); 
    
    %control recap_trap_power
    curtime = setAnalogChannel(curtime,26,recap_trap_power);
    %control recap_repump_power
    curtime = setAnalogChannel(curtime,25,recap_repump_power);
    
    %cam trigger after 1s load
    DigitalPulse(calctime(curtime,0.1),1,1,1);

    curtime = calctime(curtime,1000);
    
    %turn the trap light off
        %analog
        setAnalogChannel(curtime,26,0.0);
        %TTL
        setDigitalChannel(curtime,6,1);
        %shutter
        setDigitalChannel(curtime,2,0);

        %turn the repump light off
        %analog
        setAnalogChannel(curtime,25,0);
        %TTL
        setDigitalChannel(curtime,7,1);
        %shutter
        curtime = setDigitalChannel(curtime,3,0);

    %Load_MOT (1s later)
    curtime = Load_MOT(calctime(curtime,500),recap_detuning,image_loc);
    
    %control recap_trap_power
    curtime = setAnalogChannel(curtime,26,recap_trap_power);
    %control recap_repump_power
    curtime = setAnalogChannel(curtime,25,recap_repump_power);

    %cam trigger after 1s load
    curtime = DigitalPulse(calctime(curtime,recap_load_time),1,5,1);

else
    error('Undefined imaging type');
end

%% Load MOT


MOT_detuning = 38;

%call Load_MOT function
curtime = Load_MOT(curtime,MOT_detuning);

%% Put in Dark Spot

%curtime = DigitalPulse(calctime(curtime,0),15,10,1);

%% Close Coil 16 fast switch

    setAnalogChannel(calctime(curtime,0),31,0);

%% Timeout

timeout = curtime;


end