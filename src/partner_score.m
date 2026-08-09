function S = partner_score(phi, distanceNorm, tradeTerm, rho, p)
% Partner Score
% Locked Chapter 2 partner-score equation.
%
% Current relationship:
%
%   S_ij^{c,t} = phi_ij - d_ij + w_ij^{c,t} - p*rho_ij^{c,t}
%
% Potential relationship:
%
%   S_hat_ik^{c,t} = phi_ik - d_ik + w_hat_ik^{c,t}
%                    - p*rho_ik^{c,t}
%
% where:
%   phi       = same trade-community indicator
%   d         = normalized geographic distance
%   w         = normalized observed trade weight for current relationship
%   w_hat     = normalized expected trade potential for candidate importer
%   rho       = regulatory exposure
%   p         = regulatory penalty
%
% Assumption:
% Community, distance, and trade components are equally important after
% normalization. There are NO alpha_C, alpha_D, or alpha_W parameters.
%
% Estimating heterogeneous component weights is left for future research.

S = phi ...
    - distanceNorm ...
    + tradeTerm ...
    - p .* rho;

end
