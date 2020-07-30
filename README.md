![Shellcheck CI](https://github.com/pforret/semver/workflows/Shellcheck%20CI/badge.svg)
![Bash CI](https://github.com/pforret/semver/workflows/Bash%20CI/badge.svg)
![Bash CI](https://github.com/pforret/semver/workflows/Bash%20CI/badge.svg?event=release)
![GitHub All Releases](https://img.shields.io/github/downloads/pforret/semver/total)
![GitHub](https://img.shields.io/github/license/pforret/semver)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/pforret/semver)
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/pforret/semver)

# semver.sh

* Semantic Versioning helper script
* get and set semver version numbers
* works for PHP packages: composer.json, packagist, git tag
* works for bash/shell scripts: git tag, VERSION.md

## Usage

    # semver.sh v1.0 - by Peter Forret <peter@forret.com>
    # Usage:

* `semver.sh get`: get current version (from git tag and composer)
* `semver.sh check`: compare versions of git tag and composer
* `semver.sh set <version>`: set current version through git tag and composer
* `semver.sh set auto`: add +1 bugfix version e.g. 2.4.17 -> 2.4.18

## Install

### per project 

1. download https://raw.githubusercontent.com/pforret/semver/master/semver.sh in the root of your git repo
2. `chmod +x semver.sh`
3. `./semver.sh check`

### global
1. git clone this repo
2. symlink the script to a location in your path: `ln -s <cloned_folder>/semver.sh /usr/local/bin/`
3. call semver.sh from the root of your git repo


## References
* https://semver.org/