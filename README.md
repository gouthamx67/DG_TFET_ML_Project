# DG-TFET machine learning and design optimization

End-to-end workflow for predicting and optimizing double-gate tunnel-FET
figures of merit with five model families:

- polynomial ridge regression (PR)
- decision tree (DT)
- random forest (RFR)
- LightGBM (LGBR)
- PyTorch MLP (ANN)

The project predicts `Ion`, `Ioff`, `Vth`, `gm_max`, and `SS_min`, models the
full `log10(Id)` curve, and searches the device design space with grid, random,
Bayesian, and evolutionary optimization.

## Data provenance

The primary dataset is **physics-based compact-model synthetic** data generated
with the THM-TFET v1.2 compact model (`ctfet`, Technische Hochschule
Mittelhessen, 2021). It is **not TCAD and not measured data**.

The compact model was checked against published BM1 Sentaurus TCAD curves. With
`Eg_ch = 1.08 eV`, the full-range `log10` RMSE is 0.273 at `Vd = 0.1 V`, 0.218
at `0.3 V`, and 0.183 at `0.5 V`. The model is implemented for 300 K only and
was not varied in temperature.

See:

- `reports/methodology.md` for the full method
- `reports/dataset_report.md` for the dataset audit
- `reports/final_report.md` for results and limitations
- `data/raw/validation_bm1/` for the BM1 TCAD comparison files
- `src/octave/ctfet/LICENSE.txt` for the compact-model licence

## Key results

Held-out test performance (validation-selected model per target):

| Target | Model | Val R² | Test R² | Test RMSE |
|---|---|---:|---:|---:|
| `log10 Ion` | polynomial | 0.9891 | 0.9935 | 0.0737 |
| `log10 Ioff` | ANN | 0.9925 | 0.9964 | 0.0387 |
| `Vth` | ANN | 0.9076 | 0.8753 | 0.1067 V |
| `log10 gm_max` | polynomial | 0.9889 | 0.9950 | 0.0557 |
| `SS_min` | ANN | 0.9703 | 0.9461 | 4.8669 mV/dec |
| `log10 Id` (curve) | ANN | 0.9993 | 0.9993 | 0.0820 dex |

The optimizer’s best design is at the boundary of the explored box:

| Parameter | Value |
|---|---:|
| `lch` | 50 nm |
| `tox` | 3 nm |
| `tch` | 5 nm |
| `eps_ox` | 25 |
| `Ns` | 1e20 cm⁻³ |
| `Nd` | 1e20 cm⁻³ |
| `Nch` | 1e10 cm⁻³ |
| `NT` | 1e10 cm⁻² |

Surrogate prediction: `Ion ≈ 1.95e-5 A/µm`, `Ioff ≈ 1.48e-15 A/µm`,
`Vth ≈ 0.262 V`, `SS ≈ 28.0 mV/dec`, `Ion/Ioff ≈ 1.3e10`.

Octave re-simulation: `Ion ≈ 1.28e-5 A/µm`, `Ioff ≈ 1.13e-15 A/µm`,
`Vth ≈ 0.244 V`, `SS ≈ 22.9 mV/dec`, `Ion/Ioff ≈ 1.1e10`.

Because the top 10 designs sit in one narrow corner, the re-simulation check
uses MAE/bias rather than `R²`: `Ion` 0.213 dex, `Ioff` 0.108 dex,
`gm_max` 0.035 dex, `Vth` 0.0155 V, `SS_min` 5.24 mV/dec. Recomputing the
selection score on the Octave outputs keeps the same winner (device 0, grid:
11.607 vs. 11.569 for the runner-up).

## Project layout

```
DG_TFET_ML_Project/
├── data/
│   ├── raw/                     # generated I-V data, design table, BM1 validation
│   └── processed/               # FoMs, valid curves, splits, scalers metadata
├── models/saved_models/         # generated locally; model binaries are not versioned
├── notebooks/                   # 01–05, executed with saved outputs
├── reports/                     # methodology, dataset, final report
├── results/
│   ├── graphs/                  # comparison, parity, importance, Pareto plots
│   ├── metrics/                 # metrics JSON/CSV, optimization summaries
│   └── predictions/             # held-out and optimized-design predictions
├── src/
│   ├── ann_model.py             # PyTorch MLP wrapper
│   ├── data_generation.py       # LHS + chunked Octave generation
│   ├── evaluate_models.py       # held-out evaluation and plots
│   ├── feature_extraction.py    # FoM extraction and validity filters
│   ├── optimize_device.py       # grid/random/BO/GA + Octave validation
│   ├── preprocessing.py         # features, targets, grouped split, scaling
│   ├── train_models.py          # PR/DT/RFR/LGBR/ANN training
│   └── octave/                  # THM compact model + chunk driver
└── requirements.txt
```

## Installation

Python 3.14 is the tested environment. Install the Python dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Regenerating the dataset requires `podman` and the Octave image:

```bash
podman pull docker.io/gnuoctave/octave:latest
```

Prepared summary CSV artifacts and figures are included, so the notebooks and
model evaluation run without Octave. Model binaries (`models/saved_models/`,
about 1.5 GB) and the full curve tables are not versioned; regenerate them with
the commands below. Octave is needed only for data regeneration and the
optimized-design re-simulation.

## Reproduce

Generate the dataset (512 devices, 6 chunks/workers):

```bash
python3 src/data_generation.py --devices 512 --chunks 6 --workers 6
```

Extract FoMs and build the grouped splits:

```bash
python3 src/feature_extraction.py
python3 src/preprocessing.py
```

Train all models with the controlled thread settings:

```bash
OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  python3 src/train_models.py --tasks fom,curve --overwrite
```

Run evaluation and optimization:

```bash
python3 src/evaluate_models.py
python3 src/optimize_device.py
```

Notes:

- `train_models.py` merges each run into `model_comparison.csv` and replaces
  only the selected task/target/model rows; `--overwrite` controls retraining,
  not file replacement.
- The FoM suite (25 fits) takes about 70 s with the final settings. The curve
  suite takes about 6.5 minutes.
- The optimization run takes about 2 minutes, dominated by the Gaussian-process
  Bayesian search and the Octave validation.

## Notebooks

| Notebook | Content |
|---|---|
| `01_data_generation.ipynb` | dataset provenance, design space, example I-V, BM1 validation |
| `02_feature_extraction_and_eda.ipynb` | FoM extraction, distributions, correlations, split integrity |
| `03_model_training.ipynb` | model comparison, ANN loss curves, runtime settings |
| `04_model_evaluation.ipynb` | parity plots, feature importance, curve check |
| `05_device_optimization.ipynb` | method comparison, Pareto front, best design, re-simulation |

## Important limitations

- The data are synthetic compact-model output, not TCAD or measured silicon.
- The model is validated only at 300 K.
- The optimized design lies on the training-box boundary; treat it as a
  model-relative result.
- `Vth` is the weakest FoM (`R² ≈ 0.875`).
- `Ion` is normalized to 1 µm width; layout, series resistance, variability,
  and fabrication constraints are not included.
- The surrogate overpredicts `Ion` at the corner by about 0.21 dex.

## Acknowledgment

THM-TFET v1.2 compact model, Copyright 2021 Technische Hochschule Mittelhessen.
See `src/octave/ctfet/LICENSE.txt`.

BM1 TCAD validation data: F. Horst et al., “Closed-form modeling approach of
trap-assisted tunneling current for use in compact TFET models,” 26th
International Conference Mixed Design of Integrated Circuits and Systems,
pp. 81–86, June 2019.
