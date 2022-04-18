function y = Get_FPar(Index)
%Get_FPar  Get_Par returns the value of a global FLOAT variable.
%
%  Syntax:  Get_FPar (Index)
%
%  Parameters:
%    Index           Number (1 ... 80) of the global FLOAT variable FPAR_1 ...
%                    FPAR_80.
%    Return value    <>255: Current value of the variables
%                    255: Error
%
%  Example:
%    % Read the value of the FLOAT variable FPAR_56
%    ret_val = Get_FPar(56)
%
%  See also  GET_PAR, GET_PAR_ALL, GET_PAR_BLOCK, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(38,1100+Index);



