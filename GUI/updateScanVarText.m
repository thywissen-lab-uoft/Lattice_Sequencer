function updateScanVarText

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

data=guidata(fig);

    if isfield(seqdata,'variables') && ~isempty(seqdata.variables)
       vars = fieldnames(seqdata.variables);
       inds=[];

       % Find variables that have multiple entries
       for kk=1:length(vars)
          if length(seqdata.variables.(vars{kk}))>1
             inds(end+1) = kk; 
          end
       end

       if isempty(inds)
           str = 'no scan variable detected';
       else
           % Make string descriptor based on variables scan
           str = '';
           for kk=1:length(inds)
              str=[str vars{kk} '(' ...
                  num2str(length(seqdata.variables.(vars{kk})))...
                  ')'];
           end
       end

       data.VarText.String = str;
    end           
end