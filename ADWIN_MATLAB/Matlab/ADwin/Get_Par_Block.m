%Get_Par_Block  transfers a specified number of consecutive global variables PAR
%  into a row vector (data type int32).
%
%  Syntax:  Get_Par_Block (StartIndex, Count)
%
%  Parameters:
%    StartIndex      Number (1 ... 80) of the first global variable PAR_1 ...
%                    PAR_80 to be transferred.
%    Count           Number (>=1) of values to be transferred.
%    Return value    Row vector with transferred values.
%
%  Example:
%    %Read values of variables PAR_10...PAR_39 and write the values to the row
%    %vector v:
%    v = Get_Par_Block(10, 30);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
