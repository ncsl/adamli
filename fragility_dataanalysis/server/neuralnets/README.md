# TensorFlow Dev

# Installation
1. Virtual Env 
Following tensorflow's documentation on https://www.tensorflow.org/versions/r0.10/get_started/os_setup#virtualenv_installation, I install GPU enabled tensorflow for python 2.7.

For Ubuntu:
'''
sudo apt-get install python-pip python-dev python-virtualenv

virtualenv --system-site-packages ~/tensorflow

source ~/tensorflow/bin/activate  # If using bash

# Ubuntu/Linux 64-bit, GPU enabled, Python 2.7
# Requires CUDA toolkit 7.5 and CuDNN v5. For other versions, see "Install from sources" below.

export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.10.0-cp27-none-linux_x86_64.whl

pip install --upgrade $TF_BINARY_URL
'''

Mac OSX:
'''
sudo easy_install pip
sudo pip install --upgrade virtualenv

virtualenv --system-site-packages ~/tensorflow

export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-0.10.0-py2-none-any.whl

pip install --upgrade $TF_BINARY_URL

'''
2. 

# Computational Notes:
