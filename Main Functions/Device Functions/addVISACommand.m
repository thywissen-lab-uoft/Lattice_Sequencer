function addVISACommand(addr, str, varargin)
%------
%Author: Stefan Trotzky
%Created: January 2015
%Summary: Adds a VISA command string to seqdata.visa{}
%Call: addVISACommand(addr, str, options)
%   string addr: the device name (can be found through NI VISA Interactive Control app), e.g.
%       'USB0::0x1AB1::0x0641::DG4E160900481::INSTR' for one of the Rigol 
%       signal generators connected via USB board 0.
%       A short dial option is available by entering an integer; the respective
%       names are listed in getVISADeviceName.m .
%   string str: the command string to be sent to the device (see devices
%       programming manual); multiple commands are separated by ';'.
%
%
% Valid options (and default values) are:
%
% Mode ('first') how to deal with the commands (take FIRST only, APPEND to existing, 
%                REPLACE no matter what); should be careful using REPLACE
%                or APPEND!
% Query ('on') whether to query devices or to remove queries from the list of commands
%                NOTE: this option still awaits programming (i.e. setting
%                it to 'off' will do nothing)!
%
% Last changes: 2015-02-20 (checked)
%------    

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

global seqdata;

% the number of necessary input arguments
narginfix = 2;

% Define valid options for this function and their default values here. 
opt = struct('Mode', 'first', ... how to deal with the commands (take FIRST only, APPEND to existing, REPLACE no matter what)
             'Query', 'on'... whether to query devices or to remove queries from the list of commands
             );
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal input are address and command string!')
elseif (nargin >= narginfix)
    % an appropriate number of input arguments -- check their validity
end

% checking the optional input arguments
if ( ~isempty(varargin) )
    optnames = {};
    optvalues = {};

    % if first optional arguments are structures, read in their fields first
    while ( isstruct(varargin{1}) )
        addnames = fieldnames(varargin{1});
        for j = 1:length(addnames)
            optnames{end+1} = addnames{j};
            optvalues{end+1} = varargin{1}.(addnames{j});
        end
        varargin = varargin(2:end); % remove first argument from list
        if ( isempty(varargin) ); break; end
    end 

    % check that there is an even number of remaining optional arguments
    if mod(length(varargin),2)
        error('Optional arguments must be given in pairs ...''name'',value,... !');
    else
        for j = 1:(length(varargin)/2)
            % check that the first part of each pair is a string
            if ~ischar(varargin{2*j-1})
                error('Optional arguments must be given in pairs ...''name'',value,... !');
            else
                optnames{end+1} = varargin{2*j-1};
                optvalues{end+1} = varargin{2*j};
            end
        end
    end

    % assigning values to optional arguments to fields of structure 'opt',
    % provided that these fields were initialized above
    for j =1:length(optnames)
        % check that the option is valid; i.e. defined as a field of the
        % structure opt. Make it an error if needed.
        if ~isfield(opt,optnames{j})
            logText([mename '::Unknown option ''' optnames{j} ''' !']);
            % error('Unknown option ''' optnames{j} ''' !'); 
        else
            opt.(optnames{j}) = optvalues{j};
        end
    end

    clear('varargin','optnames','optvalues');
    
end

%% Collect, check and add VISA commands

if (str(end)~=';') && (str(end)~='?')
    % give warning if command is unterminated and terminate with ';'
    buildWarning(mename, ['Command unterminated (' str '), adding '';''']);
    str = [str ';'];
end


if isnumeric(addr) % speed dial
    addr = getVISADeviceName(addr);
end

if ~isfield(seqdata,'visa')
    % create field visa if it does not exist, yet.
    % add first command.
    seqdata.visa{1} = [addr,'#',str];
else
    len = length(seqdata.visa);

    % create array of existing primary addresses
    for j=1:length(seqdata.visa);
        addrs{j} = seqdata.visa{j}(1:(strfind(seqdata.visa{j},'#')-1));
    end

    idx = find(strcmpi(addrs,addr));
    
    if isempty(idx);
        % add a new entry for non-existend primary address;
        seqdata.visa{len+1} = [addr,'#',str];
    elseif length(idx) > 1;
        buildWarning(mename, ['Found same address twice! This is impossible'])
        buildWarning(mename, ['Only use addVISACommand to change seqdata.visa! Doing nothing.']);
    else
        
        switch lower(opt.Mode)
            case {'first'}
                
                % not adding anything (since there already is an entry for
                % this adress). Instead comparing the new command string 
                % and the existing entry and throwing a warning if commands
                % are different.
                

                if ~strcmpi([addr '#' str], seqdata.visa{idx})
                    buildWarning(mename, ['Multiple programming at VISA address ' addr ' ignored.'])
                end
                
            case {'append'}
                
                % append command to existing list.
                if seqdata.visa{idx}(end) == '?';
                    % if command list already includes a question, insert after
                    % last ';' or after '#'.
                    pos = strfind(seqdata.visa{idx},';');
                    if isempty(pos)
                        pos = strfind(seqdata.visa{idx},'#');
                    else
                        pos = pos(end);
                    end
                    seqdata.visa{idx} = [seqdata.visa{idx}(1:pos) str seqdata.visa{idx}((pos+1):end)];
                else
                    seqdata.visa{idx} = [seqdata.visa{idx} str];
                end
                
            case {'replace'}
                
                % replace existing command. No error thrown. Trusting that
                % users are careful about using this options.
                seqdata.visa{idx} = str;
                
            otherwise
                
               error('Unknown mode! Check file documentation')
        end

    end
end

end
