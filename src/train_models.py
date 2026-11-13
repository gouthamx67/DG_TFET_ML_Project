"""Train and tune five regression models for DG-TFET targets.

Tasks
-----
fom    device figures of merit at each drain bias
curve  full log10(Id) versus Vgs, Vds, and design parameters

Models
------
polynomial, decision_tree, random_forest, lightgbm, ann
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from lightgbm import LGBMRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GridSearchCV, GroupKFold, RandomizedSearchCV
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import PolynomialFeatures, StandardScaler
from sklearn.linear_model import Ridge
from sklearn.tree import DecisionTreeRegressor

from ann_model import TorchMLPRegressor

PROJECT = Path(__file__).resolve().parents[1]
PROC = PROJECT / "data" / "processed"
MODELS = PROJECT / "models" / "saved_models"
METRICS = PROJECT / "results" / "metrics"
PREDS = PROJECT / "results" / "predictions"

SEED = 42
N_JOBS = 12

FOM_FEATURES = [
    "log10_lch", "log10_tox", "log10_tch", "eps_ox",
    "log10_Ns", "log10_Nd", "log10_Nch", "log10_NT", "Vds_V",
]
CURVE_FEATURES = [*FOM_FEATURES, "Vgs_V"]
FOM_TARGETS = [
    "log10_Ion", "log10_Ioff", "Vth_V", "log10_gm_max",
    "SS_min_mV_per_dec",
]
CURVE_TARGET = "log10_Id"

MODEL_NAMES = ["polynomial", "decision_tree", "random_forest", "lightgbm", "ann"]
TREE_MODELS = {"decision_tree", "random_forest", "lightgbm"}


def load_task(task: str) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, list[str], list[str]]:
    if task == "fom":
        train = pd.read_csv(PROC / "fom_train.csv")
        val = pd.read_csv(PROC / "fom_validation.csv")
        test = pd.read_csv(PROC / "fom_test.csv")
        return train, val, test, FOM_FEATURES, FOM_TARGETS
    train = pd.read_csv(PROC / "curves_train.csv")
    val = pd.read_csv(PROC / "curves_validation.csv")
    test = pd.read_csv(PROC / "curves_test.csv")
    return train, val, test, CURVE_FEATURES, [CURVE_TARGET]


def feature_matrix(df: pd.DataFrame, features: list[str], scaled: bool) -> np.ndarray:
    cols = [f"scaled_{f}" for f in features] if scaled else features
    return df[cols].to_numpy(dtype=float)


def regression_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    mse = mean_squared_error(y_true, y_pred)
    return {
        "r2": float(r2_score(y_true, y_pred)),
        "mae": float(mean_absolute_error(y_true, y_pred)),
        "mse": float(mse),
        "rmse": float(np.sqrt(mse)),
    }


def linear_scale_metrics(target: str, y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    if not target.startswith("log10_"):
        return {"r2_linear": np.nan, "rmse_linear": np.nan}
    yt = np.power(10.0, y_true)
    yp = np.power(10.0, y_pred)
    return {
        "r2_linear": float(r2_score(yt, yp)),
        "rmse_linear": float(np.sqrt(mean_squared_error(yt, yp))),
    }


def search_spaces(model: str, task: str) -> tuple[object, dict, int]:
    if model == "polynomial":
        pipe = Pipeline(
            [
                ("poly", PolynomialFeatures(include_bias=False)),
                ("ridge", Ridge()),
            ]
        )
        grid = {
            "poly__degree": [1, 2, 3],
            "ridge__alpha": [0.01, 0.1, 1.0, 10.0, 100.0],
        }
        return pipe, grid, 0
    if model == "decision_tree":
        est = DecisionTreeRegressor(random_state=SEED)
        dist = {
            "max_depth": [3, 5, 7, 10, 15, None],
            "min_samples_leaf": [1, 2, 5, 10, 20],
            "min_samples_split": [2, 5, 10, 20],
            "max_features": [None, "sqrt", 0.5],
        }
        return est, dist, 40
    if model == "random_forest":
        est = RandomForestRegressor(random_state=SEED, n_jobs=1)
        dist = {
            "n_estimators": [100, 200, 400],
            "max_depth": [5, 10, 20, None],
            "min_samples_leaf": [1, 2, 5, 10],
            "max_features": ["sqrt", 0.5, 1.0],
        }
        return est, dist, 12 if task == "fom" else 8
    if model == "lightgbm":
        est = LGBMRegressor(
            random_state=SEED,
            n_jobs=1,
            verbosity=-1,
            subsample_freq=1,
            max_bin=63,
        )
        dist = {
            "n_estimators": [100, 200, 400],
            "learning_rate": [0.01, 0.03, 0.05, 0.1],
            "num_leaves": [7, 15, 31],
            "min_child_samples": [5, 10, 20, 40],
            "subsample": [0.8, 1.0],
            "colsample_bytree": [0.8, 1.0],
            "reg_alpha": [0.0, 1e-3, 1e-2],
            "reg_lambda": [0.0, 1e-3, 1e-2],
        }
        return est, dist, 12 if task == "fom" else 8
    raise ValueError(model)


def train_sklearn(
    model: str,
    task: str,
    target: str,
    train: pd.DataFrame,
    val: pd.DataFrame,
    test: pd.DataFrame,
    features: list[str],
) -> tuple[dict, object, dict, pd.DataFrame]:
    scaled = model == "polynomial"
    X_train = feature_matrix(train, features, scaled)
    X_val = feature_matrix(val, features, scaled)
    X_test = feature_matrix(test, features, scaled)
    y_train = train[target].to_numpy()
    y_val = val[target].to_numpy()
    y_test = test[target].to_numpy()
    groups = train["device_id"].to_numpy()

    est, dist, n_iter = search_spaces(model, task)
    cv = GroupKFold(n_splits=5)
    if n_iter == 0:
        search = GridSearchCV(
            est, dist, scoring="r2", cv=cv, n_jobs=N_JOBS, refit=True
        )
    else:
        search = RandomizedSearchCV(
            est,
            dist,
            n_iter=n_iter,
            scoring="r2",
            cv=cv,
            n_jobs=N_JOBS,
            random_state=SEED,
            refit=True,
        )

    t0 = time.perf_counter()
    search.fit(X_train, y_train, groups=groups)
    seconds = time.perf_counter() - t0

    best = search.best_estimator_
    pred_val = best.predict(X_val)
    pred_test = best.predict(X_test)
    cv_idx = search.best_index_

    result = {
        "task": task,
        "target": target,
        "model": model,
        "cv_r2_mean": float(search.best_score_),
        "cv_r2_std": float(search.cv_results_["std_test_score"][cv_idx]),
        "val_r2": float(r2_score(y_val, pred_val)),
        "test_r2": float(r2_score(y_test, pred_test)),
        "test_mae": float(mean_absolute_error(y_test, pred_test)),
        "test_mse": float(mean_squared_error(y_test, pred_test)),
        "test_rmse": float(np.sqrt(mean_squared_error(y_test, pred_test))),
        "train_seconds": float(seconds),
        "best_params": json.dumps(search.best_params_, default=str),
        **linear_scale_metrics(target, y_test, pred_test),
    }

    preds = test[["device_id"]].copy()
    if task == "curve":
        preds["Vgs_V"] = test["Vgs_V"].to_numpy()
        preds["Vds_V"] = test["Vds_V"].to_numpy()
    else:
        preds["Vds_V"] = test["Vds_V"].to_numpy()
    preds["y_true"] = y_test
    preds["y_pred"] = pred_test
    preds["split"] = "test"
    return result, best, search.best_params_, preds


def ann_configs(task: str) -> list[dict]:
    if task == "fom":
        return [
            {"hidden_sizes": (128, 64), "dropout": 0.1, "lr": 1e-3,
             "batch_size": 256, "max_epochs": 300, "patience": 25},
            {"hidden_sizes": (256, 128, 64), "dropout": 0.1, "lr": 1e-3,
             "batch_size": 256, "max_epochs": 300, "patience": 25},
            {"hidden_sizes": (128, 128, 128), "dropout": 0.2, "lr": 5e-4,
             "batch_size": 256, "max_epochs": 300, "patience": 25},
        ]
    return [
        {"hidden_sizes": (256, 128, 64), "dropout": 0.1, "lr": 1e-3,
         "batch_size": 512, "max_epochs": 120, "patience": 12},
        {"hidden_sizes": (128, 64, 32), "dropout": 0.1, "lr": 1e-3,
         "batch_size": 512, "max_epochs": 120, "patience": 12},
    ]


def train_ann(
    task: str,
    target: str,
    train: pd.DataFrame,
    val: pd.DataFrame,
    test: pd.DataFrame,
    features: list[str],
) -> tuple[dict, object, dict, pd.DataFrame, dict]:
    X_train = feature_matrix(train, features, True)
    X_val = feature_matrix(val, features, True)
    X_test = feature_matrix(test, features, True)
    y_train = train[target].to_numpy()
    y_val = val[target].to_numpy()
    y_test = test[target].to_numpy()

    y_scaler = StandardScaler().fit(y_train.reshape(-1, 1))
    y_train_s = y_scaler.transform(y_train.reshape(-1, 1)).ravel()
    y_val_s = y_scaler.transform(y_val.reshape(-1, 1)).ravel()

    t0 = time.perf_counter()
    best_model = None
    best_val = float("inf")
    best_cfg = None
    best_history = None
    for i, cfg in enumerate(ann_configs(task)):
        model = TorchMLPRegressor(seed=SEED + i, **cfg)
        model.fit(X_train, y_train_s, X_val, y_val_s)
        pred_val_s = model.predict(X_val)
        val_mse = mean_squared_error(y_val_s, pred_val_s)
        if val_mse < best_val:
            best_val = val_mse
            best_model = model
            best_cfg = cfg
            best_history = model.history
    seconds = time.perf_counter() - t0

    pred_test_s = best_model.predict(X_test)
    pred_test = y_scaler.inverse_transform(pred_test_s.reshape(-1, 1)).ravel()
    pred_val = y_scaler.inverse_transform(
        best_model.predict(X_val).reshape(-1, 1)
    ).ravel()

    result = {
        "task": task,
        "target": target,
        "model": "ann",
        "cv_r2_mean": np.nan,
        "cv_r2_std": np.nan,
        "val_r2": float(r2_score(y_val, pred_val)),
        "test_r2": float(r2_score(y_test, pred_test)),
        "test_mae": float(mean_absolute_error(y_test, pred_test)),
        "test_mse": float(mean_squared_error(y_test, pred_test)),
        "test_rmse": float(np.sqrt(mean_squared_error(y_test, pred_test))),
        "train_seconds": float(seconds),
        "best_params": json.dumps({k: str(v) for k, v in best_cfg.items()}),
        **linear_scale_metrics(target, y_test, pred_test),
    }

    preds = test[["device_id"]].copy()
    if task == "curve":
        preds["Vgs_V"] = test["Vgs_V"].to_numpy()
        preds["Vds_V"] = test["Vds_V"].to_numpy()
    else:
        preds["Vds_V"] = test["Vds_V"].to_numpy()
    preds["y_true"] = y_test
    preds["y_pred"] = pred_test
    preds["split"] = "test"

    extras = {
        "y_scaler": y_scaler,
        "history": best_history,
        "config": {k: str(v) for k, v in best_cfg.items()},
        "all_val_mse": float(best_val),
    }
    return result, best_model, best_cfg, preds, extras


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tasks", default="fom,curve")
    ap.add_argument("--models", default=",".join(MODEL_NAMES))
    ap.add_argument("--targets", default="all")
    ap.add_argument("--overwrite", action="store_true")
    args = ap.parse_args()

    MODELS.mkdir(parents=True, exist_ok=True)
    METRICS.mkdir(parents=True, exist_ok=True)
    PREDS.mkdir(parents=True, exist_ok=True)

    rows = []
    for task in [t.strip() for t in args.tasks.split(",") if t.strip()]:
        train, val, test, features, targets = load_task(task)
        if args.targets != "all":
            wanted = {t.strip() for t in args.targets.split(",")}
            targets = [t for t in targets if t in wanted]
        print(f"\n=== task {task}: {len(train)} train / {len(val)} val / {len(test)} test")
        for target in targets:
            print(f"\n-- target {target}")
            for model in [m.strip() for m in args.models.split(",") if m.strip()]:
                out_stem = f"{task}_{target}_{model}"
                metrics_path = METRICS / f"{out_stem}.json"
                pred_path = PREDS / f"{out_stem}.csv"
                model_path = MODELS / f"{out_stem}.joblib"
                if not args.overwrite and metrics_path.exists() and pred_path.exists():
                    print(f"   {model}: cached")
                    rows.append(json.loads(metrics_path.read_text()))
                    continue
                print(f"   {model}: training")
                if model == "ann":
                    result, best, params, preds, extras = train_ann(
                        task, target, train, val, test, features
                    )
                    joblib.dump(best, model_path)
                    joblib.dump(extras["y_scaler"], MODELS / f"{out_stem}_target_scaler.joblib")
                    (METRICS / f"{out_stem}_history.json").write_text(
                        json.dumps(extras["history"])
                    )
                    (METRICS / f"{out_stem}_config.json").write_text(
                        json.dumps(extras["config"], indent=2)
                    )
                else:
                    result, best, params, preds = train_sklearn(
                        model, task, target, train, val, test, features
                    )
                    joblib.dump(best, model_path)
                metrics_path.write_text(json.dumps(result, indent=2))
                preds.to_csv(pred_path, index=False)
                rows.append(result)
                print(
                    f"     val R2={result['val_r2']:.4f} "
                    f"test R2={result['test_r2']:.4f} "
                    f"({result['train_seconds']:.1f} s)"
                )

    if rows:
        df = pd.DataFrame(rows)
        out = METRICS / "model_comparison.csv"
        if out.exists():
            old = pd.read_csv(out)
            df = pd.concat([old, df], ignore_index=True)
            df = df.drop_duplicates(["task", "target", "model"], keep="last")
        df.to_csv(out, index=False)
        print(f"\nwrote {out}")


if __name__ == "__main__":
    main()
