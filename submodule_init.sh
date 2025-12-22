# 1. 提取所有子模块的 URL 和 Path，并格式化为 "URL PATH" 的行
# 我们使用 git config 来解析，确保格式准确
submodules=$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read path_key module_path; do
    url_key=$(echo $path_key | sed 's/\.path$/.url/')
    url=$(git config -f .gitmodules --get "$url_key")
    echo "$url $module_path"
done)

# 2. 使用 xargs 并行克隆
# -n 2: 每次传递 2 个参数 (url 和 path) 给后面的 sh
# -P 8: 同时开启 8 个线程（你可以根据带宽调整这个数字）
echo "$submodules" | xargs -n 2 -P 8 sh -c '
    url=$0
    path=$1
    if [ ! -d "$path/.git" ]; then
        echo "正在克隆 [$path] ..."
        git clone --quiet "$url" "$path"
    else
        echo "跳过 [$path] (目录已存在)"
    fi
'

# 3. 修复 Git 索引 (Index)
# 这一步必须在克隆完成后执行，将所有子模块目录注册为 160000 模式
echo "正在将目录注册到 Git 索引..."
git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read path_key module_path; do
    if [ -d "$module_path/.git" ]; then
        git add "$module_path"
    fi
done

# 4. 最后同步配置并更新（确保状态一致性）
git submodule sync
git submodule update --init --recursive

echo "全部任务完成！"