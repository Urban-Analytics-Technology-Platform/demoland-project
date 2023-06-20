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
        """
        oa : pd.Series
            A series denoteing the difference in a number of jobs compared to the baseline.
            Indexed by OA code named "to_id". Series is named "oa".

            Example::

                to_id
                E00041363    38
                E00041364    78
                E00041366   -56
                E00041367    76
                E00041368    48
                             ..
                E00175601    20
                E00175602   -16
                E00175603    32
                E00175604   -81
                E00175605    51
                Name: oa, Length: 3795, dtype: int64

        """
        merged = xr.merge([self.baseline, xr.DataArray.from_series(oa)])
        merged["combined"] = merged.wpz_population + merged.oa.fillna(0)
        single_mode = merged.sel(mode=mode)
        return single_mode["combined"].where(single_mode["ttm_15"]).sum(dim=["to_id"])

    def greenspace_accessibility(self, oa: pd.Series, mode: str):
        """
        oa : pd.Series
            A series denoteing the additional square meters of parks in an OA.
            Indexed by OA code named "to_id". Series is named "oa".

            Example::

                to_id
                E00041363    7713
                E00041364     473
                E00041366    2092
                E00041367    8861
                E00041368    5830
                             ...
                E00175601    6850
                E00175602    9157
                E00175603    4095
                E00175604    2838
                E00175605    1327
                Name: oa, Length: 3795, dtype: int64

        """
        merged = xr.merge([self.baseline, xr.DataArray.from_series(oa)])
        single_mode = merged.sel(mode=mode)
        additional_acc = (
            single_mode["oa"].where(single_mode["ttm_15"]).sum(dim=["to_id"])
        )
        return additional_acc + merged.sel(mode=mode)["green_accessibility"]
