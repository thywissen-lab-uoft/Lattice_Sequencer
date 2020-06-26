%------
%Author: Stefan trotzky
%Created: January 2015
%Summary: Saves a seqdata structure to the history
%------

function AddToSeqHistory(seqdata,timestamp) % seqdata is not a global variable here!

    historyfolder = 'C:\Documents and Settings\LatticeSequencerHistory';
    historyfile = ['LatticeSequence_' ...
        regexprep((regexprep(datestr(timestamp,31),':','-')),' ','_') '.mat'];
    histmax = 50;
    
    [path, filename, ext] = fileparts([historyfolder filesep historyfile]);
    
    if exist(path,'dir')
        
        % Clearing some fields to save space
        if isfield(seqdata,'chnum');seqdata=rmfield(seqdata,'chnum');end
        if isfield(seqdata,'chval');seqdata=rmfield(seqdata,'chval');end
        if isfield(seqdata,'numupdatelist');seqdata=rmfield(seqdata,'numupdatelist');end
        if isfield(seqdata,'updatelist');seqdata=rmfield(seqdata,'updatelist');end
        if isfield(seqdata,'outputparams');seqdata=rmfield(seqdata,'outputparams');end
        if isfield(seqdata,'scopetriggers');seqdata=rmfield(seqdata,'scopetriggers');end
        if isfield(seqdata,'params')
            if isfield(seqdata.params,'analogch');seqdata.params=rmfield(seqdata.params,'analogch');end
            if isfield(seqdata.params,'digitalch');seqdata.params=rmfield(seqdata.params,'digitalch');end
        end
        
        save([historyfolder filesep historyfile],'seqdata');
        filelist = dir([historyfolder filesep strtok(filename,'_') '*' ext]);
        
        if ( length(filelist) > histmax )
            dates = zeros(length(filelist));
            for j = 1:length(filelist)
                dates(j) = datenum(filelist(j).date);
            end
            [void,idx] = sort(dates(:,1));
            idx(end-histmax+1:end) = []; % keep histmax newest files
            for j=1:length(idx)
                delete([path filesep filelist(idx(j)).name]) % remove all others
            end
        end
            
    else
        disp('AddToSeqHistory::warning -- History folder does not exist (doing nothing)!')
    end
   
    
end