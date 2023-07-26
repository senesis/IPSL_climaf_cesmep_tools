#!/bin/bash

# Installing a CliMAF version, a C-ESM-EP version and a conda
# environment for running CliMAF and C-ESM-EP, by accessing their
# repository and conda-forge. This includes some automated testing,
# and the creation of auxilliary files : a module file, a notebook
# launcher, and a version of setenv_C-ESM-EP.sh
# There is a toggle for de-activating each of the three major steps.

# S.Sénési 07/2022

# THE LIST OF CONDA PACKAGES TO INSTALL IS PROVIDED USING ENVIRONMENT
# VARIABLE 'modules' OR (IF IT IS NOT SET) BY SOURCING COLOCATED
# SCRIPT liste_modules.sh. For reference, this list is copied in the
# conda environment root directory, in file 'packages_list'

# install locations use parameters defined below. If test_install_dir is not set, they are :
# -------------------------------------------------------------------------------------------
#  - for climaf-notebook script: $bin_dir/notebook_env${env_label}_climaf${climaf_label}
#  - for environment module    : $module_dir/env${env_label}_climaf${climaf_label}
#  - for C-ESM-EP              : $cesmep_dir
#  - for a setenv_C-ESM-EP.sh  : $cesmep_dir/setenv_C-ESM-EP.sh
#  - for climaf                : $climaf_dir/${climaf_label}
#  - for conda environment     : $env_dir/env${env_label} 
#  - list of conda packages    : $env_dir/env${env_label}/packages_list

# If test_install_dir is set, then bin_dir, module_dir, climaf_dir and env_dir are set
# as sub-directores of test_install_dir

# env_label, if not exported, is set as the current date
# climaf_label, if not exported, is set as $climaf_branch (the label of the branch/tag to install)

# Any of the three steps (CliMAF install, C-ESM-EP install, conda
# environment creation) can be skipped using parameters
# climaf_install, cesmep_install and env_install.

# Created files and dirs are made writeable by the group, except if
# $writeable is set to no
writeable=${writeable:-yes}

[ ${setx:-no} = yes ] && set -x

if [[ $(uname -n) != spirit* ]] ; then 
    echo "This script is yet validated only on Spirit; carrying on at your own risks"
fi

if [ ! -z $test_install_dir ] ; then mkdir -p $test_install_dir ; fi

# 1- About CliMAF
#####################################
# Where to get CliMAF from
climaf_repository=${climaf_repository:-https://github.com/rigoudyg/climaf}

# The name of the CliMAF branch we will use, or the name of a tag
#climaf_branch=${climaf_branch:-run_cesmep_on_spirit_and_at_TGCC}
climaf_branch=${climaf_branch:-spirit_0_maintenance}

# climaf_label can be chosen freely; defaults to climaf branch name
climaf_label=${climaf_label:-${climaf_branch}}

# Where to install CliMAF directory
if [ -z $test_install_dir ] || [ $climaf_dir ] ; then 
    climaf_dir=${climaf_dir:-/net/nfs/tools/Users/SU/jservon/climaf_installs}
else
    climaf_dir=$test_install_dir/climaf_installs
fi
    
# Should we test CliMAF
climaf_test=${climaf_test:-yes}

# Where should we put the module activating this CliMAF environment
if [ -z $test_install_dir ] || [ $module_dir ]; then 
    module_dir=${module_dir:-/net/nfs/tools/Users/SU/modulefiles/jservon/climaf/}
else
    module_dir=$test_install_dir/modules
fi

# Where should we put command 'climaf-notebook'
if [ -z $test_install_dir ] || [ $install_dir ]; then 
    bin_dir=${bin_dir:-/net/nfs/tools/Users/SU/jservon/bin}
else
    bin_dir=$test_install_dir/bin
fi

# File associating an IP port to each registered user
# (used in notebook scripts)
user_ports=/net/nfs/tools/Users/SU/jservon/notebook_user_port.txt

# Should we actually install and test CliMAF
climaf_install=${climaf_install:-yes}

# 2- About the conda environment
########################################
# Which conda is used (through a module) and where is its base environment
conda_module=${conda_module:-anaconda3-py/2021.11}
conda_dir=${conda_dir:-/net/nfs/tools/python-anaconda/Anaconda3-2021.11/}
#/net/nfs/tools/python-anaconda/miniconda3

# The label for the created conda_environment
env_label=${env_label:-$(date +%Y%m%d)}

if [ -z $test_install_dir ] || [ $env_dir ]; then 
    env_dir=${env_dir:-/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs}
else
    env_dir=$test_install_dir/envs
fi

# Should we actually create this environment
env_install=${env_install:-yes}

# 3- About C-ESM-EP
###########################################
# Where to get C-ESM-EP from
cesmep_repository=${cesmep_repository:-https://github.com/jservonnat/C-ESM-EP}

# Which branch (or tag) of C-ESM-EP repository should be used for test
cesmep_branch=${cesmep_branch:-spirit}

# Provide a directory for installing C-ESM-EP. It will hold a useful
# setenv_C-ESM-EP.sh, that invokes the relevant module 
cesmep_dir=${cesmep_dir:-${test_install_dir:-.}/cesmep_test}

# If you set CESMEP_CLIMAF_CACHE to the empty string, your standard
# climaf_cache will be used. Take care that this may pollute the test
# with results from another CLiMAF code.
CESMEP_CLIMAF_CACHE=${CESMEP_CLIMAF_CACHE:-/scratchu/$USER/cesmep_test_cache}

# Should we actually install and test CESMEP. If yes, provide details
cesmep_install=${cesmep_install:-yes}
reference_comparison=ref_comparison
reference_results=TBD
email=${email:-jerome.servonnat@lsce.ipsl.fr}
#---------------------------------------------------------------------------------------------
# END of script parameters
#---------------------------------------------------------------------------------------------

[ ${setx:-no} = yes ] && set +x
module -s purge
[ ${setx:-no} = yes ] && set -x

dir=$(cd $(dirname $0); pwd)
env_dir=$(mkdir -p $env_dir ; cd $env_dir; pwd)
cesmep_dir=$(mkdir -p $cesmep_dir ; cd $cesmep_dir; pwd)
climaf_dir=$(mkdir -p $climaf_dir ; cd $climaf_dir; pwd)
module_dir=$(mkdir -p $module_dir ; cd $module_dir; pwd)
bin_dir=$(mkdir -p $bin_dir ; cd $bin_dir; pwd)

env_path=$env_dir/$env_label
module_path=$module_dir/env${env_label}_climaf${climaf_label}
nb_path=$bin_dir/notebook_env${env_label}_climaf${climaf_label}

if [ $env_install = yes ] ; then 
    echo -e "\tCreating conda environment $env_label - this may take quite a while"
    #echo "-------------------------------------------------------------"
    log=env_install.log
    
    # Init variables for swiss_knife.sh
    export ANA=$conda_module  where=$env_dir python="python=3.9" channels="-c conda-forge -c r"
    export env=$env_label create=yes install=yes  mamba=yes 

    # Source list of packages/modules if not set through an env. variable
    [ -z $modules ] && . $dir/liste_modules.sh
    $dir/swiss_knife.sh "$modules" > $log 2>&1

    [ $? -ne 0 ] && echo "Issue when creating the conda environment - see $log" && exit 1
    
    # Copy packages list in the environment root dir
    echo "modules=\"$modules\"" > $env_path/packages_list
    echo -e "\tOK ! \n\tPackages list is available at $env_path/packages_list"
    [ $writeable = yes ] && chmod -R g+w $env_path 2>/dev/null
    chmod -f g+w $env_dir $log
fi    


if [ $climaf_install = yes ] ; then 
    echo -e "\tInstalling Climaf branch $climaf_branch at: "
    echo -e "\t\t$climaf_dir/$climaf_label"
    #echo "------------------------------------------------------------------------------------------"
    bin_dir=$(mkdir -p $bin_dir; cd $bin_dir; pwd)
    log=$(pwd)/climaf_install.log
    cd $climaf_dir
    rm -fR $climaf_label
    git clone -b $climaf_branch $climaf_repository ${climaf_label} > $log 2>&1
    [ $? -ne 0 ] && echo "Issue cloning CliMAF - See $log" && exit 1
    [ $writeable = yes ] && chmod -f -R g+w $climaf_label 2>/dev/null

    if [ $climaf_test = yes ] ; then 
	echo -e -n "\t\tInstall done, beginning test; in case of failure, look at ~/tmp/tests ..."
	test_modules="netcdfbasics period cache classes functions operators standard_operators "
	test_modules="$test_modules operators_derive operators_scripts cmacro driver dataloc "
	test_modules="$test_modules find_files html example_data_retrieval example_index_html mcdo"
	#example_data_plot
	[ ${setx:-no} = yes ] && set +x
	module load $conda_module 
	conda deactivate 
	conda activate $env_path || (echo "Issue activating $env_path" ; exit 1)
	[ ${setx:-no} = yes ] && set -x
	cd $climaf_label/tests
	./launch_tests_with_coverage.sh 1 3 "$test_modules" > $log 2>&1
	[ $? -ne 0 ] && echo "CliMAF test did not succeed - see $log" && exit 1
	echo -e "\t OK"
	[ ${setx:-no} = yes ] && set +x
	conda deactivate
	[ ${setx:-no} = yes ] && set -x
    fi
    chmod -f g+w $climaf_dir $log
    #
fi

if [ $climaf_install = yes ] || [ $env_install = yes ] ; then 
    echo -e "\tCreating the module file for the new CliMAF environment, at \n\t\t$module_path "
    sed -e "s^CLIMAF_DIR^${climaf_dir}/${climaf_label}^g" -e "s^CONDA_ENV^${env_path}^g" \
	-e "s^CONDA_DIR^$conda_dir^g" -e "s^BIN_DIR^$bin_dir^g" -e "s^CLIMAF_LABEL^$climaf_label^g" \
	-e "s^NB_SCRIPT^$nb_path^g" $dir/climaf_module_template > $module_path
    [ $writeable = yes ] && chmod -f g+w $module_path 2>/dev/null
    #
    echo -e "\tCreating the script for launching notebooks at \n\t\t$nb_path "
    sed -e "s^MODULE_PATH^$module_path^g" -e "s^USER_PORTS^$user_ports^g" \
	$dir/climaf-notebook_template > $nb_path
    chmod +x $nb_path
    [ $writeable = yes ] && chmod -f g+w $nb_path 2>/dev/null
fi

if [ $cesmep_install = yes ] ; then
    cesmep_subdir=C-ESM-EP_tmp
    echo -e "\tInstalling C-ESM-EP code and launching a reference comparison"
    #echo "-------------------------------------------------------------"
    echo -e "\t\tCloning C-ESM-EP branch $cesmep_branch"
    mkdir -p $cesmep_dir
    cd $cesmep_dir
    rm -fR $cesmep_subdir
    log=$(pwd)/cesmep_install.log
    git clone -b $cesmep_branch $cesmep_repository $cesmep_subdir #> $log 2>&1
    [ $? -ne 0 ] && echo "Issue cloning C-ESM-EP - See $log" && exit 1
    [ $writeable = yes ] && chmod -f -R g+w $cesmep_subdir 2>/dev/null
    #
    #
    cd $cesmep_subdir
    echo -e "\t\tCreating the setenv file you should use, at: "
    echo -e "\t\t\t$(pwd)/setenv_C-ESM-EP.sh "
    sed -i -e "s^emodule=.*^emodule=$module_path^g"  setenv_C-ESM-EP.sh
    export CESMEP_CLIMAF_CACHE
    #
    [ ${setx:-no} = yes ] && set +x    
    module -s purge 
    PYTHONPATH="" 
    module -s load $module_path
    [ ${setx:-no} = yes ] && set -x
    #
    echo -e -n "\t\tLaunching run_C-ESM-EP.py with arg 'url'..."
    # Want to make sure that created module alone is enough for a successful run
    python run_C-ESM-EP.py standard_comparison url > $log
    [ $? -ne 0 ] && echo -e "\nIssue - see $log" && exit 1
    echo -e "OK"
    #
    if [ -f tests/check_ref_comparison.sh ] ; then 
	echo -e "\t\tChecking results for reference_comparison \n"
	tests/check_ref_comparison.sh $reference_comparison $reference_results $email
    fi
    
    # ./launch_test_comparison.sh test_comparison reference_comparison
    # [ $? -ne 0 ] && echo "Issue - see above" && exit 1
    
    # echo
    # echo "---------------------------------------------------------------------------------"
    # echo -e "\tPlease check completion of the jobs listed above, and have a look at the results"
    # echo -e "\tAfter job completion, you may also launch this command :"
    # echo -e "\t\t$(pwd)/compare_results.sh"
    # echo
    # echo -e "\tAnd dont forget to manage temporary directories : "
    # echo -e "\t\t- $(pwd) "
    # echo -e "\t\t- $CESMEP_CLIMAF_CACHE"
    # chmod -f g+w $log $cesmep_dir $cesmep_dir/$cesmep_subdir
else
    exit 0
fi


