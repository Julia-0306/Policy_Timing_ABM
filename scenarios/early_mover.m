function scenario = early_mover(data, T)
% EARLY_MOVER
% EU regulation becomes active at t = 6.
% UK and US remain unregulated throughout the simulation.
%
% This file contains ONLY the policy schedule.
% Behavioral logic is defined in src/ and is identical across scenarios.

scenario.id = "early_mover";
scenario.name = "Early Mover";

scenario.policyOn = false(data.N, T);

EU = data.regulatorMask.EU;

if T >= 6
    scenario.policyOn(EU, 6:T) = true;
end

end
