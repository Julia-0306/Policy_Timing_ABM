%% ROBUSTNESS: BEHAVIORAL PARAMETER SENSITIVITY
% Tests sensitivity to the four assumed behavioral parameters:
%
%   p     regulatory penalty
%   eL    local switching cost
%   eG    global switching cost
%   beta  choice sensitivity
%
% IMPORTANT:
% This script does NOT change the locked model logic.
% Each parameter is varied ONE AT A TIME around the baseline while all
% other parameters remain fixed.
%
% No new behavioral parameters are introduced.

clear;
clc;

projectRoot = fileparts(fileparts(mfilename("fullpath")));

addpath(fullfile(projectRoot, "src"));
addpath(fullfile(projectRoot, "scenarios"));

dataDir = fullfile(projectRoot, "data");
resultsDir = fullfile(projectRoot, "results", "robustness", "parameters");

if ~exist(resultsDir, "dir")
    mkdir(resultsDir);
end

data = load_model_data(dataDir);

%% Baseline specification

baseParams.T = 20;
baseParams.p = 0.50;
baseParams.eL = 0.10;
baseParams.eG = 0.20;
baseParams.beta = 4.0;
baseParams.eta = 0.50;

%% Provisional sensitivity grids
%
% These are robustness values, not new model parameters.
%
% The grids deliberately span lower, baseline, and higher values.

pValues = [0.25 0.50 0.75];

eLValues = [0.05 0.10 0.15];

% eG is varied while preserving the locked condition eG > eL.
eGValues = [0.15 0.20 0.30];

betaValues = [2.0 4.0 8.0];

%% Identical initial network for all parameter tests

rng(42, "twister");
initialState = initialize_network(data);

scenarioList = {
    baseline(data, baseParams.T)
    early_mover(data, baseParams.T)
    sequential(data, baseParams.T)
    coordinated(data, baseParams.T)
    delayed_coordination(data, baseParams.T)
};

%% Run one-at-a-time sensitivity

allResults = struct();
summaryRows = [];

parameterNames = ["p","eL","eG","beta"];
parameterValues = {pValues, eLValues, eGValues, betaValues};

for q = 1:numel(parameterNames)

    parameterName = parameterNames(q);
    values = parameterValues{q};

    for v = 1:numel(values)

        params = baseParams;
        params.(parameterName) = values(v);

        % Preserve the locked cost ordering.
        if params.eG <= params.eL
            continue;
        end

        settingField = matlab.lang.makeValidName( ...
            sprintf("%s_%g", parameterName, values(v)));

        allResults.(settingField) = struct();

        fprintf("\n%s = %.3f\n", parameterName, values(v));

        for s = 1:numel(scenarioList)

            scenario = scenarioList{s};

            result = run_model( ...
                initialState, ...
                data, ...
                params, ...
                scenario);

            allResults.(settingField).(scenario.id) = result;

            newRow = table( ...
                parameterName, ...
                values(v), ...
                string(scenario.id), ...
                string(scenario.name), ...
                result.F(end), ...
                result.R(end), ...
                sum(result.numSwitches), ...
                sum(result.numLocalSwitches), ...
                sum(result.numGlobalSwitches), ...
                'VariableNames', { ...
                    'parameter', ...
                    'value', ...
                    'scenario_id', ...
                    'scenario_name', ...
                    'final_fitness', ...
                    'final_risk', ...
                    'total_switches', ...
                    'local_switches', ...
                    'global_switches'});

            summaryRows = [summaryRows; newRow]; %#ok<AGROW>

        end
    end
end

%% Save

save( ...
    fullfile(resultsDir, "robustness_parameters_results.mat"), ...
    "allResults", ...
    "baseParams", ...
    "pValues", ...
    "eLValues", ...
    "eGValues", ...
    "betaValues", ...
    "scenarioList", ...
    "-v7.3");

writetable( ...
    summaryRows, ...
    fullfile(resultsDir, "robustness_parameters_summary.csv"));

disp(summaryRows);

fprintf("\nBehavioral-parameter robustness complete.\n");
