#!/bin/bash

# Use example for script install_all.sh, that uses most default settings,
# and especially the defaut installation directories.
# The other settings are set by exporting environment variables

# It creates conda environment 'climaf_spirit_0', module 'climaf/spirit_0' and
# install CliMAF in subdir 'climaf_spirit_0'

# S.Sénési - july 2022

dir=$(cd $(dirname $0); pwd)
script=$dir/install_all.sh

# Used as a suffix in names above. Allows to identify various conda packages set
export env_version=0

# Used as a prefix in names above. Identifies a CliMAF version,
# possibly different from the corresponding branch name
export climaf_label=spirit

# Self-explaining
export climaf_branch=run_cesmep_on_spirit_and_at_TGCC

# Self-explaining. Used only for testing a C-ESM-EP run
export cesmep_branch=spirit

$script
	  
	  
