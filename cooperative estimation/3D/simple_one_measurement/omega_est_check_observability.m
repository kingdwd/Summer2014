%% omega_est_check_observability

% quaternion
syms beta0 beta1 beta2 beta3 real;
syms w1 w2 w3 real;
syms wi1 wi2 wi3 real;
beta = [beta1;beta2;beta3];

%Cji = attpar([beta0;beta],[6 1]);
%Cji = eye(3) - 2*squiggle(beta)*beta0 + 2*squiggle(beta)*squiggle(beta);
syms phi theta psi real;
Cji = DCMConverter(1,phi)*DCMConverter(2,theta)*DCMConverter(3,psi);

rji = sym('rji',[3 1]);
rij = sym('rij',[3 1]);
wi = [wi1;wi2;wi3];% my measured ang. vel.

yest = -Cji*rji - rij;

%xhat = [beta0;beta;w1;w2;w3];
xhat = [phi;theta;psi;w1;w2;w3];

% get the H matrix
H = 0*sym('H',[3 7]);

for k = 1:7
    H(:,k) = factor(simplify(diff(yest,xhat(k))));
end

% get the F matrix

A = 0.5*[ -xhat(2:4)';xhat(1)*eye(3) + squiggle(xhat(2:4))];
% relative angular velocity, includes estimate term
%w = -Cji*wi;
w = xhat(5:7) - Cji*wi;

xdot = simplify([A*w;0;0;0]);

F = 0*sym('F',[7 7]);
for k = 1:7
    F(:,k) = factor(simplify(diff(xdot,xhat(k))));
end

% verify F with the form used in the numerical simulation
bs = squiggle(beta);
wp = xhat(5:7)-wi;
Fk = 0*F;
Fk(1:4,1:4) = 0.5*[0 -wp';wp -squiggle(wp)] + [zeros(1,4);2*beta0*squiggle(beta)*wi -beta0^2*squiggle(wi)+squiggle(bs*bs*wi)+bs*squiggle(bs*wi)+bs*bs*squiggle(wi)];
Fk(1:4,5:7) = A;

% observability matrix, 7th order
O = 0*sym('O',[21 length(xhat)]);
O(1:3,:) = H;
% it can't handle more than 3 iterations, but 3 is enough to make it think
% the thing is full rank
%for k = 2:3
%    O((1:3)+(k-1)*3,:) = simplify(O((1:3)+(k-2)*3,:)*F);
%end