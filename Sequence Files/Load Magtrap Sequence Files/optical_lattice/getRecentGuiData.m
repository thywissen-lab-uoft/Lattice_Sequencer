    function old_data = getRecentGuiData(N)

disp('Acquiring most recent GUI data');
if nargin == 0
   N = 10; 
end

global seqdata

if ~isfield(seqdata,'IxonGUIAnalayisHistoryDirectory') || ~exist(seqdata.IxonGUIAnalayisHistoryDirectory,'dir')
    warning('No feedback directory to run on');
    return;    
end

names = dir([seqdata.IxonGUIAnalayisHistoryDirectory filesep '*.mat']);
names = {names.name};
names = flip(sort(names)); % Sort by most recent     

if length(names)>=N
names = [names(1:N)];              
end
old_data = {};

    for n = 1:length(names) 
        warning off        
        data = load(fullfile(seqdata.IxonGUIAnalayisHistoryDirectory,names{n}));
        warning on
        old_data{n}=data;   
    end

    tt = zeros(1,length(old_data));
    for n = 1:length(old_data)
        tt(n) = datenum(old_data{n}.Date);
    end
    
    [~,inds]=sort(tt,'descend');
    old_data=old_data(inds);
    
%     for n = 1:length(old_data)
%        disp(old_data{n}.FileName); 
%     end

end

