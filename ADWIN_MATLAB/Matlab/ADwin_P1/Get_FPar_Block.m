function v = Get_FPar_Block(Startindex, Count)
%Get_FPar_Block  transfers a number of global FLOAT variables, which is to be
%  indicated, into a row vector.
%
%  Syntax:  Get_FPar_Block (StartIndex, Count)
%
%  Parameters:
%    StartIndex      Number (1 ... 80) of the first global FLOAT
%                    variableFPAR_1... FPAR_80 to be transferred.
%    Count           Number (>=1) of the FLOAT variables to be transferred.
%    Return value    Row vector with transferred values.
%
%  Example:
%    %Read the values of the variables PAR_10 ... PAR_34 and store in a row
%    %vector v:
%    v = Get_FPar_Block(10,25)
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_ALL, GET_FPAR_ALL, GET_PAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

v=ADlab(353, Startindex, Count);



