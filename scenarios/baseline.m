function scenario = baseline(data, T)
% BASELINE
% No importer-side regulation is active at any point in the simulation.
%
% This file contains ONLY the policy schedule.
% Behavioral logic is defined in src/ and is identical across scenarios.

N = data.N;

scenario.id = "baseline";
scenario.name = "Baseline";

scenario.policyOn = false(N, T);

end
