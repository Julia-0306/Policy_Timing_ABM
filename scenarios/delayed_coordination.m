function scenario = delayed_coordination(data, T)
% DELAYED_COORDINATION
% Locked policy timing:
%
%   EU -> t = 6
%   UK -> t = 12
%   US -> t = 12
%
% This file contains ONLY the policy schedule.
% Behavioral logic is defined in src/ and is identical across scenarios.

scenario.id = "delayed_coordination";
scenario.name = "Delayed Coordination";

scenario.policyOn = false(data.N, T);

EU = data.regulatorMask.EU;
UK = data.regulatorMask.UK;
US = data.regulatorMask.US;

if T >= 6
    scenario.policyOn(EU, 6:T) = true;
end

if T >= 12
    scenario.policyOn(UK | US, 12:T) = true;
end

end
