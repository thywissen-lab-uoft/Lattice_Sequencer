%------
%Author: Dylan
%Created: Apr 2013
%Summary:  This ramps up the lattice in order to image after doing physics
%in the shallow lattice.  Only called after load_lattice sequence
%------

function curtime = Deep_Lattice(timein, P_dip,P_Xlattice,P_Ylattice,P_Zlattice,P_RotWave)
global seqdata;

% timein is the time at which the lattice starts to be ramped up
    curtime = timein;
    
    
% Turn rotating waveplate to shift some power to the lattice beams
    img_rotation_time = 1;   % The time to rotate the waveplate
    img_P_RotWave = P_RotWave;        % The fraction of power that will be transmitted 
                            % through the PBS to lattice beams
                            % 0 = dipole, 1 = lattice
    AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmax1,Pmax2)(0.5*asind(sqrt((Pmax1)))/9.36+0.5*asind(sqrt((Pmax2)*(t/tt)))/9.36),img_rotation_time,img_rotation_time,P_RotWave,img_P_RotWave-P_RotWave);

%% Sequence parameters    

%ramp up and back
    ramp_up_and_down = 0;

% Parameters for ramping the dipole trap, e.g. to decompress during loading
    img_dip_endpower = 1*P_dip;     % where to end the ramp
    img_dip_ramptime = 0;     % how long to ramp (note: this has to be shorter or equal to the lattice ramptime)
    img_dip_rampstart = 0;      % when to ramp the ODTs, relative to timein
    
img_lattice_depth = 1300;      %Additional Depth for Lattice
                            %10Er for Rb = 4 Er for K40    

% Parameters for ramping up the lattice (starts at timein)
    
    img_zlat_rampuppower = img_lattice_depth;% where to end the ramp
    img_ylat_rampuppower = img_lattice_depth;
    img_xlat_rampuppower =img_lattice_depth;
    img_lat_rampuptime = 100;   % how long to ramp
    


%% Ramp up lattice
    
    
    % Enable rf output on ALPS3 (fast rf-switch -- 0: ON / 1: OFF)
    setDigitalChannel(calctime(curtime,0),11,0);
    setDigitalChannel(calctime(curtime,0),34,0);
   
          
    % ODT1&2 ramps
                AnalogFunc(calctime(curtime,+img_dip_rampstart),40,@(t,tt,dt)(minimum_jerk(t,tt,dt)+P_dip),img_dip_ramptime,img_dip_ramptime,img_dip_endpower-P_dip);
                curtime = AnalogFunc(calctime(curtime,+img_dip_rampstart),38,@(t,tt,dt)(minimum_jerk(t,tt,dt)+2.2*P_dip),img_dip_ramptime,img_dip_ramptime,2.2*(img_dip_endpower-P_dip));
       
    % Lattice rampup
              AnalogFunc(calctime(curtime,0),43,@(t,tt,dt)(minimum_jerk(t,tt,dt)+P_Zlattice),img_lat_rampuptime,img_lat_rampuptime,img_zlat_rampuppower);
              AnalogFunc(calctime(curtime,0),45,@(t,tt,dt)(minimum_jerk(t,tt,dt)+P_Xlattice),img_lat_rampuptime,img_lat_rampuptime,img_xlat_rampuppower);
    curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt)(minimum_jerk(t,tt,dt)+P_Ylattice),img_lat_rampuptime,img_lat_rampuptime,img_ylat_rampuppower);

    
    
    img_xlat_curpower = img_xlat_rampuppower + P_Xlattice;
    img_ylat_curpower = img_ylat_rampuppower + P_Ylattice;
    img_zlat_curpower = img_zlat_rampuppower + P_Zlattice;
    
%% Turn on Molasses Beams
% if ( seqdata.flags.do_imaging_molasses == 1 )
%     curtime = imaging_molasses(calctime(curtime,0));
% else
% end
 %% Hold for some time
 
 curtime = calctime(curtime,1);
  


 %% Shut off lattice
 
if  ramp_up_and_down == 1;
   
    % Parameters for ramping down the lattice (after things have been done)
    img_zlat_rampdownpower = 15;       % where to end the ramp
    img_ylat_rampdownpower = 15;       % where to end the ramp
    img_xlat_rampdownpower = 15;       % where to end the ramp
    img_lat_rampupdowntime = 100; % how long to ramp (0: switch off)
    img_lat_rampupdowntau = 0;    % time-constant for exponential rampdown (0: min-jerk)
    
    post_rampupdown_time = 50;

    if ( img_lat_rampupdowntime > 0 )
        % ramp down lattice (min-jerk oder exponential)
        if ( img_lat_rampupdowntau == 0 );
            % Min-jerk ramp-down of lattices
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+img_zlat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_zlat_curpower-img_zlat_rampdownpower);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+img_xlat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_xlat_curpower-img_xlat_rampdownpower);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt)(-minimum_jerk(t,tt,dt)+img_ylat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_ylat_curpower-img_ylat_rampdownpower);
        else
            % exponential ramp-down of lattices
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,dt,tau)(-exponential_ramp(t,tt,dt,tau)+img_zlat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_zlat_curpower-img_zlat_rampdownpower,img_lat_rampupdowntau);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,dt,tau)(-exponential_ramp(t,tt,dt,tau)+img_xlat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_xlat_curpower-img_xlat_rampdownpower,img_lat_rampupdowntau);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt,tau)(-exponential_ramp(t,tt,dt,tau)+img_ylat_curpower),img_lat_rampupdowntime,img_lat_rampupdowntime,img_ylat_curpower-img_ylat_rampdownpower,img_lat_rampupdowntau);
        
        end
    end
    
    curtime=calctime(curtime,post_rampupdown_time);

    img_xlat_curpower = img_xlat_rampdownpower;
    img_ylat_curpower = img_zlat_rampdownpower;
    img_zlat_curpower = img_zlat_rampdownpower;

elseif ramp_up_and_down == 0;
    
end
    
    % Parameters for ramping down the lattice (after things have been done)
    img_zlat_endpower = 0;       % where to end the ramp
    img_ylat_endpower = 0;       % where to end the ramp
    img_xlat_endpower = 0;       % where to end the ramp
    img_lat_rampdowntime = 10; % how long to ramp (0: switch off)
    img_lat_rampdowntau = 0.2;    % time-constant for exponential rampdown (0: min-jerk)
    

    if ( img_lat_rampdowntime > 0 )
        % ramp down lattice (min-jerk oder exponential)
        if ( img_lat_rampdowntau == 0 );
            % Min-jerk ramp-down of lattices
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,A)(minimum_jerk(t,tt,A)+img_zlat_curpower),img_lat_rampdowntime,img_lat_rampdowntime,img_zlat_endpower-img_zlat_curpower);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,A)(minimum_jerk(t,tt,A)+img_xlat_curpower),img_lat_rampdowntime,img_lat_rampdowntime,img_xlat_endpower-img_xlat_curpower);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,A)(minimum_jerk(t,tt,A)+img_ylat_curpower),img_lat_rampdowntime,img_lat_rampdowntime,img_ylat_endpower-img_ylat_curpower);
        else
            % exponential ramp-down of lattices
            %   Changed on June 25 from the following form:
            %   AnalogFunc(calctime(curtime,0),43,@(t,tt,A,tau)(exponential_ramp(t,tt,A,tau)+img_zlat_endpower),img_lat_rampdowntime,img_lat_rampdowntime,img_zlat_endpower-img_zlat_curpower,img_lat_rampdowntau);
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,A,tau)(exponential_ramp(t,tt,A,tau)+img_zlat_endpower),img_lat_rampdowntime,img_lat_rampdowntime,img_zlat_curpower-img_zlat_endpower,img_lat_rampdowntau);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,A,tau)(exponential_ramp(t,tt,A,tau)+img_xlat_endpower),img_lat_rampdowntime,img_lat_rampdowntime,img_xlat_curpower-img_xlat_endpower,img_lat_rampdowntau);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,A,tau)(exponential_ramp(t,tt,A,tau)+img_ylat_endpower),img_lat_rampdowntime,img_lat_rampdowntime,img_ylat_curpower-img_ylat_endpower,img_lat_rampdowntau);
        
        end
    end
    
    %switch ALPS-enable off (switch-TTL HI) and set power to zero
        %Analog Control
        setAnalogChannel(calctime(curtime,0),43,-10,1);
        setAnalogChannel(calctime(curtime,0),44,-10,1);
        setAnalogChannel(calctime(curtime,0),45,-10,1);
        %TTLs
        setDigitalChannel(calctime(curtime,0),11,1);  %0: ON / 1: OFF         
        setDigitalChannel(calctime(curtime,0),34,1);  %0: ON / 1: OFF  
    
    DigitalPulse(calctime(curtime,0),12,0.1,1);
    


   
    timeout = curtime;

end