#!/bin/bash

# List packages to be included in a conda environment

# This file is sourced by install_all.sh, and provides a value for $modules
# Its current content matches the needs for C-ESM-EP
# S.Sénési - 07/2022

# Make the list of modules, organized by component :
# system, CliMAF, notebooks, C-ESM-EP, ESMValTool

# System
system_modules="ncurses"  #in order to avoid complaints about version information for libtinfo.6

# CliMAF
climaf_modules="natsort ujson xarray netcdf4 h5netcdf cftime yaml pyyaml sphinx"
climaf_exec="cdo<2.0.4 ncl imagemagick ncview nco!=5.0.4 exiv2 perl ipython pipenv "
# Note: CliMAF also needs pdftk, but there is no conda package for that, only a Ubuntu package

# Notebooks
nb_modules="jupyter jupytext papermill texlive-core nb_conda"

# C-ESM-EP
cesmep_modules="cdms2 cdutil "
r_modules="r-irkernel r-evd r-ncdf4 r-foreach r-doParallel r-goftest Cython"

#ESMValTool
evt_modules="esmvaltool iris"

# General modules
general_modules="dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal matplotlib  basemap "
#general_modules="dask joblib dask-jobqueue windspharm pandas regionmask geopandas gdal matplotlib  basemap global-land-mask"

# Aggregates all modules
modules="$system_modules $climaf_modules $climaf_exec $cesmep_modules $general_modules $nb_modules $evt_modules $r_modules "

