function out = getVISADeviceName(num)
%------
%Author: Stefan Trotzky
%Created: January
%Summary: Speed dial option for visa devices with rather long identifiers
%   like USB0::0x1AB1::0x0641::DG4E160900481::INSTR. Make sure that this
%   function is up to date when using it.
%------  

devices = {'USB0::0x1AB1::0x0641::DG4E180900374::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E160900481::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E191700653::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E191700649::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100174::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221600305::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100173::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E221100169::INSTR', ...
           'USB0::0x1AB1::0x0641::DG4E225202524::INSTR', ...
           'getVISADeviceName::AddNewDevice'};
       
       
       
% devices(1) DG4E180900374 is the Raman Rigol
% devices(2) DG4E160900481 is the Rigol for conductivity modulation
% devices(5) DG4E221100174 is the Rigol for AM spec and Z lattice regulation
% devices(6) DG4E221600305 is for two high field imaging beams
% devices(7) DG4E221100173 is for Raman 3 and D1 lock EOM
% devices(8) DG4E221100169 is for upwards K kill beam
% devices(9) DG4E225202524 is for X & Y lattice modulation(new, 02/02/2022)
      
out = '';

if num > length(devices);
    out = 'getVISADeviceName::DeviceNotListed';
else
    out = devices{num};
end

end
