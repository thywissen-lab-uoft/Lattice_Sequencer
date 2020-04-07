%------
%Author: DJ
%Created: Dec 2010
%Summary: This function ramps the DDS frequency from start_freq to end_freq
%in time tt.
%------

function y = ramp_DDS_freq(tt, start_freq, end_freq,DDS_id)
%%%%%%%%%%%%%%%%%%%%%%%%% April 2014: added input parameter DDS_id to
%%%%%%%%%%%%%%%%%%%%%%%%% address e.g. indiidual calibration factors for
%%%%%%%%%%%%%%%%%%%%%%%%% each DDS (S.T.). If an error occurs in this
%%%%%%%%%%%%%%%%%%%%%%%%% function, this may be the reason. Make sure that
%%%%%%%%%%%%%%%%%%%%%%%%% DDS_id is specified (DDS_id = 1 for evaporation
%%%%%%%%%%%%%%%%%%%%%%%%% DDS). Handed down to calc_DDS_freq.


global seqdata;

%clock
clk_rate = 1E9; %1GHz clock

add_cmd = char(hex2dec('C1'));

%Calculate ramp delta_f and delta_t (note: delta_f/delta_t*tt = (f2-f1))

%required frequency change per 4 clock cycles in units of the minimum
%delta frequency
freq_slope = (abs(end_freq-start_freq)/(clk_rate/2^(32)))/(tt/1E3/(4/clk_rate));

y = {};

%no ramp
if (freq_slope == 0)
    
    %simple set frequency command
    y{1} =  [add_cmd char(hex2dec('A5')) char(hex2dec('00')) calc_DDS_freq(start_freq,DDS_id)];
        
%ramp    
else
   
    for i = 1:10
    
        delta_t = i*10*ceil(10/freq_slope);
        
        if delta_t >= 2^(16)
            delta_t = 2^(16)-1;
        end
        
        delta_f = max(1,ceil(freq_slope*delta_t));
        
        if delta_f > 2^(32)
            warning('Frequency ramp is too fast');
        end
        
        if (abs(delta_f/delta_t/freq_slope-1)) < 0.001
                       
            break;
        end
        
    end
    
    if tt < 100
        buildWarning('ramp_DDS_freq',sprintf('Fast sweep: df = %g, dt = %g, df/dt/slope = %g.',...
            delta_f,delta_t,delta_f/delta_t/freq_slope),0);
    end
    
    %general purpose
    y{1} =  [add_cmd char(hex2dec('A5')) char(hex2dec('00')) calc_DDS_freq(start_freq,DDS_id)];
    y{2} =  [add_cmd char(hex2dec('AC')) char(hex2dec('00')) char(hex2dec('00')) ...
         char(mod(floor(delta_f/256^0),256)) char(mod(floor(delta_f/256^1),256)) char(mod(floor(delta_f/256^2),256)) char(mod(floor(delta_f/256^3),256))...
         char(hex2dec('00')) char(mod(floor(delta_t/256^0),256)) char(mod(floor(delta_t/256^1),256)) char(hex2dec('00')) char(hex2dec('00'))...
         calc_DDS_freq(end_freq,DDS_id)];
    
end



%phase-o-matic
%y = set_DDS_freq(start_freq);
%y =  [y native2unicode(hex2dec('C1')) native2unicode(hex2dec('AC')) calc_DDS_freq(abs(end_freq-start_freq)*(RRClk_dec/tt),DDS_id) RRClk calc_DDS_freq(end_freq,DDS_id)];


end