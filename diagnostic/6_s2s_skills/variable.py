import os

# Define ERA5 default location and filename template
DEFAULT_REF_PATH = "/pscratch/sd/z/zhan391/e3sm_dart/Observations/ERA5/6hourly"
DEFAULT_TEMPLATE = "ERA5.6hourly.en00.{var}.{year}01-{year}12.nc"

# Main variable configuration dictionary
variable_dict = {
    "PSL": {
        "unit": "Pa",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "PRECT": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "U200": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "U500": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "U850": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "V200": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "V500": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "V850": {
        "unit": "m/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "T200": {
        "unit": "K",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "T500": {
        "unit": "K",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "T850": {
        "unit": "K",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Q200": {
        "unit": "kg/kg",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Q500": {
        "unit": "kg/kg",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Q850": {
        "unit": "kg/kg",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "OMEGA200": {
        "unit": "Pa/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "OMEGA500": {
        "unit": "Pa/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "OMEGA850": {
        "unit": "Pa/s",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Z200": {
        "unit": "m2/s2",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Z500": {
        "unit": "m2/s2",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    "Z850": {
        "unit": "m2/s2",
        "ref_path": DEFAULT_REF_PATH,
        "ref_template": DEFAULT_TEMPLATE
    },
    # Example custom override:
    # "TREFHT": {
    #     "unit": "K",
    #     "ref_path": "/custom/path/for/trefht",
    #     "ref_template": "custom_template_trefht_{year}.nc"
    # }
}


def get_variable_file_path(var: str, year: int) -> str:
    """
    Generate the full file path for a given variable and year.

    Parameters:
        var (str): Variable name.
        year (int): Year to insert into the template.

    Returns:
        str: Full path to the file.
    """
    if var not in variable_dict:
        raise ValueError(f"Variable '{var}' is not defined in the configuration.")
    
    config = variable_dict[var]
    path = config["ref_path"]
    template = config["ref_template"]
    filename = template.format(var=var, year=year)
    return os.path.join(path, filename)
