function compile(fncs)

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

%%
data.StatusSub.String = '';

%% Initialize Sequence    
data.Status.String = 'initializing sequence ...';
data.Status.ForegroundColor = 'k';

start_new_sequence;
initialize_channels;
curtime = 0;
%% Update GUI Text
mystr =[];

for kk = 1:length(fncs)
    mystr = [mystr '@' func2str(fncs{kk}) ','];
end

mystr(end)=[];
data.SequenceText.String=mystr;

%% Run Each portion
isGood = 1;

for kk = 1:length(fncs)
    data.Status.String = ['running @' func2str(fncs{kk})];
    data.Status.ForegroundColor = [220,88,42]/255;
    pause(.2)
    try
        fncs{kk}(curtime);    
    catch ME
        warning( getReport( ME, 'extended', 'hyperlinks', 'on' ) )
        isGood = 0;
        break
    end
end

if ~isGood
    data.Status.String = ['sequence error'];
    data.Status.ForegroundColor = 'r';
    return
end

data.Status.String = ['sequence evaluated'];
data.Status.ForegroundColor = [17,59,8]/255;
pause(.1)

%% Calc sequence
data.Status.String = ['converting sequence into hardware commands'];
data.Status.ForegroundColor = [220,88,42]/255;

pause(.1)
calc_sequence;    
pause(.1)
data.Status.String = ['sequence calulated'];
data.Status.ForegroundColor = [17,59,8]/255;

end

