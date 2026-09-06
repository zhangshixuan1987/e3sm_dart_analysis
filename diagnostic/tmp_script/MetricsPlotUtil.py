import os
import time
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from scipy.ndimage import gaussian_filter
import cartopy.crs as ccrs
import cartopy.feature as cfeature

import colorcet as cc

class SpatialMetricPlotter:
    def __init__(self, projection=ccrs.PlateCarree()):
        self.projection = projection

    def plot_grid_metrics(self, out_path, fig_path, model_dict, var_dict,
                          data_key, metric_key, mask_key=None, fig_key="Metric",
                          sig_level=0.1, season="ANN", cmap=None):

        os.makedirs(fig_path, exist_ok=True)

        if cmap is None:
            from cmocean import cm as cc
            cmap = cc.balance

        fontz = 14
        tick_fontz = 12
        nrow, ncol = len(var_dict), len(model_dict)
        scale = nrow / 4.0

        fig = plt.figure(figsize=(4.5 * ncol + 2, 3.0 * nrow))
        start_time = time.time()

        for i, (var, vinfo) in enumerate(var_dict.items()):
            levels = vinfo["level"]
            clevels = np.unique(np.sort(np.array(levels)))
            norm = BoundaryNorm(boundaries=clevels, ncolors=256, extend='both')
            cf_last = None

            for j, model in enumerate(model_dict):
                ax = plt.subplot(nrow, ncol, i * ncol + j + 1, projection=self.projection)
                nc_file = os.path.join(out_path, f"{model}_{data_key}.nc")

                if not os.path.exists(nc_file):
                    ax.set_title(f"{model}\n[Missing]", fontsize=fontz)
                    ax.axis("off")
                    continue

                try:
                    ds = xr.open_dataset(nc_file)
                except Exception:
                    ax.set_title(f"{model}\n[Read Error]", fontsize=fontz)
                    ax.axis("off")
                    continue

                if metric_key not in ds:
                    ax.set_title(f"{model}\n[No {metric_key}]", fontsize=fontz)
                    ax.axis("off")
                    continue

                metric = ds[metric_key].sel(var=var) if "var" in ds[metric_key].dims else ds[metric_key]
                mask = ds[mask_key].sel(var=var) if (mask_key and mask_key in ds) else None

                if (metric.lon > 180).any():
                    metric = metric.assign_coords(lon=((metric.lon + 180) % 360) - 180).sortby('lon')
                    if mask is not None:
                        mask = mask.assign_coords(lon=((mask.lon + 180) % 360) - 180).sortby('lon')

                # Smooth metric field
                smoothed = xr.apply_ufunc(
                    gaussian_filter, metric,
                    kwargs={"sigma": 1.0},
                    input_core_dims=[["lat", "lon"]],
                    output_core_dims=[["lat", "lon"]],
                    vectorize=True, dask="parallelized",
                    output_dtypes=[metric.dtype]
                )

                cf = ax.contourf(smoothed.lon, smoothed.lat, smoothed,
                                 levels=clevels, cmap=cmap, norm=norm, extend="both",
                                 transform=ccrs.PlateCarree())
                cf_last = cf

                # Significance hatching
                if mask is not None:
                    sig_mask = xr.where(mask < sig_level, 1, np.nan)
                    ax.contourf(sig_mask.lon, sig_mask.lat, sig_mask,
                                levels=[0, 2], colors='none', hatches=['..'],
                                transform=ccrs.PlateCarree())

                ax.coastlines(linewidth=0.5)
                ax.add_feature(cfeature.BORDERS, linewidth=0.3)

                gl = ax.gridlines(draw_labels=True, linewidth=0.2, color='gray', linestyle='--')
                gl.top_labels = False
                gl.right_labels = False
                gl.xlabel_style = {'size': tick_fontz}
                gl.ylabel_style = {'size': tick_fontz}

                panel_label = f"{chr(97 + i)}{j + 1}"
                ax.set_title(f"({panel_label}) {model_dict[model]}", loc="left", fontsize=fontz)
                ax.set_title(vinfo['alias'], loc="right", fontsize=fontz)

            # Row-wise colorbar
            if cf_last:
                cbar_ax = fig.add_axes([0.93, 0.78 - i * 0.23 / scale - 0.3 * (1 - scale), 0.014, 0.17 / scale])
                cbar = fig.colorbar(cf_last, cax=cbar_ax, ticks=clevels)
                cbar.set_label(f"{vinfo['alias']} ({vinfo['unit']})", fontsize=fontz)
                cbar.ax.tick_params(labelsize=tick_fontz)

                for spine in cbar.ax.spines.values():
                    spine.set_visible(True)
                    spine.set_linewidth(1.0)
                    spine.set_edgecolor("black")

        plt.subplots_adjust(left=0.06, right=0.90, top=0.95, bottom=0.08, hspace=0.2, wspace=0.15)
        fig_file = os.path.join(fig_path, f"surface_metric_grid_{season}_{fig_key}.pdf")
        plt.savefig(fig_file, dpi=300, bbox_inches="tight")
        plt.close()
        print(f"[INFO] Multi-variable metric plot saved to: {fig_file} in {time.time() - start_time:.2f} sec.")
