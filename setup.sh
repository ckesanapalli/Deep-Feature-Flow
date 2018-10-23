#!/bin/bash
##ENVIRONMENT SETTINGS; CHANGE WITH CAUTION

#SBATCH --export=NONE               			#Do not propagate environment
#SBATCH --get-user-env=L            			#Replicate login environment

##NECESSARY JOB SPECIFICATIONS
#SBATCH --job-name="DFF_Project_Setup"			#Set the job name
#SBATCH --time=02:00:00							#Set the wall clock limit

#SBATCH --ntasks=1								#Request 1 task
#SBATCH --mem=2560M								#Request 2560MB (2.5GB) per node
#SBATCH --output=start_log.%j.txt				#Send stdout/err
# #SBATCH --gres=gpu:1							#Request 1 GPU per node can be 1 or 2
# #SBATCH --partition=gpu							#Request the GPU partition/queue

##OPTIONAL JOB SPECIFICATIONS
#SBATCH --account=122806181077					#Set billing account to 123456
#SBATCH --mail-type=END							#Send email on all job events
#SBATCH --mail-user=k.c.chowdary135@gmail.com	#Send all emails to email_address


# Copy start.sh and environment.yml files to the HPRC server

# ==============================================================================
# for the HPRC environment creation
# We recommend using Anaconda, Python 2.7.
# ==============================================================================
DFF_MAIN=$(pwd)
cd $SCRATCH						# Make scratch your current directory
ml purge                       	# Purge all modules
ml CUDA/9.0.176					# Load CUDA module
ml Anaconda/3-5.0.0.1			# Load Anaconda module
conda env create -f $DFF_MAIN/environment.yml		# Create environment

# ==============================================================================
# Clone the Deep Feature Flow repository, and
# we'll call the directory that you cloned Deep-Feature-Flow as ${DFF_ROOT}.
# ==============================================================================
cd $DFF_MAIN
git clone https://github.com/ckesanapalli/Deep-Feature-Flow.git
DFF_ROOT="$DFF_MAIN/Deep-Feature-Flow"
# ==============================================================================
# build cython module automatically and create some folders.
# ==============================================================================
cd $DFF_ROOT
./init.sh

# ==============================================================================
# For advanced users, you may put your Python package into ./external/mxnet/$(YOUR_MXNET_PACKAGE)
# Clone MXNet and checkout to MXNet@(commit 62ecb60) by
# ==============================================================================
cd $DFF_ROOT/external/mxnet
git clone --recursive https://github.com/dmlc/mxnet.git
git checkout 62ecb60
git submodule update
MXNET_ROOT="$DFF_ROOT/external/mxnet/mxnet"

# ==============================================================================
# Copy operators in $(DFF_ROOT)/dff_rfcn/operator_cxx or
# $(DFF_ROOT)/rfcn/operator_cxx to $(YOUR_MXNET_FOLDER)/src/operator/contrib by
# ==============================================================================
cd $DFF_ROOT
cp -r $DFF_ROOT/dff_rfcn/operator_cxx/* $MXNET_ROOT/src/operator/contrib/

# ==============================================================================
# Compile MXNet
# ==============================================================================
cd $MXNET_ROOT
make -j4

# ==============================================================================
# Install the MXNet Python binding by
# Note: If you will actively switch between different versions of MXNet, please follow 3.5 instead of 3.4
# ==============================================================================
cd $MXNET_ROOT/python
# Error: Cannot use sudo in HPRC Server
# sudo python setup.py install 
python setup.py install

# ==============================================================================
# modify MXNET_VERSION in ./experiments/dff_rfcn/cfgs/*.yaml to $(YOUR_MXNET_PACKAGE).
# Thus you can switch among different versions of MXNet quickly.
# ==============================================================================
cd $DFF_ROOT/experiments/dff_rfcn/cfgs
sed "s/\<MXNET_VERSION: \"mxnet\"\>/MXNET_VERSION: \"$(MXNET_ROOT)\"/g" *.yaml

# ==============================================================================
# making model and data folders
# ==============================================================================
cd $DFF_ROOT
mkdir model
mkdir model/pretrained_model/a
mkdir data/ILSVRC2015/
mkdir data/ILSVRC2015/Annotations/
mkdir data/ILSVRC2015/Annotations/DET
mkdir data/ILSVRC2015/Annotations/VID
mkdir data/ILSVRC2015/Data
mkdir data/ILSVRC2015/Data/DET
mkdir data/ILSVRC2015/Data/VID
mkdir data/ILSVRC2015/ImageSets