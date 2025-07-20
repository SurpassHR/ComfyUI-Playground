#!/bin/bash

set -euo pipefail

# 下载（clone）自定义节点，如已存在，则更新（pull），额外处理含有子模块的节点
# 其中，正则表达式内容为：从链接中查找仓库名称 REPO_NAME
# 先匹配 [https://example.com/xyz/REPO_NAME.git] 或 [git@example.com:xyz/REPO_NAME.git]
# 再匹配 [http(s)://example.com/xyz/REPO_NAME]
# 查找结果存放在 BASH_REMATCH[2]
function clone_or_pull () {
    if [[ $1 =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $1 =~ ^(http.*\/)(.*)$ ]]; then
        local repo_name="${BASH_REMATCH[2]}"
        [[ -z "${repo_name}" ]] && { echo "[ERROR] 无法提取仓库名称: $1"; return 1; }

        echo "正在下载: ${repo_name}";
        set +e
            git clone --depth=1 --no-tags "$1" 2>/dev/null || git -C "${repo_name}" pull --ff-only 2>/dev/null;
            if [[ -f "${repo_name}/requirements.txt" ]]; then
                echo "正在安装: $repo_name 的相关依赖..."
                pip install -r "${repo_name}/requirements.txt" >/dev/null # 克隆仓库的同时安装对应依赖
            fi
            # 检查目录是否存在
            if [[ ! -d "${repo_name}" ]]; then
                echo "[ERROR] 仓库目录未创建: ${repo_name}";
                return 1;
            fi
            # 安装依赖和子模块（略）
        set -e
    else
        echo "[ERROR] 无效的 URL: $1";
        return 1;
    fi;
}


echo "########################################"
echo "[INFO] 下载 ComfyUI & Manager..."
echo "########################################"

# 使用稳定版 ComfyUI（GitHub 上有发布标签）
set +e
cd /root/autodl-tmp
git clone https://github.com/SurpassHR/ComfyUI-Playground.git ComfyUI 2>/dev/null || git -C ComfyUI pull --ff-only 2>/dev/null
cd /root/autodl-tmp/ComfyUI
latest_tag=$(git tag | grep -e '^v' | sort -V | tail -1)
if [[ -n "$latest_tag" ]]; then
    git reset --hard "$latest_tag"
    echo "已重置到标签: $latest_tag"
else
    echo "警告: 未找到以 'v' 开头的标签，保持当前提交。"
    # 可选：回退到默认分支（如 main/master）
    # git reset --hard origin/$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
fi
set -e

cd /root/autodl-tmp/ComfyUI/custom_nodes
clone_or_pull https://github.com/ltdrdata/ComfyUI-Manager.git

# 使用镜像站点替换 ComfyUI-Manager 默认仓库地址，避免卡 UI
# 治标不治本，使用 Manager 全部功能仍需挂代理或魔改
mkdir -p /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager

cat <<EOF > /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager/config.ini
[default]
channel_url = https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
EOF

cat <<EOF > /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager/channels.list
default::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
recent::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/new
legacy::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/legacy
forked::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/forked
dev::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/dev
tutorial::https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/tutorial
EOF

echo "########################################"
echo "[INFO] 下载扩展组件（自定义节点）……"
echo "########################################"

cd /root/autodl-tmp/ComfyUI/custom_nodes

# 工作空间
clone_or_pull https://github.com/crystian/ComfyUI-Crystools.git

# 综合
clone_or_pull https://github.com/kijai/ComfyUI-KJNodes.git
clone_or_pull https://github.com/rgthree/rgthree-comfy.git
clone_or_pull https://github.com/WASasquatch/was-node-suite-comfyui.git
clone_or_pull https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
clone_or_pull https://github.com/city96/ComfyUI-GGUF.git
clone_or_pull https://github.com/cubiq/ComfyUI_essentials.git
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere.git
clone_or_pull https://github.com/KohakuBlueleaf/PixelOE.git
clone_or_pull https://github.com/heshengtao/comfyui_LLM_party.git
clone_or_pull https://github.com/alexopus/ComfyUI-Image-Saver.git
clone_or_pull https://github.com/Extraltodeus/pre_cfg_comfy_nodes_for_ComfyUI.git
clone_or_pull https://github.com/yolain/ComfyUI-Easy-Use.git
clone_or_pull https://github.com/nkchocoai/ComfyUI-SaveImageWithMetaData.git
clone_or_pull https://github.com/weilin9999/WeiLin-Comfyui-Tools.git

# 控制
clone_or_pull https://github.com/cubiq/ComfyUI_IPAdapter_plus.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git
clone_or_pull https://github.com/Fannovel16/comfyui_controlnet_aux.git
clone_or_pull https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git

# 3D
clone_or_pull https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git

# 更多
clone_or_pull https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git
clone_or_pull https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git
clone_or_pull https://github.com/1038lab/ComfyUI-RMBG.git
clone_or_pull https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt.git
clone_or_pull https://github.com/weilin9999/WeiLin-Comfyui-Tools.git
clone_or_pull https://github.com/pamparamm/sd-perturbed-attention.git
clone_or_pull https://github.com/pollockjj/ComfyUI-MultiGPU.git
clone_or_pull https://github.com/huanngzh/ComfyUI-MVAdapter.git
clone_or_pull https://github.com/Acly/comfyui-tooling-nodes.git
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere.git
clone_or_pull https://github.com/mirabarukaso/ComfyUI_Mira.git
clone_or_pull https://github.com/KohakuBlueleaf/PixelOE.git
clone_or_pull https://github.com/chengzeyi/Comfy-WaveSpeed.git

pip \
    install \
    deepdiff \
    opencv-python \
    numba \
    gguf \
    openai \
    piexif \
    scikit-image \
    ultralytics \
    webcolors \
    matplotlib \
    trimesh \
    polygraphy \
    omegaconf \
    pynvml \
    aisuite \
    segment_anything \
    dill \
    diffusers \
    tensorrt \
    docstring_parser \
    accelerate \
    groundingdino-py \
    pymeshlab \
    onnxruntime \
    xatlas \
    beautifulsoup4 \
    langchain_community \
    langchain_openai

apt install ffmpeg

# 云服务器存储空间有限，清除 pip 的缓存
pip cache purge

echo "########################################"
echo "[INFO] 下载模型……"
echo "########################################"

cd /root/autodl-tmp/ComfyUI/models
# 增加 --continue=true 来避免重复下载
aria2c \
  --input-file=/root/autodl-tmp/ComfyUI/download_models.txt \
  --allow-overwrite=false \
  --auto-file-renaming=false \
  --continue=true \
  --max-connection-per-server=3 \
  --continue=true

# 标记为下载完成，下次启动不再尝试下载
# touch /root/autodl-tmp/.download-complete
