# LandUseDemonstrator
Developing a modelling system to quantify features of land use in urban environments for the United Kingdom.

Most of the information related to the project are stored in the [book](https://ciupava.github.io/LandUseDemonstrator/).

---

**IN PROGRESS**

To reproduce the stuff I do, the code is in `/python` and there atm the code I am most working on is `accessib.ipynb`, I did some preliminary stuff (simple data handling) in `data_prep.ipynb`.

(Some stuff is also in `/R`, but it's mainly first trials and not currently used in the analysis)

For your convenience, a yaml file for creating a python environment is available. Install using the following code:

> ```python
> cd python # name of the folder where the yml is located, if not there yet
> conda env create -f env.yml  # generates an environment called "demoland"
> conda activate demoland # to active the environment