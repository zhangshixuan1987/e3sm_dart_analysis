# Diagnostic Notebooks

Active land-atmosphere workflow drivers:

1. `land_atmosphere__prepare_metrics.ipynb` - configure inputs, inspect available experiments/variables, and prepare metric inputs.
2. `land_atmosphere__compute_coupling.ipynb` - compute terrestrial coupling diagnostics and intermediate coupling products.
3. `land_atmosphere__plot_diagnostics.ipynb` - plot model-versus-observation TCI/TCC diagnostics and comparison figures.

Legacy, duplicate, and specialized variants are kept in `archive/` so the main workflow stays readable.

Active data-assimilation diagnostic workflow drivers:

1. `analysis_da__obs_distribution.ipynb` - inspect and plot DART obs_seq observation distributions.
2. `analysis_da__obs_space_diagnostics_control.ipynb` - plot control obs_diag time-series diagnostics.
3. `analysis_da__obs_space_diagnostics_compare.ipynb` - compare obs_diag time-series diagnostics across experiments.
4. `analysis_da__obs_common_diagnostics_compare.ipynb` - compare common-observation diagnostics across experiments.
5. `analysis_da__obs_space_diagnostics_prof.ipynb` - plot vertical profile obs_diag diagnostics.
6. `analysis_da__obs_compare_diagnostics_prof.ipynb` - compare vertical profile obs_diag diagnostics across experiments.
