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
cp -f "${script_dir}/zsh_config/.zshrc" "/home/${user_name}/.zshrc"
chown "${user_name}:${user_name}" "/home/${user_name}/.zshrc"
chmod 600 "/home/${user_name}/.zshrc"

mkdir -p "${script_dir}/build"

cd "${script_dir}/build"
git clone https://github.com/ar18-linux/libstderred.git
chmod +x "${script_dir}/build/libstderred/install.sh"
"${script_dir}/build/libstderred/install.sh"

cd "${script_dir}/build"
git clone https://github.com/ar18-linux/zsh_ar18_lib.git
chmod +x "${script_dir}/build/zsh_ar18_lib/install.sh"
"${script_dir}/build/zsh_ar18_lib/install.sh"
