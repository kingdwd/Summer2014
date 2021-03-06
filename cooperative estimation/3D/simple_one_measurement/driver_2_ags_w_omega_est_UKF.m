clear variables;
close all;

global Ts;

addpath('../../2D');
addpath('../');

if ~exist('data_3d.mat','file');
    disp('Error: generate data first');
    return;
end

load('data_3d.mat');

%% process

% measurement error in IMU
% aassume both agents have same IMU noise:
Qk = diag([1e-6*[1 1 1] ...% component for measured ang. vel uncertainty
    (.05/3)^2*[1 1 1]]);% component for estimated ang. vel uncertainty, tuned empirically

% generate IMU histories
W = zeros(length(T),6);
for k = 1:length(T)
    W(k,1:3) = Yc{1}(k,11:13) + randn(1,3).*diag(sqrt(Qk(1:3,1:3)))';
    W(k,4:6) = Yc{2}(k,11:13) + randn(1,3).*diag(sqrt(Qk(1:3,1:3)))';
end

% compute truth
qji = zeros(length(T),4);
for k = 1:length(T)
    Cin = attparsilent(Yc{1}(k,7:10)',[6 1]);
    Cjn = attparsilent(Yc{2}(k,7:10)',[6 1]);
    Cji = Cjn*Cin';
    qji_tr = attparsilent(Cji,[1 6]);
    qji(k,:) = qji_tr';
end
qji = quatmin(qji);

xh = cell(2,1);
Ph = cell(2,1);

tv = T;

for i = 1:2
    xh{i} = zeros(length(tv),7);
    Ph{i} = zeros(length(tv),49);
    %xh{i}(1,:) = [1 0 0 0];
    xh{i}(1,1:4) = randn(4,1);xh{i}(1,1:4) = xh{i}(1,1:4)./norm(xh{i}(1,1:4));
    xh{i}(1,5:7) = 0;% initialize ang vel to zero. is estimate of j's ang vel in j's frame
    Ph{i}(1,:) = reshape( .1*eye(7) + 1e-8*ones(7), 49,1)';
end

%% use exact initial conditions
xh{1}(1,1:4) = qji(1,:);
xh{1}(1,5:7) = Yc{2}(1,11:13);
xh{2}(1,1:4) = qji(1,:);xh{2}(1,1) = -xh{2}(1,1);
xh{2}(1,5:7) = Yc{1}(1,11:13);

%
Rx = zeros(6);
% measurement error
errnom = [1e-8 err_dev err_dev].^2;

tic;
for j = 1:2
    for k = 1:length(T)-1
        %% update
        xhat = xh{j}(k,:)';
        Pk = reshape(Ph{j}(k,:)',7,7);
        
        if j == 1
            % my measured angular velocity
            wi = W(k,1:3)';
        else
            % my measured angular velocity
            wi = W(k,4:6)';
        end
        % his measured angular velocity
        wj = xhat(5:7);
        if j == 1
            % his meas of me
            rij_j = meas{2}(k,(1:3))';
        else
            rij_j = meas{1}(k,(1:3))';
        end
        % my meas of him
        rji_i = meas{j}(k,(1:3))';
        
        r2 = cross(rji_i,[1;0;0]);r2 = r2./norm(r2);
        r3 = cross(rji_i,r2);
        Crt_b(2,:) = r2';
        Crt_b(3,:) = r3';
        
        % error covariance associated with rji_i
        Rx(1:3,1:3) = Crt_b'*diag(errnom)*Crt_b;
        
        % repeat for rij_j2
        Crt_b = zeros(3);
        Crt_b(1,:) = rij_j';
        r2 = cross(rij_j,[1;0;0]);r2 = r2./norm(r2);
        r3 = cross(rij_j,r2);
        Crt_b(2,:) = r2';
        Crt_b(3,:) = r3';
        
        % error covariance associated with rij_j, in its frame
        Rx(4:6,4:6) = Crt_b'*diag(errnom)*Crt_b;
        
        uk = [wi;rji_i];
        
        yk = -rij_j;
        Pvk = Qk;
        
        Pnk = Rx;
        
        [xp,Pp] = ukf_update(xhat,Pk,Pvk,Pnk,uk,yk,@update_eq_2_ags_omega,@measurement_eq_2_ags_omega);
        
        if any(any(isnan(Pp)))
            disp('Error: NaN in covariance output');
            return;
        end
        
        % store
        xh{j}(k+1,:) = xp';
        Ph{j}(k+1,:) = reshape(Pp,49,1)';
        if ~mod(k-1,100)
            etaCalc(k,length(T),toc);
        end
    end
end

%% evaluate results

close all;
figure;

Pdiag = 1:8:49;

qji_in = interp1(T,qji,tv);

xh{1}(:,1:4) = quatmin(xh{1}(:,1:4),qji_in);
xh{2}(:,1:4) = quatmin(xh{2}(:,1:4),[-qji_in(:,1) qji_in(:,2:4)]);

for k = 1:4
    subplot(2,2,k);
    plot(tv,xh{1}(:,k),'--x');
    hold on;
    plot(tv,xh{1}(:,k) + 2*sqrt(Ph{1}(:,Pdiag(k))),'r--');
    plot(tv,xh{1}(:,k) - 2*sqrt(Ph{1}(:,Pdiag(k))),'r--');
    plot(T,qji(:,k),'k-','linewidth',2);
    set(gca,'ylim',[-1 1]);
end

figure;
for k = 1:4
    subplot(2,2,k);
    plot(tv,xh{2}(:,k),'--x');
    hold on;
    plot(tv,xh{2}(:,k) + 2*sqrt(Ph{2}(:,Pdiag(k))),'r--');
    plot(tv,xh{2}(:,k) - 2*sqrt(Ph{2}(:,Pdiag(k))),'r--');
    if k == 1
        plot(T,-qji(:,k),'k-','linewidth',2);
    else
        plot(T,qji(:,k),'k-','linewidth',2);
    end
    set(gca,'ylim',[-1 1]);
end

% compute error quaternions
q_err1 = zeros(length(tv),1);
q_err2 = zeros(length(tv),1);
for i = 1:length(tv)
    %truth
    Cji = attpar(qji_in(i,:)',[6 1]);
    Cji_1 = attpar(xh{1}(i,:)',[6 1]);
    Cij_2 = attpar(xh{2}(i,:)',[6 1]);
    % error DCMs
    Ct_1 = Cji_1'*Cji;
    Ct_2 = Cij_2'*Cji';
    %error quaternions
    gar1 = attpar(Ct_1,[1 2]);
    q_err1(i) = gar1(1,2);
    gar2 = attpar(Ct_2,[1 2]);
    q_err2(i) = gar2(1,2);
end

figure;

subplot(211);
plot(tv, q_err1);
ylabel('agent 1 pointing error (rad)');

subplot(212);
plot(tv, q_err2);
ylabel('agent 2 pointing error (rad)');

% agent 1 estimate of 2's angular velocity
figure;
for j = 1:3
    subplot(3,1,j);
    plot(tv,xh{1}(:,j+4));
    hold on;
    plot(tv,xh{1}(:,j+4) + 3*sqrt(Ph{1}(:,Pdiag(j+4))),'r--');
    plot(tv,xh{1}(:,j+4) - 3*sqrt(Ph{1}(:,Pdiag(j+4))),'r--');
    plot(tv,Yc{2}(:,j+10),'--')
end

% agent 2 estimate of 1's angular velocity
figure;
for j = 1:3
    subplot(3,1,j);
    plot(tv,xh{2}(:,j+4));
    hold on;
    plot(tv,xh{2}(:,j+4) + 3*sqrt(Ph{2}(:,Pdiag(j+4))),'r--');
    plot(tv,xh{2}(:,j+4) - 3*sqrt(Ph{2}(:,Pdiag(j+4))),'r--');
    plot(tv,Yc{1}(:,j+10),'--')
end

%% compute state-predicted output
ypred = zeros(length(tv),6);
for k = 1:length(tv)
    for j = 1:2
        if j == 1
            % my measured angular velocity
            wi = W(k,1:3)';
        else
            % my measured angular velocity
            wi = W(k,4:6)';
        end
        % my meas of him
        rji_i = meas{j}(k,(1:3))';
        
        uk = [wi;rji_i];
        
        ypred(k,(j-1)*3+(1:3)) = measurement_eq_2_ags_omega(xh{j}(k,:)',zeros(6,1),uk)';
    end
end

figure;
subplot(211);
plot(tv,ypred(:,1:3))
hold on
plot(tv,-meas{2}(:,1:3),'--')
title('Agent 1 state-predicted output of agent 2''s measurements');

subplot(212);
plot(tv,ypred(:,4:6))
hold on
plot(tv,-meas{1}(:,1:3),'--')
title('Agent 2 state-predicted output of agent 1''s measurements');