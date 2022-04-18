function  v=Get_Fifo(FifoNo, Count)
%Get_Fifo  is obsolete, use GetFifo_Double instead.
%  Get_Fifo transfers FIFO data from a FIFO array to a row vector.
%
%  Syntax:  Get_Fifo(FifoNo, Count)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Count            Number (>=1) of elements to be transferred.
%    Return value    row vector with transferred values
%
%  Notes:
%    You should first use the function Fifo_Empty to check, how much used
%    elements the FIFO array has. If more data are read from the FIFO array
%    than used elements are given, the surplus data is erroneous.
%
%  Example:
%    %Query the number of used elements in the FIFO array DATA_12 and transfer
%    %200 values into the row vector v:
%    num_fifo = Fifo_Full(12);
%    if num_fifo >= 200
%     v = Get_Fifo(12, 200);
%    end
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

v=ADlab(110, FifoNo, Count);
