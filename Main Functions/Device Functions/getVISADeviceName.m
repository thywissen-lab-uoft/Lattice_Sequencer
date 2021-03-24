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
           'getVISADeviceName::AddNewDevice'};
       
       
       
       % devices(1) is the Raman Rigol
       % devices(2) is the Rigol for conductivity modulation
       % devices(3) is for high field imaging
      
out = '';

if num > length(devices);
    out = 'getVISADeviceName::DeviceNotListed';
else
    out = devices{num};
end

end
