# Methodology

## 1. Objective

The project predicts five double-gate tunnel-FET (DG-TFET) figures of merit
(FoMs) from geometry, dielectric, and doping parameters, and uses the resulting
surrogates to search for improved device designs.

Targets:

- `Ion` — drain current at `Vgs = 1.0 V`
- `Ioff` — drain current at `Vgs = 0 V`
- `Vth` — constant-current threshold voltage
- `gm_max` — maximum transconductance
- `SS_min` — minimum subthreshold swing

Models compared: polynomial ridge regression (PR), decision tree (DT), random
forest (RFR), LightGBM (LGBR), and a PyTorch multilayer perceptron (ANN).

A sixth model predicts the full `log10(Id)` transfer curve as a function of
`Vgs` and the device parameters.

## 2. Data provenance

### 2.1 Source audit

No public numerical DG-TFET TCAD dataset suitable for supervised training was
found. The sources inspected were:

- `llm4tcad_flow`: TCAD code-generation data, not device I-V data.
- ESDED: 25 experimental TFET JSON files. These are mixed TFET architectures
  with incomplete geometry and were used only as a qualitative sanity check.
- A Kaggle TFET dataset: unverified provenance, row-random structure, and no
  device grouping. It was not used for primary training.
- `Semiconductor_Database`: no TFET numerical data.

### 2.2 Primary generator

The primary dataset is generated with the **THM-TFET v1.2 physics-based compact
model** (`ctfet`, Technische Hochschule Mittelhessen, 2021). The source is kept
in `src/octave/ctfet/` with its `LICENSE.txt`. The licence permits modification,
copying, and redistribution provided the copyright notice, disclaimer, and
conditions are retained and the research group is acknowledged.

The data label used everywhere is:

> physics-based compact-model synthetic (NOT TCAD, NOT measured)

### 2.3 BM1 TCAD validation

The compact model was checked against the published BM1 Sentaurus TCAD transfer
characteristics. The validation files are preserved in
`data/raw/validation_bm1/`:

- `BM1_ntfet_tcad_data_vds_01.csv`
- `BM1_ntfet_tcad_data_vds_03.csv`
- `BM1_ntfet_tcad_data_vds_05.csv`
- `bm1_sim_vd_010.csv`, `bm1_sim_vd_030.csv`, `bm1_sim_vd_050.csv`
- `BM1_ntfet_tcad_param.pdf`

The TCAD data are from F. Horst et al., “Closed-form modeling approach of
trap-assisted tunneling current for use in compact TFET models,” 26th
International Conference Mixed Design of Integrated Circuits and Systems,
pp. 81–86, June 2019.

With `Eg_ch = 1.08 eV`, the agreement is:

| Vds | log10 RMSE, full −1.5…1.5 V | log10 RMSE, Vgs ≥ 0 | model/TCAD at Vgs = 1.0 V | model/TCAD at Vgs = 1.5 V |
|---:|---:|---:|---:|---:|
| 0.1 V | 0.273 | 0.227 | 0.625 | 0.973 |
| 0.3 V | 0.218 | 0.127 | 0.640 | 0.871 |
| 0.5 V | 0.183 | 0.072 | 0.804 | 0.869 |

The model reproduces the shape and order of magnitude of the TCAD curves, but it
is not a one-to-one TCAD replacement. It is implemented for **T = 300 K** and was
not varied in temperature.

## 3. Design space and simulation protocol

The design space was chosen to keep the compact model in a numerically stable
and physically plausible region. An earlier, broader space produced current
blow-ups (up to `Ion ≈ 2.5e6 A/µm` in a few devices) and many unusable curves;
it was discarded.

| Parameter | Min | Max | Sampling |
|---|---:|---:|---|
| `lch` | 15 nm | 50 nm | log |
| `tox` | 1 nm | 3 nm | log |
| `tch` | 5 nm | 15 nm | log |
| `eps_ox` | 3.9 | 25 | linear |
| `Ns` | 5e19 cm⁻³ | 1e20 cm⁻³ | log |
| `Nd` | 1e18 cm⁻³ | 1e20 cm⁻³ | log |
| `Nch` | 1e10 cm⁻³ | 1e13 cm⁻³ | log |
| `NT` | 1e10 cm⁻² | 1e12 cm⁻² | log |

Fixed parameters: `lsd = 20 nm`, `Eg_s = Eg_d = 1.124 eV`,
`Eg_ch = 1.08 eV`, silicon source/drain/channel, n-type TFET, `wch = 1e-4 cm`
(1 µm), `T = 300 K`. The interface-trap density `NT` is varied as a process
parameter; the model was calibrated at `NT = 1e10 cm⁻²`.

Sampling: 512 devices by Latin hypercube, including the BM1 benchmark as device
0. Bias grid: `Vgs = −0.4 … 1.5 V` in 0.02 V steps (96 points), and
`Vds ∈ {0.1, 0.3, 0.5} V`. This gives 147,456 rows.

Simulation is chunked across six workers and executed in the Octave container
`docker.io/gnuoctave/octave:latest`. Runtime was about 13 minutes with six
workers. The chunk driver is `src/octave/generate_chunk.m`; the setup is in
`src/octave/setup_params.m`.

Relevant model fixes:

- `TFET_Fit.N_ch` must be set equal to `TFET_Para.N_ch`; otherwise
  `func_TFET_verilog` fails with `structure has no member 'N_ch'`.
- All `TFET_Plot` fields must be initialized; set `y_pos = 'Center'` and
  `x_pos = 'xch1_s'`.
- `string.m` is a small compatibility shim because `string()` is not available
  in the container’s Octave namespace.
- `Eg_ch = 1.08` is used to match BM1; the physical value is closer to 1.124 eV.
  This is a calibration choice and is documented as such.

## 4. FoM extraction

For each valid `(device, Vds)` curve:

- `Ioff = Id(Vgs = 0)`
- `Ion = Id(Vgs = 1.0)`
- `Vth`: constant-current threshold at `Iref = 1e-8 A/µm`; fallback to
  `1e-9 A/µm`, then max-gm if needed.
- `gm_max`: maximum `dId/dVgs` in the valid region.
- `SS_min`: minimum `d Vgs / d log10(Id)` over
  `Id ∈ [max(10·Ioff, 1e-12), min(Ion/10, 1e-6)]`, with `Vgs ≥ 0`, positive
  slope, and at least five points.

Validity filters:

- `Ion` in `1e-9 … 1e-4 A/µm`
- `Ion/Ioff ≥ 100`
- finite, positive current
- defined `SS` and `Vth`

Result: 1,268 valid curves from 491 devices; 121,728 valid I-V rows. Valid
curves by `Vds`: 318/512 at 0.1 V, 461/512 at 0.3 V, 489/512 at 0.5 V.
Vth method counts: 1,227 constant-current 10 nA and 41 constant-current 1 nA.

## 5. Preprocessing and split

Features:

```
log10_lch, log10_tox, log10_tch, eps_ox,
log10_Ns, log10_Nd, log10_Nch, log10_NT, Vds_V
```

The curve model adds `Vgs_V`. Targets are `log10_Ion`, `log10_Ioff`, `Vth_V`,
`log10_gm_max`, and `SS_min_mV_per_dec`; the curve target is `log10_Id`.

The split is **grouped by device** with seed 42:

| Split | Devices | FoM rows | Curve rows |
|---|---:|---:|---:|
| train | 344 | 888 | 85,248 |
| validation | 74 | 193 | 18,528 |
| test | 73 | 187 | 17,952 |

Every `(device, Vds)` curve belongs to exactly one split. No device appears in
more than one split. `StandardScaler` is fit on the training rows only; scaled
columns are stored alongside the raw features.

## 6. Models and training

All models are trained on the same feature/target definitions:

- PR: `PolynomialFeatures(degree=3)` + ridge regression.
- DT: decision tree with cost-complexity pruning search.
- RFR: random forest with randomized hyperparameter search.
- LGBR: LightGBM with randomized hyperparameter search.
- ANN: PyTorch MLP with early stopping on validation loss.

Hyperparameter search uses `GroupKFold` grouped by `device_id`. The ANN
architecture search covers hidden sizes, dropout, learning rate, batch size,
epoch budget, and patience. All random seeds are fixed.

### Runtime control

An early configuration oversubscribed the 16-core host: RF and LGBM used many
threads while a 12-job outer search was already running, producing 39+ minute
runs. The final settings are:

- outer `N_JOBS = 12`
- RF and LGBM `n_jobs = 1`
- RF/LGBM search iterations 12 (FoM) and 8 (curve)
- RF/LGBM `n_estimators ∈ {100, 200, 400}`
- LGBM `num_leaves ∈ {7, 15, 31}`, `max_bin = 63`
- `OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1`

The FoM suite (25 fits) completed in 69.5 s. The curve suite (5 fits) completed
in 6 min 29 s. The curve ANN is the most expensive model because it trains on
85,248 rows.

## 7. Evaluation protocol

Model selection uses **validation R²**, not test R². Test metrics are reported
after selection. The test set is a held-out set of devices, so it measures
generalization to unseen device geometries within the sampled box, not to real
fabricated devices.

Evaluation outputs:

- `results/metrics/model_comparison.csv`: all 30 fits (25 FoM + 5 curve)
- `results/metrics/best_models.csv`: validation-selected best per target
- `results/metrics/feature_importance.csv`: permutation importance
- `results/graphs/`: comparison, parity, residual, ANN-loss, and importance plots
- `results/predictions/`: held-out predictions for every fit

Permutation importance is computed manually so that the PyTorch ANN wrapper,
which is not a scikit-learn estimator, can be scored through its `predict`
method. ANN predictions are inverse-transformed with the saved target scaler
before scoring.

## 8. Optimization protocol

The five validation-selected FoM surrogates are used to search the same
8-D box. `Vds` is fixed at 0.5 V during optimization.

### Objective

The scalar score rewards:

```
score = log10(Ion/Ioff)
        - (SS - 60) / 60
        - 0.5 log10(Ioff / 1e-15)
        + 0.5 log10(gm / 1e-7)
        - |Vth - 0.40| / 0.40
```

subject to:

- `0.20 ≤ Vth ≤ 0.80 V`
- `SS ≤ 60 mV/dec`
- `Ioff ≤ 1e-12 A/µm`
- `Ion ≥ 1e-7 A/µm`
- `gm ≥ 1e-7 S/µm`
- `Ion/Ioff ≥ 1e6`

The search methods are:

1. coarse grid over the 8 parameters (34,560 points)
2. Latin-hypercube random search (20,000 points)
3. Gaussian-process Bayesian optimization with a Matérn kernel and expected
   improvement (300 Latin-hypercube initialization points plus 20 EI steps;
   320 evaluations)
4. vectorized differential evolution (genetic/evolutionary search; 61
   generations, population 120, about 7,320 candidate evaluations)

A 3-objective Pareto analysis (minimize `Ioff`, minimize `SS`, maximize
`Ion/Ioff`) is computed on up to 5,000 feasible random-search candidates.

### Surrogate validation

The top 10 unique surrogate designs are converted back to Octave units and
re-simulated with `src/octave/generate_chunk.m`. Predicted and re-simulated
`Ion`, `Ioff`, `Vth`, `gm`, and `SS` are compared.

All top designs lie in a narrow corner of the box. `R²` is therefore not an
informative statistic for that 10-point set; the report uses **MAE and bias**.
The held-out test R² of each surrogate is the proper generalization metric.

## 9. Reproducibility

```bash
python3 src/data_generation.py --devices 512 --chunks 6 --workers 6
python3 src/feature_extraction.py
python3 src/preprocessing.py

OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  python3 src/train_models.py --tasks fom,curve --overwrite

python3 src/evaluate_models.py
python3 src/optimize_device.py
```

Notebooks 01–05 are executed with `nbclient`; the saved outputs are the ones in
`notebooks/`.

## 10. Limitations

- The primary data are synthetic compact-model output, not TCAD or measured
  silicon.
- The compact model is validated only at 300 K.
- `Ion` is normalized to a 1 µm device width; real layouts need width and
  contact resistance corrections.
- The optimization optimum lies on the boundary of the training box. It is a
  model-relative optimum and is sensitive to extrapolation.
- The `Vth` target is the weakest FoM (`R² ≈ 0.875` on test).
- The top-10 re-simulation set is too narrow for a meaningful R²; use the MAE
  and bias values, and the held-out test metrics, instead.
- Series resistance, variability, trap physics beyond the compact model, and
  fabrication constraints are outside this study.
