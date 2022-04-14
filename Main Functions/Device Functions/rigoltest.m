% Samping Rate
sr = 40e3;
dt = 1/sr;

% Timings
t1 = .075;          % Ramp on
tha = 1.12;         % Hold after ramp
t2 = .500;          % Ramp to sympathetic
t3 = 18;tau=18;     % Exponential Decrease
thb= 0.2;           % Hold time after evaporation

% Total Time
Ttot = t1 + tha + t2 + t3 +thb;

% Time Vector
tVec = 0:dt:Ttot;

% Optical Powers
y0 = -0.04;
y1 = 1.5;
y2 = 0.8;
y3 = 0.08;
y4 = 0.08;

% Ramp On
tVec_a = tVec(tVec<=t1);
y_a = tVec_a*(y1-y0)/t1+y0;

% Hold
tVec_b = tVec(logical([tVec>t1].*[tVec<=(t1+tha)]));
y_b = tVec_b./tVec_b.*y1;

% Ramp to Sympathetic
tVec_c = tVec(logical([tVec>(t1+tha)].*[tVec<=(t1+tha+t2)]));
y_c = y1 + (tVec_c-(t1+tha))/t2*(y2-y1);

% Exponential
tVec_d = tVec(logical([tVec>(t1+tha+t2)].*[tVec<=(t1+tha+t2+t3)]));
dt = tVec_d-(t1+tha+t2);
y_d = y2 + (y3-y2)./(exp(-t3/tau)-1).*(exp(-dt/tau)-1);

% Hold
tVec_e = tVec(logical([tVec>(t1+tha+t2+t3)]));
dt = tVec_e-(t1+tha+t2+t3);
y_e = tVec_e./tVec_e.*y4;

% Combine all ramps
tt = [tVec_a tVec_b tVec_c tVec_d tVec_e];
yy = [y_a y_b y_c y_d y_e];

% Plot the powers
figure(1)
clf
co=get(gca,'colororder');
plot(tt,yy,'-','linewidth',1,'color',co(1,:));
hold on
% plot(tt,yy,'-','linewidth',1,'color',co(2,:));
xlabel('time (seconds)');
ylabel('power (W)');

%% Calculate Voltages

% DipoleTrap1
pow2volt_1 = @(a)(6.2123*a + 0.0359);

% DipoleTrap2
pow2volt_2 = @(a)(5.4671*a + 0.0429);

% Voltages
v1 = pow2volt_1(yy);
v2 = pow2volt_2(yy);

% Voltage limits (keep resolution fixed no matter the level)
V_L = -0.2;
V_H = 10;

% Scale the voltage level from -1 to 1
volt2val = @(V) (V-V_L)/(V_H-V_L)*2-1;

% Scale the voltages
values_1 = volt2val(v1);
values_2 = volt2val(v2);

% Plot the normalized voltages
figure(2);
clf
plot(values_1,'-','linewidth',1,'color',co(1,:));
hold on
plot(values_2,'-','linewidth',1,'color',co(2,:));
xlabel('points');
ylabel('normalized voltage');

%% Program Rigol
DeviceName='USB0::0x1AB1::0x0643::DG8A231601935::0';

ch1 = struct;
ch1.ChannelNumber = 1;
ch1.SamplingRate = 40e3; % in Sa/s
ch1.V_Low = V_L;        % Low level in Volts
ch1.V_High = V_H;        % High Level in Volts
ch1.Values = values_1;  % Normalized value [-1,1]

programDG800AWG(DeviceName,ch1)

ch2 = struct;
ch2.ChannelNumber = 2;
ch2.SamplingRate = 40e3; % in Sa/s
ch2.V_Low = V_L;        % Low level in Volts
ch2.V_High = V_H;        % High Level in Volts
ch2.Values = values_2;  % Normalized value [-1,1]

programDG800AWG(DeviceName,ch2)
