#!/bin/bash

# Let the user know that they need to have the correct cuDNN archive present in their home directory first
echo "Checking your home directory for the correct cuDNN library archive. . ."

# Check to see if a file beginning with "cudnn-" in the name with the extension  ".tgz" is present in the users home directory.
if [ -e "$HOME"/cudnn-* ]; then
    echo "A cuDNN Archive is present"
else
    echo "ERROR: You must first download the correct cuDNN libraries from https://developer.nvidia.com/cudnn"
    echo "and place the archive in your home directory. You need to register for a free Nvidia Developer account first."
    exit 1
fi

echo "Checking cuDNN version, Arch & CUDA version compatibility. . ."

# Check to see if the file contains -11.2- immediately after cudnn.
if [[ $(ls "$HOME"/cudnn-* | grep -o 'cudnn-11.2') == "cudnn-11.2" ]]; then
    echo "cuDNN version is compatible with CUDA 11.2"
else
    echo "ERROR: The detected cuDNN archive does not support CUDA 11.2. Please ensure you download the correct archive and run this script again"
    exit 1
fi

# Check to see if "linux" is present next in the file name.
if [[ $(ls "$HOME"/cudnn-* | grep -o 'linux') == "linux" ]]; then
    echo "cuDNN archive is for Linux operating system"
else
    echo "ERROR: The detected cuDNN archive appears to be for the wrong operating system. Please ensure you have downloaded the correct archive and run this script again"
    exit 1
fi

# Check to see if -x64- is present after linux.
if [[ $(ls "$HOME"/cudnn-* | grep -o 'x64') == "x64" ]]; then
    echo "cuDNN archive is for x86_64 architecture"
else
    echo "WARNING: This script has only been tested on x86_64. The detected cuDNN libraries are for a different architecture."
    echo "If you continue there is no guarantee it will work"
    read -p "Do you want to continue? (Y/N): " user_choice
    if [[ $user_choice == "N" ]]; then
        exit 1
    fi
fi

# Check to make sure the file name contains v8.1.0.77
if [[ $(ls "$HOME"/cudnn-* | grep -o 'v8.1.0.77') == "v8.1.0.77" ]]; then
    echo "Great you have the correct cuDNN Library archive present. Lets continue!"
else
    echo "WARNING: The preferred cuDNN version is v8.1.0.77."
    echo "You have version $(ls "$HOME"/cudnn-* | grep -o '[0-9].*') , this is untested."
    read -p "Do you want to continue? (Y/N): " user_choice
    if [[ $user_choice == "N" ]]; then
        exit 1
    fi
fi

# Step 2: Install Dependencies
echo "Time to install some dependencies. . ."
sudo apt-get update -y
sudo apt-get install -y nano curl git build-essential gcc-9 g++-9 python-is-python3 python3-virtualenv python3-pip --no-install-recommends

# Check if all packages were successfully installed
if dpkg -s nano git build-essential gcc-9 g++-9 python-is-python3 python3-virtualenv python3-pip >/dev/null 2>&1; then
    echo "SUCCESS: Dependencies Installed"
else
    echo "ERROR: Some packages failed to install"
    echo "Please check the package names and your internet connection and run the script again."
    read -p "Do you want to exit? (Y/N): " user_choice
    if [[ $user_choice == "Y" ]]; then
        exit 1
    fi
fi

# Step 3: NVIDIA GPU drivers
echo "Taking care of the GPU drivers. . ."
if [[ $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | awk '{print $1}') == "450.80.02" ]]; then
    echo "GPU driver version $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | awk '{print $1}') already installed."
else
    echo "Installing recommended NVIDIA driver version"
    echo "Please wait. . ."
    recommended_driver=$(ubuntu-drivers devices | grep -i 'nvidia' | awk '{print $3}')
    sudo apt-get install -y $recommended_driver
    echo ""
fi

# Step 4: CUDA
echo "Let's get CUDA setup now."
echo "Please wait. . ."
curl -# -O https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux.run
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
sudo sh cuda_11.2.0_460.27.04_linux.run --silent --toolkit --override
echo "CUDA Installed"

# Step 5: cuDNN
echo "Loading cuDNN Libraries"
echo "Please wait. . ."
tar -xzvf cudnn-11.2-linux-x64-v8.1.0.77.tgz
sudo cp -P cuda/include/cudnn.h /usr/local/cuda-11.2/include
sudo cp -P cuda/lib64/libcudnn* /usr/local/cuda-11.2/lib64/
sudo chmod a+r /usr/local/cuda-11.2/lib64/libcudnn*
echo "cuDNN libraries Installed"

# Step 6: Library Paths
echo "Adding CUDA and cuDNN library paths"
echo "export PATH=/usr/local/cuda/bin:\$PATH" >> /home/$USER/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" >> /home/$USER/.bashrc
echo "export PATH=/home/$USER/.local/bin:\$PATH" >> /home/$USER/.bashrc
source /home/$USER/.bashrc
echo ""

echo "Verifying cuda-11-2.conf"
if [ -f /etc/ld.so.conf.d/cuda-11-2.conf ]; then
  echo "cuda-11-2.conf found"
else
  echo "/etc/ld.so.conf.d/cuda-11-2.conf" >> /etc/ld.so.conf.d/cuda-11-2.conf
  echo "/usr/local/cuda-11.2/targets/x86_64-linux/lib" >> /etc/ld.so.conf.d/cuda-11-2.conf
  echo "/usr/local/cuda/bin" >> /etc/ld.so.conf.d/cuda-11-2.conf
fi

echo "Creating ncbin.conf"
echo "/home/$USER/.local/bin" >> /etc/ld.so.conf.d/ncbin.conf
sudo ldconfig
echo ""

# Step 7
print "Verifying CUDA and cuDNN installation. . ."

NVCC_OUTPUT=$(nvcc --version)
echo "$NVCC_OUTPUT"

if echo "$NVCC_OUTPUT" | grep -q 'nvcc\|NVIDIA\|Cuda\|compiler\|Built\|compilation tools\|release 11.2'; then
    echo "CUDA and cuDNN have been successfully installed. Next let's setup Tensorflow."
else
    echo "Something doesn't seem right... please review the output"
    read -p "Do you want to continue? (Y/N)" choice
    case "$choice" in 
      y|Y ) echo "Continuing";;
      n|N ) echo "Exiting"; exit 1;;
      * ) echo "Invalid input. Exiting";;
    esac
fi

# Step 9
print("Installing Tensorflow and TensorRT")
!pip install --upgrade pip &> /dev/null
!pip install tensorflow tensorrt &> /dev/null

if successful:
    print("SUCCESS! You should now be able to enable Tensorflow GPU Mode in the Admin settings of Recognize.")
    install_nvtop = input("It is recommended to use 'nvtop' to monitor and verify that your GPU is being used by Recognize. Do you want to install nvtop now? (Y/N)")
    if install_nvtop == "Y":
        !apt-get install nvtop -y &> /dev/null
        print("Installed. 'nvtop' can be ran from the command line")
    else:
        print("Have a great day!")
else:
    print("ERROR: Tensorflow and TensorRT installation failed.")
