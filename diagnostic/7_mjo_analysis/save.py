"""Compatibility module for older notebooks.

The Hovmoller implementation lives in ``MJOPrecDiag.py``. This file used to
contain an indented method fragment, which made ``compileall`` fail as soon as
it scanned the diagnostics package.
"""

try:
    from .MJOPrecDiag import HovmollerPrecipAnalyzer
except ImportError:
    from MJOPrecDiag import HovmollerPrecipAnalyzer

__all__ = ["HovmollerPrecipAnalyzer"]
