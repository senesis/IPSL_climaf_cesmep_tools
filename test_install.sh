#!/bin/bash
# Use this script for testing the installation in a test location
# On script execution, install location will be displayed for all components
# Once everything is OK, just comment out the line setting test_install_dir

export test_install_dir=/scratchu/ssenesi/test_install

export climaf_branch=V3.0
export cesmep_branch=spirit_ClimafV3.0

# We must execute from a location with write permission, let us choose the install dir
cd $test_install_dir

/net/nfs/tools/Users/SU/jservon/tools/install_all.sh
	  
	  
