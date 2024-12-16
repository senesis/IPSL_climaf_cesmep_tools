#/!bin/bash

# Install conda packages in environment $env, and test their import in
# python or their basic execution. By default, creates the environment.

# The list of conda packages names is the first argument

# Packages are installed through successive calls to 
# 'mamba install', each followed by an import/exec test

# If $import is set and != last, each import/exec phase do test all
# packages already installed, otherwise only the newly installed
# package is tested

# If $install = no, just test the import / execution
# If $create != no, creates environment $env
# The environment is located with a full path, at $where
# Use conda channels $channels if set
# The conda base environment is activated by 'module load $ANA'

# If $python is "no", no python specification applies to the environment created
# otherwise, if it is not set or empty, specification 'python=3.9' is applied,
#            otherwise $python should be a python specification

# All steps have a log in directory 'logs'

# S.Sénési - 07/2022

set -e
#set -x
modules=$1

create=${create:-no}  # Créer l'env si un arg fourni
ANA=${ANA:-anaconda3-py/2021.11}
install=${install:-no}  # Installer ou pas les modules (par défaut : test seulement)
do_test=${do_test:-yes}  # Tester ou pas les modules 
env=${env:-test_import}
where=${where:-/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs}
import=${import:-last}  # sinon -> ré-importer à chaque étape tous les modules installés
# Can also set 'channels' and 'python'

dir=$(cd $(dirname $0); pwd)

[ $create != no ] && [ $install = no ] && echo "Install set to yes" && install=yes
module purge ;
module load $ANA

CENV=$where/$env

if [ "$python" != "no" ] ; then
    python_spec=${python:-"python=3.9"}
else
    python_spec=""
fi

# If channels is not set, set a default value. If set to "no", don't set channels
if [ "x$channels" != xno ] ; then
    channels_spec=${channels:-"-c defaults -c conda-forge -c r"}
else
    channels_spec=""
fi

mkdir -p logs

# Mamba base
PATH=$dir/../mambaforge/bin:$PATH

if [ "$create" != no ]; then
    if [ "$create" = yes ]; then
	echo -n Creating env $CENV ...
	rm -fR $CENV ; mkdir -p $where;
	echo -e "name: \ndependencies:\n  - python=3.10" > envir.yml
	mamba env create --prefix $CENV --yes -f envir.yml > logs/create_$(basename $CENV) 2>&1
    elif [ $create = add ]; then 
	echo -n Complementing env $CENV ...
    else
	echo -n Unkwon option create=$create
	exit 1
    fi
fi
conda activate $CENV 

# Path to a python code which "imports" each of the packages provided as first argument
# Depending on a hard-coded table (module_names), it may :
#  - translate the conda package name in the actual module name
#  - or skip the import
#  - or rather test the execution  (by sys.exec) of the 'package', with argument '-h'
# It exits on first issue
test_import=$dir/test_import_exec.py


# Next setting needed because of interaction between handling of
# parallelism by both Python and OpenBlas.  See
# e.g. https://github.com/xianyi/OpenBLAS/wiki/Faq#multi-threaded
export OPENBLAS_NUM_THREADS=1

sublist=""
echo "Testing install + import iteratively :"
for module in $modules; do
    conda deactivate
    conda activate $CENV
    echo $module
    log=logs/inst_${env}_${module}.log
    if [ $install != no ] ; then 
	if [[ $module == pip:* ]] ; then
	    echo Installing with pip ...
	    python -m pip install ${module/pip:/} > $log
	else
	    echo Installing..
	    mamba install --yes $channels_spec -q $module > $log
	fi
    fi
    if [ $do_test = yes ]; then
	# Useful ?
	if [ $import != last ] ; then 
	    sublist=$sublist" "$module
	else
	    sublist=$module
	fi
	echo "Importing or executing modules ["$sublist"]" 
	if ! python $test_import "$sublist" ; then
	    echo "Issue when importing $module, maybe check conda install log $log"
	    exit 1
	fi
    fi
    echo 
done
