# Adaptive Trade Network Model for Environmental Policy Timing

This repository contains the MATLAB implementation of the agent-based model used in the accompanying paper.

The model is a **stylised, mechanism-based adaptive trade-network model**, not a forecast of observed bilateral trade. It examines how alternative timings of importer-side environmental regulation affect trade-network adaptation and embodied deforestation-risk exposure.

## 1. Requirements

The model is implemented in MATLAB.

Run all commands from the repository root.

## 2. Repository structure

```text
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
├── figures/
│   └── create_network_figures.m
│
└── results/
```

Do not change this directory structure because the MATLAB scripts construct paths relative to the repository root.

## 3. Reproducing the benchmark model

Run:

```bash
matlab -batch "run('main.m')"
```

The benchmark simulation compares five policy scenarios:

1. **Baseline:** no regulation.
2. **Early mover:** EU regulates from \(t=6\).
3. **Sequential:** EU at \(t=6\), UK at \(t=10\), US at \(t=14\).
4. **Coordinated:** EU, UK, and US regulate simultaneously at \(t=6\).
5. **Delayed coordination:** EU at \(t=6\), UK and US at \(t=12\).

One model period corresponds to one year and the simulation horizon is \(T=20\).

The main outputs are:

```text
results/chapter2_results.mat
results/scenario_summary.csv
```

## 4. Benchmark specification

The benchmark parameters are:

```text
T     = 20
p     = 0.50
e_L   = 0.10
e_G   = 0.20
beta  = 4
H     = 5
```

where \(p\) is the regulatory penalty, \(e_L\) and \(e_G\) are local and global switching costs, \(\beta\) controls softmax choice sensitivity, and \(H\) is the trade-volume recovery horizon.

The final model does not use an `eta` adjustment-speed parameter.

### Initial network

The model contains 30 countries and four commodity layers: palm oil, soy, timber, and paper. All countries participate in all four layers.

At \(t=1\), each exporter is assigned five partners per commodity layer, drawn randomly without replacement from all other countries. Initial trade weights are drawn uniformly from \([2,8]\).

Community membership and geographic distance do **not** determine the initial topology. They enter only during subsequent partner evaluation and network adaptation.

The EU, UK, and US are each guaranteed at least eight incoming links per commodity layer at \(t=1\). Where necessary, links are reassigned one-for-one, preserving exporter out-degree and initial total trade volume.

Initial relationships are treated as established relationships and do not begin in recovery.

## 5. Model logic

In each period, exporters evaluate existing and potential trading relationships according to:

- community membership;
- geographic distance;
- trade importance or expected market potential;
- regulatory exposure.

Exporters either retain an existing relationship or replace it one-for-one. Switching can occur locally or globally, with global switching carrying a higher cost. Replacement partners are selected using a softmax choice rule.

New replacement relationships initially carry only part of the displaced trade volume. Conditional on survival, they recover linearly toward the pre-switch volume over \(H\) years.

Environmental risk is calculated from realised trade volume and exporter–commodity-specific deforestation-risk intensity:

\[
r^{c,t}_{ij}=W^{c,t}_{ij}\delta_{ic},
\]

with aggregate exposure

\[
R_t=\sum_{c,i,j}r^{c,t}_{ij}.
\]

Deforestation intensities are normalized to \([0,1]\) within commodity layers and should be interpreted as **relative deforestation-risk exposure**, not hectares of deforestation.

## 6. Robustness and falsification tests

All robustness scripts are stored in:

```text
robustness/
```

They cover:

- 100 initial-network realisations and recovery horizons \(H\in\{3,5,7\}\);
- regulatory-penalty sensitivity;
- switching-cost sensitivity;
- choice-sensitivity robustness;
- deforestation-intensity permutation placebo/falsification.

To run all robustness exercises:

```bash
for f in robustness/*.m; do
    echo "Running $f"
    matlab -batch "run('$f')"
done
```

Outputs are written to:

```text
results/robustness/
```

The robustness exercises are computationally more intensive than the benchmark run.

## 7. Reproducing the network figures

After running `main.m`, generate the network figures with:

```bash
matlab -batch "run('figures/create_network_figures.m')"
```

The figures are written to:

```text
results/figures/
```

The figure script reads the saved benchmark results and does not rerun or modify the model.

## 8. Reproducibility

The benchmark uses a fixed MATLAB random seed.

The Monte Carlo exercises use explicitly defined replication seeds. Within each replication, all scenarios start from the same initial network and use common random numbers for paired comparisons.

To reproduce the reported results, do not modify the random seeds, parameter values, scenario definitions, or input data.

## 9. Interpretation

The model is designed as a **mechanism-based policy experiment**.

Network topology and trade communities are synthetic. Geography, regulator identities, and deforestation-risk intensities provide empirical or semi-empirical grounding.

The model is therefore intended to study how policy timing affects adaptive network dynamics, rather than to reproduce or forecast observed bilateral trade.

## Citation

If you use this repository, please cite the accompanying paper.

**Paper citation:** to be added upon publication.
