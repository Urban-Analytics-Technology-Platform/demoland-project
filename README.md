# LandUseDemonstrator

Developing a modelling system to quantify features of land use in urban environments for the United Kingdom.

## Code

**IN PROGRESS** -UPDATED 8 Feb 23-

To reproduce the stuff I do, the code is in `/python` and there atm the code I am most working on is several `accessibility` notebooks.  
I did some preliminary stuff (simple data handling) in `data_prep.ipynb`.

(Some thing is also in `/R`, but it's mainly first trials and not currently used in the analysis)

A few yaml files for creating a Python environment are available.
The most complete of them is `env_r5py.yml`.
It enables the `r5py` and `tracc` packages (for accessibility analysis), and also the function `explore` with `geopandas` (for visualisation in notebooks).
Install using the following code:

```sh
cd python                           # name of the folder where the yml is located
conda env create -f env_demo_r5.yml # generates an environment called "demoland_r5"
conda activate demoland_r5          # to activate the environment
```

You can track the research and work in progress in the [*Notes* chapter of the book](https://ciupava.github.io/LandUseDemonstrator/notes.html).


## Web app frontend

**https://alan-turing-institute.github.io/demoland-web/**

We have also created a web app, allowing users to visualise the outputs of the models and to compare the different scenarios we have chosen.
The underlying code for the web app is [hosted separately on GitHub](https://github.com/alan-turing-institute/demoland-web).


## Book

**https://ciupava.github.io/LandUseDemonstrator/**

Separately, we provide a book which fully describes the project and its methodology.

To view the book locally, [install Quarto](https://quarto.org/), and then run `quarto preview` from the root of the repository.
The source code can be found in the `/book` subdirectory.

The `/book` directory also contains a `notes.qmd` file, which charts the history of the project as it has evolved.
This is not included in the actual Quarto output; however, it is retained as a reference for anybody who would like to read it.
