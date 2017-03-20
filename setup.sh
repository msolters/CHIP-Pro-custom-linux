#!/bin/bash
# This script will pull in the CHIP-SDK, and then unpack it.
# Some things will be downloaded, compiled, and installed so it may ask for
# your password.

HERE="$PWD"

git clone https://github.com/nextthingco/CHIP-SDK
cd "$HERE/CHIP-SDK"
sh ./setup_ubuntu1404.sh
