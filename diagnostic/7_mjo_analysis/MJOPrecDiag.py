# hovmoller_mjo_analyzer.py

"""
Module: hovmoller_mjo_analyzer

Description:
------------
Class `HovmollerPrecipAnalyzer` for generating MJO diagnostics using equatorial precipitation data.
Supports:
- RMM index loading and filtering
- RMM phase composites
- RMM phase-space plots
- Optional overlay of MJO phase and amplitude
"""

# Core Python
import os
import numpy as np
import pandas as pd
import xarray as xr
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.colors as mcolors
import matplotlib.animation as animation
from datetime import datetime
from scipy.signal import butter, filtfilt

# Optional imports
import xskillscore as xs
from typing import Optional, Dict
import metpy.calc as mpcalc

class HovmollerPrecipAnalyzer:
    def __init__(self, data_dict, 
                 varname,
                 var_info, 
                 lat_bounds=(-20, 20),
                 dt_hours=24,
                 mjo_filter=True,
                 remove_clim=True, 
                 rmm_path=None,
                 frequency= 'daily', 
                 time_start = None,
                 time_end = None, 
                 fontz=12):
        self.data_dict = data_dict
        self.varname = varname
        self.varstr = var_info['alias']
        self.varunt = var_info['units']
        self.lat_bounds = lat_bounds
        self.dt_hours = dt_hours
        self.mjo_filter = mjo_filter
        self.remove_clim = remove_clim
        self.rmm_path = rmm_path
        self.time_start = time_start
        self.time_end = time_end
        self.fontz = fontz
        self.frequency = frequency
        self.rmm_index = None
         
    def _load_rmm_index(self, months=None, years=None, season=None, reload_data=False):
        local_txt = os.path.join(self.rmm_path, 'rmm.74toRealtime.txt')
        local_nc = os.path.join(self.rmm_path, 'rmm.74toRealtime.nc')
        col_names = ['year', 'month', 'day', 'RMM1', 'RMM2', 'phase', 'amplitude', 'Missing']

        if os.path.exists(local_nc) and not reload_data:
            ds = xr.open_dataset(local_nc)
        else:
            if not os.path.exists(local_txt) or reload_data:
                url = 'http://www.bom.gov.au/climate/mjo/graphics/rmm.74toRealtime.txt'
                df = pd.read_csv(url, skiprows=2, names=col_names, sep=r'\s+')
                os.makedirs(os.path.dirname(local_txt), exist_ok=True)
                df.to_csv(local_txt, sep=' ', index=False, header=False)
            else:
                df = pd.read_csv(local_txt, skiprows=2, names=col_names, sep=r'\s+')

            df.index = [datetime.datetime(y, m, d, 12) for y, m, d in zip(df.year, df.month, df.day)]
            df = df[['RMM1', 'RMM2', 'phase', 'amplitude']]
            df[df >= 999] = np.nan
            ds = xr.Dataset.from_dataframe(df).rename({'index': 'time'})
            ds.to_netcdf(local_nc)

        if months:
            ds = ds.sel(time=ds.time.dt.month.isin(months))
        if years:
            ds = ds.sel(time=ds.time.dt.year.isin(years))
        if season:
            season_months = {
                'DJF': [12, 1, 2], 'MAM': [3, 4, 5],
                'JJA': [6, 7, 8], 'SON': [9, 10, 11]
            }
            if season in season_months:
                ds = ds.sel(time=ds.time.dt.month.isin(season_months[season]))

        self.rmm_index = ds
        return ds

    def _bandpass_filter(self, data, low_days=20, high_days=96):
        fs = 24 / self.dt_hours
        nyq = 0.5 * fs
        low = 1 / high_days / nyq
        high = 1 / low_days / nyq
        b, a = butter(4, [low, high], btype='band')
        return xr.apply_ufunc(
            lambda x: filtfilt(b, a, x, axis=0),
            data,
            input_core_dims=[["time"]],
            output_core_dims=[["time"]],
            vectorize=True
        )
    
    def _open_dataset(self, path, template, ensemble=None):
        if '%(ensemble)' in template:
            if ensemble is None:
                raise ValueError("Ensemble ID must be provided for ensemble template.")
            filename = template % {'ensemble': ensemble}
        else:
            filename = template
        full_path = os.path.join(path, filename)
        if not os.path.exists(full_path):
            raise FileNotFoundError(f"Missing file: {full_path}")
        ds = xr.open_dataset(full_path)
        # Normalize longitude/latitude coordinate names if needed
        if "longitude" in ds.coords:
            ds = ds.rename({"longitude": "lon"})
        if "latitude" in ds.coords:
            ds = ds.rename({"latitude": "lat"})
        if "lon" in ds and ds.lon.min() >= 0:
            ds = ds.assign_coords(lon=((ds.lon + 180) % 360 - 180)).sortby("lon")
        return ds[self.varname]
    
    def _ensure_datetime64(self, da: xr.DataArray, freq: str) -> xr.DataArray:
        """Ensure 'time' coordinate is datetime64[ns] and normalize if daily or coarser."""
        # Convert CFTimeIndex or any non-datetime64 to datetime64[ns]
        if not isinstance(da.indexes['time'], pd.DatetimeIndex):
            da['time'] = da.indexes['time'].to_datetimeindex(time_unit='ns')

        # Normalize time for daily and coarser frequencies
        if freq in ['daily', 'day', 'D', 'monthly', 'mon', 'M', 'yearly', 'annual', 'Y']:
            # Normalize to midnight to remove any hour/minute/second inconsistencies
            da['time'] = pd.to_datetime(da['time'].values).normalize()

        return da
    
    def parse_time_range(self, time, freq):
        # Check if the input is a time range string like '201101-201101'
        if isinstance(time, str) and '-' in time:
            start_date, end_date = time.split('-')
            if freq in ['daily', 'day', 'D']:
                start = pd.to_datetime(start_date, format='%Y%m%d')
                end = pd.to_datetime(end_date, format='%Y%m%d')
            elif freq in ['monthly', 'mon', 'M']:
                start = pd.to_datetime(start_date, format='%Y%m')
                end = pd.to_datetime(end_date, format='%Y%m')
            else: 
                raise ValueError('Invalid frequency for parse_time_range: {freq}')

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


    def _load_and_concatenate_segments(self, seg_dict, ensemble=None):
        ds_list = []
        
        for seg_key in sorted(seg_dict.keys()):
            meta = seg_dict[seg_key]
            
            # Load the dataset
            da = self._open_dataset(meta['path'], meta['template'], ensemble)
            
            freq = self.frequency or meta['frequency'] 
            
            # Apply time slicing using 'period'
            if 'period' in meta: 
                period = meta['period']
                print(f"Period in file dictionary {period}")
                time_range, years = self.parse_time_range(period,freq)
            else:
                raise ValueError("Invalid option for slice time selection: period")
            
            try: 
                # Apply time selection
                da = self._ensure_datetime64(da,freq)   
                
                #print(f"Extracting time range: {time_range[0]} to {time_range[-1]}")
                da = da.sel(time=slice(time_range[0], time_range[-1]))  # Use slice for inclusive selection
                
                # Scale the data if 'fscale' is present                       
                da = da * meta.get('fscale', 1.0)
                
                # Log the actual time range selected
                actual_start = pd.to_datetime(str(da.time.values.min()))
                actual_end = pd.to_datetime(str(da.time.values.max()))
                print(f"Selected period ({period}): got {actual_start} to {actual_end}")
                    
            except Exception as e:
                raise ValueError(f"Invalid period format in segment '{seg_key}' ({meta['period']}): {e}")
            
            # Append the processed segment data to the list
            ds_list.append(da)
        
        # Final concatenation after all segments are normalized to datetime
        data_combined = xr.concat(ds_list, dim='time').sortby('time')
        if self.time_start and self.time_end:
            period = f"{self.time_start}-{self.time_end}"
            print(f"Customized period: {period}")
            time_range, years = self.parse_time_range(period, freq)

            # Select the time slice from combined data
            print(f"Extracting time range: {time_range[0]} to {time_range[-1]}")
            data_combined = data_combined.sel(time=slice(time_range[0], time_range[-1]))
      
        return data_combined

    
    def _remove_daily_climatology(self, da):
        doy = da['time'].dt.dayofyear
        clim = da.groupby(doy).mean('time')
        return da.groupby(doy) - clim

    def _compute_equatorial_mean(self, da):
        da_eq = da.sel(lat=slice(*self.lat_bounds))
        weights = np.cos(np.deg2rad(da_eq.lat))
        weights /= weights.sum()
        return (da_eq * weights).sum(dim='lat')
    
    def generate_hovmoller(self, exp_key, savepath=None,
                           filter_by_amplitude=False, amp_thresh=1.0,
                           overlay_phase=False,
                           shade_amplitude=False,
                           vmin=-5, vmax=5, nlevs=21,
                           clevs = None,
                           cmap='',
                           xlabel='Longitude',
                           precip_ticks=None):

        segs = self.data_dict[exp_key]
        nens = max(segs[s].get('nens', 1) for s in segs)
        
        if clevs:
            vmin=clevs[0]
            vmax=clevs[-1]
            nlevs=len(clevs),
        else: 
            clevs = np.linspace(vmin, vmax, nlevs)
            
        if "GPCP" in exp_key:
            mag_scale = 0.5
        else:
            mag_scale = 1.0
            
        title = f'{exp_key} Hovmoller ({self.varname} x {mag_scale})'
        
        norm = mcolors.BoundaryNorm(clevs, ncolors=cmap.N)
        
        print(f"\n[INFO] Processing {exp_key} with {nens} ensemble member(s)...")

        if nens == 1:
            da = self._load_and_concatenate_segments(segs)
        else:
            ens_list = []
            for m in range(1, nens + 1):
                member_id = f'EN{m:02d}'
                da_ens = self._load_and_concatenate_segments(segs, ensemble=member_id)
                ens_list.append(da_ens.expand_dims(ensemble=[member_id]))
            da = xr.concat(ens_list, dim='ensemble').mean(dim='ensemble', skipna=True)

        da = da * mag_scale
        
        if self.remove_clim:
            if len(da.time) > 270:
                # Remove daily climatology if long enough
                da_anom = self._remove_daily_climatology(da)
            else:
                # Remove mean over time (suitable for 90-day dataset)
                #da_anom = da - da.mean(dim='time')
                da_anom = da.groupby('time.month') - da.groupby('time.month').mean('time')


        if self.mjo_filter:
            # Apply bandpass filter to anomaly or raw depending on remove_clim
            da_filt = self._bandpass_filter(da_anom if self.remove_clim else da)
        elif self.remove_clim:
            da_filt = da_anom
        else:
            da_filt = da
               
        hov = self._compute_equatorial_mean(da_filt)
        hov['time'] = pd.to_datetime(hov.time.values).normalize()
        hov = hov.assign_coords(lon=((hov.lon + 360) % 360))
        hov = hov.sortby('lon')
        hov_plot = hov.transpose("time", "lon")

        rmm_aligned = None
        if filter_by_amplitude or overlay_phase or shade_amplitude:
            rmm_ds = self._load_rmm_index()
            rmm_df = rmm_ds.to_dataframe().dropna()
            rmm_df.index = rmm_df.index.normalize()
            rmm_df = rmm_df.loc[rmm_df.index.isin(hov.time.values)]
            rmm_df = rmm_df[rmm_df['amplitude'] > 1.0]
            rmm_df = rmm_df[~rmm_df.index.duplicated(keep='first')] 
            dups = rmm_df.index[rmm_df.index.duplicated()]
            print("Duplicate times in RMM index:", dups)

        plt.figure(figsize=(9, 6))
        print(f"total time in hovmoller {len(hov['time'])}")
        cf = plt.contourf(
            hov_plot.lon.values,
            hov_plot.time.values,
            hov_plot.values,
            levels=clevs,
            cmap=cmap,
            norm=norm,
            vmin=vmin,
            vmax=vmax,
            extend='both'
        )
        cs = plt.contour(
            hov_plot.lon.values,
            hov_plot.time.values,
            mpcalc.smooth_n_point(hov_plot.values, 9, 2), 
            clevs, colors='k', 
            linewidths=0.2
        )
        
        if shade_amplitude and rmm_df is not None and 'amplitude' in rmm_df:
            amp = rmm_df['amplitude']
            amp_norm = amp / amp.max()  # Normalize amplitude
            plt.scatter(
                hov_plot.lon.values[-1] + 5,  # Scatter near the edge for visibility
                hov_plot.time.values,
                c=amp_norm,
                cmap='Greys',
                marker='s',
                s=20,
                label='RMM Amplitude'
            )
            
        for line_lon in [120, 150, 180]:
            if self.mjo_filter or  self.remove_clim:
                plt.axvline(line_lon, color='Black', linestyle='--', linewidth=2.0, alpha=0.6) 
            else:
                plt.axvline(line_lon, color='white', linestyle='--', linewidth=2.0, alpha=0.6)
            
        target_time = np.datetime64("2012-01-01")
        if self.mjo_filter or  self.remove_clim:
            plt.axhline(target_time, color='Black', linestyle='--', linewidth=2.0, alpha=0.6)
        else:
            plt.axhline(target_time, color='white', linestyle='--', linewidth=2.0, alpha=0.6)

        plt.title(title, fontsize=self.fontz*1.2)
        plt.xlabel(xlabel, fontsize=self.fontz*1.2)
        plt.ylabel('Time', fontsize=self.fontz*1.2)

        cbar = plt.colorbar(cf, orientation='vertical', pad=0.015, shrink=0.95)
        cbar.set_label(f"{self.varstr} ({self.varunt})", fontsize=self.fontz*1.2)
        if clevs:
            cbar.set_ticks(clevs)
        else:
            cbar.set_ticks(np.linspace(vmin, vmax,nlevs))
            
        cbar.ax.tick_params(labelsize=self.fontz)

        plt.gca().yaxis.set_major_formatter(mdates.DateFormatter('%b-%d'))

        xticks = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360]
        xticklabels = ['0', '30E', '60E', '90E', '120E', '150E', '180',
                       '150W', '120W', '90W', '60W', '30W', '0']
        xticks = xticks [::2]
        xticklabels = xticklabels[::2]
        
        ax = plt.gca()
        ax.set_xticks(xticks)
        ax.set_xticklabels(xticklabels, fontsize=self.fontz)
        ax.tick_params(labelsize=self.fontz)
        ax.invert_yaxis()

        if overlay_phase and 'phase' in hov.coords:
            for phase in range(1, 9):
                mask = hov.phase.values == phase
                if np.any(mask):
                    y_vals = hov.time.values[mask]
                    x_vals = np.full_like(y_vals, hov.lon.values[0] - 10)
                    plt.scatter(x_vals, y_vals, label=f'Phase {phase}', s=10)
            plt.legend(title='RMM Phase', loc='upper left',
                       fontsize=self.fontz -2, title_fontsize=self.fontz*1.2)

        plt.tight_layout()
        if savepath:
            plt.savefig(savepath, dpi=600)
            print(f"[INFO] Saved to {savepath}")
            plt.close()
        else:
            plt.show()

    def plot_phase_composites(self, composites, savepath=None):
        """
        Plot precipitation composites for RMM phases 1–8.
        Longitude is normalized to [-180, 180] with consistent tick labels.
        """
        # Normalize longitude to match Hovmöller
        composites = composites.assign_coords(lon=((composites.lon + 180) % 360 - 180)).sortby('lon')

        fig, axes = plt.subplots(2, 4, figsize=(16, 6), sharey=True)
        phases = range(1, 9)
        vmax = np.abs(composites).max().item()

        # Use consistent longitude ticks
        xticks = [-180, -150, -120, -90, -60, -30, 0, 30, 60, 90, 120, 150, 180]
        xticklabels = ['180W', '150W', '120W', '90W', '60W', '30W',
                       '0', '30E', '60E', '90E', '120E', '150E', '180']
        xticks = xticks[::2]
        xticklabels = xticklabels[::2]
        
        for i, phase in enumerate(phases):
            ax = axes.flat[i]
            ax.plot(composites.lon, composites.sel(phase=phase), label=f'Phase {phase}')
            ax.axhline(0, color='gray', linestyle='--', lw=0.5)
            ax.set_title(f'Phase {phase}', fontsize=self.fontz)
            ax.set_xticks(xticks)
            ax.set_xticklabels(xticklabels, fontsize=self.fontz)
            ax.tick_params(labelsize=self.fontz)
            ax.set_ylim(-vmax, vmax)
            if i in [0, 4]:
                ax.set_ylabel('Precip (mm/day)', fontsize=self.fontz)

        plt.tight_layout()
        plt.show()

        if savepath:
            plt.savefig(savepath, dpi=600)
            print(f"[INFO] Saved to {savepath}")
            plt.close()
            
    def plot_rmm_phase_space(self, start=None, end=None, amp_thresh=1.0, savepath=None):
        rmm_ds = self._load_rmm_index()
        rmm_df = rmm_ds.to_dataframe().dropna()
        rmm_df = rmm_df[rmm_df["amplitude"] > amp_thresh]
        
        # Normalize rmm_df.index to ensure it's in datetime64 format (if not already)
        rmm_df.index = pd.to_datetime(rmm_df.index).normalize()
        
        if start:
            rmm_df = rmm_df[rmm_df.index >= pd.to_datetime(start)]
        if end:
            rmm_df = rmm_df[rmm_df.index <= pd.to_datetime(end)]
        #print(rmm_df.index)
        
        fig, ax = plt.subplots(figsize=(6, 6))
        sc = ax.scatter(
            rmm_df["RMM1"],
            rmm_df["RMM2"],
            c=rmm_df["phase"],
            cmap='tab10',
            s=10
        )

        ax.set_xlabel("RMM1", fontsize=self.fontz)
        ax.set_ylabel("RMM2", fontsize=self.fontz)
        ax.set_title(f"MJO Phase Space (Amp > {amp_thresh})", fontsize=self.fontz)
        ax.axhline(0, color='k', lw=0.5)
        ax.axvline(0, color='k', lw=0.5)
        ax.tick_params(labelsize=self.fontz)
        ax.grid(True)

        cb = plt.colorbar(sc, ax=ax, ticks=range(1, 9))
        cb.set_label("RMM Phase", fontsize=self.fontz)
        cb.ax.tick_params(labelsize=self.fontz)

        plt.tight_layout()
        plt.show()

        if savepath:
            plt.savefig(savepath, dpi=150)
            print(f"[INFO] Saved RMM phase diagram to: {savepath}")
            plt.close()

    def compute_phase_composites(self, exp_key, use_filtered=True):
        """
        Compute zonal mean precipitation composites by RMM phase.
        Returns:
            xr.DataArray of shape [phase, lon] with normalized longitudes.
        """
        segs = self.data_dict[exp_key]
        nens = max(segs[s].get('nens', 1) for s in segs)

        if nens == 1:
            da = self._load_and_concatenate_segments(segs)
        else:
            ens_list = []
            for m in range(1, nens + 1):
                member_id = f'EN{m:02d}'
                da_ens = self._load_and_concatenate_segments(segs, ensemble=member_id)
                ens_list.append(da_ens.expand_dims(ensemble=[member_id]))
            da = xr.concat(ens_list, dim='ensemble').mean(dim='ensemble', skipna=True)

        # Remove mean if needed
        if self.remove_clim:
            da = da - da.mean(dim='time')
    
        # Apply filtering
        if use_filtered:
            da = self._bandpass_filter(da)

        # Equatorial mean and time normalization
        da_eq = self._compute_equatorial_mean(da)
        #print(da_eq['time'])
        
        # Drop duplicate times in da_eq
        da_eq, _ = xr.align(da_eq, da_eq.drop_duplicates('time'))

        # Load RMM data
        rmm = self._load_rmm_index()
        rmm_df = rmm.to_dataframe().dropna()
        rmm_df.index = rmm_df.index.normalize()
        rmm_df = rmm_df[rmm_df['amplitude'] > 1.0]
        rmm_df = rmm_df[~rmm_df.index.duplicated(keep='first')]

        # Intersect time indices and drop duplicates
        model_times = pd.Index(da_eq.time.values).drop_duplicates()
        rmm_times = rmm_df.index
        shared_times = model_times.intersection(rmm_times)

        if len(shared_times) == 0:
            raise ValueError("No overlapping valid times between model and RMM index.")
    
        # Select valid times and assign phase
        da_eq = da_eq.sel(time=shared_times)
        rmm_df = rmm_df.loc[shared_times]
        phase_da = xr.DataArray(rmm_df['phase'].values, coords={'time': da_eq.time}, dims='time')
        da_eq = da_eq.assign_coords(phase=phase_da)

        # Group by phase
        composites = da_eq.groupby('phase').mean('time')

        # Normalize longitude to [-180, 180]
        composites = composites.assign_coords(lon=((composites.lon + 180) % 360 - 180)).sortby('lon')

        return composites


    def animate_phase_space(self, savepath="rmm_phase_anim.mp4"):
        rmm_ds = self._load_rmm_index()
        df = rmm_ds.to_dataframe().dropna()

        fig, ax = plt.subplots(figsize=(6, 6))
        ax.set_xlim(-4, 4)
        ax.set_ylim(-4, 4)
        ax.axhline(0, color='gray', lw=0.5)
        ax.axvline(0, color='gray', lw=0.5)
        ax.grid(True)
        ax.set_title("Animated MJO Phase Space")
        ax.set_xlabel("RMM1")
        ax.set_ylabel("RMM2")
        line, = ax.plot([], [], lw=2)
        point, = ax.plot([], [], 'ro')

        def init():
            line.set_data([], [])
            point.set_data([], [])
            return line, point

        def update(i):
            line.set_data(df.RMM1[:i], df.RMM2[:i])
            point.set_data(df.RMM1[i], df.RMM2[i])
            return line, point

        ani = animation.FuncAnimation(fig, update, frames=len(df), init_func=init,
                                      interval=50, blit=True)
        ani.save(savepath, fps=15)
        print(f"Saved animation to {savepath}")

