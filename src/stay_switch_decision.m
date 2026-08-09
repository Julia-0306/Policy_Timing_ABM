function shouldSwitch = stay_switch_decision(currentScore, potentialValue)
% STAY_SWITCH_DECISION
% Locked Chapter 2 stay/switch rule.
%
%   Stay   if S_ij^{c,t} >= V_i^{c,t}
%   Switch if S_ij^{c,t} <  V_i^{c,t}
%
% Ties are resolved in favor of retaining the existing relationship.
%
% No additional threshold or persistence parameter is used.

shouldSwitch = currentScore < potentialValue;

end
