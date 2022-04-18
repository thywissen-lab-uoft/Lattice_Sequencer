%Get_Par_Block  transfers a specified number of global LONG variables into a
%  row vector.
%
%  Syntax:  Get_Par_Block (StartIndex, Count)
%
%  Parameters:
%    StartIndex      Number (1 ... 80) of the first global LONG variable PAR_1
%                    ... PAR_80 to be transferred.
%    Count           Number (>=1) of the LONG variables to be transferred.
%    Return value    Row vector with transferred values
%
%  Example:
%    %Read the parameters PAR_10...PAR_39 and write the values to the row
%    %vector v:
%    v=Get_Par_Block(10, 30)
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_ALL, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $