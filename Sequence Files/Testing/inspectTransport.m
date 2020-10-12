function inspectTransport
%INSPECTTRANSPORT Summary of this function goes here
%   Detailed explanation goes here
global seqdata


%% Original Transport
start_new_sequence();
seqdata.cycle = 1;
timein=0;
curtime = timein;
seqdata.flags.image_loc = 1; %0: `+-+MOT cell, 1: science chamber    
seqdata.flags.hor_transport_type = 1; 
seqdata.flags.ver_transport_type = 3; 
seqdata.flags.compress_QP = 1; % compress QP after transport

curtime = Transport_Cloud(curtime,seqdata.flags.hor_transport_type,seqdata.flags.ver_transport_type, seqdata.flags.image_loc);
[curtime, I_QP, I_kitt, V_QP, I_fesh] = ramp_QP_after_trans(curtime, seqdata.flags.compress_QP);

%%
[aTraces, dTraces]=generateTraces(seqdata);


end

