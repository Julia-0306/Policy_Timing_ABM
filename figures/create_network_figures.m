%% CREATE_NETWORK_FIGURES
% Publication-ready network figures for Chapter 2.
%
% Run from the repository root with:
%
%   matlab -batch "run('figures/create_network_figures.m')"
%
% REQUIRED INPUT:
%   results/chapter2_results.mat
%
% The MAT file must contain:
%   results.baseline.A / W
%   results.sequential.A / W
%   results.coordinated.A / W
%   results.delayed_coordination.A / W
%   data
%
% The benchmark result structure stores A and W for every network state,
% including the initial state and the network after each annual transition.
%
% FIGURES CREATED:
%   1. Fig2.pdf/.png
%      Initial palm-oil network (t = 1).
%
%   2. Fig3.pdf/.png
%      Sequential, coordinated, and delayed-coordination networks
%      immediately after the first regulatory intervention (t = 7)
%      and at the final network state (t = 21, i.e. after period 20).
%
%   3. Fig4.pdf/.png
%      Final policy-induced rewiring relative to the paired baseline.
%
% PUBLICATION-STYLE CHANGES IN THIS VERSION
%   - Colour-blind-safe, print-safe palette (Okabe-Ito) for communities,
%     used consistently instead of MATLAB's default `lines` colormap.
%   - A community + regulator legend is now drawn on every figure (the
%     original only had a legend on the rewiring figure).
%   - An explicit edge-width "key" is added so a reader can translate
%     line thickness back into a trade-flow magnitude; without it, edge
%     width is a decoration rather than data.
%   - Directed edges between a reciprocal pair (i->j and j->i both exist)
%     are drawn as two separate curved arcs rather than overlapping
%     straight quiver arrows, so direction is not lost by occlusion.
%   - Arrowhead size is computed from the fixed axis extent rather than
%     from `quiver`'s auto-scaling, so arrowheads are visually consistent
%     across panels and across figures.
%   - Panel labels (a), (b), (c) ... are added to all multi-panel figures,
%     as most journals require.
%   - A single, explicit font family/size hierarchy is applied to every
%     axes (title / label / tick / legend), instead of relying on
%     scattered per-call FontSize values.
%   - Text objects use 'Interpreter','none' so that underscores in
%     regulator-group labels or ISO3 codes are never parsed as TeX
%     subscripts.
%   - The global random stream is saved and restored around the seeded
%     community reconstruction, so this plotting script has no side
%     effects on any other randomised code that may run in the same
%     session.
%   - PNG export resolution set to 1000 dpi for line-art compatibility.
%     Vector PDF remains the preferred submission format.
%   - The script still DOES NOT rerun the model and DOES NOT alter
%     results; it only reads results/chapter2_results.mat.
%
% COLOUR SPACE:
%   Figures are exported as RGB PNG and vector PDF. No manual CMYK
%   conversion is applied.
%
% IMPORTANT:
%   - Node position is a fixed, synthetic, geography-free layout driven
%     purely by community membership (see compute_community_layout),
%     reused identically across every panel in every figure -- real
%     longitude/latitude is no longer used for plotting (only passed
%     through unchanged to initialize_network(data), in case the
%     underlying trade model itself uses geography).
%   - Community colours are fixed across all panels.
%   - Edge-width scaling is fixed across comparable panels.
%   - The community assignment is reconstructed with the benchmark seed
%     used for network initialisation (42). This is safe only if the
%     benchmark network was generated with rng(42,"twister"), as in main.m.
%
% If community information is later stored directly in chapter2_results.mat,
% replace the reconstruction block below with that stored vector.

clear;
clc;
close all;

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------

scriptDir = fileparts(mfilename("fullpath"));
projectRoot = fileparts(scriptDir);

srcDir = fullfile(projectRoot, "src");
resultsDir = fullfile(projectRoot, "results");
figureDir = fullfile(resultsDir, "figures");

addpath(srcDir);

if ~exist(figureDir, "dir")
    mkdir(figureDir);
end

resultFile = fullfile(resultsDir, "chapter2_results.mat");

assert(isfile(resultFile), ...
    "Missing results/chapter2_results.mat. Run main.m first.");

S = load(resultFile);

assert(isfield(S, "results"), ...
    "chapter2_results.mat does not contain variable 'results'.");

assert(isfield(S, "data"), ...
    "chapter2_results.mat does not contain variable 'data'.");

results = S.results;
data = S.data;

%% ------------------------------------------------------------------------
% Publication style (fonts, sizes) — applied globally
% -------------------------------------------------------------------------

pubStyle = struct( ...
    "FontName",        "Helvetica", ...
    "TitleFontSize",   9, ...
    "LabelFontSize",   8, ...
    "TickFontSize",    7.5, ...
    "LegendFontSize",  7.5, ...
    "PanelLabelSize",  9, ...
    "TextColor",       [0 0 0], ...
    "BackgroundColor", [1 1 1]);

set(groot, "DefaultAxesFontName",  pubStyle.FontName);
set(groot, "DefaultTextFontName",  pubStyle.FontName);
set(groot, "DefaultAxesFontSize",  pubStyle.TickFontSize);
set(groot, "DefaultLegendFontName", pubStyle.FontName);

% Force a light, print-style appearance regardless of the user's MATLAB
% UI theme (recent MATLAB releases can default new figures to a dark
% theme, e.g. when synced to the OS appearance setting). Without this,
% axes/text pick up dark-theme foreground/background defaults even
% though the figure Color is explicitly set to white below, producing a
% black plot area with washed-out grey text. DefaultFigureTheme is only
% available from R2025a onward, so this is wrapped defensively; the
% explicit "w"/"k" colors set on every axes and text object elsewhere in
% this script are the real guarantee and work on any release.
try
    set(groot, "DefaultFigureTheme", "light");
catch
    % Theme property unavailable on this MATLAB release; harmless.
end

set(groot, "DefaultAxesColor", pubStyle.BackgroundColor);
set(groot, "DefaultAxesXColor", pubStyle.TextColor);
set(groot, "DefaultAxesYColor", pubStyle.TextColor);
set(groot, "DefaultTextColor", pubStyle.TextColor);

%% ------------------------------------------------------------------------
% Figure settings
% -------------------------------------------------------------------------

commodityIndex = 1;       % 1 = palm oil in the Chapter 2 model
commodityLabel = "Palm oil";

% Network-state indices:
%
% results.A{1}  = initial network at t = 1
% results.A{7}  = network after transition t = 6, i.e. state at t = 7
% results.A{21} = final state after period 20
initialIndex = 1;
postFirstShockIndex = 7;

nStates = numel(results.baseline.A);
finalIndex = nStates;

% Plotting preferences.
% Show "ISO3 / weighted degree" text inside every node, matching the
% reference figure's always-labelled nodes.
labelAllNodes = true;
% No coordinate grid/axis labels -- this is now an abstract,
% geography-free layout, not a map.
showAxes = false;

% Export resolution for PNG versions (dpi). 600 is a safe default for
% combination line/point figures; use 1200 if the journal requires it
% for pure line art.
pngResolution = 1000;

% Curvature applied to reciprocal (bidirectional) edge pairs, as a
% fraction of the straight-line edge length. Set to 0 to disable.
reciprocalCurvature = 0.12;

%% ------------------------------------------------------------------------
% Validate saved histories
% -------------------------------------------------------------------------

scenarioIDs = [
    "baseline"
    "sequential"
    "coordinated"
    "delayed_coordination"
];

for s = 1:numel(scenarioIDs)

    id = scenarioIDs(s);

    assert(isfield(results, id), ...
        "Missing scenario '%s' in results.", id);

    assert(isfield(results.(id), "A") && isfield(results.(id), "W"), ...
        "Scenario '%s' does not contain A/W network histories.", id);

    assert(numel(results.(id).A) == nStates, ...
        "Scenario '%s' has a different number of A states.", id);

    assert(numel(results.(id).W) == nStates, ...
        "Scenario '%s' has a different number of W states.", id);

end

assert(postFirstShockIndex <= nStates, ...
    "Requested post-shock network state is not available.");

%% ------------------------------------------------------------------------
% Country metadata
% -------------------------------------------------------------------------
%
% Note: data.longitude / data.latitude are still read here (via N below)
% and passed untouched into initialize_network(data) further down, since
% the underlying trade-network model may use real geography internally.
% They are NOT used for node plot positions any more -- see "Node layout"
% below, which replaces them with a synthetic, geography-free layout.

N = numel(data.longitude);

iso3 = to_string_vector(data.iso3, N);

% Regulator labels.
if isfield(data, "is_regulator")
    regulatorMask = logical(data.is_regulator(:));
else
    regulatorMask = false(N,1);
end

if isfield(data, "regulator_group")
    regulatorGroup = to_string_vector(data.regulator_group, N);
else
    regulatorGroup = strings(N,1);
end

%% ------------------------------------------------------------------------
% Reconstruct the fixed benchmark community assignment
% -------------------------------------------------------------------------
%
% The saved benchmark results contain A/W histories but not the community
% vector. Community assignment is part of the initialized state and is fixed
% through time. The benchmark main script initializes the network after:
%
%   rng(42,"twister")
%
% so reconstruct the same initial state using that seed. The current
% global random stream is saved beforehand and restored afterward so this
% plotting script has no side effects on other code in the same session.

previousRngState = rng;
rng(42, "twister");
initialStateForPlot = initialize_network(data);
community = initialStateForPlot.community(:);
rng(previousRngState);

assert(numel(community) == N, ...
    "Community vector does not match number of countries.");

K = max(community);
communityColors = get_colorblind_palette(K);
communityLabels = "Community " + string(1:K);

%% ------------------------------------------------------------------------
% Node layout — synthetic, geography-free (replaces longitude/latitude)
% -------------------------------------------------------------------------
%
% Nodes are placed on a fixed, deterministic layout driven purely by
% community membership: each community gets its own position around a
% large outer circle, and its member nodes are arranged on a small circle
% around that community's centre. This is computed once here and reused
% for every panel in every figure below (exactly as the real lon/lat
% coordinates were reused across panels before), so a given country sits
% in the same spot in every figure and panels stay visually comparable.
% Inner-circle radius grows with community size so nodes never overlap
% regardless of how large a community is, and the outer circle radius is
% chosen so neighbouring communities' circles can't overlap each other
% either -- unlike real-world geography, this layout has no crowded
% regions by construction, so no inset/zoom is needed.

[longitude, latitude] = compute_community_layout(community);

%% ------------------------------------------------------------------------
% Verify that reconstructed initial network matches stored benchmark
% -------------------------------------------------------------------------

AStoredInitial = logical(results.baseline.A{initialIndex});
WStoredInitial = double(results.baseline.W{initialIndex});

sameA = isequal(AStoredInitial, logical(initialStateForPlot.A));
sameW = max(abs(WStoredInitial(:) - double(initialStateForPlot.W(:)))) < 1e-10;

if ~(sameA && sameW)
    warning([ ...
        "The network reconstructed with seed 42 does not exactly match " ...
        "the saved initial benchmark network. Network figures will still " ...
        "use the SAVED A/W histories, but community colours may not be " ...
        "the original assignments. If your current benchmark uses a " ...
        "different seed, change the seed in this plotting script or save " ...
        "state.community directly in chapter2_results.mat." ...
    ]);
end

%% ------------------------------------------------------------------------
% Common edge-weight scaling — percentile-based colour + transparency
% -------------------------------------------------------------------------
%
% Rather than mapping raw weight linearly to line width (which, for a
% skewed trade-weight distribution, either buries everything below the
% top few ties or makes most ties visually indistinguishable), every
% edge is placed on its PERCENTILE within a shared reference
% distribution. That percentile then drives three redundant visual
% channels together — colour, opacity, and (lightly) width — so weak
% ties fade toward near-invisible and only the relationships that matter
% stay visually loud. This is what actually fixes a "blob" of
% same-weight-looking grey lines: colour/opacity contrast reads far
% better than width alone once there are more than a handful of edges.
%
% Two reference distributions are used:
%   - weightRefInitial: nonzero weights in the initial network (Figure 1).
%   - weightRefMain: pooled nonzero weights across all scenario/timepoint
%     panels shown in Figure 2, so percentile (and therefore colour) is
%     directly comparable across all six panels of that figure.

snapshotScenarioIDs = [
    "sequential"
    "coordinated"
    "delayed_coordination"
];

snapshotIndices = [
    postFirstShockIndex
    finalIndex
];

allMainWeights = [];
for s = 1:numel(snapshotScenarioIDs)
    for q = 1:numel(snapshotIndices)
        Wq = double(results.(snapshotScenarioIDs(s)).W{snapshotIndices(q)}(:,:,commodityIndex));
        allMainWeights = [allMainWeights; Wq(Wq > 0)]; %#ok<AGROW>
    end
end

edgeColormap = parula(256);

weightRefMain = struct( ...
    "sorted", sort(allMainWeights), ...
    "cmap", edgeColormap);

weightRefInitial = struct( ...
    "sorted", sort(WStoredInitial(WStoredInitial > 0)), ...
    "cmap", edgeColormap);

%% ========================================================================
% FIGURE 1: INITIAL NETWORK
% ==========================================================================

fig1 = figure( ...
    "Color", "w", ...
    "Units", "centimeters", ...
    "Position", [2 2 19 10.5]);
try, fig1.Theme = "light"; catch, end %#ok<TRYNC>

tl1 = tiledlayout(fig1, 1, 4, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

ax1 = nexttile(tl1, 1, [1 3]);

draw_weighted_network( ...
    ax1, ...
    AStoredInitial(:,:,commodityIndex), ...
    WStoredInitial(:,:,commodityIndex), ...
    longitude, ...
    latitude, ...
    community, ...
    communityColors, ...
    regulatorMask, ...
    regulatorGroup, ...
    iso3, ...
    weightRefInitial, ...
    labelAllNodes, ...
    showAxes, ...
    reciprocalCurvature, ...
    620, ...
    struct("axisLimits", [], "arrowHeadLen", []), ...
    pubStyle);

axPanel1 = nexttile(tl1, 4);
draw_side_panel(axPanel1, communityColors, communityLabels, ...
    any(regulatorMask), weightRefInitial, pubStyle);

export_figure_pair( ...
    fig1, ...
    figureDir, ...
    "Fig2", ...
    pngResolution);

%% ========================================================================
% FIGURE 2: TIMING SCENARIO SNAPSHOTS
% ==========================================================================

fig2 = figure( ...
    "Color", "w", ...
    "Units", "centimeters", ...
    "Position", [1 1 19 15.8]);
try, fig2.Theme = "light"; catch, end %#ok<TRYNC>

tl2 = tiledlayout(fig2, 2, 4, ...
    "TileSpacing", "loose", ...
    "Padding", "normal");

scenarioTitles = [
    "Sequential"
    "Coordinated"
    "Delayed"
];

panelLabels2 = ["a" "b" "c" "d" "e" "f"];

% At t = 7 only the first intervention has occurred. Sequential and delayed
% coordination must therefore still be identical, whereas coordinated
% regulation has already activated all three regulators.
assert( ...
    isequal( ...
        logical(results.sequential.A{postFirstShockIndex}(:,:,commodityIndex)), ...
        logical(results.delayed_coordination.A{postFirstShockIndex}(:,:,commodityIndex))) ...
    && ...
    max( ...
        abs( ...
            double(results.sequential.W{postFirstShockIndex}(:,:,commodityIndex)) - ...
            double(results.delayed_coordination.W{postFirstShockIndex}(:,:,commodityIndex)) ...
        ), ...
        [], "all") < 1e-10, ...
    "At t=7 sequential and delayed coordination should still be identical." ...
);

for s = 1:numel(snapshotScenarioIDs)

    id = snapshotScenarioIDs(s);

    % Row 1: state immediately after the first regulatory intervention.
    % (Tiles 1-3 of the 2x4 grid; tile 4/8 are reserved for the side panel.)
    ax = nexttile(tl2, s);

    draw_weighted_network( ...
        ax, ...
        logical(results.(id).A{postFirstShockIndex}(:,:,commodityIndex)), ...
        double(results.(id).W{postFirstShockIndex}(:,:,commodityIndex)), ...
        longitude, ...
        latitude, ...
        community, ...
        communityColors, ...
        regulatorMask, ...
        regulatorGroup, ...
        iso3, ...
        weightRefMain, ...
        labelAllNodes, ...
        showAxes, ...
        reciprocalCurvature, ...
        220, ...
        struct("axisLimits", [], "arrowHeadLen", [], "labelMode", "iso"), ...
        pubStyle);

    title(ax, ...
        sprintf("%s, t = 7", scenarioTitles(s)), ...
        "FontWeight", "bold", "FontSize", pubStyle.TitleFontSize - 0.5, ...
        "Color", pubStyle.TextColor);
    add_panel_label(ax, panelLabels2(s), pubStyle);

    % Row 2: final network.
    ax = nexttile(tl2, s + 4);

    draw_weighted_network( ...
        ax, ...
        logical(results.(id).A{finalIndex}(:,:,commodityIndex)), ...
        double(results.(id).W{finalIndex}(:,:,commodityIndex)), ...
        longitude, ...
        latitude, ...
        community, ...
        communityColors, ...
        regulatorMask, ...
        regulatorGroup, ...
        iso3, ...
        weightRefMain, ...
        labelAllNodes, ...
        showAxes, ...
        reciprocalCurvature, ...
        220, ...
        struct("axisLimits", [], "arrowHeadLen", [], "labelMode", "iso"), ...
        pubStyle);

    title(ax, ...
        sprintf("%s, final", scenarioTitles(s)), ...
        "FontWeight", "bold", "FontSize", pubStyle.TitleFontSize - 0.5, ...
        "Color", pubStyle.TextColor);
    add_panel_label(ax, panelLabels2(s + 3), pubStyle);

end

% Single shared legend + edge-width key for the whole figure, in its own
% reserved tile spanning both rows of the last column.
axPanel2 = nexttile(tl2, 4, [2 1]);
draw_side_panel(axPanel2, communityColors, communityLabels, ...
    any(regulatorMask), weightRefMain, pubStyle);

export_figure_pair( ...
    fig2, ...
    figureDir, ...
    "Fig3", ...
    pngResolution);

%% ========================================================================
% FIGURE 3: FINAL REWIRING RELATIVE TO BASELINE
% ==========================================================================

fig3 = figure( ...
    "Color", "w", ...
    "Units", "centimeters", ...
    "Position", [1 1 19 8.5]);
try, fig3.Theme = "light"; catch, end %#ok<TRYNC>

tl3 = tiledlayout(fig3, 1, 3, ...
    "TileSpacing", "compact", ...
    "Padding", "normal");

A_base_final = logical( ...
    results.baseline.A{finalIndex}(:,:,commodityIndex));

panelLabels3 = ["a" "b" "c"];

for s = 1:numel(snapshotScenarioIDs)

    id = snapshotScenarioIDs(s);

    A_policy_final = logical( ...
        results.(id).A{finalIndex}(:,:,commodityIndex));

    ax = nexttile(tl3, s);

    draw_rewiring_network( ...
        ax, ...
        A_base_final, ...
        A_policy_final, ...
        longitude, ...
        latitude, ...
        community, ...
        communityColors, ...
        regulatorMask, ...
        regulatorGroup, ...
        iso3, ...
        pubStyle);

    nAdded = nnz(A_policy_final & ~A_base_final);
    nRemoved = nnz(A_base_final & ~A_policy_final);
    nCommon = nnz(A_policy_final & A_base_final);

   title(ax, ...
    sprintf( ...
        "%s\nAdded: %d | Removed: %d\nCommon: %d", ...
        scenarioTitles(s), ...
        nAdded, ...
        nRemoved, ...
        nCommon), ...
    "FontWeight", "bold", ...
    "FontSize", pubStyle.TitleFontSize - 1, ...
    "Color", pubStyle.TextColor);

end

export_figure_pair( ...
    fig3, ...
    figureDir, ...
    "Fig4", ...
    pngResolution);

%% ------------------------------------------------------------------------
% Console output
% -------------------------------------------------------------------------

fprintf("\n============================================================\n");
fprintf(" Network figures created successfully\n");
fprintf("============================================================\n\n");

fprintf("Saved in:\n  %s\n\n", figureDir);

fprintf("1. Fig2.pdf/.png\n");
fprintf("2. Fig3.pdf/.png\n");
fprintf("3. Fig4.pdf/.png\n\n");

%% ========================================================================
% LOCAL FUNCTIONS
% ==========================================================================

function palette = get_colorblind_palette(K)
% GET_COLORBLIND_PALETTE
% Returns K rows of RGB in [0,1] drawn from the Okabe-Ito palette, which
% is distinguishable under the common forms of colour-vision deficiency
% and reproduces reasonably in greyscale print. Falls back to `lines`
% for K beyond the base palette (rare for community counts in practice).

    okabeIto = [
        0.00 0.45 0.70   % blue
        0.90 0.60 0.00   % orange
        0.00 0.60 0.50   % bluish green
        0.80 0.40 0.00   % vermillion-ish
        0.35 0.70 0.90   % sky blue
        0.94 0.89 0.26   % yellow
        0.80 0.60 0.70   % reddish purple
        0.00 0.00 0.00   % black
    ];

    if K <= size(okabeIto,1)
        palette = okabeIto(1:K, :);
    else
        palette = [okabeIto; lines(K - size(okabeIto,1))];
    end

end


function rgb = pastelize_color(rgb, whiteFraction)
% PASTELIZE_COLOR
% Blends a colour toward white by whiteFraction (0-1), used for node
% fills so the fully-saturated community colour stays reserved for
% edges -- matching the two-tone look (light node, saturated edge) of
% the reference figure while keeping the same underlying hue per
% community, so colour identity is still consistent between a node and
% the edges leaving it.

    rgb = rgb * (1 - whiteFraction) + [1 1 1] * whiteFraction;
    rgb = min(max(rgb, 0), 1);

end


function textColor = contrast_text_color(fillColor)
% CONTRAST_TEXT_COLOR
% Chooses near-black or white text based on the perceived luminance of
% fillColor (simple WCAG-style heuristic), so in-node labels stay
% legible regardless of which community colour a given node has.

    luminance = 0.299 * fillColor(1) + 0.587 * fillColor(2) + 0.114 * fillColor(3);

    if luminance > 0.6
        textColor = [0.10 0.10 0.10];
    else
        textColor = [1 1 1];
    end

end


function degree = compute_weighted_degree(A, W)
% COMPUTE_WEIGHTED_DEGREE
% Total weighted degree per node (sum of outgoing + incoming edge
% weights) for the network state given by A/W. A is accepted for
% signature symmetry with the rest of the script even though only W is
% needed once weights are already zero on absent edges.

    degree = sum(W, 2) + sum(W, 1)';

end


function [posX, posY] = compute_community_layout(community)
% COMPUTE_COMMUNITY_LAYOUT
% Fixed, deterministic, geography-free node layout: each community is
% placed at its own position around a large outer circle, and that
% community's member nodes are arranged evenly on a small circle around
% the community's centre.
%
% Inner-circle radius grows with community size (so member nodes never
% overlap however large a community is), and the outer-circle radius is
% chosen so that no two communities' inner circles can reach each other
% either -- by construction there is no crowded sub-region the way real
% geography could produce one, so no inset/zoom panel is needed.
%
% Purely a function of community membership, so it is computed once and
% reused for every panel/scenario in every figure, keeping node position
% comparable across panels exactly the way fixed lon/lat coordinates
% were reused before.

    N = numel(community);
    K = max(community);

    innerRadiusFor = @(m) max(36, 6.0 * m);

    communitySizes = accumarray(community, 1, [K, 1]);
    maxInnerRadius = innerRadiusFor(max(communitySizes));

    if K > 1
        minCenterSeparation = 2 * maxInnerRadius + 45; % larger buffer between communities
        outerRadius = max(165, minCenterSeparation / (2 * sin(pi / K)));
        communityAngles = linspace(0, 2*pi, K + 1);
        communityAngles(end) = [];
    else
        outerRadius = 0;
        communityAngles = 0;
    end

    posX = zeros(N, 1);
    posY = zeros(N, 1);

    for g = 1:K

        memberIdx = find(community == g);
        m = numel(memberIdx);

        cx = outerRadius * cos(communityAngles(g));
        cy = outerRadius * sin(communityAngles(g));

        if m == 1
            posX(memberIdx) = cx;
            posY(memberIdx) = cy;
            continue;
        end

        r = innerRadiusFor(m);
        memberAngles = linspace(0, 2*pi, m + 1);
        memberAngles(end) = [];

        posX(memberIdx) = cx + r * cos(memberAngles)';
        posY(memberIdx) = cy + r * sin(memberAngles)';

    end

end


function draw_weighted_network( ...
    ax, ...
    A, ...
    W, ...
    longitude, ...
    latitude, ...
    community, ...
    communityColors, ...
    regulatorMask, ...
    regulatorGroup, ...
    iso3, ...
    weightRef, ...
    labelAllNodes, ...
    showAxes, ...
    reciprocalCurvature, ...
    nodeArea, ...
    viewOverride, ...
    pubStyle)
% viewOverride is a struct with fields "axisLimits" ([xmin xmax ymin
% ymax] or [] for automatic full-extent limits) and "arrowHeadLen"
% (scalar or [] for automatic). Both default to automatic when an empty
% struct/fields are passed. This lets the same drawing logic be reused
% unchanged for a magnified inset of a crowded sub-region: the full
% A/W/longitude/latitude data is passed in as usual, but the axes only
% shows (and auto-scales arrowheads for) a restricted geographic window.

    cla(ax);
    hold(ax, "on");

    N = size(A,1);

    assert(size(A,2) == N, "A must be square.");
    assert(all(size(W) == size(A)), "A and W must have same size.");

    if isfield(viewOverride, "arrowHeadLen") && ~isempty(viewOverride.arrowHeadLen)
        arrowHeadLen = viewOverride.arrowHeadLen;
    else
        arrowHeadLen = compute_arrow_head_length(longitude, latitude);
    end

    degree = compute_weighted_degree(A, W);

    % ---------------------------------------------------------------
    % Directed weighted edges
    % ---------------------------------------------------------------
    %
    % Edge colour identifies the SOURCE node's community (full-saturation
    % community colour), matching the reference figure's convention.
    % Trade weight is still represented -- via each edge's percentile in
    % the shared reference distribution (weightRef.sorted) -- through
    % opacity and width, so weak/typical ties still fade toward the
    % background rather than competing equally with strong ones. Edges
    % are drawn weakest-first so the strongest (most opaque) ties are
    % never hidden underneath a stack of faint crossings.
    %
    % Line style is solid for ties within a community and dashed for
    % ties that cross between communities -- a common, readable
    % convention for separating "core" structure from "bridging" ties;
    % swap this rule out if your data has a more specific categorical
    % distinction (e.g. regulator vs non-regulator) you'd rather encode.

    [source, target] = find(A);

    edgeWeights = zeros(numel(source), 1);
    for e = 1:numel(source)
        edgeWeights(e) = W(source(e), target(e));
    end

    keep = edgeWeights > 0;
    source = source(keep);
    target = target(keep);
    edgeWeights = edgeWeights(keep);

    [edgeWeights, drawOrder] = sort(edgeWeights, "ascend");
    source = source(drawOrder);
    target = target(drawOrder);

    for e = 1:numel(source)

        i = source(e);
        j = target(e);
        weight = edgeWeights(e);

        pct = weight_to_percentile(weight, weightRef.sorted);

        width = 0.30 + 1.60 * pct;
        alphaVal = 0.10 + 0.80 * pct^1.4;
        edgeColor = communityColors(community(i), :);

        if community(i) == community(j)
            lineStyle = "-";
        else
            lineStyle = "--";
        end

        isReciprocal = A(j,i);
        if isReciprocal && i < j
            curvature = reciprocalCurvature;
        elseif isReciprocal && i > j
            curvature = -reciprocalCurvature;
        else
            curvature = 0;
        end

        draw_directed_edge( ...
            ax, ...
            longitude(i), latitude(i), ...
            longitude(j), latitude(j), ...
            edgeColor, ...
            width, ...
            curvature, ...
            arrowHeadLen, ...
            alphaVal, ...
            lineStyle);

    end

    % ---------------------------------------------------------------
    % Country nodes by community, with in-circle "ISO3 / weighted
    % degree" labels
    % ---------------------------------------------------------------

    K = size(communityColors,1);

    nodeFillFraction = 0.35; % how far node fill is blended toward white

    for g = 1:K

        mask = find(community == g);
        fillColor = pastelize_color(communityColors(g,:), nodeFillFraction);

        scatter( ...
            ax, ...
            longitude(mask), ...
            latitude(mask), ...
            nodeArea, ...
            repmat(fillColor, numel(mask), 1), ...
            "filled", ...
            "MarkerEdgeColor", "none");

        if labelAllNodes

            textColor = contrast_text_color(fillColor);

            if isfield(viewOverride, "labelMode")
                labelMode = string(viewOverride.labelMode);
            else
                labelMode = "full";
            end

            if labelMode == "iso"
                nodeFontSize = max(min(pubStyle.TickFontSize - 1.5, ...
                    4.8 * sqrt(nodeArea / 220)), 4.2);
            else
                nodeFontSize = max(min(pubStyle.TickFontSize - 2.5, ...
                    4.2 * sqrt(nodeArea / 260)), 3.8);
            end

            for q = 1:numel(mask)

                nodeIdx = mask(q);

                if labelMode == "iso"
                    labelStr = sprintf("%s", iso3(nodeIdx));
                else
                    labelStr = sprintf("%s\n%d", ...
                        iso3(nodeIdx), round(degree(nodeIdx)));
                end

                text( ...
                    ax, ...
                    longitude(nodeIdx), ...
                    latitude(nodeIdx), ...
                    labelStr, ...
                    "FontSize", nodeFontSize, ...
                    "FontName", pubStyle.FontName, ...
                    "FontWeight", "bold", ...
                    "Color", textColor, ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "middle", ...
                    "Interpreter", "none", ...
                    "Clipping", "on");

            end

        end

    end

    % ---------------------------------------------------------------
    % Regulator nodes
    % ---------------------------------------------------------------

    regulatorIdx = find(regulatorMask);

    if ~isempty(regulatorIdx)

        % Regulating importers are identified by group labels only.
        % No additional square outline is drawn around regulator nodes.

        % Label once per unique regulator group (e.g. "EU"), not once per
        % member country -- individually labelling every member of a
        % tightly-clustered bloc stacks the labels directly on top of
        % each other and becomes unreadable. Each label is placed just
        % outside the centroid of its group's node positions.
        regulatorLabels = regulatorGroup(regulatorIdx);
        noGroup = strlength(regulatorLabels) == 0;
        regulatorLabels(noGroup) = iso3(regulatorIdx(noGroup));

        [uniqueLabels, ~, memberOf] = unique(regulatorLabels);

        for g = 1:numel(uniqueLabels)

            members = regulatorIdx(memberOf == g);
            cx = mean(longitude(members));
            cy = mean(latitude(members));

            text( ...
                ax, ...
                cx + 4, ...
                cy + 4, ...
                uniqueLabels(g), ...
                "FontSize", pubStyle.TickFontSize, ...
                "FontName", pubStyle.FontName, ...
                "FontWeight", "bold", ...
                "Color", pubStyle.TextColor, ...
                "Interpreter", "none", ...
                "Clipping", "on");

        end

    end

    if isfield(viewOverride, "axisLimits") && ~isempty(viewOverride.axisLimits)
        axisLimitsOverride = viewOverride.axisLimits;
    else
        axisLimitsOverride = [];
    end

    format_network_axes(ax, longitude, latitude, showAxes, pubStyle, axisLimitsOverride);

    hold(ax, "off");

end


function draw_rewiring_network( ...
    ax, ...
    A_baseline, ...
    A_policy, ...
    longitude, ...
    latitude, ...
    community, ...
    communityColors, ...
    regulatorMask, ...
    regulatorGroup, ...
    iso3, ...
    pubStyle)

    cla(ax);
    hold(ax, "on");

    arrowHeadLen = compute_arrow_head_length(longitude, latitude);

    common = A_baseline & A_policy;
    added = A_policy & ~A_baseline;
    removed = A_baseline & ~A_policy;

    % Common relationships: light background, undirected style (no
    % arrowhead) so they read as "background structure" rather than
    % competing for attention with the policy-driven changes.
    draw_binary_edge_set( ...
        ax, common, longitude, latitude, ...
        [0.82 0.82 0.82], 0.45, "-", 0, false);

    % Removed baseline relationships: dashed red.
    draw_binary_edge_set( ...
        ax, removed, longitude, latitude, ...
        [0.75 0.20 0.20], 1.15, "--", 0, true);

    % New policy relationships: solid blue.
    draw_binary_edge_set( ...
        ax, added, longitude, latitude, ...
        [0.10 0.35 0.70], 1.35, "-", arrowHeadLen, true);

    % Country nodes.
    K = size(communityColors,1);

    for g = 1:K

        mask = community == g;

        scatter( ...
            ax, ...
            longitude(mask), ...
            latitude(mask), ...
            38, ...
            repmat(communityColors(g,:), nnz(mask), 1), ...
            "filled", ...
            "MarkerEdgeColor", "none");

    end

    % Regulator outlines and labels.
    regulatorIdx = find(regulatorMask);

    if ~isempty(regulatorIdx)

        % Regulating importers are identified by group labels only.
        % No additional square outline is drawn around regulator nodes.

        % One label per unique regulator group, at that group's
        % centroid -- see the matching comment in draw_weighted_network.
        regulatorLabels = regulatorGroup(regulatorIdx);
        noGroup = strlength(regulatorLabels) == 0;
        regulatorLabels(noGroup) = iso3(regulatorIdx(noGroup));

        [uniqueLabels, ~, memberOf] = unique(regulatorLabels);

        for g = 1:numel(uniqueLabels)

            members = regulatorIdx(memberOf == g);
            cx = mean(longitude(members));
            cy = mean(latitude(members));

            text( ...
                ax, ...
                cx + 2.5, ...
                cy + 2.5, ...
                uniqueLabels(g), ...
                "FontSize", pubStyle.TickFontSize - 0.5, ...
                "FontName", pubStyle.FontName, ...
                "FontWeight", "bold", ...
                "Color", pubStyle.TextColor, ...
                "Interpreter", "none", ...
                "Clipping", "on");

        end

    end

    format_network_axes(ax, longitude, latitude, false, pubStyle);

    % Legend built from dummy lines (kept per-panel here since each panel
    % shows a distinct added/removed/common comparison).
    hCommon = plot(ax, nan, nan, "-", ...
        "Color", [0.82 0.82 0.82], "LineWidth", 1.0);
    hAdded = plot(ax, nan, nan, "-", ...
        "Color", [0.10 0.35 0.70], "LineWidth", 1.5);
    hRemoved = plot(ax, nan, nan, "--", ...
        "Color", [0.75 0.20 0.20], "LineWidth", 1.5);

    legend( ...
        ax, ...
        [hCommon hAdded hRemoved], ...
        ["Common", "Added under policy", "Removed under policy"], ...
        "Location", "southoutside", ...
        "FontSize", pubStyle.LegendFontSize, ...
        "FontName", pubStyle.FontName, ...
        "TextColor", pubStyle.TextColor, ...
        "Box", "off");

    hold(ax, "off");

end


function draw_binary_edge_set( ...
    ax, edgeMask, longitude, latitude, edgeColor, lineWidth, lineStyle, ...
    arrowHeadLen, drawArrow)

    [source, target] = find(edgeMask);

    for e = 1:numel(source)

        i = source(e);
        j = target(e);

        if lineStyle == "--"

            plot( ...
                ax, ...
                [longitude(i), longitude(j)], ...
                [latitude(i), latitude(j)], ...
                lineStyle, ...
                "Color", edgeColor, ...
                "LineWidth", lineWidth);

        else

            draw_directed_edge( ...
                ax, ...
                longitude(i), latitude(i), ...
                longitude(j), latitude(j), ...
                edgeColor, lineWidth, 0, ...
                arrowHeadLen * double(drawArrow), 0.55);

        end

    end

end


function draw_directed_edge( ...
    ax, x1, y1, x2, y2, color, lineWidth, curvature, arrowHeadLen, alphaVal, lineStyle)
% DRAW_DIRECTED_EDGE
% Draws a straight or quadratically-curved directed edge from (x1,y1) to
% (x2,y2) with a fixed-size arrowhead (independent of edge length), so
% that reciprocal (bidirectional) pairs can be shown as two visually
% separated arcs instead of overlapping straight lines. lineStyle
% ("-" or "--") is optional and defaults to solid.
%
% alphaVal (0-1) is rendered by blending `color` toward white rather
% than via true alpha transparency. True per-object alpha on line/patch
% objects (via the undocumented Color(4)/FaceAlpha route) forces
% exportgraphics's vector PDF path to composite large numbers of
% overlapping semi-transparent shapes, which for a network with more
% than a couple hundred edges can be extremely slow or destabilize the
% figure entirely (manifesting as "vectorized content might take a long
% time" warnings, or exportgraphics later failing with "Input was not a
% valid graphics object" on a subsequent figure). Blending to an opaque
% colour instead produces the same faded visual effect with ordinary,
% cheap-to-render vector paths.

    if nargin < 11 || strlength(string(lineStyle)) == 0
        lineStyle = "-";
    end

    % Background this blends toward -- matches pubStyle.BackgroundColor,
    % which every axes in this script is forced to (see format_network_axes).
    backgroundColor = [1 1 1];
    alphaVal = min(max(alphaVal, 0), 1);
    displayColor = color * alphaVal + backgroundColor * (1 - alphaVal);

    dx = x2 - x1;
    dy = y2 - y1;
    edgeLen = hypot(dx, dy);

    if edgeLen == 0
        return;
    end

    if curvature == 0

        xs = [x1, x2];
        ys = [y1, y2];

    else

        % Perpendicular offset at the midpoint, quadratic Bezier curve.
        mx = (x1 + x2) / 2;
        my = (y1 + y2) / 2;

        perpX = -dy / edgeLen;
        perpY =  dx / edgeLen;

        offset = curvature * edgeLen;

        cx = mx + perpX * offset;
        cy = my + perpY * offset;

        t = linspace(0, 1, 24);
        xs = (1 - t).^2 * x1 + 2 * (1 - t) .* t * cx + t.^2 * x2;
        ys = (1 - t).^2 * y1 + 2 * (1 - t) .* t * cy + t.^2 * y2;

    end

    % Shorten the tail end slightly so the line does not sit exactly on
    % the arrowhead / target node marker.
    if arrowHeadLen > 0
        shrink = min(0.5, arrowHeadLen / edgeLen);
        keep = round(numel(xs) * (1 - shrink));
        keep = max(keep, 2);
        xs = xs(1:keep);
        ys = ys(1:keep);
    end

    plot(ax, xs, ys, lineStyle, "Color", displayColor, "LineWidth", lineWidth);

    if arrowHeadLen > 0 && numel(xs) >= 2

        tanX = x2 - xs(end);
        tanY = y2 - ys(end);
        tanLen = hypot(tanX, tanY);
        if tanLen == 0
            tanX = dx; tanY = dy; tanLen = edgeLen;
        end
        tanX = tanX / tanLen;
        tanY = tanY / tanLen;

        perpX = -tanY;
        perpY =  tanX;

        halfWidth = arrowHeadLen * 0.45;

        baseX = x2 - tanX * arrowHeadLen;
        baseY = y2 - tanY * arrowHeadLen;

        triX = [x2, baseX + perpX * halfWidth, baseX - perpX * halfWidth];
        triY = [y2, baseY + perpY * halfWidth, baseY - perpY * halfWidth];

        patch(ax, triX, triY, displayColor, "EdgeColor", "none");

    end

end


function pct = weight_to_percentile(weight, sortedRefWeights)
% WEIGHT_TO_PERCENTILE
% Empirical-CDF lookup: where does `weight` fall within the reference
% distribution of nonzero weights, as a value in [0,1]? Percentile-based
% scaling spreads visual contrast evenly across the data instead of
% letting a handful of very large weights compress everything else
% toward the same (nearly invisible) end of a linear scale.
%
% Implemented by counting rather than interp1(), because trade-weight
% distributions commonly contain ties (repeated identical values), and
% interp1() requires strictly unique sample points.

    n = numel(sortedRefWeights);

    if n == 0
        pct = 0;
        return;
    end

    if n == 1
        pct = double(weight >= sortedRefWeights(1));
        return;
    end

    countLE = sum(sortedRefWeights <= weight);
    countLT = sum(sortedRefWeights < weight);

    % Average rank across tied values (midpoint of the tie block),
    % 1-indexed, then normalized to [0,1].
    midRank = (countLT + countLE + 1) / 2;
    pct = (midRank - 1) / (n - 1);

    pct = min(max(pct, 0), 1);

end


function rgb = sample_colormap(cmap, pct)
% SAMPLE_COLORMAP
% Linearly interpolated lookup into an Nx3 colormap at position pct in
% [0,1]. Using interpolation (rather than a rounded index) keeps colour
% transitions smooth even for a coarse reference colormap.

    pct = min(max(pct, 0), 1);
    n = size(cmap, 1);

    idx = 1 + pct * (n - 1);
    idxLow = floor(idx);
    idxHigh = ceil(idx);
    frac = idx - idxLow;

    idxLow = max(idxLow, 1);
    idxHigh = min(idxHigh, n);

    rgb = (1 - frac) * cmap(idxLow, :) + frac * cmap(idxHigh, :);

end


function headLen = compute_arrow_head_length(longitude, latitude)
% Fixed arrowhead size, expressed in data units, scaled to ~1.6% of the
% plotted coordinate range so it stays visually consistent regardless of
% individual edge length or panel count.

    xRange = max(longitude) - min(longitude);
    yRange = max(latitude) - min(latitude);
    diag = hypot(xRange, yRange);

    headLen = 0.016 * diag;

end


function draw_side_panel( ...
    axPanel, communityColors, communityLabels, hasRegulators, ...
    weightRef, pubStyle)
% DRAW_SIDE_PANEL
% Self-contained legend panel combining the community colour key, the
% regulator marker key, and the edge-style key, drawn entirely with
% text/plot/scatter on a dedicated axes (no legend() object involved).
% This is deliberately low-tech: legend() objects built from dummy
% series can be invalidated by axes state elsewhere in the figure (e.g.
% hold toggling, tiledlayout re-flowing), which is fragile in
% batch/headless runs. Plain graphics primitives on a private axes are
% not.
%
% Community swatches are shown as the same pastel-filled circle used
% for nodes. Edges take their colour from the source node's community
% (full saturation), are solid for within-community ties and dashed for
% cross-community ties, and fade toward transparent for lower-weight
% ties -- illustrated below with one representative colour rather than
% the full per-community palette, since opacity/width (not hue)
% is what encodes weight now.

    cla(axPanel);
    hold(axPanel, "on");
    axis(axPanel, "off");
    axPanel.Color = pubStyle.BackgroundColor;

    xSwatch = 2;
    xText = 6;
    xMax = 34;

    y = 100;
    lineStep = 8;

    text(axPanel, 0, y, "Community", ...
        "FontWeight", "bold", "FontName", pubStyle.FontName, ...
        "FontSize", pubStyle.LegendFontSize, "Interpreter", "none");
    y = y - lineStep;

    K = size(communityColors, 1);
    for g = 1:K
        fillColor = pastelize_color(communityColors(g,:), 0.35);
        scatter(axPanel, xSwatch, y, 90, fillColor, ...
            "filled", "MarkerEdgeColor", [0.25 0.25 0.25], "LineWidth", 0.6);
        text(axPanel, xText, y, communityLabels(g), ...
            "FontName", pubStyle.FontName, ...
            "FontSize", pubStyle.LegendFontSize, ...
            "VerticalAlignment", "middle", "Interpreter", "none");
        y = y - lineStep;
    end

    if hasRegulators
        y = y - 0.4 * lineStep;
        scatter(axPanel, xSwatch, y, 90, "s", ...
            "MarkerFaceColor", "none", "MarkerEdgeColor", [0 0 0], ...
            "LineWidth", 1.6);
        text(axPanel, xText, y, "Regulator", ...
            "FontName", pubStyle.FontName, ...
            "FontSize", pubStyle.LegendFontSize, ...
            "VerticalAlignment", "middle", "Interpreter", "none");
        y = y - lineStep;
    end

    y = y - 0.6 * lineStep;

    % --- Edge colour / line-style key ---------------------------------

    text(axPanel, 0, y, "Edge ties", ...
        "FontWeight", "bold", "FontName", pubStyle.FontName, ...
        "FontSize", pubStyle.LegendFontSize, "Interpreter", "none");
    y = y - lineStep;

    text(axPanel, 0, y, "(colour = source community)", ...
        "FontName", pubStyle.FontName, ...
        "FontSize", max(pubStyle.LegendFontSize - 1.5, 6), ...
        "Interpreter", "none");
    y = y - 0.9 * lineStep;

    exampleColor = communityColors(1, :);

    plot(axPanel, [0 5], [y y], "-", "Color", exampleColor, "LineWidth", 1.4);
    text(axPanel, xText, y, "Within-community tie", ...
        "FontName", pubStyle.FontName, "FontSize", pubStyle.LegendFontSize, ...
        "VerticalAlignment", "middle", "Interpreter", "none");
    y = y - lineStep;

    plot(axPanel, [0 5], [y y], "--", "Color", exampleColor, "LineWidth", 1.4);
    text(axPanel, xText, y, "Cross-community tie", ...
        "FontName", pubStyle.FontName, "FontSize", pubStyle.LegendFontSize, ...
        "VerticalAlignment", "middle", "Interpreter", "none");
    y = y - lineStep;

    y = y - 0.4 * lineStep;

    % --- Trade-weight (opacity/width) key ------------------------------

    sortedWeights = weightRef.sorted(:);
    sortedWeights = sortedWeights(sortedWeights > 0);
    sortedWeights = sort(sortedWeights, "ascend");

    if ~isempty(sortedWeights)

        text(axPanel, 0, y, "Edge weight", ...
            "FontWeight", "bold", "FontName", pubStyle.FontName, ...
            "FontSize", pubStyle.LegendFontSize, "Interpreter", "none");
        y = y - lineStep;

        text(axPanel, 0, y, "(opacity + width = percentile)", ...
            "FontName", pubStyle.FontName, ...
            "FontSize", max(pubStyle.LegendFontSize - 1.5, 6), ...
            "Interpreter", "none");
        y = y - 0.9 * lineStep;

        n = numel(sortedWeights);
        refPercentiles = [0.10 0.50 0.90 0.99];

        for k = 1:numel(refPercentiles)

            pct = refPercentiles(k);

            if n == 1
                wVal = sortedWeights(1);
            else
                wVal = interp1(linspace(0, 1, n), sortedWeights, pct, ...
                    "linear", "extrap");
            end

            width = 0.30 + 1.60 * pct;
            alphaVal = 0.10 + 0.80 * pct^1.4;

            % Same white-blend approach as draw_directed_edge, for
            % consistency and to avoid the undocumented Color(4) alpha
            % trick (see that function's comment for why).
            swatchColor = exampleColor * alphaVal + [1 1 1] * (1 - alphaVal);

            plot(axPanel, [0 5], [y y], "-", ...
                "Color", swatchColor, "LineWidth", width);

            text(axPanel, xText, y, ...
                sprintf("p%d \x2248 %.3g", round(pct * 100), wVal), ...
                "FontName", pubStyle.FontName, ...
                "FontSize", pubStyle.LegendFontSize, ...
                "VerticalAlignment", "middle", "Interpreter", "none");

            y = y - lineStep;

        end

    end

    xlim(axPanel, [-1 xMax]);
    ylim(axPanel, [max(y, 0) 108]);

    hold(axPanel, "off");

end


function add_panel_label(ax, label, pubStyle)
% Adds a conventional journal-style panel label: (a), (b), (c), ...

    text(ax, 0.02, 0.965, "(" + lower(label) + ")", ...
        "Units", "normalized", ...
        "FontName", pubStyle.FontName, ...
        "FontSize", pubStyle.PanelLabelSize, ...
        "FontWeight", "bold", ...
        "Color", pubStyle.TextColor, ...
        "Interpreter", "none", ...
        "VerticalAlignment", "top", ...
        "HorizontalAlignment", "left");

end


function format_network_axes(ax, longitude, latitude, showAxes, pubStyle, axisLimitsOverride)
% axisLimitsOverride: [xmin xmax ymin ymax], or [] for the default
% automatic full-extent (padded) limits.

    if nargin < 6
        axisLimitsOverride = [];
    end

    % Force a light, print-safe appearance on this axes regardless of
    % any MATLAB UI dark-theme default (see the groot defaults set near
    % the top of the script for the figure-wide equivalent).
    ax.Color = pubStyle.BackgroundColor;
    ax.XColor = pubStyle.TextColor;
    ax.YColor = pubStyle.TextColor;
    ax.GridColor = pubStyle.TextColor;

    if ~isempty(axisLimitsOverride)

        xlim(ax, axisLimitsOverride(1:2));
        ylim(ax, axisLimitsOverride(3:4));

    else

        xRange = max(longitude) - min(longitude);
        yRange = max(latitude) - min(latitude);

        xPad = max(10, 0.05 * xRange);
        yPad = max(5, 0.08 * yRange);

        xlim(ax, [min(longitude)-xPad, max(longitude)+xPad]);
        ylim(ax, [min(latitude)-yPad, max(latitude)+yPad]);

    end

    axis(ax, "equal");

    % showAxes is false by default now that node position is a synthetic
    % community layout rather than real geography (see
    % compute_community_layout), so this coordinate grid is normally
    % unreachable. Left in place, with generic axis labels, in case
    % showAxes is re-enabled for layout debugging.
    if showAxes

        xlabel(ax, "X", "FontSize", pubStyle.LabelFontSize, ...
            "FontName", pubStyle.FontName, "Color", pubStyle.TextColor);
        ylabel(ax, "Y", "FontSize", pubStyle.LabelFontSize, ...
            "FontName", pubStyle.FontName, "Color", pubStyle.TextColor);

        grid(ax, "on");
        ax.GridAlpha = 0.10;
        ax.MinorGridAlpha = 0.05;

    else

        axis(ax, "off");

    end

    ax.Box = "on";
    ax.FontSize = pubStyle.TickFontSize;
    ax.FontName = pubStyle.FontName;
    ax.Layer = "top";

end



function export_figure_pair(fig, outputDir, baseName, pngResolution)
% EXPORT_FIGURE_PAIR
% Dense network figures can make MATLAB's vector renderer unstable in
% headless/batch mode. Export them directly as high-resolution raster
% graphics instead. This avoids the "Vectorized content might take a long
% time" / invalid graphics-handle failure.
%
% The PNG is the preferred submission artwork. A rasterized PDF copy is
% also produced for direct inclusion in LaTeX/Overleaf.

    assert(isgraphics(fig, "figure"), ...
        "export_figure_pair: figure handle for '%s' is invalid or was " + ...
        "closed before export.", baseName);

    drawnow;

    pdfFile = fullfile(outputDir, baseName + ".pdf");
    pngFile = fullfile(outputDir, baseName + ".png");

    % Export PNG FIRST. Do not invoke the vector renderer for these dense
    % network figures, because it can invalidate the figure during batch
    % execution before the raster export is attempted.
    exportgraphics( ...
        fig, ...
        pngFile, ...
        "ContentType", "image", ...
        "Resolution", pngResolution, ...
        "BackgroundColor", "white");

    assert(isgraphics(fig, "figure"), ...
        "Figure '%s' became invalid after PNG export.", baseName);

    % Rasterized PDF at the same resolution for manuscript use.
    exportgraphics( ...
        fig, ...
        pdfFile, ...
        "ContentType", "image", ...
        "Resolution", pngResolution, ...
        "BackgroundColor", "white");

end


function values = to_string_vector(raw, expectedLength)
% TO_STRING_VECTOR
% Robustly converts common MATLAB table/string/cell/categorical forms
% loaded from the saved MAT file into an N-by-1 string vector.

    if isstring(raw)

        values = raw(:);

    elseif iscell(raw)

        values = string(raw(:));

    elseif iscategorical(raw)

        values = string(raw(:));

    elseif ischar(raw)

        if size(raw,1) == expectedLength
            values = string(cellstr(raw));
        else
            values = string(raw(:));
        end

    else

        values = string(raw(:));

    end

    if numel(values) ~= expectedLength
        error( ...
            "Metadata vector has %d entries but expected %d.", ...
            numel(values), ...
            expectedLength);
    end

end