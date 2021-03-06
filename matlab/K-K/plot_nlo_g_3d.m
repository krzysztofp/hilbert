function plot_nlo_g_3d(Spectrum, Area, Width, Centers, Real, Imag)
% plot_nlo_g_3d plots the nlo under-integral function
%% Sample data for coumarine
%% Spectrum =[5.30e-07,5.50e-07,5.70e-07,6.00e-07,6.30e-07,6.60e-07,6.90e-07,7.20e-07,7.50e-07,7.80e-07,8.050000e-07,8.50e-07,8.80e-07,9.20e-07,9.640e-07,1.0150e-06];
%% Area = [1.860000e-42,2.120000e-42,-5.560000e-42,9.83183514953900e-44];
%% Width = [1.450000e-07,6.60e-08,5.30e-10,1.830e-08];
%% Centers = [7.20e-07,7.620000e-07,4.750000e-07,8.30e-07];
%% Real = [-3.843580e-36,1.905940e-35,7.855620e-36,3.033850e-37,-1.180530e-36,-3.831240e-36,-6.295560e-36,-5.239590e-36,-9.278530e-36,-1.880560e-35,-5.281310e-36,1.248310e-35, 1.415500e-35,1.012200e-35,5.152260e-36,6.691250e-36];
%% Imag = [5.23773E-36,3.50639E-36,2.4859E-36,3.23581E-36,5.217E-36,8.77457E-36,1.31922E-35,2.30605E-35,3.47489E-35,3.12974E-35,1.7376E-35,6.43164E-36,1.13379E-36,9.25422E-38,6.93364E-38,7.19202E-38];

% getting the wavelengths:
minwl = Spectrum(4)/1.4; 
sectrumsize = size(Spectrum);
maxwl= Spectrum(sectrumsize(2)/2)*1.2;

% prepare arguments for integration
args = minwl:0.4E-8:maxwl;

% prepare the gaussians
gCount = size(Centers);

% declare the inner function
sum=@(x)0; 

for i=1:gCount(2)
     sum = @(t)(sum(t) + (Area(i)/(Width(i).*sqrt(pi/2))).*exp(-2.*((t-(Centers(i)))/Width(i)).^2));
end;

% divide the non-negative half-axis into three parts:
% 
[X,Y] = meshgrid(args,args);
refr  = @(x,y)(2/pi) * (innerfun_nlo_g(y,x,sum(y)) + innerfun_nlo_g(y,x,sum(y)));
% refrMiddle = @(w)(0); % TODO

% tr = @(w)(2/pi)*trapz(args,(innerfun_nlo_g(args,w,sum(args))));

%refr = @(w)(2/pi)*quadgk(@(t)(innerfun_nlo_g(t,w,sum(t))),0,inf,'MaxIntervalCount',10E6,'Waypoints',Spectrum(round(sectrumsize/2)));

% final & main loop
Z = refr(X,Y);

% plot it!
plot3(X,Y,Z);
% meshc(X,Y,Z);
% surf(X,Y,Z);


end