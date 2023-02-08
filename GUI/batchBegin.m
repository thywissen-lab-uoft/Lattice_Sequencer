function batchBegin(sequence_queue_index)
global sequence_queue;
global sequence_queue_index;
global seqdata
global sw
global batch_listener

if nargin == 0
    sequence_queue_index = 1;   
end
%% Find the GUI
figs = get(groot,'Children');
fig = [];
for i = 1:length(figs)
    if isequal(figs(i).UserData,'sequencer_gui')        
        fig = figs(i);
    end
end

if isempty(fig)
    warning('cannot run this without the GUI open');
    return;
end

%% Create listener handle
d=guidata(fig);

sw = d.SequencerWatcher;
batch_listener = listener(sw,'CycleComplete',@(src,evt) batchIter);

batchIter;

function batchIter(src,evt)        
    cmd = sequence_queue(sequence_queue_index);  
    
    funcs = cmd.SequenceFunctions;
    opts = cmd.Options;
    seqdata.scancycle = cmd.ScanCycle;        
    runSequence(funcs,opts);    
    sequence_queue_index = sequence_queue_index+1;
    
    if sequence_queue_index > length(sequence_queue)
        delete(batch_listener);
    end
end

end

