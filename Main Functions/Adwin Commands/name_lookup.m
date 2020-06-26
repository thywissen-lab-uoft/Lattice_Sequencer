function channel = name_lookup(name, isanalog)

% hands back the channel number for a given channel name. hands back -1 if
% channel name was not found or is ambiguous
% ST-2013-03-02

if ~exist('isanalog','var'); isanalog = 1; end % default: lookup analog channel

global seqdata;

if ( ischar(name) )
    if ( isanalog )
        idx = 1:length(seqdata.analognames);
        channel = idx(strcmpi(name,seqdata.analognames));
    else
        idx = 1:length(seqdata.dignames);
        channel = idx(strcmpi(name,seqdata.dignames));
    end
else
    channel = name;
end

if ( isempty(channel) || length(channel)>1 )
    channel = -1; % will provoke an error
    error(['Unknown channel name: ' name]);
end

end