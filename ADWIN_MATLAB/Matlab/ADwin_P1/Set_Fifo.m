function  v=Set_Fifo(FifoNo, Data)
%Set_Fifo  is obsolete, use SetFifo_Double instead.
%  Set_Fifo transfers data from a row vector into a FIFO array.
%
%  Syntax:  Set_Fifo(FifoNo, Vector)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Data            row vector with values to be transferred.
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    You should first use the function Fifo_Empty to check, if the FIFO array
%    has enough empty elements to hold all data of the row vector. If more
%    data are transferred into the FIFO array than empty elements are given,
%    the surplus data are overwritten and are definitively lost.
%
%  Example:
%    %Check FIFO array DATA_12 for empty elements and transfer all elements of
%    %the row vector vector into the FIFO array:
%    num_fifo = Fifo_Empty(12);
%    num_vector = length(vector);
%    if num_fifo >= num_vector
%     Set_Fifo(12, vector);
%    end
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, GETFIFO_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2005 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 2.01.00 $  $Date: 24-05-06  16:00:00 $

v=ADlab(111, FifoNo, Data);
