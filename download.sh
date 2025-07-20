#!/bin/bash

set -euo pipefail

# 下载（clone）自定义节点，如已存在，则更新（pull），额外处理含有子模块的节点
# 其中，正则表达式内容为：从链接中查找仓库名称 REPO_NAME
# 先匹配 [https://example.com/xyz/REPO_NAME.git] 或 [git@example.com:xyz/REPO_NAME.git]
# 再匹配 [http(s)://example.com/xyz/REPO_NAME]
# 查找结果存放在 BASH_REMATCH[2]
function clone_or_pull () {
    if [[ $1 =~ ^(.*[/:])(.*)(\.git)$ ]] || [[ $1 =~ ^(http.*\/)(.*)$ ]]; then
        echo "正在下载： ${BASH_REMATCH[2]}" ;
        set +e ;
            git clone --depth=1 --no-tags "$1" || git -C "${BASH_REMATCH[2]}" pull --ff-only ;

            if [ -f "${BASH_REMATCH[2]}/.gitmodules" ] ; then
                echo "正在下载 ${BASH_REMATCH[2]} 的子模块..." ;
                sed -i.bak 's|url = https://github.com/|url = https://github.com/|' "${BASH_REMATCH[2]}/.gitmodules" ;
                git -C "${BASH_REMATCH[2]}" submodule update --init --recursive ;
            fi ;
        set -e ;
    else
        echo "[ERROR] 无效的 URL: $1" ;
        return 1 ;
    fi ;
}


echo "########################################"
echo "[INFO] 下载 ComfyUI & Manager..."
echo "########################################"

# 使用稳定版 ComfyUI（GitHub 上有发布标签）
set +e
cd /root/autodl-tmp
git clone https://github.com/SurpassHR/ComfyUI-Playground.git ComfyUI || git -C ComfyUI pull --ff-only
cd /root/autodl-tmp/ComfyUI
git reset --hard "$(git tag | grep -e '^v' | sort -V | tail -1)"
set -e

cd /root/autodl-tmp/ComfyUI/custom_nodes
clone_or_pull https://github.com/ltdrdata/ComfyUI-Manager.git

# 使用镜像站点替换 ComfyUI-Manager 默认仓库地址，避免卡 UI
# 治标不治本，使用 Manager 全部功能仍需挂代理或魔改
mkdir -p /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager

cat <<EOF > /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager/config.ini
[default]
channel_url = https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
EOF

cat <<EOF > /root/autodl-tmp/ComfyUI/user/default/ComfyUI-Manager/channels.list
default::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
recent::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/new
legacy::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/legacy
forked::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/forked
dev::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/dev
tutorial::https://gh-proxy.com/https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/node_db/tutorial
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
clone_or_pull https://github.com/pythongosssss/ComfyUI-Custom-Scripts
clone_or_pull https://github.com/city96/ComfyUI-GGUF
clone_or_pull https://github.com/cubiq/ComfyUI_essentials
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere
clone_or_pull https://github.com/KohakuBlueleaf/PixelOE
clone_or_pull https://github.com/heshengtao/comfyui_LLM_party
clone_or_pull https://github.com/alexopus/ComfyUI-Image-Saver
clone_or_pull https://github.com/Extraltodeus/pre_cfg_comfy_nodes_for_ComfyUI

# 控制
clone_or_pull https://github.com/cubiq/ComfyUI_IPAdapter_plus.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git
clone_or_pull https://github.com/ltdrdata/ComfyUI-Inspire-Pack
clone_or_pull https://github.com/Fannovel16/comfyui_controlnet_aux.git
clone_or_pull https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet

# 3D
clone_or_pull https://github.com/kijai/ComfyUI-Hunyuan3DWrapper

# 更多
clone_or_pull https://github.com/pythongosssss/ComfyUI-WD14-Tagger.git
clone_or_pull https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git
clone_or_pull https://github.com/1038lab/ComfyUI-RMBG
clone_or_pull https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt
clone_or_pull https://github.com/weilin9999/WeiLin-Comfyui-Tools
clone_or_pull https://github.com/pamparamm/sd-perturbed-attention
clone_or_pull https://github.com/pollockjj/ComfyUI-MultiGPU
clone_or_pull https://github.com/huanngzh/ComfyUI-MVAdapter
clone_or_pull https://github.com/Acly/comfyui-tooling-nodes
clone_or_pull https://github.com/chrisgoringe/cg-use-everywhere
clone_or_pull https://github.com/mirabarukaso/ComfyUI_Mira
clone_or_pull https://github.com/KohakuBlueleaf/PixelOE
clone_or_pull https://github.com/chengzeyi/Comfy-WaveSpeed

echo "########################################"
echo "[INFO] 下载模型……"
echo "########################################"

cd /root/autodl-tmp/ComfyUI/models
aria2c \
  --input-file=/runner-scripts/download-models.txt \
  --allow-overwrite=false \
  --auto-file-renaming=false \
  --continue=true \
  --max-connection-per-server=3

# 标记为下载完成，下次启动不再尝试下载
# touch /root/autodl-tmp/.download-complete
