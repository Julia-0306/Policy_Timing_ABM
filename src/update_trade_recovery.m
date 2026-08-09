function nextState = update_trade_recovery( ...
    state, ...
    newlyCreatedLinks, ...
    recoveryHorizon)
% UPDATE_TRADE_RECOVERY
% Updates trade volumes of surviving replacement relationships that are
% currently rebuilding toward their pre-switch trade volume.
%
% One model period equals one year.
%
% -------------------------------------------------------------------------
% LOCKED RECOVERY RULE
% -------------------------------------------------------------------------
%
% A replacement relationship begins with:
%
%   W_new,0
%
% and has target:
%
%   W_target = pre-switch trade volume.
%
% If the relationship survives, trade recovers linearly:
%
%   W(a)
%       = W_new,0
%         + min(a/H,1)
%           * (W_target - W_new,0)
%
% where:
%
%   a = age of replacement relationship in years
%   H = recovery horizon in years
%
% Baseline:
%
%   H = 5
%
% Therefore full recovery occurs exactly after five surviving years.
%
% -------------------------------------------------------------------------
% IMPORTANT TIMING CONVENTION
% -------------------------------------------------------------------------
%
% A link formed during the current t -> t+1 transition enters the new
% network at age 0.
%
% It must NOT immediately receive its age-1 recovery increment.
%
% newlyCreatedLinks identifies those links so they are excluded from ageing
% in the period in which they are formed.
%
% At the next annual transition, if they still survive, age increases from
% 0 to 1 and they receive the first linear recovery step.

nextState = state;

A = state.A;
W = state.W;

isRecovering = state.isRecovering;

recoveryAge = state.recoveryAge;

recoveryStartWeight = state.recoveryStartWeight;

recoveryTargetWeight = state.recoveryTargetWeight;

[N,~,C] = size(W);

%% Create logical mask of links formed in the current transition

createdNow = false(N,N,C);

for q = 1:numel(newlyCreatedLinks)

    i = newlyCreatedLinks(q).i;

    k = newlyCreatedLinks(q).newPartner;

    c = newlyCreatedLinks(q).commodity;

    createdNow(i,k,c) = true;

end

%% Update all surviving recovering relationships

for c = 1:C

    for i = 1:N

        for j = 1:N

            %% Only active recovering links matter

            if ~A(i,j,c)
                continue;
            end

            if ~isRecovering(i,j,c)
                continue;
            end

            %% A newly created link remains at age zero this period

            if createdNow(i,j,c)
                continue;
            end

            %% Increase relationship age by one year

            recoveryAge(i,j,c) = ...
                recoveryAge(i,j,c) + 1;

            age = ...
                recoveryAge(i,j,c);

            startWeight = ...
                recoveryStartWeight(i,j,c);

            targetWeight = ...
                recoveryTargetWeight(i,j,c);

            %% Linear recovery

            recoveryShare = ...
                min(age ./ recoveryHorizon, 1);

            W(i,j,c) = ...
                startWeight ...
                + recoveryShare ...
                .* (targetWeight - startWeight);

            %% Full recovery reached

            if age >= recoveryHorizon

                W(i,j,c) = ...
                    targetWeight;

                isRecovering(i,j,c) = false;

            end

        end

    end

end

%% Numerical protection

W(W < 0) = 0;

W(~isfinite(W)) = 0;

%% Store updated recovery state

nextState.W = W;

nextState.isRecovering = isRecovering;

nextState.recoveryAge = recoveryAge;

nextState.recoveryStartWeight = recoveryStartWeight;

nextState.recoveryTargetWeight = recoveryTargetWeight;

end