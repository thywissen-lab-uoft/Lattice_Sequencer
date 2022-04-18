%GetFifo_Double  transfers FIFO data from a FIFO array to a row vector.
%
%  Syntax:  GetFifo_Double (FifoNo, Count)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Count            Number (>=1) of elements to be transferred.
%    Return value    Row vector with transferred values
%
%  Notes:
%    You should first use the function Fifo_Empty to check, how much used
%    elements the FIFO array has. If more data are read from the FIFO array than
%    used elements are given, the surplus data is erroneous.
%    Until T11, please note: float values in the ADwin system have 32-bit
%    precision. You should therefore display data of the returned row vector
%    only with single precision to avoid misunderstandings. 
%    The function GetFifo_Double replaces the function Get_Fifo, which was used
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

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
