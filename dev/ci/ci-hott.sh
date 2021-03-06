#!/usr/bin/env bash

ci_dir="$(dirname "$0")"
. "${ci_dir}/ci-common.sh"

git_download HoTT

( cd "${CI_BUILD_DIR}/HoTT" && ./autogen.sh -skip-submodules && ./configure && make && make validate )
