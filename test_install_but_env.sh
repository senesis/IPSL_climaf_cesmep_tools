#!/bin/bash
# Use this script for testing the installation in a test location, and
# only for CliMAF and C-ESM-EP (don't re-install the environment, re-use
# the one installed by a former call to test_install.sh)

# We want to use an already installed environment
export env_install=no
export env_label=env20221128

/net/nfs/tools/Users/SU/jservon/tools/test_install.sh
	  
	  
