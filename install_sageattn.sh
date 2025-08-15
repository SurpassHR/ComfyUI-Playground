COMFYUI_ROOT="/root/autodl-tmp/ComfyUI"

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-ubuntu2204-12-8-local_12.8.0-570.86.10-1_amd64.deb
dpkg -i cuda-repo-ubuntu2204-12-8-local_12.8.0-570.86.10-1_amd64.deb
cp /var/cuda-repo-ubuntu2204-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
apt-get update
apt-get -y install cuda-toolkit-12-8
rm -rf ./cuda-repo-ubuntu2204-12-8-local_12.8.0-570.86.10-1_amd64.deb
apt-get clean
rm -rf /var/lib/apt/lists/*

cd ${COMFYUI_ROOT}
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
python -s -m pip install . --no-build-isolation
cd .. && rm -rf ./SageAttention