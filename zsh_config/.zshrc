# TODO
# Set title
# error_to_str
# Show runtime of finished command
# Show device path is on

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

## Things to monitor
# Uptime
# Connectivity
# CPU usage
# Network usage
# RAM usage
# Free space on root partition
# Root I/O
# SWAP used
# Current date and time

## Things for the prompt
# Last command
# Last exit code
# Last command error_to_string
# Last command finish date and time
# Last command execution time
# $PWD
# Disk space available on $PWD device
# Underlying device the path is on

# Override default config file in Debian so history search puts cursor at the end, not the front.
# Somehow wrecks history sensitive search.
# Cursor is put at the start of the line because Debian sources /etc/zsh/zshrc.
# The culprit in there is in function zle-line-init (ll 74-77)
#echo 'unsetopt global_rcs' > ~/.zprofile
#echo " " > ~/.zprofile

if [[ ! -o interactive ]]; then
  echo $$ > /tmp/non-interactive
  exit
fi

export AR18_PREFIX="$(cat /opt/ar18/ar18_prefix)"

#mkdir -p "/dev/shm/ar18/tmp"
# Delete all in /dev/shm/ar18 except /tmp and /stderrred.
find "/dev/shm/ar18/../"* -mindepth 1 -maxdepth 1 -type d -not -name tmp -not -name libstderrred -exec rm -r {} +;
mkdir -p "/dev/shm/ar18"
#rsync -rL "${AR18_PREFIX}/tmux" "/dev/shm/ar18/"
rsync -rL "${AR18_PREFIX}/ar18_lib_zsh" "/dev/shm/ar18/"
#rsync -rL "${AR18_PREFIX}/background" "/dev/shm/ar18/"
rsync -rL "${AR18_PREFIX}/libstderred" "/dev/shm/ar18/"
rsync -rL "${AR18_PREFIX}/GitBSLR" "/dev/shm/ar18/"

export AR18_PREFIX="/dev/shm/ar18"
#export AR18_PREFIX="/opt/ar18"
chmod 755 "${AR18_PREFIX}" -R

# Debugging ar18lib. Re-source functions even when already defined.
alias type="false"
. ${AR18_PREFIX}/ar18_lib_zsh/ar18.sh

## Attach to last tmux session or start it if there a no sessions yet.
#if [ "$TMUX" = "" ]; then tmux attach || tmux; fi

# Create fbterm environment in case we are in the linux console.
fbterm 2>/dev/null

pid="$$"

tmp_dir="${AR18_PREFIX}/tmp"
mkdir -p "${tmp_dir}/${pid}"

echo "$(date +%s)" > "${tmp_dir}/${pid}/shell_start_time"

set -u
#set -o pipefail
#set -e

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. "_" and "-" will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Reevaluate prompt every time.
setopt prompt_subst

# Wildcard expansion for autocomplete
setopt GLOB_COMPLETE

SAVEHIST=1000000
HISTFILE=~/.zsh_history
export HISTTIMEFORMAT="[%F %T] "
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

# Show dot files in autocomplete.
setopt globdots

zmodload zsh/complist

# Keyboard shortcuts - Use Ctrl + v in a terminal to get keycodes needed here
if [ "${TERM}" = "linux" ]; then
  # Load key binding for linux console to make it more like terminal emulator
  loadkeys /opt/ar18/zsh_config/wordnav.keys 2>/dev/null
  # Movement
    # Go back and forth whole words
      # debian console
      # arch console
      bindkey '^[b' path-backward-word
      bindkey '^[f' path-forward-word
    # Go at end and beginning of line
      # debian console
      # arch console
      bindkey "^[[1~" beginning-of-line
      bindkey "^[[4~" end-of-line

  # Deletion
    # Delete whole words
      # debian console
      # arch console
      bindkey '^[d' backward-kill-dir
      bindkey "^[[3~" kill-word
  # History
    # Search history with cursor
      # debian console
      # arch console
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward
  # Auto-completion
    # Shift + tab to go back in selection
      # arch/debian console
      bindkey -M menuselect '^[[Z' reverse-menu-complete
else
  # Movement
    # Go back and forth whole words
      # xfce4-terminal
      bindkey '^[[1;5D' path-backward-word
      bindkey '^[[1;5C' path-forward-word
    # Go at end and beginning of line
      # xfce4-terminal
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

  # Deletion
    # Delete whole words
      # xfce4-terminal
      bindkey "^H" backward-kill-dir
      bindkey "^[[4~" end-of-line
      bindkey "^[[3;5~" kill-word
  # History
    # Search history with cursor
      # xfce4 terminal
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward
  # Auto-completion
    # Shift + tab to go back in selection
      # xfce4 terminal
      bindkey -M menuselect '^[[Z' reverse-menu-complete
fi

# Backwards kill a whole word or until a forward slash or standard word delimiter
backward-kill-dir () {
  local WORDCHARS=${WORDCHARS/\/}
  local WORDCHARS=${WORDCHARS//=}
  local WORDCHARS=${WORDCHARS//.}
  local WORDCHARS=${WORDCHARS//-}
  local WORDCHARS=${WORDCHARS//_}
  zle backward-kill-word
}
zle -N backward-kill-dir

# Move word-wise forward considering path tokens as words
path-forward-word () {
  local WORDCHARS=${WORDCHARS/\/}
  local WORDCHARS=${WORDCHARS//=}
  local WORDCHARS=${WORDCHARS//.}
  local WORDCHARS=${WORDCHARS//-}
  local WORDCHARS=${WORDCHARS//_}
  zle emacs-forward-word
}
zle -N path-forward-word

# Move word-wise backward considering path tokens as words
path-backward-word () {
  local WORDCHARS=${WORDCHARS/\/}
  local WORDCHARS=${WORDCHARS//=}
  local WORDCHARS=${WORDCHARS//.}
  local WORDCHARS=${WORDCHARS//-}
  local WORDCHARS=${WORDCHARS//_}
  zle emacs-backward-word
}
zle -N path-backward-word

# Errors in bold red
# The zsh approach does not work with a call to bash,i.e. there will be no prompt.
#autoload colors && colors
#exec 2>>( sed -u "s/^/${fg_bold[red]}/; s/\$/${reset_color}/" )
# The libstderred approach does not work when executing a python script, instead of executing the script an interactive python shell is started. Workaround: set LD_PRELOAD to empty before the call 
if [[ ! -v LD_PRELOAD ]]; then
 export LD_PRELOAD="${AR18_PREFIX}/libstderred/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"
 bold=$(tput bold || tput md)
 red=$(tput setaf 1)
 export STDERRED_ESC_CODE=`echo -e "$bold$red"`
 export STDERRED_BLACKLIST="^(bash|test.*)$"
fi

function get_prompt_last_command_returned(){
  if [ -f "${tmp_dir}/${pid}/last_command" ]; then
    last_command="$(cat "${tmp_dir}/${pid}/last_command")"
    if [[ "${last_command}" != "" ]]; then
      printf '\n%s' "[$(get_prompt_command_time)] Command [$(get_prompt_last_command)] returned [$(get_prompt_last_code)] [e2s]"
    fi
  fi
}


function get_prompt_last_command(){
  if [ -f "${tmp_dir}/${pid}/last_command" ]; then
    last_command="$(cat "${tmp_dir}/${pid}/last_command")"
    printf '%s' "${last_command}"
  fi
}


function get_prompt_host(){
  set +u
  local my_session_type="foo"
  local my_ssh_client="${SSH_CLIENT}" || true
  local my_ssh_tty="${SSH_TTY}" || true
  if [[ "${my_ssh_client}" != "" ]] || [[ "${my_ssh_tty}" != "" ]]; then
    my_session_type=remote/ssh
  # many other tests omitted
  else
    case $(ps -o comm= -p $PPID) in
  	sshd|*/sshd) my_session_type=remote/ssh;;
    esac
  fi
  set -u

  if [[ "${my_session_type}" == "remote/ssh" ]]; then
    local host="%B%F{red}%M%f%b"
  else
    local host="%B%F{green}%M%f%b"
  fi
  printf '%s' "${host}"
}


function get_prompt_disk_usage(){
  local disk_usage="$(df "$(readlink -f $PWD)" | sed -n 2p | tr -s " " | cut -d ' ' -f 5)"
  local disk_usage=$(sed 's|%|%%|g' <<< ${disk_usage})
  printf '%s' "${disk_usage}"
}


function get_prompt_command_time(){
  local start_time="$(date +%s)"
  local command_time="$(cat "${tmp_dir}/${pid}/last_command_start_time")"
  if [[ "${command_time}" != "" ]]; then
    printf '%s' "$((start_time - command_time))"
  else
    printf '%s' "NA"
  fi
}


function get_prompt_last_code(){
  local last_code="%B%(?.%F{green}.%F{red})%?%f%b"
  printf '%s' "${last_code}"
}


function get_prompt_date_time(){
  if [ -f "${tmp_dir}/${pid}/last_command" ]; then
    last_command="$(cat "${tmp_dir}/${pid}/last_command")"
    if [[ "${last_command}" != "" ]]; then
      printf '\n%s' "[%D %D{%L:%M:%S}]"
    else
      printf '%s' "[%D %D{%H:%M:%S}]"
    fi
  else
    printf '%s' "[%D %D{%H:%M:%S}]"
  fi
}


function get_prompt_battery_charge {
  # Battery 0: Discharging, 94%, 03:46:34 remaining
  bat_percent=$(acpi | awk -F ':' {'print $2;'} | awk -F ',' {'print $2;'} | sed -e "s/\s//" -e "s/%.*//")

  if [ $bat_percent -lt 20 ]; then cl='%F{red}'
  elif [ $bat_percent -lt 50 ]; then cl='%F{yellow}'
  else cl='%F{green}'
  fi

  filled=${(l:`expr $bat_percent / 10`::▸:)}
  empty=${(l:`expr 10 - $bat_percent / 10`::▹:)}
  printf '%s' $cl$filled$empty'%F{default}'
}


function get_prompt_internet_connectivity(){
  return
  connected="$(cat "${tmp_dir}/connectivity")"
  if [[ "${connected}" == "1" ]]; then
    printf '%s' '[%F{green}\U2713%F{default}]'
  elif [[ "${connected}" == "0" ]]; then
    printf '%s' '[%F{red}\u2717%F{default}]'
  else
    printf '%s' '[%F{purple}?%F{default}]'
  fi
}


## Prompt.
export PROMPT=$'$(get_prompt_last_command_returned)$(get_prompt_date_time) $(get_prompt_internet_connectivity) %n@$(get_prompt_host)\n%/ [$(get_prompt_disk_usage)]\n%#'
#export PROMPT=$'\n'"[%D %T] $(get_prompt_last_code) %n@$(get_prompt_host)"$'\n'"%/ [$(get_prompt_disk_usage)]"$'\n'"%#"

export PATH=$PATH:.

#function precmd2(){
#  clear
#  return
#  LEFT="The time is"
# RIGHT="$(date) "
#  RIGHTWIDTH=$(($COLUMNS-${#LEFT}))
#  print $LEFT${(l:$RIGHTWIDTH::.:)RIGHT}
#}

## Right prompt.
# Right prompt ends exactly at right edge.
#ZLE_RPROMPT_INDENT=0
# Right prompt syntax.
#RPROMPT='[%D{%L:%M:%S %p}]'

# Update prompt every TMOUT seconds. View is scrolled down in this event though.
# Selected text is unselected at refresh. These things don't happen with terminator terminal emulator.
# Or set "scroll on output" to false.
#TRAPALRM(){
  # Debug: Get value of $WIDGET if it doesn't work and add it to condition.
  # echo "foo: $WIDGET"
  # Only reset prompt when not tab-selecting items.
  #if [ "$WIDGET" != "expand-or-complete" ]; then
    #zle reset-prompt
  #fi
#}
#TMOUT=1

alias t="tmux attach || tmux"
alias ls="ls --color"
alias ll="ls -la --color"
alias lc="sudo cryptsetup luksClose "
alias lo="sudo cryptsetup luksOpen "
alias um="sudo umount "
alias m="sudo mount "
alias ai="sudo apt install "
alias au="sudo apt remove --autoremove "
alias h="history 1"
alias sh="ssh pi@arserver-0.spdns.org -p2222"
alias cd..="cd .."
alias z="hstr"
alias r=". ~/.zshrc"
alias ar18git="git clone http://github.com/ar18-linux"
alias sysst="LD_PRELOAD= sudo systemctl start"
alias sysss="LD_PRELOAD= systemctl status"
alias syssp="LD_PRELOAD= sudo systemctl stop"
alias sysr="LD_PRELOAD= sudo systemctl restart"
alias git="LD_PRELOAD=/opt/ar18/GitBSLR/gitbslr.so git"
# Programs that don't work well with libstderred
alias systemctl="LD_PRELOAD='' systemctl"
alias python="LD_PRELOAD='' python"
alias bash="LD_PRELOAD='' bash"
alias xonsh="LD_PRELOAD='' xonsh"
alias makepkg="LD_PRELOAD='' makepkg"
alias pip3="LD_PRELOAD='' pip3"
alias nmcli="LD_PRELOAD= nmcli"

## Preexec command. 
#function preexec2(){
#  echo "foo: $1"
#  start_time="$(date +%s)"
#  sed -i "s/^last_command_start_time=.+$//g" "${tmp_dir}/${pid}"
#  echo "last_command_start_time=${start_time}" >> "${tmp_dir}/${pid}"
#}

## Exit trap.
function on_exit(){
  # Detach from tmux on exit automatically.
  #tmux detach
  rm -rf "${tmp_dir}/${pid}"
}

trap 'on_exit' EXIT

## Custom accept-line widget.
my-accept-line(){
  start_time="$(date +%s)"
  echo "last_command_start_time=${start_time}" > "${tmp_dir}/${pid}/last_command_start_time"

  #cat "${tmp_dir}/${pid}" | grep last_command_start_time | cut -d '=' -f 2-
  # Kindly ...
  if [[ "${BUFFER}" == *" please" ]]; then
    BUFFER="sudo ${BUFFER% please}"
  fi
  echo "${BUFFER}" > "${tmp_dir}/${pid}/last_command"
  clear
  zle .accept-line
}
zle -N accept-line my-accept-line

# Autocomplete lower case to upper case to match results.
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# Highlight selection when tabbing through possible entries.
zstyle ':completion:*' menu select
