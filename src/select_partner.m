function [selectedPartner, probabilities] = select_partner( ...
    candidatePool, poolScores, beta)
% SELECT_PARTNER
% Selects the specific replacement importer within the already-selected
% local or global candidate pool.
%
% Locked softmax rule:
%
%   P_ik^{c,t}
%      = exp(beta*S_hat_ik^{c,t})
%        / sum_{m in C_i} exp(beta*S_hat_im^{c,t})
%
% beta is the choice-sensitivity parameter.
% No additional partner-selection parameter is introduced.

if isempty(candidatePool)
    selectedPartner = [];
    probabilities = [];
    return;
end

z = beta .* poolScores(:);
z = z - max(z);

weights = exp(z);
probabilities = weights ./ sum(weights);

u = rand;
cdf = cumsum(probabilities);

position = find(u <= cdf, 1, "first");

if isempty(position)
    position = numel(candidatePool);
end

selectedPartner = candidatePool(position);

end
