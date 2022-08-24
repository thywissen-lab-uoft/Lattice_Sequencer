function f_osc_out=calcOffsetLockFreq(detuning,type)
% Author : CJ Fujiwara
% Last Edited : 2022/08/23
%
% calcOffsetLockFreq.m
%
% This function converts a desired detuning of the Rb Trap laser and
% returns the corresponding frequency that should go into the offset lock
% (which is later multiplied by x32).
%
% The validity of this is only true for a given optical layout of the trap
% and repump laser system (AOMs and whatnots). So if you change that, these
% relationships will change.
%
%
% detuning - the desired detuning of the laser light on the atoms in MHz
% type - a character string referring to what light you wish to specify the
% detuning for. Type can have the following values :
%
%      MOT - the detuning is given for the MOT trap detuning
%      Probe32 - the detuning is given for the Probe beam relative to the
%      F=2 --> F=3 transition (ie. imaging)
%      Probe22 - the detuning is given for the Probe beam relative to the
%      F=2 --> F=2 transition (ie. optical pumping)
%
% This program merely calculates the correct frequency output of the
% DDS. This function should be used in conjunction with DDS_sweep to
% actually control the frequency (with the appropriate DDS_id).
%
% Funny quirk of this code, is that instead of solving for the oscillator
% frequency, which would be straightfoward.  We instead solve for it using
% a linear interpolant, this is because the author thinks it is easier for
% you to debug and understand and edit if the detunings are a function of the
% oscillator frequency (and not the other way around). To do so, we simply
% use the interp1 function.

% Ground state splitting of Rb in MHz
HF_S12_21 = 6.83468261090429*1e3;

% Excited state splitting of F=3 and F=2
HF_P32_32 = 266.650;

% Excited state splitting of F=2 and F=1
HF_P32_21 = 156.947;

% Excited state splitting of F=1 and F=0
HF_P32_10 = 72.218;

% MOT Trap single pass
MOTTrapSP = 109.8;

% MOT Repump single pass
MOTRepumpSP = 80.5;

% Probe Trap single pass
ProbeTrapSP = -131.6;

f_osc = linspace(150,300,1e3);

% Detuning of repump laser relative to 1->2'
detuning_repump = -HF_P32_21/2;

% Detuning of vescent trap laser relative to 2->3'
detuning_vescent = (detuning_repump-32*f_osc)-(-HF_S12_21+HF_P32_32);


detuning_trap_MOT = detuning_vescent + MOTTrapSP;

detuning_trap_probe_32 = detuning_vescent + ProbeTrapSP;

detuning_trap_probe_22 = detuning_vescent + ProbeTrapSP + HF_P32_32;


switch type
    case 'MOT'
        f_osc_out = interp1(detuning_trap_MOT,f_osc,detuning,'linear');        
    case 'Probe32'
        f_osc_out = interp1(detuning_trap_probe_32,f_osc,detuning,'linear');      
    case 'Probe22'        
        f_osc_out = interp1(detuning_trap_probe_22,f_osc,detuning,'linear');    
    otherwise
        error('You specified the wrong detuning type you fool!!');    
end



end

