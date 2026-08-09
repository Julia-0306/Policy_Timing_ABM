function data = load_model_data(dataDir)
% Load model data
% Reads and validates the five Chapter 2 data files.
%
% Expected files:
%   countries.csv
%   regulators.csv
%   distance_matrix.csv
%   deforestation_intensity_v2.csv
%   deforestation_intensity_metadata_v2.csv
%
% This function only prepares empirical/semi-empirical inputs.
% It does NOT introduce behavioral assumptions.

arguments
    dataDir (1,1) string = "data"
end

%% Read files

countries = readtable(fullfile(dataDir, "countries.csv"), ...
    TextType="string");

regulators = readtable(fullfile(dataDir, "regulators.csv"), ...
    TextType="string");

distanceTable = readtable(fullfile(dataDir, "distance_matrix.csv"), ...
    TextType="string", VariableNamingRule="preserve");

deltaTable = readtable(fullfile(dataDir, "deforestation_intensity_v2.csv"), ...
    TextType="string");

deltaMetadata = readtable( ...
    fullfile(dataDir, "deforestation_intensity_metadata_v2.csv"), ...
    TextType="string");

%% Basic validation

countries = sortrows(countries, "model_id");
regulators = sortrows(regulators, "model_id");

N = height(countries);

assert(N == 30, ...
    "The current Chapter 2 design uses 30 country agents.");

assert(height(regulators) == N, ...
    "regulators.csv must contain exactly one row per modeled country.");

assert(all(countries.iso3 == regulators.iso3), ...
    "countries.csv and regulators.csv must use the same country order.");

%% Country identifiers

data.N = N;
data.model_id = countries.model_id;
data.iso3 = countries.iso3;
data.country_name = countries.country_name;
data.latitude = countries.latitude;
data.longitude = countries.longitude;

%% Regulator groups

data.regulator_group = regulators.regulator_group;
data.is_regulator = logical(regulators.is_regulator);

data.regulatorMask.EU = regulators.regulator_group == "EU";
data.regulatorMask.UK = regulators.regulator_group == "UK";
data.regulatorMask.US = regulators.regulator_group == "US";

%% Distance matrix

distanceIso = distanceTable{:,1};
distanceIso = string(distanceIso);

assert(all(distanceIso == countries.iso3), ...
    "Rows of distance_matrix.csv must match countries.csv.");

distanceColumns = string(distanceTable.Properties.VariableNames(2:end));

assert(all(distanceColumns == countries.iso3'), ...
    "Columns of distance_matrix.csv must match countries.csv.");

D = table2array(distanceTable(:,2:end));
D = double(D);

assert(all(size(D) == [N N]), ...
    "Distance matrix must be N x N.");

assert(all(abs(diag(D)) < 1e-10), ...
    "Distance matrix diagonal must be zero.");

%% Normalize geographic distance to [0,1]
%
% LOCKED MODEL REQUIREMENT:
% Partner-score components are normalized and equally weighted.
%
% The minimum and maximum are calculated over off-diagonal bilateral
% distances only. No distance-weight parameter is introduced.

offDiagonal = ~eye(N);
validD = D(offDiagonal);

dMin = min(validD);
dMax = max(validD);

assert(dMax > dMin, ...
    "Distance matrix has no usable variation.");

Dnorm = zeros(N,N);
Dnorm(offDiagonal) = (D(offDiagonal) - dMin) ./ (dMax - dMin);

data.distance_km = D;
data.distance = Dnorm;

%% Deforestation intensity delta_ic

deltaTable = sortrows(deltaTable, "country");

% Reorder explicitly to the country order used by the model.
[tf, loc] = ismember(countries.iso3, deltaTable.country);

assert(all(tf), ...
    "Every modeled country must occur in deforestation_intensity_v2.csv.");

deltaTable = deltaTable(loc,:);

commodityNames = ["palm_oil","soy","timber","paper"];

delta = zeros(N, numel(commodityNames));

for c = 1:numel(commodityNames)
    delta(:,c) = deltaTable.(commodityNames(c));
end

assert(all(delta(:) >= 0 & delta(:) <= 1), ...
    "All deforestation intensity values must lie in [0,1].");

data.C = numel(commodityNames);
data.commodity_names = commodityNames;
data.delta = delta;

%% Metadata is retained for provenance only.
% It does not directly affect simulation behavior.

data.delta_metadata = deltaMetadata;

end
