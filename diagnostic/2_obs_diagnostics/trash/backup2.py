def create_ts_var_entry(
    name, 
    lev_type='pressure', 
    spread='totalspread', 
    rmse='rmse', 
    nposs='Nposs', 
    nused='Nused', 
    type1='guess', 
    type2='VPguess', 
    type3='guess_RankHist', 
    y1aix=[0, 10], 
    y2aix=[0, 100],
    y1aix0=[0, 10], 
    y2aix0=[0, 100],
    ):
    """Factory to create a standard time series variable dictionary entry."""
    return {
        'name': name,
        'lev_type': lev_type,
        'CopySpread': spread,
        'CopyRMSE': rmse,
        'CopyNposs': nposs,
        'CopyNused': nused,
        'type1': type1,
        'type2': type2,
        'type3': type3,
        'y1aix': y1aix,
        'y2aix': y2aix,
        'y1aix0': y1aix0,
        'y2aix0': y2aix0,
    }

def build_ts_var_dict():
    """Constructs the full variable dictionary for time series data using the factory."""
    return {
        'RADIOSONDE_U': create_ts_var_entry('RADIOSONDE_U_WIND_COMPONENT',
                                            y1aix=[0, 8],y2aix=[0, 100],
                                            y1aix0=[0, 16],y2aix0=[0,100]),
        'RADIOSONDE_V': create_ts_var_entry('RADIOSONDE_V_WIND_COMPONENT',
                                            y1aix=[0, 8],y2aix=[0, 100],
                                            y1aix0=[0, 16],y2aix0=[0,100]),
        'RADIOSONDE_T': create_ts_var_entry('RADIOSONDE_TEMPERATURE',
                                            y1aix=[0, 4],y2aix=[0, 100],
                                            y1aix0=[0,8],y2aix0=[0,100]),
        'RADIOSONDE_Q': create_ts_var_entry('RADIOSONDE_SPECIFIC_HUMIDITY',
                                            y1aix=[0,3],y2aix=[0, 100],
                                            y1aix0=[0,3],y2aix0=[0,100]),
        'SAT_U': create_ts_var_entry('SAT_U_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),
        'SAT_V': create_ts_var_entry('SAT_V_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),
        'SAT_V': create_ts_var_entry('SAT_V_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),   
        'SAT_V': create_ts_var_entry('SAT_V_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),  
        'AIRCRAFT_U': create_ts_var_entry('AIRCRAFT_U_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),  
        'AIRCRAFT_V': create_ts_var_entry('AIRCRAFT_V_WIND_COMPONENT',
                                     y1aix=[0, 8],y2aix=[0, 100],
                                     y1aix0=[0,16],y2aix0=[0,100]),  
    }

def draw_ts_diagnostics(var_dict, exp_dict, reader, fig_path):
    """
    Main processing function for time series diagnostics using DartObsDiagReader.

    Parameters:
    -----------
    var_dict : dict
        Dictionary of variable metadata.
    exp_dict : dict
        Experiment metadata.
    reader : DartObsDiagReader
        Initialized reader object with config and utility methods.
    fig_path : str
        Output path for storing plots.
    """
    dtype = "guess"  # Can be changed to 'VPguess' or 'guess_RankHist' as needed
    regnams = ['Northern Hemisphere', 'Southern Hemisphere', 'Tropics', 'North America'] #'global']

    for regnam in regnams:
        for var in var_dict: 
            try:
                print(f"\n>>> Processing variable '{var}' in region '{regnam}'")
                
                # Retrieve diagnostics data and pressure levels
                data_dict, lev_str = reader.extract_metrics_data(
                    var=var,
                    var_dict=var_dict[var],
                    dtype=dtype,
                    regnam=regnam,
                    exp_dict=exp_dict
                )
                
                # Initialize the plotter class
                plotter = ObsDiagPlotter(
                    var=var,
                    var_dict=var_dict[var],
                    data_dict=data_dict,
                    fig_path=fig_path,
                    plevstr=lev_str,
                    regnam=regnam,
                    fgw=10,
                    fgh=12,
                    hs=0.5,
                    ws=0.5
                )
                
                # Generate the time series plot
                for lev in lev_str: 
                    print(f'ploting {lev}')
                    plotter.plot_timeseries(lev, xmin=0, xmax=31, show = False, save = True)
                
            except Exception as e:
                print(f"[ERROR] Failed to process '{var}' in '{regnam}': {e}")

def get_config():
    """Returns the configuration dictionary."""
    return {
        'case_name': 'JAN2011',
        'resolution': "F20TR_ne30pg2_r05_IcoswISC30E3r5",
        'machine': "compy",
        'diag_key': "obs_diag_output",
        'frequency': "6hourly",
        'region': 'Northern Hemisphere',
        'path_template': "/compyfs/zhan391/v3_dart_cda_scratch/%(RUNNAME)/archive/%(CASENAME)/dart_diagnostics/%(DIAG)",
        'file_template': "%(RUNNAME)_%(RES)_%(MACH).dart.e.eam_%(KEY).%(TIME).nc"
    }

def extract_exp_info(exp_name: str = None) -> dict:
    """
    Returns experiment metadata dictionary for DART/CTRL ensemble configurations.
    
    Parameters:
    -----------
    exp_name : str, optional
        Specific experiment name to extract (e.g., 'DARTEN10').
    
    Returns:
    --------
    dict
        Experiment metadata dictionary (single entry if `exp_name` is specified).
    """
    exp_dict = {
        'CTRLEN10': {
            'run': 'CTRLEN10_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy',
            'key': 'dart_en10',
            'diag1': 'obs_seq',
            'diag2': 'obs_diag',
            'diag3': 'closest_member',
            'period': '2011120100-2012012000',
        },
        'DARTEN10': {
            'run': 'DARTEN10_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy',
            'key': 'dart_en10',
            'diag1': 'obs_seq',
            'diag2': 'obs_diag',
            'diag3': 'closest_member',
            'period': '2011120100-2012010106',
        },
        'DARTEN20': {
            'run': 'DARTEN20_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy',
            'key': 'dart_en20',
            'diag1': 'obs_seq',
            'diag2': 'obs_diag',
            'diag3': 'closest_member',
            'period': '2011120100-2012011018',
        },
        'DARTEN40': {
            'run': 'DARTEN40_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy',
            'key': 'dart_en40',
            'diag1': 'obs_seq',
            'diag2': 'obs_diag',
            'diag3': 'closest_member',
            'period': '2011120100-2011123106',
        },
        # 'DARTEN80': { ... }
    }

    if exp_name:
        return {exp_name: exp_dict[exp_name]} if exp_name in exp_dict else {}

    return exp_dict

