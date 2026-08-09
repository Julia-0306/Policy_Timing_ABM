# Adaptive Trade Network Model for Environmental Policy Sequencing

This repository contains the MATLAB implementation used for the
agent-based trade-network simulations. 

The model is a **stylised, mechanism-based adaptive trade-network
model**, not a forecast of observed bilateral trade. Countries are
represented as exporters/importers in four commodity layers. Exporters
evaluate existing and potential partners, may replace existing
relationships after regulatory shocks, and rebuild trade volume through
surviving replacement relationships over time.

The repository contains the benchmark simulation and the
robustness/falsification exercises reported in the paper.

------------------------------------------------------------------------

## 1. Reproducing the analysis

Run all commands from the **repository root**.

### Benchmark model

From a terminal with MATLAB available on the system path:

``` bash
matlab -batch "run('main.m')"
```

This is the main entry point for the benchmark model. It runs all five
policy scenarios using the same model logic and benchmark parameters.

The five scenarios are:

1.  **Baseline:** no regulation.
2.  **Early mover:** EU regulates from (t=6).
3.  **Sequential:** EU at (t=6), UK at (t=10), US at (t=14).
4.  **Coordinated:** EU, UK, and US regulate simultaneously at (t=6).
5.  **Delayed coordination:** EU at (t=6), UK and US jointly at (t=12).

One model period corresponds to **one year**. The benchmark simulation
horizon is (T=20).

### Robustness and falsification tests

All final robustness scripts are stored in:

``` text
robustness/
```

To reproduce **every robustness/falsification exercise in that
directory**, run:

``` bash
for f in robustness/*.m; do
    echo "Running $f"
    matlab -batch "run('$f')"
done
```

This is the recommended command for reviewers because it automatically
executes the complete set of robustness scripts contained in the
submitted repository without requiring filenames to be entered manually.

The robustness folder contains the exercises reported in the paper:

-   initial-network × recovery-horizon robustness;
-   regulatory-penalty sensitivity;
-   switching-cost sensitivity;
-   choice-sensitivity robustness;
-   deforestation-intensity permutation placebo/falsification test.

The initial-network × recovery-horizon experiment uses **100
independently initialized networks**, three recovery horizons
(H`\in`{=tex}{3,5,7}), and five policy scenarios, for a total of **1,500
simulations**. Within each replication, common random numbers are used
for paired scenario comparisons.

> **Runtime note:** the robustness scripts contain substantially more
> simulations than `main.m` and therefore take longer to execute.

------------------------------------------------------------------------

## 2. Repository structure

The expected structure is:

``` text
project_root/
│
├── README.md
├── main.m
│
├── data/
│   ├── countries.csv
│   ├── regulators.csv
│   ├── distance_matrix.csv
│   ├── deforestation_intensity_v2.csv
│   └── deforestation_intensity_metadata_v2.csv
│
├── src/
│   ├── load_model_data.m
│   ├── initialize_network.m
│   ├── partner_score.m
│   ├── relationship_value.m
│   ├── stay_switch_decision.m
│   ├── select_adjustment_mode.m
│   ├── select_partner.m
│   ├── update_network.m
│   ├── compute_outcomes.m
│   └── run_model.m
│
├── scenarios/
│   ├── baseline.m
│   ├── early_mover.m
│   ├── sequential.m
│   ├── coordinated.m
│   └── delayed_coordination.m
│
├── robustness/
│   └── *.m
│
└── results/
    └── ...
```

Do **not** move the scripts out of this structure. The MATLAB files
construct paths relative to the repository root.

------------------------------------------------------------------------

## 3. Model inputs

The `data/` directory contains the empirical and semi-empirical inputs
used by the model.

-   `countries.csv` --- country definitions used by the simulation.
-   `regulators.csv` --- identifies the EU, UK, and US regulatory nodes.
-   `distance_matrix.csv` --- bilateral geographic-distance information
    used in partner scoring.
-   `deforestation_intensity_v2.csv` --- exporter- and
    commodity-specific environmental-risk intensities.
-   `deforestation_intensity_metadata_v2.csv` --- metadata documenting
    the environmental calibration.

The environmental calibration uses Trase information for palm oil and
soy and FAOSTAT information for timber and paper. Raw environmental
measures are normalized within commodity layers to (\[0,1\]). They
should therefore be interpreted as **relative deforestation-risk
intensities**, not predicted hectares of deforestation.

------------------------------------------------------------------------

## 4. Benchmark model specification

The benchmark model uses:

``` text
T     = 20 years
p     = 0.50
e_L   = 0.10
e_G   = 0.20
beta  = 4
H     = 5 years
```

where:

-   `p` is the regulatory penalty;
-   `e_L` is the local switching cost;
-   `e_G` is the global switching cost, with (e_G\>e_L);
-   `beta` is the softmax choice-sensitivity parameter;
-   `H` is the trade-volume recovery horizon.

The final model does **not** use an `eta` adjustment-speed parameter.
Trade-volume adjustment is represented explicitly through relationship
age and the recovery horizon (H).

------------------------------------------------------------------------

## 5. Core model logic

For every commodity layer and period, exporters evaluate their current
and feasible alternative trading relationships.

The current-partner score is based on:

-   same-community membership;
-   normalized geographic distance;
-   realised trade importance;
-   regulatory exposure.

Potential partners are evaluated using the corresponding expected market
potential.

After comparing the current relationship with feasible alternatives, the
exporter either:

-   **stays** with the current importer; or
-   **switches** and replaces the relationship one-for-one.

If switching occurs, the model distinguishes between local and global
adjustment. Global adjustment is more costly than switching within the
existing trade community.

The selected replacement partner is drawn using a softmax choice rule.
Higher-scoring candidates therefore have a higher probability of being
selected, while `beta` determines how concentrated that choice is.

Each removed relationship is replaced **one-for-one**. The model does
not permanently drop the link without replacement.

------------------------------------------------------------------------

## 6. Trade-volume recovery

A replacement relationship does not immediately inherit the full volume
of the relationship it replaces.

Its initial volume is

\[ W^{c,0}*{ik}\ =\ W\^{c,t}*{ij}`\widehat{w}`{=tex}^{c,t}\_{ik}. \]

Conditional on survival, the relationship subsequently recovers
linearly:

\[ W\^c\_{ik}(a) =
W^{c,0}*{ik}\ +\ `\min`{=tex}`\left`{=tex}(`\frac{a}{H}`{=tex},1`\right`{=tex})\ `\left`{=tex}(\ W\^{c,t}*{ij}-W^{c,0}\_{ik}
`\right`{=tex}), \]

where:

-   \(a\) is the age of the replacement relationship in years;
-   \(H\) is the recovery horizon;
-   (W\^{c,t}\_{ij}) is the volume of the replaced relationship;
-   (`\widehat{w}`{=tex}\^{c,t}\_{ik}) is the market potential of the
    new partner.

The benchmark uses (H=5). The robustness analysis also evaluates (H=3)
and (H=7).

This mechanism is important for policy sequencing because trade can
rebuild during the years between regulatory shocks.

------------------------------------------------------------------------

## 7. Environmental outcome

Environmental risk is calculated as

\[ r\^{c,t}*{ij} = W\^{c,t}*{ij}`\delta`{=tex}\_{ic}, \]

with total embodied deforestation-risk exposure

\[ R_t = `\sum`{=tex}*{c,i,j} r\^{c,t}*{ij}. \]

Here, (`\delta`{=tex}\_{ic}) belongs to the **exporter--commodity
pair**, not the importing destination.

Consequently, redirecting the same volume from importer (j) to importer
(k) does not mechanically make the trade flow environmentally cleaner.
Changes in total risk can arise through changes in realised trade volume
and through changes in the composition of trade across
exporter--commodity pairs.

------------------------------------------------------------------------

## 8. Reproducibility

The benchmark model uses a fixed MATLAB random seed so that
synthetic-network initialization and stochastic partner selection are
reproducible.

The Monte Carlo robustness exercises use explicitly defined replication
seeds. Within a replication, scenarios are compared using the same
initialized network and common random numbers wherever required. This
permits paired comparisons across policy scenarios rather than
comparisons between unrelated stochastic realizations.

Reviewers should **not change random seeds, parameter values, scenario
definitions, or input files** when reproducing the reported results.

------------------------------------------------------------------------

## 9. Outputs

Scripts create their output directories automatically under:

``` text
results/
```

The benchmark run writes the full MATLAB simulation output and a compact
scenario summary. The main benchmark outputs include:

``` text
results/chapter2_results.mat
results/scenario_summary.csv
```

Robustness scripts write their outputs below:

``` text
results/robustness/
```

For example, the initial-network × recovery-horizon experiment stores
its results in the `networks_recovery` subdirectory and includes the
complete simulation output, aggregate summaries, paired scenario
differences, and lowest-risk scenario frequencies.

The `.mat` files retain the complete simulation objects required for
subsequent inspection, while `.csv` outputs provide compact tabular
summaries where generated by the corresponding script.

------------------------------------------------------------------------

## 10. Recommended reviewer workflow

For a minimal reproduction of the benchmark results:

``` bash
git clone <REPOSITORY-URL>
cd <REPOSITORY-NAME>
matlab -batch "run('main.m')"
```

Inspect:

``` text
results/scenario_summary.csv
```

For the complete computational reproduction, subsequently run:

``` bash
for f in robustness/*.m; do
    echo "Running $f"
    matlab -batch "run('$f')"
done
```

Then inspect the outputs under:

``` text
results/robustness/
```

A clean reproduction can be performed by deleting the generated
`results/` directory before running the scripts again. The scripts
recreate the required output directories.

------------------------------------------------------------------------

## 11. Interpretation and scope

The simulation should be interpreted as a **mechanism-based policy
experiment**.

The network topology and trade communities are stylised. Geography,
regulator identities, and environmental-risk intensities introduce
empirical information, but the model is not intended to reproduce or
forecast the observed global trade network.

The purpose of the model is to isolate how:

1.  importer-side environmental regulation changes partner incentives;
2.  exporters adapt their trading relationships;
3.  replacement relationships rebuild trade volume over time; and
4.  the timing of successive regulatory interventions changes the
    network state encountered by later shocks.

Accordingly, the central comparison concerns the **transition dynamics
generated by alternative policy timings**, rather than point forecasts
of country-level trade.

------------------------------------------------------------------------

## 12. Troubleshooting

### MATLAB cannot find a function

Make sure MATLAB is launched from the repository root and that the
directory structure above has not been changed.

Use:

``` bash
pwd
ls
```

and verify that `main.m`, `src/`, `scenarios/`, `data/`, and
`robustness/` are present.

### Input file not found

Verify that all files in `data/` are present and retain their repository
filenames.

### Robustness script takes a long time

This is expected. Several robustness exercises repeat all five scenarios
across 100 network realizations and multiple parameter values.

### Reproduced values differ from the paper

First verify that:

-   no model parameters were edited;
-   no input data files were changed;
-   the random-seed logic remains unchanged;
-   all scripts are being run from the repository version associated
    with the paper.

------------------------------------------------------------------------

## Citation

If you use this code, please cite the accompanying paper.

**Paper citation:** to be added upon publication.
