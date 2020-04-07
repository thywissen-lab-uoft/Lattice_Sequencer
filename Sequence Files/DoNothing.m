function [timeout, varargout] = DoNothing(timein, par1, par2, varargin)
% [timeout, out1, out2] = DoNothing(timein, par1, par2, options)
% 
% This function does nothing. A template for lattice sequencer functions.
%
% A function always should read in a time (timein) and hand back a time
% (timeout). Next parameters (par1, par2, ...) should be necessary
% parameters for the function call. After that, options can be specified in
% the format DoSomething(..., 'opt1', value1, 'opt2', value2) as it is
% known e.g. from the plot function. Alternatively, one may hand over a
% structure of the form p.opt1 = value1; p.opt2 = value2. Handing over 
% multiple structures is possible, before adding individual options again
% via ... 'opt1', value1 ... . Note that if an optional parameter is handed
% over multiple times, its last set value will be used.
%
% As opposed to the necessary parameters, the optional ones have default 
% values (which can be empty), specified in the initialization of the 
% structure opt. Note that only initialized options will be read.
%
% At the beginning of this comment block, there should be a restatement of 
% the function's syntax; try 'help DoNothying' -- this should give all 
% information needed to use the function at a glance. Remove this header.
%
% One more convention: if the sequence structure seqdata is given to a 
% function as an input, it shall be the second input argument after timein.
%
% Started: 2015-02-09; Stefan Trotzky
% Last changes: 2015-02-10

%% constants and defaults

% know who you are.
[mename, mename] = fileparts(mfilename('fullpath'));

% if necessary, 'global seqdata' should go here.

% the number of necessary input arguments (including timein)
narginfix = 3;

% Define valid options for this function and their default values here. Use
% lower-case field names!
opt = struct('opt1', 0, ... this is option one and its default value is 0
             'opt2', 1, ... this is option two and its default value is 1
             'opt3', pi, ... this is option three
             'opt4', 'hello world' ... this is option four
             );
         
%% checking inputs (edit with care!)

% checking the necessary input arguments
if (nargin < narginfix)
    % too few input arguments; throw an error
    error('Minimal inputs are timein, par1 and par2!')
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
        if ~isfield(opt,lower(optnames{j}))
            disp([mename '::Unknown option ''' optnames{j} ''' !']);
            % error('Unknown option ''' optnames{j} ''' !'); 
        else
            opt.(lower(optnames{j})) = optvalues{j};
        end
    end

    clear('varargin','optnames','optvalues');
    
end

%% do nothing

% whatever the function does -- this one does nothing other than showing 
% the opt structure throwing out the optional arguments

opt

out = {opt.opt1, opt.opt2, opt.opt3, opt.opt4};

%% assigning outputs (edit with care!)

timeout = timein;

if ( nargout <= 1 )
    % only timeout has been requested (or not) -- doing nothing
elseif ( nargout > 1 )
    % check that there no more than the available output arguments are
    % requested
    if ((nargout-1) > length(out))
        error('Invalid number of output arguments!')
    else
        for j = 1:(nargout-1)
            varargout{j} = out{j};
        end
    end
end
    
end