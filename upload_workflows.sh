#!/bin/bash

# 1. 获取项目根目录
project_root=$(git rev-parse --show-toplevel)
if [ -z "$project_root" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

# 2. workflows 目录固定在这里（原先从 .gitmodules 解析）
submodule_path="user/default/workflows"

if [ ! -d "$project_root/$submodule_path" ]; then
    echo "Error: workflows directory not found: $submodule_path"
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
