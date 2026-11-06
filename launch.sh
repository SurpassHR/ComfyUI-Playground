#!/bin/bash

# ComfyUI launching script for Linux/macOS also suitable for windows bash

params=""

# 自定义节点加载策略：
#   all      = 加载全部自定义节点（原始行为）
#   minimax  = 只加载 MiniMax SEED HUNTER 工作流所需的节点包（白名单）
#   none     = 全部屏蔽，仅核心节点（排查前端卡死时用）
CUSTOM_NODES_MODE="minimax"

# 采样预览方式：
#   auto  = 隐空间近似（Latent2RGB），不依赖 vae_approx 里的预览模型
#   taesd = 用 vae_approx/ 下的 TAE 解码器，画质更好
# 注意：MiniMax H3 用 taesd 时，ComfyUI 的视频 TAE 会返回 5D 张量 (B,T,H,W,C)，
# 而 VHS 的动画潜在预览（工作流 extra 里的 VHS_latentpreview）按 4D 处理，
# 会报 "Input and output must have the same number of spatial dimensions"。
# 所以这里默认用 auto。
PREVIEW_METHOD="auto"

# 各工作流所需的节点包，目录名必须与 custom_nodes 下完全一致；可重复，重复无副作用

# MiniMax SEED HUNTER v2.5.1
SEEDHUNTER_NODES=(
    ComfyUI-Easy-Use                          # easy seed
    ComfyUI-Fantastic-MiniMaxH3-PromptBuilder # MiniMaxH3MediaLoader / MiniMaxH3ReferenceSplitter
    ComfyUI-H3-Prompt-IDE                     # H3PromptIDE / H3PromptReferenceInputs
    ComfyUI-KJNodes                           # ImageResizeKJv2 / INTConstant / MiniMaxChunkFeedForward 等 10 个
    ComfyUI-MiniMaxH3Mod                      # MiniMaxH3RefModsLoader / MiniMaxH3RefModApply
    ComfyUI-Pixaroma                          # PixaromaGroupSwitch / PixaromaLabel / PixaromaLoraLoader 等 5 个
    ComfyUI-VFI                               # RIFEInterpolation
    Comfyui_Minimax_h3_latent_Upscaler        # MinimaxH3LatentUpscaler3D
    ControlAltAI-Nodes                        # ThreeWaySwitch
    cg-use-everywhere                         # Anything Everywhere
    comfyui-videohelpersuite                  # VHS_VideoCombine / VHS_GetImageCount / VHS_LoadAudioUpload
    rgthree-comfy                             # Any Switch (rgthree)
    # ComfyUI-Manager                         # 需要 Manager 界面时取消注释（会在启动时联网抓取缓存）
)

# KREA2：[T2I] Simple New + [I2I] A2R Double Pass
KREA2_NODES=(
    CRT-Nodes                           # FancyTimerNode
    ComfyUI-CacheDiT                    # CacheDiT_Model_Optimizer
    ComfyUI-ConditioningKrea2Rebalance  # Switch
    ComfyUI-Easy-Use                    # easy ifElse / cleanGpuUsed / imageScaleToNormPixels 等
    ComfyUI-KJNodes                     # PathchSageAttentionKJ / ImageConcatMulti / ModelPatchTorchSettings
    ComfyUI-Krea2-Ostris-Edit           # Krea2OstrisEditModelPatch / TextEncodeKrea2OstrisEdit
    ComfyUI-MultiGPU                    # UNETLoaderDisTorch2MultiGPU
    ComfyUI-PlagueKind-Nodes            # UnifiedResizeImageMask
    ComfyUI-ZImagePowerNodes            # StyleStringInjector2 //ZImagePowerNodes
    ComfyUI-krea2-negpip                # ApplyKrea2NegPiP
    ComfyUI_Mira                        # UpscaleImageByModelThenResize
    ComfyUI_essentials                  # GetImageSize+ / ImageResize+ / SimpleMath+
    Comfyui_PDuse                       # PD_ShowText
    Comfyui_TTP_Toolset                 # TTP_Image_Assy / TTP_Image_Tile_Batch / TTP_Tile_image_size
    Goohaitools-comfyui                 # 数学运算_孤海
    comfyui-custom-scripts              # ShowText|pysssss
    comfyui-impact-pack                 # FaceDetailer / SAMLoader
    comfyui-impact-subpack              # UltralyticsDetectorProvider
    comfyui-krea2-conditioning          # ConditioningKrea2Rebalance
    comfyui-vrgamedevgirl               # FastFilmGrain
    comfyui_tinyterranodes              # ttN seed
    masquerade-nodes-comfyui            # Get Image Size
    rgthree-comfy                       # Power Lora Loader (rgthree)
    seedvr2_videoupscaler               # SeedVR2LoadDiTModel / SeedVR2LoadVAEModel / SeedVR2VideoUpscaler
    was-ns                              # Text Concatenate / Text Multiline
)

# python whitelist_from_workflow.py \
#     "user/default/workflows/MINIMAX/minimaxH3SEEDHUNTERLatent_v251.json" \
#     "user/default/workflows/MINIMAX/[REF2VA] Motion Context.json" \
#     "user/default/workflows/KREA2/[I2I] A2R Double Pass.json" \
#     "user/default/workflows/KREA2/[T2I] Simple New.json" \
#     "user/default/workflows/KREA2/[I2I] QuadView.json" \
#     --write whitelist_nodes.sh

# 与工作流无关的必需包：ComfyUI-MultiGPU 会无条件注册一批包装节点，它们的输入项直接查
# ComfyUI-GGUF 注册的 unet_gguf/clip_gguf 目录键，以及 ComfyUI-WanVideoWrapper 注册的
# wav2vec2 目录键和 WanVideo 原节点。这两个包不在白名单里时，前端每次拉 /object_info
# 都会刷一批 KeyError 报错。
REQUIRED_NODES=(
    ComfyUI-GGUF
    ComfyUI-WanVideoWrapper
    ComfyUI-Manager
    ComfyUI-Crystools
    Comfyui-QwenEditUtils
    comfyui-artius-browser
    RES4LYF
    ComfyUI-MOSS-Image-Ostris-Edit
    comfyui-wd14-tagger
    ComfyUI-NO8D-controls
    ComfyUI-Spectrum-MOSS
    ComfyUI-MOSS-Merge-Presets
    ComfyUI-Viggle-Remake
    Comfyui-Spectrum-Qwen2.1
    ComfyUI-SolAttn_triton
    selflift-Avatar
    ComfyUI-YCNodes-MiniMax-H3
    ComfyUI-H3-Multishot
)

# 优先使用 whitelist_from_workflow.py 生成的白名单文件；文件不存在时用上面手写的两组
WHITELIST_FILE="$(dirname "$0")/whitelist_nodes.sh"
if [ -f "$WHITELIST_FILE" ]; then
    # shellcheck source=/dev/null
    source "$WHITELIST_FILE"
    echo "自定义节点白名单：来自 whitelist_nodes.sh（${#WHITELIST_NODES[@]} 个包）"
else
    WHITELIST_NODES=("${SEEDHUNTER_NODES[@]}" "${KREA2_NODES[@]}")
fi

# 白名单来自生成文件还是手写数组都要补上 MultiGPU 节点的依赖，重复条目无副作用
WHITELIST_NODES+=("${REQUIRED_NODES[@]}")

case "$CUSTOM_NODES_MODE" in
    all)
        node_flags=""
        echo "自定义节点：全部加载"
        ;;
    minimax)
        node_flags="--disable-all-custom-nodes --whitelist-custom-nodes ${WHITELIST_NODES[*]}"
        echo "自定义节点：仅加载白名单（${#WHITELIST_NODES[@]} 个包，含必需依赖 ${REQUIRED_NODES[*]}）"
        ;;
    none)
        node_flags="--disable-all-custom-nodes"
        echo "注意：已屏蔽所有自定义节点"
        ;;
    *)
        echo "未知的 CUSTOM_NODES_MODE='$CUSTOM_NODES_MODE'，按 all 处理"
        node_flags=""
        ;;
esac

# Check if parameters exist
if [ $# -eq 0 ]; then
    params=""
    echo "No parameters found, using default parameters."
else
    echo "Parameters found: $@"
    params="$@"
fi

echo "Updating workflows"
bash update_workflows.sh

PYTHON="python"  # Linux/macOS uses .venv/bin/python instead of .venv/Scripts/python.exe
export LD_LIBRARY_PATH=/home/hr/Projects/Codes/ComfyUI/.venv/lib/python3.12/site-packages/nvidia/cu13/lib:/home/hr/Projects/Codes/ComfyUI/.venv/lib/python3.12/site-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
if [ -z "$params" ]; then
    "$PYTHON" -B main.py \
        $node_flags \
        --port 55554 \
        --disable-cuda-malloc \
        --preview-method "$PREVIEW_METHOD" \
        --cache-ram 40 \
        --disable-xformers \
        --disable-pinned-memory \
        --output-directory /media/hr/Data/GeneratedImages \
        --input-directory /media/hr/Data/InputImages
else
    TF_ENABLE_ONEDNN_OPTS=0 "$PYTHON" -B main.py \
        "$@" \
        $node_flags \
        --port 55554 \
        --disable-cuda-malloc \
        --preview-method "$PREVIEW_METHOD" \
        --async-offload \
        --cache-ram \
        --output-directory /media/hr/Data/GeneratedImages
fi

echo "Uploading workflows"
bash upload_workflows.sh
