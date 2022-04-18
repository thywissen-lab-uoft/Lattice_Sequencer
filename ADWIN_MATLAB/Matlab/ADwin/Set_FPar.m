%Set_FPar  sets a global variable FPAR to a specified single value.
%
%  Syntax:  Set_FPar (Index, Value)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable FPAR_1 ...
%                    FPAR_80.
%    Value           Value of data type single to be set for the variable.
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    Set_FPar always transfers a 32-bit float value even though FPAR may have
%    64-bit precision.
%
%  Example:
%    % set variable FPAR_6 to 34.7
%    ret_val = Set_FPar(6, 34.7);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
