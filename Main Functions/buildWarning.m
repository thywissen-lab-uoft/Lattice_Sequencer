function buildWarning(source, msgstring, aserror)
%
%   buildWarning(source, msgstring, aserror)
%   buildWarning(source, msgstring) = buildWarning(source, msgstring, 0)
%
% Throws either an error or a warning message during sequence building
% -- S. Trotzky, March 2014
%

    if nargin == 2;
        aserror = 0;
    elseif nargin ~=3
        error('Wrong number of input arguments');
    end

    if (aserror) % throw an error; source is evident in command window
        error(msgstring);
    else % throw a non-interupting warning
        disp([source '::warning -- ' msgstring]);
    end

end