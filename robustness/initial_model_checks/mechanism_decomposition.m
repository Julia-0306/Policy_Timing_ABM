%% MECHANISM_DECOMPOSITION
% Sequential mechanism test for the Chapter 2 adaptive trade-network ABM.
%
% PURPOSE
% Identify what each mechanism adds before deciding whether any mechanism
% or parameter can be simplified or removed.
%
% This script does NOT modify main.m or the benchmark run_model.m.
%
% M0 Minimal adaptation:
%    no softmax, no switching costs, no recovery, no regulation
%
% M1 Choice:
%    M0 + softmax partner selection
%
% M2 Frictions:
%    M1 + switching costs
%
% M3 Recovery:
%    M2 + trade-volume recovery
%
% M4 Regulation:
%    full behavioural model, baseline versus coordinated regulation
%
% M5 Policy timing:
%    full model across all five policy-timing scenarios

clear;
clc;

%% Paths

scriptDir = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDir);

addpath(fullfile(projectRoot, "src"));
addpath(fullfile(projectRoot, "scenarios"));
addpath(scriptDir);

dataDir = fullfile(projectRoot, "data");

outputDir = fullfile( ...
    projectRoot, "results", "robustness", "mechanism_decomposition");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

%% Reproducibility

rng(42, "twister");

%% Load model inputs

data = load_model_data(dataDir);

%% Benchmark parameters

params.T = 20;
params.p = 0.50;
params.eL = 0.10;
params.eG = 0.20;
params.beta = 4.0;
params.recoveryHorizon = 5;

%% One common initial network

initialState = initialize_network(data);
simulationRNG = rng;

%% Scenarios

scenarioBaseline = baseline(data, params.T);
scenarioCoordinated = coordinated(data, params.T);

scenarioTiming = {
    baseline(data, params.T)
    early_mover(data, params.T)
    sequential(data, params.T)
    coordinated(data, params.T)
    delayed_coordination(data, params.T)
};

%% Mechanism definitions

M0 = struct( ...
    "id", "M0_minimal", ...
    "label", "M0 Minimal adaptation", ...
    "useSoftmax", false, ...
    "useSwitchingCosts", false, ...
    "useRecovery", false, ...
    "useRegulation", false);

M1 = struct( ...
    "id", "M1_choice", ...
    "label", "M1 + Softmax choice", ...
    "useSoftmax", true, ...
    "useSwitchingCosts", false, ...
    "useRecovery", false, ...
    "useRegulation", false);

M2 = struct( ...
    "id", "M2_frictions", ...
    "label", "M2 + Switching costs", ...
    "useSoftmax", true, ...
    "useSwitchingCosts", true, ...
    "useRecovery", false, ...
    "useRegulation", false);

M3 = struct( ...
    "id", "M3_recovery", ...
    "label", "M3 + Recovery", ...
    "useSoftmax", true, ...
    "useSwitchingCosts", true, ...
    "useRecovery", true, ...
    "useRegulation", false);

M4 = struct( ...
    "id", "M4_regulation", ...
    "label", "M4 + Regulation", ...
    "useSoftmax", true, ...
    "useSwitchingCosts", true, ...
    "useRecovery", true, ...
    "useRegulation", true);

M5 = struct( ...
    "id", "M5_timing", ...
    "label", "M5 + Policy timing", ...
    "useSoftmax", true, ...
    "useSwitchingCosts", true, ...
    "useRecovery", true, ...
    "useRegulation", true);

%% Storage

allResults = struct();

rows = struct( ...
    "mechanismID", {}, ...
    "mechanismLabel", {}, ...
    "scenarioID", {}, ...
    "scenarioName", {}, ...
    "finalFitness", {}, ...
    "finalRisk", {}, ...
    "finalTrade", {}, ...
    "finalRecoveringLinks", {}, ...
    "totalSwitches", {}, ...
    "localSwitches", {}, ...
    "globalSwitches", {});

row = 0;

fprintf("\n");
fprintf("============================================================\n");
fprintf(" Mechanism Decomposition Experiment\n");
fprintf("============================================================\n\n");

%% M0-M3: baseline only

baselineMechanisms = {M0, M1, M2, M3};

for m = 1:numel(baselineMechanisms)

    mechanism = baselineMechanisms{m};

    fprintf("%s | Baseline\n", mechanism.label);

    rng(simulationRNG);

    r = run_model_mechanism( ...
        initialState, data, params, scenarioBaseline, mechanism);

    allResults.(mechanism.id).baseline = r;

    row = row + 1;
    rows(row) = make_summary_row(mechanism, scenarioBaseline, r);

end

%% M4: isolate regulation before introducing timing

m4Scenarios = {
    scenarioBaseline
    scenarioCoordinated
};

for s = 1:numel(m4Scenarios)

    scenario = m4Scenarios{s};

    fprintf("%s | %s\n", M4.label, scenario.name);

    rng(simulationRNG);

    r = run_model_mechanism( ...
        initialState, data, params, scenario, M4);

    allResults.(M4.id).(scenario.id) = r;

    row = row + 1;
    rows(row) = make_summary_row(M4, scenario, r);

end

%% M5: complete timing comparison

for s = 1:numel(scenarioTiming)

    scenario = scenarioTiming{s};

    fprintf("%s | %s\n", M5.label, scenario.name);

    rng(simulationRNG);

    r = run_model_mechanism( ...
        initialState, data, params, scenario, M5);

    allResults.(M5.id).(scenario.id) = r;

    row = row + 1;
    rows(row) = make_summary_row(M5, scenario, r);

end

%% Write compact summary

summaryTable = struct2table(rows);

summaryFile = fullfile(outputDir, "mechanism_summary.csv");
writetable(summaryTable, summaryFile);

%% Save complete output

matFile = fullfile(outputDir, "mechanism_results.mat");

save( ...
    matFile, ...
    "allResults", ...
    "summaryTable", ...
    "params", ...
    "M0", "M1", "M2", "M3", "M4", "M5", ...
    "simulationRNG", ...
    "-v7.3");

%% Display

fprintf("\nMechanism decomposition complete.\n\n");
disp(summaryTable);

fprintf("\nSaved summary:\n  %s\n", summaryFile);
fprintf("Saved full results:\n  %s\n\n", matFile);

%% Incremental diagnostics

fprintf("============================================================\n");
fprintf(" Incremental mechanism diagnostics\n");
fprintf("============================================================\n\n");

for m = 2:numel(baselineMechanisms)

    previousMechanism = baselineMechanisms{m-1};
    currentMechanism = baselineMechanisms{m};

    rPrev = allResults.(previousMechanism.id).baseline;
    rCurr = allResults.(currentMechanism.id).baseline;

    fprintf("%s -> %s\n", ...
        previousMechanism.id, currentMechanism.id);

    fprintf("  Change in final risk:     %+10.4f\n", ...
        rCurr.R(end) - rPrev.R(end));

    fprintf("  Change in final fitness:  %+10.4f\n", ...
        rCurr.F(end) - rPrev.F(end));

    fprintf("  Change in final trade:    %+10.4f\n", ...
        rCurr.totalTrade(end) - rPrev.totalTrade(end));

    fprintf("  Change in total switches: %+10d\n\n", ...
        sum(rCurr.numSwitches) - sum(rPrev.numSwitches));

end

rM4Base = allResults.(M4.id).baseline;
rM4Policy = allResults.(M4.id).coordinated;

fprintf("M4 regulation effect: Coordinated - Baseline\n");
fprintf("  Final risk difference:    %+10.4f\n", ...
    rM4Policy.R(end) - rM4Base.R(end));
fprintf("  Final fitness difference: %+10.4f\n", ...
    rM4Policy.F(end) - rM4Base.F(end));
fprintf("  Final trade difference:   %+10.4f\n", ...
    rM4Policy.totalTrade(end) - rM4Base.totalTrade(end));
fprintf("  Switch difference:        %+10d\n\n", ...
    sum(rM4Policy.numSwitches) - sum(rM4Base.numSwitches));

%% Local helper

function row = make_summary_row(mechanism, scenario, r)

    row = struct();

    row.mechanismID = string(mechanism.id);
    row.mechanismLabel = string(mechanism.label);

    row.scenarioID = string(scenario.id);
    row.scenarioName = string(scenario.name);

    row.finalFitness = r.F(end);
    row.finalRisk = r.R(end);
    row.finalTrade = r.totalTrade(end);
    row.finalRecoveringLinks = r.numRecoveringLinks(end);

    row.totalSwitches = sum(r.numSwitches);
    row.localSwitches = sum(r.numLocalSwitches);
    row.globalSwitches = sum(r.numGlobalSwitches);

end
