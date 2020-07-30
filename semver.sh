#!/bin/bash

readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_AUTHOR="Peter Forret <peter@forret.com>"
readonly PROG_DIRNAME=$(dirname "$0")
if [[ -z "$PROG_DIRNAME" ]] ; then
	# script called without  path specified ; must be in $PATH somewhere
  readonly PROG_PATH=$(which "$0")
  readonly PROG_FOLDER=$(dirname "$PROG_PATH")
else
  readonly PROG_FOLDER=$(cd "$PROG_DIRNAME" && pwd)
  readonly PROG_PATH="$PROG_FOLDER/$SCRIPT_NAME"
fi

uses_composer=0
[[ -f "composer.json" ]] && uses_composer=1

main(){
    check_requirements
    [[ -z "$1" ]] && show_usage_and_quit

    # there is always a composer version, not always a tag version
    [[ "$1" == "get" ]]   && get_any_version && safe_exit
    [[ "$1" == "check" ]] && check_versions

    [[ "$1" == "set" ]]   && set_versions "$2"
    
    [[ "$1" == "push" ]]  && commit_and_push
}

#####################################################################
## HELPER FUNCTIONS FOR USING composer.json, git tag, ...
#####################################################################

check_requirements(){
    git --version > /dev/null 2>&1 || die "ERROR: git is not installed on this machine"
    git status    > /dev/null 2>&1 || die "ERROR: this folder [] is not a git repository"
    [[ -d .git ]] || die "ERROR: $SCRIPT_NAME should be run from the git repo root"
}

show_usage_and_quit(){
        cat <<END >&2
# $SCRIPT_NAME v$SCRIPT_VERSION - by $SCRIPT_AUTHOR
# Usage:
    $SCRIPT_NAME get: get current version (from git tag and composer)
    $SCRIPT_NAME check: compare versions of git tag and composer
    $SCRIPT_NAME set <version>: set current version through git tag and composer
END
    safe_exit
}


get_any_version(){
  local version="0.0.0"
  if [[ $uses_composer -gt 0 ]] ; then
    version=$(composer config version)
  fi
  if [[ -n $(get_version_tag) ]] ; then
    version=$(get_version_tag)
  fi
  echo "$version"
}

get_version_tag(){
    git tag | tail -1 | sed 's/v//'
    }

get_version_md(){
    if [[ -f VERSION.md ]] ; then
      cat VERSION.md
    else
      echo ""
    fi
    }

get_version_composer(){
    if [[ $uses_composer -gt 0 ]] ; then 
      composer config version
    else
      echo ""
    fi
    }

set_version_composer(){
    if [[ $uses_composer -gt 0 ]] ; then 
      composer config version "$1"
    fi
}

set_version_tag(){
    git tag "v$1"
}

check_versions(){
  version_tag=$(get_version_tag)
  version_composer=$(get_version_composer)
  version_md=$(get_version_md)
  alert "Check versions:"
  [[ -n $version_tag      ]] && alert "Version according to git tag: $version_tag"
  [[ -n $version_composer ]] && alert "Version in composer.json    : $version_composer"
  [[ -n $version_md       ]] && alert "Version in VERSION.md       : $version_md"
  safe_exit 1
}

set_versions(){
    remote_url=$(git config remote.origin.url)
    new_version="$1"
    do_git_push=0
    current_semver=$(get_any_version)
    semver_major=$(echo $current_semver | cut -d. -f1)
    semver_minor=$(echo $current_semver | cut -d. -f2)
    semver_patch=$(echo $current_semver | cut -d. -f3)
    case "$new_version" in
      "auto"|"patch"|"fix")
        new_version="$semver_major.$semver_minor.$((semver_patch +1))"
        out "0. version $current_semver -> $new_version"
        ;;
      "minor")
        new_version="$semver_major.$((semver_minor + 1)).0"
        out "0. version $current_semver -> $new_version"
        ;;
      "major")
        new_version="$((semver_major + 1)).0.0"
        out "0. version $current_semver -> $new_version"
        ;;
    esac

    if [[ -f VERSION.md ]] ; then
      # for bash repos
      out "1. set version in VERSION.md"
      wait 1
      echo "$new_version" > VERSION.md
      git add VERSION.md
      do_git_push=1
    fi

    if [[ $uses_composer -gt 0 ]] ; then 
      # for PHP repos
      # first change composer.json
      out "1. set version in composer.json"
      wait 1
      set_version_composer "$new_version"
      git add composer.json
      do_git_push=1
    fi
    if [[ $do_git_push -gt 0 ]] ; then
      out "2. commit and push changed files"
      wait 1
      ( git commit -m "semver.sh: set version to $new_version" && git push ) 2>&1 | grep 'semver'
    fi
    # now create new version tag
    out "3. set git version tag"
    wait 1
    set_version_tag "$new_version"

    # also push tags to github/bitbucket
    out "4. push tags to $remote_url"
    wait 1
    git push --tags  2>&1 | grep 'new tag'
    safe_exit
}

commit_and_push(){
  git commit -a && git push
  safe_exit
}
#####################################################################
## HELPER FUNCTIONS FROM https://github.com/pforret/bash-boilerplate/
#####################################################################

[[ -t 1 ]] && output_to_pipe=0 || output_to_pipe=1        # detect if output is sent to pipe or to terminal
[[ $(echo -e '\xe2\x82\xac') == '€' ]] && supports_unicode=1 || supports_unicode=0 # detect if supports_unicode is supported

if [[ $output_to_pipe -eq 0 ]] ; then
  readonly col_reset="\033[0m"
  readonly col_red="\033[1;31m"
  readonly col_grn="\033[1;32m"
  readonly col_ylw="\033[1;33m"
else
  # no colors for output_to_pipe content
  readonly col_reset=""
  readonly col_red=""
  readonly col_grn=""
  readonly col_ylw=""
fi

if [[ $supports_unicode -gt 0 ]] ; then
  readonly char_succ="✔"
  readonly char_fail="✖"
  readonly char_alrt="➨"
  readonly char_wait="…"
else
  # no supports_unicode chars if not supported
  readonly char_succ="OK "
  readonly char_fail="!! "
  readonly char_alrt="?? "
  readonly char_wait="..."
fi

out()     { printf '%b\n' "$*"; }
wait()    { printf '%b\r' "$char_wait" && sleep "$1"; }
success() { out "${col_grn}${char_succ}${col_reset}  $*"; }
alert()   { out "${col_ylw}${char_alrt}${col_reset}: $*" >&2 ; }
die()     { tput bel; out "${col_red}${char_fail} $PROGIDEN${col_reset}: $*" >&2; safe_exit; }

error_prefix="${col_red}>${col_reset}"
trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$PROG_PATH awk -v lineno=\$LINENO \
'NR == lineno {print \" from line \" lineno \" : \" \$0}')" INT TERM EXIT

safe_exit() {
  trap - INT TERM EXIT
  exit 0
}

main "$1" "$2"
