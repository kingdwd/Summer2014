function yk = measurement_eq_2_ags(xk,nk,uk)

%xk: 4 x 2N+1
%nk: 6 x 2N+1

%uk[wi;wj;rji_i]

n = size(xk,1);
l = size(nk,1);

rji_i = uk(7:9);

yk = zeros(3,size(xk,2));
for k = 1:size(xk,2)
    xhat = xk(:,k);
    
    Cji = attparsilent(xhat,[6 1]);
    
    yk(:,k) = Cji*(rji_i-nk(1:3,k))+nk(4:6,k);
end

end