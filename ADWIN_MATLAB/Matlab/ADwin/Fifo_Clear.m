%Fifo_Clear  initializes the write and read pointers of a FIFO array. Now the
%  data in the FIFO array are no longer available.
%
%  Syntax:  Fifo_Clear (FifoNo)
%
%  Parameters:
%    FifoNo          Number (1...200) of the FIFO array DATA_1 ... DATA_200.
%    Return value    <>255: OK
%                    255: Error
%
%  Notes:
%    During start-up of an ADbasic program the FIFO pointers of an array are not
%    initialized automatically. We therefore recommend calling Fifo_Clear at the
%    beginning of your ADbasic program.
%    Initializing the FIFO pointers during program run is useful, if you want to
%    clear all data of the array (because of a measurement error for instance).
%
%  Example:
%    % Clear data in the FIFO array DATA_45
%    ret_val = Fifo_Clear(45);
%

%
%  Support address:  <a href="matlab:web('mailto:support@ADwin.de?subject=Support%20request%20ADsim:%20')">support@ADwin.de</a>
%  Homepage:         <a href="matlab:web('http://www.ADwin.de', '-browser')">www.ADwin.de</a>

%  Copyright (c) 1995-2018 by Jaeger Computergesteuerte Messtechnik GmbH
%  $Revision: 4.09.01 $  $Date: 2018-03-07  12:29:45 $
