# Create a docker container based on a reference conda environment on some machine (e.g. spirit)
# Add Climaf sources to the container
# Create an archive for that container and push it to Irene

# Author : S.Sénési - june 2022

# Pre-requisites :
#------------------
#  - on current machine : have Docker installed (see
#    https://docs.docker.com/get-docker/) and have sudo privilege
#
#  - have http access to GitHub (for CliMAF)
#
#  - for some remote machine (e.g. spirit)
#     - have a working conda reference environment 
#     - have ssh access to that machine (preferably without password but with a key)
#     - login shell on that machine must be able to activate conda
#
#  - for a gateway for Irene (e.g. Ciclad):
#     - have ssh access to that gateway (preferably without password but with a key)
#     - have ssh access from that gateway to Irene
#     - choose a location for a temporary file
#
#  - set the various variables documented below, from 'climaf_branch' to 'archives_dir'


# Note : upon run, the user will have to provide passwords interactively :
#  1- first for sudo on local machine
#  2- maybe next (and 3 times) for ssh/scp access to the conda env referece machine (except if using SSH keys without password)
#  3- maybe next (and 2 times) for ssh/scp access to the gateway machine (except if using SSH keys without password)
#  4- last for scp from gateway to Irene
#
# The last scp command may be deferred to a further stage in order to avoid waiting attending the execution


set -x
set -e

# All variables to set stand below this line
#-----------------------------------------------------------------------------------------------------

# Which is the reference CliMAF repository (note : you may supersede
# CliMAF code later, when using the container on Irene)
climaf_repository=http://github.com/rigoudyg/climaf.git

# Name of the CliMAF branch to include (note : you may supersede
# CliMAF code later, when using the container on Irene)
climaf_branch=run_cesmep_on_spirit_and_at_TGCC

# user@machine for the machine hosting the reference conda environment
remote_conda_env_machine=ssenesi@spirit1.ipsl.fr

# Ubuntu release for that machine (for exact reproduction of environment)
ubuntu_version="20.04"

# Name or full path of the reference conda environment
remote_conda_env=/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs/climaf_spirit_0

# May choose a name for the created conda environment, or use a sensible default
env_name=$(basename $remote_conda_env)

# user@machine for the machine used as a gateway to Irene (for scp)
gateway=ssenesi@ciclad.ipsl.upmc.fr

# Choose a directory on the gateway for the docker container archive (must exists before run)
archives_dir_on_gateway="/scratchu/ssenesi"

# Which is the target directory on Irene (with prefix user@irene-fr.ccc.cea.fr:)
archives_dir_on_irene=senesis@irene-fr.ccc.cea.fr:/ccc/cont003/home/ipsl/senesis/work/docker_archives

# Choose a (local) working directory
WD=./

# Choose a (local) directory for the docker container archive (should be
# outside $WD for avoiding issue when iterating script runs). If path is relative,
# it will be interpreted w.r.t. $WD
archives_dir=../docker_archives

# May chose a name to give to the docker container, or use a sensible default
#image_name=cesmep:prod
image_name=${env_name}:prod

# May choose a name for the container archive , or use a sensible default
archive_name=${env_name}.tar

# All variables to set stand above this line
#-----------------------------------------------------------------------------------------------------



mkdir -p $WD ; cd $WD

echo "Creating conda environment definition file from remote conda env "
echo "$remote_conda_env on machine $remote_conda_env_machine"
echo "---------------------------------------------------------------------------------------------"
time ssh $remote_conda_env_machine "conda activate $remote_conda_env ; conda env export -f tmp_environment_full.yml"
scp $remote_conda_env_machine:tmp_environment_full.yml .
ssh $remote_conda_env_machine "rm -f tmp_environment_full.yml"
echo "name: $env_name" > env.yml
sed -e '$ d' -e '1 d' tmp_environment_full.yml >> env.yml
rm tmp_environment_full.yml


echo "Getting CliMAF code for branch $climaf_branch (except if areay available in $WD)"
echo "--------------------------------------------------------------------------------------"
[ ! -d climaf ] && time git clone -b $climaf_branch $climaf_repository


echo "Building Docker container $image_name"
echo "--------------------------------------------"
cat > Dockerfile <<-EOF
	# Incorporating CliMAF and dependencies in a docker container based on Ubuntu $ubuntu_version
	
	FROM ubuntu:$ubuntu_version
	
	# Install wget (for getting miniconda) and pdftk (for CliMAF)
	RUN apt-get -y update && \\
	    apt-get -y install apt-utils 
	RUN apt-get install -y wget && \\
	    apt-get -y install pdftk && \\
	    apt-get clean && \\
	    rm -rf /var/lib/apt/lists/*
	
	# Install miniconda or minimamba
	ENV CONDA_DIR=/opt/mamba
	#RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
	#    /bin/bash ~/miniconda.sh -b -p /opt/conda
	RUN wget --quiet \\
	            https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh \\
	     	    -O ~/minimamba.sh && \\
	    /bin/bash ~/minimamba.sh -b -p /opt/mamba
	
	# Put conda in path so we can use conda activate
	ENV PATH=\$CONDA_DIR/bin:\$PATH
	
	# Install relevant conda environment from yml file
	WORKDIR /src
	COPY env.yml .
	RUN mamba update -y mamba && \\
	    mamba env create --name ${env_name} --file env.yml && \\
	    mamba clean --all -y
	
	# Install CliMAF 
	COPY climaf /src/climaf	
	ENV PYTHONPATH=/src/climaf:\$PYTHONPATH
	ENV PATH=/src/climaf/bin:\$PATH
	
	CMD ["bash"]
	EOF

echo "Next requested password (if any) is the local sudo password"
time sudo docker build -t $image_name . -f Dockerfile


echo "Creating container archive $archive_name (in directory $archives_dir)"
echo "-----------------------------------------------------------------------------"
mkdir -p $archives_dir
archive=$archives_dir/$archive_name
rm -f $archive
time sudo docker save $image_name -o $archive


echo "Pushing image archive to Irene, using gateway $gateway"
echo "-------------------------------------------------------------"
sudo chmod +r $archive
scp $archive $gateway:$archives_dir_on_gateway
echo "Copying image on Irene"
echo "Next password is for Irene (maybe with first the password for $gateway)"
ssh $gateway "cd $archives_dir_on_gateway; scp $archive_name $archives_dir_on_irene"

