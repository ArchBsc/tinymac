# Physical design results

After the GDS build passed, we downloaded `GDS_logs` from GitHub Actions and kept the main reports and layout files in this folder.

- `metrics.json`, `metrics.csv` — build statistics.
- `synthesis_stat.rpt` — synthesis results and cell area.
- `sta_summary.rpt`, `worst_setup.rpt`, `worst_hold.rpt` — timing analysis.
- `power_nom_*.rpt` — estimated power at different corners.
- `drc.magic.rpt`, `lvs.netgen.rpt`, `antenna_summary.rpt` — physical verification results.
- `warning.log` — build warnings.
- GDS, DEF, LEF, netlists, SDC and SPICE files — generated design files.

The reports and design files were copied from the original build without changing their contents. Some filenames were shortened. The source commit is recorded in `commit_id.json`.

Our summary of the results is in [physical_design.md](../../docs/physical_design.md).

The official submission, precheck and gate-level test artifacts are separate from this folder.
