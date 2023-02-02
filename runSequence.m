function runSequence(fncs)
global seqdata
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

%% Compile Code
compile(fncs);

if ~seqdata.seqcalculated
   warning('Cannot run because compliation failed');
   return
end

%% Load the adwin
isGood = 1;
doDebug = 1;

% Update GUI
data.Status.String = ['loading adwin'];
data.Status.ForegroundColor = [220,88,42]/255;
    
% Try Loading
try
    load_sequence;
catch ME
    warning(getReport(ME,'extended','hyperlinks','on'))
    isGood = 0;
end

% Quit if bad
if ~doDebug && ~isGood
    return;
end


% Update GUI
data.Status.String = ['adwin loaded'];
data.Status.ForegroundColor = [17,59,8]/255;

% Make control file
if ~doDebug
    makeControlFile;
end

% Run Adwin
data.Status.String = ['starting adwin'];
data.Status.ForegroundColor = [17,59,8]/255;
try
    Start_Process(adwinprocessnum);
end

% Start Timer
data.Status.String = ['adwin is running'];
data.Status.ForegroundColor = 'r';
start(data.timeAdwin);   


end

