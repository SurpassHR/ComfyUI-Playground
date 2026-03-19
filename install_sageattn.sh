# --- 自动获取显卡架构 (Arch List) ---
echo "正在检测 GPU 算力架构..."

COMFYUI_ROOT=$(dirname "$(realpath "$0")")

# 使用 Python 探测当前主显卡的算力版本
# 结果会从 (8, 9) 转换为 "8.9"
DETECTED_ARCH=$(python3 -c "
import torch
try:
    if torch.cuda.is_available():
        major, minor = torch.cuda.get_device_capability(0)
        print(f'{major}.{minor}')
    else:
        print('NOT_FOUND')
except Exception:
    print('ERROR')
")

# 逻辑判断：如果自动探测失败，手动设置一个安全值或报错
if [[ "$DETECTED_ARCH" == "NOT_FOUND" || "$DETECTED_ARCH" == "ERROR" ]]; then
    echo "警告: 自动探测架构失败，将尝试从 nvidia-smi 匹配或使用默认值。"
    # 备选方案：通过 nvidia-smi 的名字简单推断 (针对常见显卡)
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
    if [[ $GPU_NAME =~ "RTX 40" ]]; then DETECTED_ARCH="8.9"
    elif [[ $GPU_NAME =~ "RTX 30" ]]; then DETECTED_ARCH="8.6"
    elif [[ $GPU_NAME =~ "A100" ]]; then DETECTED_ARCH="8.0"
    elif [[ $GPU_NAME =~ "H100" ]]; then DETECTED_ARCH="9.0"
    else 
        DETECTED_ARCH="8.0" # 最终保底方案：使用通用的 Ampere 架构
        echo "无法确定具体型号，默认使用 8.0"
    fi
fi

echo ">> 最终选定的编译架构: TORCH_CUDA_ARCH_LIST=\"$DETECTED_ARCH\""

# --- 执行编译安装 ---
cd ${COMFYUI_ROOT}
[[ -d "SageAttention" ]] && rm -rf SageAttention
git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention

# 核心改进：组合环境变量进行一键安装
# 1. 指定架构 (减少 70%+ 编译量)
# 2. 限制任务数 (保护内存)
# 3. 禁用构建隔离 (使用当前虚拟环境的依赖)
export TORCH_CUDA_ARCH_LIST="$DETECTED_ARCH"
export MAX_JOBS=4

echo "正在开始编译安装 SageAttention (请观察进度)..."
uv pip install . --no-build-isolation -vv

cd ..
rm -rf ./SageAttention