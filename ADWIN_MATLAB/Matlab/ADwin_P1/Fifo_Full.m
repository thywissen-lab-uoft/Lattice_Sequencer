function y = Fifo_Full(FifoNo)
%Fifo_Full  returns the number of used elements of a FIFO array.
%
%  Syntax:  Fifo_Full (FifoNo)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Return value    <>255: Number of the used elements in the FIFO array.
%                    255: Error
%
%  Example:
%    %In ADbasic DATA_12 is dimensioned as:
%    DIM DATA_12[2500] AS FLOAT AS FIFO
%    
%    %In MATLAB you will get the number of used elements in DATA_12:
%    >> Fifo_Full(12)
%    ans =
%        2105
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

y=ADlab(112, FifoNo);



