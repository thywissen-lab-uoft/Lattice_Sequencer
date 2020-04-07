%------
%Author: Karl Pilch
%Created: September 2009
%Summary: Timing curve for transport
%------
function y=transport_curve_spline(t,tt,dt,show)


interval = t;
duration = tt;      %duration of transport in units of ms
distance = dt;       %transport distance in units of mm
    
if duration ~= 0 || distance ~=0;

%set points for acceleration: first column=time, second colume=a in
%arb.units
% at = [ 
%     0,      0
%     0.1,    1
%     0.15,   1
%     0.2,    0
%     0.25,   0
%     0.3,    0
%     0.4,    0
%     0.5,    0
%     0.6,    0
%     0.65,   0
%     0.7,    0
%     0.75,   0
%     0.8,    0
%     0.85,   -1
%     0.9,    -1
% 	1,      0
% ];
% a_t_1 = [ 
%     0,      0
%     0.2,    1
%     0.25,   0
%     0.3,    0
%     0.4,    0
%     0.5,    0
%     0.6,    0
%     0.65,   0
%     0.7,    0
%     0.75,   0
%     0.8,    -1
% 	1,      0
% ];


at = [ 
    0,      0
    0.35,   1
    0.65,   -1
	1,      0
];





at(:,1) = at(:,1)*duration;




%Interpolate the a_t curve
%a_t_spl_1 = spapi(2,at(:,1),at(:,2));     %interpolation, where you can choose the order of the polinomial e.g. 2 means linear, .. 
%a_t_spl_1 = csape(at(:,1),at(:,2));      %some kind of interpolation
a_t_spl_1 = spline(at(:,1),at(:,2));     %spline



%Integrate to get x(t)
v_t_spl_1 = fnint(a_t_spl_1);          
x_t_spl_1 = fnint(v_t_spl_1);  

%rescale x,v,a
x_t_end = fnval(x_t_spl_1,duration);
x_t_spl = biot_spline_scaley(x_t_spl_1, distance/x_t_end);
v_t_spl = biot_spline_scaley(v_t_spl_1, distance/x_t_end);
a_t_spl = biot_spline_scaley(a_t_spl_1, distance/x_t_end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %set number of points according to the 50mus timing base
%     res=0.05;
%     points=duration/res
%     interval = linspace(0,duration,points)';
    %time resolution 
    x_t = fnval(x_t_spl,interval);   
    size(x_t);

    y=x_t;
    
if show==1

        figure(10)
        clf
        plot(y)
        xlabel('N of output');
        ylabel('distance [mm]');
        % axis([-10 (tt+10) -10 (td+10)]);
        grid on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        figure(20)
        clf
        subplot(4,1,1)
        fnplt(x_t_spl)
        xlabel('time [ms]');
        ylabel('distance [mm]');
        axis([-10 (duration+10) -10 (distance+10)]);
        grid on 

        subplot(4,1,2)
        fnplt(v_t_spl)
        xlabel('time [ms]');
        ylabel('velocity [mm/ms]');
        grid on 

        subplot(4,1,3)
        fnplt(a_t_spl)
        xlabel('time [ms]');
        ylabel('acceleration [mm/ms^2]')
        grid on


        subplot(4,1,4)
        plot(at(:,1),at(:,2),'o')
        xlabel('time [ms]');
        ylabel('acceleration [mm/ms^2]')
        grid on
        


    else
    
end


else
    y=0;
end
function ppscale = biot_spline_scaley(pp, yscale)
%% in: pp: Spline in pp Form
%% out: ppscale: in scaled by the factor scale

        ppscale = pp;
        ppscale.coefs = pp.coefs.*yscale;
        
end
end