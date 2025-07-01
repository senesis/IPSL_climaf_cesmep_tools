# Create a docker container based on a reference conda environment on some machine (e.g. spirit)
# Create a docker container archive for that container and push it to various HPC centers

# Author : S.Sénési - june 2022 / january 2023
# Change , 2024 : CliMAF code is no more included in the container

# Pre-requisites :
#------------------
#  - on current machine : have Docker and its buildx package installed 
#    (see https://docs.docker.com/get-docker/) and have sudo privilege
#    (Note for Debian : apt-get install docker-buildx-plugin)
#
#  - have http access to GitHub (for CliMAF)
#
#  - for some remote machine (e.g. spirit)
#     - have a working conda reference environment 
#     - have ssh access to that machine (preferably without password but with a key)
#     - login shell on that machine must be able to activate conda
#
#  - for a gateway for the HPC machines (e.g. spirit):
#     - have ssh access to that gateway (preferably without password but with a key)
#     - have ssh access from that gateway to Irene
#     - choose a location for a temporary file
#
#  - set the various variables documented below, from 'climaf_branch' to at least 'archives_dir'


# Note : upon run, the user will have to provide passwords interactively :
#  1- first for sudo on local machine
#  2- maybe next (and 3 times) for ssh/scp access to the conda env referece machine
#      (except if using SSH keys without password)
#  3- maybe next (and 2 times) for ssh/scp access to the gateway machine
#       (except if using SSH keys without password)
#  4- last for scp from gateway to Irene
#
# The last scp command may be deferred to a further stage in order to avoid waiting attending the execution


#set -x
set -e

# All variables to set stand below this line
#-----------------------------------------------------------------------------------------------------

# user@machine for the machine hosting the reference conda environment
remote_conda_env_machine=ssenesi@spirit1.ipsl.fr

# Ubuntu release ran by that machine (for exact reproduction of environment)
ubuntu_version="20.04"

# Name or full path of the reference conda environment
remote_conda_env=/net/nfs/tools/Users/SU/jservon/spirit-2021.11_envs/20240920

# May choose a name for the created conda environment, or use a sensible default
env_name=${env_name:-$(basename $remote_conda_env)}

# user@machine for the machine used as a gateway to Irene (for scp)
gateway=ssenesi@spirit2.ipsl.fr

# Choose a directory on the gateway for the docker container archive (must exist before run)
archives_dir_on_gateway=/scratchu/ssenesi

# Which are the targets on supercomputers :
# a string of white space separated  value such as user@irene-fr.ccc.cea.fr:/some/dir/
archives_dir_on_hpc="upe47jz@jean-zay.idris.fr:/gpfswork/rech/psl/commun/Tools/cesmep_environment/"
archives_dir_on_hpc+=" senesis@irene-fr.ccc.cea.fr:/ccc/work/cont003/igcmg/igcmg/climaf_python_docker_archives/"
# Choose a (local) working directory
WD=./

# Choose a (local) directory for the docker container archive (should be
# outside $WD for avoiding issue when iterating script runs). If path is relative,
# it will be interpreted w.r.t. $WD
archives_dir=../docker_archives

# May chose a name to give to the docker container, or use a sensible default
image_name=${env_name}:prod
# Convert to lower case (for some docker versions) 
image_name=${image_name,,}

# May choose a name for the container archive , or use a sensible default
archive_name=${env_name}.tar
archive=$archives_dir/$archive_name

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


echo
echo "Building Docker container $image_name"
echo "--------------------------------------------"
cat > Dockerfile <<-EOF
	# Incorporating CliMAF dependencies in a docker container based on Ubuntu $ubuntu_version
	
	FROM ubuntu:$ubuntu_version
	
	# Install wget (for getting miniconda) and texlive + pdftk (for CliMAF)
	ENV DEBIAN_FRONTEND=noninteractive 
	RUN apt-get -y update --fix-missing && \\
	    apt-get -y upgrade --fix-missing && \\
	    apt-get -y install --fix-missing apt-utils 
	RUN apt-get install -y --fix-missing wget && \\
	    apt-get install -y --fix-missing texlive texlive-xetex && \\
	    apt-get install -y --fix-missing pdftk && \\
	    apt-get clean && \\	     
	    rm -rf /var/lib/apt/lists/*

	# Install minimamba
	ENV CONDA_DIR=/opt/mamba
	RUN wget --quiet \\
	            https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh \\
	     	    -O ~/minimamba.sh && \\
	    /bin/bash ~/minimamba.sh -b -p /opt/mamba
	
	# Put mamba in path 
	ENV PATH=\$CONDA_DIR/bin:\$PATH
	
	# Install relevant conda environment from yml file
	WORKDIR /src
	COPY env.yml .
	RUN conda update -n base -c conda-forge conda
	RUN mamba update -y mamba && \\
	    mamba env create --name ${env_name} --file env.yml && \\
	    mamba clean --all -y

	# Pseudo-activate that conda env for runtime
	ENV PATH=\$CONDA_DIR/envs/${env_name}/bin:\$CONDA_DIR/condabin:\$PATH
	ENV LD_LIBRARY_PATH=\$CONDA_DIR/envs/${env_name}/lib:\$LD_LIBRARY_PATH

	# Prepare for run time	
	WORKDIR /home
	CMD ["bash"]
	EOF

echo
echo "Next requested password (if any) is the local sudo password"
time sudo docker buildx build -t $image_name . -f Dockerfile

echo
echo "Creating container archive $archive_name (in directory $archives_dir)"
echo "-----------------------------------------------------------------------------"
mkdir -p $archives_dir
rm -f $archive
time sudo docker save $image_name -o $archive
sudo chmod +r $archive


echo
echo "Pushing image archive to the gateway to HPC center(s), command is : "
echo "   scp -p $archive $gateway:$archives_dir_on_gateway"
echo "--------------------------------------------------------------------"
scp -p $archive $gateway:$archives_dir_on_gateway
for hpc in $archives_dir_on_hpc ; do 
    echo "Pushing image from gateway to ${hpc%:*} using command:"
    echo "   ssh -tt $gateway \"cd $archives_dir_on_gateway; scp -p $archive_name $hpc\""
    echo "Next password is for ${hpc%:*} (maybe with first the password for $gateway)"
    ssh -tt $gateway "cd $archives_dir_on_gateway; scp -p $archive_name $hpc"
    if [[ $hpc = *jean-zay* ]] ; then
	echo <<-EOT
	     On jean-zay-pp you must execute something like
	 	module load singularity
		singularity build ${archive_name/.tar/.sif} docker-archive://${hpc#*:}/$archive_name
	EOT
    if [[ $hpc = *irene* ]] ; then
	echo <<-EOT
	     On Irene you must execute something like 
	     	export PCOCC_CONFIG_PATH=${hpc#*:}/.config/pcocc
	 	pcocc-rs image import docker-archive://${hpc#*:}/$archive_name ipsl:cesmep_container
	EOT
    fi
done
