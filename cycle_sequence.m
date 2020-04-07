%------
%Author: David McKay
%Created: July 2009
%Summary: This is the main function for running sequences
%------

function cycle_sequence(fhandle,waittime,targettime,startcycle,endcycle)

%fhandle: handle to the sequence file to run
%waittime: time to wait between cycles (the first cycle is run
%immediately). This is in the time units specified in
%'LatticeSequencerInitialize'
%startcycle: the start cycle number
%endcycle: the end cycle number. If this is the same as startcycle then
%just one cycle is run (no wait after). If end cycle is -1 then the cycles
%run continuously.
%
% Feb2015(ST): added a target cycle period "targettime" to ensure constant
% cycle lengths

%NOTE: If you want to run a single sequence, just set waittime=0 and
%startcycle=x, endcycle=x (or leave off endcycle)

%if startcycle and endcycle are not specified than set both to 1.
%if endcycle is not specified than set it to startcycle.
    if nargin<2
        waittime = 0;
        startcycle = 1;
        endcycle = 1;
    elseif nargin<3
        startcycle = 1;
        endcycle = 1;
    elseif nargin<4
        endcycle=startcycle;
    end

    if startcycle<1
        error('Cycle must be a positive number');
    end

    if waittime<0
        error('Wait time must be a positive number');
    end



%check if a process is already running or waiting between cycles
    curstatus = getRunStatus();

    if curstatus~=1
        error('Please stop the current process before starting a new process.');
    end

global docycle;
global seqdata;

    if isempty(seqdata)
        LatticeSequencerInitialize();
    end

%set the cycle counter to zero
    seqdata.cyclecounter = 0;

%create the randomized list for random sweeping except if we are doing a
%continuous run
% Apr 2014: included a check for the scan checkbox
    scanobj = findobj(gcbf,'tag','scan');
    if ( get(scanobj,'Value') )
        if isfield(seqdata,'multiscannum')
            seqdata = rmfield(seqdata,'multiscannum');
        end %Feb-2017
        
%         seqdata.multiscannum = [];%Feb-2017
        if isfield(seqdata,'multiscanlist')
            seqdata = rmfield(seqdata,'multiscanlist');
        end %Feb-2017
        
        seqdata.scancycle = 0;
        seqdata.doscan = 1;
        scantxt = findobj(gcbf,'tag','scanmax');
        scanmax = str2double(get(scantxt,'String'));
        seqdata.randcyclelist = rand(1,scanmax);
        [void,seqdata.randcyclelist] = sort(seqdata.randcyclelist);
    else
        seqdata.scancycle = 1;
        seqdata.doscan = 0;
        seqdata.randcyclelist = 1;
    end

% this used to be the code building the randomized index list
%     if (endcycle~=-1)
%         %seqdata.randcyclelist = randperm(endcycle-startcycle+1)+(startcycle-1);
%         seqdata.randcyclelist = [startcycle (randperm(endcycle-startcycle)+(startcycle-1))];
%     else
%         seqdata.randcyclelist = startcycle;
%     end

%this can be set to 0 by other functions (ie. a stop process) to break the
%cycle
docycle = 1;

curcycle = startcycle;

%start the find sequence
cycle_sequence_callback(0,0,curcycle,endcycle,fhandle,waittime,targettime,1);


end