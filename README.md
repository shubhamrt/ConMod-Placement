# Placement of restoration structures for wind erosion control: data and code

Data and analysis code for Tiwari, Edwards, Young, Duniway and Webb, *Strategic placement of
restoration structures reduces wind erosion in drylands* (submitted).

Horizontal sediment flux (Q, g m⁻¹ d⁻¹) was estimated with the AERO model (Edwards et al. 2022,
Aeolian Research 54, 100769). The model is not included here; the analysis starts from the flux
estimates in `data/`.

## data/

| File | Contents |
|---|---|
| `plots_1500.csv` | The 1,500 study plots: AIM PrimaryKey, vegetation type, location, cover, height, gap summaries, transect length |
| `gap_heights.csv` | Canopy gaps for each plot with bordering vegetation heights (used to rank gaps for scaled gap placement) |
| `flux_baseline.csv` | Q without structures, by plot and wind speed |
| `flux_placement.csv` | Q with structures, by plot, strategy, prescribed density and wind speed. Missing rows are failed model runs |
| `flux_sensitivity.csv` | Q for the 90-plot subsample under seven AERO parameter sets |
| `aim_locations.csv` | Locations of all AIM plots in the study region (background of Figure 2) |

Strategy codes: `targeted` = largest-gap, `scaled` = scaled gap, `proportional`, `cellgrid` = cell-grid.
AIM data are available from the Landscape Data Commons (https://landscapedatacommons.org).

## code/

Python 3 (numpy, pandas) and MATLAB (R2023a or later).

1. `python build_results.py` – flux reductions, reduction efficiency, paired contrasts, Table S3
2. `python report_numbers.py` – numbers reported in the text
3. `python sensitivity.py` – Table S5
4. `fig2_plots.m`, `fig3_schematic.m`, `fig4_initial_flux.m` (also Table S2), `figs5to8.m`

`placement.py` contains the four placement rules used to modify each plot's gap distribution
before the model runs; `python test_placement.py` checks them. Placed gap lengths were perturbed
by up to ±1% before the model runs. Outputs are written to `output/`.

## Contact

Shubham Tiwari, shubhamt@nmsu.edu
