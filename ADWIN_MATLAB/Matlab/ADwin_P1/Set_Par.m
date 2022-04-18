function y = Set_Par(Index, Value)
%Set_Par  sets a global LONG variable to the specified value.
%
%  Syntax:  Set_Par (Index, Value)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global LONG variable PAR_1 ...
%                    PAR_80.
%    Value           Value to be set for the LONG variable.
%    Return value    <>255: OK
%                    255: Error
%
%  Example:
%    % Set LONG variable PAR_1 to 2000
%    ret_val = Set_Par(1,2000);
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_ALL, GET_FPAR_ALL, GET_PAR_BLOCK, GET_FPAR_BLOCK, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(34,1000+Index, Value);



