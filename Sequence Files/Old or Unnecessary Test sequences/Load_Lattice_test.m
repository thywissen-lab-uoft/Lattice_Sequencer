%------
%Author: Dylan
%Created: Apr 2013
%Summary:   TEST Loading the lattice -- intentionally left without parameters.
%           Rampup times and everything that is done in the lattice should
%           be specified in here.
%           Typically called after evaporation in ODT
%------

function timeout = Load_Lattice_test(timein, P_dip)
global seqdata;

% timein is the time at which the lattice starts to be ramped up
    curtime = timein;
    
%This extra time only for when Load_Lattice is run alone, in order to "not go back in time".    
    curtime = calctime(curtime,1500);
    
% Turn rotating waveplate to shift some power to the lattice beams
    rotation_time = 1000;   % The time to rotate the waveplate
    P_lattice = 0.2;        % The fraction of power that will be transmitted 
                            % through the PBS to lattice beams
                            % 0 = dipole, 1 = lattice
    AnalogFunc(calctime(curtime,-100-rotation_time),41,@(t,tt,Pmax)(0.5*asind(sqrt((Pmax)*(t/tt)))/9.36),rotation_time,rotation_time,P_lattice);

%% Sequence parameters    
    
% Parameters for ramping the dipole trap, e.g. to decompress during loading
    dip_endpower = 1*P_dip;     % where to end the ramp
    dip_ramptime = 1*200;     % how long to ramp (note: this has to be shorter or equal to the lattice ramptime)
    dip_rampstart = 0*175;      % when to ramp the ODTs, relative to timein
    
%     %lattice_power_list    =    [0.1:0.1:1.0];
   lat_holdtime_list =    [0.1:0.1:2.0 0.1:0.1:2.0];
%     
%      %Create linear list
%          %index=seqdata.cycle;
% %         
%         %Create Randomized list
           index=seqdata.randcyclelist(seqdata.cycle);
%           %lattice_power = lattice_power_list(index);
            lattice_holdtime = lat_holdtime_list(index);
%          addOutputParam('lattice_power',lattice_power);
            
%          addOutputParam('run_parameter',lattice_power);

lattice_holdtime = 10; %10

lattice_depth = 20;  %10Er for Rb = 4 Er for K40    

% Parameters for ramping up the lattice (starts ant timein)
    lat_startpower = 0;     % where to sstart the ramp from
    zlat_rampuppower = 1*lattice_depth*0.0155;% where to end the ramp
    ylat_rampuppower = 1*lattice_depth*0.0060;
    xlat_rampuppower =1*lattice_depth*0.0009;
    lat_rampuptime = 250;   % how long to ramp
    
    addOutputParam('lattice_depth',lattice_depth);
    
%     if dip_ramptime+ dip_rampstart > lat_rampuptime
%        error('dipole ramp has to finish before Lattice ramp')        
%     end
    
    collapse_revival = 0;
    collapse_revival_rampuptime = 0.05;
    collapse_revival_zpwr = 30/lattice_depth*zlat_rampuppower ;
    collapse_revival_ypwr = 30/lattice_depth*ylat_rampuppower;
    collapse_revival_xpwr = 30/lattice_depth*xlat_rampuppower;
    
% Parameters for ramping down the lattice (after things have been done)
    zlat_endpower = 0;       % where to end the ramp
    ylat_endpower = 0;       % where to end the ramp
    xlat_endpower = 0;       % where to end the ramp
    lat_rampdowntime = 1; % how long to ramp (0: switch off)
    lat_rampdowntau = 0.2;    % time-constant for exponential rampdown (0: min-jerk)
    lat_post_waittime = 0 ;% whether to add a waittime after the lattice rampdown (adds to timeout)

% Additional parameters and flags for this sequence    
    dipole_trap_off_after_lattice_on = 0;
    %lattice_holdtime = 1*0.4;
    
% add ouput parameters to save along with images    
    addOutputParam('lat_rampuptime',lat_rampuptime);
    addOutputParam('zlat_rampuppower',zlat_rampuppower);
    addOutputParam('lattice_holdtime',lattice_holdtime);

%% Execute lattice sequence
    
    
    % Enable rf output on ALPS3 (fast rf-switch -- 0: ON / 1: OFF)
    setDigitalChannel(calctime(curtime,0),11,0);
    setDigitalChannel(calctime(curtime,0),34,0);
    
    setAnalogChannel(calctime(curtime,0),44,-10,1);
    setAnalogChannel(calctime(curtime,0),43,-10,1);
     setAnalogChannel(calctime(curtime,0),45,-10,1);
        
    % ODT1&2 ramps
                AnalogFunc(calctime(curtime,+dip_rampstart),40,@(t,tt,dt)(minimum_jerk(t,tt,dt)+P_dip),dip_ramptime,dip_ramptime,dip_endpower-P_dip);
                curtime = AnalogFunc(calctime(curtime,+dip_rampstart),38,@(t,tt,dt)(minimum_jerk(t,tt,dt)+2.2*P_dip),dip_ramptime,dip_ramptime,2.2*(dip_endpower-P_dip));
       
    % Lattice rampup
              AnalogFunc(calctime(curtime,0),43,@(t,tt,dt)(minimum_jerk(t,tt,dt)+lat_startpower),lat_rampuptime,lat_rampuptime,zlat_rampuppower);
              AnalogFunc(calctime(curtime,0),45,@(t,tt,dt)(minimum_jerk(t,tt,dt)+lat_startpower),lat_rampuptime,lat_rampuptime,xlat_rampuppower);
    curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt)(minimum_jerk(t,tt,dt)+lat_startpower),lat_rampuptime,lat_rampuptime,ylat_rampuppower);

% The lattice is ramped up now ... do things here (holding, further ramps, modulation, physics ...)
            
    if dipole_trap_off_after_lattice_on
        %turn off ODT1&2
        setAnalogChannel(calctime(curtime,0),40,-0.3,1);
        setAnalogChannel(calctime(curtime,0),38,-0.3,1);
    end
    
    zlat_curpower = zlat_rampuppower;
    ylat_curpower = ylat_rampuppower;
    xlat_curpower = xlat_rampuppower;
    
    if ( collapse_revival )
                  AnalogFunc(calctime(curtime,0),43,@(t,tt,dt)(minimum_jerk(t,tt,dt)+zlat_rampuppower),collapse_revival_rampuptime,collapse_revival_rampuptime,collapse_revival_zpwr-zlat_rampuppower);
                  AnalogFunc(calctime(curtime,0),45,@(t,tt,dt)(minimum_jerk(t,tt,dt)+xlat_rampuppower),collapse_revival_rampuptime,collapse_revival_rampuptime,collapse_revival_xpwr-xlat_rampuppower);
        curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt)(minimum_jerk(t,tt,dt)+ylat_rampuppower),collapse_revival_rampuptime,collapse_revival_rampuptime,collapse_revival_ypwr-ylat_rampuppower);        
        
        zlat_curpower = collapse_revival_zpwr;
        ylat_curpower = collapse_revival_ypwr;
        xlat_curpower = collapse_revival_xpwr;

    end
        
    %hold time in lattices
    curtime = calctime(curtime,lattice_holdtime);

    
% Ramp down lattice after things have been done

    if ( lat_rampdowntime > 0 )
        % ramp down lattice (min-jerk oder exponential)
        if ( lat_rampdowntau == 0 );
            % Min-jerk ramp-down of lattices
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,dt)(minimum_jerk(t,tt,dt)+zlat_curpower),lat_rampdowntime,lat_rampdowntime,zlat_endpower-zlat_curpower);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,dt)(minimum_jerk(t,tt,dt)+xlat_curpower),lat_rampdowntime,lat_rampdowntime,xlat_endpower-xlat_curpower);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt)(minimum_jerk(t,tt,dt)+ylat_curpower),lat_rampdowntime,lat_rampdowntime,ylat_endpower-ylat_curpower);
        else
            % exponential ramp-down of lattices
                      AnalogFunc(calctime(curtime,0),43,@(t,tt,dt,tau)(exponential_ramp(t,tt,dt,tau)+zlat_endpower),lat_rampdowntime,lat_rampdowntime,zlat_curpower-zlat_endpower,lat_rampdowntau);
                      AnalogFunc(calctime(curtime,0),45,@(t,tt,dt,tau)(exponential_ramp(t,tt,dt,tau)+xlat_endpower),lat_rampdowntime,lat_rampdowntime,xlat_curpower-xlat_endpower,lat_rampdowntau);
            curtime = AnalogFunc(calctime(curtime,0),44,@(t,tt,dt,tau)(exponential_ramp(t,tt,dt,tau)+ylat_endpower),lat_rampdowntime,lat_rampdowntime,ylat_curpower-ylat_endpower,lat_rampdowntau);
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
        
    % wait after lattice was ramped down (if lattice was ramped down)
    curtime = calctime(curtime,lat_post_waittime);
    
% At the end of this sequence, the lattice should be off and ALPS3 disabled
    
    timeout = curtime;

end