function V_cal = big_shim_calibration(FB_request)
if nargin < 1
    FB_request = getChannelValue(seqdata,'FB current',1,0);
end

% FL1-100 calibration 2026.05.19 (test sequence --> not centered at 2.5 V
% output)
% B2V = @(B) -0.094212*B + 4.6042;
% V_cal = B2V(FB_request);%+0.0001; % 0.1 mV offset in labjack read

% 2026.05.21 full sequence calibration (higher field, force 2.5 V big shim
% feedback output)
B2V = @(B) -0.107507*B + 6.2715;
V_cal = B2V(FB_request);
end

