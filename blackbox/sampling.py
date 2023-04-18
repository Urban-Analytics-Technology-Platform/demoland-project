import geopandas as gpd
import numpy as np
import pandas as pd

median_form = pd.read_parquet("data/median_form.parquet")
iqr_form = pd.read_parquet("data/iqr_form.parquet")
median_function = pd.read_parquet("data/median_function.parquet")
iqr_function = pd.read_parquet("data/iqr_function.parquet")
oa = (
    gpd.read_parquet("data/all_oa.parquet")
    .set_index("geo_code")
    .rename(columns={"population_estimate": "population"})
)
oa_key = pd.read_parquet("data/oa_key.parquet")


oa_area = oa.area

SIGS = {
    0: "Wild countryside",
    1: "Countryside agriculture",
    2: "Urban buffer",
    3: "Warehouse/Park land",
    4: "Open sprawl",
    5: "Disconnected suburbia",
    6: "Accessible suburbia",
    7: "Connected residential neighbourhoods",
    8: "Dense residential neighbourhoods",
    9: "Gridded residential quarters",
    10: "Dense urban neighbourhoods",
    11: "Local urbanity",
    12: "Regional urbanity",
    13: "Metropolitan urbanity",
    14: "Concentrated urbanity",
    15: "Hyper concentrated urbanity",
}


def _form(signature_type, variable, random_seed):
    """Get values for form variables

    Values are sampled from a normal distribution around
    median of a variable per signature type. The spread is
    defined as 1/5 of interquartile range.
    """
    rng = np.random.default_rng(random_seed)
    return rng.normal(
        median_form.loc[signature_type, variable],
        iqr_form.loc[signature_type, variable] / 5,
    )


def _function(signature_type, variable, random_seed):
    """Get values for function variables

    Values are sampled from a normal distribution around
    median of a variable per signature type. The spread is
    defined as 1/5 of interquartile range.
    """
    rng = np.random.default_rng(random_seed)
    return rng.normal(
        median_function.loc[signature_type, variable],
        iqr_function.loc[signature_type, variable] / 5,
    )


def _populations(defaults, index):
    """Balance residential and workplace population

    Workplace population and residential population are treated 1:1 and
    are re-allocated based on the index. The proportion of workplace categories
    is not changed.
    """
    if not -1 <= index <= 1:
        raise ValueError(f"use index must be in a range -1...1. {index} given.")
    jobs = [
        "A, B, D, E. Agriculture, energy and water",
        "C. Manufacturing",
        "F. Construction",
        "G, I. Distribution, hotels and restaurants",
        "H, J. Transport and communication",
        "K, L, M, N. Financial, real estate, professional and administrative activities",
        "O,P,Q. Public administration, education and health",
        "R, S, T, U. Other",
    ]
    n_jobs = defaults[jobs].sum()
    if index < 0:
        difference = index * n_jobs
    else:
        difference = index * defaults.population
    new_n_jobs = n_jobs + difference
    defaults.population = defaults.population - difference
    multiplier = new_n_jobs / n_jobs
    defaults[jobs] = defaults[jobs] * multiplier
    return defaults, new_n_jobs


def _greenspace(defaults, index):
    """Allocate greenspace to OA

    Allocate publicly accessible formal greenspace to OA. Defines a portion
    of OA that is covered by gren urban areas. Realistic values are be fairly
    low. The value affects populations and other land cover classes.
    """
    if not 0 <= index <= 1:
        raise ValueError(f"greenspace index must be in a range 0...1. {index} given.")
    greenspace_orig = defaults["Land cover [Green urban areas]"]
    newly_allocated_gs = index - greenspace_orig
    defaults = defaults * (1 - newly_allocated_gs)
    defaults["Land cover [Green urban areas]"] = index
    return defaults, newly_allocated_gs


def _job_types(defaults, index):
    """Balance job types

    Balance job types between manual and white collar workplace categories.
    Index represents the proportion of white collar jobs in an area. The
    total sum of FTEs is not changed.

    The service category is not affected under an assumption that both white
    and blue collar workers need the same amount of services to provide food etc.
    """
    if not 0 <= index <= 1:
        raise ValueError(f"job_types index must be in a range 0...1. {index} given.")
    blue = [
        "A, B, D, E. Agriculture, energy and water",
        "C. Manufacturing",
        "F. Construction",
        "H, J. Transport and communication",
    ]
    white = [
        "K, L, M, N. Financial, real estate, professional and administrative activities",
        "O,P,Q. Public administration, education and health",
    ]
    blue_collar = defaults[blue].sum()
    white_collar = defaults[white].sum()
    total = blue_collar + white_collar

    new_blue = total * (1 - index)
    new_white = total * index

    blue_diff = new_blue / blue_collar
    white_diff = new_white / white_collar

    defaults[blue] = defaults[blue] * blue_diff
    defaults[white] = defaults[white] * white_diff

    return defaults


def get_signature_values(
    oa_code: str,
    signature_type: str = None,
    use: float = None,
    greenspace: float = None,
    job_types: float = None,
    random_seed: int = None,
):
    """Generate explanatory variables based on a scenario

    Generates values for explanatory variables based on empirical data derived
    from the Urban Grammar project and a scenario definition based on a
    Urban Grammar signature type, land use balance, greenspace allocation
    and a job type balance.

    If the target ``signature_type`` differs from the one already allocated
    to OA, the data is sampled from the distribution from the whole GB. If
    they are equal, the existing values measured in place are used. That allows
    playing with other variables without changing the form.

    Parameters
    ----------
    oa_code : string
        String representing the OA code, e.g. ``"E00042707"``.

    signature_type : string
        String representing signature type. See below the possible options
        and their relationship to the level of urbanity.

            0: 'Wild countryside',
            1: 'Countryside agriculture',
            2: 'Urban buffer',
            3: 'Warehouse/Park land',
            4: 'Open sprawl',
            5: 'Disconnected suburbia',
            6: 'Accessible suburbia',
            7: 'Connected residential neighbourhoods',
            8: 'Dense residential neighbourhoods',
            9: 'Gridded residential quarters',
            10: 'Dense urban neighbourhoods',
            11: 'Local urbanity',
            12: 'Regional urbanity',
            13: 'Metropolitan urbanity',
            14: 'Concentrated urbanity',
            15: 'Hyper concentrated urbanity',

    use : float, optional
        Float in a range -1...1 reflecting the land use balance between
        fully residential (-1) and fully commercial (1). Defautls to 0,
        a value derived from signatures. For values < 0, we are allocating
        workplace population to residential population. For values > 0, we
        are allocating residential population to workplace population.
        Extremes are allowed but are not realistic, in most cases.
    greenspace : float, optional
        Float in a range 0...1 reflecting the amount of greenspace in the
        area. 0 representes no accessible greenspace, 1 represents whole
        area covered by a greenspace. This value will proportionally affect
        the amounts of jobs and population.
    job_types : float, optional
        Float in a range 0...1 reflecting the balance of job types in the
        area between entirely blue collar jobs (0) and entirely white collar
        jobs (1).
    random_seed : int, optional
        Random seed

    Returns
    -------
    Series
    """
    if signature_type is not None:
        signature_type = SIGS[signature_type]
    orig_type = oa_key.primary_type[oa_code]
    if signature_type is not None and orig_type != signature_type:
        form = pd.Series(
            [_form(signature_type, var, random_seed) for var in median_form.columns],
            index=median_form.columns,
            name=oa_code,
        ).abs()

        defaults = pd.Series(
            [
                _function(signature_type, var, random_seed)
                for var in median_function.columns
            ],
            index=median_function.columns,
            name=oa_code,
        ).abs()

        area_weighted = [
            "population",
            "A, B, D, E. Agriculture, energy and water",
            "C. Manufacturing",
            "F. Construction",
            "G, I. Distribution, hotels and restaurants",
            "H, J. Transport and communication",
            "K, L, M, N. Financial, real estate, professional and administrative activities",
            "O,P,Q. Public administration, education and health",
            "R, S, T, U. Other",
        ]
        defaults[area_weighted] = defaults[area_weighted] * oa_area[oa_code]

    else:
        form = oa.loc[oa_code][median_form.columns]
        defaults = oa.loc[oa_code][median_function.columns]

    # population
    if use:
        defaults, n_jobs_diff = _populations(defaults, index=use)
    else:
        n_jobs_diff = 0

    # greenspace
    if greenspace:
        defaults, newly_allocated_gs = _greenspace(defaults, greenspace)
        newly_allocated_gs = newly_allocated_gs * oa_area[oa_code]
    else:
        newly_allocated_gs = 0

    if job_types:
        defaults = _job_types(defaults, job_types)
    df = pd.concat([defaults, form])

    order = [
        "population",
        "A, B, D, E. Agriculture, energy and water",
        "C. Manufacturing",
        "F. Construction",
        "G, I. Distribution, hotels and restaurants",
        "H, J. Transport and communication",
        "K, L, M, N. Financial, real estate, professional and administrative activities",
        "O,P,Q. Public administration, education and health",
        "R, S, T, U. Other",
        "Land cover [Discontinuous urban fabric]",
        "Land cover [Continuous urban fabric]",
        "Land cover [Non-irrigated arable land]",
        "Land cover [Industrial or commercial units]",
        "Land cover [Green urban areas]",
        "Land cover [Pastures]",
        "Land cover [Sport and leisure facilities]",
        "sdbAre",
        "sdbCoA",
        "ssbCCo",
        "ssbCor",
        "ssbSqu",
        "ssbERI",
        "ssbCCM",
        "ssbCCD",
        "stbOri",
        "sdcAre",
        "sscCCo",
        "sscERI",
        "sicCAR",
        "stbCeA",
        "mtbAli",
        "mtbNDi",
        "mtcWNe",
        "ltbIBD",
        "sdsSPW",
        "sdsSWD",
        "sdsSPO",
        "sdsLen",
        "sssLin",
        "ldsMSL",
        "mtdDeg",
        "linP3W",
        "linP4W",
        "linPDE",
        "lcnClo",
        "ldsCDL",
        "xcnSCl",
        "linWID",
        "stbSAl",
        "sdsAre",
        "sisBpM",
        "misCel",
        "ltcRea",
        "ldeAre",
        "lseCCo",
        "lseERI",
        "lteOri",
        "lteWNB",
        "lieWCe",
    ]
    exvars = df[order].rename({"population": "population_estimate"})
    return (exvars, n_jobs_diff, newly_allocated_gs)


def get_data(df):
    exvars = []
    jobs_diff = []
    gs_diff = []
    for vals in df.itertuples(name=None):
        ex, j, gs = get_signature_values(*vals)
        exvars.append(ex)
        jobs_diff.append(j)
        gs_diff.append(gs)

    exvars = pd.concat(exvars, axis=1).T.astype(float)
    jobs_diff = pd.Series(jobs_diff, index=df.index.values, dtype=float, name="oa")
    jobs_diff.index.name = "to_id"
    gs_diff = pd.Series(gs_diff, index=df.index.values, dtype=float, name="oa")
    gs_diff.index.name = "to_id"
    return (exvars, jobs_diff, gs_diff)
