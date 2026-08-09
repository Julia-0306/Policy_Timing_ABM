function outcomes = compute_outcomes(state, rhoImporter, p)
% COMPUTE_OUTCOMES
% Computes network-level economic fitness and environmental risk.
%
% ENVIRONMENTAL OUTCOME
%
%   r_ij^{c,t} = W_ij^{c,t} * delta_ic
%
%   R^t = sum_{c,i,j} r_ij^{c,t}
%
% R^t is interpreted as RELATIVE EMBODIED DEFORESTATION-RISK EXPOSURE,
% not as predicted real-world deforestation.
%
% ECONOMIC OUTCOME
%
% The locked workflow requires a network fitness landscape F^t but does
% not add a separate fitness parameter.
%
% OPERATIONAL ASSUMPTION:
% Exporter-commodity fitness is the trade-share-weighted mean of the
% realized scores of its active relationships:
%
%   F_i^{c,t} = sum_j w_ij^{c,t} * S_ij^{c,t}
%
% where w_ij is the exporter's normalized observed trade share.
%
% Network fitness:
%
%   F^t = sum_{c,i} F_i^{c,t}
%
% This uses the existing partner-score ingredients and introduces no
% additional behavioral coefficients.

A = state.A;
W = state.W;

community = state.community;
D = state.distance;
delta = state.delta;

[N,~,C] = size(W);

fitnessIC = zeros(N,C);
linkRisk = zeros(size(W));

%% Economic fitness

for c = 1:C

    for i = 1:N

        partners = find(A(i,:,c));

        if isempty(partners)
            continue;
        end

        totalTrade = sum(W(i,partners,c));

        if totalTrade <= 0
            continue;
        end

        for jj = 1:numel(partners)

            j = partners(jj);

            observedShare = W(i,j,c) ./ totalTrade;
            phi = double(community(i) == community(j));
            rho = double(rhoImporter(j));

            Sij = partner_score( ...
                phi, ...
                D(i,j), ...
                observedShare, ...
                rho, ...
                p);

            fitnessIC(i,c) = ...
                fitnessIC(i,c) + observedShare .* Sij;

        end

    end

end

%% Environmental risk

for c = 1:C
    for i = 1:N
        linkRisk(i,:,c) = W(i,:,c) .* delta(i,c);
    end
end

outcomes.F_exporterCommodity = fitnessIC;
outcomes.F = sum(fitnessIC(:));

outcomes.r = linkRisk;
outcomes.R = sum(linkRisk(:));

end
