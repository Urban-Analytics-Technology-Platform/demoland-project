# Blackbox ReadMe

This folder contains everything you may need to generate indicators based on four input
variables. The rest of the repository is not needed.

# Neural network engine

For the neural networks, you need to use the `Engine` class defined in the `engine.py`
and documented in the `engine.ipynb` notebook. The `requirements.txt` contain minimal
requirements to run the `Engine` class. That is all you shall need within a Baskerville
instance. Note that to run the notebook itself, you will need `Jupyter` and its
dependencies and `matplotlib` on top of that.

## Scenario modelling

If you have a defined scenario and want to get the indicators you can use the functionality
outlined in the `scenario_modelling.ipynb`. To run that notebook, you will also need
`geopandas`. I have tried to eliminate it as a dependency from the generic `Engine` to avoid
the need of installing GDAL, GEOS and PROJ.
