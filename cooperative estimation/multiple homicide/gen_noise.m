% gen_noise

addpath('../2D');

load data.mat;

sigma_w = (.1/3)^2;% odometry error, metres
sigma_bear = (1*d2r/3)^2;%radians
sigma_gps = (.1)^2;%metres
sigma_acc = (.1/3)^2;%accelerometer
sigma_gyro = (.1/3)^2;%gyroscope

% y: [rx ry psi_1 rx ry psi_t rx ry psi_2 v2]

Ts = 0.1;

if ~exist('TRUTH','var')
    TRUTH = 0;
end

% odometry matrix
w = zeros(length(T),2);
% agent 1 bearings
b1 = zeros(length(T),2);%b1(1) = bearing to agent 2, b1(2) = bearing to target
b2 = zeros(length(T),2);%b1(1) = bearing to agent 1, b1(2) = bearing to target
u1 = zeros(length(T),1);
u2 = zeros(length(T),1);
gps = zeros(length(T),4);
imu = zeros(length(T),6);%[acc1 gyro1 acc2 gyro2]

i = 2;
t = zeros(length(T),1);
count = 0;
while i < length(T)
    count = count+1;
    
    ilast = i-1;
    
    t(count) = T(ilast);
    
    %bearing from 1 to 2
    thetaji = atan2( Y(ilast,8)-Y(ilast,2),Y(ilast,7)-Y(ilast,1) ) - Y(ilast,3);
    thetati = atan2( Y(ilast,5)-Y(ilast,2),Y(ilast,4)-Y(ilast,1) ) - Y(ilast,3);
    
    thetaij = atan2( Y(ilast,2)-Y(ilast,8),Y(ilast,1)-Y(ilast,7) ) - Y(ilast,9);
    thetatj = atan2( Y(ilast,5)-Y(ilast,8),Y(ilast,4)-Y(ilast,7) ) - Y(ilast,9);
    b1(count,1) = pi2pi(thetaji + ~TRUTH*randn*sqrt(sigma_bear));
    b1(count,2) = pi2pi(thetati + ~TRUTH*randn*sqrt(sigma_bear));
    
    b2(count,1) = pi2pi(thetaij + ~TRUTH*randn*sqrt(sigma_bear));
    b2(count,2) = pi2pi(thetatj + ~TRUTH*randn*sqrt(sigma_bear));
    
    % control inputs
    u1(count) = uref(ilast);
    u2(count) = u2ref(ilast,1);
    % gps-like position update
    gps(count,:) = Y(ilast,[1 2 7 8]) + ~TRUTH*randn(1,4)*sqrt(sigma_gps);
    
    % accelerometer & gyros
    if ilast > 1
        vdot1 = (Y(i,1:2)-2*Y(ilast,1:2)+Y(ilast-1,1:2))/(0.5*(T(i)-T(ilast-1)))^2;
        vdot2 = (Y(i,7:8)-2*Y(ilast,7:8)+Y(ilast-1,7:8))/(0.5*(T(i)-T(ilast-1)))^2;
    else
        vdot1 = (Y(i+1,1:2)-2*Y(ilast+1,1:2)+Y(ilast,1:2))/(0.5*(T(i+1)-T(ilast)))^2;
        vdot2 = (Y(i+1,7:8)-2*Y(ilast+1,7:8)+Y(ilast,7:8))/(0.5*(T(i+1)-T(ilast)))^2;
    end
    % approximate the inertial derivative of v for agent 1
    
    % inertial to body DCM
    C = [cos(Y(ilast,3)) sin(Y(ilast,3));-sin(Y(ilast,3)) cos(Y(ilast,3))];
    imu(count,1:2) = vdot1*C' + ~TRUTH*randn(1,2)*sqrt(sigma_acc);
    imu(count,3) = u1(count) + ~TRUTH*randn(1,1)*sqrt(sigma_gyro);
    % repeat for agent 2
    C = [cos(Y(ilast,9)) sin(Y(ilast,9));-sin(Y(ilast,9)) cos(Y(ilast,9))];
    imu(count,4:5) = vdot2*C' + ~TRUTH*randn(1,2)*sqrt(sigma_acc);
    imu(count,6) = u2(count) + ~TRUTH*randn(1,1)*sqrt(sigma_gyro);
    
    % odometry
    while round(1e4*(T(i) - T(ilast) - Ts))*1e-4 <= 0
        w(count,1) = w(count,1) + norm(Y(i,1:2)-Y(i-1,1:2));
        w(count,2) = w(count,2) + norm(Y(i,7:8)-Y(i-1,7:8));
        i = i+1;
        if i > length(T)
            break;
        end
    end
    % add odometry noise
    w(count,:) = w(count,:) + ~TRUTH*randn(1,2)*sqrt(sigma_w);
end

t(count+1:end,:) = [];
w(count+1:end,:) = [];
b1(count+1:end,:) = [];
b2(count+1:end,:) = [];
u1(count+1:end,:) = [];
u2(count+1:end,:) = [];
gps(count+1:end,:) = [];

%save noised.mat;