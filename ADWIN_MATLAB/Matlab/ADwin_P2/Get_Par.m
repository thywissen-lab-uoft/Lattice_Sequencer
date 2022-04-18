%Get_Par  returns the value of a global LONG variable.
%
%  Syntax:  Get_Par (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global LONG variable PAR_1 ...
%                    PAR_80.
%    return value    <>255: Current value of the variable
%                    255: Error
%
%  Example:
%    % Read the value of the LONG variable PAR_1
%    x = Get_Par(1);
%
%  See also  GET_FPAR, GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $