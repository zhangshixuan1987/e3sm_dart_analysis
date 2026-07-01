import numpy as np
import xarray as xr

class LeadTimeSelector:
    """
    Utility to subset xarray time series based on S2S lead time windows.
    Supports both daily and sub-daily (e.g., 6-hourly) forecast data.
    """

    DEFAULT_WINDOWS = {
        "day01_15": (1, 15),
        "day16_30": (16, 30),
        "day31_45": (31, 45),
        "day46_60": (46, 60),
    }

    def __init__(self, init_time, lead_windows=None):
        """
        Parameters
        ----------
        init_time : str or np.datetime64
            Forecast initialization time.
        lead_windows : dict or None
            Dictionary of lead time windows. If None, uses DEFAULT_WINDOWS.
        """
        self.init_time = np.datetime64(init_time)
        self.lead_windows = lead_windows or self.DEFAULT_WINDOWS

    def compute_lead_days(self, time_coord):
        """
        Compute fractional lead days from forecast time.
        """
        return (time_coord - self.init_time) / np.timedelta64(1, "h") / 24.0

    def select_lead_window(self, data, window_key):
        """
        Select data subset within the specified lead time window.
        """
        if window_key not in self.lead_windows:
            raise ValueError(f"Unknown lead window: {window_key}")
        start_day, end_day = self.lead_windows[window_key]
        lead_days = self.compute_lead_days(data.time)
        mask = (lead_days >= start_day) & (lead_days < end_day + 1)
        return data.sel(time=mask)

    def split_all_windows(self, data):
        """
        Return a dictionary of all subsets for each defined lead time window.
        """
        return {
            key: self.select_lead_window(data, key)
            for key in self.lead_windows
        }
