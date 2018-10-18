#!/bin/bash

# ==============================================================================
# for the HPRC environment creation
# We recommend using Anaconda2, Python 2.7.
# ==============================================================================
dos2unix *.*
cd $(SCRATCH)							# Make scratch your current directory
module load Anaconda2/5.2.0				# Load Anaconda module
conda env create -f environment.yml		# Create environment

# ==============================================================================
# Clone the Deep Feature Flow repository, and
# we'll call the directory that you cloned Deep-Feature-Flow as ${DFF_ROOT}.
# ==============================================================================
DFF_ROOT = $HOME/dlproject
cd $(DFF_ROOT)
git clone https://github.com/msracver/Deep-Feature-Flow.git

# ==============================================================================
# build cython module automatically and create some folders.
# ==============================================================================
./init.sh

# ==============================================================================
# For advanced users, you may put your Python package into ./external/mxnet/$(YOUR_MXNET_PACKAGE)
# Clone MXNet and checkout to MXNet@(commit 62ecb60) by
# ==============================================================================
cd ./external/mxnet
git clone --recursive https://github.com/dmlc/mxnet.git
git checkout 62ecb60
git submodule update
MXNET_ROOT = ./external/mxnet/*
cd $(DFF_ROOT)

# ==============================================================================
# Copy operators in $(DFF_ROOT)/dff_rfcn/operator_cxx or
# $(DFF_ROOT)/rfcn/operator_cxx to $(YOUR_MXNET_FOLDER)/src/operator/contrib by
# ==============================================================================
cp -r $(DFF_ROOT)/dff_rfcn/operator_cxx/* $(MXNET_ROOT)/src/operator/contrib/

# ==============================================================================
# Compile MXNet
# ==============================================================================
cd $(MXNET_ROOT)
make -j4

# ==============================================================================
# Install the MXNet Python binding by
# Note: If you will actively switch between different versions of MXNet, please follow 3.5 instead of 3.4
# ==============================================================================
cd python
sudo python setup.py install
cd $(DFF_ROOT)

# ==============================================================================
# modify MXNET_VERSION in ./experiments/dff_rfcn/cfgs/*.yaml to $(YOUR_MXNET_PACKAGE).
# Thus you can switch among different versions of MXNet quickly.
# ==============================================================================
sed -i '2 MXNET_VERSION: "$(MXNET_ROOT)" ' ./experiments/dff_rfcn/cfgs/*.yaml
