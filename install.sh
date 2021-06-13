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

set -x

. "${script_dir}/vars"
if [ ! -v ar18_helper_functions ]; then rm -rf "/tmp/helper_functions_$(whoami)"; cd /tmp; git clone https://github.com/ar18-linux/helper_functions.git; mv "/tmp/helper_functions" "/tmp/helper_functions_$(whoami)"; . "/tmp/helper_functions_$(whoami)/helper_functions/helper_functions.sh"; cd "${script_dir}"; export ar18_helper_functions=1; fi
obtain_sudo_password

mkdir -p "${install_dir}/${module_name}"
cp -f "${script_dir}/zsh_config/.zshrc" "/home/${user_name}/.zshrc"
echo "${ar18_sudo_password}" | sudo -Sk chown "${user_name}:${user_name}" "/home/${user_name}/.zshrc"
echo "${ar18_sudo_password}" | sudo -Sk chmod 600 "/home/${user_name}/.zshrc"

echo "${ar18_sudo_password}" | sudo -Sk cp -f "${script_dir}/zsh_config/wordnav.keys" "${install_dir}/${module_name}/wordnav.keys"
echo "${ar18_sudo_password}" | sudo -Sk chown "root:${user_name}" "${install_dir}/${module_name}/wordnav.keys"
echo "${ar18_sudo_password}" | sudo -Sk chmod 4750 "${install_dir}/${module_name}/wordnav.keys"

echo "${ar18_sudo_password}" | sudo -Sk su -c "echo \"${install_dir}\" > \"${install_dir}/ar18_prefix\""

mkdir -p "${script_dir}/build"

cd "${script_dir}/build"
git clone https://github.com/ar18-linux/libstderred.git
echo "${ar18_sudo_password}" | sudo -Sk chmod +x "${script_dir}/build/libstderred/install.sh"
"${script_dir}/build/libstderred/install.sh"

cd "${script_dir}/build"
git clone https://github.com/ar18-linux/zsh_ar18_lib.git
echo "${ar18_sudo_password}" | sudo -Sk chmod +x "${script_dir}/build/zsh_ar18_lib/install.sh"
"${script_dir}/build/zsh_ar18_lib/install.sh"

cd "${script_dir}/build"
git clone https://github.com/ar18-linux/GitBSLR.git
echo "${ar18_sudo_password}" | sudo -Sk chmod +x "${script_dir}/build/GitBSLR/install.sh"
"${script_dir}/build/GitBSLR/install.sh"

echo "${ar18_sudo_password}" | sudo -Sk usermod --shell /bin/zsh "${user_name}"

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
