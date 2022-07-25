#!/bin/bash

# Installing a CliMAF version, a C-ESM-EP version and a conda
# environment for running CliMAF and C-ESM-EP, by accessing their
# repository and conda-forge. This includes some automated testing,
# and the creation of auxilliary files : a module file, a notebook
# launcher, and a version of setenv_C-ESM-EP.sh

# S.Sénési 07/2022

# THE LIST OF CONDA PACKAGES TO INSTALL ACTUALLY LIES IN CO-LOCATED
# SCRIPT install_env.sh

# Created files and dirs are made writeable by the group, except if
# $writeable is set to no

#set -e
#set -x
writeable=${writeable:-yes}

[[ $(uname -n) != spirit* ]] && \
    echo "This script is yet validated only on Spirit; carrying on at your own risks"

# 1- About CliMAF
#####################################
# $climaf_label is free to set; it is used :
#  - as a prefix of the targer conda environment name and the module name
#       (suffix being $env_version, see below),
#  - and as a suffix for CLiMAF installation sub-directory (prefix being 'climaf_')
climaf_label=${climaf_label:-spirit}

# Where to get CliMAF from
climaf_repository=${climaf_repository:-https://github.com/rigoudyg/climaf}

# The name of the CliMAF branch we will use
climaf_branch=${climaf_branch:-run_cesmep_on_spirit_and_at_TGCC}

# Where to install CliMAF directory
climaf_dir=${climaf_dir:-/net/nfs/tools/Users/SU/jservon/climaf_installs}

# Where should we put the module activating this CliMAF environment
module_dir=${module_dir:-/net/nfs/tools/Users/SU/modulefiles/jservon/climaf/}

# Where should we put command 'climaf-notebook'
bin_dir=${bin_dir:-/net/nfs/tools/Users/SU/jservon/bin}

# File associating an IP port to each registered user
user_ports=/net/nfs/tools/Users/SU/jservon/notebook_user_port.txt

# Should we actually install and test CliMAF
climaf_install=${climaf_install:-yes}


# 2- About the conda environment
########################################
# Which conda is used (through a module) and where is its base environment
conda_module=${conda_module:-anaconda3-py/2021.11}
conda_dir=${conda_dir:-/net/nfs/tools/python-anaconda/Anaconda3-2021.11/}
#/net/nfs/tools/python-anaconda/miniconda3

# Provide a version label for the conda environment we will create
env_version=${env_version:-0}
env_dir=${env_dir:-/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs}

# Should we actually create this environment
env_install=${env_install:-yes}

# 3- About C-ESM-EP
###########################################
# Where to get C-ESM-EP from
cesmep_repository=${cesmep_repository:-https://github.com/jservonnat/C-ESM-EP}

# Which branch of C-ESM-EP repository should be used for test
cesmep_branch=${cesmep_branch:-spirit}

# Provide a working directory for installing C-ESM-EP
cesmep_dir=${cesmep_dir:-./}

# If you set CESMEP_CLIMAF_CACHE to the empty string, your standard
# climaf_cache will be used. Take care that this may pollute the test
# with results from another CLiMAF code.
CESMEP_CLIMAF_CACHE=${CESMEP_CLIMAF_CACHE:-/scratchu/$USER/cesmep_test_cache}

# Should we actually install and test CESMEP
cesmep_install=${cesmep_install:-yes}

#---------------------------------------------------------------------------------------------
# END of script parameters
#---------------------------------------------------------------------------------------------

# The name of the created conda_environment
env=climaf_${climaf_label}_${env_version}
env_path=$env_dir/$env

module purge
dir=$(cd $(dirname $0); pwd)
env_dir=$(mkdir -p $env_dir ; cd $env_dir; pwd)
cesmep_dir=$(mkdir -p $cesmep_dir ; cd $cesmep_dir; pwd)
climaf_dir=$(mkdir -p $climaf_dir ; cd $climaf_dir; pwd)
module_dir=$(mkdir -p $module_dir ; cd $module_dir; pwd)
module_path=$module_dir/${climaf_label}_${env_version}

if [ $env_install = yes ] ; then 
    echo "Creating conda environment $env - this may take quite a while"
    #echo "-------------------------------------------------------------"
    log=env_install.log
    # Init variables for swiss_knife.sh
    export ANA=$conda_module  where=$env_dir python="python=3.9" channels="-c conda-forge -c r"
    export env=$env create=yes install=yes  mamba=yes 
    # Source list of modules
    . $dir/liste_modules.sh
    $dir/swiss_knife.sh "$modules" > $log 2>&1

    [ $? -ne 0 ] && echo "Issue when creating the conda environment - see $log" && exit 1
    echo -e "\tOK !"
    [ $writeable = yes ] && chmod -R g+w $env_dir/$env
fi    


if [ $climaf_install = yes ] ; then 
    echo "Installing Climaf branch $climaf_branch as $climaf_label, and testing it"
    #echo "-------------------------------------------------------------------------"
    bin_dir=$(mkdir -p $bin_dir; cd $bin_dir; pwd)
    log=$(pwd)/climaf_install.log
    cd $climaf_dir
    rm -fR climaf_$climaf_label
    git clone -b $climaf_branch $climaf_repository climaf_$climaf_label > $log 2>&1
    [ $? -ne 0 ] && echo "Issue cloning CliMAF - See $log" && exit 1
    [ $writeable = yes ] && chmod -R g+w $climaf_label
    cd climaf_$climaf_label/tests
    test_modules="netcdfbasics period cache classes functions operators standard_operators "
    test_modules="$test_modules operators_derive operators_scripts cmacro driver dataloc "
    test_modules="$test_modules find_files html example_data_retrieval example_index_html mcdo" #example_data_plot
    module load $conda_module 
    conda deactivate 
    conda activate $env_path || (echo "Issue activating $env_path" ; exit 1)
    
    echo -e "\tInstall done, beginning test"
    ./launch_tests_with_coverage.sh 1 3 "$test_modules" > $log 2>&1
    [ $? -ne 0 ] && echo "CliMAF test did not succeed - see $log" && exit 1
    #
    echo -e "\tCreating the module file for the new CliMAF environment, at $module_path "
    #
    sed -e "s^CLIMAF_LABEL^$climaf_label^g" -e "s^ENV_VERSION^$env_version^g" \
	-e "s^ENV_DIR^$env_dir^g" -e "s^CONDA_DIR^$conda_dir^g" -e "s^BIN_DIR^$bin_dir^g" \
	-e "s^CLIMAF_DIR^$climaf_dir^g" $dir/climaf_module_template > $module_path
    [ $writeable = yes ] && chmod g+w $module_path
    #
    nb_path=$bin_dir/climaf-notebook_${climaf_label}_${env_version}
    echo -e "\tCreating the binary for launching notebook at $nb_path "
    #
    sed -e "s^CLIMAF_LABEL^$climaf_label^g" -e "s^ENV_VERSION^$env_version^g" \
	-e "s^ENV_PATH^$env_path^g" -e "s^USER_PORTS^$user_ports^g" $dir/climaf-notebook_template > $nb_path
    [ $writeable = yes ] && chmod g+w $nb_path
fi

if [ $cesmep_install = yes ] ; then 
    echo "Installing C-ESM-EP code and launching a reference comparison"
    echo "-------------------------------------------------------------"
    echo -e "\tCloning C-ESM-EP branch $cesmep_branch"
    mkdir -p $cesmep_dir
    cd $cesmep_dir
    rm -fR C-ESM-EP
    log=$(pwd)/cesemp_install.log
    git clone -b $cesmep_branch $cesmep_repository > $log 2>&1
    [ $? -ne 0 ] && echo "Issue cloning C-ESM-EP - See $log" && exit 1
    [ $writeable = yes ] && chmod -R g+w C-ESM-EP
    #
    echo -e "\tCreating the setenv file you should use, at: "
    echo -e "\t\t$(pwd)/setenv_C-ESM-EP.sh "
    #
    cd C-ESM-EP
    sed -i -e "s^emodule=.*^emodule=$module_path^g"  setenv_C-ESM-EP.sh
    export CESMEP_CLIMAF_CACHE
    #
    echo -e -n "\tLaunching run_C-ESM-EP.py for url..."
    #
    python run_C-ESM-EP.py standard_comparison url > $log
    [ $? -ne 0 ] && echo "Issue - see $log" && exit 1
    echo -e "OK"
    
    #
    echo -e "\tLaunching test_comparison, a clone of reference_comparison \n"
    #
    cd tests
    ./launch_test_comparison.sh test_comparison reference_comparison
    [ $? -ne 0 ] && echo "Issue - see above" && exit 1
    
    echo
    echo "---------------------------------------------------------------------------------"
    echo -e "\tPlease check completion of the jobs listed above, and have a look at the results"
    echo -e "\tAfter job completion, you may also launch this command :"
    echo -e "\t\t$(pwd)/compare_results.sh"
    echo
    echo -e "\tAnd dont forget to manage temporary directories : "
    echo -e "\t\t- $(pwd) "
    echo -e "\t\t- $CESMEP_CLIMAF_CACHE"
else
    exit 0
fi


