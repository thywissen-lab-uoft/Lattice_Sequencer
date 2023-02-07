function morning_diagnostics
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
    warning('open the GUI first');
    return
end

data=guidata(fig);

%% NEED TO FIGURE OUT HOW EVENT QUEIING WORKS
%% RF1B K 

camOpts = struct;
camOpts.saveDirName = 'K RF1B stats';

funcs = {@main_settings,@modseq_RF1BK,@main_sequence};

for kk=1:20
    seqdata.scancycle = 1;
    runSequence(funcs);   
    disp(camOpts.saveDirName);
   % run cam with camOpts
end

%% XDT DFG

camOpts = struct;
camOpts.saveDirName = 'dfg stats';

funcs = {@main_settings,@modseq_dfg_mix,@main_sequence};

for kk=1:20
    seqdata.scancycle = 1;
    runSequence(funcs);   
    disp(camOpts.saveDirName);
  % run cam with camOpts
end

end

