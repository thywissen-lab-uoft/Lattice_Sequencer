%------
%Author: Dylan Jervis
%Created: April 2010
%Summary: This calls MOT_sequence at some detuning
%------ 

function timeout = call_MOT_sequence(timein)

global seqdata;

curtime = timein;

%list
detuning_list=[34:2:60.0];

%Create linear list
index=seqdata.cycle;

%Create Randomized list
%index=seqdata.randcyclelist(seqdata.cycle);

detuning = detuning_list(index)
addOutputParam('MOT detuning',detuning);

curtime = MOT_sequence(curtime,detuning);

timeout = curtime;
