function out = TransitionFrequency(B, is, fs)
% out = TransitionFrequency(B, [Fi, mFi], [Ff, mFf])
%
% Calculates the transition frequency (in Hz) for rf/uwave transitions between
% states |Fi, mFi> and |Ff, mFf> at field B (in G). Makes use of the 
% Breit-Rabi formula and works for both 40K and 87Rb.
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
        else
            out = (BreitRabiRb(B, fs(1), fs(2))-BreitRabiRb(B, is(1), is(2)))/h;
        end
    elseif ( is(1) == 9/2 || is(1) == 7/2 ) % assume 40K
        if ~( fs(1) == 9/2 || fs(1) == 7/2 )
            error('K: F can only be 9/2 or 7/2!')
        elseif ( mod(is(2),1)~=0.5 || mod(fs(2),1)~=0.5 )
            error('K: mF must be half integer!')
        else
            out = (BreitRabiK(B, fs(1), fs(2))-BreitRabiK(B, is(1), is(2)))/h;
        end
    else
        error('F can only be 1 or 2 (Rb) or 9/2 or 7/2 (K)!')
    end

end