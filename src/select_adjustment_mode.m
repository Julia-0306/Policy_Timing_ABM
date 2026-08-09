function [candidatePool, mode] = select_adjustment_mode( ...
    localCandidates, globalCandidates, VL, VG)
% SELECT_ADJUSTMENT_MODE
% Implements the local/global mode AFTER a switch has been chosen.
%
% IMPORTANT:
% Local/global opportunity values were already evaluated before the
% stay/switch decision. This function therefore does NOT introduce a new
% independent decision.
%
% Locked rule:
%
%   Local  if V_L >= V_G
%   Global if V_G > V_L
%
% The selected pool C_i is passed to partner selection.

if VL >= VG
    candidatePool = localCandidates;
    mode = "local";
else
    candidatePool = globalCandidates;
    mode = "global";
end

end
