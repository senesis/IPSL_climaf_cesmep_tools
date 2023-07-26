#!/bin/bash

# Use example for script install_all.sh, that uses most default settings,
# and especially the defaut installation directories.
# The other settings are set by exporting environment variables

# It creates a conda environment , a module and installs and tests CliMAF
# Their locations will be displayed (see also install_all.sh)

# S.Sénési - july 2022- jan 2023

script=/net/nfs/tools/Users/SU/jservon/tools/install_all.sh

export climaf_branch=V3.0_IPSL1
export cesmep_branch=idris2

$script
	  
	  
