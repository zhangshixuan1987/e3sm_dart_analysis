# experiment_configs.py

exp_dict1 = {
    'CTRLEN10': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/CTRLEN10_15day_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 10
    },
    'CAPTEN10': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/CAPTEN10_15day_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 10
    },
    'DARTEN20': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/DARTEN20_15day_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 20
    },
    'DARTEN40': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/DARTEN40_15day_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 40
    }
}

exp_dict2 = {
    'CTRLEN10': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/CTRLEN10_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 10
    },
    'DARTEN20': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/DARTEN20_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 20
    },
    'DARTEN40': {
        'path': '/pscratch/sd/z/zhan391/e3sm_dart/DARTEN40_F20TR_ne30pg2_r05_IcoswISC30E3r5_compy/archive/post/atm/180x360_aave/ts/daily',
        'template': '%(variable).%(ensemble)s.%(year).nc',
        'nens': 40
    }
}

def get_experiment_dict(key):
    if key == "v3_spinup":
        return exp_dict2
    elif key == "v3_hindcast":
        return exp_dict1
    else:
        raise ValueError(f"Unknown experiment key: {key}")

