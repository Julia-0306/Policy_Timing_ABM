function nextState = update_network(state, switchDecisions)
% UPDATE_NETWORK
% Applies all partner-switching decisions simultaneously.
%
%   A^{c,t} -> A^{c,t+1}
%   W^{c,t} -> W^{c,t+1}
%
% -------------------------------------------------------------------------
% ONE-FOR-ONE REPLACEMENT
% -------------------------------------------------------------------------
%
% Every dissolved relationship is replaced by one distinct new relationship.
% Therefore switching does not mechanically reduce the number of active
% links.
%
% -------------------------------------------------------------------------
% INITIAL VOLUME OF A NEW RELATIONSHIP
% -------------------------------------------------------------------------
%
% If exporter i replaces importer j with importer k:
%
%   W_new,0
%       = W_ij^{c,t} * wHat_ik^{c,t}
%
% where:
%
%   W_ij^{c,t}
%       = realized volume of the replaced relationship
%
%   wHat_ik^{c,t}
%       = normalized market potential of the selected new importer
%         and lies in [0,1]
%
% The pre-switch volume becomes the recovery target:
%
%   W_target = W_ij^{c,t}
%
% The new relationship starts at age zero.
%
% Recovery itself is NOT performed here. It is handled separately by
% update_trade_recovery.m.

A = state.A;
W = state.W;

nextState = state;

%% Work on copies of current network state

Anew = A;
Wnew = W;

isRecovering = state.isRecovering;

recoveryAge = state.recoveryAge;

recoveryStartWeight = state.recoveryStartWeight;

recoveryTargetWeight = state.recoveryTargetWeight;

%% Apply switching decisions

for q = 1:numel(switchDecisions)

    i = ...
        switchDecisions(q).i;

    j = ...
        switchDecisions(q).oldPartner;

    k = ...
        switchDecisions(q).newPartner;

    c = ...
        switchDecisions(q).commodity;

    marketPotential = ...
        switchDecisions(q).marketPotential;

    %% Validate market potential

    assert( ...
        marketPotential >= 0 && ...
        marketPotential <= 1, ...
        "Selected partner market potential must lie in [0,1].");

    %% Pre-switch realized trade volume

    oldTradeVolume = ...
        W(i,j,c);

    %% Initial volume of new relationship
    %
    %   W_new,0 = W_old * wHat_new

    initialNewVolume = ...
        oldTradeVolume .* marketPotential;

    %% -------------------------------------------------------------
    % Remove old relationship
    %% -------------------------------------------------------------

    Anew(i,j,c) = false;

    Wnew(i,j,c) = 0;

    %% Clear any recovery record attached to the old relationship
    %
    % If the old relationship itself was still recovering, that recovery
    % ends because the relationship has been dissolved.

    isRecovering(i,j,c) = false;

    recoveryAge(i,j,c) = 0;

    recoveryStartWeight(i,j,c) = 0;

    recoveryTargetWeight(i,j,c) = 0;

    %% -------------------------------------------------------------
    % Create replacement relationship
    %% -------------------------------------------------------------

    Anew(i,k,c) = true;

    Wnew(i,k,c) = ...
        initialNewVolume;

    %% Start recovery clock at age zero

    recoveryAge(i,k,c) = 0;

    recoveryStartWeight(i,k,c) = ...
        initialNewVolume;

    recoveryTargetWeight(i,k,c) = ...
        oldTradeVolume;

    %% A relationship needs recovery only if initial volume is below target

    isRecovering(i,k,c) = ...
        initialNewVolume < oldTradeVolume;

end

%% Numerical protection

Wnew(Wnew < 0) = 0;

Wnew(~isfinite(Wnew)) = 0;

%% Updated state

nextState.A = Anew;
nextState.W = Wnew;

nextState.isRecovering = isRecovering;

nextState.recoveryAge = recoveryAge;

nextState.recoveryStartWeight = recoveryStartWeight;

nextState.recoveryTargetWeight = recoveryTargetWeight;

end