# 获取操作系统类型 (windows 或 linux)
os_name=$(python -c "import os; print(os.name)")

if [ "$os_name" == "nt" ]; then
    # Windows 社区预编译轮子仓库
    uv pip install flash-attn --find-links https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/latest
else
    # Linux 官方/社区预编译轮子仓库
    uv pip install flash-attn --find-links https://github.com/Dao-AILab/flash-attention/releases/latest \
                             --find-links https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/latest
fi