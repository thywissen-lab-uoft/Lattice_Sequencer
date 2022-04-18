%Get_FPar  returns the single value of a global variable FPAR.
%
%  Syntax:  Get_FPar (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global variable FPAR_1 ...
%                    FPAR_80.
%    Return value    <>255: Current single value of the variable
%                    255: Error
%
%  Notes:
%    Since processor T12, FPAR variables in the ADwin system have 64-bit
%    precision. Nevertheless, Get_FPar will return a value of data type single.
%
%  Example:
%    % Read the value of the variable FPAR_56
%    ret_val = Get_FPar(56);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
