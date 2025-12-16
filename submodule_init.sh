#!/bin/bash
# 初始化并更新所有子模块（基于 .gitmodules）

if [ ! -f ".gitmodules" ]; then
  echo "未找到 .gitmodules 文件，请在仓库根目录运行此脚本。"
  exit 1
fi

# 遍历所有子模块路径
git config --file .gitmodules --get-regexp "submodule\..*\.path" | while read path_key path; do
    name=$(echo "$path_key" | sed 's/submodule\.\(.*\)\.path/\1/')
    url=$(git config --file .gitmodules submodule."$name".url)

    echo "初始化子模块: $name"
    echo "  路径: $path"
    echo "  URL : $url"

    # 只需要 init，不要 add
    git submodule init "$path"
done

# 更新所有子模块
git submodule update --recursive
