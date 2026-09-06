import os
import xarray as xr
import pandas as pd
import numpy as np
import warnings 

from xcdat.dataset import open_dataset
from xcdat.bounds import create_bounds
from xcdat.dataset import open_mfdataset
from typing import Sequence, Optional

class ObsDataReader:
    """
    Class to read and preprocess observational data with internal dataset registry.
    Supports regional mean extraction.
    """

    def __init__(self, obsname, period, frequency=None):
        self.obsname = obsname
        self.period = period
        self.frequency = frequency or 'daily'
        self.derive_monthly = False
        self.obs_dict = self._define_obs_group()

    def _define_obs_group(self):
        return {
            'ERA5': {
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/ERA5/monthly',
                    'template': 'ERA5_analysis_monthly_%(year)s.nc',
                    'period': '2001-2018'
                },
                '6hourly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/ERA5/6hourly',
                    'template': 'ERA5.6hourly.en00.%(var)s.%(year)s01-%(year)s12.nc',
                    'period': '1979-2018'
                }
            },
            'GPCP': {
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/GPCP/monthly',
                    'template': 'PRECT.monthly.%(year)s.nc',
                    'period': '2010-2015'
                },
                'daily': {
                    'path': '/compyfs/zhan391/acme_init/Observations/GPCP/daily',
                    'template': 'PRECT.daily.%(year)s.nc',
                    'period': '2010-2015'
                }
            },
            'IMERG': {
                'daily': {
                    'path': '/compyfs/zhan391/acme_init/Observations/IMERG/daily',
                    'template': 'PRECT.daily.%(year)s.nc',
                    'period': '2007-2011'
                },
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/IMERG/monthly',
                    'template': 'PRECT.daily.%(year)s.nc',
                    'period': '2007-2011'
                }
            },
            'CERES-OAFlux': {
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/CERES-OAFlux/monthly',
                    'template': 'CERES-OAFlux_%(year)s.nc',
                    'period': '2001-2018',
                }
            },
            'CPC_SOM': {
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/CPC_SOM/monthly',
                    'template': 'SOILWATER_10CM.monthly.%(year)s.nc',
                    'period': '2001-2020'
                }
            },
            'ESA_CCI': {
                'daily': {
                    'path': '/compyfs/zhan391/acme_init/Observations/ESA_CCI/daily',
                    'template': 'H2OSOI.monthly.%(year)s.nc',
                    'period': '2001-2020'
                },
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/ESA_CCI/monthly',
                    'template': 'H2OSOI.monthly.%(year)s.nc',
                    'period': '2001-2020'
                }
            },
            'MODIS_LST': {
                'monthly': {
                    'path': '/compyfs/zhan391/acme_init/Observations/MODIS_LST/monthly',
                    'template': 'MOD11C3.monthly.%(year)s.nc',
                    'period': '2001-2024'
                }
            }
        }

    @staticmethod
    def define_region(regnam='global'):
        reg_dict = {
            'global':     [(-90, 90), (-180, 180)],
            'NHMidLat':   [(25, 50), (-60, 150)],
            'Tropics':    [(-10, 10), (-90, 60)],
            'Atlantic':   [(5, 55), (-95, -40)],
            'CONUS':      [(25, 50), (-125, -95)],
            'Antarctic':  [(-90, -50), (-180, 180)],
            'PolarN':     [(50, 90), (-180, 180)],
            'Greenland':  [(60, 85), (-75, -10)],
        }
        if regnam not in reg_dict:
            raise ValueError(f"Region '{regnam}' not defined. Available: {list(reg_dict.keys())}")
        return reg_dict[regnam]

    def get_group(self, name=None):
        return self.obs_dict.get(name) if name else self.obs_dict['ERA5']

    def list_datasets(self):
        return list(self.obs_dict.keys())

    def _snap_time_to_month_start(self, da: xr.DataArray, tolerance_days=15) -> xr.DataArray:
        """Snap each time value to the 1st of its month if it's within tolerance."""
        time_index = da['time'].to_index()
        snapped_time = []

        for t in time_index:
            month_start = pd.Timestamp(f"{t.year}-{t.month:02d}-01")
            if abs((t - month_start).days) <= tolerance_days:
                snapped_time.append(month_start)
            else:
                snapped_time.append(t)  # leave unchanged

        da = da.assign_coords(time=('time', pd.to_datetime(snapped_time)))
        return da

    def _ensure_datetime64(self, da: xr.DataArray, frequency: str) -> xr.DataArray:
        """Ensure 'time' coordinate is datetime64[ns] and normalize if daily or coarser."""
        # Convert CFTimeIndex or any non-datetime64 to datetime64[ns]
        if not isinstance(da.indexes['time'], pd.DatetimeIndex):
            da['time'] = da.indexes['time'].to_datetimeindex(time_unit='ns')

        # Normalize time for daily and coarser frequencies
        if frequency in ['monthly', 'mon', 'M', '1M', '1ME', 'yearly', 'annual', 'Y']:
            # Convert to first day of month
            da = self._snap_time_to_month_start(da, tolerance_days=15)
        elif frequency in ['daily', 'day', 'D']:
            # Normalize to midnight to remove any hour/minute/second inconsistencies
            da['time'] = pd.to_datetime(da['time'].values).normalize()

        return da
    
    def parse_time_range(self, time):
        # Check if the input is a time range string like '201101-201101'
        if isinstance(time, str) and '-' in time:
            start_date, end_date = time.split('-')
            start = pd.to_datetime(start_date, format='%Y%m')
            end = pd.to_datetime(end_date, format='%Y%m')

            # Adjust the end date to the last moment of the last day (23:59:59.999999)
            end = end + pd.Timedelta(days=1) - pd.Timedelta(seconds=1)

            # Create a date range from the start month to the end month (inclusive)
            time_range = pd.date_range(start=start, end=end, freq='D')  # Ensures daily frequency
            
            print(f"Parsed time range: {start} to {end}")
        else:
            raise TypeError("Only string ('YYYYMM-YYYYMM') or slice inputs are supported.")
        
        # Extract the years from the time range
        years = list(range(start.year, end.year + 1))
        
        return time_range, years
    
    def open_and_clean_mfdataset(
        paths: Sequence[str],
        frequency: str = "monthly",
        chunks: Optional[dict] = None,
        engine: Optional[str] = None,   # e.g., "netcdf4" or "h5netcdf"
    ):
        """
        Robust multi-file open + clean (Option B):
          - open without CF decoding (no warnings)
          - unify `_FillValue` / `missing_value` per variable (attrs + data)
          - then decode CF (mask/scale/time) cleanly
          - concatenate by coords, tolerate minor attr conflicts
          - de-duplicate & sort time
          - normalize timestamps for monthly/daily data
        """

        # 1) Open raw, no CF decode/masking yet (prevents warnings)
        ds = xr.open_mfdataset(
            paths,
            combine="by_coords",
            data_vars="minimal",
            coords="minimal",
            compat="override",
            join="override",
            parallel=True,
            chunks=chunks,
            engine=engine,
            decode_cf=False,      # <- key: do not decode yet
            mask_and_scale=False, # <- key: do not mask yet
        )

        # 2) Harmonize fill/missing attrs and replace mixed sentinels in the DATA
        def unify_fill_attrs(_ds: xr.Dataset, default_fill: float = -9.999e03) -> xr.Dataset:
            for v in _ds.data_vars:
                da = _ds[v]
                fv = da.attrs.get("_FillValue", None)
                mv = da.attrs.get("missing_value", None)

                # Choose a single sentinel to keep
                if fv is not None:
                    chosen = fv
                elif mv is not None:
                    chosen = mv
                else:
                    # dataset had no declared sentinels; leave data as-is
                    # (we won't set new attrs unless we need to)
                    chosen = None

                # Build list of alternative sentinels to replace
                alts = []
                for val in (fv, mv):
                    if val is not None and (chosen is None or val != chosen):
                        alts.append(val)

                # If both attrs missing but we still see classic sentinels in attrs of others,
                # you could optionally add common values (e.g., 1e20, -9999.0) here.
                # We keep it conservative and only use declared ones.

                if alts:
                    # Replace any alt sentinel values with the chosen one
                    # keep lazy/dask with xr.where + isin
                    mask = da.isin(alts)
                    _ds[v] = xr.where(~mask, da, float(chosen))

                # Normalize attrs: keep only _FillValue
                if chosen is not None:
                    _ds[v].attrs["_FillValue"] = float(chosen)
                _ds[v].attrs.pop("missing_value", None)

            return _ds

        ds = unify_fill_attrs(ds)

        # 3) Now decode CF cleanly (mask/scale + times)
        ds = xr.decode_cf(ds, mask_and_scale=True, decode_times=True)

        # 4) Ensure/normalize time
        if "time" not in ds.coords:
            raise ValueError("No 'time' coordinate after opening datasets.")

        time_index = ds.indexes["time"]
        if not isinstance(time_index, pd.DatetimeIndex):
            # CFTimeIndex -> pandas.DatetimeIndex (no deprecated kwargs)
            ds = ds.assign_coords(time=time_index.to_datetimeindex())

        # Sort + drop duplicate times (overlapping files)
        ds = ds.sortby("time")
        tvals = ds.indexes["time"].values
        _, unique_idx = np.unique(tvals, return_index=True)
        if len(unique_idx) != ds.sizes["time"]:
            ds = ds.isel(time=np.sort(unique_idx))

        # 5) Snap timestamps by frequency (helps groupby/resample downstream)
        freq = frequency.lower()
        if freq in ("monthly", "mon", "m", "1m", "1me"):
            ds = ds.assign_coords(time=ds.indexes["time"].to_period("M").to_timestamp(how="start"))
        elif freq in ("daily", "day", "d"):
            ds = ds.assign_coords(time=pd.to_datetime(ds.indexes["time"].values).normalize())

        return ds

    def read(self, var, regnam='global', regional_mean=False):
        obs_group = self.get_group(self.obsname)
        if obs_group is None:
            raise ValueError(f"Observational dataset '{self.obsname}' not found.")
        if self.frequency not in obs_group:
            raise ValueError(f"Frequency '{self.frequency}' not found in '{self.obsname}'")

        group_info = obs_group[self.frequency]

        # identify time range and list of years 
        time_range, years = self.parse_time_range(self.period) 
        
        # Generate file paths
        paths = []
        for y in years:
            print(y)
            try:
                fname = group_info["template"] % {'year': y, 'var': var}
            except KeyError:
                fname = group_info["template"] % {'year': y}
            paths.append(os.path.join(group_info["path"], fname))

        # Open and merge datasets
        try:
            refds = open_and_clean_mfdataset(
                paths,
                frequency=self.frequency,
                chunks={"time": -1},     # or {"time": 256} if you prefer fixed chunk sizes
                engine="netcdf4",        # or "h5netcdf" if that’s your stack
            )
        except Exception as e:
            raise RuntimeError(f"Failed to open datasets: {paths}") from e

        refds = self._ensure_datetime64(refds,self.frequency)
        
        # Apply time selection
        print(f"Extracting time range: {time_range[0]} to {time_range[-1]}")
        refds = refds.sel(time=slice(time_range[0], time_range[-1]))  # Use slice for inclusive selection
        
        # Normalize longitude to [-180, 180]
        if refds.lon.min() >= 0:
            refds = refds.assign_coords(lon=((refds.lon + 180) % 360 - 180)).sortby("lon")

        if var not in refds:
            available = list(refds.data_vars)
            raise KeyError(f"Variable '{var}' not found. Available: {available}")
            
        data = self.convert_obs_units(self.obsname, var, refds[var])
                
        # Apply region +  time selection 
        (lat1, lat2), (lon1, lon2) = self.define_region(regnam)
        data = data.sel(lat=slice(lat1, lat2), lon=slice(lon1, lon2))

        # Compute regional mean if requested
        if regional_mean:
            weights = np.cos(np.deg2rad(data.lat))
            weights /= weights.mean()
            data = (data * weights).mean(dim=["lat", "lon"])

        return data.chunk({"time": -1}) if 'time' in data.dims else data
    
    def convert_obs_units(self, obsname, var, data_array):
        conversions = {
            'PRECT': lambda x: x * 86400.0 * 1000.0,  # mm/day to m/s
            'PSL': lambda x: x / 100.0,               # Pa to hPa
            'PS': lambda x: x / 100.0,                # Pa to hPa
        }

        # Ensure 'time' dimension is present
        if 'time' not in data_array.dims:
            raise ValueError(f"Expected 'time' dimension in data for '{var}'")

        # If variable is 'PRECT' and 'gpcp' is in the name, return as is
        if var == 'PRECT' and 'gpcp' in obsname.lower():
            return data_array

        # Perform conversion if a valid conversion exists for the variable
        if var in conversions:
            return conversions[var](data_array)

        # If no conversion exists for the variable, return data as is
        return data_array
