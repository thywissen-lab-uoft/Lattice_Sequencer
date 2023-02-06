function runSequence(fncs)
global seqdata
global adwinprocessnum
%% Find the GUI
figName = 'Main GUI';

figs = get(groot,'Children');
fig = [];
for i = 1:length(figs)
    if isequal(figs(i).Name,figName)        
        fig = figs(i);
    end
end

if isempty(fig)
    fig=mainGUI;
end

data=guidata(fig);

if isequal(data.adwinTimer.Running, 'on')
    warning('Cannot run sequence while existing sequence is running');
   return; 
end

if isequal(data.waitTimer.Running, 'on')
    warning('Cannot run sequence while waiting');
   return; 
end

%%

data.cycleTbl.Data=seqdata.scancycle;

%% Compile Code
compile(fncs);

if ~seqdata.seqcalculated
   warning('Cannot run because compliation failed');
   return
end

%% Load the adwin
isGood = 1;

% Update GUI
data.Status.String = ['loading adwin'];
data.Status.ForegroundColor = [220,88,42]/255;
    
if ~seqdata.debugMode
    % Try Loading
    try
        load_sequence;
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'))
        isGood = 0;
    end
end

% Quit if bad
if ~isGood
    return;
end

%% Make Control File
% Update GUI
data.Status.String = ['adwin loaded'];
data.Status.ForegroundColor = [17,59,8]/255;

% Make control file
if ~seqdata.debugMode    
    makeControlFile;
end

%% Start the Adwin

% Run Adwin
data.Status.String = ['starting adwin'];
data.Status.ForegroundColor = [17,59,8]/255;

if ~seqdata.debugMode
    try
        Start_Process(adwinprocessnum);
    catch ME
        warning(getReport(ME,'extended','hyperlinks','on'))
        data.Status.String = ['ADWIN RUN ERROR'];
        data.Status.ForegroundColor = 'r';
        return
    end
end

%% Start adwim timer

% Start Timer
data.Status.String = ['adwin is running'];
data.Status.ForegroundColor = 'r';
start(data.adwinTimer);   


end

