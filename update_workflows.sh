#!/bin/bash
project_root=$(git rev-parse --show-toplevel)
dot_submodule=$project_root/.gitmodules

submodule_name=$(awk '/workflows/ {match($0,/submodule "(.*)"/,arr); print arr[1]; exit}' $dot_submodule)
submodule_path=$(awk '/workflows/ && /path = / {match($0,/path = (.*)/,arr); print arr[1]; exit}' $dot_submodule)
submodule_url=$(awk '/workflows/ && /url = / {match($0,/url = (.*)/,arr); print arr[1]; exit}' $dot_submodule)

cd $project_root/$submodule_path
stash_count=$(git stash list | wc -l)

change_file_count=$(git status --porcelain | wc -l)
if [ $change_file_count -gt 0 ]; then
    stash_prompt="git add . && git stash &&"
    unstash_prompt="&& git stash pop"
fi

git_prompt="$stash_prompt git pull --ff-only $unstash_prompt"
eval $git_prompt