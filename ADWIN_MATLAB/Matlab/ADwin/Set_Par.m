%Set_Par  sets a global variable PAR to the specified value.
%
%  Syntax:  Set_Par (Index, Value)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable PAR_1 ... PAR_80.
%    Value           Value to be set for the LONG variable.
%    Return value    <>255: OK
%                    255: Error
%
%  Example:
%    % Set LONG variable PAR_1 to 2000
%    ret_val = Set_Par(1,2000);
%
%  See also GET_PAR, GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_FPAR.
%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
