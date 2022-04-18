%SetFifo_Double  transfers data from a row vector into a FIFO array.
%
%  Syntax:  SetFifo_Double (FifoNo, Vector)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Data            Row vector with values to be transferred.
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    You should first use the function Fifo_Empty to check, if the FIFO array
%    has enough empty elements to hold all data of the row vector. If more data
%    are transferred into the FIFO array than empty elements are given, the
%    surplus data are overwritten and are definitively lost.
%    Until T11, please note: float values in the ADwin system have 32-bit
%    precision. You should therefore display data of Vector only with single
%    precision to avoid misunderstandings. 
%    The function SetFifo_Double replaces the function Set_Fifo, which was used
%    with former driver versions.
%
%  Example:
%    %Check FIFO array DATA_12 for empty elements and transfer all elements of
%    %the row vector vector into the FIFO array:
%    num_fifo = Fifo_Empty(12);
%    num_vector = length(vector);
%    if num_fifo >= num_vector
%     SetFifo_Double(12, vector);
%    end
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
