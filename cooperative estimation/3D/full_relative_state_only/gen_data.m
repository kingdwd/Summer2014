%% gen_data

clear variables;
close all;

addpath('../../2D');
addpath('../');

%% generate data

% measurement standard errors
% error stdev in agent-agent measurement
err_dev = 0.01;%rads
% error stdev in magnetometer
mag_dev = 0.01;%rads
% range sensing error
range_dev = 0.1;%metres

if ~exist('data_3d.mat','file');
    
    % sample time
    Ts = 0.01;
    % sim time
    Tmax = 30;
    
    % allowed position space
    R = 10;
    % target average speed
    Vb = 1.25;
    % number of agents
    N = 2;
    
    % data storage
    T = 0:Ts:Tmax;
    Yc = cell(N,1);
    
    for II = 1:N
        
        % initialize
        r = rand*2*R-R;
        theta = rand*2*pi - pi;
        phi = (rand-0.5)*pi;
        
        r0 = [r*cos(phi)*cos(theta);
            r*cos(phi)*sin(theta);
            r*sin(phi)];
        v0 = [0;0;0];
        q0 = rand(4,1);q0 = q0./norm(q0);
        garb = attpar(q0,[6 4],struct('seq',[1; 2; 1]));
        eul0 = garb(:,1);
        eul0dot = [0;0;0];
        
        tnow = 0;
        
        Y = zeros(length(T),13);% r1 r2 r3 v1 v2 v3 quat omega
        a0 = [0;0;0];
        count = 0;
        while(count < length(T))
            
            % pick a point in the space
            r = rand*2*R-R;
            theta = rand*2*pi - pi;
            phi = (rand-0.5)*pi;
            
            rf = [r*cos(phi)*cos(theta);
                r*cos(phi)*sin(theta);
                r*sin(phi)];
            vf = [0;0;0];
            % final time
            Tf = norm(rf-r0)/Vb;
            Tf = round(Tf/Ts)*Ts;% round to nearest sample time for simplicity
            % r0 proscribed
            
            % time vector, relative to last move
            t = 0:Ts:Tf;
            
            % generate coefficients for reference traj
            BC = [1 0 0 0 0;0 1 0 0 0;1 Tf Tf^2 Tf^3 Tf^4;0 1 2*Tf 3*Tf^2 4*Tf^3;0 0 2 0 0];% enforce continuity of accel at the start time
            for i = 1:3
                % coefficients
                vc(:,i) = BC\[r0(i);v0(i);rf(i);vf(i);a0(i)];
            end
            
            % reference attitude
            vran = rand(3,1);vran = vran./norm(vran);
            ref1 = [0 1 2 3 4]*vc;ref1 = ref1./norm(ref1);% body 1-axis reference, in inertial frame, at t = 1 sec
            ref2 = cross(ref1,vran);ref2 = ref2./norm(ref2);
            ref3 = cross(ref1,ref2);
            Cbn = [ref1' ref2' ref3']';
            
            % reference quaternion, scalar first
            qref = attpar(Cbn,[1 6]);
            garb = attpar(Cbn,[1 4],struct('seq',[1 2 1]'));
            eulref = garb(:,1);
            
            A = 2;
            
            eulref = minangle(eulref,eul0);
            
            eq = eul0 - eulref;
            
            lt = (1:length(t));
            if count+length(t) > length(T)
                lt = 1:(length(T)-count);
                t = t(lt);
            end
            
            qu = zeros(length(t),4);
            %eul = zeros(length(t),3);
            %euldot = zeros(length(t),3);
            omega = zeros(length(t),3);
            
            rc = zeros(4,3);
            EC = [1 0 0 0;0 1 0 0;1 Tf Tf^2 Tf^3;0 1 2*Tf 3*Tf^2];
            for i = 1:3
                %just do a polynomial for this also
                rc(:,i) = EC\[eul0(i);eul0dot(i);eulref(i);0];
                
                %eul(:,i) = eq(i)*exp(-A*t) + eulref(i);
                %euldot(:,i) = -A*eq(i)*exp(-A*t);
            end
            eul = [ones(length(t),1) t' t.^2' t.^3']*rc;
            euldot = [zeros(length(t),1) ones(length(t),1) 2*t' 3*t.^2']*rc;
            for i = 1:length(t)
                omega(i,:) = ([euldot(i,3);0;0] + DCMConverter(1,eul(i,3))*[0;euldot(i,2);0] + DCMConverter(1,eul(i,3))*DCMConverter(2,eul(i,2))*[euldot(i,1);0;0])';
                qu(i,:) = attpar([eul(i,:)' [1;2;1]],[4 6])';
            end
            
            Y(count+lt,1:3) = [ones(length(t),1) t' t.^2' t.^3' t.^4']*vc;
            Y(count+lt,4:6) = [zeros(length(t),1) ones(length(t),1) 2*t' 3*t.^2' 4*t.^3']*vc;
            Y(count+lt,7:10) = qu;
            Y(count+lt,11:13) = omega;
            Y(count+lt,14:16) = eul;     
            % store acceleration also
            Y(count+lt,17:19) = [zeros(length(t),1) zeros(length(t),1) 2*ones(length(t),1) 6*t' 12*t.^2']*vc;
            a0 = Y(count+lt(end),17:19);
            
            count = count+length(lt);
            tnow = tnow + t(end);
            
            % reset for next iteration
            r0 = Y(count,1:3)';
            v0 = Y(count,4:6)';
            q0 = Y(count,7:10)';
            eul0 = eul(end,:)';
            eul0dot = euldot(end,:)';
        end
        
        Y(:,7:10) = quatmin(Y(:,7:10));
        
        Yc{II} = Y;
    end
    
    save data_3d.mat;
else
    load data_3d.mat;
end
%% generate measurements for each 
if ~exist('meas','var')
    
    meas = cell(N,1);
    for II = 1:N
        meas{II} = zeros(length(T),(N-1)*3+3);
        Jcount = 0;
        for JJ = [1:II-1 II+1:N]
            Jcount = Jcount+1;
            % inertial vector from II to JJ
            rdiff = Yc{JJ}(:,1:3) - Yc{II}(:,1:3);
            % convert to body frame
            rsee = zeros(size(rdiff));
            rmeas = zeros(size(rdiff));
            for i = 1:length(T)
                quat = Yc{II}(i,7:10)';
                Cbn = attpar(quat,[6 1]);
                rsee(i,:) = rdiff(i,:)*Cbn';
                
                % generate error angle
                delta = randn*err_dev;
                % get arbitrary axis of rotation
                vec = rand(3,1);vec = vec./norm(vec);
                % get DCM from true to error "frame"
                Crp_r = attpar([vec [delta;0;0]],[2 1]);

                % get the measured range
                range_frac = (norm(rsee(i,:))+randn(1)*range_dev)/norm(rsee(i,:));
                
                % store the vector measurement (not unit vector)
                rmeas(i,1:3) = range_frac*rsee(i,:)*Crp_r;
            end
            
            meas{II}(:,(Jcount-1)*3+(1:3)) = rmeas;
        end
        % get magnetometer out
        rmeas = zeros(length(T),3);
        for i = 1:length(T)
            quat = Yc{II}(i,7:10)';
            % convert to body frame
            Cbn = attparsilent(quat,[6 1]);
            psiVec = Cbn(:,1);
            % generate error angle
            delta = randn*mag_dev;
            % get arbitrary axis of rotation
            vec = rand(3,1);vec = vec./norm(vec);
            % get DCM from true to error "frame"
            Crp_r = attpar([vec [delta;0;0]],[2 1]);
            %store the heading angle measurement (magnetometer)
            rmeas(i,1:3) = psiVec'*Crp_r;
        end
        meas{II}(:,Jcount*3+(1:3)) = rmeas;
    end
    save data_3d.mat;
end
