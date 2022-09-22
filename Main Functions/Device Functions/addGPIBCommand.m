function addGPIBCommand(addr, str, varargin)
%------
%Author: Stefan Trotzky
%Created: February 2014
%Summary: Adds a GPIB command string to seqdata.gpib{}
%
% addGPIBCommand(adress, command_string, options)
%
% Valid options (and their default values)
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
            disp([mename '::Unknown option ''' optnames{j} ''' !']);
            % error('Unknown option ''' optnames{j} ''' !'); 
        else
            opt.(optnames{j}) = optvalues{j};
        end
    end

    clear('varargin','optnames','optvalues');
    
end

%% Collect, check and add GPIB commands

if (str(end)~=';') && (str(end)~='?')
    % give warning if command is unterminated and terminate with ';'
    disp(['gpib::warning -- Command unterminated (' str '), adding '';''']);
    str = [str ';'];
end

if ~isfield(seqdata,'gpib')
    % create field gpib if it does not exist, yet.
    % add first command.
    seqdata.gpib{1} = sprintf(['%g#' str], addr);
else
    len = length(seqdata.gpib);
    addrs = zeros(1,len);

    % create array of existing primary addresses
    for j=1:length(seqdata.gpib);
        addrs(j) = str2double(seqdata.gpib{j}(1:(strfind(seqdata.gpib{j},'#')-1)));
    end

    idx = find(addrs==addr,1);        
    if isempty(idx);
        % add a new entry for non-existend primary address;
        seqdata.gpib{len+1} = sprintf(['%g#' str], addr);
    else
        switch lower(opt.Mode)
            case {'first'}                
                % not adding anything (since there already is an entry for
                % this adress). Instead comparing the new command string 
                % and the existing entry and throwing a warning if commands
                % are different.
                if ~strcmpi(sprintf(['%g#' str],addr), seqdata.gpib{idx})
                    buildWarning(mename, sprintf('Multiple programming at GPIB address %g ignored.',addr))
                end                
            case {'append'}
                
                % append command to existing list.
                if seqdata.gpib{idx}(end) == '?';
                    % if command list already includes a question, insert after
                    % last ';' or after '#'.
                    pos = strfind(seqdata.gpib{idx},';');
                    if isempty(pos)
                        pos = strfind(seqdata.gpib{idx},'#');
                    else
                        pos = pos(end);
                    end
                    seqdata.gpib{idx} = [seqdata.gpib{idx}(1:pos) str seqdata.gpib{idx}((pos+1):end)];
                else
                    seqdata.gpib{idx} = [seqdata.gpib{idx} str];
                end
                
            case {'replace'}
                
                % replace existing command. No error thrown. Trusting that
                % users are careful about using this options.
                seqdata.gpib{idx} = str;
                
            otherwise
                
               error('Unknown mode! Check file documentation')
        end
    end
end

end

% addGPIBCommand(19,'FREQ 200kHz; FREQ?')