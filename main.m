%% TRADE NETWORK ADJUSTMENT ABM
% Main entry point for the Chapter 2 ABM.
%
% MODEL FLOW
%
% 1. Network at time t
% 2. Regulatory shock
% 3. Partner scoring
% 4. Value of potential relationships
% 5. Stay or switch
% 6. If switch: local/global adjustment mode
% 7. Partner selection
% 8. Form new relationship
% 9. Establish network at t+1
% 10. Trade-volume recovery of surviving replacement relationships
% 11. Economic and environmental outcomes
% 12. Next regulatory shock acts on the adapted network
%
% IMPORTANT:
% The behavioral logic is implemented in src/.
% Scenario files change ONLY policy timing.
%
% One model period t represents ONE YEAR.

clear;
clc;

%% Paths

projectRoot = ...
    fileparts(mfilename("fullpath"));

addpath( ...
    fullfile( ...
        projectRoot, ...
        "src"));

addpath( ...
    fullfile( ...
        projectRoot, ...
        "scenarios"));

dataDir = ...
    fullfile( ...
        projectRoot, ...
        "data");

resultsDir = ...
    fullfile( ...
        projectRoot, ...
        "results");

if ~exist(resultsDir, "dir")

    mkdir(resultsDir);

end

%% ------------------------------------------------------------------------
% Reproducibility
%% ------------------------------------------------------------------------
%
% Fixed seed for:
%
%   - synthetic-network initialization
%   - stochastic softmax partner selection
%
% This is an experimental-design choice, not a behavioral parameter.

rng(42, "twister");

%% Load empirical / semi-empirical inputs

data = ...
    load_model_data( ...
        dataDir);

%% ------------------------------------------------------------------------
% Simulation horizon
%% ------------------------------------------------------------------------
%
% One period = one year.

params.T = 20;

%% ------------------------------------------------------------------------
% LOCKED BEHAVIORAL PARAMETERS
%% ------------------------------------------------------------------------

%% Regulatory penalty

params.p = 0.50;

%% Local switching cost

params.eL = 0.10;

%% Global switching cost

params.eG = 0.20;

assert( ...
    params.eG > params.eL, ...
    "Global switching cost eG must exceed local switching cost eL.");

%% Choice sensitivity
%
% Used only for softmax partner selection.

params.beta = 4.0;

%% ------------------------------------------------------------------------
% TRADE-VOLUME RECOVERY HORIZON
%% ------------------------------------------------------------------------
%
% One model period = one year.
%
% Literature-guided baseline assumption:
%
% A newly formed replacement relationship recovers linearly toward the
% pre-switch trade volume over five years, conditional on surviving.
%
% A link created at age 0 receives its first recovery increment one year
% later and reaches the pre-switch target at age 5.
%
% This replaces the previous eta-based adjustment mechanism.

params.recoveryHorizon = 5;

%% ------------------------------------------------------------------------
% Initialize synthetic trade network
%% ------------------------------------------------------------------------

initialState = ...
    initialize_network( ...
        data);

%% ------------------------------------------------------------------------
% Common random numbers
%% ------------------------------------------------------------------------
%
% Store RNG state AFTER network initialization.
%
% Every policy scenario starts from:
%
%   - the same initial network
%   - the same stochastic state
%
% Therefore scenarios remain identical until their policy regimes diverge.

simulationRNG = rng;

%% ------------------------------------------------------------------------
% Define policy-timing scenarios
%% ------------------------------------------------------------------------

scenarioList = {
    baseline(data, params.T)
    early_mover(data, params.T)
    sequential(data, params.T)
    coordinated(data, params.T)
    delayed_coordination(data, params.T)
};

%% ------------------------------------------------------------------------
% Run scenarios
%% ------------------------------------------------------------------------

results = struct();

fprintf("\n");
fprintf("============================================================\n");
fprintf(" Chapter 2 Adaptive Trade Network Model\n");
fprintf("============================================================\n\n");

for s = 1:numel(scenarioList)

    scenario = ...
        scenarioList{s};

    fprintf( ...
        "Running scenario %d/%d: %s\n", ...
        s, ...
        numel(scenarioList), ...
        scenario.name);

    %% Common random numbers

    rng(simulationRNG);

    %% Run scenario

    results.(scenario.id) = ...
        run_model( ...
            initialState, ...
            data, ...
            params, ...
            scenario);

end

%% ------------------------------------------------------------------------
% Save complete output
%% ------------------------------------------------------------------------

outputFile = ...
    fullfile( ...
        resultsDir, ...
        "chapter2_results.mat");

save( ...
    outputFile, ...
    "results", ...
    "params", ...
    "scenarioList", ...
    "data", ...
    "simulationRNG", ...
    "-v7.3");

%% ------------------------------------------------------------------------
% Create compact scenario summary
%% ------------------------------------------------------------------------

nScenarios = ...
    numel(scenarioList);

scenarioID = ...
    strings(nScenarios,1);

scenarioName = ...
    strings(nScenarios,1);

finalFitness = ...
    zeros(nScenarios,1);

finalRisk = ...
    zeros(nScenarios,1);

finalTrade = ...
    zeros(nScenarios,1);

finalRecoveringLinks = ...
    zeros(nScenarios,1);

totalSwitches = ...
    zeros(nScenarios,1);

localSwitches = ...
    zeros(nScenarios,1);

globalSwitches = ...
    zeros(nScenarios,1);

for s = 1:nScenarios

    scenario = ...
        scenarioList{s};

    r = ...
        results.(scenario.id);

    scenarioID(s) = ...
        scenario.id;

    scenarioName(s) = ...
        scenario.name;

    finalFitness(s) = ...
        r.F(end);

    finalRisk(s) = ...
        r.R(end);

    finalTrade(s) = ...
        r.totalTrade(end);

    finalRecoveringLinks(s) = ...
        r.numRecoveringLinks(end);

    totalSwitches(s) = ...
        sum(r.numSwitches);

    localSwitches(s) = ...
        sum(r.numLocalSwitches);

    globalSwitches(s) = ...
        sum(r.numGlobalSwitches);

end

summaryTable = ...
    table( ...
        scenarioID, ...
        scenarioName, ...
        finalFitness, ...
        finalRisk, ...
        finalTrade, ...
        finalRecoveringLinks, ...
        totalSwitches, ...
        localSwitches, ...
        globalSwitches);

summaryFile = ...
    fullfile( ...
        resultsDir, ...
        "scenario_summary.csv");

writetable( ...
    summaryTable, ...
    summaryFile);

%% ------------------------------------------------------------------------
% Display summary
%% ------------------------------------------------------------------------

fprintf("\nSimulation complete.\n\n");

disp(summaryTable);

fprintf( ...
    "Full results saved to:\n  %s\n", ...
    outputFile);

fprintf( ...
    "Scenario summary saved to:\n  %s\n", ...
    summaryFile);

%% ------------------------------------------------------------------------
% ROBUSTNESS NOTE
%% ------------------------------------------------------------------------
%
% eta is no longer part of the model.
%
% The former adjustment-speed robustness exercise should therefore be
% removed.
%
% A conceptually relevant replacement robustness analysis is the assumed
% relationship-recovery horizon, for example:
%
%   H = 3 years
%   H = 5 years   [baseline]
%   H = 7 years
%
% Other robustness exercises remain:
%
%   - initial-network Monte Carlo
%   - p sensitivity
%   - eL/eG sensitivity
%   - beta sensitivity
%   - environmental calibration sensitivity
%