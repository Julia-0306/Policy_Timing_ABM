%% ROBUSTNESS: ENVIRONMENTAL CALIBRATION
% Tests whether environmental conclusions depend strongly on imputed
% deforestation-intensity values delta_ic.
%
% IMPORTANT:
% This script does NOT change:
%   - network behavior,
%   - partner scoring,
%   - stay/switch logic,
%   - local/global logic,
%   - policy timing.
%
% It changes ONLY the imputed environmental calibration values.
%
% Directly sourced delta values remain unchanged.

clear;
clc;

projectRoot = fileparts(fileparts(mfilename("fullpath")));

addpath(fullfile(projectRoot, "src"));
addpath(fullfile(projectRoot, "scenarios"));

dataDir = fullfile(projectRoot, "data");
resultsDir = fullfile(projectRoot, "results", "robustness", "environmental");

if ~exist(resultsDir, "dir")
    mkdir(resultsDir);
end

dataBaseline = load_model_data(dataDir);

%% Locked baseline behavioral parameters

params.T = 20;
params.p = 0.50;
params.eL = 0.10;
params.eG = 0.20;
params.beta = 4.0;
params.eta = 0.50;

%% Environmental-calibration robustness
%
% ASSUMPTION:
% Only values marked as imputed in the metadata are perturbed.
%
% Multipliers:
%   0.75 = lower-risk imputation
%   1.00 = baseline calibration
%   1.25 = higher-risk imputation
%
% Values are clipped to the valid [0,1] interval.
%
% These multipliers are robustness scenarios, NOT behavioral parameters.

deltaMultipliers = [0.75 1.00 1.25];

%% Build imputation mask from metadata

imputedMask = build_imputed_mask(dataBaseline);

assert(any(imputedMask(:)), ...
    "No imputed delta values were identified in the metadata.");

%% Use the same synthetic network in every environmental calibration
%
% This isolates the effect of delta calibration itself.

rng(42, "twister");
initialStateBaseline = initialize_network(dataBaseline);

scenarioList = {
    baseline(dataBaseline, params.T)
    early_mover(dataBaseline, params.T)
    sequential(dataBaseline, params.T)
    coordinated(dataBaseline, params.T)
    delayed_coordination(dataBaseline, params.T)
};

%% Run

allResults = struct();
summaryRows = [];

for q = 1:numel(deltaMultipliers)

    multiplier = deltaMultipliers(q);

    data = dataBaseline;

    adjustedDelta = data.delta;

    adjustedDelta(imputedMask) = ...
        adjustedDelta(imputedMask) .* multiplier;

    adjustedDelta = min(max(adjustedDelta, 0), 1);

    data.delta = adjustedDelta;

    initialState = initialStateBaseline;
    initialState.delta = adjustedDelta;

    fieldName = matlab.lang.makeValidName( ...
        sprintf("delta_%g", multiplier));

    allResults.(fieldName) = struct();

    fprintf("\nEnvironmental multiplier = %.2f\n", multiplier);

    for s = 1:numel(scenarioList)

        scenario = scenarioList{s};

        result = run_model( ...
            initialState, ...
            data, ...
            params, ...
            scenario);

        allResults.(fieldName).(scenario.id) = result;

        newRow = table( ...
            multiplier, ...
            string(scenario.id), ...
            string(scenario.name), ...
            result.F(end), ...
            result.R(end), ...
            sum(result.numSwitches), ...
            'VariableNames', { ...
                'delta_multiplier', ...
                'scenario_id', ...
                'scenario_name', ...
                'final_fitness', ...
                'final_risk', ...
                'total_switches'});

        summaryRows = [summaryRows; newRow]; %#ok<AGROW>

    end
end

%% Save

save( ...
    fullfile(resultsDir, "robustness_environmental_results.mat"), ...
    "allResults", ...
    "deltaMultipliers", ...
    "imputedMask", ...
    "params", ...
    "scenarioList", ...
    "-v7.3");

writetable( ...
    summaryRows, ...
    fullfile(resultsDir, "robustness_environmental_summary.csv"));

disp(summaryRows);

fprintf("\nEnvironmental-calibration robustness complete.\n");


%% ------------------------------------------------------------------------
function imputedMask = build_imputed_mask(data)
% BUILD_IMPUTED_MASK
% Converts the long metadata table into an N x C logical matrix matching
% data.delta.
%
% Expected metadata columns include:
%   iso3
%   commodity
%   imputed
%
% The function handles logical, numeric, or string encodings of "imputed".

meta = data.delta_metadata;

required = ["iso3","commodity","imputed"];
available = string(meta.Properties.VariableNames);

assert(all(ismember(required, available)), ...
    "Metadata must contain iso3, commodity, and imputed columns.");

N = data.N;
C = data.C;

imputedMask = false(N,C);

for r = 1:height(meta)

    iso = string(meta.iso3(r));
    commodity = string(meta.commodity(r));

    i = find(data.iso3 == iso, 1);

    c = find(data.commodity_names == commodity, 1);

    if isempty(i) || isempty(c)
        continue;
    end

    rawValue = meta.imputed(r);

    if islogical(rawValue)
        flag = rawValue;

    elseif isnumeric(rawValue)
        flag = rawValue ~= 0;

    else
        value = lower(strtrim(string(rawValue)));
        flag = ismember(value, ["1","true","yes","y","imputed"]);

    end

    imputedMask(i,c) = flag;

end

end
