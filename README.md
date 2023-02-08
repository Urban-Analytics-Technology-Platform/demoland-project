# LandUseDemonstrator
Developing a modelling system to quantify features of land use in urban environments for the United Kingdom.

Most of the information related to the project are stored in the [book](https://ciupava.github.io/LandUseDemonstrator/).

---

**IN PROGRESS** -UPDATED 8 Feb 23-

To reproduce the stuff I do, the code is in `/python` and there atm the code I am most working on is several `accessibility` notebooks.<br/>I did some preliminary stuff (simple data handling) in `data_prep.ipynb`.

(Some thing is also in `/R`, but it's mainly first trials and not currently used in the analysis)

A few yaml files for creating a python environment are available. The most complete of them is `env_r5py.yml`, it allows using `r5py` and `tracc` packages (for accessibility analysis), and also the function _explore_ with `geopandas` (for notebooks visualisation). <br/> Install using the following code:

> ```python
> cd python # name of the folder where the yml is located, if not there yet
> conda env create -f env_demo_r5.yml  # generates an environment called "demoland_r5"
> conda activate demoland_r5 # to active the environment

You can track the research and work in progress in the github pages within the [Notes chapter](https://ciupava.github.io/LandUseDemonstrator/notes.html).