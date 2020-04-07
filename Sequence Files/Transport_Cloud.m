%------
%Author: David + Dylan
%Created: March 2011
%Summary: Transports the cloud
%------
function timeout = Transport_Cloud(timein,hor_transport_type,ver_transport_type, image_loc)


curtime = timein;
global seqdata;

horiz_length = 365;
vert_length = 174;

%0: min jerk curves, 1: slow down in middle section curves, 2: none, 3:
%linear, 4: triple min jerk

if hor_transport_type == 0
    
    %---------------
    %In this transport scheme one defines a transport distance and time and
    %the acceleration and deceleration are the minimum jerk curves given
    %the constraints of this distance and time
    %--------------
    
   
%    %list
%   hor_transport_distance_list=[0:10:300];
%   %Create linear list
%    index=seqdata.cycle;
%  
%  %Create Randomized list
%    index=seqdata.randcyclelist(seqdata.cycle);
% %  
%    hor_transport_distance = hor_transport_distance_list(index);
%    addOutputParam('hor_transport_distance',hor_transport_distance); 
    %transport_distance_list = 250:10:330;    

    %Horizontal transport parameters
    hor_transport_distance =  0; %50
    hor_transport_time = 200; %800
    hor_wait_time = 10; %10
    
    
    
  
    %Cube wait time
    cube_wait_time = 0; %300

    %Vertical transport parameters
    ver_transport_distance = 170; %60
    ver_transport_time = 1500; %650
    ver_wait_time = 0; %100


    %for checking the number of atoms mag trapped out of MOT
%     if mag_trap_MOT
%         hor_transport_distance = 0; 
%         hor_transport_time = 500; 
%         hor_wait_time = 10.0; 
%         ver_transport_distance = 0;
%     end
        

    if hor_transport_distance<horiz_length;
        
        ver_transport_distance = 0; 
        ver_transport_time = 0; 
        ver_wait_time = 0;
        cube_wait_time = 0;
    
    end
    
    if hor_transport_distance==horiz_length && ver_transport_distance>0
        
        hor_wait_time = 0;
        
    end
    
    if hor_transport_distance>horiz_length;
        
        error('Horizontal distance too far')
        
    end
    
    if ver_transport_distance>vert_length;
        
        error('Vertical distance too far')
        
    end
    
    %option to ramp down to vertical currents slowly in the cube
    ramp_in_cube = 0;

    if ~ramp_in_cube
    
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)),hor_transport_time,hor_transport_time,hor_transport_distance);
          if ver_transport_distance~=0
curtime =       AnalogFunc(calctime(curtime,cube_wait_time),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length),ver_transport_time,ver_transport_time,ver_transport_distance);
              
              %for long wait times (due to ADWIN issue)...
curtime =       long_wait(curtime,ver_wait_time,8,0);
              
              %turn on vertical probe beam
 %              turn_on_beam(curtime, 4, 0.2);
  %             curtime = calctime(curtime,500);
  %             turn_off_beam(curtime, 4);
              
              %if we are imaging in the MOT cell we need to go back
              if image_loc == 0 
curtime =       AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance);
              end
          else
              %curtime = calctime(curtime,hor_wait_time);
          end
          
          
          if image_loc == 0
curtime =       AnalogFunc(calctime(curtime,hor_wait_time),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+hor_transport_distance),hor_transport_time,hor_transport_time,hor_transport_distance);
          end
          
    else
        
          curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)),hor_transport_time,hor_transport_time,hor_transport_distance);
          if ver_transport_distance~=0
curtime =       AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length),cube_wait_time,cube_wait_time,0.1);
curtime =       AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length+0.1),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
              
              %for long wait times (due to ADWIN issue)...
curtime =       long_wait(curtime,ver_wait_time,8,0);
              
                        
              if image_loc==0
curtime =           AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
curtime =           AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+0.1),cube_wait_time,cube_wait_time,0.1);
              end
          end
          
          
          if image_loc==0
curtime =       AnalogFunc(calctime(curtime,hor_wait_time),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+hor_transport_distance),hor_transport_time,hor_transport_time,hor_transport_distance);
          end
    end
    
    
elseif hor_transport_type  == 1
    
    %---------------
    %In this transport scheme there are several different velocity "zones"
    %so that the atoms slow down before they enter the final cube as gently
    %as possible to reduce heating
    %--------------
    
     
    %  %list
    % T2_time_list=[400:50:800];
    % % 
    % % %Create linear list
    % %index=seqdata.cycle;
    % % 
    % % %Create Randomized list
    % index=seqdata.randcyclelist(seqdata.cycle);
    % % 
    % T2_time = T2_time_list(index)
    % addOutputParam('T2_time', T2_time);

    time_scaling = 1.0;   

    %Horizontal transport parameters
        %Distance to the second zone and time to get there
        D1 = 300; %300
        T1 = 1800*time_scaling; %1800
        %Distance to the third zone and time to get there
        Dm = 45; %45
        Tm =1000*time_scaling; %1000
        %Distance to the fourth zone and time to get there
        D2 = 20; %15
        T2 = 500*time_scaling; %600

        %Cube wait time
        cube_wait_time = 200; %200
%         
        
       
               
        %Type 0 Vertical transport parameters
        ver_transport_distance = 174; %174 is all the way
        ver_transport_time = 3000; %650 %700
        ver_SC_rampdown_time = 300; %300
       ver_wait_time = 0; %100  
       
        %ver_transport_distance2 = 40; %174 is all the way
        %ver_transport_time2 = 2301; %650 %700
     
        
        %Type 1 Vertical transport parameters
        %Distance to the second zone and time to get there
        D1Vert = 60; 
        T1Vert = 1200; 
        %Distance to the third zone and time to get there
        DmVert = 80; 
        TmVert = 800;
        %Distance to the fourth zone and time to get there
        D2Vert = 34; 
        T2Vert = 500; 

                 
        %Type 3 vert transport
        %rev 45 master list
            %MASTER LIST vert_lin_trans_distances = [0 20  40  60  80  100 120 140 151 154 160 173.9 174];
   %MASTER LIST vert_lin_trans_times = [450 250 450 800 450 250 500 200 200 500 500 300]; %300 100
                vert_lin_trans_times = [450 250 450 800 450 250 500 200 150 500 500 300];
            vert_lin_trans_distances = [0 20  40  60  80  100 120 140 151 154 160 173.9 174];
            %vert_lin_trans_distances = [0 20  40  60  80  100 120 140 156 157 160 173.9 174];
       
        %rev 48 master list (May 8, 2012)
%                 vert_lin_trans_times = [450 250 450 800 450 250 500 200 200 500 500 300];
%             vert_lin_trans_distances = [0 20  40  60  80  100 120 140 149 152 160 173.9 174];
            
            
            %for old position of top QP
        
%vert_lin_trans_distances = [0 20  40  60  80  100 120 145 148 160 173.9 174]; %this always needs to start with 0
       
        %for low QP currents in raise QP position
        %vert_lin_trans_distances = [0 20  40  60  80  100 120 145 148 160 169];
        
        
        %trying to optimize raised position of top QP
%         vert_lin_trans_times =       [450 250 450 800 450 250 500 200 150 300 200 300]; %300 100
%         vert_lin_trans_distances = [0  20  40  60  80  100 120 140 156 157 163 173.9 174];
        
%         vert_lin_trans_times =       [5300]; %300 100
%         vert_lin_trans_distances = [0  174];
                
        %for old position of top QP
        %vert_lin_trans_times =       [450 250 450 800 450 250 500 15 500 500 300];
        
        %for low QP currents in raise QP position
        %vert_lin_trans_times =       [450 250 450 800 450 250 500 15 500 700];
        
                
        %Type 4 vert transport
                
         Dtriple1 = 60;
         Ttriple1 = 1200;
         Dtriple2 = 40;
         Ttriple2 = 800;
         Dtriple3 = 74;
         Ttriple3 = 1200;
        
          
         

        percent_trans = 1;
        dist_temp = vert_lin_trans_distances;
        time_temp = vert_lin_trans_times;
        
        vert_lin_trans_distances = [0];
        vert_lin_trans_times = [];
        
        for ii = 2:length(dist_temp)
            
            if percent_trans==0
                break;
            end
            
            if dist_temp(ii) < (percent_trans*174)
                vert_lin_trans_distances(ii) = dist_temp(ii);
                vert_lin_trans_times(ii-1) = time_temp(ii-1);
            else
                vert_lin_trans_distances(ii) = (percent_trans*174);
                vert_lin_trans_times(ii-1) = ((percent_trans*174)-dist_temp(ii-1))*time_temp(ii-1)/(dist_temp(ii)-dist_temp(ii-1));
                break;
            end
        end
        
    cube_shim = 0;
    
  
    
    y_cube_shim_time = 0.1;
    %y_cube_shim_value = 7; % is 7.5 max
    x_cube_shim_time = cube_wait_time;
    x_cube_shim_value = 0;
    cube_shim_pulse_length = 20;
    
     
    
curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,dm,tm,d2,t2)(for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)),T1+Tm+T2,D1,T1,Dm,Tm,D2,T2);
    
    if (ver_transport_distance~=0 && ver_transport_type==0) || ...
            ((D1Vert + DmVert + D2Vert)~=0 && ver_transport_type==1) || ...
            (length(vert_lin_trans_distances)>1 && ver_transport_type==3)||...
            ((Dtriple1+Dtriple1+Dtriple1)~=0 && ver_transport_type==4)
          
                              
          
          if cube_shim
             AnalogFunc(calctime(curtime,0),29,@(t,tt,dt)(minimum_jerk(t,tt,dt)),y_cube_shim_time,y_cube_shim_time,y_cube_shim_value);
             AnalogFunc(calctime(curtime,0),30,@(t,tt,dt)(minimum_jerk(t,tt,dt)),x_cube_shim_time,x_cube_shim_time,x_cube_shim_value);
             setAnalogChannel(calctime(curtime,cube_shim_pulse_length),29,0);
             setAnalogChannel(calctime(curtime,cube_shim_pulse_length),30,0);
          
          end
          
          
           
          if ver_transport_type==0
         
              if ver_transport_distance < 0.2
                  error('Vertical transport distance must be greater than 0.2')
              end
              
              disp(ver_wait_time);
              
              %travel 0.1mm above cube              
curtime =     AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length),cube_wait_time,cube_wait_time,0.1);

              %travel to 533.9mm, 0.1mm below middle of SC.
curtime =     AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length+0.1),ver_transport_time,ver_transport_time,ver_transport_distance-0.2);
              
%                %second min jerk stack.
%               curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+360+ver_transport_distance),ver_transport_time2,ver_transport_time2,ver_transport_distance2);

              if ver_transport_distance==174 %all the way to the science cell
                  %travel final 0.1mm into SC.
curtime =         AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+538.9),ver_SC_rampdown_time,ver_SC_rampdown_time,0.1);
              end

              %for connect_spline_to_fit = 1 only!
              %curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+533.9),100,100,0.1);
         
          
          elseif ver_transport_type==1
          
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(minimum_jerk(t,tt,dt)+horiz_length),cube_wait_time,cube_wait_time,0.1);   
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,dm,tm,d2,t2)(for_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)+horiz_length+0.1),T1Vert+TmVert+T2Vert,D1Vert-0.1,T1Vert,DmVert,TmVert,D2Vert,T2Vert);
     
              %digital trigger @ 8400
            DigitalPulse(calctime(curtime,0),12,10,1);
              
          elseif ver_transport_type==3
          
              vert_lin_total_time = zeros(size(vert_lin_trans_distances));
              for ii = 2:length(vert_lin_trans_distances)
                vert_lin_total_time(ii) = vert_lin_total_time(ii-1) + vert_lin_trans_times(ii-1);
              end
              
              %vert_pp = interp1(vert_lin_total_time,vert_lin_trans_distances+horiz_length,'linear','pp');
              
              vert_pp = pchip(vert_lin_total_time,vert_lin_trans_distances+horiz_length);
              
              
%               for ii = 2:length(vert_lin_trans_distances)
%                 curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,t1,t2)((t2-t1)/tt.*t+t1+horiz_length),vert_lin_trans_times(ii-1),vert_lin_trans_times(ii-1),vert_lin_trans_distances(ii-1),vert_lin_trans_distances(ii));
%               end
              DigitalPulse(curtime,12,100,1);
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,aa)(ppval(aa,t)),vert_lin_total_time(end),vert_lin_total_time(end),vert_pp);
              
          
          elseif ver_transport_type==4
             
              curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,d2,t2,d3,t3)(for_triple_minimum_jerk(t,d1,t1,d2,t2,d3,t3)+horiz_length),Ttriple1+Ttriple2+Ttriple3,Dtriple1,Ttriple1,Dtriple2,Ttriple2,Dtriple3,Ttriple3);
              
          else
             
              %no vertical transport
              
          end
          
          curtime = calctime(curtime,ver_wait_time);
          
            Rf_sweep = 0;

            Rf_pulse_time = 0; %100

            if Rf_sweep 

                DigitalPulse(curtime,20,20,1);
                curtime=DigitalPulse(curtime,19,Rf_pulse_time,1);

            else

                curtime=calctime(curtime,Rf_pulse_time);

            end
          
          %turn cube shims off after atoms are in the science chamber
%           if image_loc==1
%              setAnalogChannel(calctime(curtime,0),29,0);
%              setAnalogChannel(calctime(curtime,0),30,0);
%           end
          
                          
           %if we are imaging in the MOT cell we need to go back
           if image_loc==0
              
              if ver_transport_type==0
                  %curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+360+ver_transport_distance+ver_transport_distance2),ver_transport_time2,ver_transport_time2,ver_transport_distance2);
                  curtime = AnalogFunc(curtime,0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+ver_transport_distance),ver_transport_time,ver_transport_time,ver_transport_distance-0.1);
                  curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+0.1),cube_wait_time,cube_wait_time,0.1);
                               
              elseif ver_transport_type==1
                  
                  %need to turn off last horizontal channel (#17) and first
                  %vertical (ch# 22) or else they spike to some value when
                  %atoms return...don't understand why yet.
                  setAnalogChannel(curtime, 17,0);
                  setAnalogChannel(curtime, 22,0);

                  %digital trigger @ 8400
            DigitalPulse(calctime(curtime,0),12,10,1);
            
                  curtime = AnalogFunc(curtime,0,@(t,d1,t1,dm,tm,d2,t2)(back_hor_minimum_jerk(t,d1,t1,dm,tm,d2,t2)+360+0.1),T1Vert+TmVert+T2Vert,D1Vert-0.1,T1Vert,DmVert,TmVert,D2Vert,T2Vert);
                  curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+horiz_length+0.1),cube_wait_time,cube_wait_time,0.1);    
                                    
              elseif ver_transport_type==3
                  
%                 for ii = length(vert_lin_trans_distances):(-1):2
%                     curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,t1,t2)((t2-t1)/tt.*t+t1+horiz_length),vert_lin_trans_times(ii-1),vert_lin_trans_times(ii-1),vert_lin_trans_distances(ii),vert_lin_trans_distances(ii-1));
%                 end
%                 
%                  vert_lin_total_time = zeros(size(vert_lin_trans_distances));
%                   for ii = 2:length(vert_lin_trans_distances)
%                     vert_lin_total_time(ii) = vert_lin_total_time(ii-1) + vert_lin_trans_times(ii-1);
%                   end
% 
%                   %vert_pp = interp1(vert_lin_total_time,vert_lin_trans_distances+horiz_length,'linear','pp');
% 
%                   vert_pp = pchip(vert_lin_total_time,vert_lin_trans_distances+horiz_length);
% 
% 
%     %               for ii = 2:length(vert_lin_trans_distances)
%     %                 curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,t1,t2)((t2-t1)/tt.*t+t1+horiz_length),vert_lin_trans_times(ii-1),vert_lin_trans_times(ii-1),vert_lin_trans_distances(ii-1),vert_lin_trans_distances(ii));
%     %               end

                  curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,aa)(ppval(aa,tt-t)),vert_lin_total_time(end),vert_lin_total_time(end),vert_pp);
              
                  
              elseif ver_transport_type==4
              
                   curtime = AnalogFunc(calctime(curtime,0),0,@(t,d1,t1,d2,t2,d3,t3)(back_triple_minimum_jerk(t,d1,t1,d2,t2,d3,t3)+horiz_length),Ttriple1+Ttriple2+Ttriple3,Dtriple1,Ttriple1,Dtriple2,Ttriple2,Dtriple3,Ttriple3);
                
                
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
elseif hor_transport_type == 3 %horizontal in linear piecewise
    
    
%   percent_trans_list = [0:0.05:1];
%   percent_trans = percent_trans_list(seqdata.randcyclelist(seqdata.cycle))
%   addOutputParam('hor_percent_trans', percent_trans);
    
%     hor_lin_trans_distances = [0 5  35 50  280  355  360]; %this always needs to start with 0
%     hor_lin_trans_times =       [200 350 250 1200 1500 500];
    hor_lin_trans_distances = [0 300  345  horiz_length]; %this always needs to start with 0
    hor_lin_trans_times =       [1800 1000 500];
    
    %hor_lin_trans_times =       [250 250 150 1000 1500 400];
    
    
     percent_trans = 1.0;
        dist_temp = hor_lin_trans_distances;
        time_temp = hor_lin_trans_times;
        
        hor_lin_trans_distances = [0];
        hor_lin_trans_times = [];
        
        for ii = 2:length(dist_temp)
            
            if percent_trans==0
                break;
            end
            
            if dist_temp(ii) < (percent_trans*horiz_length)
                hor_lin_trans_distances(ii) = dist_temp(ii);
                hor_lin_trans_times(ii-1) = time_temp(ii-1);
            else
                hor_lin_trans_distances(ii) = (percent_trans*horiz_length);
                hor_lin_trans_times(ii-1) = ((percent_trans*horiz_length)-dist_temp(ii-1))*time_temp(ii-1)/(dist_temp(ii)-dist_temp(ii-1));
                break;
            end
        end
    
     for ii = 2:length(hor_lin_trans_distances)
        curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,t1,t2)((t2-t1)/tt.*t+t1),hor_lin_trans_times(ii-1),hor_lin_trans_times(ii-1),hor_lin_trans_distances(ii-1),hor_lin_trans_distances(ii));
     end
    
      for ii = length(hor_lin_trans_distances):(-1):2
        curtime = AnalogFunc(calctime(curtime,0),0,@(t,tt,t1,t2)((t2-t1)/tt.*t+t1),hor_lin_trans_times(ii-1),hor_lin_trans_times(ii-1),hor_lin_trans_distances(ii),hor_lin_trans_distances(ii-1));
      end 
     
else
    error('Undefined transport type');
end


%% Turn off Vertical Coils 12A-14

setAnalogChannel(calctime(curtime,0),22,0,1);
setAnalogChannel(calctime(curtime,0),23,0,1);
setAnalogChannel(calctime(curtime,0),24,0,1);
setAnalogChannel(calctime(curtime,0),20,0,1);

timeout = curtime;

end