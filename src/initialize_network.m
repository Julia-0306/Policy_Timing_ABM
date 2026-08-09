function state = initialize_network(data)
% INITIALIZE_NETWORK
% Creates the stylized global trade network at t = 1.
%
% The Chapter 2 network is intentionally synthetic. Real-world geography,
% regulator identities, and deforestation intensity provide empirical or
% semi-empirical grounding, while the trade topology is simulated.
%
% -------------------------------------------------------------------------
% STRUCTURAL INITIALIZATION ASSUMPTIONS
% -------------------------------------------------------------------------
%
% 1. Number of agents:
%       N = 30
%
% 2. Commodity layers:
%       C = 4
%       palm oil, soy, timber, paper
%
% 3. Trade communities:
%       K = 5
%
% 4. Initial partners:
%       Each exporter has up to 5 outgoing partners per commodity layer.
%
% 5. Initial trade weights:
%       W_ij^{c,1} is drawn uniformly from [2,8] for active links.
%
% 6. Initial link formation:
%       Same-community partners and geographically closer partners are
%       preferred:
%
%           initialization score = phi_ij - d_ij
%
% IMPORTANT:
% No alpha_C, alpha_D, or alpha_W weighting parameters are used.
%
% -------------------------------------------------------------------------
% TRADE-RECOVERY STATE
% -------------------------------------------------------------------------
%
% Relationships present at t = 1 are treated as established relationships.
% They are NOT in recovery.
%
% Replacement relationships created later can enter a five-year linear
% recovery process. The following state arrays track that process:
%
%   isRecovering
%   recoveryAge
%   recoveryStartWeight
%   recoveryTargetWeight
%
% All four are initialized to zero/false.

N = data.N;
C = data.C;

assert(N == 30, ...
    "Current model initialization expects 30 countries.");

%% Fixed structural assumptions

K = 5;
maxPartners = 5;

weightMin = 2;
weightMax = 8;

%% Assign balanced synthetic trade communities

baseCommunity = repelem((1:K)', ceil(N / K));
baseCommunity = baseCommunity(1:N);

perm = randperm(N);

community = zeros(N,1);
community(perm) = baseCommunity;

%% Same-community indicator Phi

Phi = double(community == community');

%% Initialize adjacency and weights

A = false(N,N,C);
W = zeros(N,N,C);

for c = 1:C

    for i = 1:N

        feasible = true(1,N);
        feasible(i) = false;

        candidates = find(feasible);

        %% Structural initialization score

        initScore = ...
            Phi(i,candidates) ...
            - data.distance(i,candidates);

        %% Random tie breaker only

        tieBreaker = ...
            rand(size(candidates)) * 1e-10;

        [~, order] = ...
            sort( ...
                initScore + tieBreaker, ...
                "descend");

        nPartners = ...
            min(maxPartners, numel(candidates));

        selected = ...
            candidates(order(1:nPartners));

        A(i,selected,c) = true;

        W(i,selected,c) = ...
            weightMin ...
            + (weightMax - weightMin) ...
            .* rand(1,nPartners);

    end

end

%% ------------------------------------------------------------------------
% Recovery-state arrays
% -------------------------------------------------------------------------
%
% Initial links are established links.
%
% Therefore:
%
%   isRecovering = false
%   recoveryAge = 0
%
% recoveryStartWeight and recoveryTargetWeight are zero until a replacement
% relationship is created.

isRecovering = false(N,N,C);

recoveryAge = zeros(N,N,C);

recoveryStartWeight = zeros(N,N,C);

recoveryTargetWeight = zeros(N,N,C);

%% State

state.A = A;
state.W = W;

state.community = community;
state.Phi = Phi;

state.distance = data.distance;
state.delta = data.delta;

state.iso3 = data.iso3;
state.country_name = data.country_name;
state.commodity_names = data.commodity_names;

%% Recovery state

state.isRecovering = isRecovering;

state.recoveryAge = recoveryAge;

state.recoveryStartWeight = recoveryStartWeight;

state.recoveryTargetWeight = recoveryTargetWeight;

end