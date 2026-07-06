# NCL Scripts

Shared legacy NCL and helper shell scripts used by the diagnostic workflows.

- `obs_distribution/` contains scripts from the old `1_obs_distribution/` workflow.
- `obs_diagnostics/time_series/` contains helper scripts from the old `2_obs_diagnostics/time_series/` workflow.
- `obs_diagnostics/profile/` contains helper scripts from the old `2_obs_diagnostics/profile/` workflow.

Run scripts from their own directory unless the script itself documents another working directory. Several NCL files use relative `load "./..."` statements.
