function scenario = sequential(data, T)
% SEQUENTIAL
% Locked policy timing:
%
%   EU -> t = 6
%   UK -> t = 10
%   US -> t = 14
%
% This file contains ONLY the policy schedule.
% Behavioral logic is defined in src/ and is identical across scenarios.

scenario.id = "sequential";
scenario.name = "Sequential";

scenario.policyOn = false(data.N, T);

EU = data.regulatorMask.EU;
UK = data.regulatorMask.UK;
US = data.regulatorMask.US;

if T >= 6
    scenario.policyOn(EU, 6:T) = true;
end

if T >= 10
    scenario.policyOn(UK, 10:T) = true;
end

if T >= 14
    scenario.policyOn(US, 14:T) = true;
end

end
