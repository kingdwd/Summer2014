%% run_simple_coop_stat
%main file for running the cooperative estimation case. Data should be
%loaded and called outside of here, plots should be called outside, etc.,
%but this file generates data. Does not clear variables.
% 
% uses statistical linearization to get the computed covariance for
% cooperative measurements, instead of Jacobian

global marksUsed xhatk Qk;

marksVar = cell(N,1);
constrVar = cell(N,1);
for i = 1:N
    marksVar{i} = nan(length(tspan),M);
    constrVar{i} = nan(length(tspan),M);
end

%% initialize

tk = [sort([tspan tspan]) tspan(end)+Ts];
xk(N) = struct('xk',zeros(length(tspan)*2+1,5),'Pk',zeros(length(tspan)*2+1,25));
ye = cell(length(tspan),N);
for i = 1:N
    xk(i) = struct('xk',zeros(length(tspan)*2+1,5),'Pk',zeros(length(tspan)*2+1,25));
    %intialize state
    xk(i).xk(1,:) = ags(i).truth(1,1:5)';
    % convert inertial position to the body frame
    xk(i).xk(1,1:2) = ags(i).truth(1,1:2)*[cos(ags(i).truth(1,5)) -sin(ags(i).truth(1,5));
        sin(ags(i).truth(1,5)) cos(ags(i).truth(1,5))];
    %xk(i).xk(1,:) = xk(i).xk(1,:)+randn(1,5).*[.1 .1 .1 .1 .01];
    %initialize covariance
    xk(i).Pk(1,:) = reshape( diag([.1 .1 .1 .1 .1]) +.001*ones(5), 25,1)';
    %xk(i).Pk(1,:) = reshape( diag([2 2 .04 .04 .01]) +.01*ones(5), 25,1)';
end
%% loop over all times

Qk = Rimu;%*Ts;

tic;
for i = 1:length(tspan)
    %% update new measurements
    for j = 1:N
        ytilde = zeros(2*M,1);% doing this the lazy way for now
        yexp = zeros(2*M,1);
        Hk = zeros(2*M,5);
        % initialize the covariance matrix
        Rk = zeros(2*M);
        
        x0hat = xk(j).xk(2*i-1,1:5)';% rix,riy,u,v,psi - all are in body frame
        P0hat = reshape(xk(j).Pk(2*i-1,:)',5,5);
        psii = x0hat(5);
        rix = x0hat(1);
        riy = x0hat(2);
        
        measurement_count = 0;
        
        % iterate over the readmask
        if bitand(readmask,8) || bitand(readmask,4)
            % check that we are in the agent's FOV
            if bitand(readmask,8)
                % loop over each landmark
                for m = 1:M
                    if abs(ags(j).rb(i,m+M)) <= d2r*FOV(j) && abs(ags(j).rb(i,m)) < RANGE(j) && abs(ags(j).rb(i,m)) > RANGEMIN(j)%check that the measurement is less than the FOV
                        measurement_count = measurement_count+1;
                        ytilde(measurement_count) = ags(j).rb(i,m);
                        % measurement noise covariance
                        Rk(measurement_count,measurement_count) = Rrange(j);
                        %compute expectation
                        rkx = marks(m).xy(1);
                        rky = marks(m).xy(2);
                        Cbn = [cos(psii) sin(psii);-sin(psii) cos(psii)];
                        rki_b = Cbn*[rkx;rky]-[rix;riy];%body frame expectation of relative vector
                        rhoki = sqrt(sum( rki_b.^2 ));
                        yexp(measurement_count) = rhoki;
                        % compute gradient
                        Hk(measurement_count,:) = [-(2*rkx*cos(psii) - 2*rix + 2*rky*sin(psii))/(2*((riy - rky*cos(psii) + rkx*sin(psii))^2 + (rkx*cos(psii) - rix + rky*sin(psii))^2)^(1/2))
                            (2*riy - 2*rky*cos(psii) + 2*rkx*sin(psii))/(2*((riy - rky*cos(psii) + rkx*sin(psii))^2 + (rkx*cos(psii) - rix + rky*sin(psii))^2)^(1/2))
                            0
                            0
                            (2*(rkx*cos(psii) + rky*sin(psii))*(riy - rky*cos(psii) + rkx*sin(psii)) + 2*(rky*cos(psii) - rkx*sin(psii))*(rkx*cos(psii) - rix + rky*sin(psii)))/(2*((riy - rky*cos(psii) + rkx*sin(psii))^2 + (rkx*cos(psii) - rix + rky*sin(psii))^2)^(1/2))]';
                    end
                end
            end
            if bitand(readmask,4)
                % new bearing measures of landmarks
                %loop over each landmark
                for m = 1:M
                    if abs(ags(j).rb(i,m+M)) <= d2r*FOV(j) && abs(ags(j).rb(i,m)) < RANGE(j) && abs(ags(j).rb(i,m)) > RANGEMIN(j)%check that the measurement is less than the FOV
                        measurement_count = measurement_count+1;
                        % store measurement
                        ytilde(measurement_count) = ags(j).rb(i,M+m);
                        Rk(measurement_count,measurement_count) = Rbear(j);
                        % expectation
                        rkx = marks(m).xy(1);
                        rky = marks(m).xy(2);
                        Cbn = [cos(psii) sin(psii);-sin(psii) cos(psii)];
                        rki_b = Cbn*[rkx;rky]-[rix;riy];%body frame expectation of relative vector
                        % store expectation
                        yexp(measurement_count) = atan2(rki_b(2),rki_b(1));
                        % minimize the difference in the two angles
                        yexp(measurement_count) = minangle(yexp(measurement_count),ytilde(measurement_count));
                        % compute gradient
                        Hk(measurement_count,:) = [-(riy - rky*cos(psii) + rkx*sin(psii))/(rix^2 - 2*cos(psii)*rix*rkx - 2*sin(psii)*rix*rky + riy^2 + 2*sin(psii)*riy*rkx - 2*cos(psii)*riy*rky + rkx^2 + rky^2)
                            -(rkx*cos(psii) - rix + rky*sin(psii))/(rix^2 - 2*cos(psii)*rix*rkx - 2*sin(psii)*rix*rky + riy^2 + 2*sin(psii)*riy*rkx - 2*cos(psii)*riy*rky + rkx^2 + rky^2)
                            0
                            0
                            (rix*(rkx*cos(psii) + rky*sin(psii)) + riy*(rky*cos(psii) - rkx*sin(psii)) - rkx^2 - rky^2)/(rix^2 - 2*cos(psii)*rix*rkx - 2*sin(psii)*rix*rky + riy^2 + 2*sin(psii)*riy*rkx - 2*cos(psii)*riy*rky + rkx^2 + rky^2)]';
                    end
                end
            end
        end
        if bitand(readmask,2) || bitand(readmask,1)
            % increment the relative sharing counter
            % only do this the first time since all agents use the same counter 
            if j == 1
                update_counter = update_counter+1;
            end
            if update_counter == K_update % check if it's time to get a shared measurement
                if j == N
                    % only reset the counter after all of the agents have
                    % checked for sharing measurements fun time
                    update_counter = 0;
                end
                cooperative_count = 0;
                for j2 = [1:j-1 j+1:N]
                    % index used because each agent stores its
                    % measurements of the other agents differently than
                    % the `global' index
                    j2ind = j2;
                    if j2ind > j
                        j2ind = j2ind-1;
                    end
                    jjind = j;
                    if jjind > j2
                        jjind = jjind-1;
                    end
                    % marksUsed: vector of which landmarks are visible
                    marksUsed = zeros(M,1);
                    % measured range to other agent
                    rhoji = ags(j).rb_agent(i,(j2ind-1)*2+1);
                    % measured bearing to other agent
                    thetaji = ags(j).rb_agent(i,(j2ind-1)*2+2);
                    % measured bearing by other agent to current agent
                    thetaij = ags(j2).rb_agent(i,(jjind-1)*2+2);
                    % delta is the relative heading, equals psi_j - psi_i
					delta1 = atan2(sin(thetaji)-cos(thetaji)*tan(thetaij),sin(thetaji)*tan(thetaij)+cos(thetaji));
                    delta2 = delta1 - pi;
                    % Rx is the covariance of uncertain values in the computed
                    % measurements
                    % these terms are: [rhoji thetaji thetaij {thetakj forall k}]
                    Rx = zeros(M+6);
                    Rx(1:3,1:3) = diag([Rrange_ag Rbear_ag Rbear_ag]);%initalize R for te fixed quantities only
                    %Rx(4:6,4:6) = P0hat([1 2 5],[1 2 5]);
                    % vector of the real measurements, used for statistical linearization 
                    yeff = zeros(M+6,1);
                    yeff(1:3) = [rhoji;thetaji;thetaij];
                    %yeff(4:6) = [rix;riy;psii];
                    % loop over each landmark
                    for m = 1:M
                        % landmark position in inertial frame
                        rkx = marks(m).xy(1);
                        rky = marks(m).xy(2);
                        if abs(ags(j2).rb(i,m+M)) <= d2r*FOV(j2) && abs(ags(j2).rb(i,m)) < RANGE(j2) && abs(ags(j2).rb(i,m)) > RANGEMIN(j2)
                            marksUsed(m) = 1;
                            if bitand(readmask,1)
                                cooperative_count = cooperative_count + 1;
                                measurement_count = measurement_count+1;
                                % other agent's bearing measure
                                thetakj = ags(j2).rb(i,m+M);
                                % we have to get the ESTIMATED range from i to k,
                                % and covariance, from my estiamted state
                                Cbin = [cos(psii) sin(psii);-sin(psii) cos(psii)];%inertial-to-b_i transformation
                                rki_bi = Cbin*[rkx;rky]-[rix;riy];%body frame expectation of relative vector
                                    rkj_bi = rki_bi - rhoji*[cos(thetaji);sin(thetaji)];
                                delta = thetaji + pi - thetaij;
                                % constraint equation
                                ytilde(measurement_count) = [cos(thetakj+delta) sin(thetakj+delta)]*rkj_bi - sqrt(sum(rkj_bi.^2));
                                % expectation
                                yexp(measurement_count) = 0;
                                % add bearing measurement variance term to Rx
                                Rx(3+cooperative_count,3+cooperative_count) = Rbear(j2);
                                % store values for the statistical linearization
                                yeff(3+cooperative_count) = thetakj;%bearing
                                % compute gradient of constraint equation
								Hk(measurement_count,:) = ([cos(thetakj+delta) sin(thetakj+delta)]-rkj_bi'/sqrt(sum(rkj_bi.^2)))*[-eye(2) zeros(2,2) [-sin(psii) cos(psii);-cos(psii) -sin(psii)]*[rkx;rky] ];
                            end
                        end
                    end
                    if cooperative_count > 0
                        xhatk = [rix;riy;psii];
                        [y,Py] = statisticalLinearization(yeff(1:3+cooperative_count),Rx(1:3+cooperative_count,1:3+cooperative_count),@coopFunctionBearingOnly);
                        marksVar{j}(i,find(marksUsed)) = diag(Py);
                        constrVar{j}(i,find(marksUsed)) = y;
                        %constrVar{j}(i,find(marksUsed)) = (ytilde((measurement_count-cooperative_count+1):measurement_count)-yexp((measurement_count-cooperative_count+1):measurement_count))';
                        Rk(measurement_count-(cooperative_count)+1:measurement_count,measurement_count-(cooperative_count)+1:measurement_count) = Py;
                        %Rk(measurement_count-(cooperative_count)+1:measurement_count,measurement_count-(cooperative_count)+1:measurement_count) = ...
                        %    Jac(1:cooperative_count,1:6+cooperative_count)*Rx(1:6+cooperative_count,1:6+cooperative_count)*Jac(1:cooperative_count,1:6+cooperative_count)';
                        ytilde((measurement_count-cooperative_count+1):measurement_count) = y;
                    end
                end
            end
        end
        % if we get a new measurement, append it to the current list and
        % compute the expectation and gradient
        if measurement_count > 0
            % kalman gain
            if rank(Hk(1:measurement_count,:)*P0hat*Hk(1:measurement_count,:)' + Rk(1:measurement_count,1:measurement_count)) < measurement_count
                % if ill-conditioned, skip
                disp('singular matrix inversion, stopping');
                return;
            else
                Kk = P0hat*Hk(1:measurement_count,:)'*((Hk(1:measurement_count,:)*P0hat*Hk(1:measurement_count,:)' + Rk(1:measurement_count,1:measurement_count))\eye(measurement_count));
                % update estimate
                x0hat = x0hat + Kk*(ytilde(1:measurement_count)-yexp(1:measurement_count));
                % update covariance
                P0hat = (eye(size(Kk,1),size(Hk,2))-Kk*Hk(1:measurement_count,:))*P0hat;
            end
        end
        % store values
        xk(j).xk(2*i,:) = x0hat';
        xk(j).Pk(2*i,:) = reshape(P0hat,25,1)';
    end
    %% propagate
    for j = 1:N
        x0hat = xk(j).xk(2*i,:)';
        P0hat = reshape(xk(j).Pk(2*i,:)',5,5);
        imu = ags(j).IMU(i,:)';% a1 a2 omega
        ym = [x0hat;reshape(P0hat,25,1)];
        for counting = 1:10
            yp = rk45(ym,imu,.1*Ts,@propagate);
            ym = yp;
        end
        x0hat = ym(1:5);
        P0hat = reshape(yp(6:30),5,5);
%         
%         ri = x0hat(1:2);%body frame position vector
%         vi = x0hat(3:4);%body frame velocity vector
%         psii = x0hat(5);%heading
%         omega = imu(3);
%         ai = imu(1:2);
%         % dxhat/dt
%         f = [vi - [0 -omega;omega 0]*ri;
%             ai - [0 -omega;omega 0]*vi;
%             omega];
%         %gradient of f
%         Fk = [ -[0 -omega;omega 0] eye(2) zeros(2,1);
%             zeros(2) -[0 -omega;omega 0] zeros(2,1);
%             zeros(1,5)];
%         % account for the discretized integration in Fk:
%         Fk = Ts*Fk + eye(5);
%         % process noise influence matirx
%         G = zeros(5,3);
%         G(3:5,1:3) = Ts*[-1 0 -vi(2);
%             0 -1 vi(1);
%             0 0 -1];
%         %update
%         x0hat = x0hat + Ts*f;
         x0hat(5) = pi2pi(x0hat(5));
%         P0hat = Fk*P0hat*Fk' + G*Qk*G';% + Ts^2*eye(5);
        % store new values
        xk(j).xk(2*i+1,:) = x0hat';
        xk(j).Pk(2*i+1,:) = reshape(P0hat,25,1)';
    end
    if ~mod(i-1,.1*(length(tspan)-1))
        etaCalc(i,length(tspan),toc);
    end
end