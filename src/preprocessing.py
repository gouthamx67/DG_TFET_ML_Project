"""Preprocess the DG-TFET FoM and I-V datasets.

Creates log-transformed features and targets, a device-grouped
train/validation/test split, and feature/target scalers.  The split is
grouped by device_id so that all curves of one device stay in one split.
"""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler

PROJECT = Path(__file__).resolve().parents[1]
PROC = PROJECT / "data" / "processed"
MODELS = PROJECT / "models" / "saved_models"

SEED = 42
TRAIN_FRAC = 0.70
VAL_FRAC = 0.15
TEST_FRAC = 0.15

DESIGN_FEATURES = [
    "log10_lch",
    "log10_tox",
    "log10_tch",
    "eps_ox",
    "log10_Ns",
    "log10_Nd",
    "log10_Nch",
    "log10_NT",
]
FOM_FEATURES = [*DESIGN_FEATURES, "Vds_V"]
CURVE_FEATURES = [*FOM_FEATURES, "Vgs_V"]

FOM_TARGETS = {
    "log10_Ion": "log10_Ion",
    "log10_Ioff": "log10_Ioff",
    "Vth_V": "Vth_V",
    "log10_gm_max": "log10_gm_max",
    "SS_min_mV_per_dec": "SS_min_mV_per_dec",
}
CURVE_TARGET = "log10_Id"


def add_features(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["log10_lch"] = np.log10(out["lch_nm"])
    out["log10_tox"] = np.log10(out["tox_nm"])
    out["log10_tch"] = np.log10(out["tch_nm"])
    out["log10_Ns"] = np.log10(out["Ns_cm3"])
    out["log10_Nd"] = np.log10(out["Nd_cm3"])
    out["log10_Nch"] = np.log10(out["Nch_cm3"])
    out["log10_NT"] = np.log10(out["NT_cm2"])
    return out


def split_devices(device_ids: np.ndarray) -> dict[str, np.ndarray]:
    rng = np.random.default_rng(SEED)
    ids = np.array(sorted(device_ids))
    rng.shuffle(ids)
    n = len(ids)
    n_train = int(round(TRAIN_FRAC * n))
    n_val = int(round(VAL_FRAC * n))
    train = np.sort(ids[:n_train])
    val = np.sort(ids[n_train : n_train + n_val])
    test = np.sort(ids[n_train + n_val :])
    assert len(set(train) & set(val)) == 0
    assert len(set(train) & set(test)) == 0
    assert len(set(val) & set(test)) == 0
    return {
        "train": train,
        "validation": val,
        "test": test,
    }


def assign_split(df: pd.DataFrame, split: dict[str, np.ndarray]) -> pd.DataFrame:
    mapping = {}
    for name, ids in split.items():
        for i in ids:
            mapping[int(i)] = name
    out = df.copy()
    out["split"] = out["device_id"].map(mapping)
    if out["split"].isna().any():
        raise ValueError("some devices were not assigned to a split")
    return out


def scale_features(
    fom: pd.DataFrame, curves: pd.DataFrame, features_fom: list[str], features_curve: list[str]
) -> tuple[pd.DataFrame, pd.DataFrame, StandardScaler, StandardScaler]:
    fom_scaler = StandardScaler().fit(fom.loc[fom.split == "train", features_fom])
    curve_scaler = StandardScaler().fit(
        curves.loc[curves.split == "train", features_curve]
    )
    fom_scaled = fom_scaler.transform(fom[features_fom])
    for j, c in enumerate(features_fom):
        fom[f"scaled_{c}"] = fom_scaled[:, j]
    curves_scaled = curve_scaler.transform(curves[features_curve])
    for j, c in enumerate(features_curve):
        curves[f"scaled_{c}"] = curves_scaled[:, j]
    return fom, curves, fom_scaler, curve_scaler


def main() -> None:
    MODELS.mkdir(parents=True, exist_ok=True)

    fom = add_features(pd.read_csv(PROC / "dg_tfet_fom.csv"))
    curves = add_features(pd.read_csv(PROC / "dg_tfet_curves_model.csv"))

    fom["log10_Ion"] = np.log10(fom["Ion_A_per_um"])
    fom["log10_Ioff"] = np.log10(fom["Ioff_A_per_um"])
    fom["log10_gm_max"] = np.log10(fom["gm_max_S_per_um"])

    split = split_devices(fom["device_id"].unique())
    fom = assign_split(fom, split)
    curves = assign_split(curves, split)

    missing = [c for c in FOM_FEATURES + list(FOM_TARGETS) if c not in fom.columns]
    if missing:
        raise ValueError(f"missing FoM columns: {missing}")
    missing = [c for c in CURVE_FEATURES + [CURVE_TARGET] if c not in curves.columns]
    if missing:
        raise ValueError(f"missing curve columns: {missing}")

    bad_fom = ~np.isfinite(fom[FOM_FEATURES + list(FOM_TARGETS)]).all(axis=1)
    bad_curves = ~np.isfinite(curves[CURVE_FEATURES + [CURVE_TARGET]]).all(axis=1)
    if bad_fom.any() or bad_curves.any():
        raise ValueError(
            f"non-finite values: fom={int(bad_fom.sum())}, curves={int(bad_curves.sum())}"
        )

    fom, curves, fom_scaler, curve_scaler = scale_features(
        fom, curves, FOM_FEATURES, CURVE_FEATURES
    )

    fom.to_csv(PROC / "fom_all_splits.csv", index=False)
    curves.to_csv(PROC / "curves_all_splits.csv", index=False)

    for name in ["train", "validation", "test"]:
        fom[fom.split == name].to_csv(PROC / f"fom_{name}.csv", index=False)
        curves[curves.split == name].to_csv(
            PROC / f"curves_{name}.csv", index=False
        )

    joblib.dump(fom_scaler, MODELS / "fom_feature_scaler.joblib")
    joblib.dump(curve_scaler, MODELS / "curve_feature_scaler.joblib")

    info = {
        "seed": SEED,
        "n_devices": {
            name: int(len(ids)) for name, ids in split.items()
        },
        "n_fom_rows": {
            name: int((fom.split == name).sum())
            for name in ["train", "validation", "test"]
        },
        "n_curve_rows": {
            name: int((curves.split == name).sum())
            for name in ["train", "validation", "test"]
        },
        "features_fom": FOM_FEATURES,
        "features_curve": CURVE_FEATURES,
        "targets_fom": list(FOM_TARGETS),
        "target_curve": CURVE_TARGET,
        "split_devices": {
            name: [int(x) for x in ids] for name, ids in split.items()
        },
    }
    (PROC / "preprocessing_info.json").write_text(json.dumps(info, indent=2))
    print(json.dumps({k: v for k, v in info.items() if k != "split_devices"}, indent=2))


if __name__ == "__main__":
    main()
