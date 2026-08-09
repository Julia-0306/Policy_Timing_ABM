function [VL, VG, V] = relationship_value( ...
    potentialScores, localMask, globalMask, eL, eG)
% RELATIONSHIP_VALUE
% Evaluates the best local and global potential relationship values
% BEFORE the stay/switch decision.
%
% Local relationship value:
%
%   V_i,L^{c,t} = max_{k in L_i}(S_hat_ik^{c,t}) - e_L
%
% Global relationship value:
%
%   V_i,G^{c,t} = max_{k in G_i}(S_hat_ik^{c,t}) - e_G
%
% Overall potential relationship value:
%
%   V_i^{c,t} = max(V_i,L^{c,t}, V_i,G^{c,t})
%
% IMPORTANT:
% The maximum is used rather than log-sum-exp so that candidate-pool size
% does not mechanically increase the value of an opportunity set.
%
% e_G > e_L reflects the higher cost of global adjustment.

assert(eG > eL, ...
    "Global switching cost eG must exceed local switching cost eL.");

%% Local relationship value

if any(localMask)

    VL = max(potentialScores(localMask)) - eL;

else

    VL = -Inf;

end

%% Global relationship value

if any(globalMask)

    VG = max(potentialScores(globalMask)) - eG;

else

    VG = -Inf;

end

%% Overall potential relationship value

V = max(VL, VG);

end