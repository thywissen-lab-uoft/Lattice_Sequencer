function [data] = grabRecentPCO(date_nums)

% The location where the analysis summary are saved from the PCO camera.
analysis_history_dir = 'Y:\_communication\analysis_history';

% Get all files in the directory
f0=java.io.File(analysis_history_dir);
f0=f0.list;

% Only finds files with appropriate naming
wildcard_string = 'PixelflyImage_*.mat';
inds = arrayfun(@(a) isequal(a,{1}), ...
    regexp(a, regexptranslate('wildcard', wildcard_string)));
f0=f0(inds);

% Sort all the files
f0=sort(f0);

% Convert to numbers only
s0 = erase(erase(f0,'.mat'),'PixelflyImage');

% Find data
d=datenum(s0,'yyyy-mm-dd_HH-MM-SS');

% Find extremal request dates
d1=min(date_nums);
d2=max(date_nums);

% Find files that start +-10 min of you beginning and ends dates
i1 = find(d>(d1-10/(24*60)),1);
i2 = find(d>(d2+10/(24*60)),1);

f0 = f0(i1:i2);

end

