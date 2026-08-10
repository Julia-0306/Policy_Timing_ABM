function state = initialize_network(data)
% INITIALIZE_NETWORK
% Creates the stylized international trade network at t = 1.
%
% The network topology is synthetic. Empirical/semi-empirical information
% enters through geography, regulator identities, and deforestation-risk
% intensity.
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
%       Each exporter has exactly 5 outgoing partners per commodity layer
%       whenever at least 5 feasible destinations exist.
%
%       Initial partners are drawn uniformly at random without replacement
%       from the set of all other countries.
%
%       IMPORTANT:
%       Community membership and geographic distance do NOT determine the
%       initial topology. They enter later through the behavioral partner
%       scoring and local/global adjustment logic.
%
% 5. Initial trade weights:
%       W_ij^{c,1} is drawn uniformly from [2,8] for active links.
%
% 6. Regulatory exposure guarantee:
%       Each regulatory jurisdiction (EU, UK, US) is guaranteed at least
%       eight incoming links per commodity layer at t = 1.
%
%       The EU is treated as a regulatory GROUP: a link to any EU member
%       counts toward EU exposure. UK and US each contain one country in
%       the current regulator data.
%
%       If a jurisdiction has fewer than eight incoming links after ordinary
%       initialization, existing exporter links are reassigned toward that
%       jurisdiction. Exporter out-degree is preserved.
%
% -------------------------------------------------------------------------
% IMPORTANT IMPLEMENTATION NOTE
% -------------------------------------------------------------------------
%
% Initial network generation is intentionally separated from subsequent
% behavioral adaptation:
%
%   - topology at t = 1 is stochastic;
%   - communities and distance do not bias initial partner formation;
%   - community membership, distance, trade importance, policy exposure,
%     and switching costs govern exporter decisions after initialization.
%
% Commodity-participation logic is NOT added here. The current implementation
% initializes all N countries in every commodity layer. If the paper states
% Pr(B_ic = 1) = 0.60, that remains a separate implementation issue that
% should be reconciled explicitly rather than silently introduced here.
%
% -------------------------------------------------------------------------
% TRADE-RECOVERY STATE
% -------------------------------------------------------------------------
%
% Relationships present at t = 1 are established relationships and are not
% in recovery. Replacement relationships formed during the simulation can
% enter the recovery process.
%
% State arrays:
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

%% ------------------------------------------------------------------------
% Fixed structural assumptions
% -------------------------------------------------------------------------

K = 5;
maxPartners = 5;

weightMin = 2;
weightMax = 8;

minRegulatorIncoming = 8;

assert(size(data.distance,1) == N && size(data.distance,2) == N, ...
    "data.distance must be an N-by-N matrix.");

%% ------------------------------------------------------------------------
% Assign balanced synthetic trade communities
% -------------------------------------------------------------------------
%
% Communities are fixed structural attributes used by subsequent exporter
% decision rules. They do not determine initial partner formation.

baseCommunity = repelem((1:K)', ceil(N / K));
baseCommunity = baseCommunity(1:N);

perm = randperm(N);

community = zeros(N,1);
community(perm) = baseCommunity;

%% ------------------------------------------------------------------------
% Same-community indicator Phi
% -------------------------------------------------------------------------

Phi = double(community == community');

%% ------------------------------------------------------------------------
% Initialize adjacency and weights
% -------------------------------------------------------------------------
%
% Initial partners are sampled uniformly at random without replacement from
% all other countries. This ensures that the starting network can contain
% both within- and cross-community relationships without imposing either
% structure mechanically.

A = false(N,N,C);
W = zeros(N,N,C);

for c = 1:C

    for i = 1:N

        candidates = setdiff(1:N, i);

        nPartners = ...
            min(maxPartners, numel(candidates));

        randomOrder = randperm(numel(candidates), nPartners);

        selected = candidates(randomOrder);

        A(i,selected,c) = true;

        W(i,selected,c) = ...
            weightMin ...
            + (weightMax - weightMin) ...
            .* rand(1,nPartners);

    end

end

%% ------------------------------------------------------------------------
% Enforce minimum policy exposure
% ------------------------------------------------------------------------
%
% regulators.csv identifies regulatory jurisdictions through regulator_group:
%
%   EU
%   UK
%   US
%
% EU exposure is measured at the jurisdiction level: an incoming link to any
% EU member contributes one exposed relationship.
%
% The guarantee is imposed through one-for-one reassignment of existing
% outgoing links. No exporter receives an additional sixth partner.
%
% Exposure enforcement is intentionally neutral with respect to community
% membership and geographic distance:
%
%   - eligible exporters are sampled randomly;
%   - a feasible regulator node is sampled randomly;
%   - an eligible existing relationship is removed randomly.
%
% The old relationship's weight is transferred to the new link so that the
% exposure correction changes topology but does not mechanically change the
% exporter's initial total trade volume.
%
% Links into another regulatory jurisdiction are protected when removing
% them would push that jurisdiction below its minimum exposure threshold.

if isfield(data, "regulator_group")

    regulatorGroup = string(data.regulator_group(:));

elseif isfield(data, "is_regulator")

    error([ ...
        "data.is_regulator exists but data.regulator_group is missing. " ...
        "The exposure guarantee requires regulator_group labels EU/UK/US." ...
    ]);

else

    error([ ...
        "Regulator information is missing from data. Expected field " ...
        "data.regulator_group." ...
    ]);

end

jurisdictions = ["EU","UK","US"];

for c = 1:C

    for g = 1:numel(jurisdictions)

        jurisdiction = jurisdictions(g);

        regulatorNodes = ...
            find(regulatorGroup == jurisdiction);

        assert(~isempty(regulatorNodes), ...
            "No nodes found for regulatory jurisdiction '%s'.", ...
            jurisdiction);

        currentExposure = ...
            count_group_incoming_links( ...
                A(:,:,c), ...
                regulatorNodes);

        while currentExposure < minRegulatorIncoming

            %% Find exporters that are not already linked to this jurisdiction.

            candidateExporters = [];

            for i = 1:N

                if ~any(A(i,:,c))
                    continue;
                end

                if any(A(i,regulatorNodes,c))
                    continue;
                end

                validTargets = regulatorNodes(regulatorNodes ~= i);

                if isempty(validTargets)
                    continue;
                end

                candidateExporters(end+1) = i; %#ok<AGROW>

            end

            if isempty(candidateExporters)

                error([ ...
                    "Unable to enforce minimum incoming exposure for %s " ...
                    "in commodity layer %d while preserving exporter " ...
                    "out-degree." ...
                ], jurisdiction, c);

            end

            %% Randomize exporter order to avoid structural bias.

            candidateExporters = ...
                candidateExporters(randperm(numel(candidateExporters)));

            reassigned = false;

            for q = 1:numel(candidateExporters)

                i = candidateExporters(q);

                %% Random feasible destination within the regulator group.

                validTargets = regulatorNodes(regulatorNodes ~= i);

                target = ...
                    validTargets(randi(numel(validTargets)));

                currentPartners = find(A(i,:,c));

                %% Determine which current links may be removed.
                %
                % A link to another regulator group is protected whenever
                % removing it would reduce that group's exposure below 8.

                removable = false(size(currentPartners));

                for r = 1:numel(currentPartners)

                    oldPartner = currentPartners(r);
                    oldGroup = regulatorGroup(oldPartner);

                    if any(oldGroup == jurisdictions)

                        oldGroupNodes = ...
                            find(regulatorGroup == oldGroup);

                        oldGroupExposure = ...
                            count_group_incoming_links( ...
                                A(:,:,c), ...
                                oldGroupNodes);

                        if oldGroupExposure <= minRegulatorIncoming
                            removable(r) = false;
                            continue;
                        end

                    end

                    removable(r) = true;

                end

                removablePartners = currentPartners(removable);

                if isempty(removablePartners)
                    continue;
                end

                %% Random one-for-one reassignment.

                oldPartner = ...
                    removablePartners(randi(numel(removablePartners)));

                oldWeight = W(i,oldPartner,c);

                A(i,oldPartner,c) = false;
                W(i,oldPartner,c) = 0;

                A(i,target,c) = true;
                W(i,target,c) = oldWeight;

                reassigned = true;
                break;

            end

            if ~reassigned

                error([ ...
                    "Could not find a safe link reassignment for %s in " ...
                    "commodity layer %d without violating another " ...
                    "regulatory exposure guarantee." ...
                ], jurisdiction, c);

            end

            currentExposure = ...
                count_group_incoming_links( ...
                    A(:,:,c), ...
                    regulatorNodes);

        end

    end

end

%% ------------------------------------------------------------------------
% Verify initialization constraints
% ------------------------------------------------------------------------

for c = 1:C

    % No self-links.
    assert(~any(diag(A(:,:,c))), ...
        "Self-link detected in commodity layer %d.", c);

    % Every exporter retains the intended initial partner count.
    outDegree = sum(A(:,:,c), 2);

    expectedPartners = min(maxPartners, N-1);

    assert(all(outDegree == expectedPartners), ...
        "Initial out-degree constraint violated in commodity layer %d.", c);

    % Regulatory exposure conditions.
    for g = 1:numel(jurisdictions)

        regulatorNodes = ...
            find(regulatorGroup == jurisdictions(g));

        exposure = ...
            count_group_incoming_links( ...
                A(:,:,c), ...
                regulatorNodes);

        assert(exposure >= minRegulatorIncoming, ...
            "Exposure guarantee failed for %s in commodity layer %d.", ...
            jurisdictions(g), c);

    end

end

%% ------------------------------------------------------------------------
% Recovery-state arrays
% ------------------------------------------------------------------------
%
% Initial links are established links.

isRecovering = false(N,N,C);

recoveryAge = zeros(N,N,C);

recoveryStartWeight = zeros(N,N,C);

recoveryTargetWeight = zeros(N,N,C);

%% ------------------------------------------------------------------------
% State
% ------------------------------------------------------------------------

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


%% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function nIncoming = count_group_incoming_links(Ac, groupNodes)
% COUNT_GROUP_INCOMING_LINKS
%
% Counts directed links whose destination belongs to the specified
% regulatory jurisdiction.
%
% Ac is the N-by-N adjacency matrix for one commodity layer.

    nIncoming = nnz(Ac(:,groupNodes));

end
