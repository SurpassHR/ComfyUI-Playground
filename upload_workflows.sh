#!/bin/bash

# 1. 获取项目根目录
project_root=$(git rev-parse --show-toplevel)
if [ -z "$project_root" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

# 2. 获取 Submodule 路径
# 使用 git config 解析，查找路径中包含 "workflows" 的子模块
submodule_path=$(git config --file "$project_root/.gitmodules" --get-regexp path | grep "workflows" | awk '{print $2}' | head -n 1)

if [ -z "$submodule_path" ]; then
    echo "Error: Could not find a submodule matching 'workflows'."
    exit 1
fi

echo "Found submodule at: $submodule_path"

# 3. 进入目录 (增加 || exit 1 防止目录不存在时仍在根目录执行操作)
cd "$project_root/$submodule_path" || exit 1

# 4. 检查变更并提交
# -n 表示字符串非空 (即有变更)
if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected, committing..."

    git add .
    git commit -m "update: workflows"

    # 推送到远程 master 分支
    echo "Pushing to origin master..."
    git push origin HEAD:master
else
    echo "No changes detected."
fi