import pickle
import joblib
import pandas as pd

from sampling import get_data

with open("data/air_quality_predictor.pickle", "rb") as f:
    air_quality_predictor = pickle.load(f)

with open("data/house_price_predictor.pickle", "rb") as f:
    house_price_predictor = pickle.load(f)

with open("data/accessibility.joblib", "rb") as f:
    accessibility = joblib.load(f)


def get_indicators(df):
    vars, jobs, gsp = get_data(df)
    aq = air_quality_predictor.predict(vars)
    hp = house_price_predictor.predict(vars)
    ja = accessibility.job_accessibility(jobs, "walk")
    gs = accessibility.greenspace_accessibility(gsp, "walk")
    ja = ja.to_pandas()[df.index].values
    gs = gs.to_pandas()[df.index].values

    return pd.DataFrame(
        {
            "air_quality": aq,
            "house_price": hp,
            "job_accessibility": ja,
            "greenspace_accessibility": gs,
        },
        index=df.index,
    )


def get_indicators_lsoa(df):
    empty = pd.read_parquet("data/empty.parquet")
    lsoa_oa = pd.read_parquet("data/oa_lsoa.parquet")

    merged = (
        empty.assign(lsoa=lsoa_oa.lsoa11cd)[["lsoa"]]
        .merge(df, left_on="lsoa", right_index=True, how="left")
        .drop(columns="lsoa")
    )
    return get_indicators(merged).assign(lsoa=lsoa_oa.lsoa11cd).groupby("lsoa").mean()
