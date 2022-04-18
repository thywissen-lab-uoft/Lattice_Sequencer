%Get_FPar_All_Double  transfers all global variables FPAR_1...FPAR_80 into a row
%  vector (data type double).
%
%  Syntax:  Get_FPar_All_Double ()
%
%  Parameters:
%    Return value    Row vector with transferred values of data type double.
%
%  Notes:
%    Until T11, please note: floating-point values in the ADwin system have
%    32-bit precision. You should therefore display FPAR values only with single
%    precision to avoid misunderstandings. 
%
%  Example:
%    %Read the values of the variables PAR_1 ... PAR_80 and store in a row
%    %vector v:
%    v = Get_FPar_All_Double();
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
