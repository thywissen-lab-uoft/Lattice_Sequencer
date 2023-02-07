function initSequenceQueue

global sequence_queue;
global sequence_queue_checker;
global seqdata

%% Find the GUI
figs = get(groot,'Children');
fig = [];
for i = 1:length(figs)
    if isequal(figs(i).UserData,'sequencer_gui')        
        fig = figs(i);
    end
end

if isempty(fig)
    fig=mainGUI;
end

%%

% el = addlistener(hSource,EventName,callback)
% Should probably just make a listener objecet that waits for cycle to
% finish

sequence_queue = struct(...
    'SequenceFunctions',{},...
    'ScanCycle',{},...
    'Options',{});

%%
delete(timerfind('Name','sequencer_queue_timer'));

% The adwin progress timer object
sequence_queue_checker=timer('Name','sequencer_queue_timer',...
    'ExecutionMode','FixedSpacing',...
    'TimerFcn',@update,'Period',.1,...
    'StopFcn',@b,'StartFcn',@a);

sequence_queue_checker.UserData = fig;

    function a(src,evt)
       disp('beginning batch run'); 
    end

    function update(src,evt)
        data = guidata(src.UserData); 
        if isequal(data.adwinTimer.Runnin,'on')
            return;
        end
        pause(0.05);
        
        if isequal(data.waitTimer.Running,'on')
            return            
        end
        
        if isempty(sequence_queue)
            stop(src);
            return;
        end
        
        cmd = sequence_queue(1);
        sequence_queue(1)=[];
        
        funcs = cmd.SequenceFunctions;
        opts = cmd.Options;
        seqdata.scancycle = cmd.ScanCycle;        
        tExecute = runSequence(funcs,opts);    
    end

    function b(src,evt)
       disp('batch run complete'); 
    end
    
end

