"""Multi-objective DG-TFET design optimization on the trained surrogates.

Methods compared:
  grid search
  Latin-hypercube random search
  Gaussian-process Bayesian optimization
  differential evolution (genetic/evolutionary algorithm)

The top designs are re-simulated with the THM-TFET compact model in Octave
to check the surrogate predictions.
"""

from __future__ import annotations

import itertools
import json
import subprocess
import time
from pathlib import Path

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.optimize import differential_evolution
from scipy.stats import norm, qmc
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import ConstantKernel, Matern, WhiteKernel

from ann_model import TorchMLPRegressor
from feature_extraction import _fom_for_curve

PROJECT = Path(__file__).resolve().parents[1]
RAW = PROJECT / "data" / "raw"
MODELS = PROJECT / "models" / "saved_models"
METRICS = PROJECT / "results" / "metrics"
PREDS = PROJECT / "results" / "predictions"
GRAPHS = PROJECT / "results" / "graphs"

SEED = 42
VDS = 0.5
N_RANDOM = 20000
N_GRID_MAX = 40000
N_BO_INIT = 300
N_BO_ITER = 20
GA_MAXITER = 60
GA_POPSIZE = 15

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
DESIGN_COLS = list(BOUNDS)

FOM_FEATURES = [
    "log10_lch", "log10_tox", "log10_tch", "eps_ox",
    "log10_Ns", "log10_Nd", "log10_Nch", "log10_NT", "Vds_V",
]
TARGETS = ["log10_Ion", "log10_Ioff", "Vth_V", "log10_gm_max", "SS_min_mV_per_dec"]


def lhs(n: int, seed: int = SEED) -> pd.DataFrame:
    u = qmc.LatinHypercube(d=len(BOUNDS), seed=seed).random(n)
    data = {}
    for j, (name, (lo, hi)) in enumerate(BOUNDS.items()):
        if name in LOG_COLS:
            data[name] = np.exp(np.log(lo) + u[:, j] * (np.log(hi) - np.log(lo)))
        else:
            data[name] = lo + u[:, j] * (hi - lo)
    return pd.DataFrame(data)


def normalized_to_design(u: np.ndarray) -> pd.DataFrame:
    u = np.atleast_2d(u)
    data = {}
    for j, (name, (lo, hi)) in enumerate(BOUNDS.items()):
        if name in LOG_COLS:
            data[name] = np.exp(np.log(lo) + u[:, j] * (np.log(hi) - np.log(lo)))
        else:
            data[name] = lo + u[:, j] * (hi - lo)
    return pd.DataFrame(data)


class Surrogate:
    def __init__(self) -> None:
        best = pd.read_csv(METRICS / "best_models.csv")
        best = best[best.task == "fom"].set_index("target")
        self.models = {}
        for target in TARGETS:
            row = best.loc[target]
            self.models[target] = {
                "name": row.model,
                "model": joblib.load(MODELS / f"fom_{target}_{row.model}.joblib"),
                "target_scaler": (
                    joblib.load(
                        MODELS / f"fom_{target}_{row.model}_target_scaler.joblib"
                    )
                    if row.model == "ann"
                    else None
                ),
                "scaled": row.model in {"polynomial", "ann"},
            }
        self.feature_scaler = joblib.load(MODELS / "fom_feature_scaler.joblib")

    def _features(self, designs: pd.DataFrame) -> pd.DataFrame:
        return pd.DataFrame(
            {
                "log10_lch": np.log10(designs.lch_nm),
                "log10_tox": np.log10(designs.tox_nm),
                "log10_tch": np.log10(designs.tch_nm),
                "eps_ox": designs.eps_ox,
                "log10_Ns": np.log10(designs.Ns_cm3),
                "log10_Nd": np.log10(designs.Nd_cm3),
                "log10_Nch": np.log10(designs.Nch_cm3),
                "log10_NT": np.log10(designs.NT_cm2),
                "Vds_V": VDS,
            }
        )

    def predict(self, designs: pd.DataFrame) -> pd.DataFrame:
        X_raw = self._features(designs)[FOM_FEATURES]
        X_scaled = self.feature_scaler.transform(X_raw)
        out = pd.DataFrame(index=designs.index)
        for target, spec in self.models.items():
            X = X_scaled if spec["scaled"] else X_raw.to_numpy()
            pred = spec["model"].predict(X)
            if spec["target_scaler"] is not None:
                pred = spec["target_scaler"].inverse_transform(
                    np.asarray(pred).reshape(-1, 1)
                ).ravel()
            out[target] = pred
        out["Ion_A_per_um"] = np.power(10.0, out["log10_Ion"])
        out["Ioff_A_per_um"] = np.power(10.0, out["log10_Ioff"])
        out["gm_max_S_per_um"] = np.power(10.0, out["log10_gm_max"])
        out["Ion_Ioff_ratio"] = out["Ion_A_per_um"] / out["Ioff_A_per_um"]
        return out


def constraints(fom: pd.DataFrame) -> np.ndarray:
    return (
        (fom.Vth_V >= 0.20)
        & (fom.Vth_V <= 0.80)
        & (fom.SS_min_mV_per_dec <= 60.0)
        & (fom.Ioff_A_per_um <= 1e-12)
        & (fom.Ion_A_per_um >= 1e-7)
        & (fom.gm_max_S_per_um >= 1e-7)
        & (fom.Ion_Ioff_ratio >= 1e6)
    ).to_numpy()


def score(fom: pd.DataFrame) -> np.ndarray:
    return (
        np.log10(fom.Ion_Ioff_ratio)
        - (fom.SS_min_mV_per_dec - 60.0) / 60.0
        - 0.5 * np.log10(fom.Ioff_A_per_um / 1e-15)
        + 0.5 * np.log10(fom.gm_max_S_per_um / 1e-7)
        - 1.0 * np.abs(fom.Vth_V - 0.40) / 0.40
    ).to_numpy()


def penalty(fom: pd.DataFrame) -> np.ndarray:
    return (
        10.0 * np.maximum(0.0, 0.20 - fom.Vth_V)
        + 10.0 * np.maximum(0.0, fom.Vth_V - 0.80)
        + np.maximum(0.0, fom.SS_min_mV_per_dec - 60.0) / 10.0
        + 2.0 * np.maximum(0.0, np.log10(fom.Ioff_A_per_um / 1e-12))
        + 2.0 * np.maximum(0.0, np.log10(1e-7 / fom.Ion_A_per_um))
        + 2.0 * np.maximum(0.0, np.log10(1e-7 / fom.gm_max_S_per_um))
        + 2.0 * np.maximum(0.0, np.log10(1e6 / fom.Ion_Ioff_ratio))
    ).to_numpy()


def evaluate(sur: Surrogate, designs: pd.DataFrame) -> tuple[pd.DataFrame, np.ndarray, np.ndarray]:
    fom = sur.predict(designs)
    return fom, score(fom), constraints(fom)


def scalar_objective_batch(sur: Surrogate, U: np.ndarray) -> np.ndarray:
    U = np.asarray(U, dtype=float)
    if U.ndim == 2 and U.shape[0] == len(BOUNDS) and U.shape[1] != len(BOUNDS):
        U = U.T
    designs = normalized_to_design(U)
    fom = sur.predict(designs)
    return -(score(fom) - penalty(fom))


def candidate_frame(
    designs: pd.DataFrame,
    fom: pd.DataFrame,
    sc: np.ndarray,
    ok: np.ndarray,
    method: str,
) -> pd.DataFrame:
    out = designs.reset_index(drop=True).copy()
    out["method"] = method
    out["score"] = sc
    out["valid"] = ok
    out["pred_Ion_A_per_um"] = fom.Ion_A_per_um.to_numpy()
    out["pred_Ioff_A_per_um"] = fom.Ioff_A_per_um.to_numpy()
    out["pred_Vth_V"] = fom.Vth_V.to_numpy()
    out["pred_gm_max_S_per_um"] = fom.gm_max_S_per_um.to_numpy()
    out["pred_SS_min_mV_per_dec"] = fom.SS_min_mV_per_dec.to_numpy()
    out["pred_Ion_Ioff_ratio"] = fom.Ion_Ioff_ratio.to_numpy()
    return out


def pareto_mask(costs: np.ndarray) -> np.ndarray:
    n = len(costs)
    efficient = np.ones(n, dtype=bool)
    for i in range(n):
        if not efficient[i]:
            continue
        dominated = np.all(costs <= costs[i], axis=1) & np.any(
            costs < costs[i], axis=1
        )
        efficient[dominated] = False
    return efficient


def grid_designs() -> pd.DataFrame:
    axes = {
        "lch_nm": [15.0, 25.0, 35.0, 50.0],
        "tox_nm": [1.0, 1.5, 2.0, 2.5, 3.0],
        "tch_nm": [5.0, 8.0, 12.0, 15.0],
        "eps_ox": [3.9, 10.0, 22.0, 25.0],
        "Ns_cm3": [5e19, 7.5e19, 1e20],
        "Nd_cm3": [1e18, 1e19, 1e20],
        "Nch_cm3": [1e10, 1e11, 1e12, 1e13],
        "NT_cm2": [1e10, 1e11, 1e12],
    }
    keys = list(axes)
    rows = list(itertools.product(*(axes[k] for k in keys)))
    if len(rows) > N_GRID_MAX:
        rng = np.random.default_rng(SEED)
        idx = rng.choice(len(rows), size=N_GRID_MAX, replace=False)
        rows = [rows[i] for i in idx]
    return pd.DataFrame(rows, columns=keys)


def bayesian_optimization(sur: Surrogate) -> tuple[pd.DataFrame, pd.DataFrame, np.ndarray, np.ndarray, dict]:
    t0 = time.perf_counter()
    init = qmc.LatinHypercube(d=len(BOUNDS), seed=SEED + 1).random(N_BO_INIT)
    U = [init]
    y = [scalar_objective_batch(sur, init)]
    history = [float(y[0].min())]

    kernel = ConstantKernel(1.0, (1e-3, 1e3)) * Matern(
        length_scale=np.ones(len(BOUNDS)),
        length_scale_bounds=(1e-2, 1e2),
        nu=2.5,
    ) + WhiteKernel(1e-6, (1e-10, 1e-2))
    gp = GaussianProcessRegressor(
        kernel=kernel,
        normalize_y=True,
        n_restarts_optimizer=0,
        random_state=SEED,
    )

    for _ in range(N_BO_ITER):
        U_all = np.vstack(U)
        y_all = np.concatenate(y)
        gp.fit(U_all, y_all)
        pool = qmc.LatinHypercube(d=len(BOUNDS), seed=SEED + 2 + len(U)).random(10000)
        mu, sigma = gp.predict(pool, return_std=True)
        sigma = np.maximum(sigma, 1e-12)
        best = float(y_all.min())
        imp = best - mu
        z = imp / sigma
        ei = imp * norm.cdf(z) + sigma * norm.pdf(z)
        u_new = pool[int(np.argmax(ei)) : int(np.argmax(ei)) + 1]
        U.append(u_new)
        y_new = scalar_objective_batch(sur, u_new)[0]
        y.append(np.array([y_new]))
        history.append(float(min(best, y_new)))

    U_all = np.vstack(U)
    designs = normalized_to_design(U_all)
    fom, sc, ok = evaluate(sur, designs)
    info = {
        "seconds": time.perf_counter() - t0,
        "n_evaluations": int(len(U_all)),
        "best_objective": float(np.min(np.concatenate(y))),
        "history": history,
    }
    return designs, fom, sc, ok, info


def genetic_optimization(sur: Surrogate) -> tuple[pd.DataFrame, pd.DataFrame, np.ndarray, np.ndarray, dict]:
    t0 = time.perf_counter()
    result = differential_evolution(
        lambda U: scalar_objective_batch(sur, U),
        bounds=[(0.0, 1.0)] * len(BOUNDS),
        maxiter=GA_MAXITER,
        popsize=GA_POPSIZE,
        tol=1e-6,
        polish=False,
        seed=SEED,
        workers=1,
        updating="immediate",
        vectorized=True,
    )
    u = np.vstack([result.x.reshape(1, -1), result.population])
    designs = normalized_to_design(u)
    fom, sc, ok = evaluate(sur, designs)
    info = {
        "seconds": time.perf_counter() - t0,
        "n_generations": int(result.nfev),
        "population_size": int(result.population.shape[0]),
        "n_evaluations_approx": int(result.nfev * result.population.shape[0]),
        "vectorized": True,
        "best_objective": float(result.fun),
    }
    return designs, fom, sc, ok, info


def validation_with_octave(top: pd.DataFrame, sur: Surrogate) -> pd.DataFrame:
    in_dir = RAW / "octave_input"
    out_dir = RAW / "octave_output"
    in_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    n = len(top)
    oct_in = pd.DataFrame(
        {
            "device_id": np.arange(n),
            "lch_cm": top.lch_nm.to_numpy() * 1e-7,
            "tox_cm": top.tox_nm.to_numpy() * 1e-7,
            "tch_cm": top.tch_nm.to_numpy() * 1e-7,
            "eps_ox": top.eps_ox.to_numpy(),
            "Ns": top.Ns_cm3.to_numpy(),
            "Nd": top.Nd_cm3.to_numpy(),
            "Nch": top.Nch_cm3.to_numpy(),
            "NT": top.NT_cm2.to_numpy(),
        }
    )
    in_path = in_dir / "optimized_designs.csv"
    out_path = out_dir / "optimized_designs.csv"
    oct_in.to_csv(in_path, index=False)

    cmd = [
        "podman", "run", "--rm", "--security-opt", "label=disable",
        "-v", f"{PROJECT}:/work:Z", "-w", "/work/src/octave",
        "-e", "CHUNK_IN=/work/data/raw/octave_input/optimized_designs.csv",
        "-e", "CHUNK_OUT=/work/data/raw/octave_output/optimized_designs.csv",
        "docker.io/gnuoctave/octave:latest",
        "octave-cli", "/work/src/octave/generate_chunk.m",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stdout + "\n" + proc.stderr)

    raw = pd.read_csv(
        out_path,
        header=None,
        names=[
            "device_id", "Vgs_V", "Vds_V", "Id_A_per_um",
            "Id_TAT_A_per_um", "Id_B2B_A_per_um",
        ],
    )
    sim_rows = []
    for did, g in raw.groupby("device_id"):
        g = g[g.Vds_V == VDS].sort_values("Vgs_V")
        fom = _fom_for_curve(g.Vgs_V.to_numpy(), g.Id_A_per_um.to_numpy())
        fom["device_id"] = int(did)
        sim_rows.append(fom)
    sim = pd.DataFrame(sim_rows)
    sim["score_sim"] = score(sim)

    pred = sur.predict(top.reset_index(drop=True))
    pred["device_id"] = np.arange(n)
    out = pred.merge(sim, on="device_id", suffixes=("_pred", "_sim"))
    t = top.reset_index(drop=True)
    out["method"] = t.method
    for col in DESIGN_COLS:
        out[col] = t[col]
    out["score"] = t.score
    return out


def validation_metrics(val: pd.DataFrame) -> dict:
    from scipy.stats import pearsonr
    from sklearn.metrics import mean_absolute_error, r2_score

    pairs = {
        "Ion": ("Ion_A_per_um_pred", "Ion_A_per_um_sim", True),
        "Ioff": ("Ioff_A_per_um_pred", "Ioff_A_per_um_sim", True),
        "gm_max": ("gm_max_S_per_um_pred", "gm_max_S_per_um_sim", True),
        "Vth": ("Vth_V_pred", "Vth_V_sim", False),
        "SS_min": ("SS_min_mV_per_dec_pred", "SS_min_mV_per_dec_sim", False),
    }
    out = {}
    for name, (pred_col, sim_col, log_space) in pairs.items():
        yp = val[pred_col].to_numpy(dtype=float)
        ys = val[sim_col].to_numpy(dtype=float)
        if log_space:
            yp = np.log10(np.maximum(yp, 1e-30))
            ys = np.log10(np.maximum(ys, 1e-30))
        err = yp - ys
        rng = float(np.ptp(ys))
        out[name] = {
            "r2": float(r2_score(ys, yp)) if rng > 1e-12 else None,
            "mae": float(mean_absolute_error(ys, yp)),
            "bias": float(np.mean(err)),
            "median_abs_error": float(np.median(np.abs(err))),
            "max_abs_error": float(np.max(np.abs(err))),
            "pearson_r": float(pearsonr(ys, yp).statistic) if rng > 1e-12 else None,
            "range_sim": rng,
            "n": int(len(ys)),
            "space": "log10" if log_space else "linear",
            "r2_note": "R2 is not informative for a narrow optimized-design set; use MAE/bias",
        }
    return out


def main() -> None:
    GRAPHS.mkdir(parents=True, exist_ok=True)
    PREDS.mkdir(parents=True, exist_ok=True)
    METRICS.mkdir(parents=True, exist_ok=True)
    sur = Surrogate()

    summary = {}

    print("grid search")
    t0 = time.perf_counter()
    gd = grid_designs()
    gf, gs, gok = evaluate(sur, gd)
    gdf = candidate_frame(gd, gf, gs, gok, "grid")
    summary["grid"] = {
        "seconds": time.perf_counter() - t0,
        "n_evaluations": int(len(gd)),
        "n_valid": int(gok.sum()),
        "best_score": float(gdf[gdf.valid].score.max()),
    }
    print(f"  {len(gd)} designs, {int(gok.sum())} valid, {summary['grid']['seconds']:.1f} s")

    print("random search")
    t0 = time.perf_counter()
    rd = lhs(N_RANDOM, seed=SEED)
    rf, rs, rok = evaluate(sur, rd)
    rdf = candidate_frame(rd, rf, rs, rok, "random")
    summary["random"] = {
        "seconds": time.perf_counter() - t0,
        "n_evaluations": int(len(rd)),
        "n_valid": int(rok.sum()),
        "best_score": float(rdf[rdf.valid].score.max()),
    }
    print(f"  {len(rd)} designs, {int(rok.sum())} valid, {summary['random']['seconds']:.1f} s")

    print("bayesian optimization")
    bd, bf, bs, bok, binfo = bayesian_optimization(sur)
    bdf = candidate_frame(bd, bf, bs, bok, "bayesian")
    summary["bayesian"] = {
        **binfo,
        "n_valid": int(bok.sum()),
        "best_score": float(bdf[bdf.valid].score.max()),
    }
    print(f"  best score {summary['bayesian']['best_score']:.3f}, {binfo['seconds']:.1f} s")

    print("differential evolution")
    dd, df, ds, dok, dinfo = genetic_optimization(sur)
    ddf = candidate_frame(dd, df, ds, dok, "genetic")
    summary["genetic"] = {
        **dinfo,
        "n_valid": int(dok.sum()),
        "best_score": float(ddf[ddf.valid].score.max()),
    }
    print(f"  best score {summary['genetic']['best_score']:.3f}, {dinfo['seconds']:.1f} s")

    pool = pd.concat([gdf, rdf, bdf, ddf], ignore_index=True)
    all_best = (
        pool.sort_values("score", ascending=False)
        .groupby("method", as_index=False)
        .head(1)
        .sort_values("score", ascending=False)
    )
    all_best.to_csv(PREDS / "optimization_method_best.csv", index=False)

    valid_pool = pool[pool.valid].sort_values("score", ascending=False)
    top = valid_pool.drop_duplicates(subset=DESIGN_COLS).head(10)
    if len(top) < 10:
        top = (
            pd.concat([top, valid_pool], ignore_index=True)
            .drop_duplicates(subset=DESIGN_COLS)
            .head(10)
        )
    top.to_csv(PREDS / "optimized_designs.csv", index=False)
    valid_pool.head(100).to_csv(PREDS / "optimization_top100.csv", index=False)

    feasible_idx = np.where(rok)[0]
    if len(feasible_idx) < 100:
        feasible_idx = np.arange(len(rd))
    rng = np.random.default_rng(SEED)
    if len(feasible_idx) > 5000:
        feasible_idx = rng.choice(feasible_idx, size=5000, replace=False)
    costs = np.column_stack(
        [
            rf.Ioff_A_per_um.to_numpy(),
            rf.SS_min_mV_per_dec.to_numpy(),
            -rf.Ion_Ioff_ratio.to_numpy(),
        ]
    )
    costs_f = costs[feasible_idx]
    mask = pareto_mask(costs_f)
    pareto_idx = feasible_idx[mask]

    fig, axes = plt.subplots(1, 3, figsize=(15, 4.5))
    bg = np.random.default_rng(SEED).choice(len(rd), size=min(4000, len(rd)), replace=False)
    axes[0].scatter(rf.Ioff_A_per_um.iloc[bg], rf.SS_min_mV_per_dec.iloc[bg], s=5, alpha=0.2, c=np.log10(rf.Ion_Ioff_ratio.iloc[bg]), cmap="viridis")
    axes[0].scatter(rf.Ioff_A_per_um.iloc[pareto_idx], rf.SS_min_mV_per_dec.iloc[pareto_idx], s=14, c="k", label="Pareto")
    axes[0].set_xscale("log")
    axes[0].set_xlabel("Ioff (A/um)")
    axes[0].set_ylabel("SSmin (mV/dec)")
    axes[0].legend(fontsize=8)

    axes[1].scatter(rf.Ion_A_per_um.iloc[bg], rf.Ioff_A_per_um.iloc[bg], s=5, alpha=0.2, c=rf.SS_min_mV_per_dec.iloc[bg], cmap="plasma")
    axes[1].scatter(rf.Ion_A_per_um.iloc[pareto_idx], rf.Ioff_A_per_um.iloc[pareto_idx], s=14, c="k")
    axes[1].set_xscale("log")
    axes[1].set_yscale("log")
    axes[1].set_xlabel("Ion (A/um)")
    axes[1].set_ylabel("Ioff (A/um)")

    axes[2].scatter(rf.SS_min_mV_per_dec.iloc[bg], rf.Vth_V.iloc[bg], s=5, alpha=0.2, c=np.log10(rf.Ion_Ioff_ratio.iloc[bg]), cmap="viridis")
    axes[2].scatter(rf.SS_min_mV_per_dec.iloc[pareto_idx], rf.Vth_V.iloc[pareto_idx], s=14, c="k")
    axes[2].set_xlabel("SSmin (mV/dec)")
    axes[2].set_ylabel("Vth (V)")
    fig.suptitle("DG-TFET design space and Pareto-optimal candidates")
    fig.tight_layout()
    fig.savefig(GRAPHS / "pareto_front.png", dpi=160)
    plt.close(fig)

    summary["pareto_front_size"] = int(len(pareto_idx))
    summary["top_designs"] = int(len(top))
    (METRICS / "optimization_summary.json").write_text(json.dumps(summary, indent=2))

    print("validating top designs with Octave")
    val = validation_with_octave(top, sur)
    val.to_csv(PREDS / "optimized_designs_validation.csv", index=False)
    vmetrics = validation_metrics(val)
    (METRICS / "optimization_validation.json").write_text(
        json.dumps(vmetrics, indent=2)
    )
    ranked = val.sort_values("score_sim", ascending=False)
    summary["simulation_ranking"] = {
        "best_device_id": int(ranked.iloc[0]["device_id"]),
        "best_method": str(ranked.iloc[0]["method"]),
        "best_sim_score": float(ranked.iloc[0]["score_sim"]),
        "second_best_sim_score": float(ranked.iloc[1]["score_sim"]),
    }
    (METRICS / "optimization_summary.json").write_text(json.dumps(summary, indent=2))

    fig, axes = plt.subplots(1, 5, figsize=(18, 3.8))
    specs = [
        ("Ion_A_per_um", True, "Ion (A/um)"),
        ("Ioff_A_per_um", True, "Ioff (A/um)"),
        ("gm_max_S_per_um", True, "gm,max (S/um)"),
        ("Vth_V", False, "Vth (V)"),
        ("SS_min_mV_per_dec", False, "SSmin (mV/dec)"),
    ]
    for ax, (name, log_space, label) in zip(axes, specs):
        x = val[f"{name}_sim"].to_numpy()
        y = val[f"{name}_pred"].to_numpy()
        ax.scatter(x, y, s=35)
        lo, hi = min(x.min(), y.min()), max(x.max(), y.max())
        ax.plot([lo, hi], [lo, hi], "k--", lw=1)
        if log_space:
            ax.set_xscale("log")
            ax.set_yscale("log")
        ax.set_xlabel(f"Simulated {label}")
        ax.set_ylabel(f"Predicted {label}")
        ax.grid(alpha=0.25)
    fig.suptitle("Surrogate validation on optimized designs (THM-TFET re-simulation)")
    fig.tight_layout()
    fig.savefig(GRAPHS / "optimization_surrogate_validation.png", dpi=160)
    plt.close(fig)

    print(json.dumps(summary, indent=2))
    print(json.dumps(vmetrics, indent=2))


if __name__ == "__main__":
    main()
