#!/bin/bash

# 1. 获取项目根目录
project_root=$(git rev-parse --show-toplevel)
if [ -z "$project_root" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

# 2. 获取 Submodule 路径
# 使用 git config 解析 .gitmodules 文件
# --get-regexp path 查找所有 submodule 的 path 配置
# grep "workflows" 筛选包含 workflows 的行
# awk '{print $2}' 提取路径部分
submodule_path=$(git config --file "$project_root/.gitmodules" --get-regexp path | grep "workflows" | awk '{print $2}' | head -n 1)

if [ -z "$submodule_path" ]; then
    echo "Error: Could not find a submodule matching 'workflows'."
    exit 1
fi

echo "Found submodule at: $submodule_path"
cd "$project_root/$submodule_path" || exit

# 3. 检查是否有未提交的更改 (Stash 逻辑)
# git status --porcelain 是一种更标准的检查方式
if [ -n "$(git status --porcelain)" ]; then
    echo "Changes detected, stashing..."
    git add .
    git stash
    need_pop=true
else
    need_pop=false
fi

# 4. 执行 Pull
echo "Pulling updates..."
git pull --ff-only

# 5. 恢复 Stash
if [ "$need_pop" = true ]; then
    echo "Popping stash..."
    git stash pop
fi
