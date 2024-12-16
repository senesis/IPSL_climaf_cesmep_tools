#!/bin/bash

# List packages to be included in a conda environment for C-ESM-EP with notebooks

# This file is sourced by install_all.sh, and provides a value for $modules
# S.Sénési - 07/2022 -> ...2025

# Make the list of modules, organized by component's needs :
# system, CliMAF, notebooks, C-ESM-EP, ESMValTool

# System. 
#--------------
#2024/09 : remove conda, which was needed for pip
system_modules="bash ncurses vim emacs pip" 

# CliMAF
#--------------
climaf_modules="natsort ujson xarray netcdf4 h5netcdf cftime yaml pyyaml sphinx matplotlib "
# 2024/09 : pdflatex from anaconda rather than via pip. This helps a lot...
climaf_modules+="pyproj proj cartopy geocat-viz intake intake-esm pdflatex"

climaf_exec="cdo ncl imagemagick fonts-conda-forge ncview nco!=5.0.4 exiv2 perl ipython pipenv"

# Note: CliMAF also needs pdftk, but there is no conda package for that, only a Ubuntu package
# Note : netcdf4 and h5netcdf are back-ends for xarray. Adding h5netcdf just for the sake of
# verifying impact on performance (which was nil)
# Note : nco 5.0.4 package is not well formed

# Notebooks
#--------------
# 2023/06 : texlive-core removed because the corresponding latex misses TLUtils. Better use the system-installed latex
# ? notebook<7.0.0 
# 2024/12 : nodejs: to avoid the worker_threads error on juyter startup
# 2024/12 : httpx<0.28.0 : to avoid 'Failed to instantiate the extension manager pypi'
nb_modules="jupyter notebook jupytext papermill nb_conda nb_conda_kernels ipykernel nodejs httpx<0.28.0"

# C-ESM-EP
#--------------
cesmep_modules="numpy cdms2 cdutil "
# Note : numpy no more provides type float from version 1.24.0, while cdms2 wants to import it. CliMAF patches that

# R
#--------------
r_modules="r-irkernel r-evd r-ncdf4 r-foreach r-doParallel r-goftest Cython"

#ESMValTool
#--------------
evt_modules="esmvaltool iris"

# General modules
#--------------
# 2024/09 : remove global-land-mask , coz problems
general_modules="dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal basemap "

# Aggregates all modules
modules="$system_modules $climaf_modules $climaf_exec $cesmep_modules $general_modules $nb_modules $evt_modules $r_modules "
