function compile(funcs,doProgramDevices)
global seqdata

% Added to avoid multiple compile commands, not well tested (CF
% 2023/10/04);
if ~isfield(seqdata,'compiler_status')
    seqdata.compiler_status = 'idle';
end
if ~isequal(seqdata.compiler_status, 'idle')
    error('An additional compile command detected while compiling. Throwing error to prevent bad things. DONT DO THIS AGAIN YOU CLOD');
end
seqdata.compiler_status = 'busy';


if nargin == 1
    doProgramDevices = 1;
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
    fig=mainGUI;
end

data=guidata(fig);
data.VarText.String = '...';


% update sequencer file text
data.SequencerWatcher.updateSequenceFileText(seqdata.sequence_functions);


%% Run Sequence Functions
data.Status.String = 'initializing sequence ...';
data.Status.ForegroundColor = 'k';

start_new_sequence;
initialize_channels;
curtime = 0;
for kk = 1:length(funcs)
    data.Status.String = ['running @' func2str(funcs{kk})];
    data.Status.ForegroundColor = [220,88,42]/255;
    pause(.2)
    try
        curtime = funcs{kk}(curtime); 
    catch ME
        warning( getReport( ME, 'extended', 'hyperlinks', 'on' ) )
        data.Status.String = ['sequence error'];
        data.Status.ForegroundColor = 'r';
        seqdata.compiler_status = 'idle';
        return
    end
end

%% Calculate sequence
data.Status.String = ['converting sequence into hardware commands'];
data.Status.ForegroundColor = [220,88,42]/255;

pause(.1)
calc_sequence(doProgramDevices);    
pause(.1)
data.Status.String = ['sequence calulated'];
data.Status.ForegroundColor = [17,59,8]/255;

%% Update scan var
updateScanVarText;

%%
seqdata.compiler_status = 'idle';
end

