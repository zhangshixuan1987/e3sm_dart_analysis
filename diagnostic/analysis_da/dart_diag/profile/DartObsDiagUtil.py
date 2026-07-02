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

    def build_ts_var_dict(
        self, var_key: str = None, name: str = None,
        y1axis: list = None, y2axis: list = None
    ) -> dict:
        var_key = var_key or 'RADIOSONDE_U'
        name = name or 'RADIOSONDE_U_WIND_COMPONENT'
        entry = {
            'name': name,
            'lev_type': 'pressure',
            'CopySpread': 'totalspread',
            'CopyRMSE': 'rmse',
            'CopyNposs': 'Nposs',
            'CopyNused': 'Nused',
            'type1': 'guess',
            'type2': 'VPguess',
            'type3': 'guess_RankHist',
            'y1aix': y1axis if y1axis is not None else [0, 10],
            'y2aix': [0, 100],
            'y1aix0': y2axis if y2axis is not None else [0, 10],
            'y2aix0': [0, 100],
        }
        return {var_key: entry}
    
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
    
    def read_dart_obs_diag(
        self, regnam: str, var: str, dtype: str, var_dict: Dict[str, str],
        date: str, path: str, file: str
    ) -> Tuple:
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

    def extract_metrics_data(
        self, var: str, var_dict: Dict[str, str], 
        dtype: str, regnam: str, diag_set: str, 
        exp_dict: Dict[str, dict],
    ) -> Tuple[Dict, List[str]]:
        
        data_dict = {}
        levstr = []
        
        for exp, exp_info in exp_dict.items():
            date = exp_info['period']
            time_unit = f"days since {date[:4]}-{date[4:6]}-{date[6:8]}"
            path, file = self.resolve_dart_file_path(
                exp_info, exp, diag_set, date
            )
            results = self.read_dart_obs_diag(
                regnam, var, 
                dtype, var_dict, 
                date, path, file
            )
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

    def resolve_dart_file_path(
        self, exp_info: dict, exp: str, 
        diag_set: str, date: str
    ) -> Tuple[str, str]:
        """
        Resolve the DART observation diagnostic file path and filename
        based on a templated config and experiment info.
        """
        path = self.config['path_template'] \
            .replace('%(RUNNAME)', exp_info['run']) \
            .replace('%(CASENAME)', exp_info['key']) \
            .replace('%(DIAG)', exp_info[diag_set])
            
        file = self.config['file_template'] \
            .replace('%(RUNNAME)', exp_info['run']) \
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
    