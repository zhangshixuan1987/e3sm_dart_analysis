import os
import numpy as np
import xarray as xr
import xcdat as xc  
from typing import Dict, Tuple, List

# === Plotting ===
import matplotlib.pyplot as plt
from matplotlib.pylab import rcParams
from matplotlib.patches import Polygon
from matplotlib import ticker
from matplotlib.ticker import FuncFormatter
from matplotlib.ticker import ScalarFormatter, LogLocator

from brokenaxes import brokenaxes

# === Custom Color Maps and Visualization Tools ===
import cmaps as gvcmaps
import geocat.viz as gv
import geocat.viz.util as gvutil

class DartObsDiagReader:
    def __init__(self, config: dict):
        """
        Initialize the reader with a global config (e.g., for path resolution).
        """
        self.config = config

    def define_region(self, regnam: str = 'global') -> Tuple[Tuple[float, float], Tuple[float, float]]:
        reg_dict = {
            'global': [(-90, 90), (-180, 180)],
            'Northern Hemisphere': [(20, 90), (-180, 180)],
            'Southern Hemisphere': [(-90, -20), (-180, 180)],
            'Tropics': [(-20, 20), (-180, 180)],
            'North America': [(25, 55), (-125, -65)],
        }
        if regnam not in reg_dict:
            raise KeyError(f"Region '{regnam}' is not defined. Available regions: {list(reg_dict.keys())}")
        return reg_dict[regnam]

    def create_lev_str(self, lev, levp, lev_type) -> List[str]:
        levstr = []
        for i in range(len(lev)):
            if lev_type == 'pressure':
                levstr.append(f"{int(levp[i+1])}-{int(levp[i])} hPa")
            elif lev_type == 'height':
                levstr.append(f"{levp[i]}-{levp[i+1]} m")
            elif lev_type == 'model':
                levstr.append(f"{levp[i]}-{levp[i+1]} layer")
            else:
                raise ValueError(f"Unknown lev_type: {lev_type}")
        return levstr

    def read_dart_obs_diag(self, regnam: str, var: str, dtype: str, var_dict: Dict[str, str],
                           date: str, path: str, file: str) -> Tuple:
        rpath = os.path.join(path, file)
        print(f"Reading file: {rpath}")
        ds = xc.open_mfdataset(rpath, decode_times=False)

        time = ds['time'].values
        mlevel = ds['mlevel'].values
        mlevel_edges = ds['mlevel_edges'].values
        plevel = ds['plevel'].values
        plevel_edges = ds['plevel_edges'].values
        hlevel = ds['hlevel'].values
        hlevel_edges = ds['hlevel_edges'].values
        rank_bins = ds['rank_bins'].values
        region_names = np.array([char.decode('utf-8').strip() for char in ds['region_names'].values])
        ind_reg = int(np.where(region_names == regnam)[0][0])

        CopyMetaData = np.array([char.decode('utf-8').strip() for char in ds['CopyMetaData'].values])
        ind_vars = np.where(CopyMetaData == var_dict['CopySpread']) #[0][0])
        ind_rmse = np.where(CopyMetaData == var_dict['CopyRMSE'])   #[0][0])
        ind_npos = np.where(CopyMetaData == var_dict['CopyNposs'])  #[0][0])
        ind_nuse = np.where(CopyMetaData == var_dict['CopyNused'])  #[0][0])

        sprd = rmse = npos = nuse = hrank = np.array([])

        if dtype == 'guess':
            varname = f"{var_dict['name']}_guess"
            if varname in ds: 
                tsprd = ds[varname].values[:,ind_vars,:,ind_reg]
                trmse = ds[varname].values[:,ind_rmse,:,ind_reg]
                tnpos = ds[varname].values[:,ind_npos,:,ind_reg]
                tnuse = ds[varname].values[:,ind_nuse,:,ind_reg]
                sprd  = tsprd[0,0,:,:]
                rmse  = trmse[0,0,:,:]
                npos  = tnpos[0,0,:,:]
                nuse  = tnuse[0,0,:,:]
        elif dtype == 'VPguess':
            varname = f"{var_dict['name']}_{var_dict['type2']}"
            if varname in ds: 
                vsprd = ds[varname].values[ind_vars,:,ind_reg]
                vrmse = ds[varname].values[ind_rmse,:,ind_reg]
                vnpos = ds[varname].values[ind_npos,:,ind_reg]
                vnuse = ds[varname].values[ind_nuse,:,ind_reg]
                sprd  = vsprd[0,0,:]
                rmse  = vrmse[0,0,:]
                npos  = vnpos[0,0,:]
                nuse  = vnuse[0,0,:]
        elif dtype == 'guess_RankHist':
            varname = f"{var_dict['name']}_{var_dict['type3']}"
            if varname in ds: 
                hrank = ds[varname].values[0, :, :, ind_reg]
                       
        ds.close()
        return time, plevel, plevel_edges, mlevel, mlevel_edges, hlevel, hlevel_edges, sprd, rmse, npos, nuse, hrank

    def extract_metrics_data(self, var: str, var_dict: Dict[str, str], dtype: str,
                             regnam: str, exp_dict: Dict[str, dict]) -> Tuple[Dict, List[str]]:
        data_dict = {}
        levstr = []

        for exp, exp_info in exp_dict.items():
            date = exp_info['period']
            time_unit = f"days since {date[:4]}-{date[4:6]}-{date[6:8]}"
            path, file = self.resolve_dart_file_path(exp_info, exp, date)

            results = self.read_dart_obs_diag(regnam, var, dtype, var_dict, date, path, file)
            (time, plev, plev_edges, mlev, mlev_edges,
             hlev, hlev_edges, sprd, rmse, npos, nuse, hrank) = results
            if isinstance(npos, np.ndarray) and isinstance(nuse, np.ndarray) and npos.size > 0 and nuse.size > 0:
                rejection = np.where(npos > 0, 100.0 - (nuse * 100.0 / npos), np.nan)
            else:
                rejection = np.array([])
                
            lev_type = var_dict.get('lev_type', 'pressure')
            lev_map = {
                'pressure': (plev, plev_edges),
                'height': (hlev, hlev_edges),
                'model': (mlev, mlev_edges)
            }

            if lev_type not in lev_map:
                raise ValueError(f"Invalid level type: {lev_type}")

            lev, levp = lev_map[lev_type]
            levstr = self.create_lev_str(lev, levp, lev_type)

            data_dict[exp] = {
                'time': np.asarray(time) - time[0],
                'time_unit': time_unit,
                'rmse': rmse,
                'spread': sprd,
                'rejection': rejection,
                'histrank': hrank,
                'rmse_str': 'RMSE',
                'spread_str': 'Total Spread',
                'rejection_str': 'Data Rejection(%)',
                'lev': lev,
                'levp': levp,
                'period': date
            }

        return data_dict, levstr

    def resolve_dart_file_path(self, exp_info: dict, exp: str, date: str) -> Tuple[str, str]:
        """
        Resolve the DART observation diagnostic file path and filename
        based on a templated config and experiment info.
        """
        path = self.config['path_template'] \
            .replace('%(RUNNAME)', exp_info['run']) \
            .replace('%(CASENAME)', exp_info['key']) \
            .replace('%(DIAG)', exp_info['diag2'])

        file = self.config['file_template'] \
            .replace('%(RUNNAME)', exp) \
            .replace('%(RES)', self.config['resolution']) \
            .replace('%(MACH)', self.config['machine']) \
            .replace('%(KEY)', self.config['diag_key']) \
            .replace('%(TIME)', date)

        return path, file
    
    @staticmethod
    def extract_obs_group() -> dict:
        """
        Returns a dictionary mapping observation group names to lists of observation variable types.
        """
        return {
          'Conventional': {
            'plevel': [
              'TEMPERATURE', 'SPECIFIC_HUMIDITY', 'PRESSURE',
              'RADIOSONDE_U_WIND_COMPONENT', 'RADIOSONDE_V_WIND_COMPONENT',
              'RADIOSONDE_GEOPOTENTIAL_HGT', 'RADIOSONDE_TEMPERATURE',
              'RADIOSONDE_SPECIFIC_HUMIDITY', 'DROPSONDE_TEMPERATURE',
              'DROPSONDE_U_WIND_COMPONENT', 'DROPSONDE_V_WIND_COMPONENT',
              'DROPSONDE_SPECIFIC_HUMIDITY', 'AIRCRAFT_U_WIND_COMPONENT',
              'AIRCRAFT_V_WIND_COMPONENT', 'AIRCRAFT_TEMPERATURE',
              'AIRCRAFT_SPECIFIC_HUMIDITY', 'ACARS_U_WIND_COMPONENT',
              'ACARS_V_WIND_COMPONENT', 'ACARS_TEMPERATURE',
              'ACARS_SPECIFIC_HUMIDITY'
            ],
            'surface': [
              'RADIOSONDE_SURFACE_PRESSURE', 'DROPSONDE_SURFACE_PRESSURE',
              'RADIOSONDE_SURFACE_ALTIMETER', 'DROPSONDE_SURFACE_ALTIMETER',
              'METAR_ALTIMETER', 'MESONET_SURFACE_ALTIMETER',
              'MARINE_SFC_U_WIND_COMPONENT', 'MARINE_SFC_V_WIND_COMPONENT',
              'MARINE_SFC_TEMPERATURE', 'MARINE_SFC_SPECIFIC_HUMIDITY',
              'MARINE_SFC_PRESSURE', 'LAND_SFC_U_WIND_COMPONENT',
              'LAND_SFC_V_WIND_COMPONENT', 'LAND_SFC_TEMPERATURE',
              'LAND_SFC_SPECIFIC_HUMIDITY', 'LAND_SFC_PRESSURE',
              'MARINE_SFC_ALTIMETER', 'LAND_SFC_ALTIMETER'
            ]
          },
          'Satellite': {
            'hlevel': ['GPSRO_REFRACTIVITY'],
            'plevel': [
              'SAT_TEMPERATURE', 'SAT_TEMPERATURE_ELECTRON',
              'SAT_TEMPERATURE_ION', 'SAT_DENSITY_NEUTRAL_O3P', 'SAT_DENSITY_NEUTRAL_O2',
              'SAT_DENSITY_NEUTRAL_N2', 'SAT_DENSITY_NEUTRAL_N4S', 'SAT_DENSITY_NEUTRAL_NO',
              'SAT_DENSITY_NEUTRAL_N2D', 'SAT_DENSITY_NEUTRAL_N2P', 'SAT_DENSITY_NEUTRAL_H',
              'SAT_DENSITY_NEUTRAL_HE', 'SAT_DENSITY_NEUTRAL_CO2', 'SAT_DENSITY_NEUTRAL_O1D',
              'SAT_DENSITY_ION_O4SP', 'SAT_DENSITY_ION_O2P', 'SAT_DENSITY_ION_N2P',
              'SAT_DENSITY_ION_NP', 'SAT_DENSITY_ION_O2DP', 'SAT_DENSITY_ION_O2PP',
              'SAT_DENSITY_ION_HP', 'SAT_DENSITY_ION_HEP', 'SAT_DENSITY_ION_E',
              'SAT_VELOCITY_U', 'SAT_DENSITY_ION_NOP', 'SAT_VELOCITY_V', 'SAT_VELOCITY_W',
              'SAT_VELOCITY_U_ION', 'SAT_VELOCITY_V_ION', 'SAT_VELOCITY_W_ION',
              'SAT_VELOCITY_VERTICAL_O3P', 'SAT_VELOCITY_VERTICAL_O2',
              'SAT_VELOCITY_VERTICAL_N2', 'SAT_VELOCITY_VERTICAL_N4S',
              'SAT_VELOCITY_VERTICAL_NO', 'SAT_F107', 'SAT_RHO', 'GPS_PROFILE',
              'COSMIC_ELECTRON_DENSITY', 'GND_GPS_VTEC', 'CHAMP_DENSITY',
              'MIDAS_TEC', 'SSUSI_O_N2_RATIO', 'GPS_VTEC_EXTRAP', 'SABER_TEMPERATURE',
              'AURAMLS_TEMPERATURE', 'SAT_U_WIND_COMPONENT', 'SAT_V_WIND_COMPONENT',
              'ATOV_TEMPERATURE', 'AIRS_TEMPERATURE', 'AIRS_SPECIFIC_HUMIDITY',
              'GPS_PRECIPITABLE_WATER', 'CIMMS_AMV_U_WIND_COMPONENT',
              'CIMMS_AMV_V_WIND_COMPONENT'
            ],
            'surface': [
              'VADWND_U_WIND_COMPONENT', 'VADWND_V_WIND_COMPONENT'
            ]
          }
        }
    
    
class ObsDiagPlotter:
    def __init__(self, var, var_dict, data_dict, fig_path,
                 plevstr, regnam=None, fgw=20, fgh=12, hs=0.2, ws=0.2):
        """
        A class for plotting observation diagnostic time series and profiles.

        Parameters:
        -----------
        var : str
            Variable name (e.g., "TEMPERATURE").
        var_dict : dict
            Metadata for the variable including axis ranges.
        data_dict : dict
            Diagnostic data per experiment.
        fig_path : str
            Path to save the figures.
        plevstr : list
            List of pressure levels (e.g., ["1000hPa", "850hPa"]).
        regnam : str, optional
            Region name for labeling (e.g., "global").
        fgw, fgh : float
            Figure width and height.
        hs, ws : float
            Subplot spacing (hspace, wspace).
        """
        self.var = var
        self.var_dict = var_dict
        self.data_dict = data_dict
        self.fig_path = fig_path
        self.plevstr = plevstr
        self.regnam = regnam
        self.fgw = fgw
        self.fgh = fgh
        self.hs = hs
        self.ws = ws
        self._prepare_common()

    def _prepare_common(self):
        self.fontz = 12  # could be scaled dynamically if desired
        self.cmap = {
            'blue': '#377eb8',
            'orange': '#ff7f00',
            'green': '#4daf4a',
            'pink': '#f781bf',
            'brown': '#a65628',
            'purple': '#984ea3',
            'gray': '#999999',
            'red': '#e41a1c',
            'yellow': '#dede00'
        }

    def plot_timeseries(self, plev, xmin=None, xmax=None, xmean = None, xunit = None, show=False, save=True, uniform_lthk=True):
        """
        Plot time series diagnostics for a given pressure level.
        """
        try:
            dk = self.plevstr.index(plev)
        except ValueError:
            raise ValueError(f"Level '{plev}' not found in plevstr list.")

        nrows = len(self.data_dict)
        fig, axes = plt.subplots(nrows=nrows, ncols=1, figsize=(self.fgw, self.fgh), squeeze=False)
        axes = axes.flatten()
        
        if uniform_lthk: 
            lnthks = np.full(nrows, 2.0) 
            mksize = np.full(nrows, 6.0)
        else:
            lnthks = np.linspace(1, 4, nrows)
            mksize = np.linspace(5, 10, nrows)
        
        # Determine global time bounds if not specified
        if xmin is None:
            xmin = min(min(d['time']) for d in self.data_dict.values())
        if xmax is None:
            xmax = max(max(d['time']) for d in self.data_dict.values())
            
        for j, (exp, d) in enumerate(self.data_dict.items()):
            # Get axis limits
            if exp.lower() == 'ctrlen10':
                y1min, y1max = self.var_dict['y1aix0']
                y2min, y2max = self.var_dict['y2aix0']
            else:
                y1min, y1max = self.var_dict['y1aix']
                y2min, y2max = self.var_dict['y2aix']
        
            # Time filter mask
            time = d['time']
            mask = (time >= xmin) & (time <= xmax)
            time_filtered = time[mask]
            rmse_filtered = d['rmse'][mask, dk]
            spread_filtered = d['spread'][mask, dk]
            rejection_filtered = d['rejection'][mask, dk]
        
            # Plotting
            ax = axes[j]
            ax2 = ax.twinx()

            ax.plot(time_filtered, rmse_filtered, label="RMSE", color=self.cmap['red'],
                    marker='o', linestyle='-', linewidth=lnthks[j], markersize=mksize[j])
            ax.plot(time_filtered, spread_filtered, label="Spread", color=self.cmap['blue'],
                    marker='v', linestyle='-', linewidth=lnthks[j], markersize=mksize[j])
            ax.set_ylabel(f"{d['rmse_str']} & {d['spread_str']}", fontsize=self.fontz + 2)

            gvutil.set_axes_limits_and_ticks(ax, xlim=(xmin, xmax), ylim=(y1min, y1max))
            ax.tick_params(labelsize=self.fontz, top=False, right=False)
            ax.set_title(f"{exp} — {self.var} at {plev}", fontsize=self.fontz + 2, pad=10)
            if xunit: 
                ax.set_xlabel(f"Days since {xunit}", fontsize=self.fontz + 2)
            
            ax2.plot(time_filtered, rejection_filtered, label="Rejection", color=self.cmap['gray'],
                     marker='*', linestyle='-', linewidth=lnthks[j], markersize=mksize[j])
            ax2.set_ylabel(d['rejection_str'], fontsize=self.fontz + 2)
            gvutil.set_axes_limits_and_ticks(ax2, ylim=(y2min, y2max), yticks=np.arange(0, 101, 20))
            ax2.tick_params(labelsize=self.fontz, top=False, left=False)

            # Combined legend
            handles1, labels1 = ax.get_legend_handles_labels()
            handles2, labels2 = ax2.get_legend_handles_labels()
            ax.legend(handles1 + handles2, labels1 + labels2, fontsize=self.fontz, loc='upper left')
            
            valid_len = len(rmse_filtered)
            if valid_len > xmean:
                rmse_slice = rmse_filtered[-xmean:]
                spread_slice = spread_filtered[-xmean:]
            else:
                rmse_slice = rmse_filtered
                spread_slice = spread_filtered

            mean_rmse = np.nanmean(rmse_slice)
            mean_spread = np.nanmean(spread_slice)

            ymin, ymax = ax.get_ylim()
            ypos = ymax - 0.1 * (ymax - ymin)
            stats_text = f"Mean RMSE: {mean_rmse:.2f}\nMean Spread: {mean_spread:.2f}"
            ax.annotate(
                stats_text,
                xy=(0.98, ypos),
                xycoords=("axes fraction", "data"),
                fontsize=self.fontz,
                ha="right", va="top",
                bbox=dict(boxstyle="round", facecolor="white", edgecolor="gray", alpha=0.6)
            )
            
        plt.subplots_adjust(hspace=self.hs, wspace=self.ws)
        if show:
            plt.show()
        if save:
            os.makedirs(self.fig_path, exist_ok=True)
            reg_str = self.regnam.replace(" ", "_") if self.regnam else "region"
            fname = os.path.join(self.fig_path, f"fig_obs_diag_ts_{self.var}_{reg_str}_{plev.replace(' ','')}.pdf")
            fig.savefig(fname, bbox_inches='tight')

    def plot_exp_profile(self, show=True, save=True, panel_width = 12, panel_height = 16):
        """
        Plot vertical profile of RMSE, Spread, and Rejection.
        """
        ncols = len(self.data_dict)
        fig, axes = plt.subplots(
            nrows=1, ncols=ncols,
            figsize=(panel_width, panel_height),
            squeeze=False
        )        
        
        lnthks = np.linspace(1, 8, ncols)
        mksize = np.linspace(10, 20, ncols)
        x1min, x1max = self.var_dict['y1aix']
        x2min, x2max = self.var_dict['y2aix']
        lev_label = {
            'pressure': 'Pressure (hPa)',
            'height': 'Height (m)',
            'model': 'Model Level'
        }.get(self.var_dict.get('lev_type'), 'Level')

        for j, (exp, d) in enumerate(self.data_dict.items()):
            ax = axes[0, j]
            ax2 = ax.twiny()
            lev = d['lev']

            ax.plot(d['rmse'], lev, label="RMSE", color=self.cmap['red'],
                    marker="o", markersize=mksize[1], linestyle="-", linewidth=lnthks[1])
            ax.plot(d['spread'], lev, label="Spread", color=self.cmap['blue'],
                    marker="v", markersize=mksize[1], linestyle="-", linewidth=lnthks[1])
            ax.set_xlabel(f"{d['rmse_str']} & {d['spread_str']}", fontsize=self.fontz*1.5)
            ax.set_ylabel(lev_label, fontsize=self.fontz*1.5)
            gvutil.set_axes_limits_and_ticks(ax, xlim=(x1min, x1max))
            #gvutil.add_major_minor_ticks(ax, labelsize=self.fontz*1.5)
            ax.tick_params(labelsize=self.fontz*1.5, top=False, right=False)
            ax.set_title(f"{exp} — {self.var}", fontsize=self.fontz*1.5)

            if self.var_dict.get('lev_type') == 'pressure':
                ax.invert_yaxis()

            ax2.plot(d['rejection'], lev, label="Rejection", color=self.cmap['gray'],
                     marker="*", markersize=mksize[1], linestyle="-", linewidth=lnthks[1])
            ax2.set_xlabel(d['rejection_str'], fontsize=self.fontz*1.5)
            gvutil.set_axes_limits_and_ticks(ax2, xlim=(x2min, x2max))
            #gvutil.add_major_minor_ticks(ax2, labelsize=self.fontz*1.5)
            ax2.tick_params(labelsize=self.fontz*1.5, bottom=False, left=False)

            # Combined legend
            handles1, labels1 = ax.get_legend_handles_labels()
            handles2, labels2 = ax2.get_legend_handles_labels()
            ax.legend(handles1 + handles2, labels1 + labels2, fontsize=self.fontz*1.5, loc='upper right')

        plt.subplots_adjust(hspace=self.hs, wspace=self.ws)
        if show:
            plt.show()
        if save:
            os.makedirs(self.fig_path, exist_ok=True)
            reg_str = self.regnam.replace(" ", "_") if self.regnam else "region"
            fname = os.path.join(self.fig_path, f"fig_obs_diag_prof_{self.var}_{reg_str}.pdf")
            fig.savefig(fname, bbox_inches='tight')

    def plot_metric_profile(self, variable = None, show=True, save=True,
                            panel_width=12, panel_height=16,
                            xmin=None, xmax=None,
                            ymin=None, ymax=None,
                            yscale="linear"):
        """
        Plot vertical profiles of RMSE, Spread/RMSE, and Rejection in three horizontal panels.
        - Uses log-scaled x-axis with plain number tick labels (except Rejection).
        - Spread/RMSE plotted in panel 2 to indicate ensemble dispersiveness.
        - Rejection panel uses fixed linear scale [0, 100].
        - Legend shown only in the Rejection panel.

        Parameters:
            show (bool): Whether to display the figure.
            save (bool): Whether to save the figure.
            panel_width (int): Total width of the figure.
            panel_height (int): Total height of the figure.
            xmin (float): Optional min value for RMSE x-axis (log scale).
            xmax (float): Optional max value for RMSE x-axis (log scale).
        """
        fig, axes = plt.subplots(
            nrows=1, ncols=3,
            figsize=(panel_width, panel_height),
            sharey=True
        )

        metrics = ['rmse', 'spread', 'rejection']
        metric_labels = ['RMSE', 'Spread / RMSE', 'Rejection']
        lev_label = {
            'pressure': 'Pressure (hPa)',
            'height': 'Height (m)',
            'model': 'Model Level'
        }.get(self.var_dict.get('lev_type'), 'Level')

        exp_names = list(self.data_dict.keys())
        color_list = plt.cm.tab10.colors
        marker_list = ['o', 's', '^', 'v', '*', 'D', 'P', 'X']
        linestyle_list = ['-', '--', '-.', ':']

        style_map = {
            exp: {
                'color': color_list[i % len(color_list)],
                'marker': marker_list[i % len(marker_list)],
                'linestyle': linestyle_list[i % len(linestyle_list)],
                'linewidth': 1.5 + 0.5 * (i % 3),
                'markersize': 8 + (i % 3) * 2
            }
            for i, exp in enumerate(exp_names)
        }
        
        #typlical log ticks for axis setup 
        logx_ticks = [0.01, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100]
        logy_ticks = [1000, 700, 500, 300, 200, 100, 50, 30, 20, 10, 5, 2, 1]

        for i, (metric, label) in enumerate(zip(metrics, metric_labels)):
            ax = axes[i]
            for exp, d in self.data_dict.items():
                style = style_map[exp]
                lev = d['lev']

                if metric == 'spread':
                    spread = np.clip(d['spread'], 1e-6, None)
                    rmse = np.clip(d['rmse'], 1e-6, None)
                    values = spread / rmse
                else:
                    values = np.clip(d[metric], 1e-3, None)

                ax.plot(values,lev,
                        label=exp,
                        color=style['color'],
                        marker=style['marker'],
                        linestyle=style['linestyle'],
                        linewidth=style['linewidth'],
                        markersize=style['markersize'])
                
            ax.set_yscale(yscale)
            ax.yaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:g}"))
            ax.set_ylim(ymin, ymax)
            ax.set_yticks([t for t in logy_ticks if ymin <= t <= ymax])
            
            # Axis config per metric
            if metric == 'rejection':
                ax.set_xscale('log')
                ax.xaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:g}"))
                ax.set_xlim(1, 100)
                ax.set_xticks([1,2,5,10,20,50,100])
            elif metric == 'spread':
                ax.set_xscale('log')
                ax.xaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:g}"))
                ax.set_xlim(0.5, 2.0)
                ax.set_xticks([0.4,0.6,0.8,1.2,1.6,2.0])
                ax.axvline(1.0, color='black', linestyle=':', linewidth=1)
            else:  # RMSE
                ax.set_xscale('log')
                ax.xaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:g}"))
                if xmin is not None and xmax is not None:
                    ax.set_xlim(xmin, xmax)
                    ax.set_xticks([t for t in logx_ticks if xmin <= t <= xmax])
                else:
                    ax.set_xlim(0.1, 10)
                    ax.set_xticks([t for t in logx_ticks if 0.1 < t <= 10])

            ax.set_xlabel(label, fontsize=self.fontz * 1.4)
            ax.tick_params(which='minor', label1On=False)
            
            if i == 0:
                ax.set_ylabel(lev_label, fontsize=self.fontz * 1.4)
            if self.var_dict.get('lev_type') == 'pressure':
                ax.invert_yaxis()

            ax.tick_params(labelsize=self.fontz * 1.2)
            ax.set_title(f"{label} ({variable})", fontsize=self.fontz * 1.4)

            if i == 2:
                handles, labels = ax.get_legend_handles_labels()
                ax.legend(
                    handles, labels,
                    loc='best',
                    fontsize=self.fontz,
                    frameon=True,
                    handlelength=2.5,
                    labelspacing=0.6
                )

        plt.tight_layout()
        plt.subplots_adjust(wspace=0.25)

        if show:
            plt.show()
        if save:
            os.makedirs(self.fig_path, exist_ok=True)
            reg_str = self.regnam.replace(" ", "_") if self.regnam else "region"
            fname = os.path.join(
                self.fig_path,
                f"fig_obs_diag_prof_{self.var}_{reg_str}_logx_dispersion.pdf"
            )
            fig.savefig(fname, bbox_inches='tight')
