function out = BreitRabiRb(B,F,mF)
% out = BreitRabiRb(B, F, mF)
%
% Calculates hyperfine energy for Rb state |F, mF> at magnetic field B (in G)
% using the Breit-Rabi formula (source: Ramsey, Molecular Beams, p.86). 
% Output in units of energy [J]. Transcribed from established Mathematica code.
% S. Trotzky, May 2014
    
    h = 6.6260755e-34;
    muB = 1.39962418e6; % (Hz/G)
    hfs = 6834682612.8; % (Hz)
    gJ = 2.00233113; % Aromindo et al., Rev. Mod. Phys. 49, 31 (1977), should in principle be equal to electron's "gS" since S = J = 1/2
    gI = -0.0009951414; % 87Rb (Steck)
        
    xRb = @(B) ((gJ - gI) * muB * B / hfs);
    ebrRb = @(B,F,mF) ( -h*hfs/8 + gI*h*muB*B.*mF + (-1).^F*h*hfs/2*sqrt( 1 + mF.*xRb(B) + xRb(B).^2 ) );
    
    out = ebrRb(B,F,mF);
    
end
