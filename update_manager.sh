#!/bin/bash
cd custom_nodes/ComfyUI-Manager || exit 1
git stash && git pull --ff-only && git stash pop || true
cd -