#!/bin/bash

# List packages to be included in a conda environment

# This file is sourced by install_all.sh, and provides a value for $modules
# Its current content matches the needs for C-ESM-EP
# S.Sénési - 07/2022

# Make the list of modules, organized by component's needs :
# system, CliMAF, notebooks, C-ESM-EP, ESMValTool

# System
system_modules="bash ncurses vim emacs" 

# CliMAF
climaf_modules="natsort ujson xarray netcdf4 h5netcdf cftime yaml pyyaml sphinx matplotlib cartopy pip:pdflatex"
climaf_exec="cdo!=2.0.4 ncl imagemagick fonts-conda-forge ncview nco!=5.0.4 exiv2 perl ipython pipenv"
# Note: CliMAF also needs pdftk, but there is no conda package for that, only a Ubuntu package
# Note : netcdf4 and h5netcdf are back-ends for xarray. Adding h5netcdf just for the sake of
# verifying impact on performance (which was nil)
# Note : cdo 2.0.4 is not compatible with ciclad's glibc
# Note : nco 5.0.4 package is not well formed

# Notebooks
# texlive-core removed, june 2023, because the corresponding latex misses TLUtils.
# Better use the system-installed latex
nb_modules="jupyter jupytext papermill " #nb_conda"

# C-ESM-EP
cesmep_modules="numpy<1.24.0 cdms2 cdutil "
# Note : numpy does no more provide type float from version 1.24.0, while cdms2 wants to import it.
r_modules="r-irkernel r-evd r-ncdf4 r-foreach r-doParallel r-goftest Cython"

#ESMValTool
evt_modules="esmvaltool iris"

# General modules
general_modules="dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal basemap "
#general_modules="dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal basemap global-land-mask"

# Aggregates all modules
modules="$system_modules $climaf_modules $climaf_exec $cesmep_modules $general_modules $nb_modules $evt_modules $r_modules "

