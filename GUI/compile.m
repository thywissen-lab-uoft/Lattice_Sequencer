function compile(funcs)

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

%% Initialize Sequence    
data.Status.String = 'initializing sequence ...';
data.Status.ForegroundColor = 'k';

start_new_sequence;
initialize_channels;
curtime = 0;

%% Update GUI Text
mystr =[];

for kk = 1:length(funcs)
    mystr = [mystr '@' func2str(funcs{kk}) ','];
end

mystr(end)=[];
data.SequenceText.String=mystr;

%% Run Each portion

%disp(repmat('-',1,60));
%disp('Compiling');
%disp(repmat('-',1,60));

initialize_channels();

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
        return
    end
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

%% Update scan var
updateScanVarText;

end

