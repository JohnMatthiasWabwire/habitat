#!/bin/bash

set -euo pipefail

source .expeditor/scripts/shared.sh

# This script should contain all shared functions for the verify pipeline

# Always accept habitat license
sudo hab license accept

get_rustfmt_toolchain() {
  # It turns out that every nightly version of rustfmt has slight tweaks from the previous version.
  # This means that if we're always using the latest version, then we're going to have enormous
  # churn. Even PRs that don't touch rust code will likely fail CI, since master will have been
  # formatted with a different version than is running in CI. Because of this, we're going to pin
  # the version of nightly that's used to run rustfmt and bump it when we do a new release.
  #
  # Note that not every nightly version of rust includes rustfmt. Sometimes changes are made that
  # break the way rustfmt uses rustc. Therefore, before updating the pin below, double check
  # that the nightly version you're going to update it to includes rustfmt. You can do that
  # using https://mexus.github.io/rustup-components-history/x86_64-unknown-linux-gnu.html
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  cat "$dir/../../../RUSTFMT_VERSION"
}

install_rustfmt() {
  local toolchain="${1?toolchain argument required}"
  # Only include rustc, rust-std, and cargo components
  # as the base default. This ensures that when we install the
  # rustfmt component, we don't try to bring in anything else
  # like clippy that might not be available in the toolchain
  # for a given target.
  # https://blog.rust-lang.org/2019/10/15/Rustup-1.20.0.html#profiles
  rustup set profile minimal
  install_rust_toolchain "$toolchain"
  rustup component add --toolchain "$toolchain" rustfmt
  # set profile back to default
  rustup set profile default
}

# Get the version of the nightly toolchain we use for compiling,
# running, tests, etc.
get_nightly_toolchain() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    cat "$dir/../../../RUST_NIGHTLY_VERSION"
}

install_hab_pkg() {
  for ident; do
    installed_pkgs=$(hab pkg list "$ident")

    if [[ -z $installed_pkgs ]]; then
      sudo -E hab pkg install "$ident"
    else
      echo "$ident already installed"
    fi
  done
}
