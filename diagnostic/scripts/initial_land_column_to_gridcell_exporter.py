# column_to_gridcell_exporter.py
# -*- coding: utf-8 -*-
"""
Column→Gridcell exporter for ELM/CLM restarts
---------------------------------------------
Step 1 only: aggregate restart *columns* to *gridcells* and save a NetCDF.
Later, you can regrid this gridcell file with ncremap.

Features
- Area-weighted mean for intensive variables (default)
- Sum for extensive variables (configurable per-variable)
- Handles layered variables (column, lev*) with level-preserving aggregation
- Honors cols1d_active==1 if present
- Carries source grid description (lon/lat, plus lon_b/lat_b/area/frac if available)
- Compression and chunk-size control
- Simple CLI

Examples
--------
# Aggregate a few vars with defaults (mean):
python column_to_gridcell_exporter.py \
  --restart ELM_restart.nc \
  --src-domain land_domain.nc \
  --out agg_gridcell.nc \
  --vars H2OSOI TSA SOILM

# Specify that some vars should be summed (extensive):
python column_to_gridcell_exporter.py \
  --restart ELM_restart.nc \
  --src-domain land_domain.nc \
  --out agg_gridcell.nc \
  --vars H2OSOI TSA TOT_WATER \
  --sum-vars TOT_WATER

# Auto-pick all numeric 'column' vars:
python column_to_gridcell_exporter.py \
  --restart ELM_restart.nc \
  --src-domain land_domain.nc \
  --out agg_gridcell.nc
"""
from __future__ import annotations
import argparse
import numpy as np
import xarray as xr
import warnings
from typing import Iterable, Dict, List, Optional


class ColumnToGridcellExporter:
    col2gc_name = "cols1d_gridcell_index"
    col_area_candidates = ("cols1d_areai", "cols1d_area", "col_area")
    lon_candidates = ("grid1d_lon", "lon", "gridcell_lon", "xc")
    lat_candidates = ("grid1d_lat", "lat", "gridcell_lat", "yc")

    def __init__(self, rst_path: str, src_domain_path: str):
        self.rst = xr.open_dataset(rst_path, decode_timedelta=False)
        self.src = xr.open_dataset(src_domain_path)

        # ---- discover gridcell centers ----
        self.lon_gc, self.lat_gc = self._find_lonlat(self.src)
        self.ngc = int(self.lon_gc.size)

        # ---- column → gridcell index, robust 1→0 base normalization ----
        if self.col2gc_name not in self.rst:
            raise KeyError(f"'{self.col2gc_name}' not found in restart.")
        col2gc = np.asarray(self.rst[self.col2gc_name].values, dtype=float).ravel()
        finite = np.isfinite(col2gc)
        if finite.any():
            if (np.nanmin(col2gc[finite]) >= 1.0) and np.isclose(np.nanmax(col2gc[finite]), float(self.ngc)):
                col2gc = col2gc - 1.0
        self.col2gc = col2gc

        # ---- active mask (optional) ----
        self.active = None
        if "cols1d_active" in self.rst:
            self.active = (np.asarray(self.rst["cols1d_active"].values, dtype=float).ravel() == 1.0)

        # ---- in-range valid mask ----
        in_range = (self.col2gc >= 0) & (self.col2gc < self.ngc)
        valid = np.isfinite(self.col2gc) & in_range
        if self.active is not None:
            valid &= self.active
        self.valid = valid
        self.col2gc_valid = self.col2gc[self.valid].astype(np.int64)

        # ---- optional column areas for weighting ----
        self.col_area = None
        for nm in self.col_area_candidates:
            if nm in self.rst.variables:
                self.col_area = np.asarray(self.rst[nm].values, dtype=float).ravel()[self.valid]
                break

        # ---- optional grid polygons & metrics (useful if you conservatively regrid later) ----
        self.xv = self.src.get("xv")   # corners (various shapes)
        self.yv = self.src.get("yv")
        self.area = self.src.get("area")
        self.frac = self.src.get("frac")

    # ---------------- public API ----------------
    def export(
        self,
        out_path: str,
        varnames: Optional[Iterable[str]] = None,
        *,
        sum_vars: Optional[Iterable[str]] = None,
        compress: bool = True,
        chunks: Optional[int] = None,
    ) -> xr.Dataset:
        """
        Aggregate chosen column variables to gridcells and write a NetCDF with:
          - lon(gridcell), lat(gridcell)
          - optional lon_b/lat_b(gridcell,nv), area(gridcell), frac(gridcell)
          - aggregated variables on gridcell (and lev* preserved if layered)

        Parameters
        ----------
        varnames : list[str] or None
            If None, auto-pick all numeric vars that include 'column'.
        sum_vars : list[str] or None
            Variables to aggregate by *sum* (extensive). Others use area-weighted mean.
        compress : bool
            Enable zlib compression (complevel=3).
        chunks : int or None
            If provided, set NetCDF chunksizes along 'gridcell' for data vars.
        """
        if varnames is None:
            varnames = self._auto_pick_column_vars()
        varnames = list(varnames)
        sum_set = set(sum_vars or [])

        data_vars = {}
        for v in varnames:
            da = self.rst[v]
            if "column" not in da.dims:
                warnings.warn(f"Skipping '{v}': no 'column' dimension.")
                continue
            if v in sum_set:
                agg = self._aggregate_column_sum(da)
            else:
                agg = self._aggregate_column_mean(da)
            agg.name = v
            # propagate a few attrs
            keep = {k: da.attrs[k] for k in ("units", "long_name", "standard_name") if k in da.attrs}
            agg.attrs.update(keep)
            data_vars[v] = agg

        # grid description
        coords = {
            "lon": (("gridcell",), self.lon_gc.values, {"standard_name": "longitude", "units": "degrees_east"}),
            "lat": (("gridcell",), self.lat_gc.values, {"standard_name": "latitude",  "units": "degrees_north"}),
        }
        if self._has_corners_1d():
            coords["lon_b"] = (("gridcell","nv"), self._as_1d_corners(self.xv).values, {"long_name": "longitude of cell vertices", "units": "degrees_east"})
            coords["lat_b"] = (("gridcell","nv"), self._as_1d_corners(self.yv).values, {"long_name": "latitude of cell vertices",  "units": "degrees_north"})

        # optional metrics as variables
        if self._has_metric_1d(self.area):
            data_vars["area"] = (("gridcell",), self._as_1d_metric(self.area).values, {"long_name":"cell area"})
        if self._has_metric_1d(self.frac):
            data_vars["frac"] = (("gridcell",), self._as_1d_metric(self.frac).values, {"long_name":"cell fraction"})

        ds_out = xr.Dataset(data_vars=data_vars, coords=coords)
        ds_out.attrs.update({
            "title": "ELM/CLM restart columns aggregated to gridcells",
            "notes": "Use ncremap later to regrid this gridcell file to a target grid.",
        })

        # NetCDF encoding
        encoding: Dict[str, Dict] = {}
        if compress:
            for vn in ds_out.data_vars:
                encoding[vn] = {"zlib": True, "complevel": 3}
            for cn in ds_out.coords:
                if ds_out[cn].ndim > 0:
                    encoding[cn] = {"zlib": True, "complevel": 3}
        if chunks:
            for vn, da in ds_out.data_vars.items():
                if "gridcell" in da.dims:
                    shape = da.sizes
                    # chunks only along gridcell; other dims untouched
                    cs = tuple(chunks if d == "gridcell" else shape[d] for d in da.dims)
                    encoding.setdefault(vn, {}).update({"chunksizes": cs})

        ds_out.to_netcdf(out_path, encoding=encoding or {})
        return ds_out

    # ---------------- helpers ----------------
    def _find_lonlat(self, ds: xr.Dataset):
        lon = None; lat = None
        for n in self.lon_candidates:
            if n in ds: lon = ds[n]; break
        for n in self.lat_candidates:
            if n in ds: lat = ds[n]; break
        if lon is None or lat is None:
            raise KeyError("Could not find gridcell lon/lat in source domain.")
        if lon.ndim == 2:
            lon = xr.DataArray(lon.values.ravel(), dims=("gridcell",))
            lat = xr.DataArray(lat.values.ravel(), dims=("gridcell",))
        elif lon.ndim == 1 and lon.dims[0] != "gridcell":
            lon = lon.rename("gridcell"); lat = lat.rename("gridcell")
        return lon, lat

    @staticmethod
    def _sanitize(da: xr.DataArray):
        arr = np.asarray(da.values, dtype=float)
        for k in ("_FillValue", "missing_value"):
            fv = da.attrs.get(k, None)
            if fv is not None:
                arr[np.isclose(arr, float(fv))] = np.nan
        arr[np.isclose(arr, 1.0e36)] = np.nan
        return arr

    # ---- aggregation kernels ----
    def _bincount_mean(self, values: np.ndarray):
        vals = np.asarray(values, dtype=float)[self.valid]
        idx = self.col2gc_valid
        if self.col_area is None:
            # equal weights
            num = np.bincount(idx, weights=vals, minlength=self.ngc)
            den = np.bincount(idx, minlength=self.ngc)
        else:
            w = self.col_area
            m = np.isfinite(vals) & np.isfinite(w)
            num = np.bincount(idx[m], weights=vals[m]*w[m], minlength=self.ngc)
            den = np.bincount(idx[m], weights=w[m], minlength=self.ngc)
        out = np.full(self.ngc, np.nan, dtype=float)
        ok = den > 0
        out[ok] = num[ok] / den[ok]
        return out

    def _bincount_sum(self, values: np.ndarray):
        vals = np.asarray(values, dtype=float)[self.valid]
        idx = self.col2gc_valid
        m = np.isfinite(vals)
        return np.bincount(idx[m], weights=vals[m], minlength=self.ngc)

    def _aggregate_column_mean(self, da: xr.DataArray) -> xr.DataArray:
        # 1D
        if da.ndim == 1:
            vals = self._sanitize(da)
            gc = self._bincount_mean(vals)
            return xr.DataArray(gc, dims=("gridcell",), coords={"lon": self.lon_gc, "lat": self.lat_gc})
        # layered
        if da.dims[0] != "column":
            da = da.transpose("column", ...)
        levdim = [d for d in da.dims if d != "column"][0]
        parts = []
        for k in range(da.sizes[levdim]):
            vals = self._sanitize(da.isel({levdim: k}))
            parts.append(xr.DataArray(self._bincount_mean(vals), dims=("gridcell",)))
        return xr.concat(parts, dim=levdim).assign_coords({levdim: da[levdim], "lon": self.lon_gc, "lat": self.lat_gc})

    def _aggregate_column_sum(self, da: xr.DataArray) -> xr.DataArray:
        # 1D
        if da.ndim == 1:
            vals = self._sanitize(da)
            gc = self._bincount_sum(vals)
            return xr.DataArray(gc, dims=("gridcell",), coords={"lon": self.lon_gc, "lat": self.lat_gc})
        # layered
        if da.dims[0] != "column":
            da = da.transpose("column", ...)
        levdim = [d for d in da.dims if d != "column"][0]
        parts = []
        for k in range(da.sizes[levdim]):
            vals = self._sanitize(da.isel({levdim: k}))
            parts.append(xr.DataArray(self._bincount_sum(vals), dims=("gridcell",)))
        return xr.concat(parts, dim=levdim).assign_coords({levdim: da[levdim], "lon": self.lon_gc, "lat": self.lat_gc})

    # ---- grid helpers ----
    def _has_corners_1d(self) -> bool:
        return (self.xv is not None) and (self.yv is not None) and (self._corner_ndim_ok(self.xv) and self._corner_ndim_ok(self.yv))

    @staticmethod
    def _corner_ndim_ok(da: xr.DataArray) -> bool:
        return (("gridcell" in da.dims and "nv" in da.dims) or
                ("nj" in da.dims and "ni" in da.dims and "nv" in da.dims) or
                ("n" in da.dims and "nv" in da.dims))

    def _as_1d_corners(self, da: xr.DataArray) -> xr.DataArray:
        if ("gridcell" in da.dims) and ("nv" in da.dims):
            return da
        if ("nj" in da.dims) and ("ni" in da.dims) and ("nv" in da.dims):
            arr = da.values.reshape((-1, da.sizes["nv"]))
            return xr.DataArray(arr, dims=("gridcell","nv"))
        if ("n" in da.dims) and ("nv" in da.dims):
            nj = self.src.dims.get("nj", None); ni = self.src.dims.get("ni", None)
            if nj is not None and ni is not None and da.sizes["n"] == nj * ni:
                arr = da.values.reshape((nj*ni, da.sizes["nv"]))
                return xr.DataArray(arr, dims=("gridcell","nv"))
        raise ValueError("Unrecognized corner variable shape for conversion to (gridcell,nv).")

    @staticmethod
    def _has_metric_1d(da) -> bool:
        return (da is not None) and (("gridcell" in da.dims) or ("n" in da.dims) or (("nj" in da.dims) and ("ni" in da.dims)))

    def _as_1d_metric(self, da: xr.DataArray) -> xr.DataArray:
        if "gridcell" in da.dims and da.ndim == 1:
            return da
        if ("nj" in da.dims) and ("ni" in da.dims) and da.ndim == 2:
            arr = da.values.reshape((-1,))
            return xr.DataArray(arr, dims=("gridcell",))
        if ("n" in da.dims) and da.ndim == 1:
            nj = self.src.dims.get("nj", None); ni = self.src.dims.get("ni", None)
            if nj is not None and ni is not None and da.sizes["n"] == nj * ni:
                arr = da.values.reshape((nj * ni,))
                return xr.DataArray(arr, dims=("gridcell",))
        raise ValueError("Unrecognized metric variable shape for conversion to (gridcell,).")

    def _auto_pick_column_vars(self) -> List[str]:
        """Pick numeric vars with a 'column' dim; skip indices/coords/booleans."""
        bad = {self.col2gc_name, "cols1d_lon", "cols1d_lat", "cols1d_active"}
        out: List[str] = []
        for k, v in self.rst.variables.items():
            if k in bad:
                continue
            if "column" in v.dims and np.issubdtype(v.dtype, np.number):
                out.append(k)
        return out

    def close(self):
        for ds in (self.rst, self.src):
            try: ds.close()
            except Exception: pass


# ---------------- CLI ----------------
def _parse_args():
    p = argparse.ArgumentParser(description="Aggregate ELM/CLM restart columns to gridcells.")
    p.add_argument("--restart", required=True, help="Path to restart file (NetCDF).")
    p.add_argument("--src-domain", required=True, help="Path to source land domain file (NetCDF).")
    p.add_argument("--out", required=True, help="Output NetCDF path for aggregated gridcell file.")
    p.add_argument("--vars", nargs="*", help="Variables to aggregate (default: auto-pick all 'column' vars).")
    p.add_argument("--sum-vars", nargs="*", default=[], help="Variables to aggregate by SUM (extensive). Others use weighted MEAN.")
    p.add_argument("--no-compress", action="store_true", help="Disable NetCDF compression.")
    p.add_argument("--chunks", type=int, default=None, help="Chunk size along 'gridcell' (optional).")
    return p.parse_args()


def main():
    args = _parse_args()
    exp = ColumnToGridcellExporter(args.restart, args.src_domain)
    try:
        ds = exp.export(
            out_path=args.out,
            varnames=args.vars,
            sum_vars=args.sum_vars,
            compress=(not args.no_compress),
            chunks=args.chunks,
        )
        print(f"Wrote {args.out} with variables: {', '.join(ds.data_vars.keys())}")
    finally:
        exp.close()


if __name__ == "__main__":
    main()
