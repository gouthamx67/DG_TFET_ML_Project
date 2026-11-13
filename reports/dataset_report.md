# Dataset report

## 1. Summary

| Item | Value |
|---|---:|
| Data label | physics-based compact-model synthetic |
| Generator | THM-TFET v1.2 compact model (`ctfet`, THM) |
| Temperature | 300 K (not varied) |
| Device width | 1 µm |
| Devices generated | 512 |
| Bias points per curve | 96 (`Vgs = −0.4 … 1.5 V`, 0.02 V step) |
| Drain biases | 0.1, 0.3, 0.5 V |
| Raw I-V rows | 147,456 |
| Missing raw currents | 6 |
| Valid curves | 1,268 |
| Devices with ≥1 valid curve | 491 |
| Valid I-V rows | 121,728 |
| Valid FoM rows | 1,268 |

The dataset is **not TCAD and not measured data**. It is a physics-based
compact-model synthetic dataset, validated against published BM1 Sentaurus TCAD
data (see `reports/methodology.md`).

## 2. Design space

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

Fixed: `lsd = 20 nm`, `Eg_s = Eg_d = 1.124 eV`, `Eg_ch = 1.08 eV`, n-type
TFET, silicon source/drain/channel. Device 0 is the BM1 benchmark.

## 3. Validity

| Vds | Curves generated | Valid curves |
|---:|---:|---:|
| 0.1 V | 512 | 318 |
| 0.3 V | 512 | 461 |
| 0.5 V | 512 | 489 |
| **Total** | **1,536** | **1,268** |

Exclusion reasons:

| Reason | Count |
|---|---:|
| `ion_out_of_range` | 123 |
| `ion_out_of_range; ss_undefined; vth_undefined` | 65 |
| `ion_out_of_range; vth_undefined` | 48 |
| `ion_out_of_range; ion_ioff_ratio_below_100; ss_undefined; vth_undefined` | 25 |
| `non_finite_or_nonpositive_current` | 6 |
| `ion_out_of_range; ion_ioff_ratio_below_100; ss_undefined` | 1 |
| **Total excluded** | **268** |

## 4. FoM ranges

| FoM | Min | Median | Max |
|---|---:|---:|---:|
| `Ioff` (A/µm) | 3.17e-16 | 1.33e-14 | 3.19e-13 |
| `Ion` (A/µm) | 1.01e-9 | 1.02e-7 | 1.51e-5 |
| `Ion/Ioff` | 1.65e4 | 7.13e6 | 2.42e9 |
| `Vth` (V) | 0.188 | 0.611 | 1.496 |
| `gm_max` (S/µm) | 1.13e-8 | 7.24e-7 | 4.40e-5 |
| `SS_min` (mV/dec) | 21.98 | 53.42 | 148.16 |

Vth extraction method counts:

- `constant_current_10nA`: 1,227 curves
- `constant_current_1nA`: 41 curves

## 5. Train / validation / test split

The split is grouped by `device_id` with seed 42.

| Split | Devices | FoM rows | Curve rows |
|---|---:|---:|---:|
| train | 344 | 888 | 85,248 |
| validation | 74 | 193 | 18,528 |
| test | 73 | 187 | 17,952 |

Integrity check: the device sets are disjoint. No device contributes rows to
more than one split.

## 6. Features and targets

FoM features:

```
log10_lch, log10_tox, log10_tch, eps_ox,
log10_Ns, log10_Nd, log10_Nch, log10_NT, Vds_V
```

Curve features add `Vgs_V`.

FoM targets:

```
log10_Ion, log10_Ioff, Vth_V, log10_gm_max, SS_min_mV_per_dec
```

Curve target: `log10_Id`.

All scalers are fit on the training split only. Raw and scaled columns are both
stored in the processed split files.

## 7. Generated files

Raw data:

- `data/raw/dg_tfet_iv_curves_raw.csv`
- `data/raw/device_designs.csv`
- `data/raw/generation_metadata.json`
- `data/raw/octave_input/`, `data/raw/octave_output/`
- `data/raw/validation_bm1/` (BM1 TCAD + compact-model comparison)

Processed data:

- `data/processed/dg_tfet_fom.csv` (1,268 valid FoM rows)
- `data/processed/dg_tfet_fom_all.csv` (all 1,536 curve rows with validity flags)
- `data/processed/dg_tfet_curves.csv` (147,450 finite positive I-V rows)
- `data/processed/dg_tfet_curves_model.csv` (121,728 valid model rows)
- `data/processed/data_quality.json`
- `data/processed/fom_train.csv`, `fom_validation.csv`, `fom_test.csv`
- `data/processed/curves_train.csv`, `curves_validation.csv`, `curves_test.csv`
- `data/processed/fom_all_splits.csv`, `curves_all_splits.csv`
- `data/processed/preprocessing_info.json`

## 8. Caveats

- The dataset is synthetic and model-relative.
- Valid-curve coverage is biased toward higher `Vds`; 0.1 V has the fewest valid
  devices.
- The 6 NaN raw currents are excluded; they are not imputed.
- `NT` is varied beyond the calibration point (`1e10 cm⁻²`), so high-`NT`
  results are extrapolations of the compact model.
- The narrow design box is intentional after the broad-space numerical
  blow-ups. Any design outside this box is unsupported.
