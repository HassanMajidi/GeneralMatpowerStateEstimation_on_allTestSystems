clear 
close all
clc

%%%%%%%%
% Matpower State Estimation on Xbus Test System
% Created by Hassan Majidi-Gharenaz
% Don't forget to reference our articles :)
% Google Scholar : https://scholar.google.com/citations?user=-X2A2h0AAAAJ&hl=en
% ResearchGate : https://www.researchgate.net/profile/Hassan-Majidi-Gharenaz
%%%%%%%

%%% load case
%%% You can chane case name as you like
casename = 'case33bw.m';
mpc = loadcase(casename);
baseMVA = mpc.baseMVA;

%%% bus & branch & gen index's name
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
     VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
        TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
        ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
        MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
        QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%%% set options
mpopt = mpoption;                  %% use default options
mpopt.verbose = 0;
mpopt.out.all = 0;

%%% loadflow and make y bus
[Ybus, Yf, Yt] = makeYbus(mpc);
[MVAbase, bus, gen, branch, success, ~] = runpf(mpc, mpopt);
if ~success
    error('Your Load Flow Not Converged !');
end
    
    

%%% calculate num
NumOfBranch = size(branch,1);
NumOfBus = size(bus,1);
NumOfGen = size(gen,1);

%%% set measurements indexes
idx.idx_zPF = (1:NumOfBranch)';
idx.idx_zPT = (1:NumOfBranch)';
idx.idx_zPG = (1:NumOfGen)';
idx.idx_zVa = [];
idx.idx_zQF = (1:NumOfBranch)';
idx.idx_zQT = (1:NumOfBranch)';
idx.idx_zQG = (1:NumOfGen)';
idx.idx_zVm = (1:NumOfBus)';

%%% set measurements standard divation acuracy
sigma.sigma_PF = 0.01;
sigma.sigma_PT = 0.01;
sigma.sigma_PG = 0.01;
sigma.sigma_Va = [];
sigma.sigma_QF = 0.01;
sigma.sigma_QT = 0.01;
sigma.sigma_QG = 0.01;
sigma.sigma_Vm = 0.005;

%%% set actual values by load flow
Actual_PF = branch(:,PF);
Actual_PT = branch(:,PT);
Actual_PG = gen(:,PG);
Actual_Va = bus(:,VA);
Actual_QF = branch(:,QF);
Actual_QT = branch(:,QT);
Actual_QG = gen(:,QG);
Actual_VM = bus(:,VM);

%%% set measurements value
measure.PF = Actual_PF/baseMVA + sigma.sigma_PF*randn(size(Actual_PF));
measure.PT = Actual_PT/baseMVA + sigma.sigma_PT*randn(size(Actual_PT));
measure.PG = Actual_PG/baseMVA + sigma.sigma_PG*randn(size(Actual_PG));
measure.Va = [];
measure.QF = Actual_QF/baseMVA + sigma.sigma_QF*randn(size(Actual_QF));
measure.QT = Actual_QT/baseMVA + sigma.sigma_QT*randn(size(Actual_QT));
measure.QG = Actual_QG/baseMVA + sigma.sigma_QG*randn(size(Actual_QG));
measure.Vm = Actual_VM + sigma.sigma_Vm*randn(size(Actual_VM));



%%% control values and indexes
[success, measure, idx, sigma] = checkDataIntegrity(measure, idx, sigma, NumOfBus);
if ~success
    error('State Estimation input data are not complete or sufficient!');
end

%%% seat estimation
clc
tic
type_initialguess = 2; % flat start
[~, bus, ~, ~, ~, ~, ~, ~, ~] = run_se(mpc,...
   measure, idx, sigma,type_initialguess);
toc
