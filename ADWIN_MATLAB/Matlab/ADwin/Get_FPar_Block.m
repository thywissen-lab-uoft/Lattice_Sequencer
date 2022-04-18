%Get_FPar_Block  transfers a specified number of consecutive global variables
%  FPAR into a row vector (data type single).
%
%  Syntax:  Get_FPar_Block (StartIndex, Count)
%
%  Parameters:
%    StartIndex      Number (1 ... 80) of the first global variable FPAR_1...
%                    FPAR_80 to be transferred.
%    Count           Number (>=1) of variables to be transferred.
%    Return value    Row vector with transferred values of data type single.
%
%  Example:
%    %Read values of variables PAR_10 ... PAR_34 and store in a row vector v:
%    v = Get_FPar_Block(10,25);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
