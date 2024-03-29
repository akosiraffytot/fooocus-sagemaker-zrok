#!/bin/bash

# Set this variable to true to install to the temporary folder, or to false to have the installation in permanent storage.
install_in_temp_dir=true

if [ ! -d "Fooocus" ]
then
  git clone https://github.com/lllyasviel/Fooocus.git
fi

cd Fooocus
git pull

# Update Python version to 3.10 and above
# Function to run a command
run_command() {
    echo "Please wait, $2 is loading..."
    $1 >/dev/null 2>&1
    echo "$2 completed!"
}

# Install Python 3.10 and update packages
run_command "conda install conda -y" "Conda"
run_command "conda update -n base conda -y" "Update"
run_command "conda create -n base python=3.10 -y" "Python"
run_command "conda install -q -y glib=2.51.0" "glib"

# Print Python version
echo "Congratulations. Your Python version now is:"
python --version

if [ "$install_in_temp_dir" = true ]
then
  echo "Installation folder: /tmp/fooocus_env"
  if [ ! -L ~/.conda/envs/fooocus ]
  then
    echo "removing ~/.conda/envs/fooocus"
    rm -rf ~/.conda/envs/fooocus
    rmdir ~/.conda/envs/fooocus
    ln -s /tmp/fooocus_env ~/.conda/envs/fooocus
  fi
else
  echo "Installation folder: ~/.conda/envs/fooocus"
  if [ -L ~/.conda/envs/fooocus ]
  then
    rm ~/.conda/envs/fooocus
  fi
fi

eval "$(conda shell.bash hook)"

if [ ! -d ~/.conda/envs/fooocus ]
then 
    echo ".conda/envs/fooocus is not a directory or does not exist"
fi

if [ ! -d /tmp/fooocus_env ] 
then
    echo "/tmp/fooocus_env is currently not a directory"
fi

if [ "$install_in_temp_dir" = true ] && [ ! -d /tmp/fooocus_env ] || [ "$install_in_temp_dir" = false ] && [ ! -d ~/.conda/envs/fooocus ]
then
    echo "Installing"
    if [ "$install_in_temp_dir" = true ] && [ ! -d /tmp/fooocus_env ]
    then
        echo "Creating /tmp/fooocus_env"
        mkdir /tmp/fooocus_env
    fi
    conda env create -f environment.yaml
    conda activate fooocus
    pwd
    ls
    pip install -r requirements_versions.txt
    pip install torch torchvision --force-reinstall --index-url https://download.pytorch.org/whl/cu117
    pip install opencv-python-headless
    rm -f /opt/conda/.condarc
    conda install -y conda-forge::glib
    rm -rf ~/.cache/pip
fi

# Because the file manager in Sagemaker Studio Lab ignores the folder called "checkpoints"
# we need to move checkpoint files into a folder with a different name
current_folder=$(pwd)
model_folder=${current_folder}/models/checkpoints-real-folder
if [ ! -e config.txt ]
then
  json_data="{ \"path_checkpoints\": \"$model_folder\" }"
  echo "$json_data" > config.txt
  echo "JSON file created: config.txt"
else
  echo "Updating config.txt to use checkpoints-real-folder"
  jq --arg new_value "$model_folder" '.path_checkpoints = $new_value' config.txt > config_tmp.txt && mv config_tmp.txt config.txt
fi

# If the checkpoints folder exists, move it to the new checkpoints-real-folder
if [ ! -L models/checkpoints ]
then
    mv models/checkpoints models/checkpoints-real-folder
    ln -s models/checkpoints-real-folder models/checkpoints
fi

conda activate fooocus
cd ..
pwd

# Install and set up ZROK (adjust installation path if needed)

mkdir -p /home/studio-lab-user/.zrok  # Create a ZROK directory in your home directory
wget -P /home/studio-lab-user/.zrok https://github.com/openziti/zrok/releases/download/v0.4.23/zrok_0.4.23_linux_amd64.tar.gz  # Download ZROK
tar -xf /home/studio-lab-user/.zrok/zrok*linux*.tar.gz -C /home/studio-lab-user/.zrok  # Extract ZROK
mkdir -p /home/studio-lab-user/.zrok/bin && install /home/studio-lab-user/.zrok/zrok /home/studio-lab-user/.zrok/bin  # Create bin directory and install ZROK

# Add ZROK to PATH environment variable
export PATH="/home/studio-lab-user/.zrok/bin:$PATH"

# Verify ZROK installation
zrok version

# Restart ZROK 
# zrok disable

# Enable Zrok
# Change YOUR_ZROK_TOKEN_HERE with your Zrok Token.
zrok enable YOUR_ZROK_TOKEN_HERE

# start zrok
if [ $# -eq 0 ]
then
    python start-zrok.py
fi
