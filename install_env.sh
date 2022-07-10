#!/bin/bash

# Creating a conda environment $env_name for running the C-ESM-EP
# S.Sénési - 07/2022
set -x
env_name=${1:-cesmepm}

# Which module should be loaded for activating a conda base environment
export ANA=${ANA:-anaconda3-py/2021.11}

# Where should we create the environment
export where=${where:-/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs}

# Do we pin a python version for the environment 
export python="python=3.9"

# Which conda channels should we use
export channels="-c conda-forge -c r"

# Make the list of modules, organized by component :
# CliMAF, notebooks, C-ESM-EP, ESMValTool

# CliMAF
climaf_modules="natsort ujson xarray netcdf4 cftime yaml pyyaml sphinx"
climaf_exec="cdo<2.0.4 ncl imagemagick ncview nco!=5.0.4 exiv2 perl ipython pipenv "
# Note: CliMAF also needs pdftk, but there is no conda package for that, only a Ubuntu package

# Notebooks
nb_modules="jupyter jupytext papermill texlive-core"

# C-ESM-EP
cesmep_modules="cdms2 cdutil dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal matplotlib  basemap"
r_modules="r-irkernel r-evd r-ncdf4 r-foreach r-doParallel r-goftest Cython"

#ESMValTool
evt_modules="esmvaltool iris"

# Aggregates all modules
modules="$climaf_modules $climaf_exec $cesmep_modules $nb_modules $evt_modules $r_modules "

# Set variables used by swiss_knife.sh, and call it
export create=yes install=yes mamba=no env=$env_name mamba=yes

# execute co-located tool
dir=$(cd $(dirname $0); pwd)
$dir/swiss_knife.sh "$modules"

