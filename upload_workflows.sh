#!/bin/bash
project_root=$(git rev-parse --show-toplevel)
dot_submodule=$project_root/.gitmodules

submodule_name=$(awk '/workflows/ {match($0,/submodule "(.*)"/,arr); print arr[1]; exit}' $dot_submodule)
submodule_path=$(awk '/workflows/ && /path = / {match($0,/path = (.*)/,arr); print arr[1]; exit}' $dot_submodule)
submodule_url=$(awk '/workflows/ && /url = / {match($0,/url = (.*)/,arr); print arr[1]; exit}' $dot_submodule)

cd $project_root/$submodule_path
change_file_count=$(git status --porcelain | wc -l)

if [ $change_file_count -gt 0 ]; then
    git add . && git commit -m "update: workflows" && git push origin HEAD:master
fi