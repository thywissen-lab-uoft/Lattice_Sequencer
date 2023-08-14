function saveTraces(opts)

% This code saves the analog and digital channels to file

global seqdata

rootDir = 'Y:\_communication';

[aTraces, dTraces]=generateTraces(seqdata);

% Get the seqdata of the subset of channels
aTraces = aTraces(ismember({aTraces.name},opts.AnalogChannels));
dTraces = dTraces(ismember({dTraces.name},opts.DigitalChannels));

% Start Time in units of Adwin Cycles
t1 = opts.StartTime;

% End tine in units of Adwin Cycles
t2 = opts.StartTime + ceil(opts.Duration/seqdata.deltat);

% Truncate analog data and convert to seconds
for kk=1:length(aTraces)
    i1 = find(aTraces(kk).data(:,1)>=t1,1);
    i2 = find(aTraces(kk).data(:,1)>t2,1);
    if isempty(i2)
       i2 = size(aTraces(kk).data,1); 
    end
    aTraces(kk).data = aTraces(kk).data(i1:i2,:);   % truncate
    aTraces(kk).data(:,1) = aTraces(kk).data(:,1)*seqdata.deltat; % convert cycles to seconds
end


% Truncate digital data and convert to seconds
for kk=1:length(dTraces)
    i1 = find(dTraces(kk).data(:,1)>=t1,1);
    i2 = find(dTraces(kk).data(:,1)>t2,1);
    
    if isempty(i2)
       i2 = size(dTraces(kk).data,1); 
    end
    dTraces(kk).data = dTraces(kk).data(i1:i2,:);   % Truncate
    dTraces(kk).data(:,1) = dTraces(kk).data(:,1)*seqdata.deltat; % convert cycles to seconds
end

start_time = opts.StartTime*seqdata.deltat;
duration = opts.Duration;

% Save to File
save(fullfile(rootDir,opts.FileName),'aTraces','dTraces','start_time','duration');
end

