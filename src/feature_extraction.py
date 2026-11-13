"""Extract device figures of merit from the generated DG-TFET I-V curves.

Targets (per device and drain bias):
    Ion      on-current at Vgs = 1.0 V              [A/um]
    Ioff     off-current at Vgs = 0 V               [A/um]
    Vth      constant-current threshold at 10 nA/um [V]
    gm_max   peak transconductance                  [S/um]
    SS_min   minimum subthreshold swing             [mV/dec]

Outputs
-------
data/processed/dg_tfet_fom.csv          valid curves, model-ready
data/processed/dg_tfet_fom_all.csv      all curves with validity flags
data/processed/dg_tfet_curves.csv       all finite positive I-V rows
data/processed/dg_tfet_curves_model.csv I-V rows of valid curves
data/processed/data_quality.json        extraction and exclusion report
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd

PROJECT = Path(__file__).resolve().parents[1]
RAW = PROJECT / "data" / "raw"
PROC = PROJECT / "data" / "processed"

VDD = 1.0
IREF = 1e-8
IREF_LOW = 1e-9
ION_MIN = 1e-9
ION_MAX = 1e-4
RATIO_MIN = 100.0
SS_MIN_POINTS = 5

DESIGN_COLS = [
    "lch_nm",
    "tox_nm",
    "tch_nm",
    "eps_ox",
    "Ns_cm3",
    "Nd_cm3",
    "Nch_cm3",
    "NT_cm2",
]


def _crossing(v: np.ndarray, i: np.ndarray, iref: float) -> float:
    idx = np.where((i[:-1] < iref) & (i[1:] >= iref) & (v[1:] > 0))[0]
    if len(idx) == 0:
        return np.nan
    k = int(idx[0])
    if i[k + 1] == i[k]:
        return float(v[k])
    return float(v[k] + (iref - i[k]) * (v[k + 1] - v[k]) / (i[k + 1] - i[k]))


def _fom_for_curve(v: np.ndarray, i: np.ndarray) -> dict:
    ioff = float(np.interp(0.0, v, i))
    ion = float(np.interp(VDD, v, i))
    ratio = ion / ioff if ioff > 0 else np.nan

    logi = np.log10(i)
    dlogi = np.gradient(logi, v)
    gm = np.gradient(i, v)
    mask_pos = v >= 0
    gm_max = float(np.max(gm[mask_pos])) if np.any(mask_pos) else np.nan
    gm_vdd = float(np.interp(VDD, v, gm))
    k_gm = int(np.argmax(gm[mask_pos]))
    vth_gm = float(v[mask_pos][k_gm])
    if k_gm == 0 or k_gm == int(np.sum(mask_pos)) - 1:
        vth_gm = np.nan

    lo = max(10.0 * ioff, 1e-12)
    hi = min(ion / 10.0, 1e-6)
    region = (i >= lo) & (i <= hi) & (dlogi > 0) & mask_pos
    if int(region.sum()) >= SS_MIN_POINTS:
        ss = 1000.0 / dlogi[region]
        ss_min = float(np.min(ss))
        ss_avg = float(np.mean(ss))
    else:
        ss_min = np.nan
        ss_avg = np.nan

    vth_cc = _crossing(v, i, IREF)
    vth_low = _crossing(v, i, IREF_LOW)
    if np.isfinite(vth_cc):
        vth, method = vth_cc, "constant_current_10nA"
    elif np.isfinite(vth_low):
        vth, method = vth_low, "constant_current_1nA"
    elif np.isfinite(vth_gm):
        vth, method = vth_gm, "max_gm"
    else:
        vth, method = np.nan, "undefined"

    return {
        "Ioff_A_per_um": ioff,
        "Ion_A_per_um": ion,
        "Ion_Ioff_ratio": ratio,
        "gm_max_S_per_um": gm_max,
        "gm_at_Vdd_S_per_um": gm_vdd,
        "SS_min_mV_per_dec": ss_min,
        "SS_avg_mV_per_dec": ss_avg,
        "Vth_cc_V": vth_cc,
        "Vth_low_V": vth_low,
        "Vth_gm_V": vth_gm,
        "Vth_V": vth,
        "Vth_method": method,
    }


def extract_fom(curves: pd.DataFrame, designs: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for (did, vd), x in curves.groupby(["device_id", "Vds_V"], sort=True):
        x = x.sort_values("Vgs_V")
        v = x["Vgs_V"].to_numpy()
        i = x["Id_A_per_um"].to_numpy()
        finite = bool(np.all(np.isfinite(i)) and np.all(i > 0))
        if finite:
            row = {"device_id": int(did), "Vds_V": float(vd), **_fom_for_curve(v, i)}
        else:
            row = {
                "device_id": int(did),
                "Vds_V": float(vd),
                **{c: np.nan for c in [
                    "Ioff_A_per_um", "Ion_A_per_um", "Ion_Ioff_ratio",
                    "gm_max_S_per_um", "gm_at_Vdd_S_per_um",
                    "SS_min_mV_per_dec", "SS_avg_mV_per_dec",
                    "Vth_cc_V", "Vth_low_V", "Vth_gm_V", "Vth_V",
                ]},
                "Vth_method": "undefined",
            }
        row["finite_curve"] = finite
        row["ion_ok"] = bool(finite and ION_MIN <= row["Ion_A_per_um"] <= ION_MAX)
        row["ratio_ok"] = bool(finite and row["Ion_Ioff_ratio"] >= RATIO_MIN)
        row["ss_ok"] = bool(finite and np.isfinite(row["SS_min_mV_per_dec"]))
        row["vth_ok"] = bool(finite and np.isfinite(row["Vth_V"]))
        row["valid"] = bool(
            row["ion_ok"] and row["ratio_ok"] and row["ss_ok"] and row["vth_ok"]
        )
        reasons = []
        if not finite:
            reasons.append("non_finite_or_nonpositive_current")
        if finite and not row["ion_ok"]:
            reasons.append("ion_out_of_range")
        if finite and not row["ratio_ok"]:
            reasons.append("ion_ioff_ratio_below_100")
        if finite and not row["ss_ok"]:
            reasons.append("ss_undefined")
        if finite and not row["vth_ok"]:
            reasons.append("vth_undefined")
        row["exclusion_reason"] = ";".join(reasons) if reasons else "none"
        rows.append(row)

    fom = pd.DataFrame(rows).merge(designs, on="device_id", how="left")
    ordered = ["device_id", *DESIGN_COLS, "Vds_V"] + [
        c for c in fom.columns if c not in {"device_id", *DESIGN_COLS, "Vds_V"}
    ]
    return fom[ordered]


def build_quality_report(fom_all: pd.DataFrame, curves: pd.DataFrame) -> dict:
    valid = fom_all[fom_all["valid"]]
    per_vds = (
        fom_all.groupby("Vds_V")["valid"].agg(["size", "sum"]).astype(int)
    )
    return {
        "n_devices_total": int(curves["device_id"].nunique()),
        "n_devices_valid": int(valid["device_id"].nunique()),
        "n_curves_total": int(len(fom_all)),
        "n_curves_valid": int(len(valid)),
        "valid_by_vds": {
            str(k): {"total": int(r["size"]), "valid": int(r["sum"])}
            for k, r in per_vds.iterrows()
        },
        "exclusion_reasons": (
            fom_all.loc[~fom_all["valid"], "exclusion_reason"]
            .value_counts()
            .to_dict()
        ),
        "target_ranges": {
            "Ioff_A_per_um": {
                "min": float(valid.Ioff_A_per_um.min()),
                "median": float(valid.Ioff_A_per_um.median()),
                "max": float(valid.Ioff_A_per_um.max()),
            },
            "Ion_A_per_um": {
                "min": float(valid.Ion_A_per_um.min()),
                "median": float(valid.Ion_A_per_um.median()),
                "max": float(valid.Ion_A_per_um.max()),
            },
            "Ion_Ioff_ratio": {
                "min": float(valid.Ion_Ioff_ratio.min()),
                "median": float(valid.Ion_Ioff_ratio.median()),
                "max": float(valid.Ion_Ioff_ratio.max()),
            },
            "Vth_V": {
                "min": float(valid.Vth_V.min()),
                "median": float(valid.Vth_V.median()),
                "max": float(valid.Vth_V.max()),
            },
            "gm_max_S_per_um": {
                "min": float(valid.gm_max_S_per_um.min()),
                "median": float(valid.gm_max_S_per_um.median()),
                "max": float(valid.gm_max_S_per_um.max()),
            },
            "SS_min_mV_per_dec": {
                "min": float(valid.SS_min_mV_per_dec.min()),
                "median": float(valid.SS_min_mV_per_dec.median()),
                "max": float(valid.SS_min_mV_per_dec.max()),
            },
        },
        "vth_method_counts": valid["Vth_method"].value_counts().to_dict(),
        "data_label": "physics-based compact-model synthetic, not TCAD or measured",
        "temperature_K": 300.0,
        "temperature_note": "model validated only at 300 K",
    }


def main() -> None:
    PROC.mkdir(parents=True, exist_ok=True)
    curves = pd.read_csv(RAW / "dg_tfet_iv_curves_raw.csv")
    designs = pd.read_csv(RAW / "device_designs.csv")

    fom_all = extract_fom(curves, designs)
    fom = fom_all[fom_all["valid"]].reset_index(drop=True)

    finite = curves[np.isfinite(curves["Id_A_per_um"]) & (curves["Id_A_per_um"] > 0)]
    curves_feat = finite.merge(designs, on="device_id", how="left")
    curves_feat["log10_Id"] = np.log10(curves_feat["Id_A_per_um"])

    valid_keys = fom[["device_id", "Vds_V"]]
    curves_model = curves_feat.merge(
        valid_keys, on=["device_id", "Vds_V"], how="inner"
    )

    fom_all.to_csv(PROC / "dg_tfet_fom_all.csv", index=False)
    fom.to_csv(PROC / "dg_tfet_fom.csv", index=False)
    curves_feat.to_csv(PROC / "dg_tfet_curves.csv", index=False)
    curves_model.to_csv(PROC / "dg_tfet_curves_model.csv", index=False)

    report = build_quality_report(fom_all, curves)
    (PROC / "data_quality.json").write_text(json.dumps(report, indent=2))

    print(f"valid curves: {len(fom)} ({fom.device_id.nunique()} devices)")
    print(f"valid I-V rows: {len(curves_model)}")
    print(f"wrote {PROC / 'dg_tfet_fom.csv'}")
    print(f"wrote {PROC / 'dg_tfet_curves_model.csv'}")
    print(f"wrote {PROC / 'data_quality.json'}")


if __name__ == "__main__":
    main()
