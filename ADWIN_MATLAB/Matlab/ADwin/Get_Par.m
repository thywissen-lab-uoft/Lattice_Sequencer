%Get_Par  returns the value of a global variable PAR.
%
%  Syntax:  Get_Par (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable PAR_1 ... PAR_80.
%    return value    <>255: Current value of the variable, data type int32.
%                    255: Error
%
%  Example:
%    % Read value of the LONG variable PAR_1
%    x = Get_Par(1);
%
%  See also GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, GET_FPAR.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
