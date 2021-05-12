#!/bin/bash

set -e
set -x

if [[ "$(whoami)" != "root" ]]; then
  read -p "[ERROR] must be root!"
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

. "${script_dir}/vars"

if [ ! -d "${install_dir}" ]; then
  mkdir -p "${install_dir}"
fi

mkdir -p "${install_dir}"
cp -f "${script_dir}/zsh_config/.zshrc" "${install_dir}/.zshrc"
chown "$(logname):$(logname)" "${install_dir}/.zshrc"
chmod 600 "${install_dir}/.zshrc"

mkdir "${script_dir}/build"
cd "${script_dir}/build"
git clone https://github.com/ar18-linux/libstderred.git
"${script_dir}/build/libstderred/install.sh"
