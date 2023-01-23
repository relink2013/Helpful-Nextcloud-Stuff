
# Enabling Tensorflow GPU mode for Recognize in Nextcloud 25.0.3

*These instructions are for a Minimized installation of Ubuntu Server 22.04. However I am sure they can easily be adapted to any other distro.*

  

## Prep & Dependancies
```
sudo apt update && sudo apt install -y nano git build-essential gcc-9 g++-9 python-is-python3 python3-virtualenv python3-pip
```
  

## Instal Latest Nvidia Driver (As of writing it's v525.78.01)
```
sudo ubuntu-drivers autoinstall
```
  

## Manually download the correct CUDA version
```
wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux.run
```
  

## Set your complier to the latest version compatible with the above libs (v9 as of Ubuntu 22.04)
```
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100
```
```
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
```
  

## Manually install CUDA using the above package from Nvidia

*Make sure you un-check to install the GPU Drivers as they are already setup from step 2*
```
sudo sh cuda_11.2.0_460.27.04_linux.run
```
  

## Manually Install the correct cuDNN version

*Create Nvidia developer account and download the following file to your home directory:*

https://developer.nvidia.com/compute/machine-learning/cudnn/secure/8.1.0.77/11.2_20210127/cudnn-11.2-linux-x64-v8.1.0.77.tgz

  

## Decompress
```
tar -zvxf cudnn-11.2-linux-x64-v8.1.0.77.tgz
```
  

## Move the files to where they belong
```
sudo cp -P cuda/include/cudnn.h /usr/local/cuda-11.2/include
```
```
sudo cp -P cuda/lib64/libcudnn* /usr/local/cuda-11.2/lib64/
```
```
sudo chmod a+r /usr/local/cuda-11.2/lib64/libcudnn*
```
  

## Edit your bashrc file to add the paths to the new libs
```
nano /home/$USER/.bashrc
```
  

## Add the following to the file
*I chose to add them toward the top under the line that reads "# for examples". But I dont think it really matters where they go.* 

    export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}$

    export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

    export PATH=/home/nextcloud/.local/bin:$PATH

  

## Run in terminal
```
source .bashrc
```
  

## It is also good to ensure the libraries are in ld.so

*First check that `cuda-11-2.conf` is present (it should already be there)*
```
sudo ls /etc/ld.so.conf.d/
```

*If for somereason its not there then you will need to create it by running*
```
sudo nano /etc/ld.so.conf.d/cuda-11-2.conf
```
 *Then add the following lines ensuring they are correctly pointing to your cuda libraries.
 The below is for Ubuntu, paths may be different for other distros.*
```
/usr/local/cuda-11.2/targets/x86_64-linux/lib
/usr/local/cuda/bin
```
  

## Then Create an additional conf for your local bin directory
```
sudo nano /etc/ld.so.conf.d/ncbin.conf
```
  

## Add this one line to the file and replace <USER> with your user name.
```
/home/<USER>/.local/bin
```
  

## Save the ncbin.conf file and then run the following to make the system aware of the change.
```
sudo ldconfig
```
  

## At this point CUDA and cuDNN should be functioning.
 *Run in terminal to verify.*
```
nvcc --version
```
 
## If everythis is installed correctly you should see an output similar to the following:
```
nvcc: NVIDIA (R) Cuda compiler driverCopyright (c) 2005-2020 NVIDIA Corporation
Built on Mon_Nov_30_19:08:53_PST_2020
Cuda compilation tools, release 11.2, V11.2.67
Build cuda_11.2.r11.2/compiler.29373293_0
```
  

## Last step is to install Tensorflow & TensorRT
*This is a fairly large download so it may take a while.*
```
pip install --upgrade pip && pip install tensorflow tensorrt
```
  
________
Once everything is done that should be it. Go login to your Nextcloud with an Admin account.

Go into `Administration` > `Recognize` & scroll down to "`Tensorflow GPU mode`"

You should now be able to enable GPU mode with no error messages!!!

When working correctly the green box should NOT change and should still only say

    Libtensorflow was loaded successfully into Node.js.

If there is an issue that box will turn orange and say,
```
Successfully loaded libtensorflow in Node.js, but couldn't load GPU. Make sure 
CUDA Toolkit and cuDNN are installed and accessible, or turn off GPU mode. 
```
I have still seen the Orange error a few times despite monitoring the GPU and seeing that it's working just fine. A refresh of the page made it go away. So don't panic, follow the optional step below so that your able to monitor the GPU and see for yourself if its working or not.

  

## OPTIONAL

*If youd like to verify that Tensorflow is infact using CUDA then I reccomend installing "nvtop"*
```
sudo apt install nvtop
```

*Simply run it from a terminal*
```
nvtop
```
  And you should now see a graph showing GPU & VRAM usage along with a list of running GPU processes. For Recognize you want to see the following process listed.
```
/var/www/nextcloud/apps/recognize/bin/node
```
  

Keep in mind that Recognize works in batches so you will see the graph spike and drop every few minutes. You will also see the process exit and come back. This is normal. 

Recognize will also still use your CPU as well. If you want to limit the usage of your CPU you can use the "CPU cores" option.

  
  

## Notes

As of writing this guide (01/22/2023) I do NOT recommend trying to add the Nvidia developer repositories. I tried several times to add the repositories to my system and received errors pertaining to outdated key storage methods, and the repositories not containing a "release" file for Ubuntu 22.04 despite the fact they clearly do. 

Besides, while updating the GPU driver SHOULD be perfectly fine, you really don't want to update CUDA or cuDNN unless Recognize specifies that a newer version is ok to use. So I personally recommend sticking with a static installation that wont be automatically updated. 

	 

