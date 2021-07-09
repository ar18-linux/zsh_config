#!/bin/bash
# ar18

# Script template version 2021-06-12.03
# Make sure some modification to LD_PRELOAD will not alter the result or outcome in any way
LD_PRELOAD_old="${LD_PRELOAD}"
LD_PRELOAD=
# Determine the full path of the directory this script is in
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
script_path="${script_dir}/$(basename "${0}")"
#Set PS4 for easier debugging
export PS4='\e[35m${BASH_SOURCE[0]}:${LINENO}: \e[39m'
# Determine if this script was sourced or is the parent script
if [ ! -v ar18_sourced_map ]; then
  declare -A -g ar18_sourced_map
fi
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  ar18_sourced_map["${script_path}"]=1
else
  ar18_sourced_map["${script_path}"]=0
fi
# Initialise exit code
if [ -z "${ar18_exit_map+x}" ]; then
  declare -A -g ar18_exit_map
fi
ar18_exit_map["${script_path}"]=0
# Get old shell option values to restore later
shopt -s inherit_errexit
IFS=$'\n' shell_options=($(shopt -op))
# Set shell options for this script
set -o pipefail
set -eu
#################################SCRIPT_START##################################

ar18.script.import ar18.script.install
ar18.script.import ar18.script.obtain_sudo_password
ar18.script.import ar18.script.execute_with_sudo

. "${script_dir}/vars"

ar18.script.obtain_sudo_password

ar18.script.execute_with_sudo mkdir -p "${install_dir}/${module_name}"
cp -f "${script_dir}/zsh_config/.zshrc" "/home/${user_name}/.zshrc"
ar18.script.execute_with_sudo chown "${user_name}:${user_name}" "/home/${user_name}/.zshrc"
ar18.script.execute_with_sudo chmod 600 "/home/${user_name}/.zshrc"

ar18.script.execute_with_sudo cp -f "${script_dir}/zsh_config/wordnav.keys" "${install_dir}/${module_name}/wordnav.keys"
ar18.script.execute_with_sudo chown "root:${user_name}" "${install_dir}/${module_name}/wordnav.keys"
ar18.script.execute_with_sudo chmod 4750 "${install_dir}/${module_name}/wordnav.keys"

ar18.script.execute_with_sudo su -c "echo \"${install_dir}\" > \"${install_dir}/ar18_prefix\""

build_dir="/tmp/build"

ar18.script.execute_with_sudo rm -rf !${build_dir}

mkdir -p "${build_dir}"

cd "${build_dir}"
git clone https://github.com/ar18-linux/libstderred.git
ar18.script.execute_with_sudo chmod +x "${build_dir}/libstderred/install.sh"
"${build_dir}/libstderred/install.sh"

cd "${build_dir}"
git clone https://github.com/ar18-linux/zsh_ar18_lib.git
ar18.script.execute_with_sudo chmod +x "${build_dir}/zsh_ar18_lib/install.sh"
"${script_dir}/build/zsh_ar18_lib/install.sh"

cd "${build_dir}"
git clone https://github.com/ar18-linux/GitBSLR.git
ar18.script.execute_with_sudo chmod +x "${build_dir}/GitBSLR/install.sh"
"${script_dir}/build/GitBSLR/install.sh"

ar18.script.execute_with_sudo usermod --shell /bin/zsh "${user_name}"

##################################SCRIPT_END###################################
# Restore old shell values
set +x
for option in "${shell_options[@]}"; do
  eval "${option}"
done
# Restore LD_PRELOAD
LD_PRELOAD="${LD_PRELOAD_old}"
# Return or exit depending on whether the script was sourced or not
if [ "${ar18_sourced_map["${script_path}"]}" = "1" ]; then
  return "${ar18_exit_map["${script_path}"]}"
else
  exit "${ar18_exit_map["${script_path}"]}"
fi
