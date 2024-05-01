%Note: curtime is only updated to tof in this code just before the first
%absorption image. Thus, all times before this are referenced to the
%presumed drop time.

function timeout = HF_absorption_image(timein)

global seqdata; 
curtime = timein; 

%Populate the relevant structures
seqdata.times.tof_start = curtime; %Forms a list of useful time references.

%Choose to take a dark image or not
seqdata.flags.HF_absorption_image.TakeDarkImage = 1;

%Load in the absorption imaging parameters.
seqdata.params.HF_absorption_image = Load_HF_Absorption_Image_Parameters(); 

seqdata.times.tof_end = calctime(curtime,seqdata.params.HF_absorption_image.timings.tof); %Also append the time that the image is actually taken to the time list


%% Shorthand for certain parameters and flags

%Shorthand for convenience
flags = seqdata.flags.HF_absorption_image;
params = seqdata.params.HF_absorption_image;

% Display the imaging flags (conditions of imaging)
str=['High Field Absorption Imaging'];

% K Probe Detuning 
K_detuning = params.detunings.KTrap;

%% Turn off magnetic fields long after TOF is complete
%Turns off the FB, shims and QP coils 50 ms after TOF

% Turn off feshbach sometime after the time of flight
clear('ramp');
ramp.fesh_ramptime = 100; 
ramp.fesh_ramp_delay = 0;
ramp.fesh_final = 0;
ramp.settling_time = 10;
ramp_bias_fields(calctime(curtime,params.timings.tof+50), ramp);

% Turn off the shims sometime after the time of flight
setAnalogChannel(calctime(curtime,params.timings.tof+50),'X Shim',0,3);
setAnalogChannel(calctime(curtime,params.timings.tof+50),'Y Shim',0,4);
setAnalogChannel(calctime(curtime,params.timings.tof+50),'Z Shim',0,3);

% Turn off feshbach sometime after the time of flight (used to be 100ms after,
% changed to 50 ms to match FB and shims)
ramp_time = 100;
AnalogFuncTo(calctime(curtime,params.timings.tof+50),'Coil 16',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time,ramp_time,0,1);    
AnalogFuncTo(calctime(curtime,params.timings.tof+50),'Coil 15',...
    @(t,tt,y1,y2)(ramp_linear(t,tt,y1,y2)),ramp_time,ramp_time,0,1);   
   

%% Prepare detunings

%K High Field Imaging
% Set the detunings for the High Field imaging

% Set Trap FM detuning for FB field
offset_list = [1.5];
    offset = getScanParameter(offset_list,...
        seqdata.scancycle,seqdata.randcyclelist,'HF_K_FM_offset','MHz');

setAnalogChannel(calctime(curtime,params.timings.tof-params.timings.k_detuning_shift_time),...
        'K Trap FM',K_detuning+(seqdata.params.FB_imaging_value-190)*0.675*2+offset);

if (flags.Attractive)
    if seqdata.flags.lattice
        HF_prob_freq = params.detunings.attractive_lattice;
    else
        HF_prob_freq =  params.detunings.attractive_xdt;
    end
else
    if seqdata.flags.lattice
        HF_prob_freq = params.detunings.repulsive_lattice;
    else
        HF_prob_freq =  params.detunings.repulsive_xdt;
    end
end

%% Program Rigol for the HF IMAGING AOM

% Frequency of rigol is based on the relative shift
freq = (120+HF_prob_freq)*1E6;

% Power in HF imaging beam  
pow = params.powers.HF_probe;

% Rigol Channel 2 (-9 HF high field imaging)
ch2=struct;
ch2.STATE='ON';
ch2.AMPLITUDE=pow;
ch2.FREQUENCY=freq;   

% Rigol address # 
addr=6;     
programRigol(addr,[],ch2);     

%% Pre-Absorption Shutter Preperation

%open shutter
setDigitalChannel(calctime(curtime,-5 + params.timings.tof),'High Field Shutter',1);
%Close shutter much later
setDigitalChannel(calctime(curtime,500),'High Field Shutter',0);


%% Take the absorption images

% Update curtime to the imaging time (add the tof).
curtime = calctime(curtime,params.timings.tof);

tD_list = [-20];-20;
tD=getScanParameter(tD_list,seqdata.scancycle,...
    seqdata.randcyclelist,'pixel_delay','us');

% Take the first absorption image with atoms

params.isProgrammedSRS = 0;
params=do_HF_abs_pulses(curtime,params,flags,tD*1e-3);

% Wait 200 ms for all traces of atoms to be gone 
% RHYS - could be shorter
curtime = calctime(curtime,200); 

% Take the second absorption image without atoms
do_HF_abs_pulses(curtime,params,flags,tD*1e-3);

%% Dark Image

if flags.TakeDarkImage
    curtime = calctime(curtime,250);
    DigitalPulse(curtime,'PixelFly Trigger',1,1); 
    curtime = calctime(curtime,100);
end

%% Add parameters to output file and timeout of function
addOutputParam('tof',params.timings.tof);
addOutputParam('ktrap_det',K_detuning);
addOutputParam('kHF_img_det',HF_prob_freq);

timeout=curtime;
end

