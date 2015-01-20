function [ xp,Pp ] = ekf_propagate_ranging_and_imu(xhat,uk,Pk,Qk,Ts)
%[xp,Pp] = ekf_propagete_ranging_and_imu(xhat,uk,Pk,Qk,Ts)

%xk: 20 x 2N+1, inertial position, inertial velocity, inertial quaternion, relative position, and relative quaternion ... then unknown feature parameters 

%uk[wi;wj;ai;aj;r(1,2,3)j/j] : 21 x 2N+1

n = length(xhat);
m = 12;

% state influence
F = zeros(n);
%``control'' influence
B = zeros(n,m);
% process noise influence
G = zeros(n,m);

xdot = zeros(n,1);

% his position relative to mine. My body frame
rji = xhat(11:13);
rji1 = xhat(11);
rji2 = xhat(12);
rji3 = xhat(13);
% my velocity
vin = xhat(4:6);
vin1 = xhat(4);
vin2 = xhat(5);
vin3 = xhat(6);
% my attitude
qin = xhat(7:10);
qin1 = xhat(7);
qin2 = xhat(8);
qin3 = xhat(9);
qin4 = xhat(10);
% his attitude relative to mine. His body frame
qji = xhat(14:17);
qji1 = xhat(14);
qji2 = xhat(15);
qji3 = xhat(16);
qji4 = xhat(17);
% his inertial velocity (his body frame)
vjn = xhat(18:20);
vjn1 = xhat(18);
vjn2 = xhat(19);
vjn3 = xhat(20);

% IMU measurements I made
wi = uk(1:3);
wi1 = uk(1);
wi2 = uk(2);
wi3 = uk(3);
wj = uk(4:6);
wj1 = uk(4);
wj2 = uk(5);
wj3 = uk(6);
ai = uk(7:9);
aj = uk(10:12);

v1 = 0;v2 = 0;v3 = 0;
v4 = 0;v5 = 0;v6 = 0;

Cin = attparsilent(qin,[6 1]);
Cji = attparsilent(qji,[6 1]);

%% compute the time derivative of the state
xdot(1:3) = Cin'*vin;
xdot(4:6) = ai - squiggle(wi)*vin;
% A matrix for qin
Ain = 0.5*[ -qin(2:4)';qin(1)*eye(3) + squiggle(qin(2:4))];
xdot(7:10) = Ain*wi;

xdot(11:13) = (Cji'*vjn-vin) - squiggle(wi)*rji;

% relative angular velocity in j frame
wji = wj-Cji*wi;
% A matrix for q_ji
A = 0.5*[ -qji(2:4)';qji(1)*eye(3) + squiggle(qji(2:4))];
% time rate of relative attitude
xdot(14:17) = A*wji;

xdot(18:20) = aj - squiggle(wj)*vjn;

%% state influence matrix
F(1:3,4:6) = [[ qin1^2 + qin2^2 - qin3^2 - qin4^2,         2*qin2*qin3 - 2*qin1*qin4,         2*qin1*qin3 + 2*qin2*qin4]
[         2*qin1*qin4 + 2*qin2*qin3, qin1^2 - qin2^2 + qin3^2 - qin4^2,         2*qin3*qin4 - 2*qin1*qin2]
[         2*qin2*qin4 - 2*qin1*qin3,         2*qin1*qin2 + 2*qin3*qin4, qin1^2 - qin2^2 - qin3^2 + qin4^2]];

F(4:6,4:6) = [[        0, wi3 - v3, v2 - wi2]
    [ v3 - wi3,        0, wi1 - v1]
    [ wi2 - v2, v1 - wi1,        0]];

F(7:10,7:10) = [[            0, v1/2 - wi1/2, v2/2 - wi2/2, v3/2 - wi3/2]
    [ wi1/2 - v1/2,            0, wi3/2 - v3/2, v2/2 - wi2/2]
    [ wi2/2 - v2/2, v3/2 - wi3/2,            0, wi1/2 - v1/2]
    [ wi3/2 - v3/2, wi2/2 - v2/2, v1/2 - wi1/2,            0]];

F(11:13,4:6) = -eye(3);
F(11:13,11:13) = [[        0, wi3 - v3, v2 - wi2]
    [ v3 - wi3,        0, wi1 - v1]
    [ wi2 - v2, v1 - wi1,        0]];
F(11:13,14:17) = [[ 2*qji1*vjn1 + 2*qji3*vjn3 - 2*qji4*vjn2, 2*qji2*vjn1 + 2*qji3*vjn2 + 2*qji4*vjn3, 2*qji1*vjn3 + 2*qji2*vjn2 - 2*qji3*vjn1, 2*qji2*vjn3 - 2*qji1*vjn2 - 2*qji4*vjn1]
    [ 2*qji1*vjn2 - 2*qji2*vjn3 + 2*qji4*vjn1, 2*qji3*vjn1 - 2*qji2*vjn2 - 2*qji1*vjn3, 2*qji2*vjn1 + 2*qji3*vjn2 + 2*qji4*vjn3, 2*qji1*vjn1 + 2*qji3*vjn3 - 2*qji4*vjn2]
    [ 2*qji1*vjn3 + 2*qji2*vjn2 - 2*qji3*vjn1, 2*qji1*vjn2 - 2*qji2*vjn3 + 2*qji4*vjn1, 2*qji4*vjn2 - 2*qji3*vjn3 - 2*qji1*vjn1, 2*qji2*vjn1 + 2*qji3*vjn2 + 2*qji4*vjn3]];
F(11:13,18:20) = Cji';

F(14:17,14:17) = [[                                                                                                                                               -qji1*(qji2*v1 + qji3*v2 + qji4*v3 - qji2*wi1 - qji3*wi2 - qji4*wi3), v4/2 - wj1/2 - (qji1^2*v1)/2 - (3*qji2^2*v1)/2 - (qji3^2*v1)/2 - (qji4^2*v1)/2 + (qji1^2*wi1)/2 + (3*qji2^2*wi1)/2 + (qji3^2*wi1)/2 + (qji4^2*wi1)/2 - qji2*qji3*v2 - qji2*qji4*v3 + qji2*qji3*wi2 + qji2*qji4*wi3, v5/2 - wj2/2 - (qji1^2*v2)/2 - (qji2^2*v2)/2 - (3*qji3^2*v2)/2 - (qji4^2*v2)/2 + (qji1^2*wi2)/2 + (qji2^2*wi2)/2 + (3*qji3^2*wi2)/2 + (qji4^2*wi2)/2 - qji2*qji3*v1 - qji3*qji4*v3 + qji2*qji3*wi1 + qji3*qji4*wi3, v6/2 - wj3/2 - (qji1^2*v3)/2 - (qji2^2*v3)/2 - (qji3^2*v3)/2 - (3*qji4^2*v3)/2 + (qji1^2*wi3)/2 + (qji2^2*wi3)/2 + (qji3^2*wi3)/2 + (3*qji4^2*wi3)/2 - qji2*qji4*v1 - qji3*qji4*v2 + qji2*qji4*wi1 + qji3*qji4*wi2]
    [ wj1/2 - v4/2 + (3*qji1^2*v1)/2 + (qji2^2*v1)/2 + (qji3^2*v1)/2 + (qji4^2*v1)/2 - (3*qji1^2*wi1)/2 - (qji2^2*wi1)/2 - (qji3^2*wi1)/2 - (qji4^2*wi1)/2 - qji1*qji3*v3 + qji1*qji4*v2 + qji1*qji3*wi3 - qji1*qji4*wi2,                                                                                                                                                qji2*(qji1*v1 - qji3*v3 + qji4*v2 - qji1*wi1 + qji3*wi3 - qji4*wi2), wj3/2 - v6/2 - (qji1^2*v3)/2 - (qji2^2*v3)/2 - (3*qji3^2*v3)/2 - (qji4^2*v3)/2 + (qji1^2*wi3)/2 + (qji2^2*wi3)/2 + (3*qji3^2*wi3)/2 + (qji4^2*wi3)/2 + qji1*qji3*v1 + qji3*qji4*v2 - qji1*qji3*wi1 - qji3*qji4*wi2, v5/2 - wj2/2 + (qji1^2*v2)/2 + (qji2^2*v2)/2 + (qji3^2*v2)/2 + (3*qji4^2*v2)/2 - (qji1^2*wi2)/2 - (qji2^2*wi2)/2 - (qji3^2*wi2)/2 - (3*qji4^2*wi2)/2 + qji1*qji4*v1 - qji3*qji4*v3 - qji1*qji4*wi1 + qji3*qji4*wi3]
    [ wj2/2 - v5/2 + (3*qji1^2*v2)/2 + (qji2^2*v2)/2 + (qji3^2*v2)/2 + (qji4^2*v2)/2 - (3*qji1^2*wi2)/2 - (qji2^2*wi2)/2 - (qji3^2*wi2)/2 - (qji4^2*wi2)/2 + qji1*qji2*v3 - qji1*qji4*v1 - qji1*qji2*wi3 + qji1*qji4*wi1, v6/2 - wj3/2 + (qji1^2*v3)/2 + (3*qji2^2*v3)/2 + (qji3^2*v3)/2 + (qji4^2*v3)/2 - (qji1^2*wi3)/2 - (3*qji2^2*wi3)/2 - (qji3^2*wi3)/2 - (qji4^2*wi3)/2 + qji1*qji2*v2 - qji2*qji4*v1 - qji1*qji2*wi2 + qji2*qji4*wi1,                                                                                                                                                qji3*(qji1*v2 + qji2*v3 - qji4*v1 - qji1*wi2 - qji2*wi3 + qji4*wi1), wj1/2 - v4/2 - (qji1^2*v1)/2 - (qji2^2*v1)/2 - (qji3^2*v1)/2 - (3*qji4^2*v1)/2 + (qji1^2*wi1)/2 + (qji2^2*wi1)/2 + (qji3^2*wi1)/2 + (3*qji4^2*wi1)/2 + qji1*qji4*v2 + qji2*qji4*v3 - qji1*qji4*wi2 - qji2*qji4*wi3]
    [ wj3/2 - v6/2 + (3*qji1^2*v3)/2 + (qji2^2*v3)/2 + (qji3^2*v3)/2 + (qji4^2*v3)/2 - (3*qji1^2*wi3)/2 - (qji2^2*wi3)/2 - (qji3^2*wi3)/2 - (qji4^2*wi3)/2 - qji1*qji2*v2 + qji1*qji3*v1 + qji1*qji2*wi2 - qji1*qji3*wi1, wj2/2 - v5/2 - (qji1^2*v2)/2 - (3*qji2^2*v2)/2 - (qji3^2*v2)/2 - (qji4^2*v2)/2 + (qji1^2*wi2)/2 + (3*qji2^2*wi2)/2 + (qji3^2*wi2)/2 + (qji4^2*wi2)/2 + qji1*qji2*v3 + qji2*qji3*v1 - qji1*qji2*wi3 - qji2*qji3*wi1, v4/2 - wj1/2 + (qji1^2*v1)/2 + (qji2^2*v1)/2 + (3*qji3^2*v1)/2 + (qji4^2*v1)/2 - (qji1^2*wi1)/2 - (qji2^2*wi1)/2 - (3*qji3^2*wi1)/2 - (qji4^2*wi1)/2 + qji1*qji3*v3 - qji2*qji3*v2 - qji1*qji3*wi3 + qji2*qji3*wi2,                                                                                                                                                qji4*(qji1*v3 - qji2*v2 + qji3*v1 - qji1*wi3 + qji2*wi2 - qji3*wi1)]];

F(18:20,18:20) = [[        0, wj3 - v6, v5 - wj2]
    [ v6 - wj3,        0, wj1 - v4]
    [ wj2 - v5, v4 - wj1,        0]];
%% control influence matrix
B(4:6,1:3) = [[     0, -vin3,  vin2]
[  vin3,     0, -vin1]
[ -vin2,  vin1,     0]];
B(4:6,7:9) = eye(3);

B(7:10,1:3) = [[ -qin2/2, -qin3/2, -qin4/2]
[  qin1/2, -qin4/2,  qin3/2]
[  qin4/2,  qin1/2, -qin2/2]
[ -qin3/2,  qin2/2,  qin1/2]];

B(11:13,1:3) = [[     0, -rji3,  rji2]
[  rji3,     0, -rji1]
[ -rji2,  rji1,     0]];

B(14:17,1:3) = [[  qji2/2,  qji3/2,  qji4/2]
[ -qji1/2, -qji4/2,  qji3/2]
[  qji4/2, -qji1/2, -qji2/2]
[ -qji3/2,  qji2/2, -qji1/2]];
B(14:17,4:6) = [[ -qji2/2, -qji3/2, -qji4/2]
[  qji1/2, -qji4/2,  qji3/2]
[  qji4/2,  qji1/2, -qji2/2]
[ -qji3/2,  qji2/2,  qji1/2]];

B(18:20,4:6) = [[     0, -vjn3,  vjn2]
[  vjn3,     0, -vjn1]
[ -vjn2,  vjn1,     0]];
B(18:20,10:12) = eye(3);
%% process noise influence matrix
G = -B;
%% propagate
% euler appx
xp = xhat + Ts*xdot;

F = F*Ts+eye(n);
B = Ts*B;
G = Ts*G;

Pp = F*Pk*F' + G*Qk*G';

% normalize quaternions
xp(14:17) = xp(14:17)/norm(xp(14:17));
xp(7:10) = xp(7:10)/norm(xp(7:10));
end