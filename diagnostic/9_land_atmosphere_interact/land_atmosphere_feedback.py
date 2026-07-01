import numpy as np
import xarray as xr
from typing import Dict, List, Union
from scipy.stats import pearsonr

class LandAtmosphereFeedbackAnalyzer:
    def __init__(self, land_mask: xr.DataArray = None, alpha: float = 0.05, n_bootstrap: int = 1000):
        self.land_mask = land_mask
        self.alpha = alpha
        self.n_bootstrap = n_bootstrap

    def _bootstrap_corr(self, x, y):
        idx = np.arange(len(x))
        boot_corrs = []
        for _ in range(self.n_bootstrap):
            sample_idx = np.random.choice(idx, size=len(idx), replace=True)
            xr_ = x[sample_idx]
            yr_ = y[sample_idx]
            if np.std(xr_) > 0 and np.std(yr_) > 0:
                boot_corrs.append(np.corrcoef(xr_, yr_)[0, 1])
        if len(boot_corrs) == 0:
            return np.nan, np.nan, np.nan
        boot_corrs = np.array(boot_corrs)
        lower = np.percentile(boot_corrs, 100 * (self.alpha / 2))
        upper = np.percentile(boot_corrs, 100 * (1 - self.alpha / 2))
        return np.mean(boot_corrs), lower, upper

    def compute_lag_correlation_curve(
        self,
        model_data: Dict[str, List[xr.Dataset]],
        var_land: str,
        var_atm: str,
        lags: List[int],
    ) -> Dict[str, Dict[int, Dict[str, float]]]:
        results = {}
        for exp, members in model_data.items():
            exp_result = {}
            for lag in lags:
                rs = []
                for mem in members:
                    x = mem[var_land]
                    y = mem[var_atm]

                    if lag > 0:
                        x = x.isel(time=slice(0, -lag))
                        y = y.isel(time=slice(lag, None))
                    elif lag < 0:
                        x = x.isel(time=slice(-lag, None))
                        y = y.isel(time=slice(0, lag))

                    if self.land_mask is not None:
                        x = x.where(self.land_mask)
                        y = y.where(self.land_mask)

                    x = x.values.flatten()
                    y = y.values.flatten()
                    mask = np.isfinite(x) & np.isfinite(y)
                    if np.sum(mask) > 30:
                        r_mean, r_low, r_high = self._bootstrap_corr(x[mask], y[mask])
                        rs.append((r_mean, r_low, r_high))

                rs = np.array(rs)
                exp_result[lag] = {
                    "mean": float(np.nanmean(rs[:, 0])),
                    "low": float(np.nanmean(rs[:, 1])),
                    "high": float(np.nanmean(rs[:, 2])),
                }
            results[exp] = exp_result
        return results

    def compute_spatial_map(self, model_data: List[xr.Dataset], var_land: str, var_atm: str, lag: int) -> xr.DataArray:
        maps = []
        for mem in model_data:
            x = mem[var_land]
            y = mem[var_atm]

            if lag > 0:
                x = x.isel(time=slice(0, -lag))
                y = y.isel(time=slice(lag, None))
            elif lag < 0:
                x = x.isel(time=slice(-lag, None))
                y = y.isel(time=slice(0, lag))

            rmap = xr.corr(x, y, dim="time")
            if self.land_mask is not None:
                rmap = rmap.where(self.land_mask)
            maps.append(rmap)
        return xr.concat(maps, dim="member").mean(dim="member")

    def save_to_netcdf(self, data: Dict[str, Dict[int, Dict[str, float]]], filename: str):
        exp_list = []
        for exp, lag_dict in data.items():
            lags = list(lag_dict.keys())
            means = [lag_dict[lag]["mean"] for lag in lags]
            lows = [lag_dict[lag]["low"] for lag in lags]
            highs = [lag_dict[lag]["high"] for lag in lags]
            ds = xr.Dataset({
                f"{exp}_mean": xr.DataArray(means, coords={"lag": lags}, dims=["lag"]),
                f"{exp}_low": xr.DataArray(lows, coords={"lag": lags}, dims=["lag"]),
                f"{exp}_high": xr.DataArray(highs, coords={"lag": lags}, dims=["lag"]),
            })
            exp_list.append(ds)
        final_ds = xr.merge(exp_list)
        final_ds.to_netcdf(filename)


# --- Plotting Utilities ---

def plot_lag_with_ci(results_dict: Dict[str, Dict[int, Dict[str, float]]], title="Land–Atmosphere Lag Correlation"):
    import matplotlib.pyplot as plt

    plt.figure(figsize=(8, 5))
    for exp, lag_r in results_dict.items():
        lags = sorted(lag_r.keys())
        means = [lag_r[l]["mean"] for l in lags]
        lows = [lag_r[l]["low"] for l in lags]
        highs = [lag_r[l]["high"] for l in lags]
        plt.plot(lags, means, label=exp)
        plt.fill_between(lags, lows, highs, alpha=0.2)

    plt.axvline(0, linestyle="--", color="gray")
    plt.xlabel("Lag (hours)")
    plt.ylabel("Correlation")
    plt.title(title)
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


def plot_feedback_map_with_sig(rmap: xr.DataArray, threshold: float = 0.2, title="Spatial Feedback Map"):
    import matplotlib.pyplot as plt
    import cartopy.crs as ccrs

    sig = np.abs(rmap) >= threshold

    fig = plt.figure(figsize=(10, 5))
    ax = plt.axes(projection=ccrs.PlateCarree())
    rmap.plot(ax=ax, transform=ccrs.PlateCarree(), cmap='RdBu_r', vmin=-1, vmax=1, add_colorbar=True)
    sig.plot.contour(ax=ax, levels=[0.5], colors='black', linewidths=0.5, transform=ccrs.PlateCarree())
    ax.coastlines()
    ax.set_title(title)
    plt.show()

