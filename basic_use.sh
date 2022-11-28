#!/bin/bash

# Use example for script install_all.sh, that uses most default settings,
# and especially the defaut installation directories.
# The other settings are set by exporting environment variables

# It creates conda environment 'climaf_spirit_0', module 'climaf/spirit_0' and
# install CliMAF in subdir 'climaf_spirit_0'

# S.Sénési - july 2022

script=/net/nfs/tools/Users/SU/jservon/tools/install_all.sh

export climaf_branch=run_cesmep_on_spirit_and_at_TGCC
export cesmep_branch=spirit

$script
	  
	  
