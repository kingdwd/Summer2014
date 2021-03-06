function [xnew,Pnew] = ukf_update(xk,Pxk,Pvk,Pnk,uk,ytilde,updatefun,measurementfun,alpha)
% Pxk: covariance associated with state
% Pvk: covariance associated with process noise
% Pnk: covariance assocaited with measurement noise

% vector lengths
n = length(xk);
m = length(uk);
nl = size(Pnk,1);
vl = size(Pvk,1);
N = n+nl+vl;

% number of known features seen by agents i and j (1 and 2)
m1 = uk(10);
m2 = uk(10 + 1 + 3*m1);

% constant gamma that influences sigma points
if nargin < 9
    alpha = 1e-3;
end
Kappa = 0;
lambda = alpha^2*(N+Kappa)-N;
gamm = sqrt(N+lambda);

%augmented covariance and state
Paug = zeros(N);
Paug(1:n,1:n) = Pxk;
Paug(n+(1:vl),n+(1:vl)) = Pvk;
Paug(n+vl+(1:nl),n+vl+(1:nl)) = Pnk;

xaug = [xk;zeros(nl+vl,1)];

[Psq,resnorm] = sqrtm(Paug);
if (abs(resnorm) > 1e-14)
    fprintf('Error: matrix square root residual norm is %g.\n',resnorm);
    return;
end
Psq = real(Psq);

% compute the sigma points
XAUG = zeros(N,2*N+1);
XAUG(:,1) = xaug;
for k = 1:N
    XAUG(:,k+1) = xaug + gamm*Psq(:,k);
    XAUG(:,N+1+k) = xaug - gamm*Psq(:,k);
end

% propagate the sigma points
XAUGPLUS = updatefun(XAUG(1:n,:),XAUG(n+(1:vl),:),uk);

% weights
beta = 2;% optimal for Gaussian
wc = 0.5/(N+lambda)*ones(2*N+1,1);
wm = 0.5/(N+lambda)*ones(2*N+1,1);
wm(1) = lambda/(N+lambda);
wc(1) = lambda/(N+lambda) + 1-alpha^2+beta;

% calculate the update
xp = sum(XAUGPLUS(1:n,:).*repmat(wm',n,1),2);

% re-normalize
if isequal(updatefun,@update_eq_all) || isequal(updatefun,@update_eq_no_imu)
    xp(1:4) = xp(1:4)/norm(xp(1:4));
end
if isequal(updatefun,@update_eq_17_state)
    xp(7:10) = xp(7:10)/norm(xp(7:10));
    xp(14:17) = xp(14:17)/norm(xp(14:17));
end

Pp = zeros(n);
for k = 1:2*N+1
    Pp = Pp + wc(k)*(XAUGPLUS(1:n,k)-xp)*(XAUGPLUS(1:n,k)-xp)';
end

% pass the sigma points through the measurement function
YKAUG = measurementfun(XAUGPLUS(1:n,:),XAUG(n+vl+(1:nl),:),uk);

g = size(YKAUG,1);

yhat = sum(YKAUG.*repmat(wm',g,1),2);
% add something to handle magnetometer normalization if necessary here

% measurement covariance
Pyk = zeros(g);
% cross covariance
Pxkyk = zeros(n,g);
for k = 1:2*N+1
    Pyk = Pyk + wc(k)*(YKAUG(:,k)-yhat)*(YKAUG(:,k)-yhat)';
    Pxkyk = Pxkyk + wc(k)*(XAUGPLUS(1:n,k)-xp)*(YKAUG(:,k)-yhat)';
end

% Kalman gain
if any(any(isnan(Pyk)))
    disp('Singular measurement covariance');
    return;
end

Kk = Pxkyk*(Pyk\eye(g));

% handle special cases by examining the input function names
% minimize angle difference
if isequal(measurementfun, @measurement_eq_no_imu)
    yhat([2 3 5 6]) = minangle(yhat([2 3 5 6]),ytilde([2 3 5 6]));
    % normalize magnetometer
    yhat(7:9) = yhat(7:9)./norm(yhat(7:9));
end
if isequal(measurementfun, @measurement_eq_all)
    yhat([2 3 5 6]) = minangle(yhat([2 3 5 6]),ytilde([2 3 5 6]));
end
if isequal(measurementfun, @measurement_eq_no_range)
    yhat = minangle(yhat,ytilde);
end
if isequal(measurementfun, @measurement_eq_17_state)
    %minimize diff between bearing/declination angles to agents
    yhat([2 3 5 6]) = minangle(yhat([2 3 5 6]),ytilde([2 3 5 6]));
    % normalize magnetometer
    yhat(7:9) = yhat(7:9)./norm(yhat(7:9));
    % minimize diff between bearing/declination to features
    m1 = uk(10);
    m2 = uk(10 + 3*m1 + 1);
    yhat( (2:3:(3*m1)) + 9) = minangle(yhat( (2:3:(3*m1)) + 9),ytilde( (2:3:(3*m1)) + 9));
    yhat( (3:3:(3*m1)) + 9) = minangle(yhat( (3:3:(3*m1)) + 9),ytilde( (3:3:(3*m1)) + 9));
    yhat( 9 + 3*m1 + (2:3:3*m2) ) = minangle(yhat( 9 + 3*m1 + (2:3:3*m2) ),ytilde( 9 + 3*m1 + (2:3:3*m2) ));
    yhat( 9 + 3*m1 + (3:3:3*m2) ) = minangle(yhat( 9 + 3*m1 + (3:3:3*m2) ),ytilde( 9 + 3*m1 + (3:3:3*m2) ));
end

xnew = xp + Kk*(ytilde-yhat);

% renormalize quaternions as necessary
if isequal(updatefun,@update_eq_all) || isequal(updatefun,@update_eq_no_imu)
    xnew(1:4) = xnew(1:4)/norm(xnew(1:4));
end
if isequal(updatefun,@update_eq_17_state)
    xnew(7:10) = xnew(7:10)/norm(xnew(7:10));
    xnew(14:17) = xnew(14:17)/norm(xnew(14:17));
end
Pnew = Pp - Kk*Pyk*Kk';
end
