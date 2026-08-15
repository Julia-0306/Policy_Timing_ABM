# ODD Model Description: Adaptive Trade-Network Model of Environmental Policy Timing

## 1. Purpose and patterns

### Purpose

The model is a stylized adaptive trade-network agent-based model
designed to isolate how the **timing of importer-side environmental
regulation** changes trade-network adjustment and environmental
outcomes.

The central mechanism is that exporters continuously evaluate their
existing trade relationships against alternative import markets.
Environmental regulation changes the attractiveness of regulated
importers, causing exporters to adapt their trade relationships. Because
these adaptations change the network state on which later policy
interventions operate, different regulatory sequences can generate
different transition paths even when eventual regulatory coverage is
identical.

The model is therefore intended as a **mechanism-exploration model**,
not as a forecast of country-level trade.

### Main question

How does the timing and coordination of otherwise comparable
importer-side environmental regulation affect:

-   trade-network restructuring;
-   exporter switching behaviour;
-   trade volumes; and
-   embodied deforestation-risk exposure?

### Patterns / model behaviour of interest

The model is evaluated primarily through internally generated
comparative patterns across scenarios rather than by reproducing a
single historical trade network. Key patterns include:

-   endogenous network adaptation in the absence of regulation;
-   additional network restructuring after regulatory shocks;
-   persistence of existing trade relationships because adjustment is
    costly;
-   temporary trade-volume losses following the formation of replacement
    relationships;
-   different network trajectories under different policy schedules; and
-   differences in aggregate embodied deforestation-risk exposure across
    policy schedules.

The principal comparison holds the behavioural model fixed while
changing the timing of regulation.

------------------------------------------------------------------------

## 2. Entities, state variables and scales

### 2.1 Entities

The model contains **30 country agents**.

All countries can act as both exporters and importers. Roles are
relationship-specific: in a directed link (i `\rightarrow `{=tex}j),
country (i) is the exporter and country (j) is the importer.

Self-trade is excluded.

Three countries/markets --- the **EU, UK and US** --- are designated as
potential regulators. Their regulator identity is fixed throughout the
simulation, while regulatory exposure depends on the scenario and
simulation period.

### 2.2 Commodity layers

Trade is represented in four separate commodity layers:

1.  palm oil;
2.  soy;
3.  timber; and
4.  paper.

All 30 countries are present in every commodity layer.

One model period represents **one year**.

The simulation runs for **20 periods

### 2.3 Node attributes

#### Fixed throughout the simulation

-   **Country identity**
-   **Trade community:** one of five synthetic communities
-   **Geographic location**
-   **Regulator identity:** EU, UK, US, or non-regulator
-   **Commodity-specific deforestation intensity**

Bilateral distance is derived from country locations and remains fixed.

#### Recalculated or state-dependent

-   **Import-market potential**, where applicable, is calculated from
    the current model/network state rather than treated as a permanently
    fixed country characteristic.

### 2.4 Link attributes

A directed link represents an exporter--importer trade relationship in a
specific commodity layer.

Link-level information includes:

-   exporter (i);
-   importer (j);
-   commodity;
-   active/inactive relationship status;
-   current trade volume;
-   same-community status, derived from node communities;
-   bilateral distance, derived from node locations;
-   regulatory exposure;
-   recovery status;
-   recovery age;
-   initial recovery volume; and
-   recovery target volume.

### 2.5 Network state

For each commodity (c) and period (t), the network state contains:

-   (A\^{c,t}): directed adjacency matrix indicating which relationships
    exist;
-   (W\^{c,t}): trade-volume matrix;
-   relationship recovery information;
-   regulatory exposure; and
-   fixed country and bilateral attributes needed for behavioural
    decisions.

### 2.6 Fixed versus changing quantities

  -----------------------------------------------------------------------------
  Element           Initialization /     Fixed or changing?   Update over time
                    initial value                             
  ----------------- -------------------- -------------------- -----------------
  Number of         30                   Fixed                No change
  countries                                                   

  Country identity  Assigned at setup    Fixed                No change

  Community         One of 5 synthetic   Fixed                No change
                    communities                               

  Geographic        Loaded at setup      Fixed                No change
  location                                                    

  Bilateral         Derived from         Fixed                No change
  distance          locations                                 

  Deforestation     Commodity-specific   Fixed                No change
  intensity         input                                     

  Regulator         EU/UK/US designated  Fixed                No change
  identity                                                    

  Active trade      5 outgoing partners  Changing             Links may be
  links             per country and                           replaced
                    commodity at                              
                    initialization                            

  Trade volume      Random value between Changing             Changes after
                    2 and 8 on initial                        replacement and
                    links                                     during recovery

  Relationship      Initial              Changing             New replacement
  status            relationships                             links may enter
                    established                               recovery

  Recovery age      Initial links are    Changing             Increases
                    not recovering                            annually for
                                                              surviving
                                                              recovering links

  Import-market     Calculated from      Changing             Recalculated
  potential         model state                               during simulation

  Regulatory        Zero in Baseline     Scenario-dependent   Changes when a
  exposure                                                    regulator becomes
                                                              active

  Policy penalty    Benchmark parameter  Fixed within a run   Does not change
  (p)                                                         within a run

  Softmax           Benchmark parameter  Fixed within a run   Does not change
  sensitivity                                                 within a run
  (`\beta`{=tex})                                             

  Local/global      Benchmark parameters Fixed within a run   Do not change
  switching costs                                             within a run

  Recovery horizon  5 years in benchmark Fixed within a run   Does not change
                                                              within a run
  -----------------------------------------------------------------------------

------------------------------------------------------------------------

## 3. Process overview and scheduling

### 3.1 Initialization and first network

Initialization creates the starting network. Initialization
itself is conceptually prior to the first behavioural simulation period.

The initialization procedure:

1.  creates 30 country agents;
2.  assigns fixed country attributes;
3.  creates the four commodity layers;
4.  assigns each exporter five outgoing partners per commodity;
5.  assigns initial trade volumes;
6.  treats all initial relationships as established and not recovering;
7.  ensures minimum incoming exposure of the designated regulators; and
8.  stores the resulting state as the initial network.

### 3.2 Annual simulation sequence

Starting from (N(t)), each annual simulation period follows this
sequence:

1.  **Calculate market potential.**
2.  **Evaluate existing relationships and potential partners.**
3.  **Decide whether to stay or switch.**
4.  **If switching, determine the relevant local/global adjustment
    mode.**
5.  **Select a replacement partner.**
6.  **Collect all replacement decisions.**
7.  **Apply replacements synchronously.**
8.  **Assign the initial trade volume of newly created relationships.**
9.  **Update recovery of surviving replacement relationships.**
10. **Calculate model outcomes.**
11. Store the resulting network as (N(t+1)).

Thus:

**Existing network → evaluation → stay/switch → partner selection →
synchronous replacement → trade-volume/recovery update → outcomes → next
network**

### 3.3 Agent activation

The model does **not** randomly select two countries each period and
then determine whether they trade.

Instead, the simulation starts from an existing directed trade network.
Existing exporter--importer relationships are evaluated against
available replacement partners. Network change therefore occurs through
the reassessment and replacement of existing relationships.

### 3.4 Synchronous updating

Replacement decisions are **synchronous**.

All stay/switch and partner-selection decisions are based on the current
network (N(t)). The network is not modified immediately after each
individual exporter decision. Once decisions have been collected,
replacements are applied to produce (N(t+1)).

This prevents the arbitrary order in which agents are processed within a
period from directly determining the decisions of later agents in that
same period.

### 3.5 Baseline dynamics

In the Baseline scenario, no regulatory penalty is active.

The network can nevertheless evolve because exporters continue to
compare existing relationships with alternatives. Baseline network
change therefore arises solely from endogenous exporter adaptation.

Regulation is not required for adaptation to occur.

------------------------------------------------------------------------

## 4. Design concepts

### 4.1 Basic principles

The model combines ideas from adaptive trade networks,
relationship-specific trade frictions, spatial/community structure, and
importer-side environmental regulation.

Its central behavioural premise is that exporters can redirect trade
relationships when alternative destinations become more attractive.
Existing network structure matters because current relationships,
available alternatives, and previous replacement decisions shape future
opportunities.

### 4.2 Emergence

The following system-level outcomes emerge from repeated exporter-level
decisions:

-   network topology;
-   patterns of partner switching;
-   local versus global adjustment;
-   trade-volume trajectories;
-   aggregate network fitness; and
-   aggregate embodied deforestation-risk exposure.

No aggregate network trajectory is imposed directly.

### 4.3 Adaptation

Exporters adapt by comparing the value of existing relationships with
the value of available alternatives.

If retaining the current relationship is at least as attractive as
switching, the relationship is retained. If the alternative opportunity
value is higher, the exporter switches and selects a replacement
importer.

Adaptation occurs both with and without regulation. Regulation modifies
the incentives faced by exporters; it does not create the adaptation
mechanism itself.

### 4.4 Objectives

Exporter behaviour is represented through relationship scores rather
than through a full profit-maximization problem.

Relationship attractiveness reflects:

-   trade-community membership;
-   geographic distance;
-   current trade importance or expected market potential;
-   switching frictions; and
-   regulatory exposure when regulation is active.

The model therefore represents bounded, stylized partner choice rather
than a structural model of firm or national welfare maximization.

### 4.5 Learning

Agents do not learn behavioural parameters or estimate new decision
rules from past experience.

There is therefore **no explicit learning mechanism** in the benchmark
model.

### 4.6 Prediction

Agents do not forecast the future regulatory path or solve a
forward-looking dynamic optimization problem.

Potential partners are evaluated using information available in the
current period.

### 4.7 Sensing

Exporters use information represented in the model about:

-   their current relationships;
-   available candidate importers;
-   community membership;
-   bilateral distance;
-   market potential;
-   relationship characteristics; and
-   current regulatory exposure.

Agents do not possess information outside the variables explicitly
represented in the model.

### 4.8 Interaction

Countries interact through directed trade relationships.

Exporter decisions affect other countries by creating or dissolving
incoming trade links. These changes alter the network state inherited by
subsequent periods.

This network feedback is central to the policy-timing mechanism: an
earlier intervention can change the network on which a later
intervention operates.

### 4.9 Stochasticity

Stochasticity enters through:

-   random initialization of trading partners;
-   random initial trade volumes; and
-   probabilistic partner selection through the Softmax rule in the
    benchmark model.

Simulation results should therefore be evaluated across multiple random
seeds/initial networks rather than from a single realization.

### 4.10 Collectives

The five trade communities represent persistent groups of countries with
lower within-community trade frictions.

Communities are assigned during initialization and remain fixed. They
are not emergent communities generated endogenously by the simulation.

### 4.11 Observation

Key recorded model outcomes include:

-   number of switches;
-   local and global switches;
-   network fitness;
-   total trade volume; and
-   aggregate embodied deforestation-risk exposure.

Results are compared across policy scenarios and across repeated network
realizations.

------------------------------------------------------------------------

## 5. Initialization

Initialization produces the initial network.

### Step 1: Create agents

-   Create 30 country agents.
-   All countries can act as exporters and importers.
-   Exclude self-trade.

### Step 2: Assign fixed agent attributes

-   Assign each country to one of five synthetic communities.
-   Assign geographic location/distance information.
-   Assign commodity-specific deforestation intensity.
-   Identify EU, UK and US as regulators.

These characteristics remain fixed during the simulation.

### Step 3: Create commodity networks

Create four commodity layers:

-   palm oil;
-   soy;
-   timber; and
-   paper.

All countries are present in every layer.

### Step 4: Create initial trade links

-   Each country receives exactly five outgoing partners in each
    commodity layer.
-   Partners are drawn randomly without replacement from the other 29
    countries.
-   Links are directed from exporter to importer.

### Step 5: Assign initial link attributes

-   Each initial link receives a random trade volume between 2 and 8.
-   All initial relationships are treated as established.
-   Initial relationships are therefore not in recovery.

### Step 6: Ensure regulator exposure

-   EU, UK and US are each guaranteed at least eight incoming links in
    every commodity layer.
-   Existing links are reassigned if necessary.
-   Reassignment is one-for-one, so each exporter retains five outgoing
    relationships.

This exposure condition ensures that a regulatory shock has
relationships on which it can operate.

### Step 7: Store the initial state

The model stores the adjacency matrix, trade volumes, fixed attributes
and recovery state.

The resulting state is (N(1)).

------------------------------------------------------------------------

## 6. Input data

The model combines synthetic structural features with
empirical/semi-empirical environmental and geographic inputs.

### 6.1 Country information

Country identities and geographic information are loaded from the model
data files.

Geographic information is used to construct bilateral distance.

### 6.2 Communities

Five trade communities are **synthetic and fixed**.

They represent persistent trade frictions or affinity between groups of
countries and are not intended to reproduce a specific observed
community partition.

### 6.3 Regulator identities

EU, UK and US are designated as the regulating import markets used in
the policy scenarios.

### 6.4 Deforestation intensity

Each country--commodity pair receives a deforestation-intensity measure.

The current calibration uses:

-   Trase supply-chain risk information for palm oil and soy; and
-   FAOSTAT forestry production/forest information for timber and paper.

Raw measures from different sources are normalized within commodity
layers to a common (\[0,1\]) scale so that they can enter the stylized
model on a comparable scale.

### 6.5 Model input files

Current model inputs include:

-   `countries.csv`
-   `regulators.csv`
-   `distance_matrix.csv`
-   `deforestation_intensity_v2.csv`
-   `deforestation_intensity_metadata_v2.csv`

------------------------------------------------------------------------

## 7. Submodels

### 7.1 Market potential

For each exporter and potential importer, the model calculates a
normalized measure of expected market attractiveness.

This quantity is used when evaluating potential replacement partners.

### 7.2 Partner score

Current and potential relationships are evaluated using a common score
structure.

The benchmark score combines:

-   same-community advantage;
-   normalized geographic distance;
-   realized trade importance for existing relationships or expected
    market potential for potential relationships; and
-   a regulatory penalty when the importer is policy-exposed.

The community, distance and trade components enter with equal weight
after normalization.

No additional component-specific weighting parameters are used in the
benchmark specification.

### 7.3 Stay/switch decision

For an existing relationship, the exporter compares the current
relationship score with the opportunity value of alternatives.

-   **Stay** when the current relationship is at least as attractive as
    the alternative opportunity value.
-   **Switch** when the alternative opportunity value is higher.

Ties are resolved in favour of retaining the existing relationship.

No additional persistence threshold is imposed.

### 7.4 Local versus global adjustment

Potential replacement partners are separated into:

-   **local candidates:** countries in the exporter's community; and
-   **global candidates:** countries outside the exporter's community.

The model compares the opportunity values of the local and global
candidate sets.

The higher-valued adjustment mode determines the candidate pool used for
partner selection.

Global adjustment carries a higher switching cost than local adjustment.

### 7.5 Partner selection

Within the selected candidate pool, the benchmark model uses a Softmax
choice rule.

Higher-scoring alternatives have a higher probability of being selected,
but the highest-scoring alternative is not chosen with certainty.

The parameter (`\beta`{=tex}) controls choice sensitivity.

### 7.6 Replacement

Switching is implemented as **one-for-one relationship replacement**.

If exporter (i) replaces importer (j) with importer (k):

-   the old link (i `\rightarrow `{=tex}j) is dissolved;
-   the new link (i `\rightarrow `{=tex}k) is created; and
-   the number of outgoing links is preserved.

All replacements decided during a period are applied synchronously.

### 7.7 Initial volume of replacement relationships

A new relationship begins with a fraction of the trade volume of the
relationship it replaces.

The initial volume depends on the displaced relationship's realized
trade volume and the selected importer's normalized market potential.

The displaced relationship's pre-switch volume becomes the recovery
target.

### 7.8 Trade-volume recovery

New replacement relationships enter the new network at **relationship
age zero**.

Relationship age is distinct from simulation time: the simulation can
start at (t=1) while a relationship created during any (t
`\rightarrow `{=tex}t+1) transition starts with age (0).

If a replacement relationship survives, its trade volume recovers
linearly toward the displaced relationship's pre-switch trade volume.

The benchmark recovery horizon is five years.

A link created in the current transition does not immediately receive an
age-one recovery increment. If it survives to the next annual
transition, its recovery age increases from 0 to 1.

### 7.9 Regulatory exposure

When a regulator is active under a scenario, relationships with that
importer receive a regulatory penalty in exporter evaluation.

The policy therefore changes relative destination attractiveness rather
than directly forcing exporters to dissolve relationships.

### 7.10 Policy scenarios

The benchmark experiment contains five scenarios:

-   **Baseline:** no regulation.
-   **Early mover:** EU regulation begins first.
-   **Sequential:** EU, UK and US regulate sequentially.
-   **Coordinated:** EU, UK and US regulate simultaneously.
-   **Delayed coordination:** EU moves first and UK/US join later.

The policy-timing experiment changes the regulatory schedule while
keeping the behavioural model and other benchmark parameters fixed.

### 7.11 Environmental outcome

Commodity-specific embodied deforestation-risk exposure is calculated
from trade volume and the exporter's commodity-specific deforestation
intensity.

Aggregate environmental risk is obtained by summing exposure across
active relationships and commodity layers.

The resulting quantity should be interpreted as a **relative embodied
deforestation-risk exposure measure**, not as a forecast of physical
hectares deforested.

### 7.12 Network fitness

The model also records a network/exporter fitness measure representing
the attractiveness/quality of the realized network configuration.


------------------------------------------------------------------------

## Appendix A. Mechanism decomposition used for model diagnosis

The benchmark model was additionally decomposed into sequential
mechanisms to clarify the role of each component.

  -----------------------------------------------------------------------
  Order                   Mechanism               Role
  ----------------------- ----------------------- -----------------------
  M0                      Organic network         Minimal dynamic
                          adaptation              network: exporters can
                                                  retain or replace
                                                  relationships without
                                                  regulation, switching
                                                  costs, recovery, or
                                                  probabilistic partner
                                                  choice.

  M1                      Probabilistic partner   Adds Softmax partner
                          choice                  selection.

  M2                      Switching frictions     Adds local and global
                                                  switching costs.

  M3                      Trade-volume recovery   Adds gradual rebuilding
                                                  of trade volume after
                                                  replacement.

  M4                      Regulation              Adds the regulatory
                                                  penalty for
                                                  policy-exposed
                                                  importers.

  M5                      Policy timing           Holds the regulatory
                                                  mechanism fixed and
                                                  varies the timing of
                                                  EU, UK and US
                                                  implementation.
  -----------------------------------------------------------------------

This decomposition is a diagnostic experiment and should not be confused
with the annual scheduling of the benchmark model.


## Reference

Grimm, V., Railsback, S. F., Vincenot, C. E., Berger, U., Gallagher, C.,
DeAngelis, D. L., Edmonds, B., Ge, J., Giske, J., Groeneveld, J.,
Johnston, A. S. A., Milles, A., Nabe-Nielsen, J., Polhill, J. G.,
Radchuk, V., Rohwäder, M.-S., Stillman, R. A., Thiele, J., & Ayllón, D.
(2020). The ODD protocol for describing agent-based and other simulation
models: A second update to improve clarity, replication, and structural
realism. *Journal of Artificial Societies and Social Simulation, 23*(2),
7. https://doi.org/10.18564/jasss.4259
