clc; clear; close all;

n           = 2048;
m           = 839;
s           = 20;

start = tic;
fprintf(' Start to generate the compressed sensing data...\n');

%%  Huawei A*(The correlation is 0.0345)
A   = zeros(m,n);
for m1 = 1:839
    for n1 = 1:832
        A(m1,n1) = exp(1i*420*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n1-1)/839);
    end
    for n2 = 833:1664
        A(m1,n2) = exp(1i*419*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n2-833)/839);
    end
    for n3 = 1665:2048
        A(m1,n3) = exp(1i*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n3-1665)/839);
    end
end
%% Huawei A**(839x5952��The correlation is 0.0345 )
% A   = zeros(m,n);
% for m1 = 1:839
%     for n1 = 1:837
%         A(m1,n1) = exp(1i*420*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n1-1)/839);
%     end
%     for n2 = 838:1674
%          A(m1,n2) = exp(1i*419*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n2-838)/839);
%     end
%     for n3 = 1675:2511
%         A(m1,n3) = exp(1i*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n3-1675)/839);
%     end
%     for n4 = 2512:3348
%         A(m1,n4) = exp(1i*838*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n4-2512)/839);
%     end
%     for n5 = 3349:4185
%         A(m1,n5) = exp(1i*15*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n5-3349)/839);
%     end
%     for n6 = 4186:5022
%          A(m1,n6) = exp(1i*824*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n6-4186)/839);
%     end
%     for n7 = 5023:5859
%         A(m1,n7) = exp(1i*427*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n7-5023)/839);
%     end
%     for n8 = 5860:5952
%         A(m1,n8) = exp(1i*412*pi*m1*(m1-1)/839)*exp(1i*2*pi*(m1-1)*(n8-5860)/839);
%     end
% end

%%
A = A./sqrt(839);
data.A  = A;       % ��normalization����

% n00 = randperm(64,s);  % �����̶������û�
load('n00', 'n00');
Reaj = zeros(1,64);    % ��ʼ����Ϊ�Ǽ���״̬
Reaj(n00) = 1;         % ����1��ʾ�û����0��ʾ�û�δ����

data.At = data.A';
clear Ax Ay m1 n1 m2 n2
fprintf(' Data generation used %2.4f seconds.\n\n',toc(start));

pars.draw = 1;
pars.eta  = 1;

% �ظ���������龯���ʸ���
% Iter  = 2000;
Iter  = 2000;
OBJ   = zeros(Iter,1);
iter  = zeros(Iter,1);
Time  = zeros(Iter,1);
Err   = zeros(Iter,1);

b  = zeros(m,1) ;

fprintf(' \n ���   sigma    CPUʱ��     ������     Ŀ��ֵ    ��������    �龯����    ©�����   ��ֵ \n');
fprintf('\n ------------------------------------------------------------------------------------------\n');

Var =[0.0006,0.0008,0.0009,0.001,0.0011,0.0012,0.0013,0.0014,0.0015,0.002,0.003,0.004,0.005,0.006,0.007,0.008,0.01,0.02,0.04,0.06,0.08,0.10];
Threshold   = [0.050,0.070,0.070,0.090,0.095,0.097,0.097,0.10,0.11,0.12,0.16,0.20,0.22,0.24,0.26,0.29,0.32,0.44,0.65,0.80,0.93,1.00];

xbeta  = sqrt(0.5*1);
v   = 1;
mis = zeros(length(Var),1);
fal = zeros(length(Var),1);
%for v=1:length(Var)
while v < length(Var)+1
    var = Var(v);
    RA_C = zeros(1,64);
    for i =1: Iter
        x0     = zeros(32,64);
        for n0 = n00
            m0 = randperm(32,1);
            x0(m0,n0) = xbeta*randn+1i*xbeta*randn;
        end
        x0     = x0(:);
        %   data.x_opt = x0;
        noise_sigma = sqrt(0.5*var);
        noise   = noise_sigma*randn(m,1)+ 1i*noise_sigma*randn(m,1);
        b  = A*x0 + noise;
        data.b  = b;               %  �޸Ĳ���
        out1   = BNHTP(n,s,data,pars);
        % x00  = out1.sol;
        x00   = out1.sol.*(abs(out1.sol)>Threshold(v));   % ��ֵ����
        Rec   = reshape(x00,32,64);       % �ָ�ֵ
        Recj  = (sign(sum(abs(Rec)))) ;   % �ָ�ֵ�ļ����û���
        Ra_c  = Reaj-Recj  ;              % ���Ԫ����+1����©�죬�����-1�����龯
        RA_C  = RA_C+Ra_c;
        OBJ(i)  = out1.obj;
        iter(i) = out1.iter;
        Time(i) = out1.time;
        Err(i)  = norm(x0-x00)/norm(x0);
    end
    
    rA_C  = RA_C/Iter ;
    Fal   = abs( sum(rA_C(rA_C<0))/(64-s)) ;
    Mis   = sum(rA_C(rA_C>0))/(s) ;
    
    if Fal-0.001>0.00015&& Fal >0.0002     % Fal-0.001>0.0001 && Fal >0.0002
        if var < 0.002
        Threshold(v)  = Threshold(v)+0.0025;  % Threshold(v)+0.0025; 
        else
        Threshold(v)  = Threshold(v)+0.005; 
        end
    elseif Fal > 0.0012
        Threshold(v)  = Threshold(v)+ 0.0225;
    elseif 0.001 - Fal > 0.00015          %  elseif 0.001 - Fal > 0.0001
        Threshold(v)  = Threshold(v)-0.0225;
    else
        fprintf('\n   %d',  v);
        fprintf('   %.4f % ', Var(v));
        fprintf('   %.3f ',  sum(Time)/Iter);
        fprintf('     %5.2e',...
            sum(Err)/Iter);
        fprintf('    %5.2e', sum(OBJ)/Iter);
        fprintf('    %.2f',  sum(iter)/Iter);
        fprintf('      %.5f % ',  Fal);
        fprintf('    %.5f % \n', Mis);
        fprintf('   %.4f ',  Threshold(v));
        v= v+1;
        mis(v) = Mis;
        fal(v) = Fal;
    end
   
end
    fprintf('\n ---------------------------------------------------------------------------------------\n');
    
    TIME = toc(start);

