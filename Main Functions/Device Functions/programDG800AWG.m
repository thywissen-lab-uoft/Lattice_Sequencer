function programDG800AWG(DeviceName,ch)

if nargin==0
    DeviceName='USB0::0x1AB1::0x0643::DG8A231601935::0';
end

if nargin ==1 || nargin == 0
    ch = struct;
    ch.ChannelNumber = 2;
    ch.SamplingRate = 1e6; % in Sa/s
    ch.V_Low = -10;        % Low level in Volts
    ch.V_High = 10;        % High Level in Volts
    ch.Values = sin(2*pi*linspace(0,1,1e5));  % Normalized value [-1,1]
%     ch.Values = values_1;
    % ch1.Values = [linspace(-1,1,2^16)];  % Normalized value [-1,1]
    ch.Period = length(ch.Values)/ch.SamplingRate;

end

% High and low voltages
V_Low = ch.V_Low;
V_High = ch.V_High;

% Sampling rate of 40 kHz allows 2E6 points to be 40 seconds
SamplingRate = ch.SamplingRate; 

% Get the values
Values = ch.Values;

% Helper function convert -1 to 1 to 0 to 2^16-1 
val2int16 = @(val) int16(round(-2^15+2^16*((val+1)/2)));
val2uint16 = @(val) typecast(val2int16(val),'uint16');

valStart = val2uint16(ch.Values(1));

% Channel Number
ChannelNumber = ch.ChannelNumber;

% Source Precursor
src = strrep(':SOURCE<n>:','<n>',num2str(ChannelNumber));

% Connect to Rigol
obj=visaConnect(DeviceName);

% If connection faile exit the function
if isempty(obj)
    return;
end   

% Turn off output
CMD = strrep(':OUTPUT<n>:STATE OFF','<n>',num2str(ChannelNumber));
fprintf(obj,CMD);
pause(0.1);

% Change to sequence mode
CMD = [src 'APPLY:SEQUENCE'];
fprintf(obj,CMD);
pause(0.1);

% Default chunk size
Nsize = 16383;

% Do not know if this chunk size is good
goodChunk  = false;

% Set chunk size to data length if data length is small enough
if length(Values)<=Nsize
    goodChunk = true;  
    Nsize = length(Values);
end

% Find good chunk size if data length is larger than max buffer
while ~goodChunk
    if mod(length(Values),Nsize)<10 && mod(length(Values))~=0
       Nsize =  Nsize-1; 
    else
        goodChunk = true;
    end
end

% Remaining values to be written
ValuesRemaining = Values;

pause(0.2);
% Send data in chunks 
while length(ValuesRemaining) > Nsize
    data = typecast(val2uint16(ValuesRemaining(1:Nsize)),'uint8');
    s1 = num2str(length(data));
    s2 = num2str(length(s1));
    hdr = [src 'TRACe:DATA:DAC16 VOLATILE,CON,#' s2 s1];
    disp(hdr)
    fwrite(obj,[hdr data],'uint8');        
    pause(0.05);
    ValuesRemaining(1:Nsize)=[]; 
end

% Convert uint16 to pairs of uint8
data = typecast(val2uint16(ValuesRemaining),'uint8');
s1 = num2str(length(data));
s2 = num2str(length(s1));

hdrb = [src 'TRACe:DATA:DAC16 VOLATILE,END,#' s2 s1];
fwrite(obj,[hdrb data],'uint8','sync');
disp(hdrb);
pause(0.2);

% Set sampling rate
CMD = [src 'FUNCTION:SEQUENCE:SRAT ' num2str(SamplingRate)];
fprintf(obj,CMD);

% Set the high voltage
CMD = [src 'VOLTAGE:HIGH ' num2str(V_High) 'V'];
fprintf(obj,CMD);
pause(0.2);

% Set the low voltage
CMD = [src 'VOLTAGE:LOW ' num2str(V_Low) 'V'];
fprintf(obj,CMD);
pause(0.2);

% Set idle burst level to the first point
CMD = [src 'BURST:STATE ON'];
fprintf(obj,CMD);
pause(0.2);

% Set idle burst level to the first point
CMD = [src 'BURST:IDLE ' num2str(valStart)];
fprintf(obj,CMD);
pause(0.2);

% Set the waveform to be triggered
CMD = [src 'BURST:MODE TRIG'];
fprintf(obj,CMD);
pause(0.2);

% Set the waveform to be triggered
CMD = [src 'BURST:TRIGGER:SOURCE EXT'];
fprintf(obj,CMD);
pause(0.2);

% Set the waveform to be triggered
CMD = [src 'BURST:NCYCLES 1'];
fprintf(obj,CMD);
pause(0.2);

% Turn on output
CMD = strrep(':OUTPUT<n>:STATE ON','<n>',num2str(ChannelNumber));
fprintf(obj,CMD);
pause(0.1);

% Close the connection
fclose(obj);

disp('done?')

end

function obj=visaConnect(DeviceName)
    obj=[];

    try
        % Find the VISA object
        obj = instrfind('Type','visa-usb','RsrcName', DeviceName);
        if isempty(obj)
            obj = visa('NI', DeviceName);
        else
            fclose(obj);
            obj = obj(1);
        end
        
        % Make Large output buffer
        set(obj, 'OutputBufferSize', 34e6);
        
        % Open the VISA object
        fopen(obj);
        
        % Get basic device information
        nfo = query(obj, '*IDN?');
        nfo=strtrim(nfo);   
        disp(['Established connection to ' nfo]);

    catch ME
        warning([DeviceName]);
        obj=[];
    end

end