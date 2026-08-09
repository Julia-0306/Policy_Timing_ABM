function scenario = coordinated(data, T)
% COORDINATED
% EU, UK, and US regulation all become active at t = 6.
%
% This file contains ONLY the policy schedule.
% Behavioral logic is defined in src/ and is identical across scenarios.

scenario.id = "coordinated";
scenario.name = "Coordinated";

scenario.policyOn = false(data.N, T);

regulated = ...
    data.regulatorMask.EU | ...
    data.regulatorMask.UK | ...
    data.regulatorMask.US;

if T >= 6
    scenario.policyOn(regulated, 6:T) = true;
end

end
