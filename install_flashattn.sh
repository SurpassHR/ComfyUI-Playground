os_name=$(python -c "import os; print(os.name)")
if [ "$os_name" == "nt" ]; then
    # for windows https://huggingface.co/lldacing/flash-attention-windows-wheel/tree/main https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/lastest
    aria2c https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.4.10/flash_attn-2.8.2+cu128torch2.8-cp312-cp312-win_amd64.whl
    uv pip install flash_attn-2.8.2+cu128torch2.8-cp312-cp312-win_amd64.whl
elif [ "$os_name" == "posix" ]; then
    # for linux https://github.com/Dao-AILab/flash-attention/releases/latest
    aria2c https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu12torch2.8cxx11abiTRUE-cp312-cp312-linux_x86_64.whl
    uv pip install flash_attn-2.8.3+cu12torch2.8cxx11abiTRUE-cp312-cp312-linux_x86_64.whl
fi