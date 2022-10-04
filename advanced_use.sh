#!/bin/bash
# Use example for script install_all.sh

# We use local directories as location target for conda env,
# climaf and cesmep install, notebook script, module location

# We also use local repositories

script=/net/nfs/tools/Users/SU/jservon/tools/install_all.sh

export env_install=yes
export env_label=0
export env_dir=./envs

export climaf_install=yes 
export climaf_repository=/home/ssenesi/climaf_installs/climaf_running
export climaf_branch=run_cesmep_on_spirit_and_at_TGCC
export climaf_label=spirit
export climaf_dir=./climafs

export module_dir=./modules
export bin_dir=./bin

export cesmep_install=yes
export cesmep_repository=/home/ssenesi/environnements/C-ESM-EP
export cesmep_branch=spirit
export cesmep_dir=./cesmep
export CESMEP_CLIMAF_CACHE=""

$script
	  
	  
