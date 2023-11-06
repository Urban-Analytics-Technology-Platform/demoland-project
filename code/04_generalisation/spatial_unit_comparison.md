# Comparison of spatial units

The notebooks `create_data`, `create_summary` and `run_predictors` contain code used to
analyse the effect of a spatial unit in the modeling exercise (both air pollution and
house price). The idea is that the best spatial unit will be then used for nation-wide
models.

Tested spatial units:

- LSOA (as in the Tyne and Wear pilot)
- Enclosed tessellation cells
- H3 grid of a resolution 9 (roughly 200m edge)
- Square grid 250x250m

The method:

1. Interpolate target variables onto selected geometry (except cases were data come at the same unit)
2. Interpolate explanatory variables (except cases were data come at the same unit)
3. Use Air Quality 1km grid to create 5 randomised folds to ensure clean train-test split
4. Join the fold information on geometry
5. Create spatially-lagged variables using 2km distance band (based on centroids)
5. Using 5-fold cross-validation, train both predictive models on all spatial units
6. Measure performance and compare

Performance metrics:

- R2
- mean error
- mean squared error
- Difference in Moran's I in predicted and observed values using the same distance band
  that was used for spatial lag

Summary of results:

- Grids outperform LSOA and ET cells
- H3 is preferable due to its geometry ensuring consistent spatial lag and no need for
  spatial operations in creating it.