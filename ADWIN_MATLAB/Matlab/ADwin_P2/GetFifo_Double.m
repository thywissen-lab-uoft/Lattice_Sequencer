%GetFifo_Double  transfers FIFO data from a FIFO array to a row vector.
%
%  Syntax:  GetFifo_Double (FifoNo, Count)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Count           Number (>=1) of elements to be transferred.
%    Return value    Row vector with transferred values
%
%  Notes:
%    You should first use the function Fifo_Empty to check, how much used
%    elements the FIFO array has. If more data are read from the FIFO array
%    than used elements are given, the surplus data is erroneous.
%    The function GetFifo_Double replaces the function Get_Fifo which was used
%    with former driver versions.
%
%  Example:
%    %Query the number of used elements in the FIFO array DATA_12 and transfer
%    %200 values into the row vector v:
%    num_fifo = Fifo_Full(12);
%    if num_fifo >= 200
%     v = GetFifo_Double(12, 200);
%    end
%
%  See also  GETDATA_DOUBLE, SETDATA_DOUBLE, SETFIFO_DOUBLE, FIFO_FULL, FIFO_EMPTY, FIFO_CLEAR, DATA2FILE.
%
%  Support address:  support@ADwin.de
%  Homepage:         www.ADwin.de

%  Copyright (c) 1995-2011 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.01.03 $  $Date: November 8, 2011  16:00:00 $