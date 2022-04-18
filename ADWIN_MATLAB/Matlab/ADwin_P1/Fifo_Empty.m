function y = Fifo_Empty(FifoNo)
%Fifo_Empty  returns the number of empty elements in a FIFO array.
%
%  Syntax:  Fifo_Empty (FifoNo)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Return value    <>255: Number of empty elements in the FIFO array.
%                    255: Error
%
%  Example:
%    %In ADbasic DATA_5 is dimensioned as:
%    DIM DATA_5[100] AS LONG AS FIFO
%    
%    %In MATLAB you will get the number of empty elements in DATA_5:
%    >> Fifo_Empty(5)
%    ans =
%        68
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(113, FifoNo);



