#!/bin/bash
set -e
here="$(cd "$(dirname "$0")" && pwd)"
target="/mnt/c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/GoofyAhhForever"
mkdir -p "$target/Sounds"
cp "$here"/*.lua "$here"/*.toc "$here"/*.xml "$target/"
cp "$here/Sounds/"* "$target/Sounds/" 2>/dev/null || true
echo "Copiado a $target"
