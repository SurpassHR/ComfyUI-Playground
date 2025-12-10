COMFYUI_ROOT="/root/autodl-tmp/ComfyUI"

SUDO="sudo"
# 检查当前是否是root用户，如果是root用户后续命令不需要添加sudo
if [[ $EUID -ne 0 ]]; then
    SUDO=""
fi

# 检查当前ubuntu版本，格式为例如2204
UBUNTU_VERSION=$(lsb_release -rs | sed 's/\.//')

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/cuda-ubuntu${UBUNTU_VERSION}.pin
$SUDO mv cuda-ubuntu${UBUNTU_VERSION}.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-ubuntu${UBUNTU_VERSION}-12-8-local_12.8.0-570.86.10-1_amd64.deb
$SUDO dpkg -i cuda-repo-ubuntu${UBUNTU_VERSION}-12-8-local_12.8.0-570.86.10-1_amd64.deb
$SUDO cp /var/cuda-repo-ubuntu${UBUNTU_VERSION}-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
$SUDO apt-get update
$SUDO apt-get -y install cuda-toolkit-12-8
rm -rf ./cuda-repo-ubuntu${UBUNTU_VERSION}-12-8-local_12.8.0-570.86.10-1_amd64.deb
$SUDO apt-get clean
$SUDO rm -rf /var/lib/apt/lists/*

cd ${COMFYUI_ROOT}
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention
uv pip install . --no-build-isolation # 直接指定sm_xx然后运行，如：TORCH_CUDA_ARCH_LIST="8.9" uv pip install . --no-build-isolation
cd .. && rm -rf ./SageAttention