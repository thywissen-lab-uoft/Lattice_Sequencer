function [my_data] = grabRecentPCO(date_nums)

% The location where the analysis summary are saved from the PCO camera.
analysis_history_dir = 'Y:\_communication\analysis_history';

% Get all files in the directory
f0=java.io.File(analysis_history_dir);
f0=f0.list;
f = cell(f0);

% dir is slower for large number of files
% a=dir(analysis_history_dir);

% Only finds files with appropriate naming
wildcard_string = 'PixelflyImage_*.mat';
inds = arrayfun(@(a) isequal(a,{1}), ...
    regexp(f, regexptranslate('wildcard', wildcard_string)));
f=f(inds);

% Sort all the files
f=sort(f);

% Convert to numbers only
s = erase(erase(f,'.mat'),'PixelflyImage_');

% Find data

d=datenum(s,'yyyy-mm-dd_HH-MM-SS');

% Find extremal request dates
d1=min(date_nums);
d2=max(date_nums);

% Find files that start +-10 min of you beginning and ends dates
i1 = find(d>(d1-10/(24*60)),1);
i2 = find(d>(d2+10/(24*60)),1);

f = f(i1:i2);

all_data={};
for kk=1:length(f)
   data=load(fullfile(analysis_history_dir,f{kk}));  
   data=data.data;
   all_data{kk}=data;
   ExecutionDates(kk)=data.ExecutionDate;
end

clear my_data;
for kk=1:length(date_nums)
    i=find(date_nums(kk)==ExecutionDates,1);
    my_data{kk}=all_data{i};
end

end

