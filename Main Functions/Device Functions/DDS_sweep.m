%%This is a sample function for how to setup DDS sweeps

function timeout = DDS_sweep(timein,DDS_id,start_freq,end_freq,tt)

%%%INPUTS%%%%
%timein: time to run this process
%DDS_id: to identify which DDS to command (in case there are more than one)
%tt: time of the sweep
%freq_start: starting frequency of the sweep
%freq_end: ending frequency of the sweep
%%%%%%%%%%%%%

global seqdata;

%add a new sweep to the seqdata array
seqdata.numDDSsweeps = seqdata.numDDSsweeps + 1;

if DDS_id==1
    
    DigitalPulse(timein,18,0.1,1);
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:) = [DDS_id start_freq end_freq tt];

elseif DDS_id==2 %Formerly 6.8GHz microwave. Currently setting 4-pass frequency.

% Old commands for setting 6.8GHz microwave. 
%     DigitalPulse(timein,13,0.1,1);
%     seqdata.DDSsweeps(seqdata.numDDSsweeps,:) = [DDS_id start_freq/32 end_freq/32 tt];

    DigitalPulse(timein,13,0.1,1);
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:) = [DDS_id start_freq end_freq tt];
    
elseif DDS_id==3
    
    %USE A DIFFERENT TRIGGER HERE
    DigitalPulse(timein,13,0.1,1);
    seqdata.DDSsweeps(seqdata.numDDSsweeps,:) = [DDS_id start_freq end_freq tt];
    
else
    error('Invalid DDS ID');
end

%output the time **including** the sweep
timeout = calctime(timein,tt);

end