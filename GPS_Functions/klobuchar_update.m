function [correction] = klobuchar_update(lat_u,long_u,az,el,gpsSeconds)
%[time_correction] = klobuchar_update(user_lat,user_long,azimuth,elevation,current GPS Second)  
% uses an imperic model to remove ~50% RMS error from the pseudorange measurement

%init iono delay variables
A_i = 0;
P_i = 0;
delay = 0;

%speed of light
c = 299792458;

%load the klobuchar parameters
load('iono_corr_terms')
alphaParam = [iono_corr_terms.alpha_0, iono_corr_terms.alpha_1, iono_corr_terms.alpha_2, iono_corr_terms.alpha_3];
betaParam = [iono_corr_terms.beta_0, iono_corr_terms.beta_1, iono_corr_terms.beta_2, iono_corr_terms.beta_3];

%step 1 - calculate the earth cenetered angle
psi = (0.0137 / (el + 0.11)) - 0.022;

%compute latitude of ionospheric Pierce Point
lat_I = lat_u + psi*cos(az);

if(lat_I > .416)
    lat_I = .416;
elseif(lat_I < -.416)
    lat_I = -.416;
end

%compute longitude of ionospheric pierce point
long_I = long_u + (psi*sin(az)) / cos(lat_I);

%find geomagnetic latitude at IPP
lat_m = lat_I + .064*cos(long_I - 1.617);

%find local time at IPP
tGPS = 43200*long_I + gpsSeconds;

if(tGPS > 86400)
    tGPS = tGPS - 86400;
elseif(tGPS < 0)
    tGPS = tGPS + 86400;
end

%compute ionospheric delay
for i = 1:length(alphaParam)
A_i = A_i + alphaParam(i)*lat_m;
end

if(A_i < 0)
    A_i = 0;
end

%compute period of ionosphere delay
for i = 1:length(alphaParam)
P_i = P_i + betaParam(i)*lat_m;
end

if(P_i < 72000)
    A_i = 72000;
end

%compute the phase of the ionospheric delay
X_i = (2*pi(tGPS - 50400)) / P_i;

%compute the slant factor
F = 1.0 + 16.0*(0.53 - el)^3;

%compute the ionospheric time delay
if abs(X_i) < 1.57
    for j = 1:3
        delay = dalay + alphaParam(j)*lat_m *(1 - (X_i^2 / 2) + (X_i^4 / 24))
    end
    I_L1 = (delay + 5e-9)*F;
else
    I_L1 = 5e-9 * F;
end

correction = I_L1*c;
 
end