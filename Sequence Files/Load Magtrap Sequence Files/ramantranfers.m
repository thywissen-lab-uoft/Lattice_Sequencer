function timeout = RamanManipulation(timein,settings)
% Raman Manipulation

global seqdata
curtime=timein;

validModes={'RabiOscillations',...
    'LandauZener_Rigol',...
    'LandauZener_SRS',...
    'LandauZener_Shims'};

if nargin~=2
   settings=struct;
   settings.Mode='LandauZener_EOM';
   
end




% Possible Modes :
%
%   Two photon Raman Rabi oscillations
%   Landau-Zener Sweep : Shims, Rigol, EOM
%   STIRAP

end

