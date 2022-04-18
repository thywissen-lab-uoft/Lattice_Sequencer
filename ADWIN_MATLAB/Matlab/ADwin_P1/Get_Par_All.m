function v = Get_Par_All()
%Get_Par_All  transfers all global long variables into a row vector.
%
%  Syntax:  Get_Par_All ()
%
%  Parameters:
%    Return value    Row vector with transferred values (PAR_1...PAR_80) 
%
%  Example:
%    %Read the parameters PAR_1...PAR_80 and write the values to the row vector
%    %v:
%    v=Get_Par_All
%
%  See also  GET_PAR, GET_FPAR, GET_PAR_BLOCK, GET_FPAR_ALL, GET_FPAR_BLOCK, SET_PAR, SET_FPAR.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

v=ADlab(350);



