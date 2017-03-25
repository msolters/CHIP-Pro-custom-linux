#!/bin/bash
# Flash the NAND image stored by new-image/ to any attached FEL device. 

CHIP_TOOLS_PATH="$PWD/CHIP-SDK/CHIP-tools"

bash $CHIP_TOOLS_PATH/chip-flash-nand-images.sh ./new-image
