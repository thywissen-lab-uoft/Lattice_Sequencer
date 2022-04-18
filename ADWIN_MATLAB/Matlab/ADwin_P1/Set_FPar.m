function y = Set_FPar(Index, Value)
%Set_FPar  sets a global FLOAT variable to a specified value.
%
%  Syntax:  Set_FPar (Index, Value)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global FLOAT variable FPAR_1 ...
%                    FPAR_80.
%    Value           Value to be set for the FLOAT variable.
%    Return value    <>255: OK
%                    255: Error
%
%  Example:
%    % Set Float-Variable FPAR_6 to 34.7
%    ret_val = Set_FPar(6, 34.7)
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_ALL, GET_FPAR_ALL, GET_PAR_BLOCK, GET_FPAR_BLOCK, SET_PAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(34,1100+Index, Value);



