#!/usr/bin/env bash
# install.sh - Install or uninstall mysql-utils symlinks and bash completion
set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

declare -r VERSION=1.0.0
declare -r SCRIPT_NAME=${0##*/}
declare -r SCRIPT_DIR=$(cd -- "${0%/*}" && pwd -P)

declare -r BIN_DIR=/usr/local/bin
declare -r COMPLETION_DIR=/etc/bash_completion.d
declare -r COMPLETION_NAME=mysql-utils
declare -r SYMLINK_FILE="$SCRIPT_DIR/.symlink"

declare -- ACTION=install
declare -i DRY_RUN=0

# Messaging functions
_msg() {
  local -- prefix="$SCRIPT_NAME:" msg
  case ${FUNCNAME[1]} in
    info)  prefix+=" ◉" ;;
    warn)  prefix+=" ▲" ;;
    error) prefix+=" ✗" ;;
  esac
  for msg in "$@"; do printf '%s %s\n' "$prefix" "$msg"; done
}

info() { >&2 _msg "$@"; }
warn() { >&2 _msg "$@"; }
error() { >&2 _msg "$@"; }
die() { (($# < 2)) || error "${@:2}"; exit "${1:-0}"; }

show_help() {
  cat <<HELP
Usage: $SCRIPT_NAME [OPTIONS] [ACTION]

Install or uninstall mysql-utils symlinks and bash completion.

ACTIONS:
  install     Create symlinks and install completion (default)
  uninstall   Remove symlinks and completion file

OPTIONS:
  -n, --dry-run   Show what would be done without making changes
  -h, --help      Display this help message
  -V, --version   Display version information

EXAMPLES:
  sudo $SCRIPT_NAME              Install mysql-utils
  sudo $SCRIPT_NAME -n           Dry run — show what would be done
  sudo $SCRIPT_NAME uninstall    Remove mysql-utils installation
HELP
}

while (($#)); do
  case $1 in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)    show_help; exit 0 ;;
    -V|--version) echo "$SCRIPT_NAME $VERSION"; exit 0 ;;
    -[nhV]?*)     set -- "${1:0:2}" "-${1:2}" "${@:2}"; continue ;;
    -*)           die 22 "Invalid option ${1@Q} (use --help)" ;;
    install)      ACTION=install ;;
    uninstall)    ACTION=uninstall ;;
    *)            die 22 "Unknown action ${1@Q} (use install or uninstall)" ;;
  esac
  shift
done

# Read .symlink file, return script entries (excluding completion files)
read_symlink_file() {
  [[ -f $SYMLINK_FILE ]] || die 2 "Missing .symlink file: $SYMLINK_FILE"
  local -- line
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -n $line ]] || continue
    [[ $line != *.bash_completion ]] || continue
    echo "$line"
  done < "$SYMLINK_FILE"
}

do_install() {
  local -- name target source
  local -i count=0

  info "Installing mysql-utils from $SCRIPT_DIR"
  ((! DRY_RUN)) || info "(dry run)"

  # Install script symlinks
  while IFS= read -r name; do
    source="$SCRIPT_DIR/$name"
    target="$BIN_DIR/$name"

    if [[ ! -f $source ]]; then
      warn "Source not found, skipping: $source"
      continue
    fi

    if [[ -L $target ]]; then
      local -- existing
      existing=$(readlink -f -- "$target" 2>/dev/null) || true
      if [[ $existing == "$source" ]]; then
        info "Already installed: $name"
        continue
      fi
      warn "Symlink exists but points elsewhere: $target -> $(readlink -- "$target")"
      warn "Updating to: $source"
      ((DRY_RUN)) || ln -sfn -- "$source" "$target"
    elif [[ -e $target ]]; then
      warn "File exists and is not a symlink: $target (skipping)"
      continue
    else
      info "Linking: $target -> $source"
      ((DRY_RUN)) || ln -s -- "$source" "$target"
    fi
    ((++count))
  done <<< "$(read_symlink_file)"

  # Install bash completion
  local -- comp_source="$SCRIPT_DIR/mysql-utils.bash_completion"
  local -- comp_target="$COMPLETION_DIR/$COMPLETION_NAME"

  if [[ -f $comp_source ]]; then
    info "Installing completion: $comp_target"
    ((DRY_RUN)) || cp -- "$comp_source" "$comp_target"
    ((++count))
  else
    warn "Completion file not found: $comp_source"
  fi

  info "Done ($count items installed)"
}

do_uninstall() {
  local -- name target source
  local -i count=0

  info "Uninstalling mysql-utils"
  ((! DRY_RUN)) || info "(dry run)"

  # Remove script symlinks
  while IFS= read -r name; do
    target="$BIN_DIR/$name"

    if [[ -L $target ]]; then
      local -- existing
      existing=$(readlink -f -- "$target" 2>/dev/null) || true
      if [[ $existing == "$SCRIPT_DIR/$name" ]]; then
        info "Removing: $target"
        ((DRY_RUN)) || rm -- "$target"
        ((++count))
      else
        warn "Symlink does not point to us, skipping: $target -> $(readlink -- "$target")"
      fi
    elif [[ -e $target ]]; then
      warn "Not a symlink, skipping: $target"
    fi
  done <<< "$(read_symlink_file)"

  # Remove bash completion
  local -- comp_target="$COMPLETION_DIR/$COMPLETION_NAME"
  if [[ -f $comp_target ]]; then
    info "Removing completion: $comp_target"
    ((DRY_RUN)) || rm -- "$comp_target"
    ((++count))
  fi

  info "Done ($count items removed)"
}

case $ACTION in
  install)   do_install ;;
  uninstall) do_uninstall ;;
esac

#fin
