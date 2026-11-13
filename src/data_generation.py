"""Generate the DG-TFET dataset with the THM-TFET physics-based compact model.

The model is the published THM-TFET v1.2 compact model (THM University of
Applied Sciences, Giessen, Germany), distributed through nanoHUB resource
"ctfet".  It is a DC, physics-based compact model for double-gate
point-tunneling TFETs and was calibrated by its authors against Sentaurus
TCAD (benchmark BM1).  The generated data are therefore *physics-based
compact-model synthetic* data, not TCAD data and not measurements.

Usage
-----
    python src/data_generation.py [--devices 512] [--chunks 6] [--skip-run]

The Octave model source is in src/octave/ctfet (see LICENSE.txt there).
Octave is run in a rootless podman container:
    docker.io/gnuoctave/octave:latest
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import qmc

PROJECT = Path(__file__).resolve().parents[1]
RAW = PROJECT / "data" / "raw"
OCT_IN = RAW / "octave_input"
OCT_OUT = RAW / "octave_output"
LOG_DIR = PROJECT / "results" / "metrics" / "generation_logs"

IMAGE = "docker.io/gnuoctave/octave:latest"

# Design space for a silicon n-type double-gate TFET.
# Bounds are chosen from the physically meaningful part of the ctfet tool
# ranges and from the published BM1 device.  Dimensions are sampled
# log-uniformly; eps_ox linearly.
BOUNDS = {
    "lch_nm": (15.0, 50.0),
    "tox_nm": (1.0, 3.0),
    "tch_nm": (5.0, 15.0),
    "eps_ox": (3.9, 25.0),
    "Ns_cm3": (5e19, 1e20),
    "Nd_cm3": (1e18, 1e20),
    "Nch_cm3": (1e10, 1e13),
    "NT_cm2": (1e10, 1e12),
}
LOG_COLS = ["lch_nm", "tox_nm", "tch_nm", "Ns_cm3", "Nd_cm3", "Nch_cm3", "NT_cm2"]
VGS = np.round(np.arange(-0.4, 1.5001, 0.02), 2)
VDS = [0.1, 0.3, 0.5]

BENCHMARK = {
    "lch_nm": 22.0,
    "tox_nm": 2.0,
    "tch_nm": 10.0,
    "eps_ox": 22.0,
    "Ns_cm3": 1e20,
    "Nd_cm3": 1e20,
    "Nch_cm3": 1e11,
    "NT_cm2": 1e10,
}


def lhs_design(n: int, seed: int = 42) -> pd.DataFrame:
    """Latin-hypercube sample of the design space (without the benchmark)."""
    d = len(BOUNDS)
    sampler = qmc.LatinHypercube(d=d, seed=seed)
    u = sampler.random(n)
    data = {}
    for j, (name, (lo, hi)) in enumerate(BOUNDS.items()):
        if name in LOG_COLS:
            data[name] = np.exp(np.log(lo) + u[:, j] * (np.log(hi) - np.log(lo)))
        else:
            data[name] = lo + u[:, j] * (hi - lo)
    return pd.DataFrame(data)


def build_designs(n_devices: int, seed: int = 42) -> pd.DataFrame:
    n_lhs = n_devices - 1
    df = lhs_design(n_lhs, seed=seed)
    df = pd.concat([pd.DataFrame([BENCHMARK]), df], ignore_index=True)
    df.insert(0, "device_id", np.arange(len(df), dtype=int))
    for col in ["lch_nm", "tox_nm", "tch_nm"]:
        df[col] = df[col].round(4)
    return df


def write_chunks(designs: pd.DataFrame, n_chunks: int) -> list[dict]:
    OCT_IN.mkdir(parents=True, exist_ok=True)
    OCT_OUT.mkdir(parents=True, exist_ok=True)
    ids = np.array_split(designs.index.to_numpy(), n_chunks)
    chunks = []
    for k, idx in enumerate(ids):
        part = designs.loc[idx].copy()
        oct_in = pd.DataFrame(
            {
                "device_id": part.device_id,
                "lch_cm": part.lch_nm * 1e-7,
                "tox_cm": part.tox_nm * 1e-7,
                "tch_cm": part.tch_nm * 1e-7,
                "eps_ox": part.eps_ox,
                "Ns": part.Ns_cm3,
                "Nd": part.Nd_cm3,
                "Nch": part.Nch_cm3,
                "NT": part.NT_cm2,
            }
        )
        in_path = OCT_IN / f"chunk_{k:02d}.csv"
        out_path = OCT_OUT / f"chunk_{k:02d}.csv"
        oct_in.to_csv(in_path, index=False)
        chunks.append(
            {
                "chunk": k,
                "n_devices": len(part),
                "in_path": in_path,
                "out_path": out_path,
            }
        )
    return chunks


def run_chunk(chunk: dict) -> dict:
    log_path = LOG_DIR / f"chunk_{chunk['chunk']:02d}.log"
    cmd = [
        "podman",
        "run",
        "--rm",
        "--security-opt",
        "label=disable",
        "-v",
        f"{PROJECT}:/work:Z",
        "-w",
        "/work/src/octave",
        "-e",
        f"CHUNK_IN=/work/data/raw/octave_input/{chunk['in_path'].name}",
        "-e",
        f"CHUNK_OUT=/work/data/raw/octave_output/{chunk['out_path'].name}",
        IMAGE,
        "octave-cli",
        "/work/src/octave/generate_chunk.m",
    ]
    t0 = time.time()
    with open(log_path, "w") as log:
        proc = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, text=True)
    return {
        "chunk": chunk["chunk"],
        "returncode": proc.returncode,
        "seconds": round(time.time() - t0, 1),
        "out_path": str(chunk["out_path"]),
        "log": str(log_path),
    }


def run_all(chunks: list[dict], max_workers: int) -> list[dict]:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        futures = {pool.submit(run_chunk, c): c for c in chunks}
        for fut in as_completed(futures):
            res = fut.result()
            results.append(res)
            print(
                f"chunk {res['chunk']:02d}: rc={res['returncode']} "
                f"{res['seconds']} s"
            )
    results.sort(key=lambda r: r["chunk"])
    for res in results:
        if res["returncode"] != 0:
            raise RuntimeError(
                f"chunk {res['chunk']} failed; see {res['log']}"
            )
    return results


def merge_outputs(chunks: list[dict]) -> pd.DataFrame:
    frames = []
    for c in chunks:
        df = pd.read_csv(
            c["out_path"],
            header=None,
            names=[
                "device_id",
                "Vgs_V",
                "Vds_V",
                "Id_A_per_um",
                "Id_TAT_A_per_um",
                "Id_B2B_A_per_um",
            ],
        )
        frames.append(df)
    curves = pd.concat(frames, ignore_index=True)
    curves = curves.sort_values(["device_id", "Vds_V", "Vgs_V"]).reset_index(drop=True)
    curves["device_id"] = curves["device_id"].astype(int)
    return curves


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--devices", type=int, default=512)
    ap.add_argument("--chunks", type=int, default=6)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--skip-run", action="store_true")
    args = ap.parse_args()

    if shutil.which("podman") is None:
        sys.exit("podman is required to run the Octave compact model")
    if not (PROJECT / "src" / "octave" / "ctfet" / "func_TFET_verilog.m").exists():
        sys.exit("ctfet model source missing under src/octave/ctfet")

    designs = build_designs(args.devices, seed=args.seed)
    designs.to_csv(RAW / "device_designs.csv", index=False)
    print(f"wrote {RAW / 'device_designs.csv'} ({len(designs)} designs)")

    chunks = write_chunks(designs, args.chunks)
    print(f"wrote {len(chunks)} chunk inputs to {OCT_IN}")

    if not args.skip_run:
        results = run_all(chunks, args.workers)
        (RAW / "generation_run.json").write_text(
            json.dumps(results, indent=2)
        )
    else:
        print("--skip-run set; not running Octave")

    missing = [c["out_path"] for c in chunks if not c["out_path"].exists()]
    if missing:
        sys.exit(f"missing chunk outputs: {missing}")

    curves = merge_outputs(chunks)
    curves.to_csv(RAW / "dg_tfet_iv_curves_raw.csv", index=False)
    n_bad = int(curves["Id_A_per_um"].isna().sum())
    print(
        f"wrote {RAW / 'dg_tfet_iv_curves_raw.csv'} "
        f"({len(curves)} rows, {n_bad} NaN currents)"
    )

    meta = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "model": "THM-TFET v1.2 compact model (ctfet, THM University of Applied Sciences)",
        "model_type": "physics-based compact model calibrated to Sentaurus TCAD",
        "data_label": "physics-based compact-model synthetic (NOT TCAD, NOT measured)",
        "license": "see src/octave/ctfet/LICENSE.txt",
        "n_devices": int(len(designs)),
        "bias_grid": {
            "Vgs_V": [float(VGS[0]), float(VGS[-1]), float(VGS[1] - VGS[0])],
            "Vds_V": VDS,
        },
        "width_um": 1.0,
        "temperature_K": 300.0,
        "temperature_note": "model validated only at 300 K; T not varied",
        "design_space": {
            k: {"min": v[0], "max": v[1], "sampling": "log" if k in LOG_COLS else "linear"}
            for k, v in BOUNDS.items()
        },
        "fixed_parameters": {
            "lsd_nm": 20.0,
            "Eg_s_eV": 1.124,
            "Eg_d_eV": 1.124,
            "Eg_ch_eV": 1.08,
            "mat_s": "Silicon",
            "TYPE": 1,
        },
        "note_NT": "interface trap density NT is varied as a process parameter; model calibrated at NT=1e10 cm^-2",
    }
    (RAW / "generation_metadata.json").write_text(json.dumps(meta, indent=2))
    print(f"wrote {RAW / 'generation_metadata.json'}")


if __name__ == "__main__":
    main()
