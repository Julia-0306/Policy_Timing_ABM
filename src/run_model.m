function results = run_model(initialState, data, params, scenario)
% RUN_MODEL
% Executes the LOCKED Chapter 2 behavioral flow:
%
%   1. Network at time t
%   2. Regulatory shock
%   3. Partner scoring
%   4. Value of potential relationships
%   5. Stay or switch
%   6. If switch: local/global adjustment mode
%   7. Partner selection
%   8. Form new relationship
%   9. Establish new network at t+1
%  10. Recover surviving replacement relationships
%  11. Compute economic and environmental outcomes
%  12. Next regulation acts on the already adapted network
%
% -------------------------------------------------------------------------
% IMPORTANT
% -------------------------------------------------------------------------
%
% All relationship decisions in period t are evaluated against the SAME
% network snapshot at t and applied simultaneously.
%
% -------------------------------------------------------------------------
% TRADE-VOLUME LOGIC
% -------------------------------------------------------------------------
%
% A newly formed replacement relationship begins at:
%
%   W_new,0
%       = W_old * wHat_new
%
% where wHat_new is normalized market potential of the selected importer.
%
% Its recovery target is:
%
%   W_target = W_old
%
% If the relationship survives, its volume recovers linearly toward W_old
% over params.recoveryHorizon annual periods.
%
% Baseline:
%
%   recoveryHorizon = 5
%
% Full recovery therefore occurs after five years.
%
% There is NO eta adjustment-speed parameter in the core model.

T = params.T;

state = initialState;

[N,~,C] = size(state.W);

%% ------------------------------------------------------------------------
% Storage
%% ------------------------------------------------------------------------

results.F = zeros(T+1,1);

results.R = zeros(T+1,1);

results.deltaF = zeros(T,1);

results.deltaR = zeros(T,1);

results.numSwitches = zeros(T,1);

results.numLocalSwitches = zeros(T,1);

results.numGlobalSwitches = zeros(T,1);

results.A = cell(T+1,1);

results.W = cell(T+1,1);

%% Additional recovery diagnostics

results.numRecoveringLinks = zeros(T+1,1);

results.totalTrade = zeros(T+1,1);

%% Initial state

results.A{1} = state.A;

results.W{1} = state.W;

results.numRecoveringLinks(1) = ...
    sum(state.isRecovering(:));

results.totalTrade(1) = ...
    sum(state.W(:));

%% ------------------------------------------------------------------------
% Simulation periods
%% ------------------------------------------------------------------------

for t = 1:T

    %% ----------------------------------------------------------------
    % 1. GLOBAL NETWORK AT TIME t
    %% ----------------------------------------------------------------

    A_t = state.A;

    W_t = state.W;

    %% ----------------------------------------------------------------
    % 2. REGULATORY SHOCK
    %% ----------------------------------------------------------------

    rhoImporter = ...
        scenario.policyOn(:,t);

    outcomes_t = ...
        compute_outcomes( ...
            state, ...
            rhoImporter, ...
            params.p);

    results.F(t) = ...
        outcomes_t.F;

    results.R(t) = ...
        outcomes_t.R;

    %% ----------------------------------------------------------------
    % Expected trade potential w_hat
    %% ----------------------------------------------------------------
    %
    % Candidate importer market potential:
    %
    %   wHat_k^{c,t}
    %       = imports_k^{c,t}
    %         / max_m(imports_m^{c,t})
    %
    % Hence:
    %
    %   wHat in [0,1]

    importPotential = ...
        zeros(N,C);

    for c = 1:C

        importerTotal = ...
            squeeze(sum(W_t(:,:,c),1))';

        maxImporterTotal = ...
            max(importerTotal);

        if maxImporterTotal > 0

            importPotential(:,c) = ...
                importerTotal ./ maxImporterTotal;

        end

    end

    %% ----------------------------------------------------------------
    % Store switching decisions
    %% ----------------------------------------------------------------

    switchDecisions = struct( ...
        "i", {}, ...
        "oldPartner", {}, ...
        "newPartner", {}, ...
        "commodity", {}, ...
        "mode", {}, ...
        "marketPotential", {});

    localCount = 0;

    globalCount = 0;

    %% ----------------------------------------------------------------
    % 3-8. EXPORTER-LEVEL ADAPTATION
    %% ----------------------------------------------------------------

    for c = 1:C

        for i = 1:N

            currentPartners = ...
                find(A_t(i,:,c));

            if isempty(currentPartners)
                continue;
            end

            totalExporterTrade = ...
                sum(W_t(i,currentPartners,c));

            if totalExporterTrade <= 0
                continue;
            end

            %% ---------------------------------------------------------
            % Prevent duplicate replacement partners
            %% ---------------------------------------------------------

            reservedNewPartners = [];

            %% Evaluate each current relationship separately

            for jj = 1:numel(currentPartners)

                j = ...
                    currentPartners(jj);

                %% ----------------------------------------------------
                % 3A. CURRENT PARTNER SCORE
                %% ----------------------------------------------------

                phiCurrent = ...
                    double( ...
                        state.community(i) ...
                        == state.community(j));

                observedWeight = ...
                    W_t(i,j,c) ...
                    ./ totalExporterTrade;

                rhoCurrent = ...
                    double(rhoImporter(j));

                currentScore = ...
                    partner_score( ...
                        phiCurrent, ...
                        state.distance(i,j), ...
                        observedWeight, ...
                        rhoCurrent, ...
                        params.p);

                %% ----------------------------------------------------
                % 3B. FEASIBLE POTENTIAL PARTNERS
                %% ----------------------------------------------------

                feasible = ...
                    true(1,N);

                % Exporter cannot trade with itself.
                feasible(i) = false;

                % Existing partners are not candidate new links.
                feasible(A_t(i,:,c)) = false;

                % Candidate must have positive current market potential.
                feasible( ...
                    importPotential(:,c)' <= 0) = false;

                %% ----------------------------------------------------
                % One-for-one distinct replacement rule
                %% ----------------------------------------------------
                %
                % Every selected new importer must be a valid country
                % index. This assertion is diagnostic only and does not
                % change model behavior.

                if ~isempty(reservedNewPartners)

                    assert( ...
                        all(isfinite(reservedNewPartners)) && ...
                        all(reservedNewPartners >= 1) && ...
                        all(reservedNewPartners <= N) && ...
                        all(mod(reservedNewPartners,1) == 0), ...
                        "reservedNewPartners contains an invalid country index.");

                    feasible(reservedNewPartners) = ...
                        false;

                end

                K_i = ...
                    find(feasible);

                %% No feasible replacement -> stay

                if isempty(K_i)
                    continue;
                end

                %% ----------------------------------------------------
                % Potential partner scores
                %% ----------------------------------------------------

                potentialScores = ...
                    zeros(1,numel(K_i));

                for kk = 1:numel(K_i)

                    k = ...
                        K_i(kk);

                    phiPotential = ...
                        double( ...
                            state.community(i) ...
                            == state.community(k));

                    expectedWeight = ...
                        importPotential(k,c);

                    rhoPotential = ...
                        double(rhoImporter(k));

                    potentialScores(kk) = ...
                        partner_score( ...
                            phiPotential, ...
                            state.distance(i,k), ...
                            expectedWeight, ...
                            rhoPotential, ...
                            params.p);

                end

                %% ----------------------------------------------------
                % 4. VALUE OF POTENTIAL RELATIONSHIPS
                %% ----------------------------------------------------

                localMask = ...
                    state.community(K_i)' ...
                    == state.community(i);

                globalMask = ...
                    ~localMask;

                [VL, VG, V] = ...
                    relationship_value( ...
                        potentialScores, ...
                        localMask, ...
                        globalMask, ...
                        params.eL, ...
                        params.eG);

                %% ----------------------------------------------------
                % 5. STAY OR SWITCH
                %% ----------------------------------------------------

                shouldSwitch = ...
                    stay_switch_decision( ...
                        currentScore, ...
                        V);

                if ~shouldSwitch
                    continue;
                end

                %% ----------------------------------------------------
                % 6. LOCAL / GLOBAL ADJUSTMENT MODE
                %% ----------------------------------------------------

                localCandidates = ...
                    K_i(localMask);

                globalCandidates = ...
                    K_i(globalMask);

                [candidatePool, mode] = ...
                    select_adjustment_mode( ...
                        localCandidates, ...
                        globalCandidates, ...
                        VL, ...
                        VG);

                if isempty(candidatePool)
                    continue;
                end

                %% ----------------------------------------------------
                % 7. PARTNER SELECTION
                %% ----------------------------------------------------

                selectedMask = ...
                    ismember( ...
                        K_i, ...
                        candidatePool);

                poolScores = ...
                    potentialScores( ...
                        selectedMask);

                [newPartner, ~] = ...
                    select_partner( ...
                        candidatePool, ...
                        poolScores, ...
                        params.beta);

                if isempty(newPartner)
                    continue;
                end

                %% ----------------------------------------------------
                % VALIDATE SELECTED PARTNER
                %% ----------------------------------------------------
                %
                % newPartner must be exactly one valid country index
                % belonging to candidatePool.
                %
                % This check changes no behavioral rule.

                if ~isscalar(newPartner) || ...
                   ~isfinite(newPartner) || ...
                   newPartner < 1 || ...
                   newPartner > N || ...
                   mod(newPartner,1) ~= 0 || ...
                   ~ismember(newPartner, candidatePool)

                    fprintf("\n");
                    fprintf("INVALID PARTNER SELECTION\n");
                    fprintf("t = %d\n", t);
                    fprintf("exporter i = %d\n", i);
                    fprintf("commodity c = %d\n", c);
                    fprintf("current partner j = %d\n", j);

                    fprintf("newPartner:\n");
                    disp(newPartner);

                    fprintf("candidatePool:\n");
                    disp(candidatePool);

                    fprintf("poolScores:\n");
                    disp(poolScores);

                    error( ...
                        "select_partner returned an invalid partner.");

                end

                %% ----------------------------------------------------
                % Reserve selected partner EXACTLY ONCE
                %% ----------------------------------------------------

                reservedNewPartners(end+1) = ...
                    newPartner;

                %% ----------------------------------------------------
                % 8. RECORD NEW RELATIONSHIP
                %% ----------------------------------------------------

                q = ...
                    numel(switchDecisions) + 1;

                switchDecisions(q).i = ...
                    i;

                switchDecisions(q).oldPartner = ...
                    j;

                switchDecisions(q).newPartner = ...
                    newPartner;

                switchDecisions(q).commodity = ...
                    c;

                switchDecisions(q).mode = ...
                    mode;

                switchDecisions(q).marketPotential = ...
                    importPotential(newPartner,c);

                %% Count adjustment mode

                if mode == "local"

                    localCount = ...
                        localCount + 1;

                else

                    globalCount = ...
                        globalCount + 1;

                end

            end

        end

    end

    %% ----------------------------------------------------------------
    % 9. ESTABLISH NEW NETWORK AT t+1
    %% ----------------------------------------------------------------

    state = ...
        update_network( ...
            state, ...
            switchDecisions);

    %% ----------------------------------------------------------------
    % 10. TRADE-VOLUME RECOVERY
    %% ----------------------------------------------------------------
    %
    % Relationships created during THIS transition remain at age zero.
    %
    % Older recovering relationships that survive increase their age by
    % one year and recover linearly toward their pre-switch target.

    state = ...
        update_trade_recovery( ...
            state, ...
            switchDecisions, ...
            params.recoveryHorizon);

    %% ----------------------------------------------------------------
    % Store updated network
    %% ----------------------------------------------------------------

    results.A{t+1} = ...
        state.A;

    results.W{t+1} = ...
        state.W;

    %% Switching outcomes

    results.numSwitches(t) = ...
        numel(switchDecisions);

    results.numLocalSwitches(t) = ...
        localCount;

    results.numGlobalSwitches(t) = ...
        globalCount;

    %% Recovery diagnostics

    results.numRecoveringLinks(t+1) = ...
        sum(state.isRecovering(:));

    results.totalTrade(t+1) = ...
        sum(state.W(:));

    %% ----------------------------------------------------------------
    % 11. NEW NETWORK AT t+1: OUTCOME LANDSCAPES
    %% ----------------------------------------------------------------

    outcomes_next = ...
        compute_outcomes( ...
            state, ...
            rhoImporter, ...
            params.p);

    results.F(t+1) = ...
        outcomes_next.F;

    results.R(t+1) = ...
        outcomes_next.R;

    results.deltaF(t) = ...
        outcomes_next.F ...
        - outcomes_t.F;

    results.deltaR(t) = ...
        outcomes_next.R ...
        - outcomes_t.R;

end

%% ------------------------------------------------------------------------
% Store metadata
%% ------------------------------------------------------------------------

results.scenario = ...
    scenario;

results.params = ...
    params;

end