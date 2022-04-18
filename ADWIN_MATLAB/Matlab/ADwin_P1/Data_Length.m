function y = Data_Length(DataNo)
%Data_Length  returns the length of an ADbasic array, that is the number of
%  elements.
%
%  Syntax:  Data_Length (DataNo)
%
%  Parameters:
%    DataNo          Array number (1...200).
%    return value    >0: Declared length of the array (= number of elements)
%                    0: Error - Array is not declared.
%                    -1: Other error.
%
%  Notes:
%    To determine the length of a string in a DATA array of the type STRING you
%    use the instruction String_Length.
%
%  Example:
%    %In ADbasic DATA_2 is dimensioned as:
%    DIM DATA_2[2000] AS LONG
%    
%    %In MATLAB you will have the length of the array DATA_2:
%    >> Data_Length(2)
%    ans =
%        2000
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(100, DataNo);



