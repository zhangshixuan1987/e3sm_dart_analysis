# Diagnostics

This directory contains diagnostic notebooks, helper scripts, legacy NCL workflows,
and generated figures used for E3SM-DART analysis.

## Diagnostic Notebooks

Active land-atmosphere workflow drivers live in `jupyter/`:

1. `land_atmosphere__prepare_metrics.ipynb` - configure inputs, inspect available experiments/variables, and prepare metric inputs.
2. `land_atmosphere__compute_coupling.ipynb` - compute terrestrial coupling diagnostics and intermediate coupling products.
3. `land_atmosphere__plot_diagnostics.ipynb` - plot model-versus-observation TCI/TCC diagnostics and comparison figures.

Legacy, duplicate, and specialized variants are kept in `jupyter/archive/` so the
main workflow stays readable.

Active data-assimilation diagnostic workflow drivers live in `jupyter/`:

1. `analysis_da__obs_distribution.ipynb` - inspect and plot DART obs_seq observation distributions.
2. `analysis_da__obs_diagnostics_compare.ipynb` - compare obs_diag time-series diagnostics across experiments; switch modes with `PLOT_MODE`.
3. `analysis_da__obs_compare_multilevel_diagnostics.ipynb` - compare obs_diag diagnostics with multiple pressure levels per experiment panel.
4. `analysis_da__obs_profile_diagnostics.ipynb` - plot vertical profile obs_diag diagnostics; switch modes with `PROFILE_MODE`.

## Configs

`configs/` contains experiment dictionaries and configuration-building helpers
shared by the diagnostic notebooks. Keep reusable importable modules here; keep
standalone commands in `scripts/`.

## NCL Scripts

Shared legacy NCL and helper shell scripts used by the diagnostic workflows live
in `ncl_scripts/`.

- `ncl_scripts/obs_distribution/` contains scripts from the old `1_obs_distribution/` workflow.
- `ncl_scripts/obs_diagnostics/time_series/` contains helper scripts from the old `2_obs_diagnostics/time_series/` workflow.
- `ncl_scripts/obs_diagnostics/profile/` contains helper scripts from the old `2_obs_diagnostics/profile/` workflow.

Run scripts from their own directory unless the script itself documents another
working directory. Several NCL files use relative `load "./..."` statements.

The RMSE/bias profile backup directories document four regional scripts:

- Southern Hemisphere: `plot_rmse_bias_profil_eamv0_vs_eam_v1_T_SH.ncl`
- Northern Hemisphere: `plot_rmse_bias_profil_eamv0_vs_eam_v1_T_NH.ncl`
- Tropics: `plot_rmse_bias_profil_eamv0_vs_eam_v1_T_TP.ncl`
- North America: `plot_rmse_bias_profil_eamv0_vs_eam_v1_T_NA.ncl`

## Helper Scripts

`scripts/` contains helper scripts for running or batching the land-atmosphere
interaction workflow.
