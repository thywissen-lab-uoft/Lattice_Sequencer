function [B, errf] = FrequencyToField(f, is, fs)
% [B, errf] = FrequencyToField(f, [Fi, mFi], [Ff, mFf])
%
% Finds the field (in G) for a given transition frequency f (in Hz) for transfer 
% from state |Fi, mFi> to |Ff, mFf>. Makes use of the Breit-Rabi formula
% and works both for 40K and 87Rb. Uses two steps of interpolation (1G & 
% 1mG steps) to find the minimum value. Hands back the field and the 
% frequency error in Hz. Currently limited to B < 400G.
% S. Trotzky, May 2014

    if (length(is) ~= 2 || length(fs) ~= 2)
        error('Wrong format of initial or final state. Specify as [F, mF]!');
    end
    
    if ( abs(is(2) > is(1)) || abs(fs(2) > fs(1)) )
        error(' Absolute value of mF needs to be smaller or equal than F (mF = -F ... F)!')
    end
    
    h = 6.6260755e-34;
    
    if ( is(1) == 1 || is(1) == 2 ) % assume 87Rb
        if ~( fs(1) == 1 || fs(1) == 2 )
            error('Rb: F can only be 1 or 2!')
        elseif ( mod(is(2),1)~=0 || mod(fs(2),1)~=0 )
            error('Rb: mF must be integer!')            
        else % two steps of interpolation 0-400G in 1G steps and 1G around found value in 1mG steps
            B = 0:400; ff = abs(BreitRabiRb(B, fs(1), fs(2))-BreitRabiRb(B, is(1), is(2)))/h;
            B0 = interp1(ff,B,abs(f));
            B = B0+[-0.5:0.001:0.5]; ff = abs(BreitRabiRb(B, fs(1), fs(2))-BreitRabiRb(B, is(1), is(2)))/h;
            B0 = interp1(ff,B,abs(f));
            out = [B0, abs(f) - abs(BreitRabiRb(B0, fs(1), fs(2))-BreitRabiRb(B0, is(1), is(2)))/h];
        end
    elseif ( is(1) == 9/2 || is(1) == 7/2 ) % assume 40K
        if ~( fs(1) == 9/2 || fs(1) == 7/2 )
            error('K: F can only be 9/2 or 7/2!')
        elseif ( mod(is(2),1)~=0.5 || mod(fs(2),1)~=0.5 )
            error('K: mF must be half integer!')            
        else % two steps of interpolation 0-400G in 1G steps and 1G around found value in 1mG steps
            B = 0:400; ff = abs(BreitRabiK(B, fs(1), fs(2))-BreitRabiK(B, is(1), is(2)))/h;
            B0 = interp1(ff,B,abs(f));
            B = B0+[-0.5:0.001:0.5]; ff = abs(BreitRabiK(B, fs(1), fs(2))-BreitRabiK(B, is(1), is(2)))/h;
            B0 = interp1(ff,B,abs(f));
            out = [B0, abs(f) - abs(BreitRabiK(B0, fs(1), fs(2))-BreitRabiK(B0, is(1), is(2)))/h];
        end
    else
        error('F can only be 1 or 2 (Rb) or 9/2 or 7/2 (K)!')
    end
    
    B = out(1);
    errf = out(2);

end