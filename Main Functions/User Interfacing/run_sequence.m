%------
%Author: David McKay
%Created: July 2009
%Summary: This function runs the current sequence
%------
function run_sequence(fhandle)

%fhandle is the function to call when the sequence is done running on the
%ADWIN

%if no function handle was specified
if nargin<1
    fhandle = @default_seq_stopped;
end

global seqdata;
global adwin_booted;
global adwinprocessnum;
global wait_timer;
global adwin_process_timer;
global adwin_connected;

%check the adwin has been booted and the process loaded
if ((adwinprocessnum<0)||(~adwin_booted))&& adwin_connected
    error('ADWIN not booted or the process loaded. Cannot Run the sequence');
end

%check if the sequence has been loaded
if ~(seqdata.seqloaded==1)
    error('Sequence has not been loaded onto the ADWIN');
end


%create a timer that wakes up once the cycle is over
adwin_process_timer = timer('TimerFcn',fhandle,'StartDelay',round(seqdata.sequencetime*1000)/1000,...
    'Name','adwin_proces_timerCB');

%run the process; keep this block up high in this function, in order not to
%delay the start of the process.
disp('Starting the ADWIN Process');
if adwin_connected
    seqdata.seqstart = now; % in days    
    
    Start_Process(adwinprocessnum);
    
    %start the process timer
    start(adwin_process_timer);
    % @@ Add GPIB/VISA reprogramming timers here
    
    windows = get(0,'Children');
    lsfigure = windows(strcmpi(get(windows,'Name'),'Lattice Sequencer'));
    buildmon = findobj(lsfigure,'tag','buildmon');
    set(buildmon,'String','process started');
else
    error('ADWIN not connected!')
end



% % Build seqdata.history here (local)
AddToSeqHistory(seqdata,now);

% update flag monitor
if isfield(seqdata,'flags')
    if ~isempty(seqdata.outputparams)
        for i = 1:length(seqdata.outputparams)
            %the first element is a string and the second element is a number
            monitorstring{i} = sprintf('%s: %g \n',seqdata.outputparams{i}{1},seqdata.outputparams{i}{2});
        end
        FlagsGUI(seqdata.flags,monitorstring)    
    else
        FlagsGUI(seqdata.flags)
    end
end


%output parameters to file, use the function handle as the file name
% Feb2015(ST): moved to after starting the process in order not to delay
% things.
CreateOutputParamFile('latticeseqparams',func2str(fhandle{4}));

%update communication files (S. Trotzky, 2013-11)
disp('Saving seqdata to communication files.')
% try
%     ThrowSequenceData(seqdata)
% catch
% end