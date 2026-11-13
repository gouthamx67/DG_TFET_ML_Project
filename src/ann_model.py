"""Small PyTorch MLP regressor with early stopping and loss history."""

from __future__ import annotations

import copy
import random

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader, TensorDataset


class TorchMLPRegressor:
    def __init__(
        self,
        hidden_sizes: tuple[int, ...] = (128, 64, 32),
        dropout: float = 0.1,
        lr: float = 1e-3,
        weight_decay: float = 1e-5,
        batch_size: int = 256,
        max_epochs: int = 300,
        patience: int = 25,
        seed: int = 42,
        device: str | None = None,
    ) -> None:
        self.hidden_sizes = tuple(hidden_sizes)
        self.dropout = dropout
        self.lr = lr
        self.weight_decay = weight_decay
        self.batch_size = batch_size
        self.max_epochs = max_epochs
        self.patience = patience
        self.seed = seed
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model: nn.Sequential | None = None
        self.history: dict[str, list[float]] = {"train_loss": [], "val_loss": []}

    def _build(self, n_features: int) -> nn.Sequential:
        layers: list[nn.Module] = []
        prev = n_features
        for h in self.hidden_sizes:
            layers.extend(
                [nn.Linear(prev, h), nn.ReLU(), nn.Dropout(self.dropout)]
            )
            prev = h
        layers.append(nn.Linear(prev, 1))
        return nn.Sequential(*layers)

    def fit(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
    ) -> "TorchMLPRegressor":
        random.seed(self.seed)
        np.random.seed(self.seed)
        torch.manual_seed(self.seed)
        torch.backends.cudnn.deterministic = True

        self.model = self._build(X_train.shape[1]).to(self.device)
        optim = torch.optim.Adam(
            self.model.parameters(),
            lr=self.lr,
            weight_decay=self.weight_decay,
        )
        loss_fn = nn.MSELoss()

        train_ds = TensorDataset(
            torch.tensor(X_train, dtype=torch.float32),
            torch.tensor(y_train.reshape(-1, 1), dtype=torch.float32),
        )
        train_loader = DataLoader(
            train_ds, batch_size=self.batch_size, shuffle=True
        )
        X_val_t = torch.tensor(X_val, dtype=torch.float32, device=self.device)
        y_val_t = torch.tensor(
            y_val.reshape(-1, 1), dtype=torch.float32, device=self.device
        )

        best_val = float("inf")
        best_state = None
        bad_epochs = 0

        for _ in range(self.max_epochs):
            self.model.train()
            batch_losses = []
            for xb, yb in train_loader:
                xb = xb.to(self.device)
                yb = yb.to(self.device)
                optim.zero_grad()
                loss = loss_fn(self.model(xb), yb)
                loss.backward()
                optim.step()
                batch_losses.append(float(loss.detach().cpu()))

            self.model.eval()
            with torch.no_grad():
                val_loss = float(loss_fn(self.model(X_val_t), y_val_t).cpu())

            self.history["train_loss"].append(float(np.mean(batch_losses)))
            self.history["val_loss"].append(val_loss)

            if val_loss < best_val - 1e-7:
                best_val = val_loss
                best_state = copy.deepcopy(self.model.state_dict())
                bad_epochs = 0
            else:
                bad_epochs += 1
                if bad_epochs >= self.patience:
                    break

        if best_state is not None:
            self.model.load_state_dict(best_state)
        return self

    def predict(self, X: np.ndarray) -> np.ndarray:
        if self.model is None:
            raise RuntimeError("model is not fitted")
        self.model.eval()
        with torch.no_grad():
            X_t = torch.tensor(X, dtype=torch.float32, device=self.device)
            return self.model(X_t).cpu().numpy().ravel()
