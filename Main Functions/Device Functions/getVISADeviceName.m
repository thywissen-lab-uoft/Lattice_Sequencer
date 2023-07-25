function out = getVISADeviceName(num)
%------
%Author: Stefan Trotzky
%Created: January
%Summary: Speed dial option for visa devices with rather long identifiers
%   like USB0::0x1AB1::0x0641::DG4E160900481::INSTR. Make sure that this
%   function is up to date when using it.
%------  
%
% The VISA devices here are specified by USB connection.  This doesn't
% necessarily have to be the case.

devices = {'USB0::0x1AB1::0x0641::DG4E180900374::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E160900481::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E191700653::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E191700649::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100174::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221600305::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100173::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100169::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E225202524::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E224101686::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E231700442::INSTR', ...
           'USB0::0x1AB1::0x0643::DG8A213702086::INSTR', ...
           'getVISADeviceName::AddNewDevice'};       
      
       
% devices(01) DG4E180900374 is the Raman 1 (V) and Raman 2 (H1)
% devices(02) DG4E160900481 is the Rigol for conductivity modulation
% devices(03) 
% devices(04) 
% devices(05) DG4E221100174 is the Rigol for AM spec and Z lattice regulation
% devices(06) DG4E221600305 is for two high field imaging beams
% devices(07) DG4E221100173 is for D1 lock and Raman 3 (H2)
% devices(08) DG4E221100169 is for upwards K kill beam
% devices(09) DG4E225202524 is for X & Y lattice modulation(new, 02/02/2022)
% devices(10) DG4E224101686 is FPUMP & EIT 2        (2023/04/18);
% devices(11) DG4E231700442 is EIT 1 and K D1 OPP   (2023/04/18);
% devices(12) DG8A213702086 is XDT Piezo Modulation   (2023/07/25);

out = '';

if num > length(devices);
    out = 'getVISADeviceName::DeviceNotListed';
else
    out = devices{num};
end

end
