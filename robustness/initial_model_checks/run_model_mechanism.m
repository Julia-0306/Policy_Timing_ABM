function results = run_model_mechanism(initialState, data, params, scenario, mechanism)
% RUN_MODEL_MECHANISM
% Experimental mechanism-decomposition version of run_model.m.
%
% IMPORTANT:
%   - This file is ONLY for the mechanism-decomposition experiment.
%   - It does not modify the benchmark model.
%   - All network decisions remain synchronous.
%
% mechanism.useSoftmax
% mechanism.useSwitchingCosts
% mechanism.useRecovery
% mechanism.useRegulation

T = params.T;
state = initialState;
[N,~,C] = size(state.W);

requiredFields = ["useSoftmax","useSwitchingCosts","useRecovery","useRegulation"];
for f = 1:numel(requiredFields)
    assert(isfield(mechanism, requiredFields(f)), ...
        "Mechanism specification is missing field '%s'.", requiredFields(f));
end

results.F = zeros(T+1,1);
results.R = zeros(T+1,1);
results.deltaF = zeros(T,1);
results.deltaR = zeros(T,1);
results.numSwitches = zeros(T,1);
results.numLocalSwitches = zeros(T,1);
results.numGlobalSwitches = zeros(T,1);
results.A = cell(T+1,1);
results.W = cell(T+1,1);
results.numRecoveringLinks = zeros(T+1,1);
results.totalTrade = zeros(T+1,1);

results.A{1} = state.A;
results.W{1} = state.W;
results.numRecoveringLinks(1) = sum(state.isRecovering(:));
results.totalTrade(1) = sum(state.W(:));

for t = 1:T

    A_t = state.A;
    W_t = state.W;

    if mechanism.useRegulation
        rhoImporter = scenario.policyOn(:,t);
    else
        rhoImporter = zeros(N,1);
    end

    outcomes_t = compute_outcomes(state, rhoImporter, params.p);
    results.F(t) = outcomes_t.F;
    results.R(t) = outcomes_t.R;

    importPotential = zeros(N,C);
    for c = 1:C
        importerTotal = squeeze(sum(W_t(:,:,c),1))';
        maxImporterTotal = max(importerTotal);
        if maxImporterTotal > 0
            importPotential(:,c) = importerTotal ./ maxImporterTotal;
        end
    end

    switchDecisions = struct( ...
        "i", {}, "oldPartner", {}, "newPartner", {}, ...
        "commodity", {}, "mode", {}, "marketPotential", {});

    localCount = 0;
    globalCount = 0;

    for c = 1:C
        for i = 1:N

            currentPartners = find(A_t(i,:,c));
            if isempty(currentPartners)
                continue;
            end

            totalExporterTrade = sum(W_t(i,currentPartners,c));
            if totalExporterTrade <= 0
                continue;
            end

            reservedNewPartners = [];

            for jj = 1:numel(currentPartners)

                j = currentPartners(jj);

                phiCurrent = double(state.community(i) == state.community(j));
                observedWeight = W_t(i,j,c) ./ totalExporterTrade;
                rhoCurrent = double(rhoImporter(j));

                currentScore = partner_score( ...
                    phiCurrent, state.distance(i,j), ...
                    observedWeight, rhoCurrent, params.p);

                feasible = true(1,N);
                feasible(i) = false;
                feasible(A_t(i,:,c)) = false;
                feasible(importPotential(:,c)' <= 0) = false;

                if ~isempty(reservedNewPartners)
                    feasible(reservedNewPartners) = false;
                end

                K_i = find(feasible);
                if isempty(K_i)
                    continue;
                end

                potentialScores = zeros(1,numel(K_i));

                for kk = 1:numel(K_i)
                    k = K_i(kk);
                    phiPotential = double(state.community(i) == state.community(k));
                    expectedWeight = importPotential(k,c);
                    rhoPotential = double(rhoImporter(k));

                    potentialScores(kk) = partner_score( ...
                        phiPotential, state.distance(i,k), ...
                        expectedWeight, rhoPotential, params.p);
                end

                localMask = state.community(K_i)' == state.community(i);
                globalMask = ~localMask;

                if mechanism.useSwitchingCosts
                    eL = params.eL;
                    eG = params.eG;
                else

    % Effectively zero switching costs.
    % Tiny positive values preserve the eG > eL requirement of
    % relationship_value.m without economically affecting the result.

                    eL = 1e-12;
                    eG = 2e-12;

end

                [VL, VG, V] = relationship_value( ...
                    potentialScores, localMask, globalMask, eL, eG);

                shouldSwitch = stay_switch_decision(currentScore, V);
                if ~shouldSwitch
                    continue;
                end

                localCandidates = K_i(localMask);
                globalCandidates = K_i(globalMask);

                [candidatePool, mode] = select_adjustment_mode( ...
                    localCandidates, globalCandidates, VL, VG);

                if isempty(candidatePool)
                    continue;
                end

                selectedMask = ismember(K_i, candidatePool);
                poolScores = potentialScores(selectedMask);

                if mechanism.useSoftmax
                    [newPartner, ~] = select_partner( ...
                        candidatePool, poolScores, params.beta);
                else
                    [~, bestIdx] = max(poolScores);
                    newPartner = candidatePool(bestIdx);
                end

                if isempty(newPartner)
                    continue;
                end

                assert( ...
                    isscalar(newPartner) && isfinite(newPartner) && ...
                    newPartner >= 1 && newPartner <= N && ...
                    mod(newPartner,1) == 0 && ...
                    ismember(newPartner, candidatePool), ...
                    "Invalid partner selected in mechanism experiment.");

                reservedNewPartners(end+1) = newPartner; %#ok<AGROW>

                q = numel(switchDecisions) + 1;
                switchDecisions(q).i = i;
                switchDecisions(q).oldPartner = j;
                switchDecisions(q).newPartner = newPartner;
                switchDecisions(q).commodity = c;
                switchDecisions(q).mode = mode;
                switchDecisions(q).marketPotential = importPotential(newPartner,c);

                if mode == "local"
                    localCount = localCount + 1;
                else
                    globalCount = globalCount + 1;
                end

            end
        end
    end

    % Apply all replacements simultaneously.
    state = update_network(state, switchDecisions);

    if mechanism.useRecovery

        state = update_trade_recovery( ...
            state, switchDecisions, params.recoveryHorizon);

    else

        % Remove the recovery mechanism cleanly:
        % every replacement immediately inherits its pre-switch target volume.
        for q = 1:numel(switchDecisions)
            i = switchDecisions(q).i;
            k = switchDecisions(q).newPartner;
            c = switchDecisions(q).commodity;

            targetWeight = state.recoveryTargetWeight(i,k,c);
            state.W(i,k,c) = targetWeight;

            state.isRecovering(i,k,c) = false;
            state.recoveryAge(i,k,c) = 0;
            state.recoveryStartWeight(i,k,c) = 0;
            state.recoveryTargetWeight(i,k,c) = 0;
        end

        state.isRecovering(:) = false;
        state.recoveryAge(:) = 0;
        state.recoveryStartWeight(:) = 0;
        state.recoveryTargetWeight(:) = 0;

    end

    results.A{t+1} = state.A;
    results.W{t+1} = state.W;

    results.numSwitches(t) = numel(switchDecisions);
    results.numLocalSwitches(t) = localCount;
    results.numGlobalSwitches(t) = globalCount;

    results.numRecoveringLinks(t+1) = sum(state.isRecovering(:));
    results.totalTrade(t+1) = sum(state.W(:));

    outcomes_next = compute_outcomes(state, rhoImporter, params.p);

    results.F(t+1) = outcomes_next.F;
    results.R(t+1) = outcomes_next.R;
    results.deltaF(t) = outcomes_next.F - outcomes_t.F;
    results.deltaR(t) = outcomes_next.R - outcomes_t.R;

end

results.scenario = scenario;
results.params = params;
results.mechanism = mechanism;

end
