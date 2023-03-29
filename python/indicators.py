import libpysal
import pandas as pd
import xarray as xr


class Model:
    """Model wrapper taking care of spatial lag computation"""

    def __init__(self, W, model):
        self.W = W
        self.model = model

    def predict(self, X):
        data = X.copy()
        for col in X.columns.copy():
            data[f"{col}_lag"] = libpysal.weights.spatial_lag.lag_spatial(
                self.W, data[col]
            )
        return self.model.predict(data)


class Accessibility:
    def __init__(self, baseline):
        self.baseline = baseline

    def job_accessibility(self, oa: pd.Series, mode: str):
        merged = xr.merge([self.baseline, xr.DataArray.from_series(oa)])
        merged["combined"] = merged.wpz_population + merged.oa.fillna(0)
        single_mode = merged.sel(mode=mode)
        return single_mode["combined"].where(single_mode["ttm_15"]).sum(dim=["to_id"])

    def greenspace_accessibility(self, oa: pd.Series, mode: str):
        # TODO
        merged = xr.merge([self.baseline, xr.DataArray.from_series(oa)])
        merged["combined"] = merged.greenspace_area + merged.oa.fillna(0)
        single_mode = merged.sel(mode=mode)
        return single_mode["combined"].where(single_mode["ttm_15"]).sum(dim=["to_id"])
