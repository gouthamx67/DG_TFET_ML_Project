"""Evaluate trained models, build comparison tables, and generate plots."""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import r2_score

PROJECT = Path(__file__).resolve().parents[1]
PROC = PROJECT / "data" / "processed"
MODELS = PROJECT / "models" / "saved_models"
METRICS = PROJECT / "results" / "metrics"
PREDS = PROJECT / "results" / "predictions"
GRAPHS = PROJECT / "results" / "graphs"

FOM_FEATURES = [
    "log10_lch", "log10_tox", "log10_tch", "eps_ox",
    "log10_Ns", "log10_Nd", "log10_Nch", "log10_NT", "Vds_V",
]
CURVE_FEATURES = [*FOM_FEATURES, "Vgs_V"]

DISPLAY = {
    "log10_Ion": "log10(Ion)",
    "log10_Ioff": "log10(Ioff)",
    "Vth_V": "Vth (V)",
    "log10_gm_max": "log10(gm,max)",
    "SS_min_mV_per_dec": "SSmin (mV/dec)",
    "log10_Id": "log10(Id)",
}

COLORS = {
    "polynomial": "#4C72B0",
    "decision_tree": "#DD8452",
    "random_forest": "#55A868",
    "lightgbm": "#C44E52",
    "ann": "#8172B3",
}


def load_metrics() -> pd.DataFrame:
    return pd.read_csv(METRICS / "model_comparison.csv")


def select_best(metrics: pd.DataFrame) -> pd.DataFrame:
    idx = metrics.groupby(["task", "target"])["val_r2"].idxmax()
    best = metrics.loc[idx].copy()
    best = best.sort_values(["task", "target"])
    best.to_csv(METRICS / "best_models.csv", index=False)
    return best


def markdown_table(metrics: pd.DataFrame) -> str:
    lines = [
        "| Task | Target | Model | Val R2 | Test R2 | Test MAE | Test RMSE | Train s |",
        "|---|---|---|---:|---:|---:|---:|---:|",
    ]
    for _, r in metrics.sort_values(["task", "target", "val_r2"], ascending=[True, True, False]).iterrows():
        lines.append(
            f"| {r.task} | {DISPLAY.get(r.target, r.target)} | {r.model} | "
            f"{r.val_r2:.4f} | {r.test_r2:.4f} | {r.test_mae:.4g} | "
            f"{r.test_rmse:.4g} | {r.train_seconds:.1f} |"
        )
    return "\n".join(lines) + "\n"


def plot_grouped_r2(metrics: pd.DataFrame) -> None:
    fom = metrics[metrics.task == "fom"]
    targets = list(DISPLAY.keys())[:5]
    models = list(COLORS)
    x = np.arange(len(targets))
    width = 0.15
    fig, ax = plt.subplots(figsize=(12, 5))
    for j, model in enumerate(models):
        vals = [
            fom[(fom.target == t) & (fom.model == model)]["test_r2"].iloc[0]
            for t in targets
        ]
        ax.bar(x + (j - 2) * width, vals, width, label=model, color=COLORS[model])
    ax.set_xticks(x)
    ax.set_xticklabels([DISPLAY[t] for t in targets])
    ax.set_ylabel("Test R²")
    ax.set_ylim(0.6, 1.01)
    ax.set_title("DG-TFET figure-of-merit models: test R²")
    ax.legend(ncol=5, fontsize=8, loc="lower center")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(GRAPHS / "fom_test_r2_by_target.png", dpi=160)
    plt.close(fig)

    curve = metrics[metrics.task == "curve"]
    fig, ax = plt.subplots(figsize=(8, 4))
    vals = [curve[curve.model == m]["test_r2"].iloc[0] for m in models]
    ax.bar(models, vals, color=[COLORS[m] for m in models])
    ax.set_ylim(0.94, 1.005)
    ax.set_ylabel("Test R²")
    ax.set_title("DG-TFET I-V curve model: test R²")
    for i, v in enumerate(vals):
        ax.text(i, v + 0.001, f"{v:.4f}", ha="center", fontsize=8)
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(GRAPHS / "curve_test_r2.png", dpi=160)
    plt.close(fig)


def plot_parity_and_residuals(best: pd.DataFrame) -> None:
    for _, r in best.iterrows():
        pred_path = PREDS / f"{r.task}_{r.target}_{r.model}.csv"
        if not pred_path.exists():
            continue
        df = pd.read_csv(pred_path)
        yt = df["y_true"].to_numpy()
        yp = df["y_pred"].to_numpy()
        label = DISPLAY.get(r.target, r.target)

        fig, ax = plt.subplots(figsize=(5, 5))
        ax.scatter(yt, yp, s=8, alpha=0.35, color=COLORS.get(r.model, "#333"))
        lo = min(yt.min(), yp.min())
        hi = max(yt.max(), yp.max())
        ax.plot([lo, hi], [lo, hi], "k--", lw=1)
        ax.set_xlabel(f"True {label}")
        ax.set_ylabel(f"Predicted {label}")
        ax.set_title(f"{label}: {r.model} (test R²={r.test_r2:.4f})")
        ax.grid(alpha=0.25)
        fig.tight_layout()
        fig.savefig(GRAPHS / f"parity_{r.task}_{r.target}.png", dpi=160)
        plt.close(fig)

        fig, ax = plt.subplots(figsize=(6, 3.5))
        resid = yp - yt
        ax.scatter(yt, resid, s=8, alpha=0.35, color=COLORS.get(r.model, "#333"))
        ax.axhline(0, color="k", lw=1, ls="--")
        ax.set_xlabel(f"True {label}")
        ax.set_ylabel("Residual (pred - true)")
        ax.set_title(f"{label}: residuals ({r.model})")
        ax.grid(alpha=0.25)
        fig.tight_layout()
        fig.savefig(GRAPHS / f"residuals_{r.task}_{r.target}.png", dpi=160)
        plt.close(fig)


def plot_ann_losses() -> None:
    histories = sorted(METRICS.glob("*_ann_history.json"))
    if not histories:
        return
    fig, axes = plt.subplots(2, 3, figsize=(12, 6))
    axes = axes.ravel()
    for ax, path in zip(axes, histories):
        h = json.loads(path.read_text())
        ax.plot(h["train_loss"], label="train")
        ax.plot(h["val_loss"], label="validation")
        ax.set_yscale("log")
        ax.set_title(path.stem.replace("_ann_history", ""), fontsize=8)
        ax.set_xlabel("Epoch")
        ax.set_ylabel("MSE (scaled)")
        ax.grid(alpha=0.25)
        ax.legend(fontsize=7)
    for ax in axes[len(histories) :]:
        ax.axis("off")
    fig.tight_layout()
    fig.savefig(GRAPHS / "ann_loss_curves.png", dpi=160)
    plt.close(fig)


def manual_permutation_importance(
    predict_fn, X: np.ndarray, y: np.ndarray, n_repeats: int, seed: int = 42
) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    baseline = r2_score(y, predict_fn(X))
    imp = np.zeros((X.shape[1], n_repeats), dtype=float)
    for j in range(X.shape[1]):
        for k in range(n_repeats):
            Xp = X.copy()
            rng.shuffle(Xp[:, j])
            imp[j, k] = baseline - r2_score(y, predict_fn(Xp))
    return imp.mean(axis=1), imp.std(axis=1)


def compute_importance(best: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for _, r in best.iterrows():
        if r.task == "fom":
            df = pd.read_csv(PROC / "fom_test.csv")
            features = FOM_FEATURES
        else:
            df = pd.read_csv(PROC / "curves_test.csv")
            features = CURVE_FEATURES
        model = joblib.load(MODELS / f"{r.task}_{r.target}_{r.model}.joblib")
        target_scaler = None
        if r.model == "ann":
            target_scaler = joblib.load(
                MODELS / f"{r.task}_{r.target}_{r.model}_target_scaler.joblib"
            )

        def predict_fn(X, model=model, target_scaler=target_scaler):
            pred = model.predict(X)
            if target_scaler is not None:
                pred = target_scaler.inverse_transform(
                    np.asarray(pred).reshape(-1, 1)
                ).ravel()
            return pred

        scaled = r.model in {"polynomial", "ann"}
        cols = [f"scaled_{f}" for f in features] if scaled else features
        X = df[cols].to_numpy(dtype=float)
        y = df[r.target].to_numpy(dtype=float)
        means, stds = manual_permutation_importance(
            predict_fn, X, y, n_repeats=5 if r.task == "curve" else 10
        )
        for f, m, s in zip(features, means, stds):
            rows.append(
                {
                    "task": r.task,
                    "target": r.target,
                    "model": r.model,
                    "feature": f,
                    "importance_mean": float(m),
                    "importance_std": float(s),
                }
            )

        order = np.argsort(means)[::-1][:10]
        fig, ax = plt.subplots(figsize=(6, 4))
        ax.barh(
            [features[i] for i in order][::-1],
            [means[i] for i in order][::-1],
            xerr=[stds[i] for i in order][::-1],
            color=COLORS.get(r.model, "#333"),
            alpha=0.85,
        )
        ax.set_xlabel("Permutation importance (R² drop)")
        ax.set_title(
            f"{DISPLAY.get(r.target, r.target)}: {r.model} importance"
        )
        ax.grid(axis="x", alpha=0.25)
        fig.tight_layout()
        fig.savefig(
            GRAPHS / f"importance_{r.task}_{r.target}.png", dpi=160
        )
        plt.close(fig)

    out = pd.DataFrame(rows)
    out.to_csv(METRICS / "feature_importance.csv", index=False)
    return out


def main() -> None:
    GRAPHS.mkdir(parents=True, exist_ok=True)
    metrics = load_metrics()
    best = select_best(metrics)
    (METRICS / "model_comparison.md").write_text(markdown_table(metrics))
    plot_grouped_r2(metrics)
    plot_parity_and_residuals(best)
    plot_ann_losses()
    compute_importance(best)
    print(f"wrote evaluation tables and plots to {GRAPHS}")
    print(best[["task", "target", "model", "val_r2", "test_r2"]].to_string(index=False))


if __name__ == "__main__":
    main()
