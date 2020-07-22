% %------
%Author: David McKay
%Created: July 2009
%Summary: This turns on the MOT
%------
%RHYS - the main file for the sequence. Can we give it another name?
%RHYS - the file is basically some initializations defining which parts of
%the sequence to call, plus initialization of some parameters. Then,
%functions for different sequences (dipole trap loading, lattice, imaging,
%etc...) are called from if statements. Also, this main function itself
%contains a lot of the magnetic trap evaporation sequence, making it not
%really a 'main' file perse. 
%RHYS - an improved organization would be for this to simply be a 'main'
%file that loads parameters. It could then call various class methods for
%different parts of the sequence (i.e. Mag_Trap.Load(x,y,z),
%XDT.Evaporate(p,q,r), etc...)
%
% CORA - Some rambling thoughts: I'm not quite sure if object oriented 
% programming is the ideal coding framework for this system. (this is not
% in direct opposition to your comment rhys, but on the benefits of OOO for
% us
% 1) MATLAB is not inherently object
% oriented, though you can define classes.  While structure object (which
% is what seqdata is), may resemble classes, they don't really have the
% same inherent architecture (ie. constructors, inheretence, etc).
% 2) we don't really make multiple instances of 'class objects'.   
% 
% Global variables are powerful and very dangerous tools in my experience.
% Perhaps another solution would be to remove the globalness of this
% variable. For example, seqdata could be a locally passed structure that
% is operated on : (not a real example below)
%   seqdata = magtrap(seqdata) % adds the magtrap to the sequence
%
% The experiment is inherently "timelike and sequential". Ie. The MOT is
% loaded, then we do some CMOT/molasses, then we do transport.  
% And I think if possible, it would be helpful if the code structure
% better reflected the causal and sequential nature of the experiment.
%



function timeout = Load_MagTrap_sequence(timein)

curtime = timein;

%% Initialize seqdata
    global seqdata;

    seqdata.numDDSsweeps = 0;
    seqdata.scanindex = -1;

    %RHYS - which parameters should be sequence parameters and which should
    %not? An answer is that perhaps all parameters could be sequence
    %parameters... but seqdata is a global variable, and this could lead to
    %local conflicts (ramp_time is probably used in many different local
    %contexts as a variable, for instance). Two solutions come to mind: 1) more
    %layers to the seqdata structure (easy) or 2) switching to class-based
    %sequencer with local properties defined (e.g. XDT.ramp_time, 
    %Lattice.ramp_time, etc...) (harder, but better)

    %Ambient field cancelling values (ramp to these at end of XDT loading)
    seqdata.params. shim_zero = [(0.1585-0.0160), (-0.0432-0.022), (-0.0865-0.015)];

    %RHYS - Global comment: remove things like this where old values have been
    %commented out for years. Let's use version control (i.e. git) for this
    %purpose. 

    %Shim values that align the plugged-QP trap (these are non-zero, since the
    %centre of the imaging window is different from the natural QP centre)
    seqdata.params. plug_shims = [(seqdata.params. shim_zero(1)-1-0.04-0.3),...
    (seqdata.params. shim_zero(2)+0.125), ...
    (seqdata.params. shim_zero(3)+ 0.35 + 0.35 + 0.20)];%0.35 + 0.55)];


    seqdata.params. shim_val = [0 0 0]; %Current shim values (x,y,z)- reset to zero

    hold_list = [500];
    seqdata.params. molasses_time = getScanParameter(hold_list,...
    seqdata.scancycle,seqdata.randcyclelist,'hold_list');%192.5;
    addOutputParam('molasses_hold_list',seqdata.params. molasses_time); 
       
    % Dipole trap and lattice beam parameters 
    seqdata.params. XDT_area_ratio = 1; % DT2 with respect to DT1

    %RHYS - the ordering here is odd. Why do these flags happen before other
    %flags? Should collate.

    % Rb Probe Beam AOM Order
    seqdata.flags.Rb_Probe_Order = 1;   %1: AOM deflecting into -1 order, beam ~resonant with F=2->F'=2 when offset lock set for MOT
                                    %2: AOM deflecting into +1 order, beam ~resonant with F=2->F'=3 when offset lock set for MOT

    seqdata.flags. in_trap_OP = 0; 
    seqdata.flags. plane_selection_after_D1 = 0;
    seqdata.flags. lattice_img_molasses = 0;
    seqdata.flags. SRS_programmed = [0 0]; %Flags for whether SRS A and B have been programmed via GPIB
        
    kHz = 1E3;
    MHz = 1E6;
    GHz = 1E9;

%% Initialize channes

    initialize_channels();

%% Switches

    %RHYS - please fix indenting in whole code, it is awful. 

    %RHYS - these can be switched on for certain predefined sequences. It's
    %a good idea, but I have never used them (except MOT_abs_image). They
    %should be studied before considering deleting (transfer recap for
    %instance was used for benchmarking transport system). 
    
    %It's preferable to add a switch here than comment out code!
    %Special flags
    mag_trap_MOT = 0; %Absportion image of MOT after magnetic trapping
    MOT_abs_image = 0; %Absorption image of the MOT (no load in mag trap);
    transfer_recap_curve = 0; %Transport curve from MOT and back
    after_sci_cell_load = 0; %Abs image after loading into science cell
    bench_transport = 0; %special stage for benchmarking the transport
    bench_rf = 0; %special stage for benchmarking RF power making it to the atoms
    seqdata.flags.rb_vert_insitu_image = 0; 
    %take a vertical in-situ image of BEC in XDT to centre the microscope objective
    
    seqdata.flags.controlled_load = 0; %do a specific load time
    controlled_load_time = 20000;

    %RHYS - go through flags and remove obsolete options. PXU and VV should
    %know most of what is and is not useful, but should still be done
    %carefully. Obviously the code that would be called by the flag must
    %also be modified. 
    
    %RHYS - the flag system makes some sense, in that it is useful for
    %specifying what parts of the sequence to run, whether to look at Rb or
    %K, etc. Compared with the CHIP lab approach of running a different
    %file for each possible sequence, this seems more natural. However, it
    %should be streamlined: only a few flags are ever actually switched for
    %controlling the sequence these days. The others are basically
    %permanent, and thus should no longer be considered 'flags', but more
    %like 'fixed properties'. 
    
    % Imaging
    
    %RHYS - really don't need so many image types, and why is iXon_movie
    %its own thing?
    
    seqdata.flags.image_type = 0; 
    %0: absorption image, 1: recapture, 2:fluor, 
    %3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 
    %6: MOT fluor with MOT off, 7: fluorescence image after do_imaging_molasses 
    %8: iXon fluorescence + Pixelfly absorption
    iXon_movie = 1; %Take a multiple frame movie?
    seqdata.flags.image_atomtype = 0;%  0= Rb, 1 = K, 2 = Rb+K
    seqdata.flags.image_loc = 1; %0: `+-+MOT cell, 1: science chamber    
    seqdata.flags.img_direction = 0; 
    %1 = x direction (Sci) / MOT, 2 = y direction (Sci), 
    %3 = vertical direction, 4 = x direc tion (has been altered ... use 1), 5 = fluorescence(not useful for iXon)
    seqdata.flags.do_stern_gerlach = 0; %1: Do a gradient pulse at the beginning of ToF
    seqdata.flags.iXon = 0; % use iXon camera to take an absorption image (only vertical)
    seqdata.flags.do_F1_pulse = 0; % repump Rb F=1 before/during imaging
   
    %RHYS - thse two should be fixed by the circumstance of the sequence,
    %not separately defined. 
    
    seqdata.flags.In_Trap_imaging = 0;
    seqdata.flags.High_Field_Imaging = 0;
    %1= image out of QP, 0=image K out of XDT , 2 = obsolete, 
    %3 = make sure shim are off for D1 molasses (should be removed)
    seqdata.flags.K_D2_gray_molasses = 0; %RHYS - Irrelevant now. 
    
    %RHYS - params should be defined in a separate location from flags. 
    
    seqdata.params.tof =  15;  % 45 for rough alignment, 20 for K-D diffraction
    seqdata.params.UV_on_time = 10000; %UV on time + savingtime + wait time = real wait time between cycles%
    % usually 15s for non XDT
    
    %RHYS - Global comment: All of these flags and parameters could be
    %defined in an text file and loaded on sequence run, rather than
    %hardcoded. Should make for better organization. 
    
    %RHYS - These have been fixed for years. Other options could be
    %compared.
    
    % Transport curves
    seqdata.flags.hor_transport_type = 1; 
    %0: min jerk curves, 1: slow down in middle section curves, 2: none
    seqdata.flags.ver_transport_type = 3; 
    %0: min jerk curves, 1: slow down in middle section curves, 2: none, 3: linear, 4: triple min jerk

    % For debugging: enable only certain coils during the transport
    % sequence (and only during the transport sequence!)
    % seqdata.coil_enable = ones(1,23); % can comment these lines for normal operation
    % seqdata.coil_enable(8) = 0; %coil 7
    % List of channels as they are ordered in transport_coil_currents*.m:
    % 1:a18, 2:a7, 3:a8 4:a9, 5:a10, 6:a11, 7:a12, 8:a13, 9:a14, 10:a15,
    % 11:a16, 12:a17, 13:a9, 14:a22, 15:a23, 16:a24, 17:a20, 18:a21, 19:a6,
    % 20:a3, 21:a17, 22:d22, 23:d28
    % use this order with the boolean enable array!

    % Use stage1  = 2 to evaporate fast for transport benchmarking 
    % Use stage1b = 2 to do microwave evaporation in the plugged QP trap
    seqdata.flags.compress_QP = 1; % compress QP after transport
    seqdata.flags.RF_evap_stages = [1, 0, 0]; %[stage1, decomp/transport, stage1b] %Currently seems that [1,1,0]>[1,0,0] for K imaging, vice-versa for Rb.
    
    %RHYS - Here be parameters. 
    
    rf_evap_time_scale = [1.0 1.5];[1.0 1.2];[0.8 1.2];[1.0 1.2]; %[0.9 1] little improvement; [0.2 1.2] small clouds but fast [0.7, 1.6]
    RF_1B_Final_Frequency = 0.85;
    seqdata.flags.do_plug = 0;   % ramp on plug after transfer to window
    seqdata.flags.lower_atoms_after_evap = 0; % lower hot cloud after evap to get clean TOF signal

    %RHYS - a bunch of unused options here. 
    
    % Dipole trap
    seqdata.flags.do_dipole_trap = 0; % 1: dipole trap loading, 2: dipole trap pulse, 3: pulse on dipole trap during evaporation
    seqdata.flags.CDT_evap = 0;        % 1: exp. evap, 2: fast lin. rampdown to test depth, 3: piecewise lin. evap 
    seqdata.flags.K_RF_sweep = 0;    %sweep 40K into |9/2,-9/2>; %create mixture in XDT, go to dipole-transfer,  40K RF Sweep, set second_sweep to 1    
    seqdata.flags.init_K_RF_sweep = 0; %sweep 40K into |9/2,-9/2>; %create mixture in XDT before evap, go to dipole-transfer,  40K RF Sweep, set second_sweep to 1  

    % Optical lattice
    seqdata.flags.load_lattice = 0; % set to 2 to ramp to deep lattice at the end; 3, variable lattice off & XDT off time
    seqdata.flags.pulse_lattice_for_alignment = 0; % 1: lattice diffraction, 2: hot cloud alignment, 3: dipole force curve
    seqdata.flags.pulse_zlattice_for_alignment = 0; % 1: pulse z lattice after ramping up X&Y lattice beams (need to plug in a different BNC cable to z lattice ALPS)

    if (seqdata.flags.do_dipole_trap ~= 0 || seqdata.flags.load_lattice ~= 0)
        seqdata.flags.QP_imaging = 0;
    else
        seqdata.flags.QP_imaging = 1;
    end

    %RHYS - these are kind of useless.
    %VV - Although these are set to zero there are a bunch of occurrances of these flags in the this
    %sequeence and other files. So keeping these for now. Will be deleted
    %later
    %Imaging Molasses
    seqdata.flags.do_imaging_molasses = 0; % 1: In Lattice or XDT, 2: Free space after QP, 3: Free Space after XDT
    seqdata.flags.evap_away_Rb_in_QP = 0; %Evaporate to 0.4MHz in QP+XDT to kill Rb and load lots of K (only works when loading XDT)
    seqdata.flags.pulse_raman_beams = 0; % pulse on D2 raman beams for testing / alignment
    %RHYS - Useful! Where to trigger scope. Should be more apparent. 
    
    scope_trigger = 'Load lattices'; 

%% Set switches for predefined scenarios

    %RHYS - the predefined scenarios described before. These have not been
    %used in years, so cannot verify whether they do or do not work. Useful
    %idea though. 

    if mag_trap_MOT || MOT_abs_image || transfer_recap_curve
        seqdata.flags.hor_transport_type = 2;
        seqdata.flags.ver_transport_type = 2;
        seqdata.flags.image_type = 0; %0: absorption image, 1: recapture, 2:fluor, 3: blue_absorption, 4: MOT fluor, 5: load MOT immediately, 6: MOT fluor with MOT off
        seqdata.flags.image_loc = 0;
        seqdata.flags.do_plug = 0;
        seqdata.flags.compress_QP = 0;
        seqdata.flags.RF_evap_stages = [0 0 0];
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;  
        seqdata.flags.pulse_lattice_for_alignment = 0;
    end

    if seqdata.flags.image_loc == 0 %MOT cell imaging
        seqdata.flags.do_plug = 0;
        seqdata.flags.compress_QP = 0;
        seqdata.flags.RF_evap_stages = [0 0 0];
        seqdata.flags.do_dipole_trap = 0;
        seqdata.flags.load_lattice = 0;  
        seqdata.flags.pulse_lattice_for_alignment = 0;
    end

%% Consistency checks
    %Implement special flags
    if (mag_trap_MOT + MOT_abs_image + transfer_recap_curve + after_sci_cell_load)>1
        error('Too many special flags set');
    end

%% Set Objective Piezo Voltage
% If the cloud moves up, the voltage must increase to refocus
%  (as the experiment warms up, selected plane tends to move up a bit)
    
    %RHYS - Setting some specific parameters for DDS and objective
    %position. Silly that this is here. 

    obj_piezo_V_List = [4.6];
    % 0.1V = 700 nm, must be larger than 0. larger value means farther away from the window.
    obj_piezo_V = getScanParameter(obj_piezo_V_List, seqdata.scancycle, seqdata.randcyclelist, 'Objective_Piezo_Z');%5
    % obj_piezo_V = 6.8;
    setAnalogChannel(calctime(curtime,0),'objective Piezo Z',obj_piezo_V,1);
    addOutputParam('objpzt',obj_piezo_V);
    
    %VV - I plan to puth the below line of code into a seperate code just
    %for the purpose of initialization of the experiment. I don't think it
    %is a good practice to keep commented code here just like this.
    
    % Set 4-Pass Frequency
    %Don't want to do this with every cycle since it drops the connection
    %sometimes and doesn't turn on correctly
 
%     detuning_list = [0];[0];300;
%     df = getScanParameter(detuning_list, seqdata.scancycle, seqdata.randcyclelist, 'detuning');
%     DDSFreq = 324.20625*MHz + df*kHz/4;
%     DDS_sweep(calctime(curtime,0),2,DDSFreq,DDSFreq,calctime(curtime,1));
%     addOutputParam('DDSFreq',DDSFreq);
% 
% 
%     % %Set the frequency of the first DP AOM 
%     D1_FM_List = [222.5];
%     D1_FM = getScanParameter(D1_FM_List, seqdata.scancycle, seqdata.randcyclelist);%5
%     setAnalogChannel(calctime(curtime,0),'D1 FM',D1_FM);
%     addOutputParam('D1_DP_FM',D1_FM);

%% Make sure dipole and lattice traps are off and adjust XDT piezo mirrors
%% and initialize repump imaging.

    %RHYS - Initialization settings for a lot of channels. But, the 'reset
    %values' should already be set in initialize_channels, and, I think,
    %set at the end of the sequence. So, these should just be incorporated
    %into that function properly instead of defined here. 

    %Initialize modulation ramp to off.
    setAnalogChannel(calctime(curtime,0),'Modulation Ramp',0);

    %Initialize the Raman VVA to on.
    setAnalogChannel(calctime(curtime,0),'Raman VVA',9.9);

    %close all RF and uWave switches
    setDigitalChannel(calctime(curtime,0),'RF TTL',0);
    setDigitalChannel(calctime(curtime,0),'Rb uWave TTL',0);
    setDigitalChannel(calctime(curtime,0),'K uWave TTL',0);
    setAnalogChannel(calctime(curtime,0),'uWave VVA',10);
    
    %Set both transfer switches back to initial positions
    setDigitalChannel(calctime(curtime,0),'RF/uWave Transfer',0); %0 = RF
    setDigitalChannel(calctime(curtime,0),'K/Rb uWave Transfer',1); %1 = Rb
    setDigitalChannel(calctime(curtime,0),'Rb Source Transfer',1); %0 = Anritsu, 1 = Sextupler
    
    %Reset Feschbach coil regulation
    setDigitalChannel(calctime(curtime,0),'FB Integrator OFF',0);  %Integrator disabled
    setDigitalChannel(calctime(curtime,0),'FB offset select',0);        %No offset voltage
    
    %turn off dipole trap beams
    setAnalogChannel(calctime(curtime,0),'dipoleTrap1',-0.5,1);
    setAnalogChannel(calctime(curtime,0),'dipoleTrap2',-1,1);
    setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
    setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);
    
    %turn off lattice beams
    setAnalogChannel(calctime(curtime,0),'xLattice',-0.1,1);
    setAnalogChannel(calctime(curtime,0),'yLattice',-9.9,1);
    setAnalogChannel(calctime(curtime,0),'zLattice',-0.1,1);
    
    setDigitalChannel(calctime(curtime,0),'yLatticeOFF',1);
    setDigitalChannel(calctime(curtime,0),'Lattice Direct Control',1);% Added 2014-03-06 in order to avoid integrator wind-up
    
    %set rotating waveplate back to full dipole power
    AnalogFuncTo(calctime(curtime,0),'latticeWaveplate',@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),2500,2500,0,1);
    
    %set uWave Generator Selection back to SRS A by default
    setDigitalChannel(curtime,'K uWave Source',0);
    
    % Set CDT piezo mirrors (X, Y, Z refer to channels, not spatial dimension)
    CDT_piezo_X = 0;
    CDT_piezo_Y = 0;
    CDT_piezo_Z = 0;
    setAnalogChannel(curtime,'Piezo mirror X',CDT_piezo_X);
    setAnalogChannel(curtime,'Piezo mirror Y',CDT_piezo_Y);
    setAnalogChannel(curtime,'Piezo mirror Z',CDT_piezo_Z);

    %Close science cell repump shutter
    setDigitalChannel(calctime(curtime,0),'Rb Sci Repump',0); %1 = open, 0 = closed
    setDigitalChannel(calctime(curtime,0),'K Sci Repump',0); %1 = open, 0 = closed
        
    %Kill beam AOM on to keep warm.
    setDigitalChannel(calctime(curtime,0),'Kill TTL',1);
    setDigitalChannel(curtime,'Downwards D2 Shutter',0);
    
    %Pulsed beams on to keep warm.
    setDigitalChannel(calctime(curtime,0),'D1 OP TTL',1);
    
    %Set Raman AOM TTL to open.
    %Turn off Raman shutter with TTL.
    setDigitalChannel(calctime(curtime,5),'Raman Shutter',1);
    setDigitalChannel(calctime(curtime,0),'Raman TTL',1);
    
    %Set 'D1' Raman AOMs to open, shutter closed.
    setDigitalChannel(calctime(curtime,0),'D1 TTL',1);
    setDigitalChannel(calctime(curtime,0),'D1 Shutter',0);
    
    %Set TTL to keep F-pump and mF-pump warm.
    setDigitalChannel(calctime(curtime,0),'F Pump TTL',0);
    setDigitalChannel(calctime(curtime,0),'FPump Direct',1);
    setAnalogChannel(calctime(curtime,0),'F Pump',9.99);
    
    %Plug beam
    setDigitalChannel(calctime(curtime,0),'Plug Shutter',0); %1: off, 0: on
   
    %High-field imaging
    setDigitalChannel(calctime(curtime,0),'High Field Shutter',0);
    setDigitalChannel(calctime(curtime,0),'K High Field Probe',1);

    
%% Make sure Shim supply relay is on

    %Turn on MOT Shim Supply Relay
    setDigitalChannel(calctime(curtime,0),33,1);

    %Turn shim multiplexer to MOT shims    
    setDigitalChannel(calctime(curtime,0),37,0);  

%% Prepare to Load into the Magnetic Trap

    if ( seqdata.flags.controlled_load == 1 )

        %turn off trap
        setAnalogChannel(curtime,8,0);
        setDigitalChannel(curtime,4,0);

        %turn trap back on
curtime = Load_MOT(calctime(curtime,500),30);

        %wait fixed amount of time
curtime = calctime(curtime,controlled_load_time);

    else

        %RHYS - which historic reasons? Is it important?
        
        %this has been here for historic reasons
        curtime = calctime(curtime,1500);

    end
    
    %RHYS - The first important code that is called. Applies
    %CMOT/molasses/optical pumping to MOT. 
curtime = Prepare_MOT_for_MagTrap(curtime);
   
    %RHYS - Should integrate the following lines into the above function. 

    %Open other AOMS to keep them warm. Why ever turn them off for long
    %when we have shutters to do our dirty work?
    setDigitalChannel(calctime(curtime,10),'K Trap TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Trap AM',0.8);
    
    setDigitalChannel(calctime(curtime,10),'Rb Trap TTL',0);    
    setAnalogChannel(calctime(curtime,10),'Rb Trap AM',0.7);

    setDigitalChannel(calctime(curtime,10),'K Repump TTL',0);
    setAnalogChannel(calctime(curtime,10),'K Repump AM',0.45);
    
    setAnalogChannel(calctime(curtime,10),'Rb Repump AM',0.9);

%% Load into Magnetic Trap

    %RHYS - One of the first examples of doing something based on a
    %confusing series of if statements and conditions. Works, but is highly
    %error prone and has become very convoluted over time as options have
    %been added and removed. 

    if ~( MOT_abs_image || seqdata.flags.image_type==4 )

        %same as molasses (assume this zero's external fields)

        yshim2 = 0.25;%0.25; %0.9
        xshim2 = 0.25;%0.2; %0.1
        zshim2 = 0.05;%0.05; %0.3  0.0 Dec 4th 2013
        
        %RHYS - Again, probably control these things within functions for
        %code readability. 
        
        %optimize shims for loading into mag trap
        setAnalogChannel(calctime(curtime,0.01),'Y Shim',yshim2,3); %1.25
        setAnalogChannel(calctime(curtime,0.01),'X Shim',xshim2,2); %0.3 
        setAnalogChannel(calctime(curtime,0.01),'Z Shim',zshim2,2); %0.2

        %RHYS - the second important function, which loads the MOT into the magtrap. 

curtime = Load_MagTrap_from_MOT(curtime);

        if transfer_recap_curve && (seqdata.flags.hor_transport_type == 2)
curtime = calctime(curtime,1000);
        end

    end
        
    %turn off shims
    setAnalogChannel(calctime(curtime,0),'Y Shim',0.0,3); %3
    setAnalogChannel(calctime(curtime,0),'X Shim',0.0,2); %2
    setAnalogChannel(calctime(curtime,0),'Z Shim',0.0,2); %2

    

%% Transport 

    %open kitten relay
curtime = setDigitalChannel(curtime,'Kitten Relay',1);

    %Turn shim multiplexer to Science shims
    setDigitalChannel(calctime(curtime,1000),37,1); 
    %Close Science Cell Shim Relay for Plugged QP Evaporation
    setDigitalChannel(calctime(curtime,800),'Bipolar Shim Relay',1);
    
    %Turn Shims to Science cell zero values
    setAnalogChannel(calctime(curtime,1000),27,0,3); %3
    setAnalogChannel(calctime(curtime,1000),28,0,3); %3
    setAnalogChannel(calctime(curtime,1000),19,0,4); %4

    %digital trigger
    disp('Start Calculating Transport')
    ScopeTriggerPulse(calctime(curtime,0),'Start Transport');
    
    %RHYS - the third imporant function. Transports cloud from MOT to science
    %chamber. All surrounding relevant code should be integrated into this.
    %Furthermore, note the significant calculation time due to spline
    %interpolation - this is likely unneccesary?
    
curtime = Transport_Cloud(curtime, seqdata.flags.hor_transport_type, seqdata.flags.ver_transport_type, seqdata.flags.image_loc);
    disp('End Calculating Transport')



%% Ramp up QP
    % Compression stage after the transport to the science cell

    %RHYS - a fourth important function. Makes a deep magnetic trap after
    %transport. The shims are set to their plug-evaporation values here, but
    %could be played with, since the actual values only move a big trap around
    %at this stage, and may be unhelpful/irrelevant. Also, integrate into the
    %function for cleanliness (I'm going to stop repeating this). 

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_after_trans(curtime, seqdata.flags.compress_QP);


    %Shim Values to Turn On To: (0 to do plug evaporation, Bzero values for molasses after RF Stage 1)
    y_shim_val = seqdata.params. plug_shims(2); %0*0.5
    x_shim_val = seqdata.params. plug_shims(1); %0*1.6
    z_shim_val = seqdata.params. plug_shims(3); %0*0.8
       
    
    %turn on shims
    AnalogFuncTo(calctime(curtime,0),'Y Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,y_shim_val,4); 
    AnalogFuncTo(calctime(curtime,0),'X Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,x_shim_val,3); 
curtime = AnalogFuncTo(calctime(curtime,0),'Z Shim',@(t,tt,y1,y2)(ramp_minjerk(t,tt,y1,y2)),100,100,z_shim_val,3); 

%% Evaporate in Tight QP Trap

    %RHYS - Here lies a mess of parameters, with the relevant code being
    %do_evap_stage called with the aforementioned parameters. Prime candidate
    %for cleaning up. 

    if ( seqdata.flags.RF_evap_stages(1) == 1 )

         fake_sweep = 0;

         hold_time = 100;
         pre_hold_time =  100;

         start_freq = 42;42;%42  

        %this worked well with 0.6 kitten
        freqs_1 = [ start_freq 28 20 16]*MHz;[60 60];[ start_freq 28 20 16]*MHz; %7.5 %[ start_freq 28 20 12]*MHz before 2018-03-06 12MHz

        RF_gain_1 = 0.5*[-4.1 -4.1 -4.1 -4.1]*(9)/9*1;1*[-4.1 -4.1 -4.1 -4.1]*(9)/9*1;%1*[ 9 9 9 9]*(9)/9*1;1*[-5.93 -5.93 -5.93 -5.93];  %9 9 9 (5)/9*0.75
        sweep_times_1 = [ 14000 8000 1000].*rf_evap_time_scale(1);[100];%[ 14000 6000 2000].*rf_evap_speed(1);%[ 14000 6000 2000].*rf_evap_speed(1); before 2017-05-02


        %hold before evap
curtime = calctime(curtime,pre_hold_time);

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) == 0));

    %This does a fast evaporation to benchmark the transport
    if ( seqdata.flags.RF_evap_stages(1) == 2 )

         fake_sweep = 1;

         hold_time = 100;

         %Jan 2019
         start_freq = 42;%42

        %this worked well with 0.6 kitten
        freqs_1 = [start_freq 10]*MHz; %7.5
        RF_gain_1 = [9]*(5)/9*0.75;%[9]*(5)/9*0.75; %9 9 9
        sweep_times_1 = [15000]; 

curtime = do_evap_stage(curtime, fake_sweep, freqs_1, sweep_times_1, ...
        RF_gain_1, hold_time, (seqdata.flags.RF_evap_stages(3) ~= 0));

    end
    
    %Get rid of Rb afterwards (used for loading dilute 40K into lattice)
    kill_Rb_after_RFStage1 = 0;
    
    if kill_Rb_after_RFStage1
        kill_pulse_time = 5; %5

        %open shutter
        %probe
        setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
        %repump
        %setDigitalChannel(calctime(curtime,-10),5,1);
        %open analog
        %probe
        setAnalogChannel(calctime(curtime,-10),36,0.7);
        %repump (keep off since no TTL)
            
        %set TTL
        %probe
        setDigitalChannel(calctime(curtime,-10),24,1);
        %repump doesn't have one
            
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);

        %pulse beam with TTL 
        %TTL probe pulse
curtime = DigitalPulse(calctime(curtime,0),24,kill_pulse_time,0);
        %repump pulse
        %setAnalogChannel(calctime(curtime,0),2,0.7); %0.7
        %curtime = setAnalogChannel(calctime(curtime,kill_pulse_time),2,0.0);
        
        %close shutter
curtime = setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
        %curtime = setDigitalChannel(calctime(curtime,0),5,0);
        
curtime=calctime(curtime,5);
    end
    
%% Evaporation during compression
    do_evap_during_compression = 0;
    if (do_evap_during_compression && seqdata.flags.RF_evap_stages(2)==1)
        
        freqs_1 = [freqs_1(end)/MHz*1 25]*MHz;
        RF_gain_1 = [0.5 0.5]*[-4.1];
        sweep_times_1 = 560; %560 is maximum
        do_evap_stage(curtime,0, freqs_1, sweep_times_1, ...
                RF_gain_1, 0, (seqdata.flags.RF_evap_stages(3) == 0));

    end
%% Ramp down QP and transfer to the window

    %RHYS - Decompress the trap and bring atoms closer to the window. Trap
    %depth and position can be played with here. Should automatically rescale
    %plug_shim values with the depth of the gradient so trap doesn't move when
    %adjusting depth (typically we compensate by hand, but why waste the time
    %when the relationship is known?)

[curtime I_QP I_kitt V_QP I_fesh] = ramp_QP_before_transfer(curtime, seqdata.flags.RF_evap_stages(2), I_QP, I_kitt, V_QP, I_fesh);


%% Ramp on Plug
    % ramped up once atoms arrived at imaging position (or a bit later, but not earlier)

    %RHYS - Obviously cut a lot here... we just open a shutter now. It doesn't
    %even necessarily need to be its own flag (as in, it could be on by default
    %if getting to the third stage of RF evap... having the option to turn it
    %off is sometimes useful for alignments, however). 

    if ( seqdata.flags.do_plug == 1 )
   
        %set plug on time from end of evap       
        plug_offset = -500; % -200
    
        %open plug shutter
        setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',1); %0: OFF; 1: ON
   
    end

%% Evaporation Stage 1b
    % At the imaging position

    %RHYS - same comments as for the previous evaporation stage. This is just a
    %mess of parameters, with a call to do_evap_stage. 

    if ( seqdata.flags.RF_evap_stages(3) == 1 )
%% RF 1b
    fake_sweep = 0;
    rf_gain_1b_list= .5*(-4.1);[-6.3];[-4]; %-6.3;
    rf_1b_gain=getScanParameter(rf_gain_1b_list,seqdata.scancycle,seqdata.randcyclelist,'rf_1b_gain');
    %USUAL SETTINGS    
    %Evaporate to 0.7MHz to load into ODT (0.8MHz to look at Rb)
    freqs_1b = [freqs_1(end)/MHz*1 7 RF_1B_Final_Frequency 2]*MHz;
    RF_gain_1b = [.5*(-4.1) .5*(-4.1) rf_1b_gain rf_1b_gain];[-6.74 -6.74 -7.0 -7.0];[-5.5 -5.5 rf_1b_gain rf_1b_gain];[-6.74 -6.74 -7.0 -7.0];[-6.74 -6.74 -7.0 -7.0];[-5.5 -5.5 -6.3 -6.3];[4 4 1 1];[-6.74 -6.74 -7.26 -7.26];   % 8 8 5 5
    sweep_times_1b = [6000 2000 10]*rf_evap_time_scale(2); [3000 2000 10];%[3000 2500 10]*rf_evap_speed(2);

curtime = do_evap_stage(curtime, fake_sweep, freqs_1b, sweep_times_1b, RF_gain_1b, 0, 1);

    %Get rid of Rb afterwards (used for loading dilute 40K into lattice)
    kill_Rb_after_RFStage1b = 0;
    
    if kill_Rb_after_RFStage1b
        kill_pulse_time = 5; %5

        %probe
        setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
        setAnalogChannel(calctime(curtime,-10),36,0.7); 
        %probe TTL
        setDigitalChannel(calctime(curtime,-10),24,1);
            
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);

        %pulse beam with TTL 
        %TTL probe pulse
curtime = DigitalPulse(calctime(curtime,0),24,kill_pulse_time,0);
        
        %close shutter
curtime = setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
        
curtime=calctime(curtime,5);
    end
    
%% Post RF1b Tasks

    %RHYS - these should not be here, but could actually be useful for
    %debugging XDT loading... if they still work. Removes one species of atom
    %from the mag trap. 

    %blow-away Rb
    do_Rb_blow_away = 0;

   

    if do_Rb_blow_away
        
        %blow away any atoms left in F=2
        %open Rb probe shutter
        setDigitalChannel(calctime(curtime,-10),25,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,-10),4,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,-10),24,1);
        %set detuning
        setAnalogChannel(calctime(curtime,-10),34,6590-237);
        
        %pulse beam with TTL
curtime = DigitalPulse(calctime(curtime,0),24,15,0);
        
        %close shutter
        setDigitalChannel(calctime(curtime,0),25,0); %0=closed, 1=open
    end
    
    do_K_blow_away = 0;
    K_blow_away_time = -15; %1350
     
    if do_K_blow_away
          
        %open K probe shutter
        setDigitalChannel(calctime(curtime,K_blow_away_time-10),30,1); %0=closed, 1=open
        %open analog
        setAnalogChannel(calctime(curtime,K_blow_away_time-10),29,0.7);
        %set TTL
        setDigitalChannel(calctime(curtime,K_blow_away_time-10),9,1);
        %set detuning
        setAnalogChannel(calctime(curtime,K_blow_away_time-10),5,0);
        
        %pulse beam with TTL
        DigitalPulse(calctime(curtime,K_blow_away_time),9,15,0);
        
        %close K probe shutter
        setDigitalChannel(calctime(curtime,K_blow_away_time+15),30,0);
        %%0=closed, 1=open
    end
    %hold at end of evap
curtime = calctime(curtime,250); %3000
    
   
%% Microwave evaporation instead of RF    
    elseif ( seqdata.flags.RF_evap_stages(3) == 2 )
%% uWave Evap
        %RHYS - interesting option that I've never tried. Uses Rb microwaves for
        %evaporation (lower Rabi freq but possibly cleaner?)
        freqs_1b = [freqs_1(end)/MHz*0.6 4 1.0 ]*MHz; 
        RF_gain_1b = [-4 -4 -7]; 
        sweep_times_1b = [4000 3500 ]*6/6;
    
        %Do uWave evaporation
curtime = do_uwave_evap_stage(curtime, fake_sweep, freqs_1b*3, sweep_times_1b, 0);
    end

%% Post QP Evap Tasks
    %RHYS - clean.
    %turn plug off
    if ( seqdata.flags.do_plug == 1)
        hold_time_list = [0];
        hold_time = getScanParameter(hold_time_list,seqdata.scancycle,seqdata.randcyclelist,'hold_time_QPcoils');
curtime = calctime(curtime,hold_time);   
        plug_offset = -2.5;175;%0 for experiment, -10 to align for in trap image
    
        if ( seqdata.flags.do_dipole_trap ~= 1 )
            setDigitalChannel(calctime(curtime,plug_offset),'Plug Shutter',0);% 0:OFF; 1: ON
            ScopeTriggerPulse(calctime(curtime,0),'plug test');
        end        
    end
%% Dipole trap ramp on (and QP rampdown)
    if ( seqdata.flags.do_dipole_trap == 1 )

        dipole_on_time = 10; %500
    
        %RHYS - an important code. Ramp down the mag trap, load the XDT, and
        %evaporate.
[curtime I_QP V_QP P_dip dip_holdtime] = dipole_transfer(curtime, I_QP, V_QP);
    
  
    
    end
curtime=calctime(curtime,0);


%% Pulse lattice after releasing from dipole trap

    if ( seqdata.flags.pulse_lattice_for_alignment ~= 0 )
        %RHYS - how should these 'pulse lattice' alignment codes be
        %organized/called?
curtime = Pulse_Lattice(curtime,seqdata.flags.pulse_lattice_for_alignment);

    end


%% Load Lattice

    if ( seqdata.flags.load_lattice ~= 0 )
    %RHYS - loads the lattices and performs science/fluorescence imaging.
    %Important. Code is probably way too bulky. 
[curtime P_dip P_Xlattice P_Ylattice P_Zlattice P_RotWave]= Load_Lattice(curtime);
    end

%% Pulse Z Lattice after ramping up other lattices to align

    if (seqdata.flags. pulse_zlattice_for_alignment == 1 )
    %RHYS - another alignment tool. 
curtime = Pulse_Lattice(curtime,4);
    end


%% lower atoms from window for clean TOF release

    if ( seqdata.flags.lower_atoms_after_evap == 1 )
        %RHYS - this is probably useful and we should use it more. Gets atoms
        %away from the window before dropping after RF1A. 
        %100ms, 15A works well for RF_stage_2
        lower_transfer_time = 100;
curtime = AnalogFunc(curtime,1,@(t,tt,dt)(dt*t/tt+I_QP),lower_transfer_time,lower_transfer_time,15-I_QP);
    end


%% Turn off coils and traps.  

    %RHYS - Makes sure all traps are off during TOF (actually initiates TOF for
    %mag trap and XDT). Clean up, could be its own function. Check that
    %procedures are not out of date. 
    
    %turn the Magnetic Trap off
    %set all transport coils to zero (except MOT)
    for i = [7 9:17 22:24 20] 
        setAnalogChannel(calctime(curtime,0),i,0,1);
    end

    
    
    %Turn off QP Coils
    setAnalogChannel(calctime(curtime,0),21,0,1); %15
curtime = setAnalogChannel(calctime(curtime,0),1,0,1); %16
curtime = setAnalogChannel(curtime,3,0,1); %kitten
    
    %MOT
    if ( seqdata.flags.image_type ~= 4 )
        setAnalogChannel(curtime,8,0,1);
    end

    %MOT/QCoil TTL (separate switch for coil 15 (TTL) and 16 (analog))
    %Coil 16 fast switch
    %setDigitalChannel(curtime,21,1);
    qp_switch1_delay_time = 0;
    
    if I_kitt == 0
        %use fast switch
        setDigitalChannel(curtime,21,1);
        setDigitalChannel(calctime(curtime,500),21,0); 
    else
        %Cannot use Coil 16 fast switch if atoms have not be transferred to
        %imaging direction!
    end
    
    %turn off 15/16 switch (10 ms later)
    setDigitalChannel(calctime(curtime,qp_switch1_delay_time),22,0);


    if ( seqdata.flags. do_dipole_trap ~= 0 )
   
        if seqdata.flags. do_dipole_trap == 2
    
            %Leave ODT on during 15ms TOF
            setDigitalChannel(calctime(curtime,25),'XDT TTL',1);
            %turn off dipole trap 1
            setAnalogChannel(calctime(curtime,25),40,0,1);
            %turn off dipole trap 2
            setAnalogChannel(calctime(curtime,25),38,0,1);
        
        end
        
        if seqdata.flags. do_dipole_trap == 1
            setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
            %turn off dipole trap 1
            setAnalogChannel(calctime(curtime,0),40,-0.5,1);
            %turn off dipole trap 2
            setAnalogChannel(calctime(curtime,0),38,0,1);
            setDigitalChannel(calctime(curtime,0),'XDT Direct Control',1);
        end
    
    
        if seqdata.flags. do_dipole_trap == 3
            setDigitalChannel(calctime(curtime,0),'XDT TTL',1);
            %turn off dipole trap 1
            setAnalogChannel(calctime(curtime,0),40,0,1);
            %turn off dipole trap 2
            setAnalogChannel(calctime(curtime,0),38,0,1);
        end
          
    end

    if ( seqdata.flags.load_lattice ~= 0 )
        %turn lattice beams off (leave a bit of time for the rotating waveplate to get back to zero)

        %Z lattice
        setAnalogChannel(calctime(curtime,0),'zLattice',-0.1,1);%0
        %Y lattice
        setAnalogChannel(calctime(curtime,0),'yLattice',-10,1);%0
        %X lattice
        setAnalogChannel(calctime(curtime,0),'xLattice',-0.1,1);%0
    
    end

    if ~(seqdata.flags.image_type==1 || seqdata.flags.image_type==4)
        setDigitalChannel(curtime,16,1);    
    end


%% Imaging

    %RHYS - Imporant code, but could delete the scenarios that are no longer
    %used. Also, the iXon movie option under 8 could use some cleaning. 
    if seqdata.flags.image_type == 0 % Absorption Image

curtime = absorption_image(calctime(curtime,0.0)); 
    
    elseif seqdata.flags.image_type == 8 %Try to use the iXon and a Pixelfly camera simultaneously for absorption and fluorescence imaging.
    
absorption_image(calctime(curtime,0.0));
    
        if (iXon_movie)
            FrameTime = 2500;   
            ExposureTime = 2100;
            addOutputParam('FrameTime',FrameTime);
            addOutputParam('ExposureTime',ExposureTime);

curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',0, ...
            'NumFrames',2,'FrameTime',FrameTime,'ExposureTime',ExposureTime,'DoPostFlush',1); % taking a "movie"
        else
curtime = iXon_FluorescenceImage(curtime,'ExposureOffsetTime',molasses_offset,'ExposureDelay',1,'ExposureTime',5000);
        end
        
    else
        error('Undefined imaging type');
    end

    %RHYS - the next bits of post-sequence code are useful (well, if the
    %demagnetization stuff actually does anything). Could be wrapped into a
    %function. 

%% post-sequence: rotate diople trap waveplate to default value
    do_wp_default = 1;
    if (do_wp_default == 1)
        %Rotate waveplate to divert all power to dipole traps.
        P_RotWave = 0;
        AnalogFunc(calctime(curtime,0),41,@(t,tt,Pmin,Pmax)(0.5*asind(sqrt(Pmin + (Pmax-Pmin)*(t/tt)))/9.36),200,200,P_RotWave,0); 
    end

%% Post-sequence -- e.g. do controlled field ramps, heating pulses, etc.
    do_demag_pulses = 0;
    ramp_fesh_between_cycles = 1;

    if do_demag_pulses
    
curtime = pulse_Bfield(calctime(curtime,150));

    end

    if ramp_fesh_between_cycles
        % This is meant to leave material near the atoms with the same
        % magnetization at the beginning of a new cycle, irrespective whether
        % some strong field was pulsed/snapped off or not during the cycle that
        % just ends. We do not have any positive observation that this helps,
        % but we leave it in just in case (total 1.3s extra).
        fesh_ramptime = 100;
        fesh_final = 20;
        fesh_ontime = 1000;
        setDigitalChannel(calctime(curtime,0),31,1);
curtime = AnalogFunc(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0,fesh_final);
curtime = calctime(curtime,fesh_ontime);
curtime = AnalogFuncTo(calctime(curtime,0),37,@(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),fesh_ramptime,fesh_ramptime,0);
curtime = setAnalogChannel(calctime(curtime,100),37,0);
    end


%% B Field Measurement (set/reset of the field sensor after the cycle)
curtime = sense_Bfield(curtime);

%% Set/Reset Pulses for Remote Field Sensor (after the sensor in the bucket)

curtime = DigitalPulse(calctime(curtime,0),'Remote field sensor SR',50,1);

%% Reset analog and digital channels to default values
    %RHYS - Should go through channels and check whether their reset values
    %make sense! These have not been updated in forever. 
curtime = Reset_Channels(calctime(curtime,0));

%% Pulse on XDTs for 100ms and trigger pyKraken for measurement
    %RHYS - triggering the pyKraken before MOT loading is useful. Measuring the
    %XDT pointing is not done right now, since we removed the QPDs, but is in
    %theory useful (the idea of using QPDs to keep our critical beams aligned
    %is still a good one). 
    DigitalPulse(calctime(curtime,0),'RaspPi Trig',1000,1) % trigger pulse for pyKraken
    measure_XDT_pointing = 0;
    if (measure_XDT_pointing)
        %pulse XDTs on
        setDigitalChannel(calctime(curtime,1),'XDT TTL',0);
        setDigitalChannel(calctime(curtime,1),'XDT Direct Control',0);
        setAnalogChannel(calctime(curtime,1),'dipoleTrap1',0.2);
        setAnalogChannel(calctime(curtime,1),'dipoleTrap2',0.2);
        %turn XDTs off
        setAnalogChannel(calctime(curtime,5001),'dipoleTrap2',0,1);
        setDigitalChannel(calctime(curtime,5001),'XDT TTL',1);
        setAnalogChannel(calctime(curtime,5001),'dipoleTrap1',-0.5,1);
        setDigitalChannel(calctime(curtime,5002),'XDT Direct Control',1);
    end

%% Load MOT
    %RHYS - a lot of parameters and cleaning to do here. I've also always
    %thought it was odd that MOT loading happened at the end of the sequence,
    %and it makes it tricky to optimize the MOT. The reason is probably due to
    %the extra wait time spent saving files after the sequence completes... may
    %as well have a MOT loading while this happens. If that were fixed, this
    %could instead be the first thing in the sequence. 
    rb_mot_det_List=32;[32];30;
    %32 before 2019.1.1
    rb_MOT_detuning=getScanParameter(rb_mot_det_List,seqdata.scancycle,seqdata.randcyclelist,'rb_MOT_detuning');
 
    k_MOT_detuning_list = [22];% before 2018-02-14: 18
    k_MOT_detuning = getScanParameter(k_MOT_detuning_list,seqdata.scancycle,seqdata.randcyclelist,'k_MOT_detuning');        
 
    
    k_repump_shift = 0;  %before2016-11-25:0 %0
    addOutputParam('k_repump_shift',k_repump_shift);
    mot_wait_time = 50;
  
    if seqdata.flags.image_type==5
        mot_wait_time = 0;
    end
        
    %call Load_MOT function
curtime = Load_MOT(calctime(curtime,mot_wait_time),[rb_MOT_detuning k_MOT_detuning]);
        
    setAnalogChannel(curtime,'K Repump FM',k_repump_shift,2)
      
    if ( seqdata.flags.do_dipole_trap == 1 )
curtime = calctime(curtime,dip_holdtime);
        
    elseif mag_trap_MOT || MOT_abs_image

curtime = calctime(curtime,100);
        
    else
curtime = calctime(curtime,1*500);%25000
    end


    %set relay back
curtime = setDigitalChannel(calctime(curtime,10),28,0);



    %RHYS - Following is some irrelevant stuff and some quality of life stuff,
    %including an important check on overall cycle time. 
%% Scope trigger selection

    SelectScopeTrigger(scope_trigger);

%% Create a time-stamp (serial date number without the year); 
    addOutputParam('timestamp',datenum(datevec(now).*[0 1 1 1 1 1]));

%% Timeout

timeout = curtime;

    if (((timeout - timein)*(seqdata.deltat/seqdata.timeunit))>100000)
    error('Cycle time greater than 100s! Is this correct?')
    end



end